class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'employee' or 'owner'
  final String? companyId;
  final String? faceImageUrl;
  final bool isFaceRegistered;
  final DateTime createdAt;
  final DateTime? lastAttendance;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.companyId,
    this.faceImageUrl,
    this.isFaceRegistered = false,
    required this.createdAt,
    this.lastAttendance,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'employee',
      companyId: map['companyId'],
      faceImageUrl: map['faceImageUrl'],
      isFaceRegistered: map['isFaceRegistered'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastAttendance: map['lastAttendance'] != null
          ? DateTime.parse(map['lastAttendance'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'companyId': companyId,
      'faceImageUrl': faceImageUrl,
      'isFaceRegistered': isFaceRegistered,
      'createdAt': createdAt.toIso8601String(),
      'lastAttendance': lastAttendance?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? companyId,
    String? faceImageUrl,
    bool? isFaceRegistered,
    DateTime? createdAt,
    DateTime? lastAttendance,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      faceImageUrl: faceImageUrl ?? this.faceImageUrl,
      isFaceRegistered: isFaceRegistered ?? this.isFaceRegistered,
      createdAt: createdAt ?? this.createdAt,
      lastAttendance: lastAttendance ?? this.lastAttendance,
    );
  }
}
