class TournamentModel {
  final String id;
  final String name;
  final String city;
  final String ground;
  final String? bannerUrl;
  final String? logoUrl;
  final String organizerName;
  final String organizerMobile;
  final DateTime startDate;
  final DateTime endDate;
  final String category; // 'open', 'corporate', 'community', 'school', 'college', 'series', 'other'
  final String ballType; // 'leather', 'tennis', 'other'
  final String pitchType; // 'matting', 'rough', 'cemented', 'astro-turf'
  final bool inviteLinkEnabled;
  final String? inviteLinkToken;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TournamentModel({
    required this.id,
    required this.name,
    required this.city,
    required this.ground,
    this.bannerUrl,
    this.logoUrl,
    required this.organizerName,
    required this.organizerMobile,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.ballType,
    required this.pitchType,
    this.inviteLinkEnabled = true,
    this.inviteLinkToken,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      ground: json['ground'] as String,
      bannerUrl: json['banner_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      organizerName: json['organizer_name'] as String,
      organizerMobile: json['organizer_mobile'] as String,
      startDate: json['start_date'] is DateTime
          ? json['start_date'] as DateTime
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] is DateTime
          ? json['end_date'] as DateTime
          : DateTime.parse(json['end_date'] as String),
      category: json['category'] as String,
      ballType: json['ball_type'] as String,
      pitchType: json['pitch_type'] as String,
      inviteLinkEnabled: json['invite_link_enabled'] as bool? ?? true,
      inviteLinkToken: json['invite_link_token'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] is DateTime
          ? json['created_at'] as DateTime
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] is DateTime
          ? json['updated_at'] as DateTime
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'ground': ground,
      'banner_url': bannerUrl,
      'logo_url': logoUrl,
      'organizer_name': organizerName,
      'organizer_mobile': organizerMobile,
      'start_date': startDate.toIso8601String().split('T')[0], // Date only
      'end_date': endDate.toIso8601String().split('T')[0], // Date only
      'category': category,
      'ball_type': ballType,
      'pitch_type': pitchType,
      'invite_link_enabled': inviteLinkEnabled,
      'invite_link_token': inviteLinkToken,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  bool get isEditable => startDate.isAfter(DateTime.now());
  String get inviteLink => inviteLinkToken != null
      ? 'https://pitchpoint.app/tournament/join/$inviteLinkToken'
      : '';

  // Backward compatibility properties (for existing code)
  String get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      return 'registration_open';
    } else if (now.isAfter(endDate)) {
      return 'completed';
    } else {
      return 'ongoing';
    }
  }

  String? get imageUrl => bannerUrl; // Use banner as main image
  double? get prizePool => null; // Not in new schema, return null
  int? get totalTeams => null; // Not in new schema, will be computed from teams
  int? get registeredTeams => null; // Not in new schema, will be computed from teams
}

/// Tournament Team Model
class TournamentTeamModel {
  final String id;
  final String tournamentId;
  final String teamName;
  final String? teamLogo;
  final String joinType; // 'manual' or 'invite'
  final String? captainId;
  final String? captainName;
  final DateTime createdAt;

  TournamentTeamModel({
    required this.id,
    required this.tournamentId,
    required this.teamName,
    this.teamLogo,
    required this.joinType,
    this.captainId,
    this.captainName,
    required this.createdAt,
  });

  factory TournamentTeamModel.fromJson(Map<String, dynamic> json) {
    return TournamentTeamModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      teamName: json['team_name'] as String,
      teamLogo: json['team_logo'] as String?,
      joinType: json['join_type'] as String,
      captainId: json['captain_id'] as String?,
      captainName: json['captain_name'] as String?,
      createdAt: json['created_at'] is DateTime
          ? json['created_at'] as DateTime
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'team_name': teamName,
      'team_logo': teamLogo,
      'join_type': joinType,
      'captain_id': captainId,
      'captain_name': captainName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

