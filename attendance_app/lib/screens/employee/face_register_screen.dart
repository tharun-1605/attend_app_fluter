import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _faceDetected = false;
  String _statusMessage = 'Initializing camera...';
  int _imageCount = 0;
  final List<String> _capturedImages = [];

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras found';
          _isInitializing = false;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Position your face in the frame';
        });

        _startImageStream();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing camera: $e';
        _isInitializing = false;
      });
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((cameraImage) async {
      if (_isProcessing || _imageCount >= 5) return;

      _isProcessing = true;

      try {
        final inputImage = _convertCameraImage(cameraImage);
        if (inputImage == null) {
          _isProcessing = false;
          return;
        }

        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            _faceDetected = faces.isNotEmpty;
            if (_faceDetected) {
              _statusMessage =
                  'Face detected! ${5 - _imageCount} more photos needed';
            } else {
              _statusMessage = 'Position your face in the frame';
            }
          });
        }
      } catch (e) {
        // Handle error
      }

      _isProcessing = false;
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController?.description;
      if (camera == null) return null;

      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (!_faceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please position your face in the frame'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final image = await _cameraController!.takePicture();

      setState(() {
        _capturedImages.add(image.path);
        _imageCount++;
        _statusMessage = '${5 - _imageCount} more photos needed';
      });

      if (_imageCount >= 5) {
        await _saveFaceData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _saveFaceData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        _statusMessage = 'Saving face data...';
      });

      // Update user as face registered
      final userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        final updatedUser = userData.copyWith(isFaceRegistered: true);
        await _authService.updateUserData(updatedUser);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face registered successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving face data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Face')),
      body: _isInitializing
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      if (_cameraController != null &&
                          _cameraController!.value.isInitialized)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CameraPreview(_cameraController!),
                        ),
                      // Face frame overlay
                      Center(
                        child: Container(
                          width: 250,
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _faceDetected
                                  ? AppTheme.successColor
                                  : Colors.white,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _statusMessage,
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _imageCount / 5,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_imageCount/5 photos captured',
                        style: AppTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_imageCount > 0)
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _imageCount = 0;
                                  _capturedImages.clear();
                                  _statusMessage =
                                      'Position your face in the frame';
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ElevatedButton.icon(
                            onPressed: _faceDetected && _imageCount < 5
                                ? _captureImage
                                : null,
                            icon: const Icon(Icons.camera),
                            label: const Text('Capture'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
