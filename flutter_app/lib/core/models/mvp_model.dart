/// Model for Player MVP (Most Valuable Player) data
class PlayerMvpModel {
  final String playerId;
  final String playerName;
  final String? playerAvatar;
  final String matchId;
  final String teamId;
  final String teamName;
  
  // MVP Scores
  final double battingMvp;
  final double bowlingMvp;
  final double fieldingMvp;
  final double totalMvp;
  
  // Performance breakdown
  final int runsScored;
  final int ballsFaced;
  final int wicketsTaken;
  final int runsConceded;
  final int ballsBowled;
  final int catches;
  final int runOuts;
  final int stumpings;
  
  // Additional stats
  final int battingOrder;
  final double? strikeRate;
  final double? bowlingEconomy;
  final String performanceGrade;
  
  // Timestamps
  final DateTime calculatedAt;
  final bool isPlayerOfTheMatch;

  const PlayerMvpModel({
    required this.playerId,
    required this.playerName,
    this.playerAvatar,
    required this.matchId,
    required this.teamId,
    required this.teamName,
    required this.battingMvp,
    required this.bowlingMvp,
    required this.fieldingMvp,
    required this.totalMvp,
    required this.runsScored,
    required this.ballsFaced,
    required this.wicketsTaken,
    required this.runsConceded,
    required this.ballsBowled,
    required this.catches,
    required this.runOuts,
    required this.stumpings,
    required this.battingOrder,
    this.strikeRate,
    this.bowlingEconomy,
    required this.performanceGrade,
    required this.calculatedAt,
    this.isPlayerOfTheMatch = false,
  });

