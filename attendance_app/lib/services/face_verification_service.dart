import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

class FaceVerificationService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<bool> verifyAgainstRegisteredFace({
    required String? registeredFaceUrl,
    required String liveImagePath,
  }) async {
    if (registeredFaceUrl == null || registeredFaceUrl.trim().isEmpty) {
      return false;
    }

    final registeredBytes = await _loadRegisteredImageBytes(registeredFaceUrl);
    if (registeredBytes == null || registeredBytes.isEmpty) {
      return false;
    }

    final tempFile = await _writeTempImage(registeredBytes);
    try {
      final registeredFace = await _detectSingleFace(tempFile.path);
      final liveFace = await _detectSingleFace(liveImagePath);
      if (registeredFace == null || liveFace == null) return false;

      final registeredVector = _extractVector(registeredFace);
      final liveVector = _extractVector(liveFace);
      if (registeredVector == null || liveVector == null) return false;

      final distance = _euclideanDistance(registeredVector, liveVector);
      return distance < 0.18;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<Uint8List?> _loadRegisteredImageBytes(String url) async {
    try {
      if (url.startsWith('file://')) {
        final localPath = Uri.parse(url).toFilePath();
        final file = File(localPath);
        if (!await file.exists()) return null;
        return await file.readAsBytes();
      }

      if (url.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(url)) {
        final file = File(url);
        if (!await file.exists()) return null;
        return await file.readAsBytes();
      }

      final ref = FirebaseStorage.instance.refFromURL(url);
      return await ref.getData(5 * 1024 * 1024);
    } catch (_) {
      return null;
    }
  }

  Future<File> _writeTempImage(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/registered_face_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Face?> _detectSingleFace(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(input);
    if (faces.length != 1) return null;
    return faces.first;
  }

  List<double>? _extractVector(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;

    if (leftEye == null ||
        rightEye == null ||
        nose == null ||
        leftMouth == null ||
        rightMouth == null) {
      return null;
    }

    final box = face.boundingBox;
    final width = box.width == 0 ? 1.0 : box.width;
    final height = box.height == 0 ? 1.0 : box.height;

    double nx(num x) => (x.toDouble() - box.left) / width;
    double ny(num y) => (y.toDouble() - box.top) / height;

    return [
      nx(leftEye.x),
      ny(leftEye.y),
      nx(rightEye.x),
      ny(rightEye.y),
      nx(nose.x),
      ny(nose.y),
      nx(leftMouth.x),
      ny(leftMouth.y),
      nx(rightMouth.x),
      ny(rightMouth.y),
    ];
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return math.sqrt(sum);
  }

  Future<void> dispose() async {
    await _detector.close();
  }
}
