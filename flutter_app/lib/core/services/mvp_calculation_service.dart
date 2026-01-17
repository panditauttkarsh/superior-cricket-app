/// MVP Calculation Service for Superior Cricket App
/// Based on comprehensive cricket performance metrics
class MvpCalculationService {
  // Base conversion: 10 runs = 1 MVP Point
  static const double _runsPerMvpPoint = 10.0;

  // ==================== BATTING MVP CALCULATION ====================
  
  /// Par Score percentages by batting order (for 11-player team)
  static const Map<int, double> _parScorePercentages = {
    1: 0.14,  // 14%
    2: 0.13,  // 13%
    3: 0.13,  // 13%
    4: 0.12,  // 12%
    5: 0.11,  // 11%
    6: 0.09,  // 9%
    7: 0.07,  // 7%
    8: 0.06,  // 6%
    9: 0.04,  // 4%
    10: 0.03, // 3%
    11: 0.02, // 2%
  };

  /// Strike Rate bonus percentages by match type (in overs)
  static double _getSrBonusPercentage(int totalOvers) {
    if (totalOvers <= 20) return 0.08;      // 8%
    if (totalOvers <= 35) return 0.06;      // 6%
    if (totalOvers <= 50) return 0.04;      // 4%
    return 0.02;                             // 2% for 51+ overs
  }

  /// Calculate Batting MVP Points
  static double calculateBattingMvp({
    required int runsScored,
    required int ballsFaced,
    required int battingOrder,
    required int teamTotalRuns,
    required int teamTotalBalls,
  }) {
    if (runsScored == 0) return 0.0;

    // 1. Basic MVP Score (10 runs = 1 point)
    double basicMvpScore = runsScored / _runsPerMvpPoint;

    // 2. Calculate Strike Rate Bonus/Penalty
    double srBonus = 0.0;
    if (ballsFaced > 0 && teamTotalBalls > 0) {
      double playerSr = (runsScored / ballsFaced) * 100;
      double teamSr = (teamTotalRuns / teamTotalBalls) * 100;
      
      int totalOvers = (teamTotalBalls / 6).ceil();
      double srBonusPercentage = _getSrBonusPercentage(totalOvers);

      // Only reward, don't penalize (as per update)
      if (playerSr >= teamSr) {
        srBonus = ((playerSr / teamSr) * srBonusPercentage) * basicMvpScore;
      }
    }

    // Total Batting MVP Points
    return basicMvpScore + srBonus;
  }

  // ==================== BOWLING MVP CALCULATION ====================

  /// Base runs per wicket by match type (in overs)
  static double _getBaseRunsPerWicket(int totalOvers) {
    if (totalOvers <= 7) return 12.0;
    if (totalOvers <= 12) return 14.0;
    if (totalOvers <= 16) return 16.0;
    if (totalOvers <= 20) return 18.0;
    if (totalOvers <= 26) return 20.0;
    if (totalOvers <= 40) return 22.0;
    if (totalOvers <= 50) return 25.0;
    if (totalOvers <= 99) return 27.0;
    return 25.0; // Test match
  }

  /// Batting order strength percentages
  static double _getBatterStrength(int battingOrder) {
    if (battingOrder <= 4) return 1.0;   // 100% - Top order
    if (battingOrder <= 8) return 0.8;   // 80% - Middle order
    return 0.6;                           // 60% - Lower order
  }

  /// Wicket milestone bonuses
  static double _getWicketMilestoneBonus(int wickets) {
    if (wickets >= 10) return 1.5; // 15 runs = 1.5 points
    if (wickets >= 5) return 1.0;  // 10 runs = 1.0 point
    if (wickets >= 3) return 0.5;  // 5 runs = 0.5 point
    return 0.0;
  }

  /// Maiden overs to wicket conversion by match type
  static int _getMaidenOversPerWicket(int totalOvers) {
    if (totalOvers <= 7) return 1;
    if (totalOvers <= 26) return 2;
    if (totalOvers <= 50) return 3;
    return 6; // 51+ overs and Test
  }

