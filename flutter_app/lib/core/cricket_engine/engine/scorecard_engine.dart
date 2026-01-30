import '../models/delivery_model.dart';
import '../models/scorecard_model.dart';

/// Production-grade cricket scorecard calculation engine
/// 
/// This engine calculates all statistics from delivery data only.
/// It never relies on stored stats - everything is recalculated from deliveries.
/// 
/// Handles all ICC/BCCI rules:
/// - Legal ball counting (wides/no-balls don't count)
/// - Correct over calculations (always from legal balls)
/// - All dismissal types
/// - Partnerships since last wicket
/// - Fall-of-wicket timeline
/// - Extras breakdown
/// - Super overs
/// - No-ball run distribution
/// - Run-outs on no-balls
class ScorecardEngine {
  /// Calculate complete scorecard from deliveries
  /// 
  /// [deliveries] - List of all deliveries for this innings
  /// [teamName] - Name of the batting team
  /// [isSuperOver] - Whether this is a super over
  /// [superOverNumber] - Super over number (if applicable)
  static ScorecardModel calculateScorecard({
    required List<DeliveryModel> deliveries,
    required String teamName,
    bool isSuperOver = false,
    int? superOverNumber,
  }) {
    if (deliveries.isEmpty) {
      return ScorecardModel(
        teamName: teamName,
        totalRuns: 0,
        totalWickets: 0,
        totalLegalBalls: 0,
        battingStats: [],
        bowlingStats: [],
        extras: const ExtrasBreakdown(
          wides: 0,
          noBalls: 0,
          byes: 0,
          legByes: 0,
          penalty: 0,
        ),
        partnerships: [],
        fallOfWickets: [],
        isSuperOver: isSuperOver,
        superOverNumber: superOverNumber,
      );
    }

    // Deduplicate deliveries by deliveryNumber
    final uniqueDeliveries = _deduplicateDeliveries(deliveries);

    // Calculate all statistics
    final battingStats = _calculateBattingStats(uniqueDeliveries);
    final bowlingStats = _calculateBowlingStats(uniqueDeliveries);
    final extras = _calculateExtras(uniqueDeliveries);
    final partnerships = _calculatePartnerships(uniqueDeliveries);
    final fallOfWickets = _calculateFallOfWickets(uniqueDeliveries);

    // Calculate totals
    final totalRuns = uniqueDeliveries.last.teamTotal;
    final totalWickets = uniqueDeliveries
        .where((d) => d.wicketType != null)
        .length;
    final totalLegalBalls = uniqueDeliveries
        .where((d) => d.isLegalBall)
        .length;

    return ScorecardModel(
      teamName: teamName,
      totalRuns: totalRuns,
      totalWickets: totalWickets,
      totalLegalBalls: totalLegalBalls,
      battingStats: battingStats,
      bowlingStats: bowlingStats,
      extras: extras,
      partnerships: partnerships,
      fallOfWickets: fallOfWickets,
      isSuperOver: isSuperOver,
      superOverNumber: superOverNumber,
    );
  }

  /// Deduplicate deliveries by deliveryNumber
  static List<DeliveryModel> _deduplicateDeliveries(
    List<DeliveryModel> deliveries,
  ) {
    final seen = <int>{};
    final unique = <DeliveryModel>[];

    for (final delivery in deliveries) {
      if (!seen.contains(delivery.deliveryNumber)) {
        seen.add(delivery.deliveryNumber);
        unique.add(delivery);
      }
    }

    // Sort by delivery number to ensure chronological order
    unique.sort((a, b) => a.deliveryNumber.compareTo(b.deliveryNumber));
    return unique;
  }

