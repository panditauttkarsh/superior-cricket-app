class PlayerModel {
  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final String? city;
  final String? state;
  final String? role; // 'batsman', 'bowler', 'all-rounder', 'wicket-keeper'
  final Map<String, dynamic>? battingStats;
  final Map<String, dynamic>? bowlingStats;
  final int? totalMatches;
  final double? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerModel({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    this.profileImageUrl,
    this.city,
    this.state,
    this.role,
    this.battingStats,
    this.bowlingStats,
    this.totalMatches,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      role: json['role'] as String?,
      battingStats: json['batting_stats'] as Map<String, dynamic>?,
      bowlingStats: json['bowling_stats'] as Map<String, dynamic>?,
      totalMatches: json['total_matches'] as int?,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'city': city,
      'state': state,
      'role': role,
      'batting_stats': battingStats,
      'bowling_stats': bowlingStats,
      'total_matches': totalMatches,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