  /// Create from JSON
  factory PlayerMvpModel.fromJson(Map<String, dynamic> json) {
    return PlayerMvpModel(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      playerAvatar: json['player_avatar'] as String?,
      matchId: json['match_id'] as String,
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      battingMvp: (json['batting_mvp'] as num).toDouble(),
      bowlingMvp: (json['bowling_mvp'] as num).toDouble(),
      fieldingMvp: (json['fielding_mvp'] as num).toDouble(),
      totalMvp: (json['total_mvp'] as num).toDouble(),
      runsScored: json['runs_scored'] as int,
      ballsFaced: json['balls_faced'] as int,
      wicketsTaken: json['wickets_taken'] as int,
      runsConceded: json['runs_conceded'] as int,
      ballsBowled: json['balls_bowled'] as int,
      catches: json['catches'] as int,
      runOuts: json['run_outs'] as int,
      stumpings: json['stumpings'] as int,
      battingOrder: json['batting_order'] as int,
      strikeRate: json['strike_rate'] != null 
          ? (json['strike_rate'] as num).toDouble() 
          : null,
      bowlingEconomy: json['bowling_economy'] != null 
          ? (json['bowling_economy'] as num).toDouble() 
          : null,
      performanceGrade: json['performance_grade'] as String,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
      isPlayerOfTheMatch: json['is_player_of_the_match'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'player_id': playerId,
      'player_name': playerName,
      'player_avatar': playerAvatar,
      'match_id': matchId,
      'team_id': teamId,
      'team_name': teamName,
      'batting_mvp': battingMvp,
      'bowling_mvp': bowlingMvp,
      'fielding_mvp': fieldingMvp,
      'total_mvp': totalMvp,
      'runs_scored': runsScored,
      'balls_faced': ballsFaced,
      'wickets_taken': wicketsTaken,
      'runs_conceded': runsConceded,
      'balls_bowled': ballsBowled,
      'catches': catches,
      'run_outs': runOuts,
      'stumpings': stumpings,
      'batting_order': battingOrder,
      'strike_rate': strikeRate,
      'bowling_economy': bowlingEconomy,
      'performance_grade': performanceGrade,
      'calculated_at': calculatedAt.toIso8601String(),
      'is_player_of_the_match': isPlayerOfTheMatch,
    };
  }

  /// Create a copy with modified fields
  PlayerMvpModel copyWith({
    String? playerId,
    String? playerName,
    String? playerAvatar,
    String? matchId,
    String? teamId,
    String? teamName,
    double? battingMvp,
    double? bowlingMvp,
    double? fieldingMvp,
    double? totalMvp,
    int? runsScored,
    int? ballsFaced,
    int? wicketsTaken,
    int? runsConceded,
    int? ballsBowled,
    int? catches,
    int? runOuts,
    int? stumpings,
    int? battingOrder,
    double? strikeRate,
    double? bowlingEconomy,
    String? performanceGrade,
    DateTime? calculatedAt,
    bool? isPlayerOfTheMatch,
  }) {
    return PlayerMvpModel(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerAvatar: playerAvatar ?? this.playerAvatar,
      matchId: matchId ?? this.matchId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      battingMvp: battingMvp ?? this.battingMvp,
      bowlingMvp: bowlingMvp ?? this.bowlingMvp,
      fieldingMvp: fieldingMvp ?? this.fieldingMvp,
      totalMvp: totalMvp ?? this.totalMvp,
      runsScored: runsScored ?? this.runsScored,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      wicketsTaken: wicketsTaken ?? this.wicketsTaken,
      runsConceded: runsConceded ?? this.runsConceded,
      ballsBowled: ballsBowled ?? this.ballsBowled,
      catches: catches ?? this.catches,
      runOuts: runOuts ?? this.runOuts,
      stumpings: stumpings ?? this.stumpings,
      battingOrder: battingOrder ?? this.battingOrder,
      strikeRate: strikeRate ?? this.strikeRate,
      bowlingEconomy: bowlingEconomy ?? this.bowlingEconomy,
      performanceGrade: performanceGrade ?? this.performanceGrade,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      isPlayerOfTheMatch: isPlayerOfTheMatch ?? this.isPlayerOfTheMatch,
    );
  }

  /// Get MVP breakdown percentages
  Map<String, double> getMvpBreakdown() {
    if (totalMvp == 0) {
      return {
        'batting': 0.0,
        'bowling': 0.0,
        'fielding': 0.0,
      };
    }

    return {
      'batting': (battingMvp / totalMvp) * 100,
      'bowling': (bowlingMvp / totalMvp) * 100,
      'fielding': (fieldingMvp / totalMvp) * 100,
    };
  }

  /// Get formatted MVP score
  String get formattedMvpScore => totalMvp.toStringAsFixed(2);

  /// Get performance emoji
  String get performanceEmoji {
    if (totalMvp >= 15.0) return '🌟';
    if (totalMvp >= 10.0) return '💎';
    if (totalMvp >= 7.0) return '🔥';
    if (totalMvp >= 5.0) return '⭐';
    if (totalMvp >= 3.0) return '👍';
    return '📊';
  }

  /// Check if player contributed significantly
  bool get hasSignificantContribution => totalMvp >= 3.0;

  @override
  String toString() {
    return 'PlayerMvpModel(player: $playerName, totalMvp: $formattedMvpScore, '
           'batting: ${battingMvp.toStringAsFixed(2)}, '
           'bowling: ${bowlingMvp.toStringAsFixed(2)}, '
           'fielding: ${fieldingMvp.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PlayerMvpModel &&
      other.playerId == playerId &&
      other.matchId == matchId;
  }

  @override
  int get hashCode => playerId.hashCode ^ matchId.hashCode;
}

/// Model for Match MVP Summary
class MatchMvpSummary {
  final String matchId;
  final PlayerMvpModel? playerOfTheMatch;
  final List<PlayerMvpModel> topPerformers;
  final String winningTeamId;
  final DateTime calculatedAt;

  const MatchMvpSummary({
    required this.matchId,
    this.playerOfTheMatch,
    required this.topPerformers,
    required this.winningTeamId,
    required this.calculatedAt,
  });

  factory MatchMvpSummary.fromJson(Map<String, dynamic> json) {
    return MatchMvpSummary(
      matchId: json['match_id'] as String,
      playerOfTheMatch: json['player_of_the_match'] != null
          ? PlayerMvpModel.fromJson(json['player_of_the_match'])
          : null,
      topPerformers: (json['top_performers'] as List<dynamic>)
          .map((e) => PlayerMvpModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      winningTeamId: json['winning_team_id'] as String,
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': matchId,
      'player_of_the_match': playerOfTheMatch?.toJson(),
      'top_performers': topPerformers.map((e) => e.toJson()).toList(),
      'winning_team_id': winningTeamId,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }
}