  /// Calculate Bowling MVP Points
  static double calculateBowlingMvp({
    required List<Map<String, dynamic>> wickets, // List of wickets with details
    required int runsConceded,
    required int ballsBowled,
    required int maidenOvers,
    required int teamTotalRuns,
    required int teamTotalBalls,
    required int totalOvers,
  }) {
    if (wickets.isEmpty && maidenOvers == 0) return 0.0;

    double totalMvp = 0.0;
    double baseRunsPerWicket = _getBaseRunsPerWicket(totalOvers);

    // 1. Calculate wicket points
    for (var wicket in wickets) {
      int battingOrder = wicket['battingOrder'] ?? 5;
      String dismissalType = wicket['dismissalType'] ?? 'caught';
      int runsScored = wicket['runsScored'] ?? 0;

      // Base wicket value adjusted by batter strength
      double batterStrength = _getBatterStrength(battingOrder);
      double wicketValue = (baseRunsPerWicket * batterStrength) / _runsPerMvpPoint;

      // For assisted wickets (caught, stumped), bowler gets full points
      // Fielder gets additional 20%
      totalMvp += wicketValue;
    }

    // 2. Wicket milestone bonus
    totalMvp += _getWicketMilestoneBonus(wickets.length);

    // 3. Strike Rate Bonus (based on runs conceded vs team average)
    if (ballsBowled > 0 && teamTotalBalls > 0 && runsConceded > 0) {
      double playerSr = (runsConceded / ballsBowled) * 100;
      double teamSr = (teamTotalRuns / teamTotalBalls) * 100;
      
      double srBonusPercentage = _getSrBonusPercentage(totalOvers);

      // Only reward, don't penalize (as per update)
      if (playerSr <= teamSr) {
        double srBonus = ((teamSr / playerSr) * srBonusPercentage) * totalMvp;
        totalMvp += srBonus;
      }
    }

    // 4. Maiden Over Bonus
    if (maidenOvers > 0) {
      int maidensPerWicket = _getMaidenOversPerWicket(totalOvers);
      double maidenBonus = (maidenOvers / maidensPerWicket) * 
                          (baseRunsPerWicket / _runsPerMvpPoint);
      totalMvp += maidenBonus;
    }

    return totalMvp;
  }

  // ==================== FIELDING MVP CALCULATION ====================

  /// Calculate Fielding MVP Points
  static double calculateFieldingMvp({
    required List<Map<String, dynamic>> assists, // Catches, stumpings
    required List<Map<String, dynamic>> runOuts, // Direct hit run outs
    required int totalOvers,
  }) {
    double totalMvp = 0.0;
    double baseRunsPerWicket = _getBaseRunsPerWicket(totalOvers);

    // 1. Assisted wickets (catches, stumpings) - 20% of wicket value
    for (var assist in assists) {
      int battingOrder = assist['battingOrder'] ?? 5;
      double batterStrength = _getBatterStrength(battingOrder);
      double wicketValue = (baseRunsPerWicket * batterStrength) / _runsPerMvpPoint;
      
      // Fielder gets additional 20% for assisted wickets
      totalMvp += wicketValue * 0.20;
    }

    // 2. Direct hit run outs - Full wicket value
    for (var runOut in runOuts) {
      int battingOrder = runOut['battingOrder'] ?? 5;
      double batterStrength = _getBatterStrength(battingOrder);
      double wicketValue = (baseRunsPerWicket * batterStrength) / _runsPerMvpPoint;
      
      totalMvp += wicketValue;
    }

    return totalMvp;
  }

  // ==================== PLAYER OF THE MATCH ====================

  /// Determine Player of the Match
  static Map<String, dynamic>? determinePlayerOfTheMatch({
    required List<Map<String, dynamic>> allPlayerMvps,
    required String winningTeamId,
  }) {
    if (allPlayerMvps.isEmpty) return null;

    // Sort by MVP points descending
    allPlayerMvps.sort((a, b) => 
      (b['totalMvp'] as double).compareTo(a['totalMvp'] as double)
    );

    // Get top 3 players
    List<Map<String, dynamic>> top3 = allPlayerMvps.take(3).toList();

    // Check if any player from winning team is in top 3
    for (var player in top3) {
      if (player['teamId'] == winningTeamId) {
        return player;
      }
    }

    // If no winning team player in top 3, return the leader
    return allPlayerMvps.first;
  }

  /// Calculate total MVP for a player
  static double calculateTotalPlayerMvp({
    required double battingMvp,
    required double bowlingMvp,
    required double fieldingMvp,
  }) {
    return battingMvp + bowlingMvp + fieldingMvp;
  }

  /// Get MVP breakdown for display
  static Map<String, dynamic> getMvpBreakdown({
    required double battingMvp,
    required double bowlingMvp,
    required double fieldingMvp,
  }) {
    double total = battingMvp + bowlingMvp + fieldingMvp;
    
    return {
      'batting': battingMvp,
      'bowling': bowlingMvp,
      'fielding': fieldingMvp,
      'total': total,
      'battingPercentage': total > 0 ? (battingMvp / total) * 100 : 0.0,
      'bowlingPercentage': total > 0 ? (bowlingMvp / total) * 100 : 0.0,
      'fieldingPercentage': total > 0 ? (fieldingMvp / total) * 100 : 0.0,
    };
  }

  /// Format MVP points for display (2 decimal places)
  static String formatMvpPoints(double points) {
    return points.toStringAsFixed(2);
  }

  /// Get performance grade based on MVP points
  static String getPerformanceGrade(double mvpPoints) {
    if (mvpPoints >= 15.0) return 'Outstanding 🌟';
    if (mvpPoints >= 10.0) return 'Excellent 💎';
    if (mvpPoints >= 7.0) return 'Very Good 🔥';
    if (mvpPoints >= 5.0) return 'Good ⭐';
    if (mvpPoints >= 3.0) return 'Average 👍';
    return 'Below Average 📊';
  }
}
