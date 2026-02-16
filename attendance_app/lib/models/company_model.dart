class CompanyModel {
  final String id;
  final String name;
  final String ownerId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double radiusInMeters;
  final String? workingStartTime;
  final String? workingEndTime;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.address,
    this.latitude,
    this.longitude,
    this.radiusInMeters = 100.0,
    this.workingStartTime,
    this.workingEndTime,
    required this.createdAt,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      radiusInMeters: map['radiusInMeters']?.toDouble() ?? 100.0,
      workingStartTime: map['workingStartTime'],
      workingEndTime: map['workingEndTime'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'workingStartTime': workingStartTime,
      'workingEndTime': workingEndTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? address,
    double? latitude,
    double? longitude,
    double? radiusInMeters,
    String? workingStartTime,
    String? workingEndTime,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      workingStartTime: workingStartTime ?? this.workingStartTime,
      workingEndTime: workingEndTime ?? this.workingEndTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
