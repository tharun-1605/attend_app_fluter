import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../models/company_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot snapshot = await _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .where('checkInTime', isGreaterThan: startOfDay.toIso8601String())
        .where('checkInTime', isLessThan: endOfDay.toIso8601String())
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return AttendanceModel.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    }
    return null;
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
          (doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // Storage methods
  Future<String> uploadFaceImage(String userId, Uint8List imageBytes) async {
    try {
      Reference ref = _storage.ref().child('face_images').child('$userId.jpg');
      UploadTask task = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
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
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    // Get total employees
    QuerySnapshot employeesSnapshot = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .where('role', isEqualTo: 'employee')
        .get();

    int totalEmployees = employeesSnapshot.docs.length;

    // Get present employees
    QuerySnapshot attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('companyId', isEqualTo: companyId)
        .where('checkInTime', isGreaterThan: startOfDay.toIso8601String())
        .where('checkInTime', isLessThan: endOfDay.toIso8601String())
        .get();

    int presentEmployees = attendanceSnapshot.docs.length;

    return {
      'total': totalEmployees,
      'present': presentEmployees,
      'absent': totalEmployees - presentEmployees,
    };
  }
}
