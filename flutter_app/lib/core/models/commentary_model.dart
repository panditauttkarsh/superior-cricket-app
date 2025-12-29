/// Commentary Model for Ball-by-Ball Commentary
class CommentaryModel {
  final String id;
  final String matchId;
  final double over; // e.g., 5.3 means 5th over, 3rd ball
  final String ballType; // 'normal', 'wide', 'noBall', 'wicket', 'bye', 'legBye'
  final int runs; // 0, 1, 2, 3, 4, 6
  final String? wicketType; // 'bowled', 'caught', 'lbw', 'runOut', etc.
  final String strikerName;
  final String bowlerName;
  final String? nonStrikerName;
  final DateTime timestamp;
  final String commentaryText; // Human-readable sentence
  final String? shotDirection; // 'cover', 'midwicket', 'straight', etc.
  final String? shotType; // 'drive', 'cut', 'pull', etc.
  final bool isExtra; // true for wide, noBall, bye, legBye
  final String? extraType; // 'WD', 'NB', 'B', 'LB'
  final int? extraRuns; // Additional runs for extras

  CommentaryModel({
    required this.id,
    required this.matchId,
    required this.over,
    required this.ballType,
    required this.runs,
    this.wicketType,
    required this.strikerName,
    required this.bowlerName,
    this.nonStrikerName,
    required this.timestamp,
    required this.commentaryText,
    this.shotDirection,
    this.shotType,
    this.isExtra = false,
    this.extraType,
    this.extraRuns,
  });

  factory CommentaryModel.fromJson(Map<String, dynamic> json) {
    return CommentaryModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      over: (json['over'] as num).toDouble(),
      ballType: json['ball_type'] as String,
      runs: json['runs'] as int,
      wicketType: json['wicket_type'] as String?,
      strikerName: json['striker_name'] as String,
      bowlerName: json['bowler_name'] as String,
      nonStrikerName: json['non_striker_name'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      commentaryText: json['commentary_text'] as String,
      shotDirection: json['shot_direction'] as String?,
      shotType: json['shot_type'] as String?,
      isExtra: json['is_extra'] as bool? ?? false,
      extraType: json['extra_type'] as String?,
      extraRuns: json['extra_runs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'over': over,
      'ball_type': ballType,
      'runs': runs,
      'wicket_type': wicketType,
      'striker_name': strikerName,
      'bowler_name': bowlerName,
      'non_striker_name': nonStrikerName,
      'timestamp': timestamp.toIso8601String(),
      'commentary_text': commentaryText,
      'shot_direction': shotDirection,
      'shot_type': shotType,
      'is_extra': isExtra,
      'extra_type': extraType,
      'extra_runs': extraRuns,
    };
  }

  /// Helper to format over display (e.g., 5.3 -> "5.3")
  String get overDisplay {
    return over.toStringAsFixed(1).replaceAll('.0', '');
  }
}

