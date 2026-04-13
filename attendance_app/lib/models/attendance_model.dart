class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final String companyId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final bool isValidLocation;
  final String status;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.companyId,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.isValidLocation = false,
    this.status = 'present',
    this.notes,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      companyId: map['companyId'] ?? '',
      checkInTime: map['checkInTime'] != null
          ? DateTime.parse(map['checkInTime'])
          : DateTime.now(),
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'])
          : null,
      checkInLocation: map['checkInLocation'],
      checkOutLocation: map['checkOutLocation'],
      checkInLatitude: map['checkInLatitude']?.toDouble(),
      checkInLongitude: map['checkInLongitude']?.toDouble(),
      checkOutLatitude: map['checkOutLatitude']?.toDouble(),
      checkOutLongitude: map['checkOutLongitude']?.toDouble(),
      isValidLocation: map['isValidLocation'] ?? false,
      status: map['status'] ?? 'present',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'companyId': companyId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkInLocation': checkInLocation,
      'checkOutLocation': checkOutLocation,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'isValidLocation': isValidLocation,
      'status': status,
      'notes': notes,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? companyId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? checkInLocation,
    String? checkOutLocation,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    bool? isValidLocation,
    String? status,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      companyId: companyId ?? this.companyId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      isValidLocation: isValidLocation ?? this.isValidLocation,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