  /// Calculate batting statistics from deliveries
  static List<BattingStat> _calculateBattingStats(
    List<DeliveryModel> deliveries,
  ) {
    final playerStats = <String, _PlayerBattingAccumulator>{};
    final dismissedPlayers = <String>{};
    final dismissalTypes = <String, String>{};
    final dismissedBy = <String, String>{};
    final playerStartTimes = <String, DateTime>{};
    final playerEndTimes = <String, DateTime>{};

    // Track current striker/non-striker for start times
    String? currentStriker;
    String? currentNonStriker;

    for (final delivery in deliveries) {
      // Track start time when player first faces a ball
      if (delivery.striker.isNotEmpty) {
        if (!playerStartTimes.containsKey(delivery.striker)) {
          playerStartTimes[delivery.striker] = delivery.timestamp;
        }
        currentStriker = delivery.striker;
      }
      if (delivery.nonStriker.isNotEmpty) {
        if (!playerStartTimes.containsKey(delivery.nonStriker)) {
          playerStartTimes[delivery.nonStriker] = delivery.timestamp;
        }
        currentNonStriker = delivery.nonStriker;
      }

      // Initialize player stats if needed
      if (delivery.striker.isNotEmpty &&
          !playerStats.containsKey(delivery.striker)) {
        playerStats[delivery.striker] = _PlayerBattingAccumulator(
          playerName: delivery.striker,
        );
      }

      final stats = playerStats[delivery.striker];
      if (stats == null) continue;

      // Count runs (only off the bat, excluding extras)
      if (delivery.extraType == null) {
        // Regular ball - runs off bat
        stats.runs += delivery.runs;
        if (delivery.runs == 4) stats.fours++;
        if (delivery.runs == 6) stats.sixes++;
      } else if (delivery.extraType == ExtraType.noBall) {
        // No-ball - runs off bat count
        stats.runs += delivery.runs;
        if (delivery.runs == 4) stats.fours++;
        if (delivery.runs == 6) stats.sixes++;
      }
      // For wides, byes, leg-byes: runs don't count to batsman

      // Count balls faced (only legal balls)
      if (delivery.isLegalBall) {
        stats.balls++;
      }

      // Track dismissals
      if (delivery.wicketType != null && delivery.dismissedPlayer != null) {
        final dismissed = delivery.dismissedPlayer!;
        dismissedPlayers.add(dismissed);
        dismissalTypes[dismissed] = delivery.wicketType!;
        if (delivery.fielder != null) {
          dismissedBy[dismissed] = delivery.fielder!;
        } else if (delivery.bowler.isNotEmpty) {
          dismissedBy[dismissed] = delivery.bowler;
        }
        playerEndTimes[dismissed] = delivery.timestamp;
      }
    }

    // Convert to BattingStat list
    return playerStats.values.map((acc) {
      final isDismissed = dismissedPlayers.contains(acc.playerName);
      return BattingStat(
        playerName: acc.playerName,
        runs: acc.runs,
        balls: acc.balls,
        fours: acc.fours,
        sixes: acc.sixes,
        dismissalType: dismissalTypes[acc.playerName],
        dismissedBy: dismissedBy[acc.playerName],
        isNotOut: !isDismissed,
        startTime: playerStartTimes[acc.playerName],
        endTime: playerEndTimes[acc.playerName],
      );
    }).toList()
      ..sort((a, b) {
        // Sort by dismissal status (out first), then by runs
        if (a.isNotOut != b.isNotOut) {
          return a.isNotOut ? 1 : -1;
        }
        return b.runs.compareTo(a.runs);
      });
  }

  /// Calculate bowling statistics from deliveries
  static List<BowlingStat> _calculateBowlingStats(
    List<DeliveryModel> deliveries,
  ) {
    final bowlerStats = <String, _BowlerAccumulator>{};
    final overRuns = <int, int>{}; // over -> runs
    final overLegalBalls = <int, int>{}; // over -> legal balls
    final overBowler = <int, String>{}; // over -> bowler

    for (final delivery in deliveries) {
      if (delivery.bowler.isEmpty) continue;

      // Initialize bowler stats
      if (!bowlerStats.containsKey(delivery.bowler)) {
        bowlerStats[delivery.bowler] = _BowlerAccumulator(
          bowlerName: delivery.bowler,
        );
      }

      final stats = bowlerStats[delivery.bowler]!;

      // Count legal balls (CRITICAL: only legal balls count)
      if (delivery.isLegalBall) {
        stats.legalBalls++;
      }

      // Count runs conceded
      stats.runs += delivery.bowlerRuns;

      // Count wickets (only credited wickets)
      if (delivery.isWicketCreditedToBowler) {
        stats.wickets++;
      }

      // Count extras
      switch (delivery.extraType) {
        case ExtraType.wide:
          stats.wides += delivery.extraRuns ?? 0;
          break;
        case ExtraType.noBall:
          stats.noBalls += delivery.extraRuns ?? 0;
          break;
        case ExtraType.bye:
          stats.byes += delivery.extraRuns ?? 0;
          break;
        case ExtraType.legBye:
          stats.legByes += delivery.extraRuns ?? 0;
          break;
        case null:
          break;
        case ExtraType.penalty:
          break;
      }

      // Track over data for maiden calculation
      overBowler[delivery.over] = delivery.bowler;
      overRuns[delivery.over] =
          (overRuns[delivery.over] ?? 0) + delivery.bowlerRuns;
      if (delivery.isLegalBall) {
        overLegalBalls[delivery.over] =
            (overLegalBalls[delivery.over] ?? 0) + 1;
      }
    }

    // Calculate maidens (6 legal balls, 0 runs)
    for (final overNum in overBowler.keys) {
      final bowlerName = overBowler[overNum]!;
      final runsConceded = overRuns[overNum] ?? 0;
      final legalBalls = overLegalBalls[overNum] ?? 0;

      if (legalBalls == 6 && runsConceded == 0) {
        bowlerStats[bowlerName]?.maidens++;
      }
    }

    // Convert to BowlingStat list
    return bowlerStats.values.map((acc) {
      return BowlingStat(
        bowlerName: acc.bowlerName,
        legalBalls: acc.legalBalls,
        runs: acc.runs,
        wickets: acc.wickets,
        maidens: acc.maidens,
        wides: acc.wides,
        noBalls: acc.noBalls,
        byes: acc.byes,
        legByes: acc.legByes,
      );
    }).toList()
      ..sort((a, b) => b.overs.compareTo(a.overs));
  }

