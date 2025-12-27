class MatchModel {
  final String id;
  final String team1Id;
  final String team2Id;
  final String? team1Name;
  final String? team2Name;
  final int overs;
  final String groundType;
  final String ballType;
  final String? youtubeVideoId;
  final String status; // 'upcoming', 'live', 'completed'
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? tossWinnerId;
  final String? tossDecision; // 'bat', 'bowl'
  final String? winnerId;
  final Map<String, dynamic>? scorecard;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchModel({
    required this.id,
    required this.team1Id,
    required this.team2Id,
    this.team1Name,
    this.team2Name,
    required this.overs,
    required this.groundType,
    required this.ballType,
    this.youtubeVideoId,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.tossWinnerId,
    this.tossDecision,
    this.winnerId,
    this.scorecard,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      team1Id: json['team1_id'] as String,
      team2Id: json['team2_id'] as String,
      team1Name: json['team1_name'] as String?,
      team2Name: json['team2_name'] as String?,
      overs: json['overs'] as int,
      groundType: json['ground_type'] as String,
      ballType: json['ball_type'] as String,
      youtubeVideoId: json['youtube_video_id'] as String?,
      status: json['status'] as String,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      tossWinnerId: json['toss_winner_id'] as String?,
      tossDecision: json['toss_decision'] as String?,
      winnerId: json['winner_id'] as String?,
      scorecard: json['scorecard'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'team1_name': team1Name,
      'team2_name': team2Name,
      'overs': overs,
      'ground_type': groundType,
      'ball_type': ballType,
      'youtube_video_id': youtubeVideoId,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'toss_winner_id': tossWinnerId,
      'toss_decision': tossDecision,
      'winner_id': winnerId,
      'scorecard': scorecard,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

