class TournamentTeamModel {
  final String id;
  final String tournamentId;
  final String teamName;
  final String? teamLogo;
  final String? joinType;
  final String? captainId;
  final String? captainName;
  final DateTime createdAt;

  TournamentTeamModel({
    required this.id,
    required this.tournamentId,
    required this.teamName,
    this.teamLogo,
    this.joinType,
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
      joinType: json['join_type'] as String?,
      captainId: json['captain_id'] as String?,
      captainName: json['captain_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
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
