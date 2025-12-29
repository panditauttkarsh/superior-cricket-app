/// Over Summary Model for displaying over-level summaries
class OverSummaryModel {
  final String id;
  final String matchId;
  final int overNumber; // e.g., 16
  final List<int> ballRuns; // [4, 0, 0, 4, 6, 0] - runs for each ball
  final List<bool> ballWickets; // [false, false, false, false, false, false] - wicket on each ball
  final int runsInOver;
  final int wicketsInOver;
  final int totalScore; // Total score after this over
  final int totalWickets; // Total wickets after this over
  final DateTime timestamp;

  OverSummaryModel({
    required this.id,
    required this.matchId,
    required this.overNumber,
    required this.ballRuns,
    required this.ballWickets,
    required this.runsInOver,
    required this.wicketsInOver,
    required this.totalScore,
    required this.totalWickets,
    required this.timestamp,
  });

  factory OverSummaryModel.fromJson(Map<String, dynamic> json) {
    return OverSummaryModel(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      overNumber: json['over_number'] as int,
      ballRuns: List<int>.from(json['ball_runs'] as List),
      ballWickets: List<bool>.from(json['ball_wickets'] as List),
      runsInOver: json['runs_in_over'] as int,
      wicketsInOver: json['wickets_in_over'] as int,
      totalScore: json['total_score'] as int,
      totalWickets: json['total_wickets'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'over_number': overNumber,
      'ball_runs': ballRuns,
      'ball_wickets': ballWickets,
      'runs_in_over': runsInOver,
      'wickets_in_over': wicketsInOver,
      'total_score': totalScore,
      'total_wickets': totalWickets,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

