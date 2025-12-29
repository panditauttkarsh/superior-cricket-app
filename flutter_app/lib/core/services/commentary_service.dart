import '../models/commentary_model.dart';

/// Service for generating ball-by-ball commentary text
class CommentaryService {
  /// Generate commentary text based on scoring event
  static String generateCommentary({
    required double over,
    required String ballType,
    required int runs,
    required String strikerName,
    required String bowlerName,
    String? wicketType,
    String? shotDirection,
    String? shotType,
    bool isExtra = false,
    String? extraType,
    int? extraRuns,
  }) {
    final overStr = over.toStringAsFixed(1).replaceAll('.0', '');
    
    // Wicket commentary
    if (ballType == 'wicket' && wicketType != null) {
      return _generateWicketCommentary(
        overStr: overStr,
        wicketType: wicketType,
        strikerName: strikerName,
        bowlerName: bowlerName,
        runs: runs,
      );
    }
    
    // Boundary commentary
    if (runs == 4) {
      return _generateBoundaryCommentary(
        overStr: overStr,
        strikerName: strikerName,
        bowlerName: bowlerName,
        shotDirection: shotDirection,
        shotType: shotType,
      );
    }
    
    if (runs == 6) {
      return _generateSixCommentary(
        overStr: overStr,
        strikerName: strikerName,
        bowlerName: bowlerName,
        shotDirection: shotDirection,
        shotType: shotType,
      );
    }
    
    // Extra commentary
    if (isExtra && extraType != null) {
      return _generateExtraCommentary(
        overStr: overStr,
        extraType: extraType,
        extraRuns: extraRuns ?? 0,
        strikerName: strikerName,
        bowlerName: bowlerName,
      );
    }
    
    // Normal runs commentary
    return _generateNormalCommentary(
      overStr: overStr,
      runs: runs,
      strikerName: strikerName,
      bowlerName: bowlerName,
      shotDirection: shotDirection,
      shotType: shotType,
    );
  }
  
  static String _generateWicketCommentary({
    required String overStr,
    required String wicketType,
    required String strikerName,
    required String bowlerName,
    required int runs,
  }) {
    // CricHeroes style: "15.2: OUT! Akash to Utkarsh Pandita, caught at deep cover"
    String wicketText = '';
    switch (wicketType) {
      case 'Bowled':
        wicketText = 'OUT! Bowled! $bowlerName cleans him up';
        break;
      case 'Caught':
      case 'Catch Out':
        wicketText = 'OUT! $bowlerName to $strikerName, caught';
        break;
      case 'LBW':
        wicketText = 'OUT! LBW! $strikerName trapped in front by $bowlerName';
        break;
      case 'Run Out':
        wicketText = 'OUT! RUN OUT! Direct hit from point';
        break;
      case 'Stumped':
        wicketText = 'OUT! Stumped! $strikerName out of the crease, $bowlerName strikes';
        break;
      case 'Hit Wicket':
        wicketText = 'OUT! Hit Wicket! $strikerName disturbs the stumps';
        break;
      case 'Retired Hurt':
        wicketText = 'Retired Hurt! $strikerName walks off';
        break;
      default:
        wicketText = 'OUT! $strikerName dismissed by $bowlerName';
    }
    
    String runsText = runs > 0 ? '. $runs run${runs > 1 ? 's' : ''} scored' : '';
    return '$overStr: $wicketText$runsText';
  }
  
  static String _generateBoundaryCommentary({
    required String overStr,
    required String strikerName,
    required String bowlerName,
    String? shotDirection,
    String? shotType,
  }) {
    // CricHeroes style: "15.3 Akash to Utkarsh Pandita, FOUR, to deep extra cover"
    String directionText = '';
    if (shotDirection != null) {
      final directionMap = {
        'cover': 'deep extra cover',
        'midwicket': 'deep midwicket',
        'straight': 'straight down the ground',
        'square': 'square of the wicket',
        'fine': 'fine leg',
        'third': 'third man',
        'point': 'deep point',
        'midoff': 'deep mid-off',
        'midon': 'deep mid-on',
      };
      directionText = ', to ${directionMap[shotDirection] ?? shotDirection}';
    }
    
    return '$overStr $bowlerName to $strikerName, FOUR$directionText';
  }
  
  static String _generateSixCommentary({
    required String overStr,
    required String strikerName,
    required String bowlerName,
    String? shotDirection,
    String? shotType,
  }) {
    // CricHeroes style: "15.4 Akash to Utkarsh Pandita, SIX, to long-on"
    String directionText = '';
    if (shotDirection != null) {
      final directionMap = {
        'cover': 'over covers',
        'midwicket': 'over midwicket',
        'straight': 'straight down the ground',
        'square': 'over square leg',
        'fine': 'over fine leg',
        'longon': 'to long-on',
        'longoff': 'to long-off',
      };
      directionText = ', to ${directionMap[shotDirection] ?? shotDirection}';
    }
    
    return '$overStr $bowlerName to $strikerName, SIX$directionText';
  }
  
  static String _generateExtraCommentary({
    required String overStr,
    required String extraType,
    required int extraRuns,
    required String strikerName,
    required String bowlerName,
  }) {
    switch (extraType) {
      case 'WD':
        if (extraRuns > 1) {
          return '$overStr: Wide! $bowlerName strays down leg, $extraRuns runs to $strikerName';
        }
        return '$overStr: Wide! $bowlerName bowls wide, 1 run added';
        
      case 'NB':
        if (extraRuns > 1) {
          return '$overStr: No Ball! $bowlerName oversteps, $extraRuns runs to $strikerName';
        }
        return '$overStr: No Ball! $bowlerName oversteps, 1 run added';
        
      case 'B':
        if (extraRuns > 0) {
          return '$overStr: Byes! $extraRuns run${extraRuns > 1 ? 's' : ''} added, $strikerName and partner run well';
        }
        return '$overStr: Byes! No run, $bowlerName beats the bat';
        
      case 'LB':
        if (extraRuns > 0) {
          return '$overStr: Leg Byes! $extraRuns run${extraRuns > 1 ? 's' : ''} added off the pads';
        }
        return '$overStr: Leg Byes! No run, ball hits the pad';
        
      default:
        return '$overStr: Extra! $extraRuns run${extraRuns > 1 ? 's' : ''} added';
    }
  }
  
  static String _generateNormalCommentary({
    required String overStr,
    required int runs,
    required String strikerName,
    required String bowlerName,
    String? shotDirection,
    String? shotType,
  }) {
    // CricHeroes style: "15.1 Akash to Utkarsh Pandita, no run"
    if (runs == 0) {
      return '$overStr $bowlerName to $strikerName, no run';
    }
    
    if (runs == 1) {
      String directionText = shotDirection != null ? ', to $shotDirection' : '';
      return '$overStr $bowlerName to $strikerName, 1 run$directionText';
    }
    
    if (runs == 2) {
      String directionText = shotDirection != null ? ', to $shotDirection' : '';
      return '$overStr $bowlerName to $strikerName, 2 runs$directionText';
    }
    
    if (runs == 3) {
      String directionText = shotDirection != null ? ', to $shotDirection' : '';
      return '$overStr $bowlerName to $strikerName, 3 runs$directionText';
    }
    
    return '$overStr $bowlerName to $strikerName, $runs run${runs > 1 ? 's' : ''}';
  }
}

