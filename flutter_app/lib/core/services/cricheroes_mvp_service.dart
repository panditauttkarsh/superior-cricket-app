/// CricHeroes MVP Calculation Service
/// Exact implementation of CricHeroes MVP algorithm
class CricHeroesMvpService {
  // Base conversion: 10 runs = 1 MVP Point
  static const double _runsPerMvpPoint = 10.0;

  // ==================== BATTING MVP CALCULATION ====================

  /// Strike Rate bonus percentages by match type (in overs)
  static double _getSrBonusPercentage(int totalOvers) {
    if (totalOvers <= 20) return 0.08;      // 8%
    if (totalOvers <= 35) return 0.06;      // 6%
    if (totalOvers <= 50) return 0.04;      // 4%
    return 0.02;                             // 2% for 51+ overs / Test
  }

  /// Calculate Batting MVP Points
  /// Formula: Total Batting MVP = Basic MVP Score + SR Bonus
  static double calculateBattingMvp({
    required int runsScored,
    required int ballsFaced,
    required int teamTotalRuns,
    required int teamTotalBalls,
    required int totalOvers,
  }) {
    if (runsScored == 0 || ballsFaced == 0) return 0.0;

    // 1. Basic MVP Score (10 runs = 1 point)
    double basicMvpScore = runsScored / _runsPerMvpPoint;

    // 2. Calculate Strike Rate Bonus
    // Formula: ((Player SR / Team SR) * (if(Player SR - Team SR) ≥0 then 1 else 0) * SR Bonus %) * Base MVP Score
    double srBonus = 0.0;
    if (teamTotalBalls > 0) {
      double playerSr = (runsScored / ballsFaced) * 100;
      double teamSr = (teamTotalRuns / teamTotalBalls) * 100;
      
      double srBonusPercentage = _getSrBonusPercentage(totalOvers);

      // Only reward if player SR >= team SR (no penalty)
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
    if (battingOrder <= 4) return 1.0;   // 100% - Top order (1-4)
    if (battingOrder <= 8) return 0.8;   // 80% - Middle order (5-8)
    return 0.6;                           // 60% - Lower order (9-11)
  }

  /// Wicket milestone bonuses
  /// 3 wickets > 5 runs > 0.5 point
  /// 5 wickets > 10 runs > 1 point
  /// 10 wickets > 15 runs > 1.5 points
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
  /// Formula: Total Bowling MVP = Wicket Base MVP + Additional Wicket Bonus + SR Bonus + Maiden Over Bonus
  static double calculateBowlingMvp({
    required List<Map<String, dynamic>> wickets, // List of wickets with battingOrder
    required int runsConceded,
    required int ballsBowled,
    required int maidenOvers,
    required int teamTotalRuns,
    required int teamTotalBalls,
    required int totalOvers,
  }) {
    if (wickets.isEmpty && maidenOvers == 0) return 0.0;

    double baseRunsPerWicket = _getBaseRunsPerWicket(totalOvers);
    double totalMvp = 0.0;

    // 1. Calculate Wicket Base MVP Points
    // Each wicket value = (Base Runs Per Wicket * Batter Strength) / 10
    for (var wicket in wickets) {
      int battingOrder = wicket['battingOrder'] as int? ?? 5;
      double batterStrength = _getBatterStrength(battingOrder);
      double wicketValue = (baseRunsPerWicket * batterStrength) / _runsPerMvpPoint;
      totalMvp += wicketValue;
    }

    // 2. Additional Wicket Bonus (milestone bonus)
    totalMvp += _getWicketMilestoneBonus(wickets.length);

    // 3. Strike Rate Bonus
    // Formula: ((Team SR / Player SR) * (if(Team SR - Player SR) ≥0 then 1 else 0) * SR Bonus %) * Total MVP
    if (ballsBowled > 0 && teamTotalBalls > 0) {
      double playerSr = (runsConceded / ballsBowled) * 100;
      double teamSr = (teamTotalRuns / teamTotalBalls) * 100;
      
      double srBonusPercentage = _getSrBonusPercentage(totalOvers);

      // Only reward if team SR >= player SR (economical bowling)
      if (teamSr >= playerSr) {
        double srBonus = ((teamSr / playerSr) * srBonusPercentage) * totalMvp;
        totalMvp += srBonus;
      }
    }

    // 4. Maiden Over Bonus
    // In case of maiden overs, we can't calculate SR bonus as Player SR will be 0
    // So we give maiden over bonus based on match type
    if (maidenOvers > 0) {
      int maidensPerWicket = _getMaidenOversPerWicket(totalOvers);
      // Maiden bonus = (maidenOvers / maidensPerWicket) * (baseRunsPerWicket / 10)
      double maidenBonus = (maidenOvers / maidensPerWicket) * 
                          (baseRunsPerWicket / _runsPerMvpPoint);
      totalMvp += maidenBonus;
    }

    return totalMvp;
  }

  // ==================== FIELDING MVP CALCULATION ====================

  /// Calculate Fielding MVP Points
  /// - Assisted wickets (Catch, Stumping): 20% of wicket MVP points
  /// - Unassisted wickets (Run Out - direct hit): Full wicket MVP points
  static double calculateFieldingMvp({
    required List<Map<String, dynamic>> assists, // Catches, stumpings with battingOrder
    required List<Map<String, dynamic>> runOuts, // Direct hit run outs with battingOrder
    required int totalOvers,
  }) {
    double totalMvp = 0.0;
    double baseRunsPerWicket = _getBaseRunsPerWicket(totalOvers);

    // 1. Assisted wickets (catches, stumpings) - 20% of wicket value
    for (var assist in assists) {
      int battingOrder = assist['battingOrder'] as int? ?? 5;
      double batterStrength = _getBatterStrength(battingOrder);
      double wicketValue = (baseRunsPerWicket * batterStrength) / _runsPerMvpPoint;
      
      // Fielder gets additional 20% for assisted wickets
      totalMvp += wicketValue * 0.20;
    }

    // 2. Direct hit run outs - Full wicket value
    // (Par Score Bonus removed as per update)
    for (var runOut in runOuts) {
      int battingOrder = runOut['battingOrder'] as int? ?? 5;
      double batterStrength = _getBatterStrength(battingOrder);
      double wicketValue = (baseRunsPerWicket * batterStrength) / _runsPerMvpPoint;
      
      totalMvp += wicketValue;
    }

    return totalMvp;
  }

  // ==================== PLAYER OF THE MATCH ====================

  /// Determine Player of the Match
  /// - Winning team players get precedence
  /// - If winning team player in Top 3 MVP list, he becomes Player of the Match
  /// - If no winning team player in Top 3, the leader becomes Player of the Match
  static Map<String, dynamic>? determinePlayerOfTheMatch({
    required List<Map<String, dynamic>> allPlayerMvps,
    required String? winningTeamId,
  }) {
    if (allPlayerMvps.isEmpty) return null;

    // Sort by total MVP points descending
    allPlayerMvps.sort((a, b) => 
      (b['totalMvp'] as double).compareTo(a['totalMvp'] as double)
    );

    // Get top 3 players
    List<Map<String, dynamic>> top3 = allPlayerMvps.take(3).toList();

    // Check if any player from winning team is in top 3
    if (winningTeamId != null) {
      for (var player in top3) {
        if (player['teamId'] == winningTeamId) {
          return player;
        }
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

  /// Format MVP points for display (3 decimal places for accuracy)
  static String formatMvpPoints(double points) {
    return points.toStringAsFixed(3);
  }
}

