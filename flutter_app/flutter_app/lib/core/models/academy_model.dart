class AcademyModel {
  final String id;
  final String name;
  final String location;
  final String? phone;
  final String? email;
  final double? registrationFee;
  final int? totalStudents;
  final int? activePrograms;
  final double? avgAttendance;
  final int? topCoaches;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  AcademyModel({
    required this.id,
    required this.name,
    required this.location,
    this.phone,
    this.email,
    this.registrationFee,
    this.totalStudents,
    this.activePrograms,
    this.avgAttendance,
    this.topCoaches,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcademyModel.fromJson(Map<String, dynamic> json) {
    return AcademyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      registrationFee: json['registration_fee'] != null
          ? (json['registration_fee'] as num).toDouble()
          : null,
      totalStudents: json['total_students'] as int?,
      activePrograms: json['active_programs'] as int?,
      avgAttendance: json['avg_attendance'] != null
          ? (json['avg_attendance'] as num).toDouble()
          : null,
      topCoaches: json['top_coaches'] as int?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'phone': phone,
      'email': email,
      'registration_fee': registrationFee,
      'total_students': totalStudents,
      'active_programs': activePrograms,
      'avg_attendance': avgAttendance,
      'top_coaches': topCoaches,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

