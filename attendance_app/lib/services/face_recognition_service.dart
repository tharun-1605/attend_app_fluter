import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

class FaceRecognitionService {
  late FaceDetector _faceDetector;
  List<CameraDescription>? _cameras;

  FaceRecognitionService() {
    // Initialize face detector with options
    final FaceDetectorOptions options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  // Initialize cameras
  Future<void> initializeCameras() async {
    _cameras = await availableCameras();
  }

  // Get available cameras
  List<CameraDescription>? get cameras => _cameras;

  // Create camera controller
  Future<CameraController?> createCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initializeCameras();
    }

    if (_cameras == null || _cameras!.isEmpty) {
      return null;
    }

    // Use front camera for face recognition
    CameraDescription? frontCamera;
    for (var camera in _cameras!) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    frontCamera ??= _cameras!.first;

    return CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
  }

  // Detect faces in an image
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  // Detect faces from file
  Future<List<Face>> detectFacesFromFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _faceDetector.processImage(inputImage);
  }

  // Detect faces from bytes
  Future<List<Face>> detectFacesFromBytes(Uint8List bytes) async {
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: const Size(1, 1),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: bytes.length,
      ),
    );
    return await _faceDetector.processImage(inputImage);
  }

  // Check if image has a face
  Future<bool> hasFace(String imagePath) async {
    try {
      final faces = await detectFacesFromFile(imagePath);
      return faces.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if image has exactly one face
  Future<bool> hasSingleFace(String imagePath) async {
    try {
      final faces = await detectFacesFromFile(imagePath);
      return faces.length == 1;
    } catch (e) {
      return false;
    }
  }

  // Get face bounding box
  Future<Rect?> getFaceBoundingBox(String imagePath) async {
    try {
      final faces = await detectFacesFromFile(imagePath);
      if (faces.isNotEmpty) {
        return faces.first.boundingBox;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  // Check if face is looking at camera
  Future<bool> isLookingAtCamera(String imagePath) async {
    try {
      final faces = await detectFacesFromFile(imagePath);
      if (faces.isNotEmpty) {
        final face = faces.first;
        // Check if face is looking at the camera (based on yaw and roll)
        final yaw = face.headEulerAngleY;
        final roll = face.headEulerAngleX;

        // Allow some tolerance
        return (yaw?.abs() ?? 0) < 30 && (roll?.abs() ?? 0) < 20;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  // Check if eyes are open
  Future<bool> areEyesOpen(String imagePath) async {
    try {
      final faces = await detectFacesFromFile(imagePath);
      if (faces.isNotEmpty) {
        final face = faces.first;
        if (face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability != null) {
          return face.leftEyeOpenProbability! > 0.5 &&
              face.rightEyeOpenProbability! > 0.5;
        }
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }

  // Save captured image to file
  Future<String?> saveImageToFile(XFile image, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/face_$userId.jpg';
      await image.saveTo(path);
      return path;
    } catch (e) {
      return null;
    }
  }

  // Delete saved image
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Handle error
    }
  }

  // Process camera frame for face detection
  Future<InputImage?> convertCameraImage(CameraImage image) async {
    try {
      // Convert CameraImage to InputImage
      final camera = _cameras?.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

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

  // Dispose resources
  void dispose() {
    _faceDetector.close();
  }
}
