import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../models/attendance_model.dart';

class FaceLoginScreen extends StatefulWidget {
  const FaceLoginScreen({super.key});

  @override
  State<FaceLoginScreen> createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen> {
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
  bool _isMarkingAttendance = false;
  String _statusMessage = 'Initializing camera...';

  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();

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
          _statusMessage = 'Position your face in the frame to mark attendance';
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
      if (_isProcessing || _isMarkingAttendance) return;

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
              _statusMessage = 'Face detected! Tap to mark attendance';
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

  Future<void> _markAttendance() async {
    if (!_faceDetected || _isMarkingAttendance) return;

    setState(() {
      _isMarkingAttendance = true;
      _statusMessage = 'Marking attendance...';
    });

    try {
      // Get current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('User not logged in');
      }

      // Get user data
      final user = await _authService.getUserData(firebaseUser.uid);
      if (user == null) {
        throw Exception('User data not found');
      }

      // Check if user has company
      if (user.companyId == null) {
        throw Exception('No company associated with this user');
      }

      // Get company data
      final company = await _firestoreService.getCompany(user.companyId!);
      if (company == null) {
        throw Exception('Company not found');
      }

      // Check location
      bool isValidLocation = false;
      double? latitude;
      double? longitude;

      if (company.latitude != null && company.longitude != null) {
        final locationInfo = await _locationService.getLocationInfo();
        if (locationInfo != null) {
          latitude = locationInfo['latitude'];
          longitude = locationInfo['longitude'];

          final distance = _locationService.calculateDistance(
            latitude!,
            longitude!,
            company.latitude!,
            company.longitude!,
          );

          isValidLocation = distance <= company.radiusInMeters;
        }
      } else {
        // If company location is not set, allow attendance
        isValidLocation = true;
      }

      // Check if already marked attendance today
      final todayAttendance = await _firestoreService.getTodayAttendance(
        user.id,
      );

      if (todayAttendance != null && todayAttendance.checkOutTime == null) {
        // Already checked in, do checkout
        final updatedAttendance = todayAttendance.copyWith(
          checkOutTime: DateTime.now(),
          checkOutLatitude: latitude,
          checkOutLongitude: longitude,
          checkOutLocation: latitude != null && longitude != null
              ? '$latitude,$longitude'
              : null,
        );

        await _firestoreService.updateAttendance(updatedAttendance);

        if (mounted) {
          _showSuccessDialog('Checked out successfully!');
        }
      } else {
        // Create new attendance
        final attendance = AttendanceModel(
          id: const Uuid().v4(),
          userId: user.id,
          userName: user.name,
          companyId: user.companyId!,
          checkInTime: DateTime.now(),
          checkInLatitude: latitude,
          checkInLongitude: longitude,
          checkInLocation: latitude != null && longitude != null
              ? '$latitude,$longitude'
              : null,
          isValidLocation: isValidLocation,
          status: isValidLocation ? 'present' : 'invalid_location',
        );

        await _firestoreService.createAttendance(attendance);

        // Update user's last attendance
        final updatedUser = user.copyWith(lastAttendance: DateTime.now());
        await _authService.updateUserData(updatedUser);

        if (mounted) {
          if (isValidLocation) {
            _showSuccessDialog('Attendance marked successfully!');
          } else {
            _showWarningDialog(
              'Attendance marked, but you are not at the company location!',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _statusMessage = 'Error marking attendance';
          _isMarkingAttendance = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: const Text('Mark Attendance')),
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
                        child: GestureDetector(
                          onTap: _faceDetected && !_isMarkingAttendance
                              ? _markAttendance
                              : null,
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
                      const SizedBox(height: 16),
                      if (_isMarkingAttendance)
                        const CircularProgressIndicator()
                      else if (_faceDetected)
                        ElevatedButton.icon(
                          onPressed: _markAttendance,
                          icon: const Icon(Icons.check),
                          label: const Text('Mark Attendance'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
