import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/company_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<FirebaseStorage> _storageCandidates() {
    final candidates = <FirebaseStorage>[_storage];
    final currentBucket = _storage.bucket;
    const modernSuffix = '.firebasestorage.app';
    if (currentBucket.endsWith(modernSuffix)) {
      final projectId = currentBucket.substring(
        0,
        currentBucket.length - modernSuffix.length,
      );
      candidates.add(
        FirebaseStorage.instanceFor(bucket: 'gs://$projectId.appspot.com'),
      );
    }
    return candidates;
  }

  DocumentReference<Map<String, dynamic>> createCompanyDoc() {
    return _firestore.collection('companies').doc();
  }

  // Company methods
  Future<void> createCompany(CompanyModel company) async {
    await _firestore
        .collection('companies')
        .doc(company.id)
        .set(company.toMap());
  }

  Future<CompanyModel?> getCompany(String companyId) async {
    DocumentSnapshot doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .get();
    if (doc.exists) {
      return CompanyModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateCompany(CompanyModel company) async {
    await _firestore
        .collection('companies')
        .doc(company.id)
        .update(company.toMap());
  }

  // User methods
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<List<UserModel>> getEmployeesByCompany(String companyId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .where('role', isEqualTo: 'employee')
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Attendance methods
  Future<void> createAttendance(AttendanceModel attendance) async {
    await _firestore
        .collection('attendance')
        .doc(attendance.id)
        .set(attendance.toMap());
  }

  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _firestore
        .collection('attendance')
        .doc(attendance.id)
        .update(attendance.toMap());
  }

  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('checkInTime', isGreaterThan: startOfDay.toIso8601String())
          .where('checkInTime', isLessThan: endOfDay.toIso8601String())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AttendanceModel.fromMap(
          snapshot.docs.first.data(),
        );
      }
      return null;
    } on FirebaseException catch (e) {
      // Fallback for missing composite index: query by user only and filter locally.
      if (e.code != 'failed-precondition') rethrow;

      final baseSnapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .limit(200)
          .get();

      final todaysRecords = baseSnapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data()))
          .where(
            (a) =>
                !a.checkInTime.isBefore(startOfDay) &&
                a.checkInTime.isBefore(endOfDay),
          )
          .toList();

      if (todaysRecords.isEmpty) return null;
      todaysRecords.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return todaysRecords.first;
    }
  }

  Future<List<AttendanceModel>> getAttendanceByUser(
    String userId, {
    int limit = 30,
  }) async {
    QuerySnapshot snapshot = await _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .orderBy('checkInTime', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<AttendanceModel>> getAttendanceByCompany(
    String companyId, {
    DateTime? date,
  }) async {
    try {
      QuerySnapshot snapshot;

      if (date != null) {
        DateTime startOfDay = DateTime(date.year, date.month, date.day);
        DateTime endOfDay = startOfDay.add(const Duration(days: 1));

        snapshot = await _firestore
            .collection('attendance')
            .where('companyId', isEqualTo: companyId)
            .where('checkInTime', isGreaterThan: startOfDay.toIso8601String())
            .where('checkInTime', isLessThan: endOfDay.toIso8601String())
            .orderBy('checkInTime', descending: true)
            .get();
      } else {
        snapshot = await _firestore
            .collection('attendance')
            .where('companyId', isEqualTo: companyId)
            .orderBy('checkInTime', descending: true)
            .limit(100)
            .get();
      }

      return snapshot.docs
          .map(
            (doc) =>
                AttendanceModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } on FirebaseException catch (e) {
      // Fallback for missing composite index: query by company only and filter/sort locally.
      if (e.code != 'failed-precondition') rethrow;

      final baseSnapshot = await _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .limit(1000)
          .get();

      var records = baseSnapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data()))
          .toList();

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        records = records
            .where(
              (a) =>
                  !a.checkInTime.isBefore(startOfDay) &&
                  a.checkInTime.isBefore(endOfDay),
            )
            .toList();
      }

      records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return date == null && records.length > 100
          ? records.take(100).toList()
          : records;
    }
  }

  // Storage methods
  Future<String> uploadFaceImage(String userId, Uint8List imageBytes) async {
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    FirebaseException? lastError;
    for (final storage in _storageCandidates()) {
      final ref = storage.ref().child('face_images').child('$userId.jpg');
      try {
        // Upload once and retry once for transient lookup issues.
        try {
          await ref.putData(imageBytes, metadata);
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 350));
          await ref.putData(imageBytes, metadata);
        }

        // Download URL creation can lag briefly after upload on some setups.
        for (var i = 0; i < 3; i++) {
          try {
            return await ref.getDownloadURL();
          } on FirebaseException catch (e) {
            if (e.code != 'object-not-found') rethrow;
            if (i < 2) {
              await Future<void>.delayed(
                Duration(milliseconds: 300 * (i + 1)),
              );
            }
          }
        }

        // Keep registration successful with a stable storage reference.
        return 'gs://${storage.bucket}/${ref.fullPath}';
      } on FirebaseException catch (e) {
        lastError = e;
        // Try next configured bucket candidate.
      }
    }

    if (lastError != null) throw lastError;
    throw Exception('Face image upload failed');
  }

  Future<void> deleteFaceImage(String userId) async {
    try {
      await _storage.ref().child('face_images').child('$userId.jpg').delete();
    } catch (e) {
      // Ignore if file doesn't exist
    }
  }

  // Stats methods
  Future<Map<String, int>> getAttendanceStats(
    String companyId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Get total employees
    final employeesSnapshot = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .where('role', isEqualTo: 'employee')
        .get();

    final totalEmployees = employeesSnapshot.docs.length;

    try {
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .where('checkInTime', isGreaterThan: startOfDay.toIso8601String())
          .where('checkInTime', isLessThan: endOfDay.toIso8601String())
          .get();

      final presentEmployees = attendanceSnapshot.docs.length;
      return {
        'total': totalEmployees,
        'present': presentEmployees,
        'absent': totalEmployees - presentEmployees,
      };
    } on FirebaseException catch (e) {
      // Fallback for missing composite index.
      if (e.code != 'failed-precondition') rethrow;

      final baseSnapshot = await _firestore
          .collection('attendance')
          .where('companyId', isEqualTo: companyId)
          .limit(1000)
          .get();

      final presentEmployees = baseSnapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data()))
          .where(
            (a) =>
                !a.checkInTime.isBefore(startOfDay) &&
                a.checkInTime.isBefore(endOfDay),
          )
          .length;

      return {
        'total': totalEmployees,
        'present': presentEmployees,
        'absent': totalEmployees - presentEmployees,
      };
    }
  }
}
