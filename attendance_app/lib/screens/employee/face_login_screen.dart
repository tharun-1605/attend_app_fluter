import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/face_verification_service.dart';
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
  bool _isStreaming = false;
  bool _faceDetected = false;
  bool _isMarkingAttendance = false;
  String _statusMessage = 'Initializing camera...';

  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _faceVerificationService = FaceVerificationService();
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
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
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
    if (_isStreaming) return;
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
    _isStreaming = true;
  }

  Future<void> _stopImageStream() async {
    if (!_isStreaming) return;
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {
      // Ignore and continue.
    } finally {
      _isStreaming = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameraController?.description;
      if (camera == null) return null;

      final isAndroid = Platform.isAndroid;
      final expectedGroup = isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888;
      if (image.format.group != expectedGroup || image.planes.isEmpty) {
        return null;
      }

      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      // ML Kit expects a single-plane buffer for nv21/bgra8888.
      if (image.planes.length != 1) return null;
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

      String? registeredFaceUrl = user.faceImageUrl;
      if (registeredFaceUrl == null || registeredFaceUrl.trim().isEmpty) {
        // Backward-compatible fallback for users marked as registered before
        // faceImageUrl was persisted.
        if (user.isFaceRegistered) {
          final bucket = FirebaseStorage.instance.bucket;
          registeredFaceUrl = 'gs://$bucket/face_images/${user.id}.jpg';
        }
      }

      if (!user.isFaceRegistered || registeredFaceUrl == null) {
        throw Exception(
          'No registered face found. Please register your face first.',
        );
      }

      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        throw Exception('Camera not ready');
      }

      await _stopImageStream();
      final livePhoto = await _cameraController!.takePicture();
      var isFaceMatch = await _faceVerificationService.verifyAgainstRegisteredFace(
        registeredFaceUrl: registeredFaceUrl,
        liveImagePath: livePhoto.path,
      );
      if (!isFaceMatch &&
          registeredFaceUrl.contains('.firebasestorage.app/')) {
        final altUrl = registeredFaceUrl.replaceFirst(
          '.firebasestorage.app/',
          '.appspot.com/',
        );
        isFaceMatch = await _faceVerificationService.verifyAgainstRegisteredFace(
          registeredFaceUrl: altUrl,
          liveImagePath: livePhoto.path,
        );
      }
      if (!isFaceMatch) {
        throw Exception('Face does not match registered employee face');
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
        final isLocationServiceEnabled =
            await _locationService.isLocationServiceEnabled();
        if (!isLocationServiceEnabled) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Turn on location to mark attendance';
              _isMarkingAttendance = false;
            });
            _showLocationTurnOnDialog();
            _startImageStream();
          }
          return;
        }

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

      final checkInTime = DateTime.now();

      final todayAttendance = await _firestoreService.getTodayAttendance(
        user.id,
      );

      if (todayAttendance != null && todayAttendance.checkOutTime != null) {
        throw Exception(
          'You have already completed check-in and check-out for today. You can check in again tomorrow.',
        );
      }

      // Check if employee already has an open attendance cycle.
      final openAttendance = await _firestoreService.getOpenAttendance(user.id);

      if (openAttendance != null) {
        final updatedAttendance = openAttendance.copyWith(
          checkOutTime: checkInTime,
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
          checkInTime: checkInTime,
          checkInLatitude: latitude,
          checkInLongitude: longitude,
          checkInLocation: latitude != null && longitude != null
              ? '$latitude,$longitude'
              : null,
          isValidLocation: isValidLocation,
          status: isValidLocation
              ? _getAttendanceStatus(company.workingStartTime, checkInTime)
              : 'invalid_location',
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
        _startImageStream();
      }
    }
  }

  String _getAttendanceStatus(String? companyStartTime, DateTime checkInTime) {
    final lateThreshold = _parseCompanyTime(companyStartTime, checkInTime);
    if (lateThreshold == null) {
      return 'present';
    }

    return checkInTime.isAfter(lateThreshold) ? 'late' : 'present';
  }

  DateTime? _parseCompanyTime(String? time, DateTime referenceDate) {
    if (time == null || time.trim().isEmpty) {
      return null;
    }

    final normalizedTime = time.trim().toUpperCase();
    final twelveHourMatch = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    ).firstMatch(normalizedTime);
    if (twelveHourMatch != null) {
      final hour = int.parse(twelveHourMatch.group(1)!);
      final minute = int.parse(twelveHourMatch.group(2)!);
      final meridiem = twelveHourMatch.group(3)!;

      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
        return null;
      }

      var convertedHour = hour % 12;
      if (meridiem == 'PM') {
        convertedHour += 12;
      }

      return DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
        convertedHour,
        minute,
      );
    }

    final twentyFourHourMatch = RegExp(
      r'^(\d{1,2}):(\d{2})$',
    ).firstMatch(normalizedTime);
    if (twentyFourHourMatch == null) {
      return null;
    }

    final hour = int.parse(twentyFourHourMatch.group(1)!);
    final minute = int.parse(twentyFourHourMatch.group(2)!);
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      hour,
      minute,
    );
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

  void _showLocationTurnOnDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location is turned off'),
        content: const Text(
          'Please turn on device location to mark attendance at your company location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _locationService.openLocationSettings();
            },
            child: const Text('Turn On Location'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopImageStream();
    _faceVerificationService.dispose();
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
