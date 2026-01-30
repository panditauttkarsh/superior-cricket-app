/// Immutable delivery model - represents a single ball bowled
/// This is the source of truth for all calculations
class DeliveryModel {
  final int deliveryNumber;
  final int over; // Over number (0-indexed)
  final int ball; // Ball number in over (1-6)
  final String striker;
  final String nonStriker;
  final String bowler;
  final int runs; // Runs off the bat (excluding extras)
  final int teamTotal; // Team total after this delivery
  final String? wicketType; // Type of dismissal if wicket
  final String? dismissedPlayer; // Player dismissed (if wicket)
  final String? fielder; // Player who took catch/stumping/run-out
  final String? assistFielder; // Player who assisted (for run-outs)
  final ExtraType? extraType;
  final int? extraRuns; // Extra runs (1 for WD/NB, additional for runs)
  final bool isLegalBall; // true for legal, false for wide/no-ball
  final bool isShortRun; // true if short run was applied
  final DateTime timestamp;

  const DeliveryModel({
    required this.deliveryNumber,
    required this.over,
    required this.ball,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.runs,
    required this.teamTotal,
    this.wicketType,
    this.dismissedPlayer,
    this.fielder,
    this.assistFielder,
    this.extraType,
    this.extraRuns,
    required this.isLegalBall,
    required this.isShortRun,
    required this.timestamp,
  });

  /// Create from JSON (for loading from database)
  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      deliveryNumber: json['deliveryNumber'] as int,
      over: json['over'] as int,
      ball: json['ball'] as int,
      striker: json['striker'] as String? ?? '',
      nonStriker: json['nonStriker'] as String? ?? '',
      bowler: json['bowler'] as String? ?? '',
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      teamTotal: (json['teamTotal'] as num?)?.toInt() ?? 0,
      wicketType: json['wicketType'] as String?,
      dismissedPlayer: json['dismissedPlayer'] as String? ??
          (json['wicketType'] != null ? json['striker'] as String? : null),
      fielder: json['fielder'] as String?,
      assistFielder: json['assistFielder'] as String?,
      extraType: json['extraType'] != null
          ? ExtraType.fromString(json['extraType'] as String)
          : null,
      extraRuns: (json['extraRuns'] as num?)?.toInt(),
      isLegalBall: json['isLegalBall'] as bool? ?? true,
      isShortRun: json['isShortRun'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON (for saving to database)
  Map<String, dynamic> toJson() {
    return {
      'deliveryNumber': deliveryNumber,
      'over': over,
      'ball': ball,
      'striker': striker,
      'nonStriker': nonStriker,
      'bowler': bowler,
      'runs': runs,
      'teamTotal': teamTotal,
      'wicketType': wicketType,
      'dismissedPlayer': dismissedPlayer,
      'fielder': fielder,
      'assistFielder': assistFielder,
      'extraType': extraType?.toString(),
      'extraRuns': extraRuns,
      'isLegalBall': isLegalBall,
      'isShortRun': isShortRun,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get total runs for this delivery (bat runs + extras)
  int get totalRuns {
    if (extraType == ExtraType.wide || extraType == ExtraType.noBall) {
      return extraRuns ?? 0; // For WD/NB, extraRuns contains total
    }
    return runs + (extraRuns ?? 0);
  }

  /// Get runs credited to bowler (for economy calculation)
  int get bowlerRuns {
    if (extraType == ExtraType.wide || extraType == ExtraType.noBall) {
      return extraRuns ?? 0; // Bowler concedes all runs on WD/NB
    } else if (extraType == ExtraType.bye || extraType == ExtraType.legBye) {
      return 0; // Bowler doesn't concede runs on B/LB
    }
    return runs; // Bowler concedes bat runs
  }

  /// Check if wicket is credited to bowler
  bool get isWicketCreditedToBowler {
    if (wicketType == null) return false;
    const creditedTypes = [
      'Bowled',
      'Caught',
      'LBW',
      'Stumped',
      'Hit Wicket'
    ];
    return creditedTypes.any((type) => wicketType!.contains(type));
  }
}

/// Extra types in cricket
enum ExtraType {
  wide('WD'),
  noBall('NB'),
  bye('B'),
  legBye('LB'),
  penalty('PENALTY');

  final String code;
  const ExtraType(this.code);

  static ExtraType? fromString(String? str) {
    if (str == null) return null;
    return ExtraType.values.firstWhere(
      (e) => e.code == str.toUpperCase(),
      orElse: () => throw ArgumentError('Invalid extra type: $str'),
    );
  }

  @override
  String toString() => code;
}

