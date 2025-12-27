class TeamModel {
  final String id;
  final String name;
  final String? location;
  final String? city;
  final String? state;
  final String? logoUrl;
  final String? captainId;
  final String? captainName;
  final List<String> playerIds;
  final int? totalMatches;
  final int? wins;
  final int? losses;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamModel({
    required this.id,
    required this.name,
    this.location,
    this.city,
    this.state,
    this.logoUrl,
    this.captainId,
    this.captainName,
    required this.playerIds,
    this.totalMatches,
    this.wins,
    this.losses,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      logoUrl: json['logo_url'] as String?,
      captainId: json['captain_id'] as String?,
      captainName: json['captain_name'] as String?,
      playerIds: (json['player_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalMatches: json['total_matches'] as int?,
      wins: json['wins'] as int?,
      losses: json['losses'] as int?,
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
      'city': city,
      'state': state,
      'logo_url': logoUrl,
      'captain_id': captainId,
      'captain_name': captainName,
      'player_ids': playerIds,
      'total_matches': totalMatches,
      'wins': wins,
      'losses': losses,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

