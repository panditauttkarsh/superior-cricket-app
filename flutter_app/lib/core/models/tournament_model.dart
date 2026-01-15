class TournamentModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'registration_open', 'ongoing', 'completed'
  final int? totalTeams;
  final int? registeredTeams;
  final double? prizePool;
  final String? location;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bannerUrl;
  final String? logoUrl;
  final String inviteLink;
  final String? category;
  final String city;
  final String? ground;
  final String organizerName;
  final String organizerMobile;
  final String? ballType;
  final String? pitchType;

  TournamentModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.startDate,
    this.endDate,
    required this.status,
    this.totalTeams,
    this.registeredTeams,
    this.prizePool,
    this.location,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.bannerUrl,
    this.logoUrl,
    this.inviteLink = '',
    this.category,
    this.city = '',
    this.ground,
    this.organizerName = '',
    this.organizerMobile = '',
    this.ballType,
    this.pitchType,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: json['status'] as String,
      totalTeams: json['total_teams'] as int?,
      registeredTeams: json['registered_teams'] as int?,
      prizePool: json['prize_pool'] != null
          ? (json['prize_pool'] as num).toDouble()
          : null,
      location: json['location'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bannerUrl: json['banner_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      inviteLink: json['invite_link'] as String? ?? '',
      category: json['category'] as String?,
      city: json['city'] as String? ?? '',
      ground: json['ground'] as String?,
      organizerName: json['organizer_name'] as String? ?? '',
      organizerMobile: json['organizer_mobile'] as String? ?? '',
      ballType: json['ball_type'] as String?,
      pitchType: json['pitch_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'total_teams': totalTeams,
      'registered_teams': registeredTeams,
      'prize_pool': prizePool,
      'location': location,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category': category,
      'city': city,
      'ground': ground,
      'organizer_name': organizerName,
      'organizer_mobile': organizerMobile,
      'ball_type': ballType,
      'pitch_type': pitchType,
    };
  }
}

