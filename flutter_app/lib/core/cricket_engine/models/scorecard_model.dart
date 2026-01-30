import 'dart:math' as math;

/// Immutable scorecard model - complete match statistics
/// Calculated entirely from deliveries, never from stored stats
class ScorecardModel {
  final String teamName;
  final int totalRuns;
  final int totalWickets;
  final int totalLegalBalls; // Source of truth for overs calculation
  final List<BattingStat> battingStats;
  final List<BowlingStat> bowlingStats;
  final ExtrasBreakdown extras;
  final List<Partnership> partnerships;
  final List<FallOfWicket> fallOfWickets;
  final bool isSuperOver;
  final int? superOverNumber;

  const ScorecardModel({
    required this.teamName,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalLegalBalls,
    required this.battingStats,
    required this.bowlingStats,
    required this.extras,
    required this.partnerships,
    required this.fallOfWickets,
    this.isSuperOver = false,
    this.superOverNumber,
  });

  /// Calculate total overs from legal balls
  /// Returns decimal format: e.g., 11 balls = 1.5, 17 balls = 2.5
  double get totalOvers {
    return totalLegalBalls / 6.0;
  }

  /// Format overs for display (e.g., 1.5 -> "1.5", 2.833 -> "2.5")
  String get formattedOvers {
    final completeOvers = totalLegalBalls ~/ 6;
    final remainingBalls = totalLegalBalls % 6;
    return '$completeOvers.${remainingBalls}';
  }

  /// Calculate run rate
  double get runRate {
    if (totalLegalBalls == 0) return 0.0;
    return (totalRuns / totalLegalBalls) * 6.0;
  }
}

/// Batting statistics for a single player
class BattingStat {
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final String? dismissalType;
  final String? dismissedBy; // Bowler or fielder
  final bool isNotOut;
  final DateTime? startTime;
  final DateTime? endTime;

  const BattingStat({
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    this.dismissalType,
    this.dismissedBy,
    required this.isNotOut,
    this.startTime,
    this.endTime,
  });

  double get strikeRate {
    if (balls == 0) return 0.0;
    return (runs / balls) * 100.0;
  }

  int? get minutes {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!).inMinutes;
  }
}

/// Bowling statistics for a single bowler
class BowlingStat {
  final String bowlerName;
  final int legalBalls; // Source of truth - never use stored overs
  final int runs;
  final int wickets;
  final int maidens;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;

  const BowlingStat({
    required this.bowlerName,
    required this.legalBalls,
    required this.runs,
    required this.wickets,
    required this.maidens,
    required this.wides,
    required this.noBalls,
    required this.byes,
    required this.legByes,
  });

  /// Calculate overs from legal balls
  double get overs {
    return legalBalls / 6.0;
  }

  /// Format overs for display
  String get formattedOvers {
    final completeOvers = legalBalls ~/ 6;
    final remainingBalls = legalBalls % 6;
    return '$completeOvers.${remainingBalls}';
  }

  /// Calculate economy rate
  double get economy {
    if (legalBalls == 0) return 0.0;
    return (runs / legalBalls) * 6.0;
  }
}

/// Extras breakdown
class ExtrasBreakdown {
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final int penalty;

  const ExtrasBreakdown({
    required this.wides,
    required this.noBalls,
    required this.byes,
    required this.legByes,
    required this.penalty,
  });

  int get total => wides + noBalls + byes + legByes + penalty;
}

/// Partnership between two batsmen
class Partnership {
  final String player1;
  final String player2;
  final int runs;
  final int balls;
  final int? wicketNumber; // Wicket that ended this partnership

  const Partnership({
    required this.player1,
    required this.player2,
    required this.runs,
    required this.balls,
    this.wicketNumber,
  });

  double get runRate {
    if (balls == 0) return 0.0;
    return (runs / balls) * 6.0;
  }
}

/// Fall of wicket record
class FallOfWicket {
  final int wicketNumber;
  final String player;
  final int runs; // Team total when wicket fell
  final int legalBalls; // Legal balls when wicket fell
  final String dismissalType;
  final String? dismissedBy; // Bowler or fielder

  const FallOfWicket({
    required this.wicketNumber,
    required this.player,
    required this.runs,
    required this.legalBalls,
    required this.dismissalType,
    this.dismissedBy,
  });

  /// Format overs when wicket fell
  String get formattedOvers {
    final completeOvers = legalBalls ~/ 6;
    final remainingBalls = legalBalls % 6;
    return '$completeOvers.${remainingBalls}';
  }
}

