import '../models/delivery_model.dart';
import '../models/scorecard_model.dart';

/// Adapter that transforms ScorecardEngine output to match existing UI format
/// This ensures the UI remains unchanged while using the new engine
class ScorecardAdapter {
  /// Convert ScorecardModel to the format expected by existing UI
  /// Returns a map matching the structure used by _buildBattingStatsFromScorecard
  /// and _buildBowlingStatsFromScorecard
  static Map<String, dynamic> toUIScorecardFormat(ScorecardModel scorecard) {
    return {
      'team_name': scorecard.teamName,
      'total_runs': scorecard.totalRuns,
      'total_wickets': scorecard.totalWickets,
      'total_overs': scorecard.totalOvers,
      'total_legal_balls': scorecard.totalLegalBalls,
      'batting_stats': scorecard.battingStats.map((s) => _battingStatToMap(s)).toList(),
      'bowling_stats': scorecard.bowlingStats.map((s) => _bowlingStatToMap(s)).toList(),
      'extras': {
        'wides': scorecard.extras.wides,
        'no_balls': scorecard.extras.noBalls,
        'byes': scorecard.extras.byes,
        'leg_byes': scorecard.extras.legByes,
        'penalty': scorecard.extras.penalty,
        'total': scorecard.extras.total,
      },
      'partnerships': scorecard.partnerships.map((p) => _partnershipToMap(p)).toList(),
      'fall_of_wickets': scorecard.fallOfWickets.map((f) => _fallOfWicketToMap(f)).toList(),
      'is_super_over': scorecard.isSuperOver,
      'super_over_number': scorecard.superOverNumber,
    };
  }

  /// Convert to format compatible with _PlayerBattingStat
  static Map<String, dynamic> _battingStatToMap(BattingStat stat) {
    return {
      'playerName': stat.playerName,
      'runs': stat.runs,
      'balls': stat.balls,
      'fours': stat.fours,
      'sixes': stat.sixes,
      'strikeRate': stat.strikeRate,
      'dismissal': stat.dismissalType,
      'dismissedBy': stat.dismissedBy,
      'isNotOut': stat.isNotOut,
      'minutes': stat.minutes,
    };
  }

  /// Convert to format compatible with _PlayerBowlingStat
  static Map<String, dynamic> _bowlingStatToMap(BowlingStat stat) {
    return {
      'bowlerName': stat.bowlerName,
      'overs': stat.overs,
      'formattedOvers': stat.formattedOvers,
      'legalBalls': stat.legalBalls,
      'maidens': stat.maidens,
      'runs': stat.runs,
      'wickets': stat.wickets,
      'economy': stat.economy,
      'wides': stat.wides,
      'noBalls': stat.noBalls,
      'byes': stat.byes,
      'legByes': stat.legByes,
    };
  }

  static Map<String, dynamic> _partnershipToMap(Partnership p) {
    return {
      'player1': p.player1,
      'player2': p.player2,
      'runs': p.runs,
      'balls': p.balls,
      'runRate': p.runRate,
      'wicketNumber': p.wicketNumber,
    };
  }

  static Map<String, dynamic> _fallOfWicketToMap(FallOfWicket f) {
    return {
      'wicketNumber': f.wicketNumber,
      'player': f.player,
      'runs': f.runs,
      'legalBalls': f.legalBalls,
      'formattedOvers': f.formattedOvers,
      'dismissalType': f.dismissalType,
      'dismissedBy': f.dismissedBy,
    };
  }

  /// Convert legacy delivery JSON to DeliveryModel
  /// Uses DeliveryModel.fromJson for consistency
  static List<DeliveryModel> deliveriesFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) {
      final d = json as Map<String, dynamic>;
      // Ensure all required fields are present
      return DeliveryModel.fromJson({
        'deliveryNumber': d['deliveryNumber'] ?? 0,
        'over': d['over'] ?? 0,
        'ball': d['ball'] ?? 1,
        'striker': d['striker'] ?? '',
        'nonStriker': d['nonStriker'] ?? '',
        'bowler': d['bowler'] ?? '',
        'runs': d['runs'] ?? 0,
        'teamTotal': d['teamTotal'] ?? 0,
        'wicketType': d['wicketType'],
        'dismissedPlayer': d['dismissedPlayer'] ?? (d['wicketType'] != null ? d['striker'] : null),
        'fielder': d['fielder'],
        'assistFielder': d['assistFielder'],
        'extraType': d['extraType'],
        'extraRuns': d['extraRuns'],
        'isLegalBall': d['isLegalBall'] ?? true,
        'isShortRun': d['isShortRun'] ?? false,
        'timestamp': d['timestamp'] ?? DateTime.now().toIso8601String(),
      });
    }).toList();
  }
}