  /// Calculate extras breakdown
  static ExtrasBreakdown _calculateExtras(List<DeliveryModel> deliveries) {
    int wides = 0;
    int noBalls = 0;
    int byes = 0;
    int legByes = 0;
    int penalty = 0;

    for (final delivery in deliveries) {
      if (delivery.extraType == null) continue;

      final extraRuns = delivery.extraRuns ?? 0;

      switch (delivery.extraType) {
        case ExtraType.wide:
          wides += extraRuns;
          break;
        case ExtraType.noBall:
          noBalls += extraRuns;
          break;
        case ExtraType.bye:
          byes += extraRuns;
          break;
        case ExtraType.legBye:
          legByes += extraRuns;
          break;
        case ExtraType.penalty:
          penalty += extraRuns;
          break;
        case null:
          break;
      }
    }

    return ExtrasBreakdown(
      wides: wides,
      noBalls: noBalls,
      byes: byes,
      legByes: legByes,
      penalty: penalty,
    );
  }

  /// Calculate partnerships
  static List<Partnership> _calculatePartnerships(
    List<DeliveryModel> deliveries,
  ) {
    final partnerships = <Partnership>[];
    String? currentPlayer1;
    String? currentPlayer2;
    int partnershipRuns = 0;
    int partnershipBalls = 0;
    int? wicketNumber;

    for (final delivery in deliveries) {
      // Check if partnership changed (new batsman or wicket)
      final isNewPartnership = currentPlayer1 == null ||
          currentPlayer2 == null ||
          (delivery.striker != currentPlayer1 &&
              delivery.striker != currentPlayer2) ||
          (delivery.nonStriker != currentPlayer1 &&
              delivery.nonStriker != currentPlayer2) ||
          delivery.wicketType != null;

      if (isNewPartnership && currentPlayer1 != null && currentPlayer2 != null) {
        // Save previous partnership
        partnerships.add(Partnership(
          player1: currentPlayer1,
          player2: currentPlayer2,
          runs: partnershipRuns,
          balls: partnershipBalls,
          wicketNumber: wicketNumber,
        ));
        partnershipRuns = 0;
        partnershipBalls = 0;
        wicketNumber = null;
      }

      // Update current partnership
      if (delivery.striker.isNotEmpty && delivery.nonStriker.isNotEmpty) {
        currentPlayer1 = delivery.striker;
        currentPlayer2 = delivery.nonStriker;
      }

      // Add runs and balls to partnership
      partnershipRuns += delivery.totalRuns;
      if (delivery.isLegalBall) {
        partnershipBalls++;
      }

      // Track wicket that ended partnership
      if (delivery.wicketType != null) {
        wicketNumber = deliveries
            .where((d) => d.wicketType != null)
            .takeWhile((d) => d.deliveryNumber <= delivery.deliveryNumber)
            .length;
      }
    }

    // Add final partnership
    if (currentPlayer1 != null && currentPlayer2 != null) {
      partnerships.add(Partnership(
        player1: currentPlayer1!,
        player2: currentPlayer2!,
        runs: partnershipRuns,
        balls: partnershipBalls,
        wicketNumber: wicketNumber,
      ));
    }

    return partnerships;
  }

  /// Calculate fall of wickets
  static List<FallOfWicket> _calculateFallOfWickets(
    List<DeliveryModel> deliveries,
  ) {
    final fallOfWickets = <FallOfWicket>[];
    int wicketNumber = 0;
    int legalBallsCount = 0;

    for (final delivery in deliveries) {
      if (delivery.isLegalBall) {
        legalBallsCount++;
      }

      if (delivery.wicketType != null && delivery.dismissedPlayer != null) {
        wicketNumber++;
        fallOfWickets.add(FallOfWicket(
          wicketNumber: wicketNumber,
          player: delivery.dismissedPlayer!,
          runs: delivery.teamTotal,
          legalBalls: legalBallsCount,
          dismissalType: delivery.wicketType!,
          dismissedBy: delivery.fielder ?? delivery.bowler,
        ));
      }
    }

    return fallOfWickets;
  }
}

/// Internal accumulator for batting stats
class _PlayerBattingAccumulator {
  final String playerName;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;

  _PlayerBattingAccumulator({required this.playerName});
}

/// Internal accumulator for bowling stats
class _BowlerAccumulator {
  final String bowlerName;
  int legalBalls = 0;
  int runs = 0;
  int wickets = 0;
  int maidens = 0;
  int wides = 0;
  int noBalls = 0;
  int byes = 0;
  int legByes = 0;

  _BowlerAccumulator({required this.bowlerName});
}

