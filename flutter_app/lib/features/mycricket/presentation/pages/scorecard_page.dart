import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/commentary_model.dart';
import '../../../../core/services/commentary_service.dart';
import '../../../../core/repositories/commentary_repository.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

class ScorecardPage extends ConsumerStatefulWidget {
  final String? matchId;
  final String? team1;
  final String? team2;
  final int? overs;
  final int? maxOversPerBowler; // Maximum overs per bowler (e.g., 4 for T20, 10 for ODI)
  final String? youtubeVideoId; // YouTube video ID for live stream
  final List<String>? myTeamPlayers; // Squad from match setup
  final List<String>? opponentTeamPlayers; // Squad from match setup
  final String? initialStriker;
  final String? initialNonStriker;
  final String? initialBowler;
  
  const ScorecardPage({
    super.key,
    this.matchId,
    this.team1,
    this.team2,
    this.overs,
    this.maxOversPerBowler,
    this.youtubeVideoId,
    this.myTeamPlayers,
    this.opponentTeamPlayers,
    this.initialStriker,
    this.initialNonStriker,
    this.initialBowler,
  });

  @override
  ConsumerState<ScorecardPage> createState() => _ScorecardPageState();
}

// Delivery data structure - Single source of truth for all match calculations
class _Delivery {
  final int deliveryNumber; // Sequential delivery number (1, 2, 3, ...)
  final int over; // Over number (0, 1, 2, ...)
  final int ball; // Ball number in over (1-6)
  final String striker;
  final String nonStriker;
  final String bowler;
  final int runs; // Actual runs scored (after short run reduction)
  final int teamTotal; // Team total after this delivery
  final int strikerRuns; // Striker runs after this delivery
  final int strikerBalls; // Striker balls faced after this delivery
  final int bowlerRuns; // Bowler runs conceded after this delivery
  final int bowlerLegalBalls; // Bowler legal balls after this delivery
  final int wickets; // Total wickets after this delivery
  final String? wicketType; // Type of dismissal if wicket
  final String? extraType; // 'WD', 'NB', 'B', 'LB' if extra
  final int? extraRuns; // Extra runs if applicable
  final bool isLegalBall; // true for legal, false for wide/no-ball
  final bool isShortRun; // true if short run was applied
  final String? commentaryId; // Commentary entry ID
  final String? shotDirection;
  final String? shotType;
  final DateTime timestamp;

  _Delivery({
    required this.deliveryNumber,
    required this.over,
    required this.ball,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.runs,
    required this.teamTotal,
    required this.strikerRuns,
    required this.strikerBalls,
    required this.bowlerRuns,
    required this.bowlerLegalBalls,
    required this.wickets,
    this.wicketType,
    this.extraType,
    this.extraRuns,
    required this.isLegalBall,
    required this.isShortRun,
    this.commentaryId,
    this.shotDirection,
    this.shotType,
    required this.timestamp,
  });
}

// Batting statistics for a single player in an innings
class _PlayerBattingStats {
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final int minutes; // Time at crease (approximate)
  final String? dismissal; // Dismissal description (e.g., "c Aryan b Nitin Sharma")
  final bool isNotOut; // true if not out
  final bool isCaptain; // (c) indicator
  final bool isWicketKeeper; // (wk) indicator

  _PlayerBattingStats({
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    required this.minutes,
    this.dismissal,
    this.isNotOut = false,
    this.isCaptain = false,
    this.isWicketKeeper = false,
  });
}

// Player innings statistics (accumulated from deliveries)
class _PlayerInningsStats {
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  DateTime? startTime;
  String? dismissal; // New field for persistence
  bool isNotOut = true; // New field for persistence
  
  double get strikeRate => balls > 0 ? (runs / balls) * 100 : 0.0;
  int get minutes {
    if (startTime == null) return 0;
    return DateTime.now().difference(startTime!).inMinutes;
  }
}

// Bowler innings statistics (accumulated from deliveries)
class _BowlerInningsStats {
  int legalBalls = 0;
  int runs = 0;
  int wickets = 0;
  int maidens = 0;
  int wides = 0;
  int noBalls = 0;
  int byes = 0;
  int legByes = 0;
  
  double get overs => legalBalls / 6.0;
  double get economy => overs > 0 ? runs / overs : 0.0;
  
  String formatOvers() {
    final wholeOvers = legalBalls ~/ 6;
    final balls = legalBalls % 6;
    return '$wholeOvers.$balls';
  }
}

// Extras breakdown
class _ExtrasBreakdown {
  int noBalls = 0;
  int wides = 0;
  int byes = 0;
  int legByes = 0;
  int penalty = 0;
  
  _ExtrasBreakdown({
    this.noBalls = 0,
    this.wides = 0,
    this.byes = 0,
    this.legByes = 0,
    this.penalty = 0,
  });
  
  int get total => noBalls + wides + byes + legByes + penalty;
  
  String format() {
    final parts = <String>[];
    if (noBalls > 0) parts.add('nb $noBalls');
    if (wides > 0) parts.add('wd $wides');
    if (byes > 0) parts.add('b $byes');
    if (legByes > 0) parts.add('lb $legByes');
    if (penalty > 0) parts.add('penalty $penalty');
    return parts.isEmpty ? '0' : parts.join(', ');
  }
}

// Complete innings data structure
class _InningsData {
  final String teamName;
  final int runs;
  final int wickets;
  final double overs;
  final List<_PlayerBattingStats> battingStats;
  final _ExtrasBreakdown extras;
  final List<_BowlerScorecardRow> bowlerStats;
  final bool isComplete;

  _InningsData({
    required this.teamName,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.battingStats,
    required this.extras,
    required this.bowlerStats,
    this.isComplete = false,
  });
}

// Bowler scorecard row data
class _BowlerScorecardRow {
  final String bowlerName;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;
  
  _BowlerScorecardRow({
    required this.bowlerName,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });
}

// Ball data structure for undo functionality
class _BallData {
  final int runs;
  final int totalRuns;
  final int wickets;
  final int currentOver;
  final int currentBall;
  final String striker;
  final String nonStriker;
  final int strikerRuns;
  final int strikerBalls;
  final int nonStrikerRuns;
  final int nonStrikerBalls;
  final double bowlerOvers;
  final int bowlerRuns;
  final int bowlerWickets;
  final String ballNotation;
  final String? shotDirection;
  final String? shotType;
  final String? extraType; // 'WD', 'NB', 'B', 'LB'
  final int? extraRuns;
  final String? commentaryId; // ID of commentary entry for deletion on undo
  final int totalValidBalls; // Track valid balls for undo
  final int bowlerLegalBalls; // Track bowler's legal balls for undo

  _BallData({
    required this.runs,
    required this.totalRuns,
    required this.wickets,
    required this.currentOver,
    required this.currentBall,
    required this.striker,
    required this.nonStriker,
    required this.strikerRuns,
    required this.strikerBalls,
    required this.nonStrikerRuns,
    required this.nonStrikerBalls,
    required this.bowlerOvers,
    required this.bowlerRuns,
    required this.bowlerWickets,
    required this.ballNotation,
    this.shotDirection,
    this.shotType,
    this.extraType,
    this.extraRuns,
    this.commentaryId,
    required this.totalValidBalls,
    required this.bowlerLegalBalls,
  });
}

class _ScorecardPageState extends ConsumerState<ScorecardPage> {
  Timer? _saveTimer;
  // Match state - Initialize to 0/0/0.0/0
  String _battingTeam = 'Warriors';
  String _bowlingTeam = 'Titans';
  String? _team1Id; // ID of Team 1
  String? _team2Id; // ID of Team 2
  int _currentOver = 0;
  int _currentBall = 0;
  int _totalRuns = 0;
  int _wickets = 0;
  String _striker = '';
  String _nonStriker = '';
  String _bowler = '';
  
  int _strikerRuns = 0;
  int _strikerBalls = 0;
  double _strikerSR = 0.0;
  
  int _nonStrikerRuns = 0;
  int _nonStrikerBalls = 0;
  double _nonStrikerSR = 0.0;
  
  double _bowlerOvers = 0.0;
  int _bowlerRuns = 0;
  int _bowlerWickets = 0;
  
  double _crr = 0.0;
  int _projected = 0;
  
  // Current over balls only (max 6 legal deliveries)
  List<String> _currentOverBalls = [];
  // Over history (for reference, not displayed in main UI)
  List<List<String>> _overHistory = [];
  
  // Track valid balls (excluding wides/no-balls) for over calculation
  int _totalValidBalls = 0;
  
  // Track current over's ball data for summary generation
  List<Map<String, dynamic>> _currentOverBallData = []; // [{runs, isWicket, displayValue}]
  
  // Track bowler's total legal balls bowled across the spell (ICC rule)
  // This is used to calculate bowler overs: legalBalls / 6
  // Example: 2 legal balls = 0.2, 8 legal balls = 1.2, 15 legal balls = 2.3
  Map<String, int> _bowlerLegalBallsMap = {}; // Track legal balls for each bowler
  
  // Flag to track if we're waiting for bowler selection (end-of-over lock)
  bool _waitingForBowlerSelection = false;
  
  List<String> _battingTeamPlayers = [];
  List<String> _bowlingTeamPlayers = [];
  List<String> _dismissedPlayers = []; // Track dismissed batsmen
  List<String> _usedBowlers = []; // Track bowlers who have bowled
  
  // Bowling metadata
  String? _bowlerType; // 'FAST' or 'SPIN'
  String? _bowlerCategory; // e.g., 'Right Arm Leg Spin', 'Left Arm Fast', etc.
  Map<String, Map<String, String>> _bowlerMetadata = {}; // Store metadata for each bowler
  Map<String, double> _bowlerOversMap = {}; // Track overs bowled by each bowler
  
  // Batting metadata
  Map<String, String> _battingTypeMap = {}; // Store batting type (Right-handed/Left-handed) for each batsman
  Set<String> _batsmenWhoHaveBatted = {}; // Track batsmen who have already batted
  
  // Innings tracking
  int _currentInnings = 1; // 1 or 2
  int _firstInningsRuns = 0;
  int _firstInningsWickets = 0;
  double _firstInningsOvers = 0.0;
  _InningsData? _firstInningsData; // Store complete first innings data
  
  // Track 4s and 6s per player (per innings)
  Map<String, int> _playerFours = {}; // Player name -> count of 4s
  Map<String, int> _playerSixes = {}; // Player name -> count of 6s
  Map<String, DateTime> _playerStartTime = {}; // Track when player started batting (for minutes calculation)
  
  // SINGLE SOURCE OF TRUTH: Complete delivery history per innings
  List<_Delivery> _deliveries = []; // All deliveries for current innings
  List<_Delivery> _firstInningsDeliveries = []; // All deliveries for first innings (when second starts)
  
  // Track complete batting stats per player (accumulated from deliveries)
  Map<String, _PlayerInningsStats> _playerStatsMap = {}; // Player -> complete stats for current innings
  Map<String, _PlayerInningsStats> _firstInningsPlayerStats = {}; // First innings stats (when second starts)
  
  // Track complete bowler stats per bowler (accumulated from deliveries)
  Map<String, _BowlerInningsStats> _bowlerStatsMap = {}; // Bowler -> complete stats for current innings
  Map<String, _BowlerInningsStats> _firstInningsBowlerStats = {}; // First innings bowler stats
  
  // Track extras per innings
  Map<String, int> _extrasMap = {}; // 'nb', 'wd', 'b', 'lb', 'penalty' -> count
  Map<String, int> _firstInningsExtras = {}; // First innings extras
  
  // Special run states
  bool _isDeclaredRun = false;
  bool _isShortRun = false;
  
  // Out type tracking
  Map<String, String> _dismissalTypes = {}; // Track dismissal type for each batsman (e.g., 'LBW', 'Run Out', 'Catch Out', etc.)
  Map<String, int> _runOutRuns = {}; // Track runs completed on run out
  Set<String> _retiredHurtPlayers = {}; // Track players who retired hurt (can return later)
  
  // Undo functionality
  List<_BallData> _undoStack = [];
  
  // Match completion flag
  bool _matchCompleted = false;
  
  // UI State for expandable innings
  bool _firstInningsExpanded = false; // Previous innings starts collapsed
  
  // YouTube Player
  YoutubePlayerController? _youtubeController;
  
  // Get total wickets allowed (squad size - 1)
  int get _maxWickets => _battingTeamPlayers.length > 0 ? _battingTeamPlayers.length - 1 : 10;
  
  // Check if innings should end
  bool get _shouldEndInnings => _wickets >= _maxWickets || (widget.overs != null && _currentOver >= widget.overs!);
  
  // Check if match is complete
  bool get _isMatchComplete => _currentInnings == 2 && _shouldEndInnings;

  @override
  void initState() {
    super.initState();
    if (widget.team1 != null) _battingTeam = widget.team1!;
    if (widget.team2 != null) _bowlingTeam = widget.team2!;
    
    // CRITICAL: Use squad data from match setup, NOT hardcoded players
    if (widget.myTeamPlayers != null && widget.myTeamPlayers!.isNotEmpty) {
      _battingTeamPlayers = List<String>.from(widget.myTeamPlayers!);
    }
    if (widget.opponentTeamPlayers != null && widget.opponentTeamPlayers!.isNotEmpty) {
      _bowlingTeamPlayers = List<String>.from(widget.opponentTeamPlayers!);
    }
    
    // If no squad data provided, use empty lists (will be loaded from match data)
    if (_battingTeamPlayers.isEmpty && _bowlingTeamPlayers.isEmpty) {
      // Fallback only if no data available - will be loaded from match data
    }
    
    // Initialize first striker and non-striker from squad or provided initial values
    if (widget.initialStriker != null && widget.initialStriker!.isNotEmpty) {
      _striker = widget.initialStriker!;
      _batsmenWhoHaveBatted.add(_striker);
      _trackPlayerStartTime(_striker);
    } else if (_battingTeamPlayers.isNotEmpty) {
      _striker = _battingTeamPlayers[0];
      _batsmenWhoHaveBatted.add(_striker);
      _trackPlayerStartTime(_striker);
    }
    
    if (widget.initialNonStriker != null && widget.initialNonStriker!.isNotEmpty) {
      _nonStriker = widget.initialNonStriker!;
      _batsmenWhoHaveBatted.add(_nonStriker);
      _trackPlayerStartTime(_nonStriker);
    } else if (_battingTeamPlayers.length > 1) {
      _nonStriker = _battingTeamPlayers[1];
      _batsmenWhoHaveBatted.add(_nonStriker);
      _trackPlayerStartTime(_nonStriker);
    }
    
    // Show batting type selection for opening batsmen if not already set (after data load)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for match data to load first
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        if (_striker.isNotEmpty && !_battingTypeMap.containsKey(_striker)) {
          _showBattingTypeSelection(_striker);
        } else if (_nonStriker.isNotEmpty && !_battingTypeMap.containsKey(_nonStriker)) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showBattingTypeSelection(_nonStriker);
            }
          });
        }
      }
    });
    
    // Initialize first bowler from squad or provided initial value
    if (widget.initialBowler != null && widget.initialBowler!.isNotEmpty) {
      _bowler = widget.initialBowler!;
    } else if (_bowlingTeamPlayers.isNotEmpty) {
      _bowler = _bowlingTeamPlayers[0];
    }
    
    if (_bowler.isNotEmpty) {
      _usedBowlers.add(_bowler);
    }
    
    // Initialize YouTube player if video ID is provided
    if (widget.youtubeVideoId != null && widget.youtubeVideoId!.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: widget.youtubeVideoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          loop: false,
          isLive: true,
        ),
      );
    }
    
    // Load match data from Supabase if matchId is provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatchData();
    });
  }
  
  @override
  void dispose() {
    _youtubeController?.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _saveScorecardToSupabase() {
    if (widget.matchId == null) return;
    
    // Cancel previous timer
    _saveTimer?.cancel();
    
    // Debounce: Save after 2 seconds of no changes
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      try {
        final matchRepo = ref.read(matchRepositoryProvider);
        
          // Determine scores based on innings
          // Assuming team1 is the one that started batting first (Innings 1)
          Map<String, dynamic> team1ScoreData;
          Map<String, dynamic> team2ScoreData;
          
          if (_currentInnings == 1) {
            team1ScoreData = {
              'runs': _totalRuns,
              'wickets': _wickets,
              'overs': _currentOver + (_currentBall / 6),
            };
            team2ScoreData = {
              'runs': 0, 
              'wickets': 0,
              'overs': 0,
            };
          } else {
            // Second innings: Team 1 is done, Team 2 is batting
            team1ScoreData = {
              'runs': _firstInningsRuns,
              'wickets': _firstInningsWickets,
              'overs': _firstInningsOvers,
            };
            team2ScoreData = {
              'runs': _totalRuns,
              'wickets': _wickets,
              'overs': _currentOver + (_currentBall / 6),
            };
          }

          // Serialize player stats map
          final playerStatsMapSerialized = _playerStatsMap.map((key, value) {
            return MapEntry(key, {
              'runs': value.runs,
              'balls': value.balls,
              'fours': value.fours,
              'sixes': value.sixes,
              'startTime': value.startTime?.toIso8601String(),
              'isNotOut': !_dismissedPlayers.contains(key), // Determine from dismissed list
              'dismissal': _dismissalTypes[key],
            });
          });

          // Serialize bowler stats map
          final bowlerStatsMapSerialized = _bowlerStatsMap.map((key, value) {
            return MapEntry(key, {
              'legalBalls': value.legalBalls,
              'runs': value.runs,
              'wickets': value.wickets,
              'maidens': value.maidens,
              'wides': value.wides,
              'noBalls': value.noBalls,
              'byes': value.byes,
              'legByes': value.legByes,
            });
          });


          // Serialize first innings player stats map
          final firstInningsPlayerStatsSerialized = _firstInningsPlayerStats.map((key, value) {
            return MapEntry(key, {
              'runs': value.runs,
              'balls': value.balls,
              'fours': value.fours,
              'sixes': value.sixes,
              'startTime': value.startTime?.toIso8601String(),
              'isNotOut': value.isNotOut,
              'dismissal': value.dismissal,
            });
          });

          // Serialize first innings bowler stats map
          final firstInningsBowlerStatsSerialized = _firstInningsBowlerStats.map((key, value) {
            return MapEntry(key, {
              'legalBalls': value.legalBalls,
              'runs': value.runs,
              'wickets': value.wickets,
              'maidens': value.maidens,
              'wides': value.wides,
              'noBalls': value.noBalls,
              'byes': value.byes,
              'legByes': value.legByes,
            });
          });

          final scorecard = {
            'team1_score': team1ScoreData,
            'team2_score': team2ScoreData,
            'current_over': _currentOver,
            'current_ball': _currentBall,
            'striker': _striker,
            'non_striker': _nonStriker,
            'bowler': _bowler,
            'striker_runs': _strikerRuns,
            'striker_balls': _strikerBalls,
            'non_striker_runs': _nonStrikerRuns,
            'non_striker_balls': _nonStrikerBalls,
            'bowler_overs': _bowlerOvers,
            'bowler_runs': _bowlerRuns,
            'bowler_wickets': _bowlerWickets,
            'crr': _crr,
            'projected': _projected,
            'current_over_balls': _currentOverBalls,
            'over_history': _overHistory,
            'dismissed_players': _dismissedPlayers,
            'used_bowlers': _usedBowlers,
            'dismissal_types': _dismissalTypes,
            'run_out_runs': _runOutRuns,
            'retired_hurt_players': _retiredHurtPlayers.toList(),
            'is_declared_run': _isDeclaredRun,
            'is_short_run': _isShortRun,
            'bowler_metadata': _bowlerMetadata,
            'bowler_overs_map': _bowlerOversMap.map((k, v) => MapEntry(k, v)),
            'bowler_legal_balls_map': _bowlerLegalBallsMap.map((k, v) => MapEntry(k, v)),
            'total_valid_balls': _totalValidBalls,
            'batting_type_map': _battingTypeMap,
            'batsmen_who_have_batted': _batsmenWhoHaveBatted.toList(),
            'current_innings': _currentInnings,
            'first_innings_runs': _firstInningsRuns,
            'first_innings_wickets': _firstInningsWickets,
            'first_innings_overs': _firstInningsOvers,
            'bowler_type': _bowlerType,
            'bowler_category': _bowlerCategory,
            'waiting_for_bowler_selection': _waitingForBowlerSelection,
            'player_stats_map': playerStatsMapSerialized,
            'bowler_stats_map': bowlerStatsMapSerialized,
            'first_innings_player_stats': firstInningsPlayerStatsSerialized,
            'first_innings_bowler_stats': firstInningsBowlerStatsSerialized,
          };
        
        await matchRepo.updateScorecard(widget.matchId!, scorecard);
      } catch (e) {
        // Silently fail - don't interrupt user experience
        debugPrint('Failed to save scorecard: $e');
      }
    });
  }

  // Save current state for undo
  void _saveStateForUndo({
    required int runs,
    required String ballNotation,
    String? shotDirection,
    String? shotType,
    String? extraType,
    int? extraRuns,
    String? commentaryId,
  }) {
    _undoStack.add(_BallData(
      runs: runs,
      totalRuns: _totalRuns,
      wickets: _wickets,
      currentOver: _currentOver,
      currentBall: _currentBall,
      striker: _striker,
      nonStriker: _nonStriker,
      strikerRuns: _strikerRuns,
      strikerBalls: _strikerBalls,
      nonStrikerRuns: _nonStrikerRuns,
      nonStrikerBalls: _nonStrikerBalls,
      bowlerOvers: _bowlerOvers,
      bowlerRuns: _bowlerRuns,
      bowlerWickets: _bowlerWickets,
      ballNotation: ballNotation,
      shotDirection: shotDirection,
      shotType: shotType,
      extraType: extraType,
      extraRuns: extraRuns,
      commentaryId: commentaryId,
      totalValidBalls: _totalValidBalls,
      bowlerLegalBalls: _bowlerLegalBallsMap[_bowler] ?? 0,
    ));
    
    // Keep only last 50 states for memory efficiency
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  // Undo last ball - True undo that completely removes the last delivery
  Future<void> _undoLastBall() async {
    if (_undoStack.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to undo')),
      );
      return;
    }
    
    final lastState = _undoStack.removeLast();
    
    // Remove last delivery from history
    if (_deliveries.isNotEmpty) {
      _deliveries.removeLast();
      // Recalculate all stats from remaining deliveries
      _recalculateStatsFromDeliveries();
    }
    
    // Delete commentary entry if it exists
    if (lastState.commentaryId != null && widget.matchId != null) {
      try {
        final repository = ref.read(commentaryRepositoryProvider);
        await repository.deleteCommentaryById(lastState.commentaryId!);
        print('Undo: Deleted commentary entry ${lastState.commentaryId}');
      } catch (e) {
        print('Undo: Error deleting commentary: $e');
        // Continue with undo even if commentary deletion fails
      }
    }
    
    setState(() {
      // Roll back all state from before the last ball
      _totalRuns = lastState.totalRuns;
      _wickets = lastState.wickets;
      _currentOver = lastState.currentOver;
      _currentBall = lastState.currentBall;
      _striker = lastState.striker;
      _nonStriker = lastState.nonStriker;
      _strikerRuns = lastState.strikerRuns;
      _strikerBalls = lastState.strikerBalls;
      _nonStrikerRuns = lastState.nonStrikerRuns;
      _nonStrikerBalls = lastState.nonStrikerBalls;
      _bowlerRuns = lastState.bowlerRuns;
      _bowlerWickets = lastState.bowlerWickets;
      
      // Roll back legal ball counts
      _totalValidBalls = lastState.totalValidBalls;
      _bowlerLegalBallsMap[_bowler] = lastState.bowlerLegalBalls;
      
      // Recalculate bowler overs from legal balls (ICC rule)
      final bowlerLegalBalls = _bowlerLegalBallsMap[_bowler] ?? 0;
      _bowlerOvers = bowlerLegalBalls / 6.0;
      
      // Recalculate strike rates
      _strikerSR = _strikerBalls > 0 ? (_strikerRuns / _strikerBalls) * 100 : 0.0;
      _nonStrikerSR = _nonStrikerBalls > 0 ? (_nonStrikerRuns / _nonStrikerBalls) * 100 : 0.0;
      
      // CRITICAL: Reconstruct _currentOverBalls from delivery history
      // This ensures Current Over display is NEVER incorrectly empty after undo
      _reconstructCurrentOverBalls();
      
      // Remove last ball from over data if it exists
      if (_currentOverBallData.isNotEmpty) {
        _currentOverBallData.removeLast();
      }
      
      // Update CRR and projected
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Reset special run states
      _isDeclaredRun = false;
      _isShortRun = false;
      
      // Clear waiting flag if set
      _waitingForBowlerSelection = false;
    });
    
    _saveScorecardToSupabase();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Last ball undone'), duration: Duration(seconds: 1)),
    );
  }

  // CRITICAL: Reconstruct Current Over display from delivery history
  // This method rebuilds _currentOverBalls based on the active _currentOver
  // Ensures the UI always shows accurate ball-by-ball data after any state change
  void _reconstructCurrentOverBalls() {
    _currentOverBalls.clear();
    
    // If no deliveries, current over is empty
    if (_deliveries.isEmpty) return;
    
    // Get all deliveries for the current over
    for (final delivery in _deliveries) {
      if (delivery.over == _currentOver) {
        // Build ball notation based on delivery type
        String ballNotation;
        
        if (delivery.wicketType != null) {
          // Wicket
          if (delivery.wicketType == 'Run Out') {
            ballNotation = 'RO${delivery.runs}';
          } else if (delivery.wicketType == 'Retired Hurt') {
            ballNotation = 'RH';
          } else {
            ballNotation = 'W';
          }
        } else if (delivery.extraType == 'WD') {
          // Wide
          final extraRuns = delivery.extraRuns ?? 1;
          ballNotation = extraRuns > 1 ? 'WD+${extraRuns - 1}' : 'WD';
        } else if (delivery.extraType == 'NB') {
          // No Ball
          final extraRuns = delivery.extraRuns ?? 1;
          ballNotation = extraRuns > 1 ? 'NB+${extraRuns - 1}' : 'NB';
        } else if (delivery.extraType == 'B') {
          // Byes
          ballNotation = delivery.runs > 0 ? 'B${delivery.runs}' : 'B';
        } else if (delivery.extraType == 'LB') {
          // Leg Byes
          ballNotation = delivery.runs > 0 ? 'LB${delivery.runs}' : 'LB';
        } else {
          // Regular runs
          ballNotation = delivery.runs.toString();
          if (delivery.isShortRun) ballNotation += ' (SR)';
        }
        
        _currentOverBalls.add(ballNotation);
      }
    }
    
    // Also update _overHistory if needed - remove the current over if it exists
    // (since we're reconstructing from scratch)
    while (_overHistory.length > _currentOver) {
      _overHistory.removeLast();
    }
  }

  // Helper function to format bowler overs display (ICC rule)
  // Formula: overs = totalLegalBalls ~/ 6, balls = totalLegalBalls % 6
  // Examples: 1 ball = 0.1, 6 balls = 1.0, 9 balls = 1.3, 13 balls = 2.1
  String _formatBowlerOvers(int totalLegalBalls) {
    if (totalLegalBalls == 0) return '0.0';
    final overs = totalLegalBalls ~/ 6;
    final balls = totalLegalBalls % 6;
    return '$overs.$balls';
  }

  // Helper function to get bowler overs as double for calculations (e.g., CRR)
  // This returns the decimal representation for mathematical operations
  double _getBowlerOversDecimal(int totalLegalBalls) {
    return totalLegalBalls / 6.0;
  }

  // Helper function to update bowler overs from legal balls (ICC rule)
  // Stores both the formatted string and decimal value
  void _updateBowlerOvers() {
    if (_bowler.isEmpty) return;
    final bowlerLegalBalls = _bowlerLegalBallsMap[_bowler] ?? 0;
    // Store decimal for calculations (CRR, etc.)
    _bowlerOvers = _getBowlerOversDecimal(bowlerLegalBalls);
    // Update bowler overs map with decimal (for calculations)
    _bowlerOversMap[_bowler] = _bowlerOvers;
  }

  // Track 4s and 6s when runs are scored off the bat
  void _trackBoundaries(String player, int runs) {
    if (runs == 4) {
      _playerFours[player] = (_playerFours[player] ?? 0) + 1;
    } else if (runs == 6) {
      _playerSixes[player] = (_playerSixes[player] ?? 0) + 1;
    }
  }
  
  // Track when a player starts batting (for minutes calculation)
  void _trackPlayerStartTime(String player) {
    if (!_playerStartTime.containsKey(player)) {
      _playerStartTime[player] = DateTime.now();
    }
  }
  
  // Calculate minutes at crease for a player
  int _calculateMinutes(String player) {
    final startTime = _playerStartTime[player];
    if (startTime == null) return 0;
    final duration = DateTime.now().difference(startTime);
    return duration.inMinutes;
  }
  
  // Record a delivery (single source of truth)
  void _recordDelivery({
    required int over,
    required int ball,
    required String striker,
    required String nonStriker,
    required String bowler,
    required int runs,
    required int teamTotal,
    required int strikerRuns,
    required int strikerBalls,
    required int bowlerRuns,
    required int bowlerLegalBalls,
    required int wickets,
    String? wicketType,
    String? extraType,
    int? extraRuns,
    required bool isLegalBall,
    required bool isShortRun,
    String? commentaryId,
    String? shotDirection,
    String? shotType,
  }) {
    final delivery = _Delivery(
      deliveryNumber: _deliveries.length + 1,
      over: over,
      ball: ball,
      striker: striker,
      nonStriker: nonStriker,
      bowler: bowler,
      runs: runs,
      teamTotal: teamTotal,
      strikerRuns: strikerRuns,
      strikerBalls: strikerBalls,
      bowlerRuns: bowlerRuns,
      bowlerLegalBalls: bowlerLegalBalls,
      wickets: wickets,
      wicketType: wicketType,
      extraType: extraType,
      extraRuns: extraRuns,
      isLegalBall: isLegalBall,
      isShortRun: isShortRun,
      commentaryId: commentaryId,
      shotDirection: shotDirection,
      shotType: shotType,
      timestamp: DateTime.now(),
    );
    
    _deliveries.add(delivery);
    
    // Update player stats from delivery
    _updatePlayerStatsFromDelivery(delivery);
    
    // Update bowler stats from delivery
    _updateBowlerStatsFromDelivery(delivery);
    
    // Update extras from delivery
    _updateExtrasFromDelivery(delivery);
  }
  
  // Update player stats from a delivery
  void _updatePlayerStatsFromDelivery(_Delivery delivery) {
    // Initialize player stats if not exists
    if (!_playerStatsMap.containsKey(delivery.striker)) {
      _playerStatsMap[delivery.striker] = _PlayerInningsStats();
      if (_playerStartTime[delivery.striker] != null) {
        _playerStatsMap[delivery.striker]!.startTime = _playerStartTime[delivery.striker];
      }
    }
    
    final playerStats = _playerStatsMap[delivery.striker]!;
    
    // Update runs - use the strikerRuns from delivery (this is cumulative)
    // Only count runs off the bat (not extras)
    if (delivery.extraType == null) {
      // Regular ball: runs off bat
      playerStats.runs = delivery.strikerRuns;
    } else if (delivery.extraType == 'NB') {
      // No-ball: runs off bat count (additionalRuns in no-ball)
      playerStats.runs = delivery.strikerRuns;
    }
    // For wides, byes, leg-byes: strikerRuns doesn't change, so don't update
    
    // Update balls (only legal balls)
    if (delivery.isLegalBall) {
      playerStats.balls = delivery.strikerBalls;
    }
    
    // Track boundaries (only if runs are off the bat)
    if (delivery.extraType == null || delivery.extraType == 'NB') {
      // Use runs directly from the delivery object (actual runs scored on this ball)
      // This is safer than comparing cumulative runs which can be buggy with player swaps
      
      // For runs off bat (no extra) or No Ball (bat runs count), check runs
      // boundary runs are stored in 'runs'
      
      if (delivery.runs == 4) {
        playerStats.fours++;
      } else if (delivery.runs == 6) {
        playerStats.sixes++;
      }
    }
  }
  
  // Update bowler stats from a delivery
  void _updateBowlerStatsFromDelivery(_Delivery delivery) {
    if (!_bowlerStatsMap.containsKey(delivery.bowler)) {
      _bowlerStatsMap[delivery.bowler] = _BowlerInningsStats();
    }
    
    final bowlerStats = _bowlerStatsMap[delivery.bowler]!;
    
    // Update legal balls
    bowlerStats.legalBalls = delivery.bowlerLegalBalls;
    
    // Update runs conceded (includes extras)
    bowlerStats.runs = delivery.bowlerRuns;
    
    // Update wickets
    if (delivery.wicketType != null && delivery.wicketType != 'Run Out') {
      bowlerStats.wickets = delivery.wickets;
    }
    
    // Track extras by type
    if (delivery.extraType == 'WD') {
      bowlerStats.wides += (delivery.extraRuns ?? 0);
    } else if (delivery.extraType == 'NB') {
      bowlerStats.noBalls += (delivery.extraRuns ?? 0);
    } else if (delivery.extraType == 'B') {
      bowlerStats.byes += (delivery.extraRuns ?? 0);
    } else if (delivery.extraType == 'LB') {
      bowlerStats.legByes += (delivery.extraRuns ?? 0);
    }
  }
  
  // Update extras from a delivery
  void _updateExtrasFromDelivery(_Delivery delivery) {
    if (delivery.extraType != null && delivery.extraRuns != null) {
      final extraKey = delivery.extraType!.toLowerCase();
      _extrasMap[extraKey] = (_extrasMap[extraKey] ?? 0) + delivery.extraRuns!;
    }
  }
  
  // Recalculate all stats from deliveries (for undo/editing)
  void _recalculateStatsFromDeliveries() {
    // Reset all stats
    _playerStatsMap.clear();
    _bowlerStatsMap.clear();
    _extrasMap.clear();
    
    // Recalculate from all deliveries - build up incrementally
    for (final delivery in _deliveries) {
      // Initialize player stats if not exists
      if (!_playerStatsMap.containsKey(delivery.striker)) {
        _playerStatsMap[delivery.striker] = _PlayerInningsStats();
        if (_playerStartTime[delivery.striker] != null) {
          _playerStatsMap[delivery.striker]!.startTime = _playerStartTime[delivery.striker];
        }
      }
      
      final playerStats = _playerStatsMap[delivery.striker]!;
      
      // Update runs - only if off the bat (not extras)
      if (delivery.extraType == null) {
        // Regular ball: runs off bat
        playerStats.runs = delivery.strikerRuns;
      } else if (delivery.extraType == 'NB') {
        // No-ball: runs off bat count
        playerStats.runs = delivery.strikerRuns;
      }
      // For wides, byes, leg-byes: strikerRuns doesn't change
      
      // Update balls (only legal balls)
      if (delivery.isLegalBall) {
        playerStats.balls = delivery.strikerBalls;
      }
      
      // Track boundaries incrementally
      if (delivery.extraType == null || delivery.extraType == 'NB') {
        if (delivery.runs == 4) {
          playerStats.fours++;
        } else if (delivery.runs == 6) {
          playerStats.sixes++;
        }
      }
      
      // Update bowler stats
      if (!_bowlerStatsMap.containsKey(delivery.bowler)) {
        _bowlerStatsMap[delivery.bowler] = _BowlerInningsStats();
      }
      
      final bowlerStats = _bowlerStatsMap[delivery.bowler]!;
      bowlerStats.legalBalls = delivery.bowlerLegalBalls;
      bowlerStats.runs = delivery.bowlerRuns;
      
      if (delivery.wicketType != null && delivery.wicketType != 'Run Out') {
        bowlerStats.wickets = delivery.wickets;
      }
      
      // Track extras by type
      if (delivery.extraType == 'WD') {
        bowlerStats.wides += (delivery.extraRuns ?? 0);
      } else if (delivery.extraType == 'NB') {
        bowlerStats.noBalls += (delivery.extraRuns ?? 0);
      } else if (delivery.extraType == 'B') {
        bowlerStats.byes += (delivery.extraRuns ?? 0);
      } else if (delivery.extraType == 'LB') {
        bowlerStats.legByes += (delivery.extraRuns ?? 0);
      }
      
      // Update extras
      if (delivery.extraType != null && delivery.extraRuns != null) {
        final extraKey = delivery.extraType!.toLowerCase();
        _extrasMap[extraKey] = (_extrasMap[extraKey] ?? 0) + delivery.extraRuns!;
      }
    }
  }
  
  // Build batting statistics for current innings from deliveries
  List<_PlayerBattingStats> _buildCurrentInningsBattingStats() {
    final stats = <_PlayerBattingStats>[];
    
    // Get all players who have batted (from deliveries or current state)
    final allBatsmen = <String>{};
    for (final delivery in _deliveries) {
      allBatsmen.add(delivery.striker);
      allBatsmen.add(delivery.nonStriker);
    }
    // Also include current striker/non-striker if they haven't faced a ball yet
    if (_striker.isNotEmpty) allBatsmen.add(_striker);
    if (_nonStriker.isNotEmpty) allBatsmen.add(_nonStriker);
    
    // CRITICAL: Ensure stats map is synced with current state for active players
    // This handles cases where deliveries exist but map wasn't updated
    if (_striker.isNotEmpty) {
      if (!_playerStatsMap.containsKey(_striker)) {
        _playerStatsMap[_striker] = _PlayerInningsStats();
      }
      _playerStatsMap[_striker]!.runs = _strikerRuns;
      _playerStatsMap[_striker]!.balls = _strikerBalls;
    }
    if (_nonStriker.isNotEmpty) {
      if (!_playerStatsMap.containsKey(_nonStriker)) {
        _playerStatsMap[_nonStriker] = _PlayerInningsStats();
      }
      _playerStatsMap[_nonStriker]!.runs = _nonStrikerRuns;
      _playerStatsMap[_nonStriker]!.balls = _nonStrikerBalls;
    }
    
    for (final player in allBatsmen) {
      // Get stats from map (calculated from deliveries)
      // If not in map, create new but ensure it's populated from current state if active
      if (!_playerStatsMap.containsKey(player)) {
        _playerStatsMap[player] = _PlayerInningsStats();
        // If this is current striker/non-striker, use current state
        if (player == _striker) {
          _playerStatsMap[player]!.runs = _strikerRuns;
          _playerStatsMap[player]!.balls = _strikerBalls;
        } else if (player == _nonStriker) {
          _playerStatsMap[player]!.runs = _nonStrikerRuns;
          _playerStatsMap[player]!.balls = _nonStrikerBalls;
        }
      }
      
      final playerStats = _playerStatsMap[player]!;
      
      // ALWAYS sync with current state for active players (real source of truth)
      if (player == _striker) {
        playerStats.runs = _strikerRuns;
        playerStats.balls = _strikerBalls;
      } else if (player == _nonStriker) {
        playerStats.runs = _nonStrikerRuns;
        playerStats.balls = _nonStrikerBalls;
      }
      
      // Check if dismissed
      final isDismissed = _dismissedPlayers.contains(player);
      final dismissal = _dismissalTypes[player];
      
      // Only add if player has actually batted (has runs or balls) or is dismissed
      if (playerStats.runs > 0 || playerStats.balls > 0 || isDismissed) {
        stats.add(_PlayerBattingStats(
          playerName: player,
          runs: playerStats.runs,
          balls: playerStats.balls,
          fours: playerStats.fours,
          sixes: playerStats.sixes,
          strikeRate: playerStats.strikeRate,
          minutes: playerStats.minutes,
          dismissal: dismissal,
          isNotOut: !isDismissed,
        ));
      }
    }
    
    // Sort by batting order (first to bat appears first)
    stats.sort((a, b) {
      final aIndex = _batsmenWhoHaveBatted.toList().indexOf(a.playerName);
      final bIndex = _batsmenWhoHaveBatted.toList().indexOf(b.playerName);
      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });
    
    return stats;
  }
  
  // Build extras breakdown for current innings
  _ExtrasBreakdown _buildExtrasBreakdown() {
    return _ExtrasBreakdown(
      noBalls: _extrasMap['nb'] ?? 0,
      wides: _extrasMap['wd'] ?? 0,
      byes: _extrasMap['b'] ?? 0,
      legByes: _extrasMap['lb'] ?? 0,
      penalty: _extrasMap['penalty'] ?? 0,
    );
  }
  
  // Build bowler stats for current innings
  // REAL SOURCE OF TRUTH: State variables (_bowlerRuns, _bowlerLegalBallsMap, etc.)
  List<_BowlerScorecardRow> _buildBowlerStats() {
    final bowlerRows = <_BowlerScorecardRow>[];
    
    // CRITICAL: Ensure current bowler stats are synced with state
    if (_bowler.isNotEmpty) {
      if (!_bowlerStatsMap.containsKey(_bowler)) {
        _bowlerStatsMap[_bowler] = _BowlerInningsStats();
      }
      final currentBowlerStats = _bowlerStatsMap[_bowler]!;
      currentBowlerStats.legalBalls = _bowlerLegalBallsMap[_bowler] ?? 0;
      currentBowlerStats.runs = _bowlerRuns;
      currentBowlerStats.wickets = _bowlerWickets;
    }
    
    for (final entry in _bowlerStatsMap.entries) {
      final bowlerName = entry.key;
      final stats = entry.value;
      
      // Sync with current state if this is the active bowler
      if (bowlerName == _bowler) {
        stats.legalBalls = _bowlerLegalBallsMap[_bowler] ?? 0;
        stats.runs = _bowlerRuns;
        stats.wickets = _bowlerWickets;
      }
      
      bowlerRows.add(_BowlerScorecardRow(
        bowlerName: bowlerName,
        overs: stats.overs,
        maidens: stats.maidens,
        runs: stats.runs,
        wickets: stats.wickets,
        economy: stats.economy,
      ));
    }
    
    // Sort by overs bowled (most first)
    bowlerRows.sort((a, b) => b.overs.compareTo(a.overs));
    
    return bowlerRows;
  }
  
  // Build current innings data
  _InningsData _buildCurrentInningsData() {
    final overs = _currentOver + (_currentBall / 6);
    return _InningsData(
      teamName: _battingTeam,
      runs: _totalRuns,
      wickets: _wickets,
      overs: overs,
      battingStats: _buildCurrentInningsBattingStats(),
      extras: _buildExtrasBreakdown(),
      bowlerStats: _buildBowlerStats(),
      isComplete: _shouldEndInnings,
    );
  }
  
  // Save first innings data when switching to second innings
  void _saveFirstInningsData() {
    // Save deliveries
    _firstInningsDeliveries = List<_Delivery>.from(_deliveries);
    
    // Save player stats with dismissal info
    _firstInningsPlayerStats = Map<String, _PlayerInningsStats>.from(
      _playerStatsMap.map((k, v) {
        final isDismissed = _dismissedPlayers.contains(k);
        final dismissal = _dismissalTypes[k];
        
        return MapEntry(k, _PlayerInningsStats()
          ..runs = v.runs
          ..balls = v.balls
          ..fours = v.fours
          ..sixes = v.sixes
          ..startTime = v.startTime
          ..dismissal = dismissal
          ..isNotOut = !isDismissed
        );
      }),
    );
    
    // Save bowler stats
    _firstInningsBowlerStats = Map<String, _BowlerInningsStats>.from(
      _bowlerStatsMap.map((k, v) => MapEntry(k, _BowlerInningsStats()
        ..legalBalls = v.legalBalls
        ..runs = v.runs
        ..wickets = v.wickets
        ..maidens = v.maidens
        ..wides = v.wides
        ..noBalls = v.noBalls
        ..byes = v.byes
        ..legByes = v.legByes)),
    );
    
    // Save extras
    _firstInningsExtras = Map<String, int>.from(_extrasMap);
    
    // Build first innings data
    final firstInningsExtras = _ExtrasBreakdown(
      noBalls: _firstInningsExtras['nb'] ?? 0,
      wides: _firstInningsExtras['wd'] ?? 0,
      byes: _firstInningsExtras['b'] ?? 0,
      legByes: _firstInningsExtras['lb'] ?? 0,
      penalty: _firstInningsExtras['penalty'] ?? 0,
    );
    
    final firstInningsBowlerRows = _firstInningsBowlerStats.entries.map((e) {
      final stats = e.value;
      return _BowlerScorecardRow(
        bowlerName: e.key,
        overs: stats.overs,
        maidens: stats.maidens,
        runs: stats.runs,
        wickets: stats.wickets,
        economy: stats.economy,
      );
    }).toList();
    firstInningsBowlerRows.sort((a, b) => b.overs.compareTo(a.overs));
    
    final firstInningsBattingStats = _firstInningsPlayerStats.entries.map((e) {
      final player = e.key;
      final stats = e.value;
      final isDismissed = _dismissedPlayers.contains(player);
      final dismissal = _dismissalTypes[player];
      
      return _PlayerBattingStats(
        playerName: player,
        runs: stats.runs,
        balls: stats.balls,
        fours: stats.fours,
        sixes: stats.sixes,
        strikeRate: stats.strikeRate,
        minutes: stats.minutes,
        dismissal: dismissal,
        isNotOut: !isDismissed,
      );
    }).toList();
    
    _firstInningsData = _InningsData(
      teamName: _currentInnings == 1 ? _battingTeam : _bowlingTeam,
      runs: _firstInningsRuns,
      wickets: _firstInningsWickets,
      overs: _firstInningsOvers,
      battingStats: firstInningsBattingStats,
      extras: firstInningsExtras,
      bowlerStats: firstInningsBowlerRows,
      isComplete: true,
    );
  }
  
  // Helper function to increment bowler's legal balls and update overs
  void _incrementBowlerLegalBalls() {
    if (_bowler.isEmpty) return;
    _bowlerLegalBallsMap[_bowler] = (_bowlerLegalBallsMap[_bowler] ?? 0) + 1;
    _updateBowlerOvers();
  }

  // Helper function to swap striker and non-striker
  void _swapBatsmen() {
    final temp = _striker;
    _striker = _nonStriker;
    _nonStriker = temp;
    final tempRuns = _strikerRuns;
    _strikerRuns = _nonStrikerRuns;
    _nonStrikerRuns = tempRuns;
    final tempBalls = _strikerBalls;
    _strikerBalls = _nonStrikerBalls;
    _nonStrikerBalls = tempBalls;
    final tempSR = _strikerSR;
    _strikerSR = _nonStrikerSR;
    _nonStrikerSR = tempSR;
  }
  
  // Show bottom sheet to select next bowler
  Future<void> _showSelectNextBowler() async {
    final maxOversPerBowler = widget.maxOversPerBowler ?? 
        (widget.overs != null && widget.overs! <= 20 ? 4 : 10); // Default: T20=4, ODI=10
    
    // Get available bowlers ONLY from bowling team squad
    // Exclude:
    // 1. Current bowler (previous over bowler)
    // 2. Batting team players
    // 3. Bowlers who have completed their max overs
    final availableBowlers = _bowlingTeamPlayers
        .where((player) {
          // Exclude current bowler (previous over)
          if (player == _bowler) return false;
          
          // Exclude batting team players
          if (_battingTeamPlayers.contains(player)) return false;
          
          // Exclude bowlers who have completed max overs
          final oversBowled = _bowlerOversMap[player] ?? 0.0;
          if (oversBowled >= maxOversPerBowler) return false;
          
          return true;
        })
        .toList();
    
    if (availableBowlers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other bowlers available')),
      );
      return;
    }
    
    // ICC Rule: End-of-over bowler selection is MANDATORY and BLOCKING
    // Cannot dismiss, all scoring/navigation blocked until bowler selected
    final selectedBowler = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Cannot dismiss - mandatory selection
      enableDrag: false, // Cannot drag to dismiss
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Next Bowler',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Current bowler: $_bowler',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSec,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select from bowling team squad only',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSec,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: Builder(
                builder: (context) {
                  final maxOvers = widget.maxOversPerBowler ?? 
                      (widget.overs != null && widget.overs! <= 20 ? 4 : 10);
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableBowlers.length,
                    itemBuilder: (context, index) {
                      final bowler = availableBowlers[index];
                      return ListTile(
                        title: Text(
                          bowler,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                            fontFamily: 'Inter',
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_bowlerMetadata.containsKey(bowler))
                              Text(
                                '${_bowlerMetadata[bowler]!['type']} - ${_bowlerMetadata[bowler]!['category']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSec,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Overs: ${_formatBowlerOvers(_bowlerLegalBallsMap[bowler] ?? 0)} / $maxOvers',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSec.withOpacity(0.7),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.pop(context, bowler),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    
    // selectedBowler cannot be null because modal is non-dismissible
    if (selectedBowler != null && mounted) {
      // If bowler doesn't have metadata, show type/style selection
      if (!_bowlerMetadata.containsKey(selectedBowler)) {
        await _showBowlerTypeSelection(selectedBowler);
      } else {
        // Use existing metadata
        _bowlerType = _bowlerMetadata[selectedBowler]!['type'];
        _bowlerCategory = _bowlerMetadata[selectedBowler]!['category'];
      }
      
      if (mounted) {
        setState(() {
          // Store previous bowler's legal balls and overs before switching
          if (_bowler.isNotEmpty) {
            _bowlerOversMap[_bowler] = _bowlerOvers;
          }
          
          _bowler = selectedBowler;
          if (!_usedBowlers.contains(selectedBowler)) {
            _usedBowlers.add(selectedBowler);
          }
          
          // Initialize bowler stats (use existing if bowler has bowled before)
          // ICC Rule: Bowler overs = legal balls / 6 (not reset per over)
          // Initialize legal balls if bowler is new
          if (!_bowlerLegalBallsMap.containsKey(selectedBowler)) {
            _bowlerLegalBallsMap[selectedBowler] = 0;
          }
          _updateBowlerOvers(); // Calculate from legal balls
          _bowlerRuns = 0; // Reset runs for new over
          _bowlerWickets = 0; // Reset wickets for new over
          
          // Note: Strike rotation at end of over is already handled in run functions
          // when overComplete is true. No need to swap again here.
          // Reset current over balls
          _currentOverBalls = [];
          
          // Clear waiting flag - bowler selected, next over initialized
          _waitingForBowlerSelection = false;
        });
        _saveScorecardToSupabase();
      }
    }
  }
  
  // Show bowler type and category selection in a single clean modal
  Future<void> _showBowlerTypeSelection(String bowlerName) async {
    String? selectedType;
    String? selectedCategory;
    
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Step 1: Select Type
          if (selectedType == null) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Bowling Type',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTypeOption(
                          'Fast',
                          () => setModalState(() => selectedType = 'FAST'),
                        ),
                        const SizedBox(height: 12),
                        _buildTypeOption(
                          'Spin',
                          () => setModalState(() => selectedType = 'SPIN'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Step 2: Select Category
          List<String> categories;
          String title;
          
          if (selectedType == 'FAST') {
            title = 'Select Fast Bowling Category';
            categories = [
              'Right Arm Fast',
              'Right Arm Fast Medium',
              'Left Arm Fast',
              'Left Arm Fast Medium',
              'Swing Bowler',
              'Seam Bowler',
            ];
          } else {
            title = 'Select Spin Bowling Category';
            categories = [
              'Right Arm Off Spin',
              'Right Arm Leg Spin',
              'Right Arm Mystery Spinner',
              'Left Arm Orthodox (Left-arm Off Spin)',
              'Left Arm Chinaman (Left-arm Wrist Spin)',
            ];
          }
          
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => setModalState(() => selectedType = null),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...categories.map((category) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCategoryOption(
                          category,
                          () {
                            selectedCategory = category;
                            Navigator.pop(context, 'selected');
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    if (selectedType != null && selectedCategory != null && mounted) {
      setState(() {
        _bowlerType = selectedType;
        _bowlerCategory = selectedCategory;
        _bowlerMetadata[bowlerName] = {
          'type': selectedType!,
          'category': selectedCategory!,
        };
      });
      _saveScorecardToSupabase();
    }
  }
  
  Widget _buildTypeOption(String type, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                type,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSec),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryOption(String category, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Text(
          category,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
  
  // Show modal to select new batsman after wicket
  Future<void> _showSelectNewBatsman() async {
    // Get available batsmen (exclude dismissed players and current non-striker)
    final availableBatsmen = _battingTeamPlayers
        .where((player) => 
            !_dismissedPlayers.contains(player) && 
            player != _nonStriker)
        .toList();
    
    if (availableBatsmen.isEmpty) {
      // All out - end innings
      _endInnings();
      return;
    }
    
    final selectedBatsman = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select New Batsman',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableBatsmen.length,
            itemBuilder: (context, index) {
              final batsman = availableBatsmen[index];
              return ListTile(
                title: Text(
                  batsman,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                onTap: () => Navigator.pop(context, batsman),
              );
            },
          ),
        ),
      ),
    );
    
    if (selectedBatsman != null && mounted) {
      // If batsman hasn't batted before, show batting type selection
      if (!_batsmenWhoHaveBatted.contains(selectedBatsman)) {
        await _showBattingTypeSelection(selectedBatsman);
      }
      
      setState(() {
        _striker = selectedBatsman;
        _strikerRuns = 0;
        _strikerBalls = 0;
        _strikerSR = 0.0;
        _batsmenWhoHaveBatted.add(selectedBatsman);
        _trackPlayerStartTime(selectedBatsman);
      });
      _saveScorecardToSupabase();
      
      // Generate new batsman arrival commentary
      _generateNewBatsmanCommentary(selectedBatsman);
    }
  }
  
  /// Generate commentary for new batsman arrival
  Future<void> _generateNewBatsmanCommentary(String batsmanName) async {
    if (widget.matchId == null) return;
    
    try {
      // Calculate current over/ball position
      final over = (_totalValidBalls - 1) ~/ 6;
      final ball = ((_totalValidBalls - 1) % 6) + 1;
      final overDecimal = over + (ball / 10.0);
      
      final commentaryText = 'New batsman: $batsmanName comes to the crease';
      
      final commentary = CommentaryModel(
        id: const Uuid().v4(),
        matchId: widget.matchId!,
        over: overDecimal,
        ballType: 'newBatsman',
        runs: 0,
        strikerName: batsmanName,
        bowlerName: _bowler,
        timestamp: DateTime.now(),
        commentaryText: commentaryText,
      );
      
      final repository = ref.read(commentaryRepositoryProvider);
      await repository.createCommentary(commentary);
      print('Commentary: New batsman arrival - $batsmanName');
    } catch (e) {
      print('Error generating new batsman commentary: $e');
    }
  }
  
  // Show batting type selection (Right/Left Handed)
  Future<void> _showBattingTypeSelection(String batsmanName) async {
    final selectedType = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Batting Type',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              batsmanName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSec,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => Navigator.pop(context, 'Right-handed'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Right-handed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.pop(context, 'Left-handed'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Left-handed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    if (selectedType != null && mounted) {
      setState(() {
        _battingTypeMap[batsmanName] = selectedType;
      });
      _saveScorecardToSupabase();
    }
  }
  
  // End innings when all wickets fall or overs completed
  void _endInnings() {
    if (_currentInnings == 1) {
      // Save first innings data
      setState(() {
        _firstInningsRuns = _totalRuns;
        _firstInningsWickets = _wickets;
        _firstInningsOvers = _currentOver + (_currentBall / 6);
      });
      
      // Show premium innings summary
      _showInningsSummary(
        teamName: _battingTeam,
        runs: _totalRuns,
        wickets: _wickets,
        overs: _currentOver + (_currentBall / 6),
        isFirstInnings: true,
      );
    } else {
      // Second innings complete - show match result
      _showMatchResult();
    }
  }
  
  // Show premium innings summary popup
  void _showInningsSummary({
    required String teamName,
    required int runs,
    required int wickets,
    required double overs,
    required bool isFirstInnings,
  }) {
    final runRate = overs > 0 ? (runs / overs) : 0.0;
    final reason = wickets >= _maxWickets ? 'All Out' : 'Overs Completed';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.95),
              AppColors.primary.withOpacity(0.85),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Innings label
                    Text(
                      isFirstInnings ? 'FIRST INNINGS' : 'SECOND INNINGS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'Inter',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Team name
                    Text(
                      teamName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Score card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Score
                          Text(
                            '$runs / $wickets',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Inter',
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Overs
                          Text(
                            '${overs.toStringAsFixed(1)} Overs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Run Rate
                          Text(
                            'Run Rate: ${runRate.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reason
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (isFirstInnings) {
                            _startSecondInnings();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          isFirstInnings ? 'Start Second Innings' : 'View Match Result',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Start second innings
  void _startSecondInnings() {
    // Save first innings data before resetting
    _saveFirstInningsData();
    
    setState(() {
      _currentInnings = 2;
      // Swap teams
      final tempTeam = _battingTeam;
      _battingTeam = _bowlingTeam;
      _bowlingTeam = tempTeam;
      
      // Swap player lists
      final tempPlayers = _battingTeamPlayers;
      _battingTeamPlayers = _bowlingTeamPlayers;
      _bowlingTeamPlayers = tempPlayers;
      
      // Reset match state
      _totalRuns = 0;
      _wickets = 0;
      _currentOver = 0;
      _currentBall = 0;
      _striker = _battingTeamPlayers.isNotEmpty ? _battingTeamPlayers[0] : '';
      _nonStriker = _battingTeamPlayers.length > 1 ? _battingTeamPlayers[1] : '';
      _strikerRuns = 0;
      _strikerBalls = 0;
      _strikerSR = 0.0;
      _nonStrikerRuns = 0;
      _nonStrikerBalls = 0;
      _nonStrikerSR = 0.0;
      
      // Reset tracking for second innings
      _playerFours = {};
      _playerSixes = {};
      _playerStartTime = {};
      
      // Reset deliveries and stats for second innings
      _deliveries.clear();
      _playerStatsMap.clear();
      _bowlerStatsMap.clear();
      _extrasMap.clear();
      
      // Track start time for new batsmen
      if (_striker.isNotEmpty) _trackPlayerStartTime(_striker);
      if (_nonStriker.isNotEmpty) _trackPlayerStartTime(_nonStriker);
      _crr = 0.0;
      _projected = 0;
      _currentOverBalls = [];
      _overHistory = [];
      _dismissedPlayers = [];
      _usedBowlers = [];
      _bowler = _bowlingTeamPlayers.isNotEmpty ? _bowlingTeamPlayers[0] : '';
      _bowlerOvers = 0.0;
      _bowlerRuns = 0;
      _bowlerWickets = 0;
      _isDeclaredRun = false;
      _isShortRun = false;
    });
    _saveScorecardToSupabase();
  }
  
  // Show match result screen
  void _showMatchResult() async {
    final target = _firstInningsRuns + 1;
    final runsScored = _totalRuns;
    final wicketsLost = _wickets;
    final oversPlayed = _currentOver + (_currentBall / 6);
    
    String result;
    String winningTeam;
    
    if (runsScored > _firstInningsRuns) {
      winningTeam = _battingTeam;
      final margin = runsScored - _firstInningsRuns;
      result = 'Won by $margin ${margin == 1 ? 'run' : 'runs'}';
    } else if (runsScored < _firstInningsRuns) {
      winningTeam = _bowlingTeam;
      final margin = _firstInningsRuns - runsScored;
      result = 'Won by $margin ${margin == 1 ? 'run' : 'runs'}';
    } else {
      result = 'Match Tied';
      winningTeam = '';
    }
    
    // Mark match as completed
    _matchCompleted = true;
    
    // Save final match data
    await _saveFinalMatchData(result, winningTeam);
    
    // Navigate to match result screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _MatchResultScreen(
            winningTeam: winningTeam,
            result: result,
            team1Name: _currentInnings == 2 ? _bowlingTeam : _battingTeam,
            team2Name: _currentInnings == 2 ? _battingTeam : _bowlingTeam,
            team1Score: '$_firstInningsRuns/$_firstInningsWickets',
            team2Score: '$runsScored/$wicketsLost',
            team1Overs: _firstInningsOvers,
            team2Overs: oversPlayed,
            matchId: widget.matchId,
          ),
        ),
      );
    }
  }
  
  // Save final match data
  Future<void> _saveFinalMatchData(String result, String winningTeam) async {
    if (widget.matchId == null) return;
    
    // Determine winner ID
    String? winnerId;
    if (winningTeam == _battingTeam) {
      // If batting team won, we need to know if they were Team 1 or Team 2 initially
      // Assuming _battingTeam name matches one of the initial team names
      // But simpler: if _currentInnings == 1, batting team is Team 1. If 2, it's Team 2.
      // Wait, strictly:
      // If Team 1 batted first:
      // Innings 1: Batting = Team 1
      // Innings 2: Batting = Team 2
      
      // If the winner is the CURRENT batting team:
      if (_currentInnings == 1) {
         winnerId = _team1Id;
      } else {
         winnerId = _team2Id;
      }
    } else if (winningTeam == _bowlingTeam) {
       // Winner is bowling team
       if (_currentInnings == 1) {
         winnerId = _team2Id;
       } else {
         winnerId = _team1Id;
       }
    } else {
      // Draw or Tie
      winnerId = null;
    }

    try {
      final matchRepo = ref.read(matchRepositoryProvider);
      await matchRepo.updateMatch(
        widget.matchId!,
        {
          'status': 'completed',
          // 'result': result, // Removed: Column does not exist
          // 'winning_team': winningTeam, // Removed: Column does not exist
          'winner_id': winnerId, 
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error saving final match data: $e');
    }
  }

  // Handle score - now opens wagon wheel for run selection
  void _handleScore(int runs) {
    _handleScoreWithWagonWheel(runs);
  }

  Future<void> _loadMatchData() async {
    if (widget.matchId == null) return;
    
    try {
      final matchRepo = ref.read(matchRepositoryProvider);
      final match = await matchRepo.getMatchById(widget.matchId!);
      
      if (match != null && mounted) {
        final scorecard = match.scorecard;
        if (scorecard != null) {
          setState(() {
            final team1Score = scorecard['team1_score'] ?? {};
            final team2Score = scorecard['team2_score'] ?? {};
            _totalRuns = team1Score['runs'] ?? 0;
            _wickets = team1Score['wickets'] ?? 0;
            _currentOver = scorecard['current_over'] ?? 0;
            _currentBall = scorecard['current_ball'] ?? 0;
            _striker = scorecard['striker'] ?? _striker;
            _nonStriker = scorecard['non_striker'] ?? _nonStriker;
            _bowler = scorecard['bowler'] ?? _bowler;
            _strikerRuns = scorecard['striker_runs'] ?? 0;
            _strikerBalls = scorecard['striker_balls'] ?? 0;
            _nonStrikerRuns = scorecard['non_striker_runs'] ?? 0;
            _nonStrikerBalls = scorecard['non_striker_balls'] ?? 0;
            _bowlerOvers = (scorecard['bowler_overs'] ?? 0.0).toDouble();
            _bowlerRuns = scorecard['bowler_runs'] ?? 0;
            _bowlerWickets = scorecard['bowler_wickets'] ?? 0;
            _crr = (scorecard['crr'] ?? 0.0).toDouble();
            _projected = scorecard['projected'] ?? 0;
            _currentOverBalls = List<String>.from(scorecard['current_over_balls'] ?? []);
            _overHistory = (scorecard['over_history'] as List<dynamic>?)
                ?.map((e) => List<String>.from(e))
                .toList() ?? [];
            
            // Store team IDs
            _team1Id = match.team1Id;
            _team2Id = match.team2Id;
                
            // Load dismissed players
            _dismissedPlayers = List<String>.from(scorecard['dismissed_players'] ?? []);
            _usedBowlers = List<String>.from(scorecard['used_bowlers'] ?? []);
            _isDeclaredRun = scorecard['is_declared_run'] ?? false;
            _isShortRun = scorecard['is_short_run'] ?? false;
            if (scorecard['dismissal_types'] != null) {
              _dismissalTypes = Map<String, String>.from(scorecard['dismissal_types'] as Map);
            }
            if (scorecard['run_out_runs'] != null) {
              _runOutRuns = Map<String, int>.from(
                (scorecard['run_out_runs'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value as int),
                ),
              );
            }
            if (scorecard['retired_hurt_players'] != null) {
              _retiredHurtPlayers = Set<String>.from(scorecard['retired_hurt_players'] as List);
            }
            _currentInnings = scorecard['current_innings'] ?? 1;
            _firstInningsRuns = scorecard['first_innings_runs'] ?? 0;
            _firstInningsWickets = scorecard['first_innings_wickets'] ?? 0;
            _firstInningsOvers = (scorecard['first_innings_overs'] ?? 0.0).toDouble();
            _bowlerType = scorecard['bowler_type'];
            _bowlerCategory = scorecard['bowler_category'];
            if (scorecard['bowler_metadata'] != null) {
              _bowlerMetadata = Map<String, Map<String, String>>.from(
                (scorecard['bowler_metadata'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    Map<String, String>.from(value as Map),
                  ),
                ),
              );
            }
            if (scorecard['bowler_overs_map'] != null) {
              _bowlerOversMap = Map<String, double>.from(
                (scorecard['bowler_overs_map'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    (value as num).toDouble(),
                  ),
                ),
              );
            }
            // Restore bowler legal balls map (ICC rule: track total legal balls)
            if (scorecard['bowler_legal_balls_map'] != null) {
              _bowlerLegalBallsMap = Map<String, int>.from(
                (scorecard['bowler_legal_balls_map'] as Map).map(
                  (key, value) => MapEntry(
                    key.toString(),
                    value as int,
                  ),
                ),
              );
            }
            // Restore total valid balls
            _totalValidBalls = scorecard['total_valid_balls'] ?? 0;
            // Restore waiting state
            _waitingForBowlerSelection = scorecard['waiting_for_bowler_selection'] ?? false;
            
            // Recalculate bowler overs from legal balls (ICC rule)
            if (_bowler.isNotEmpty && _bowlerLegalBallsMap.containsKey(_bowler)) {
              _updateBowlerOvers();
            }
            if (scorecard['batting_type_map'] != null) {
              _battingTypeMap = Map<String, String>.from(scorecard['batting_type_map'] as Map);
            }
            if (scorecard['batsmen_who_have_batted'] != null) {
              _batsmenWhoHaveBatted = Set<String>.from(scorecard['batsmen_who_have_batted'] as List);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load match data: $e');
    }
  }

  // Show out type selection popup
  void _showOutTypeSelection() {
    // Check if max wickets reached (squad size - 1)
    if (_wickets >= _maxWickets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All out! Innings complete.')),
      );
      _endInnings();
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Type of Out',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            // Out type options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _buildOutTypeButton('LBW', () => _handleOutType('LBW')),
                  _buildOutTypeButton('Run Out', () => _handleRunOutSelection()),
                  _buildOutTypeButton('Catch Out', () => _handleOutType('Catch Out')),
                  _buildOutTypeButton('Bowled', () => _handleOutType('Bowled')),
                  _buildOutTypeButton('Hit Wicket', () => _handleOutType('Hit Wicket')),
                  _buildOutTypeButton('Retired Hurt', () => _handleOutType('Retired Hurt')),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // Build out type button
  Widget _buildOutTypeButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
  
  // Handle run out selection (with runs)
  void _handleRunOutSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Runs Completed on Run Out',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  _buildRunOutButton('+0', 0),
                  _buildRunOutButton('+1', 1),
                  _buildRunOutButton('+2', 2),
                  _buildRunOutButton('+3', 3),
                  _buildRunOutButton('Custom', null),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // Build run out runs button
  Widget _buildRunOutButton(String label, int? runs) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (runs != null) {
          _handleOutType('Run Out', runsCompleted: runs);
        } else {
          _showCustomRunOutInput();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
  
  // Show custom run out input
  void _showCustomRunOutInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Runs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter runs completed on run out'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Runs',
                hintText: '0, 1, 2, 3...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final runs = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              if (runs >= 0) {
                _handleOutType('Run Out', runsCompleted: runs);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  // Handle out type selection
  void _handleOutType(String outType, {int runsCompleted = 0}) {
    // ICC Rule: Block all scoring when waiting for bowler selection (end-of-over lock)
    if (_waitingForBowlerSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select next bowler to continue')),
      );
      return;
    }
    
    // Check if max wickets reached (squad size - 1)
    if (_wickets >= _maxWickets && outType != 'Retired Hurt') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All out! Innings complete.')),
      );
      _endInnings();
      return;
    }
    
    final isRetiredHurt = outType == 'Retired Hurt';
    final isRunOut = outType == 'Run Out';
    
    // Store striker name BEFORE any swaps (for correct commentary attribution)
    final dismissedStriker = _striker;
    
    // For Run Out, add runs to total
    if (isRunOut && runsCompleted > 0) {
      _totalRuns += runsCompleted;
      _strikerRuns += runsCompleted;
      
      // Check if target chased in second innings (Match Won)
      if (_currentInnings == 2 && _totalRuns > _firstInningsRuns) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _endInnings();
        });
      }
    }
    
    // Save state for undo
    _saveStateForUndo(
      runs: isRunOut ? runsCompleted : 0,
      ballNotation: isRunOut ? 'RO$runsCompleted' : (isRetiredHurt ? 'RH' : 'W'),
    );
    
    setState(() {
      _isDeclaredRun = false;
      _isShortRun = false;
      
      // Retired Hurt does NOT increment wickets
      if (!isRetiredHurt) {
        _wickets += 1;
        _bowlerWickets += 1;
        _dismissedPlayers.add(_striker);
      } else {
        _retiredHurtPlayers.add(_striker);
      }
      
      // Save dismissal type
      _dismissalTypes[_striker] = outType;
      if (isRunOut) {
        _runOutRuns[_striker] = runsCompleted;
      }
      
      // Wicket counts as a ball (ICC rule) - but Retired Hurt also counts as a ball
      _currentBall += 1;
      // Increment bowler's legal balls and update overs (ICC rule)
      _incrementBowlerLegalBalls();
      
      // Add to current over balls
      String ballNotation = isRetiredHurt ? 'RH' : (isRunOut ? 'RO$runsCompleted' : 'W');
      _currentOverBalls.add(ballNotation);
      
      // Check if over is complete
      bool overComplete = false;
      if (_currentBall >= 6) {
        // Save current over to history
        _overHistory.add(List<String>.from(_currentOverBalls));
        _currentBall = 0;
        _currentOver += 1;
        overComplete = true;
        // DON'T clear _currentOverBalls here - keep visible until new bowler is selected
        // _currentOverBalls = []; // Moved to bowler selection
        // Set flag to wait for bowler selection (end-of-over lock)
        _waitingForBowlerSelection = true;
      }
      
      // For Run Out: Strike changes based on runs completed
      // Odd runs → strike changes, Even runs → strike remains same
      if (isRunOut) {
        if (runsCompleted % 2 == 1 || overComplete) {
          _swapBatsmen();
        }
      } else if (overComplete) {
        // For other dismissals: swap on over completion
        _swapBatsmen();
      }
      
      // Update CRR
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Record delivery (single source of truth)
      _recordDelivery(
        over: _currentOver,
        ball: _currentBall,
        striker: dismissedStriker, // Striker before dismissal
        nonStriker: _nonStriker,
        bowler: _bowler,
        runs: isRunOut ? runsCompleted : 0,
        teamTotal: _totalRuns,
        strikerRuns: _strikerRuns,
        strikerBalls: _strikerBalls,
        bowlerRuns: _bowlerRuns,
        bowlerLegalBalls: _bowlerLegalBallsMap[_bowler] ?? 0,
        wickets: _wickets,
        wicketType: outType,
        extraType: null,
        extraRuns: null,
        isLegalBall: true, // Wicket counts as legal ball
        isShortRun: false,
        commentaryId: null,
        shotDirection: null,
        shotType: null,
      );
      
      // Check if all out (only if not Retired Hurt)
      if (!isRetiredHurt && _wickets >= _maxWickets) {
        _endInnings();
      }
    });
    
    _saveScorecardToSupabase();
    
    // STEP 3: Generate commentary for wicket (valid ball) - MUST BE DONE IMMEDIATELY
    // Use the striker name BEFORE it's changed (stored before setState)
    // Note: dismissedStriker was already captured before setState, so use it
    _generateCommentaryWithStriker(
      strikerName: dismissedStriker,
      ballType: 'wicket',
      runs: isRunOut ? runsCompleted : 0,
      wicketType: outType,
      isValidBall: true,
    ).then((commentaryId) {
      // Update undo stack with commentary ID
      if (_undoStack.isNotEmpty && commentaryId != null) {
        final lastEntry = _undoStack.removeLast();
        _undoStack.add(_BallData(
          runs: lastEntry.runs,
          totalRuns: lastEntry.totalRuns,
          wickets: lastEntry.wickets,
          currentOver: lastEntry.currentOver,
          currentBall: lastEntry.currentBall,
          striker: lastEntry.striker,
          nonStriker: lastEntry.nonStriker,
          strikerRuns: lastEntry.strikerRuns,
          strikerBalls: lastEntry.strikerBalls,
          nonStrikerRuns: lastEntry.nonStrikerRuns,
          nonStrikerBalls: lastEntry.nonStrikerBalls,
          bowlerOvers: lastEntry.bowlerOvers,
          bowlerRuns: lastEntry.bowlerRuns,
          bowlerWickets: lastEntry.bowlerWickets,
          ballNotation: lastEntry.ballNotation,
          shotDirection: lastEntry.shotDirection,
          shotType: lastEntry.shotType,
          extraType: lastEntry.extraType,
          extraRuns: lastEntry.extraRuns,
          commentaryId: commentaryId,
          totalValidBalls: lastEntry.totalValidBalls,
          bowlerLegalBalls: lastEntry.bowlerLegalBalls,
        ));
      }
    });
    
    // STEP 4: Show new batsman selection (unless all out) - AFTER commentary generated
    if (isRetiredHurt) {
      // For Retired Hurt, show new batsman selection
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (_retiredHurtPlayers.length + _wickets < _battingTeamPlayers.length - 1) {
          await _showSelectNewBatsman();
        }
      });
    } else if (_wickets < _maxWickets) {
      Future.delayed(const Duration(milliseconds: 300), () async {
        await _showSelectNewBatsman();
      });
    }
    
    // If over is complete, show next bowler selection (mandatory, blocking)
    if (_waitingForBowlerSelection && (_wickets < _maxWickets || isRetiredHurt)) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _showSelectNextBowler();
      });
    }
  }

  /// Generate and save commentary entry for the current ball
  /// Also tracks ball data for over summary generation
  /// Uses the current _striker for commentary attribution
  /// Returns the commentary ID for undo tracking
  Future<String?> _generateCommentary({
    required String ballType,
    required int runs,
    String? wicketType,
    String? shotDirection,
    String? shotType,
    bool isExtra = false,
    String? extraType,
    int? extraRuns,
    bool isValidBall = true, // true for normal balls, false for wides/no-balls
  }) async {
    return await _generateCommentaryWithStriker(
      strikerName: _striker,
      ballType: ballType,
      runs: runs,
      wicketType: wicketType,
      shotDirection: shotDirection,
      shotType: shotType,
      isExtra: isExtra,
      extraType: extraType,
      extraRuns: extraRuns,
      isValidBall: isValidBall,
    );
  }

  /// Generate and save commentary entry with explicit striker name
  /// This ensures correct attribution when striker has been swapped
  /// Returns the commentary ID for undo tracking
  Future<String?> _generateCommentaryWithStriker({
    required String strikerName,
    required String ballType,
    required int runs,
    String? wicketType,
    String? shotDirection,
    String? shotType,
    bool isExtra = false,
    String? extraType,
    int? extraRuns,
    bool isValidBall = true, // true for normal balls, false for wides/no-balls
  }) async {
    // If matchId is null (e.g. local practice), skip commentary persistence
    if (widget.matchId == null) {
      print('Commentary: Skipping - matchId is null');
      return null;
    }

    try {
      print('Commentary: Generating for matchId=${widget.matchId}, ballType=$ballType, runs=$runs, isValidBall=$isValidBall');
      // We'll compute a single over value for display/commentary
      double overDecimal;

      // Track valid balls (excluding wides/no-balls)
      if (isValidBall) {
        // Increment valid ball count FIRST
        _totalValidBalls++;

        // Calculate over and ball using CORRECT formula:
        // over = (totalValidBalls - 1) ~/ 6
        // ball = ((totalValidBalls - 1) % 6) + 1
        // This ensures: 1→0.1, 2→0.2, 3→0.3, 4→0.4, 5→0.5, 6→0.6, 7→1.1
        final over = (_totalValidBalls - 1) ~/ 6;
        final ball = ((_totalValidBalls - 1) % 6) + 1;
        overDecimal = over + (ball / 10.0); // e.g., 0.1, 0.2, ..., 0.6, 1.1

        // Track current over's ball data for summary
        // Store ball outcome for display (e.g., "4", "W", "0", "1", "B2", "LB1")
        String displayValue;
        if (ballType == 'wicket') {
          displayValue = wicketType == 'Run Out' ? 'RO' : 'W';
        } else if (isExtra && extraType != null) {
          if (extraType == 'B') {
            displayValue = runs > 0 ? 'B$runs' : 'B';
          } else if (extraType == 'LB') {
            displayValue = runs > 0 ? 'LB$runs' : 'LB';
          } else {
            displayValue = runs.toString();
          }
        } else {
          displayValue = runs.toString();
        }
        
        _currentOverBallData.add({
          'runs': runs,
          'isWicket': ballType == 'wicket',
          'displayValue': displayValue,
        });

        // Check if over is complete (ball == 6 means we just completed the 6th legal ball)
        // Generate summary AFTER the 6th ball, positioned AFTER 0.6 (not before)
        if (ball == 6) {
          // Generate summary for the completed over
          // Position it AFTER the last ball (0.6) by using over + 0.7
          await _generateOverSummary(over);
          _currentOverBallData.clear();
        }
      } else {
        // For invalid balls (wides/no-balls), use current valid ball position
        final over = (_totalValidBalls - 1) ~/ 6;
        final ball = ((_totalValidBalls - 1) % 6) + 1;
        overDecimal = over + (ball / 10.0);
      }

      // Generate CricHeroes-style commentary text
      // Use the provided strikerName (who faced the ball) for correct attribution
      final commentaryText = CommentaryService.generateCommentary(
        over: overDecimal,
        ballType: ballType,
        runs: runs,
        strikerName: strikerName,
        bowlerName: _bowler,
        wicketType: wicketType,
        shotDirection: shotDirection,
        shotType: shotType,
        isExtra: isExtra,
        extraType: extraType,
        extraRuns: extraRuns,
      );

      final commentary = CommentaryModel(
        id: const Uuid().v4(),
        matchId: widget.matchId!,
        over: overDecimal,
        ballType: ballType,
        runs: runs,
        wicketType: wicketType,
        strikerName: strikerName, // Use the striker who faced the ball
        bowlerName: _bowler,
        nonStrikerName: _nonStriker,
        timestamp: DateTime.now(),
        commentaryText: commentaryText,
        shotDirection: shotDirection,
        shotType: shotType,
        isExtra: isExtra,
        extraType: extraType,
        extraRuns: extraRuns,
      );

      // Use repository provider to persist commentary
      final repository = ref.read(commentaryRepositoryProvider);
      final created = await repository.createCommentary(commentary);
      print('Commentary: Successfully saved - ${commentary.commentaryText}');
      return created.id; // Return commentary ID for undo tracking
    } catch (e) {
      // Commentary is non-critical; log and continue
      // ignore: avoid_print
      print('Error generating commentary: $e');
      return null;
    }
  }
  
  /// Generate and save over summary
  /// Called when 6 valid balls are completed
  /// overNumber is the completed over (e.g., 0 means over 0 is done, 1 means over 1 is done)
  /// ICC Rule: Over summary appears AFTER the 6th legal ball (0.6, 1.6, etc.)
  Future<void> _generateOverSummary(int overNumber) async {
    if (widget.matchId == null || _currentOverBallData.isEmpty) return;
    
    try {
      // Use the ball data we've been tracking (before it was cleared)
      // Get display values for the 6 legal balls (e.g., "4", "0", "W", "B2", "LB1", "6")
      final ballDisplayValues = _currentOverBallData.map((b) => b['displayValue'] as String).toList();
      final ballRuns = _currentOverBallData.map((b) => b['runs'] as int).toList();
      final ballWickets = _currentOverBallData.map((b) => b['isWicket'] as bool).toList();
      
      final runsInOver = ballRuns.fold(0, (sum, runs) => sum + runs);
      final wicketsInOver = ballWickets.where((w) => w).length;
      
      // Get current batting pair stats AFTER end-of-over strike rotation
      // (strike has already rotated at this point)
      final strikerRuns = _strikerRuns;
      final strikerBalls = _strikerBalls;
      final nonStrikerRuns = _nonStrikerRuns;
      final nonStrikerBalls = _nonStrikerBalls;
      
      // Create over summary entry with enhanced format
      // Format: "OVER 0\n4 0 W B2 LB1 6\n13 Runs | 1 Wkt | 95/3\nStriker: Player1 45(30) | Non-Striker: Player2 12(18)"
      final summaryText = 'OVER $overNumber\n'
          '${ballDisplayValues.join(' ')}\n'
          '$runsInOver Runs | $wicketsInOver Wkt | $_totalRuns/$_wickets\n'
          'Striker: $_striker $strikerRuns($strikerBalls) | Non-Striker: $_nonStriker $nonStrikerRuns($nonStrikerBalls)';
      
      // Position summary AFTER the 6th ball (0.6, 1.6, etc.)
      // Use over + 0.7 to ensure it appears after 0.6 but before next over's 1.1
      final summaryCommentary = CommentaryModel(
        id: const Uuid().v4(),
        matchId: widget.matchId!,
        over: overNumber + 0.7, // e.g., 0.7 appears after 0.6, 1.7 appears after 1.6
        ballType: 'overSummary',
        runs: runsInOver,
        strikerName: _striker, // Current striker after rotation
        bowlerName: _bowler,
        nonStrikerName: _nonStriker, // Current non-striker after rotation
        timestamp: DateTime.now(), // Current timestamp (after the 6th ball)
        commentaryText: summaryText,
      );
      
      final repository = ref.read(commentaryRepositoryProvider);
      await repository.createCommentary(summaryCommentary);
      print('Over Summary: Generated for over $overNumber - $summaryText');
    } catch (e) {
      print('Error generating over summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
                    onPressed: () {
                      // Directly navigate to dashboard, not back through navigation stack
                      context.go('/');
                    },
                  ),
                  const Text(
                    'Live Coverage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Commentary Button
                      if (widget.matchId != null)
                        IconButton(
                          icon: const Icon(Icons.comment, color: AppColors.textMain),
                          tooltip: 'View Commentary',
                          onPressed: () {
                            context.push('/commentary/${widget.matchId}');
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: AppColors.textMain),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // YouTube Live Stream Video with Scoring Bar Overlay
            if (_youtubeController != null)
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 9 / 16, // 16:9 aspect ratio
                color: AppColors.background,
                child: Stack(
                  children: [
                    // YouTube Player
                    YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: AppColors.urgent,
                      progressColors: const ProgressBarColors(
                        playedColor: AppColors.urgent,
                        handleColor: AppColors.urgent,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.grey,
                      ),
                      onReady: () {
                        // Video is ready to play
                      },
                    ),
                    // Live Scoring Bar Overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildLiveScoringBarOverlay(),
                    ),
                  ],
                ),
              ),

            // Scorecard and Content - Use Expanded with proper constraints
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_youtubeController != null) const SizedBox(height: 16),
                    
                    // Main Score Card - Matching reference design
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Innings Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentInnings == 1 ? '1ST INNINGS' : '2ND INNINGS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[500],
                                      letterSpacing: 1.0,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _battingTeam,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // LIVE Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC72B32),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'CRR: ${_crr.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Large Score Display
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_totalRuns',
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2), // Blue color for runs
                                  fontFamily: 'Inter',
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                '/$_wickets',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                  fontFamily: 'Inter',
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_currentOver.${_currentBall} Ov',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[500],
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Vs and Projected Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vs $_bowlingTeam',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                'Projected: $_projected',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Current Over Section - STRICT ICC CHRONOLOGICAL ORDER
                          // Wide/No Ball appears inline at exact position it occurred
                          Text(
                            'Current Over',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Ball-by-ball display - CHRONOLOGICAL ORDER
                          // Deliveries appear exactly in the sequence they occurred
                          // Empty buckets appended at end for remaining legal balls
                          Builder(
                            builder: (context) {
                              // Count legal balls (excluding Wide/No Ball)
                              int legalBallCount = 0;
                              for (final ball in _currentOverBalls) {
                                if (!ball.startsWith('WD') && !ball.startsWith('NB')) {
                                  legalBallCount++;
                                }
                              }
                              
                              // Calculate empty slots needed (6 - legal balls bowled)
                              final emptySlots = 6 - legalBallCount;
                              
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  // Show ALL deliveries in chronological order (legal + illegal inline)
                                  ..._currentOverBalls.map((ball) => _buildBallIndicator(ball)),
                                  // Append empty slots for remaining legal balls
                                  ...List.generate(
                                    emptySlots > 0 ? emptySlots : 0,
                                    (index) => _buildEmptyBallSlot(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Batter Card - Clean design matching reference
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Batter Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Batter',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Center(
                                  child: Text(
                                    'R',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Center(
                                  child: Text(
                                    'B',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 45,
                                child: Center(
                                  child: Text(
                                    'SR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          
                          // Striker Row
                          InkWell(
                            onTap: _showManualStrikerChange,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sports_cricket,
                                        color: const Color(0xFF1976D2),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '$_striker *',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1976D2),
                                            fontFamily: 'Inter',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Text(
                                      '$_strikerRuns',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Text(
                                      '$_strikerBalls',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Center(
                                    child: Text(
                                      _strikerSR.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Non-Striker Row
                          InkWell(
                            onTap: _showManualStrikerChange,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 26),
                                    child: Text(
                                      _nonStriker,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                        fontFamily: 'Inter',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Text(
                                      '$_nonStrikerRuns',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Text(
                                      '$_nonStrikerBalls',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Center(
                                    child: Text(
                                      _nonStrikerSR.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey[200], height: 1),
                          const SizedBox(height: 16),
                          
                          // Bowler Section
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFC72B32),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BOWLER',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.8,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _bowler.length > 8 ? '${_bowler.substring(0, 8)}.' : _bowler,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Bowler Stats
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'O',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatBowlerOvers(_bowlerLegalBallsMap[_bowler] ?? 0),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    children: [
                                      Text(
                                        'R',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_bowlerRuns',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    children: [
                                      Text(
                                        'W',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_bowlerWickets',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC72B32),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Scoring Control Card - Clean design matching reference
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SCORING CONTROL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                  letterSpacing: 1.0,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (_isDeclaredRun)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14B8A6).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Declared Run',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D9488),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              if (_isShortRun)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF14B8A6).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Short Run',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D9488),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Score Buttons - First row (0, 1, 2, 3)
                          Row(
                            children: [
                              Expanded(child: _buildCleanScoreButton('0', () => _handleScore(0))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanScoreButton('1', () => _handleScore(1))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanScoreButton('2', () => _handleScore(2))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanScoreButton('3', () => _handleScore(3))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Second row (4, 6, Wide, NB)
                          Row(
                            children: [
                              Expanded(child: _buildCleanScoreButton('4', () => _handleScore(4), isHighlight: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanScoreButton('6', () => _handleScore(6), isHighlight: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanExtrasButton('WD', () => _showWideBallBottomSheet())),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanExtrasButton('NB', () => _showNoBallBottomSheet())),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Third row (Byes, LB, 5/7, OUT)
                          Row(
                            children: [
                              Expanded(child: _buildCleanExtrasButton('B', () => _showByesBottomSheet(), isGreen: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanExtrasButton('LB', () => _showLegByesBottomSheet(), isGreen: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanScoreButton('5/7', () => _showCustomRunsInput())),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCleanOutButton()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Undo Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _undoLastBall,
                              icon: Icon(Icons.undo, size: 18, color: Colors.grey[600]),
                              label: Text(
                                'Undo Last Ball',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                  fontFamily: 'Inter',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // View Full Scorecard
                          Center(
                            child: TextButton(
                              onPressed: _showFullScorecard,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Full Scorecard',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 14, color: Colors.grey[600]),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build ball indicator widget with proper styling
  Widget _buildBallIndicator(String ball) {
    final isWicket = ball == 'W';
    final isWide = ball.startsWith('WD');
    final isNoBall = ball.startsWith('NB');
    final isByes = ball.startsWith('B') || ball.startsWith('LB');
    final isFour = ball == '4';
    final isSix = ball == '6';
    final isZero = ball == '0';
    final isDeclaredRun = ball.contains('(DR)');
    final isShortRun = ball.contains('(SR)');
    
    // Color logic with subtle gradients
    Gradient? backgroundGradient;
    Color? backgroundColor;
    Color textColor = AppColors.textMain;
    
    if (isWicket) {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = Colors.white;
    } else if (isSix) {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = Colors.white;
    } else if (isFour) {
      backgroundGradient = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = Colors.white;
    } else if (isWide || isNoBall) {
      backgroundGradient = LinearGradient(
        colors: [
          const Color(0xFFFB923C).withOpacity(0.2),
          const Color(0xFFF97316).withOpacity(0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = const Color(0xFFFB923C);
    } else if (isZero) {
      backgroundGradient = LinearGradient(
        colors: [Colors.grey[300]!, Colors.grey[200]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = Colors.grey[700]!;
    } else if (isDeclaredRun || isShortRun) {
      backgroundGradient = LinearGradient(
        colors: [
          const Color(0xFF14B8A6).withOpacity(0.2),
          const Color(0xFF0D9488).withOpacity(0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      textColor = const Color(0xFF0D9488);
    } else {
      backgroundColor = AppColors.surface;
      textColor = AppColors.textMain;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: (isWicket || isFour || isSix)
            ? null
            : Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
        boxShadow: (isWicket || isFour || isSix)
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        ball.replaceAll('(DR)', '').replaceAll('(SR)', '').trim(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: 'Inter',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
  
  // Build empty ball slot
  Widget _buildEmptyBallSlot() {
    return Container(
      width: 48,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildScoreButton(String label, VoidCallback onTap, bool isHighlighted) {
    // ICC Rule: Disable scoring when waiting for bowler selection (end-of-over lock)
    final isDisabled = _waitingForBowlerSelection;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? AppColors.primary
                : AppColors.borderLight,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? Colors.white : AppColors.primary,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtrasButton(String label, VoidCallback onTap, {bool isGreen = false}) {
    // ICC Rule: Disable scoring when waiting for bowler selection (end-of-over lock)
    final isDisabled = _waitingForBowlerSelection;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGreen
                ? AppColors.success.withOpacity(0.3)
                : AppColors.warning.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGreen
                  ? AppColors.success
                  : AppColors.warning,
              height: 1.3,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutButton() {
    // ICC Rule: Disable scoring when waiting for bowler selection (end-of-over lock)
    final isDisabled = _waitingForBowlerSelection;
    return InkWell(
      onTap: isDisabled ? null : _showOutTypeSelection,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.urgent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.urgent.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_baseball, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              const Text(
                'OUT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Clean score button matching reference design
  Widget _buildCleanScoreButton(String label, VoidCallback onTap, {bool isHighlight = false}) {
    // ICC Rule: Disable scoring when waiting for bowler selection (end-of-over lock)
    final isDisabled = _waitingForBowlerSelection;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlight 
                ? const Color(0xFFFFB74D).withOpacity(0.5) 
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isHighlight ? const Color(0xFFF57C00) : Colors.grey[800],
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  // Clean extras button matching reference design
  Widget _buildCleanExtrasButton(String label, VoidCallback onTap, {bool isGreen = false}) {
    // ICC Rule: Disable scoring when waiting for bowler selection (end-of-over lock)
    final isDisabled = _waitingForBowlerSelection;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isGreen 
              ? const Color(0xFFE8F5E9) 
              : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGreen 
                ? const Color(0xFF66BB6A).withOpacity(0.5) 
                : const Color(0xFFFFB74D).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGreen ? const Color(0xFF388E3C) : const Color(0xFFF57C00),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  // Clean OUT button matching reference design
  Widget _buildCleanOutButton() {
    // ICC Rule: Disable scoring when waiting for bowler selection (end-of-over lock)
    final isDisabled = _waitingForBowlerSelection;
    return InkWell(
      onTap: isDisabled ? null : _showOutTypeSelection,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFC72B32),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC72B32).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'OUT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }


  void _showFullScorecard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Full Scorecard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Match Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_battingTeam vs $_bowlingTeam',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_currentOver}.$_currentBall Overs | $_totalRuns/$_wickets',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Batting Stats
                    const Text(
                      'Batting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFullBattingTable(),
                    
                    const SizedBox(height: 24),
                    
                    // Bowling Stats
                    const Text(
                      'Bowling',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFullBowlingTable(),
                    
                    const SizedBox(height: 24),
                    
                    // Fall of Wickets
                    const Text(
                      'Fall of Wickets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFallOfWickets(),
                    const SizedBox(height: 24), // Extra padding at bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildFullBattingTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(1),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            children: [
              _buildTableCell('Batter', isHeader: true),
              _buildTableCell('R', isHeader: true),
              _buildTableCell('B', isHeader: true),
              _buildTableCell('4s', isHeader: true),
              _buildTableCell('6s', isHeader: true),
              _buildTableCell('SR', isHeader: true),
            ],
          ),
          // Striker
          TableRow(
            children: [
              _buildTableCell('$_striker *', isHeader: false),
              _buildTableCell('$_strikerRuns', isHeader: false),
              _buildTableCell('$_strikerBalls', isHeader: false),
              _buildTableCell('${(_strikerRuns / 4).floor()}', isHeader: false),
              _buildTableCell('${(_strikerRuns / 6).floor()}', isHeader: false),
              _buildTableCell(_strikerSR.toStringAsFixed(1), isHeader: false),
            ],
          ),
          // Non-Striker
          TableRow(
            children: [
              _buildTableCell(_nonStriker, isHeader: false),
              _buildTableCell('$_nonStrikerRuns', isHeader: false),
              _buildTableCell('$_nonStrikerBalls', isHeader: false),
              _buildTableCell('${(_nonStrikerRuns / 4).floor()}', isHeader: false),
              _buildTableCell('${(_nonStrikerRuns / 6).floor()}', isHeader: false),
              _buildTableCell(_nonStrikerSR.toStringAsFixed(1), isHeader: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullBowlingTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(1),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey[100],
            ),
            children: [
              _buildTableCell('Bowler', isHeader: true),
              _buildTableCell('O', isHeader: true),
              _buildTableCell('M', isHeader: true),
              _buildTableCell('R', isHeader: true),
              _buildTableCell('W', isHeader: true),
              _buildTableCell('Econ', isHeader: true),
            ],
          ),
          // Current Bowler
          TableRow(
            children: [
              _buildTableCell(_bowler, isHeader: false),
              _buildTableCell(_formatBowlerOvers(_bowlerLegalBallsMap[_bowler] ?? 0), isHeader: false),
              _buildTableCell('0', isHeader: false),
              _buildTableCell('$_bowlerRuns', isHeader: false),
              _buildTableCell('$_bowlerWickets', isHeader: false),
              _buildTableCell((_bowlerRuns / (_bowlerOvers > 0 ? _bowlerOvers : 1)).toStringAsFixed(2), isHeader: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallOfWickets() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1st Wicket: ${(_totalRuns * 0.3).round()}/${_wickets} (${(_currentOver >= 2 ? _currentOver - 2 : 0)}.${_currentBall})'),
          if (_wickets > 1)
            Text('2nd Wicket: ${(_totalRuns * 0.5).round()}/${_wickets} (${(_currentOver >= 1 ? _currentOver - 1 : 0)}.${_currentBall})'),
          if (_wickets > 2)
            Text('3rd Wicket: ${(_totalRuns * 0.7).round()}/${_wickets} (${_currentOver}.${_currentBall})'),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {required bool isHeader}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 13,
          color: isHeader ? Colors.black87 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildLiveScoringBarOverlay() {
    // Get next bowler (simplified - you can enhance this)
    final nextBowler = _bowlingTeamPlayers.isNotEmpty && 
                       _bowlingTeamPlayers.length > 1
                       ? _bowlingTeamPlayers[1] 
                       : 'TBD';
    
    return Container(
      child: Stack(
        children: [
          // Blurry cricket ground background
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Image.asset(
                'assets/images/Screenshot 2025-12-26 at 4.44.26 PM.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),
          // Dark gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Score Row
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Team Name and Score
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.urgent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.urgent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.urgent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: AppColors.urgent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_battingTeam $_totalRuns/$_wickets',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$_currentOver.$_currentBall Ov',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                  const SizedBox(height: 8),
                  // Batters Row
                  Row(
                children: [
                  Expanded(
                    child: _buildPlayerInfoOverlay(
                      _striker,
                      _strikerRuns,
                      _strikerBalls,
                      isStriker: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPlayerInfoOverlay(
                      _nonStriker,
                      _nonStrikerRuns,
                      _nonStrikerBalls,
                      isStriker: false,
                    ),
                  ),
                ],
              ),
                  const SizedBox(height: 6),
                  // Bowler Row
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bowler: ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '$_bowler',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' ($_bowlerOvers - $_bowlerRuns/$_bowlerWickets)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Next: ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        nextBowler,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoOverlay(String name, int runs, int balls, {required bool isStriker}) {
    final strikeRate = balls > 0 ? (runs / balls * 100).toStringAsFixed(1) : '0.0';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isStriker 
            ? AppColors.primary.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: isStriker
            ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStriker)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          if (isStriker) const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$runs ($balls) SR: $strikeRate',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show Wide Ball bottom sheet
  void _showWideBallBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildExtrasBottomSheet(
        title: 'Wide Ball (WD = 1)',
        extraType: 'WD',
        onSelect: (runs) => _handleWideWithRuns(runs),
      ),
    );
  }

  // Show No Ball bottom sheet
  void _showNoBallBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildExtrasBottomSheet(
        title: 'No Ball (NB = 1)',
        extraType: 'NB',
        onSelect: (runs) => _handleNoBallWithRuns(runs),
      ),
    );
  }

  // Show Byes bottom sheet
  void _showByesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildExtrasBottomSheet(
        title: 'Byes (B)',
        extraType: 'B',
        onSelect: (runs) => _handleByesWithRuns(runs),
      ),
    );
  }

  // Show Leg Byes bottom sheet
  void _showLegByesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildExtrasBottomSheet(
        title: 'Leg Byes (LB)',
        extraType: 'LB',
        onSelect: (runs) => _handleLegByesWithRuns(runs),
      ),
    );
  }

  // Build extras bottom sheet widget
  Widget _buildExtrasBottomSheet({
    required String title,
    required String extraType,
    required Function(int) onSelect,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
          ),
          // Buttons grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildExtrasOptionButton('$extraType + 0', () => onSelect(0)),
                _buildExtrasOptionButton('$extraType + 1', () => onSelect(1)),
                _buildExtrasOptionButton('$extraType + 2', () => onSelect(2)),
                _buildExtrasOptionButton('$extraType + 3', () => onSelect(3)),
                _buildExtrasOptionButton('$extraType + 4', () => onSelect(4)),
                _buildExtrasOptionButton('$extraType + 5', () => onSelect(5)),
                _buildExtrasOptionButton('$extraType + 6', () => onSelect(6)),
                _buildExtrasOptionButton('+', () => _showCustomExtrasInput(extraType)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Build extras option button
  Widget _buildExtrasOptionButton(String label, VoidCallback onTap) {
    final isCustom = label == '+';
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isCustom ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCustom ? AppColors.primary : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCustom ? Colors.white : AppColors.textMain,
            ),
          ),
        ),
      ),
    );
  }

  // Show custom extras input
  void _showCustomExtrasInput(String extraType) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom $extraType Runs'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter runs',
            hintText: 'e.g., 5, 7, 8',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final runs = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              if (runs >= 0) {
                switch (extraType) {
                  case 'WD':
                    _handleWideWithRuns(runs);
                    break;
                  case 'NB':
                    _handleNoBallWithRuns(runs);
                    break;
                  case 'B':
                    _handleByesWithRuns(runs);
                    break;
                  case 'LB':
                    _handleLegByesWithRuns(runs);
                    break;
                }
              }
            },
            child: Text('Apply ($extraType + ${controller.text.isEmpty ? '0' : controller.text} = ${controller.text.isEmpty ? '1' : (int.tryParse(controller.text) ?? 0) + 1})'),
          ),
        ],
      ),
    );
  }

  // Handle Wide with runs (ICC rules)
  // 1. Add 1 automatic wide run to team total
  // 2. Add runs completed by running/boundary to team total (do NOT credit batsman)
  // 3. Do NOT increment legal ball count
  // 4. Change strike only if runs completed by running (excluding the 1 wide) are odd
  // Examples: Wide + 2 = +3 total (1 wide + 2 runs), strike unchanged (2 even)
  //           Wide + 1 = +2 total (1 wide + 1 run), strike changes (1 odd)
  //           Wide boundary = +5 total (1 wide + 4 boundary), strike unchanged (4 even)
  void _handleWideWithRuns(int additionalRuns) {
    // ICC Rule: Block all scoring when waiting for bowler selection (end-of-over lock)
    if (_waitingForBowlerSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select next bowler to continue')),
      );
      return;
    }
    
    // Check if innings should end
    if (_shouldEndInnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Innings complete - All out!')),
      );
      return;
    }
    
    // ICC Rule: 1 automatic wide run + additional runs completed
    final automaticWideRun = 1;
    final runsCompleted = additionalRuns; // Runs completed by running or boundary
    final totalRuns = automaticWideRun + runsCompleted;
    
    _saveStateForUndo(
      runs: totalRuns,
      ballNotation: additionalRuns > 0 ? 'WD+$additionalRuns' : 'WD',
      extraType: 'WD',
      extraRuns: totalRuns,
    );
    
    // Store striker name BEFORE any swaps (for correct commentary attribution)
    final strikerForCommentary = _striker;
    
    setState(() {
      _isDeclaredRun = false;
      _isShortRun = false;
      
      // ICC Rule: Add 1 automatic wide + runs completed to team total
      _totalRuns += totalRuns;
      
      // Check if target chased in second innings (Match Won)
      if (_currentInnings == 2 && _totalRuns > _firstInningsRuns) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _endInnings();
        });
      }
      // ICC Rule: Wide runs count against bowler
      _bowlerRuns += totalRuns;
      // ICC Rule: Do NOT credit batsman for wide runs (not off the bat)
      // _strikerRuns is NOT incremented
      // ICC Rule: Do NOT increment balls faced (wide is not a legal delivery)
      // _strikerBalls is NOT incremented
      
      // ICC Rule: Wide doesn't count as a legal ball - DO NOT increment _currentBall
      // ICC Rule: Change strike only if runs completed by running (excluding 1 wide) are odd
      // Strike rotation based on runsCompleted, NOT totalRuns
      if (runsCompleted % 2 == 1) {
        _swapBatsmen();
      }
      
      // Add to current over balls (Wide is not a legal delivery)
      String ballNotation = additionalRuns > 0 ? 'WD+$additionalRuns' : 'WD';
      _currentOverBalls.add(ballNotation);
      
      // Update CRR (ball count doesn't change for wide)
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Record delivery (single source of truth)
      _recordDelivery(
        over: _currentOver,
        ball: _currentBall,
        striker: strikerForCommentary,
        nonStriker: _nonStriker,
        bowler: _bowler,
        runs: runsCompleted, // Only runs completed, not the automatic wide
        teamTotal: _totalRuns,
        strikerRuns: _strikerRuns, // No change for wide
        strikerBalls: _strikerBalls, // No change for wide
        bowlerRuns: _bowlerRuns,
        bowlerLegalBalls: _bowlerLegalBallsMap[_bowler] ?? 0,
        wickets: _wickets,
        wicketType: null,
        extraType: 'WD',
        extraRuns: totalRuns,
        isLegalBall: false, // Wide is not a legal ball
        isShortRun: false,
        commentaryId: null,
        shotDirection: null,
        shotType: null,
      );
    });
    _saveScorecardToSupabase();
    
    // Generate commentary for wide (NOT a valid ball - doesn't count towards over)
    // Use the striker who was on strike when the wide was bowled
    _generateCommentaryWithStriker(
      strikerName: strikerForCommentary,
      ballType: 'wide',
      runs: totalRuns,
      isExtra: true,
      extraType: 'WD',
      extraRuns: totalRuns,
      isValidBall: false, // Wide doesn't count as valid ball
    ).then((commentaryId) {
      // Update undo stack with commentary ID
      if (_undoStack.isNotEmpty && commentaryId != null) {
        final lastEntry = _undoStack.removeLast();
        _undoStack.add(_BallData(
          runs: lastEntry.runs,
          totalRuns: lastEntry.totalRuns,
          wickets: lastEntry.wickets,
          currentOver: lastEntry.currentOver,
          currentBall: lastEntry.currentBall,
          striker: lastEntry.striker,
          nonStriker: lastEntry.nonStriker,
          strikerRuns: lastEntry.strikerRuns,
          strikerBalls: lastEntry.strikerBalls,
          nonStrikerRuns: lastEntry.nonStrikerRuns,
          nonStrikerBalls: lastEntry.nonStrikerBalls,
          bowlerOvers: lastEntry.bowlerOvers,
          bowlerRuns: lastEntry.bowlerRuns,
          bowlerWickets: lastEntry.bowlerWickets,
          ballNotation: lastEntry.ballNotation,
          shotDirection: lastEntry.shotDirection,
          shotType: lastEntry.shotType,
          extraType: lastEntry.extraType,
          extraRuns: lastEntry.extraRuns,
          commentaryId: commentaryId,
          totalValidBalls: lastEntry.totalValidBalls,
          bowlerLegalBalls: lastEntry.bowlerLegalBalls,
        ));
      }
    });
  }

  // Handle No Ball with runs (ICC rules)
  // 1. Add 1 automatic no-ball run to team total
  // 2. Add runs off the bat to batsman (or byes/leg-byes if no bat)
  // 3. Do NOT increment legal ball count
  // 4. Change strike only if runs completed by running (excluding the 1 no-ball) are odd
  // Note: For no-ball + byes/leg-byes, runs are NOT credited to batsman
  void _handleNoBallWithRuns(int additionalRuns) {
    // ICC Rule: Block all scoring when waiting for bowler selection (end-of-over lock)
    if (_waitingForBowlerSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select next bowler to continue')),
      );
      return;
    }
    
    // Check if innings should end
    if (_shouldEndInnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Innings complete - All out!')),
      );
      return;
    }
    
    // ICC Rule: 1 automatic no-ball run + additional runs (off the bat or byes/leg-byes)
    final automaticNoBallRun = 1;
    final runsOffBat = additionalRuns; // Runs off the bat (or byes/leg-byes)
    final totalRuns = automaticNoBallRun + runsOffBat;
    
    _saveStateForUndo(
      runs: totalRuns,
      ballNotation: additionalRuns > 0 ? 'NB+$additionalRuns' : 'NB',
      extraType: 'NB',
      extraRuns: totalRuns,
    );
    
    // Store striker name BEFORE any swaps (for correct commentary attribution)
    final strikerForCommentary = _striker;
    
    setState(() {
      _isDeclaredRun = false;
      _isShortRun = false;
      
      // ICC Rule: Add 1 automatic no-ball + runs to team total
      _totalRuns += totalRuns;

      // Check if target chased in second innings (Match Won)
      if (_currentInnings == 2 && _totalRuns > _firstInningsRuns) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _endInnings();
        });
      }
      // ICC Rule: No-ball runs count against bowler
      _bowlerRuns += totalRuns;
      // ICC Rule: Credit batsman only if runs are off the bat
      // For now, we assume additionalRuns are off the bat (not byes/leg-byes)
      // If byes/leg-byes, they should be handled separately
      if (runsOffBat > 0) {
        _strikerRuns += runsOffBat;
        _trackBoundaries(_striker, runsOffBat);
        // Note: Balls faced is NOT incremented for no-ball (not a legal delivery)
      }
      
      // ICC Rule: No ball doesn't count as a legal ball - DO NOT increment _currentBall
      // ICC Rule: Change strike only if runs off the bat (excluding 1 no-ball) are odd
      // Strike rotation based on runsOffBat, NOT totalRuns
      if (runsOffBat % 2 == 1) {
        _swapBatsmen();
      }
      
      // Add to current over balls (No Ball is not a legal delivery)
      String ballNotation = additionalRuns > 0 ? 'NB+$additionalRuns' : 'NB';
      _currentOverBalls.add(ballNotation);
      
      // Update CRR (ball count doesn't change for no ball)
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Record delivery (single source of truth)
      _recordDelivery(
        over: _currentOver,
        ball: _currentBall,
        striker: strikerForCommentary,
        nonStriker: _nonStriker,
        bowler: _bowler,
        runs: runsOffBat, // Runs off the bat
        teamTotal: _totalRuns,
        strikerRuns: _strikerRuns,
        strikerBalls: _strikerBalls, // No change for no-ball
        bowlerRuns: _bowlerRuns,
        bowlerLegalBalls: _bowlerLegalBallsMap[_bowler] ?? 0,
        wickets: _wickets,
        wicketType: null,
        extraType: 'NB',
        extraRuns: totalRuns,
        isLegalBall: false, // No-ball is not a legal ball
        isShortRun: false,
        commentaryId: null,
        shotDirection: null,
        shotType: null,
      );
    });
    _saveScorecardToSupabase();
    
    // Generate commentary for no ball (NOT a valid ball - doesn't count towards over)
    // Use the striker who was on strike when the no ball was bowled
    _generateCommentaryWithStriker(
      strikerName: strikerForCommentary,
      ballType: 'noBall',
      runs: totalRuns,
      isExtra: true,
      extraType: 'NB',
      extraRuns: totalRuns,
      isValidBall: false, // No ball doesn't count as valid ball
    ).then((commentaryId) {
      // Update undo stack with commentary ID
      if (_undoStack.isNotEmpty && commentaryId != null) {
        final lastEntry = _undoStack.removeLast();
        _undoStack.add(_BallData(
          runs: lastEntry.runs,
          totalRuns: lastEntry.totalRuns,
          wickets: lastEntry.wickets,
          currentOver: lastEntry.currentOver,
          currentBall: lastEntry.currentBall,
          striker: lastEntry.striker,
          nonStriker: lastEntry.nonStriker,
          strikerRuns: lastEntry.strikerRuns,
          strikerBalls: lastEntry.strikerBalls,
          nonStrikerRuns: lastEntry.nonStrikerRuns,
          nonStrikerBalls: lastEntry.nonStrikerBalls,
          bowlerOvers: lastEntry.bowlerOvers,
          bowlerRuns: lastEntry.bowlerRuns,
          bowlerWickets: lastEntry.bowlerWickets,
          ballNotation: lastEntry.ballNotation,
          shotDirection: lastEntry.shotDirection,
          shotType: lastEntry.shotType,
          extraType: lastEntry.extraType,
          extraRuns: lastEntry.extraRuns,
          commentaryId: commentaryId,
          totalValidBalls: lastEntry.totalValidBalls,
          bowlerLegalBalls: lastEntry.bowlerLegalBalls,
        ));
      }
    });
  }

  // Handle Byes with runs (ICC rules: Byes count as a ball)
  void _handleByesWithRuns(int runs) {
    // ICC Rule: Block all scoring when waiting for bowler selection (end-of-over lock)
    if (_waitingForBowlerSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select next bowler to continue')),
      );
      return;
    }
    
    // Check if innings should end
    if (_shouldEndInnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Innings complete - All out!')),
      );
      return;
    }
    
    _saveStateForUndo(
      runs: runs,
      ballNotation: runs > 0 ? 'B$runs' : 'B',
      extraType: 'B',
      extraRuns: runs,
    );
    
    // Store striker name BEFORE any swaps (for correct commentary attribution)
    final strikerForCommentary = _striker;
    
    setState(() {
      _isDeclaredRun = false;
      _isShortRun = false;
      
      // ICC Rule 1: Byes ADD to team total
      _totalRuns += runs;

      // Check if target chased in second innings (Match Won)
      if (_currentInnings == 2 && _totalRuns > _firstInningsRuns) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _endInnings();
        });
      }
      
      // ICC Rule 2: Byes do NOT add to bowler's runs (bowler only concedes from bat, wides, no-balls)
      // _bowlerRuns is NOT incremented for byes
      
      // ICC Rule 3: Byes do NOT add to batsman's runs (extras, not off the bat)
      // _strikerRuns is NOT incremented for byes
      
      // ICC Rule 4: Byes COUNT as a legal ball - increment striker's balls faced
      _strikerBalls += 1;
      _strikerSR = _strikerBalls > 0 ? (_strikerRuns / _strikerBalls) * 100 : 0.0;
      
      // Byes count as a legal delivery (ICC rule)
      _currentBall += 1;
      // Increment bowler's legal balls and update overs (ICC rule)
      _incrementBowlerLegalBalls();
      
      // Add to current over balls
      _currentOverBalls.add(runs > 0 ? 'B$runs' : 'B');
      
      // Check if over is complete
      bool overComplete = false;
      if (_currentBall >= 6) {
        // Save current over to history
        _overHistory.add(List<String>.from(_currentOverBalls));
        _currentBall = 0;
        _currentOver += 1;
        overComplete = true;
        // DON'T clear _currentOverBalls here - keep visible until new bowler is selected
        // _currentOverBalls = []; // Moved to bowler selection
        // Set flag to wait for bowler selection (end-of-over lock)
        _waitingForBowlerSelection = true;
      }
      
      // ICC Rule 5: Strike rotation - odd runs (1,3,5) = swap, even (0,2,4) = no swap
      // ICC Rule 6: Over progression - can end the over
      if (runs % 2 == 1 || overComplete) {
        _swapBatsmen();
      }
      
      // Update CRR
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Record delivery (single source of truth)
      _recordDelivery(
        over: _currentOver,
        ball: _currentBall,
        striker: strikerForCommentary,
        nonStriker: _nonStriker,
        bowler: _bowler,
        runs: 0, // Byes don't count as runs off bat
        teamTotal: _totalRuns,
        strikerRuns: _strikerRuns, // No change for byes
        strikerBalls: _strikerBalls,
        bowlerRuns: _bowlerRuns, // No change for byes
        bowlerLegalBalls: _bowlerLegalBallsMap[_bowler] ?? 0,
        wickets: _wickets,
        wicketType: null,
        extraType: 'B',
        extraRuns: runs,
        isLegalBall: true, // Byes count as legal ball
        isShortRun: false,
        commentaryId: null,
        shotDirection: null,
        shotType: null,
      );
      
      // Check if max overs reached
      if (widget.overs != null && _currentOver >= widget.overs!) {
        _endInnings();
      }
    });
    
    _saveScorecardToSupabase();
    
    // Generate commentary for byes (valid ball)
    // Use the striker who was on strike when the byes occurred
    _generateCommentaryWithStriker(
      strikerName: strikerForCommentary,
      ballType: 'bye',
      runs: runs,
      isExtra: true,
      extraType: 'B',
      extraRuns: runs,
      isValidBall: true, // Byes count as valid ball
    ).then((commentaryId) {
      // Update undo stack with commentary ID
      if (_undoStack.isNotEmpty && commentaryId != null) {
        final lastEntry = _undoStack.removeLast();
        _undoStack.add(_BallData(
          runs: lastEntry.runs,
          totalRuns: lastEntry.totalRuns,
          wickets: lastEntry.wickets,
          currentOver: lastEntry.currentOver,
          currentBall: lastEntry.currentBall,
          striker: lastEntry.striker,
          nonStriker: lastEntry.nonStriker,
          strikerRuns: lastEntry.strikerRuns,
          strikerBalls: lastEntry.strikerBalls,
          nonStrikerRuns: lastEntry.nonStrikerRuns,
          nonStrikerBalls: lastEntry.nonStrikerBalls,
          bowlerOvers: lastEntry.bowlerOvers,
          bowlerRuns: lastEntry.bowlerRuns,
          bowlerWickets: lastEntry.bowlerWickets,
          ballNotation: lastEntry.ballNotation,
          shotDirection: lastEntry.shotDirection,
          shotType: lastEntry.shotType,
          extraType: lastEntry.extraType,
          extraRuns: lastEntry.extraRuns,
          commentaryId: commentaryId,
          totalValidBalls: lastEntry.totalValidBalls,
          bowlerLegalBalls: lastEntry.bowlerLegalBalls,
        ));
      }
    });
    
    // If over is complete, show next bowler selection (mandatory, blocking)
    if (_waitingForBowlerSelection) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showSelectNextBowler();
      });
    }
  }

  // Handle Leg Byes with runs (ICC rules: Leg Byes count as a ball)
  void _handleLegByesWithRuns(int runs) {
    // ICC Rule: Block all scoring when waiting for bowler selection (end-of-over lock)
    if (_waitingForBowlerSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select next bowler to continue')),
      );
      return;
    }
    
    // Check if innings should end
    if (_shouldEndInnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Innings complete - All out!')),
      );
      return;
    }
    
    _saveStateForUndo(
      runs: runs,
      ballNotation: runs > 0 ? 'LB$runs' : 'LB',
      extraType: 'LB',
      extraRuns: runs,
    );
    
    // Store striker name BEFORE any swaps (for correct commentary attribution)
    final strikerForCommentary = _striker;
    
    setState(() {
      _isDeclaredRun = false;
      _isShortRun = false;
      
      // ICC Rule 1: Leg Byes ADD to team total
      _totalRuns += runs;

      // Check if target chased in second innings (Match Won)
      if (_currentInnings == 2 && _totalRuns > _firstInningsRuns) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _endInnings();
        });
      }
      
      // ICC Rule 2: Leg Byes do NOT add to bowler's runs (bowler only concedes from bat, wides, no-balls)
      // _bowlerRuns is NOT incremented for leg-byes
      
      // ICC Rule 3: Leg Byes do NOT add to batsman's runs (extras, not off the bat)
      // _strikerRuns is NOT incremented for leg-byes
      
      // ICC Rule 4: Leg Byes COUNT as a legal ball - increment striker's balls faced
      _strikerBalls += 1;
      _strikerSR = _strikerBalls > 0 ? (_strikerRuns / _strikerBalls) * 100 : 0.0;
      
      // Leg Byes count as a legal delivery (ICC rule)
      _currentBall += 1;
      // Increment bowler's legal balls and update overs (ICC rule)
      _incrementBowlerLegalBalls();
      
      // Add to current over balls
      _currentOverBalls.add(runs > 0 ? 'LB$runs' : 'LB');
      
      // Check if over is complete
      bool overComplete = false;
      if (_currentBall >= 6) {
        // Save current over to history
        _overHistory.add(List<String>.from(_currentOverBalls));
        _currentBall = 0;
        _currentOver += 1;
        overComplete = true;
        // DON'T clear _currentOverBalls here - keep visible until new bowler is selected
        // _currentOverBalls = []; // Moved to bowler selection
        // Set flag to wait for bowler selection (end-of-over lock)
        _waitingForBowlerSelection = true;
      }
      
      // ICC Rule 5: Strike rotation - odd runs (1,3,5) = swap, even (0,2,4) = no swap
      // ICC Rule 6: Over progression - can end the over
      if (runs % 2 == 1 || overComplete) {
        _swapBatsmen();
      }
      
      // Update CRR
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Check if max overs reached
      if (widget.overs != null && _currentOver >= widget.overs!) {
        _endInnings();
      }
    });
    
    _saveScorecardToSupabase();
    
    // Generate commentary for leg-byes (valid ball)
    // Use the striker who was on strike when the leg-byes occurred
    _generateCommentaryWithStriker(
      strikerName: strikerForCommentary,
      ballType: 'legBye',
      runs: runs,
      isExtra: true,
      extraType: 'LB',
      extraRuns: runs,
      isValidBall: true, // Leg-byes count as valid ball
    ).then((commentaryId) {
      // Update undo stack with commentary ID
      if (_undoStack.isNotEmpty && commentaryId != null) {
        final lastEntry = _undoStack.removeLast();
        _undoStack.add(_BallData(
          runs: lastEntry.runs,
          totalRuns: lastEntry.totalRuns,
          wickets: lastEntry.wickets,
          currentOver: lastEntry.currentOver,
          currentBall: lastEntry.currentBall,
          striker: lastEntry.striker,
          nonStriker: lastEntry.nonStriker,
          strikerRuns: lastEntry.strikerRuns,
          strikerBalls: lastEntry.strikerBalls,
          nonStrikerRuns: lastEntry.nonStrikerRuns,
          nonStrikerBalls: lastEntry.nonStrikerBalls,
          bowlerOvers: lastEntry.bowlerOvers,
          bowlerRuns: lastEntry.bowlerRuns,
          bowlerWickets: lastEntry.bowlerWickets,
          ballNotation: lastEntry.ballNotation,
          shotDirection: lastEntry.shotDirection,
          shotType: lastEntry.shotType,
          extraType: lastEntry.extraType,
          extraRuns: lastEntry.extraRuns,
          commentaryId: commentaryId,
          totalValidBalls: lastEntry.totalValidBalls,
          bowlerLegalBalls: lastEntry.bowlerLegalBalls,
        ));
      }
    });
    
    // If over is complete, show next bowler selection (mandatory, blocking)
    if (_waitingForBowlerSelection) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showSelectNextBowler();
      });
    }
  }

  // Show custom runs input (for overthrows, boundary + overthrows, etc.)
  void _showCustomRunsInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Runs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter runs (e.g., 5, 7, 8 for overthrows)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Runs',
                hintText: '5, 7, 8...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final runs = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              if (runs >= 0) {
                _handleScoreWithWagonWheel(runs);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // Show wagon wheel for run selection
  void _showWagonWheel(int runs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildWagonWheelSheet(runs),
    );
  }

  // Build wagon wheel bottom sheet with image tap detection
  Widget _buildWagonWheelSheet(int runs) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Tap on Wagon Wheel ($runs runs)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
          ),
          // Wagon Wheel Image with Tap Detection - SINGLE WHEEL ONLY
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTapDown: (details) {
                  _handleWagonWheelTap(details.localPosition, runs, context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/wagon_wheel.png', // Wagon wheel image
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // If image not found, show fallback grid with correct names only
                        return _buildWagonWheelFallback(runs);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Handle tap on wagon wheel image
  void _handleWagonWheelTap(Offset localPosition, int runs, BuildContext context) {
    // Get image size (assuming square image)
    final imageSize = MediaQuery.of(context).size.width - 80; // Account for padding
    final centerX = imageSize / 2;
    final centerY = imageSize / 2;
    
    // Calculate angle and distance from center
    final dx = localPosition.dx - centerX;
    final dy = localPosition.dy - centerY;
    final angle = (180 / math.pi) * (math.atan2(dy, dx) + math.pi); // Convert to degrees (0-360)
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Map tap location to region
    String direction = _mapTapToRegion(angle, distance, imageSize);
    
    // Close wagon wheel and show shot type selection
    Navigator.pop(context);
    _showShotTypeSelection(runs, direction);
  }
  
  // Map tap coordinates to wagon wheel region - Using correct cricket fielding region names
  String _mapTapToRegion(double angle, double distance, double imageSize) {
    final radius = imageSize / 2;
    final normalizedDistance = distance / radius;
    
    // Determine region based on angle and distance
    // Use exact region names: Third Man, Deep Fine Leg, Deep Square Leg, Deep Mid-Wicket,
    // Long On, Long Off, Deep Cover, Deep Point, Off Side, Leg Side, Straight
    if (normalizedDistance < 0.3) {
      return 'Straight';
    } else if (angle >= 0 && angle < 22.5 || angle >= 337.5) {
      return 'Third Man';
    } else if (angle >= 22.5 && angle < 45) {
      return 'Deep Point';
    } else if (angle >= 45 && angle < 67.5) {
      return 'Deep Point';
    } else if (angle >= 67.5 && angle < 90) {
      return 'Deep Cover';
    } else if (angle >= 90 && angle < 112.5) {
      return 'Deep Cover';
    } else if (angle >= 112.5 && angle < 135) {
      return 'Off Side';
    } else if (angle >= 135 && angle < 157.5) {
      return 'Off Side';
    } else if (angle >= 157.5 && angle < 180) {
      return 'Long Off';
    } else if (angle >= 180 && angle < 202.5) {
      return 'Long Off';
    } else if (angle >= 202.5 && angle < 225) {
      return 'Long On';
    } else if (angle >= 225 && angle < 247.5) {
      return 'Long On';
    } else if (angle >= 247.5 && angle < 270) {
      return 'Leg Side';
    } else if (angle >= 270 && angle < 292.5) {
      return 'Leg Side';
    } else if (angle >= 292.5 && angle < 315) {
      return 'Deep Mid-Wicket';
    } else if (angle >= 315 && angle < 337.5) {
      return 'Deep Mid-Wicket';
    } else {
      // Default based on distance for edge cases
      if (normalizedDistance > 0.7) {
        if (angle >= 270 && angle < 360) {
          return 'Deep Fine Leg';
        } else if (angle >= 180 && angle < 270) {
          return 'Deep Square Leg';
        }
      }
      return 'Straight';
    }
  }
  
  // Build fallback wagon wheel (if image not available) - Use correct region names only
  Widget _buildWagonWheelFallback(int runs) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.all(16),
      children: [
        _buildWagonWheelButton('Off Side', () => _showShotTypeSelection(runs, 'Off Side')),
        _buildWagonWheelButton('Leg Side', () => _showShotTypeSelection(runs, 'Leg Side')),
        _buildWagonWheelButton('Third Man', () => _showShotTypeSelection(runs, 'Third Man')),
        _buildWagonWheelButton('Deep Point', () => _showShotTypeSelection(runs, 'Deep Point')),
        _buildWagonWheelButton('Deep Cover', () => _showShotTypeSelection(runs, 'Deep Cover')),
        _buildWagonWheelButton('Deep Mid-Wicket', () => _showShotTypeSelection(runs, 'Deep Mid-Wicket')),
        _buildWagonWheelButton('Long On', () => _showShotTypeSelection(runs, 'Long On')),
        _buildWagonWheelButton('Long Off', () => _showShotTypeSelection(runs, 'Long Off')),
        _buildWagonWheelButton('Deep Fine Leg', () => _showShotTypeSelection(runs, 'Deep Fine Leg')),
        _buildWagonWheelButton('Straight', () => _showShotTypeSelection(runs, 'Straight')),
      ],
    );
  }
  
  // Build region label
  Widget _buildRegionLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textSec,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  // Build wagon wheel button
  Widget _buildWagonWheelButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ),
      ),
    );
  }

  // Show shot type selection
  void _showShotTypeSelection(int runs, String direction) {
    final shotTypes = _getShotTypesForDirection(direction);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Shot Type ($direction)',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: shotTypes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(shotTypes[index]),
                    onTap: () {
                      Navigator.pop(context);
                      _handleScoreWithShot(runs, direction, shotTypes[index]);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Get shot types for direction
  List<String> _getShotTypesForDirection(String direction) {
    // Use correct cricket fielding region names only
    switch (direction) {
      case 'Off Side':
        return ['Cover Drive', 'Cut', 'Square Cut', 'Late Cut', 'Upper Cut'];
      case 'Leg Side':
        return ['Pull', 'Hook', 'Sweep', 'Flick', 'Leg Glance'];
      case 'Straight':
        return ['Straight Drive', 'On Drive', 'Lofted Drive'];
      case 'Third Man':
        return ['Late Cut', 'Guide', 'Deflection'];
      case 'Deep Point':
        return ['Cover Drive', 'Square Drive', 'Cut'];
      case 'Deep Cover':
        return ['Cover Drive', 'Square Drive', 'Cut'];
      case 'Deep Mid-Wicket':
        return ['Pull', 'Flick', 'Whip'];
      case 'Deep Fine Leg':
        return ['Leg Glance', 'Flick', 'Deflection'];
      case 'Deep Square Leg':
        return ['Pull', 'Sweep', 'Whip'];
      case 'Long On':
        return ['Straight Drive', 'Lofted Drive', 'On Drive'];
      case 'Long Off':
        return ['Straight Drive', 'Lofted Drive', 'Off Drive'];
      default:
        return ['Drive', 'Cut', 'Pull', 'Sweep'];
    }
  }

  // Handle score with wagon wheel and shot type
  void _handleScoreWithShot(int runs, String direction, String shotType) {
    _handleScoreWithWagonWheel(runs, direction: direction, shotType: shotType);
  }

  // Handle score with wagon wheel (called from run buttons)
  void _handleScoreWithWagonWheel(int runs, {String? direction, String? shotType}) {
    // ICC Rule: Block all scoring when waiting for bowler selection (end-of-over lock)
    if (_waitingForBowlerSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select next bowler to continue')),
      );
      return;
    }
    
    if (direction == null || shotType == null) {
      // Show wagon wheel first
      _showWagonWheel(runs);
      return;
    }
    
    // Check if innings should end
    if (_shouldEndInnings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Innings complete - All out!')),
      );
      return;
    }
    
    // ICC Rule: Short run reduces attempted runs by exactly one
    // Apply immediately to current ball (not next ball)
    final actualRuns = _isShortRun ? (runs > 0 ? runs - 1 : 0) : runs;
    
    // Save state for undo (save the actual runs scored)
    _saveStateForUndo(
      runs: actualRuns,
      ballNotation: actualRuns.toString(),
      shotDirection: direction,
      shotType: shotType,
    );
    
    // Store striker name BEFORE any swaps (for correct commentary attribution)
    final strikerForCommentary = _striker;
    // Capture short run flag before reset
    final wasShortRun = _isShortRun;
    
    setState(() {
      // Capture declared run flag before reset
      final wasDeclaredRun = _isDeclaredRun;
      // Reset flags after use
      _isDeclaredRun = false;
      _isShortRun = false;
      
      // ICC Rule: Declared runs are treated as actual runs completed by batsmen
      // ICC Rule: Short run reduces declared/attempted runs by exactly one
      // Use actual runs (reduced if short run)
      _totalRuns += actualRuns;

      // Check if target chased in second innings (Match Won)
      if (_currentInnings == 2 && _totalRuns > _firstInningsRuns) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _endInnings();
        });
      }
      // ICC Rule: Credit batsman only if off the bat (declared runs are off the bat)
      _strikerRuns += actualRuns;
      _trackBoundaries(_striker, actualRuns);
      // ICC Rule: Declared runs and short runs count as legal deliveries
      // Increment balls faced and legal ball count
      _strikerBalls += 1;
      _strikerSR = _strikerBalls > 0 ? (_strikerRuns / _strikerBalls) * 100 : 0.0;
      _bowlerRuns += actualRuns;
      
      // Increment ball (legal delivery - ICC rule)
      _currentBall += 1;
      // Increment bowler's legal balls and update overs (ICC rule)
      _incrementBowlerLegalBalls();
      
      // Add to current over balls (max 6 legal deliveries)
      String ballNotation = actualRuns.toString();
      if (wasDeclaredRun) ballNotation += ' (DR)';
      if (wasShortRun) ballNotation += ' (SR)';
      _currentOverBalls.add(ballNotation);
      
      // Check if over is complete (ICC rule: 6 legal balls = 1 over)
      bool overComplete = false;
      if (_currentBall >= 6) {
        // Save current over to history
        _overHistory.add(List<String>.from(_currentOverBalls));
        // Reset for next over
        _currentBall = 0;
        _currentOver += 1;
        overComplete = true;
        // DON'T clear _currentOverBalls here - keep visible until new bowler is selected
        // _currentOverBalls = []; // Moved to bowler selection
        // Set flag to wait for bowler selection (end-of-over lock)
        _waitingForBowlerSelection = true;
      }
      
      // ICC Rule: Strike rotation based on ACTUAL runs (after short run reduction)
      // No automatic penalty runs affect strike rotation
      // 1. Odd runs (1, 3, 5) - batsmen swap ends
      // 2. End of over (6 balls) - batsmen always swap
      if (actualRuns % 2 == 1 || overComplete) {
        _swapBatsmen();
      }
      
      // Update CRR and projected score
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Record delivery (single source of truth)
      _recordDelivery(
        over: _currentOver,
        ball: _currentBall,
        striker: strikerForCommentary, // Use striker before swap
        nonStriker: _nonStriker,
        bowler: _bowler,
        runs: actualRuns,
        teamTotal: _totalRuns,
        strikerRuns: _strikerRuns,
        strikerBalls: _strikerBalls,
        bowlerRuns: _bowlerRuns,
        bowlerLegalBalls: _bowlerLegalBallsMap[_bowler] ?? 0,
        wickets: _wickets,
        wicketType: null, // No wicket on regular scoring
        extraType: null, // Regular ball
        extraRuns: null,
        isLegalBall: true,
        isShortRun: wasShortRun,
        commentaryId: null, // Will be updated after commentary generation
        shotDirection: direction,
        shotType: shotType,
      );
      
      // Check if max overs reached
      if (widget.overs != null && _currentOver >= widget.overs!) {
        _endInnings();
      }
    });
    
    _saveScorecardToSupabase();
    
    // Generate commentary for EVERY ball (valid ball)
    // Use the striker who faced the ball (before swap) for correct attribution
    // Use actual runs (after short run reduction if applicable)
    _generateCommentaryWithStriker(
      strikerName: strikerForCommentary,
      ballType: 'normal',
      runs: actualRuns, // Use actual runs (reduced if short run)
      shotDirection: direction,
      shotType: shotType,
      isValidBall: true,
    ).then((commentaryId) {
      // Update undo stack with commentary ID for true undo
      if (_undoStack.isNotEmpty && commentaryId != null) {
        // Update the last entry with commentary ID
        final lastEntry = _undoStack.removeLast();
        _undoStack.add(_BallData(
          runs: lastEntry.runs,
          totalRuns: lastEntry.totalRuns,
          wickets: lastEntry.wickets,
          currentOver: lastEntry.currentOver,
          currentBall: lastEntry.currentBall,
          striker: lastEntry.striker,
          nonStriker: lastEntry.nonStriker,
          strikerRuns: lastEntry.strikerRuns,
          strikerBalls: lastEntry.strikerBalls,
          nonStrikerRuns: lastEntry.nonStrikerRuns,
          nonStrikerBalls: lastEntry.nonStrikerBalls,
          bowlerOvers: lastEntry.bowlerOvers,
          bowlerRuns: lastEntry.bowlerRuns,
          bowlerWickets: lastEntry.bowlerWickets,
          ballNotation: lastEntry.ballNotation,
          shotDirection: lastEntry.shotDirection,
          shotType: lastEntry.shotType,
          extraType: lastEntry.extraType,
          extraRuns: lastEntry.extraRuns,
          commentaryId: commentaryId,
          totalValidBalls: lastEntry.totalValidBalls,
          bowlerLegalBalls: lastEntry.bowlerLegalBalls,
        ));
      }
    });
    
    // If over is complete, show next bowler selection (mandatory, blocking)
    if (_waitingForBowlerSelection) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _showSelectNextBowler();
      });
    }
  }

  // Show manual striker change popup
  void _showManualStrikerChange() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Striker?'),
        content: const Text('Select reason for striker change:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeclaredRun();
            },
            child: const Text('Declared Run'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleShortRun();
            },
            child: const Text('Short Run'),
          ),
        ],
      ),
    );
  }

  // Handle declared run
  // ICC Rule: Declared runs are treated as actual runs completed by batsmen
  // They are added to team total, credited to batsman (if off the bat),
  // and increment balls faced and legal ball count
  // Note: This function just sets the flag - actual scoring happens in _handleScoreWithWagonWheel
  void _handleDeclaredRun() {
    setState(() {
      _isDeclaredRun = true;
      _isShortRun = false;
      // Note: Strike rotation will happen in _handleScoreWithWagonWheel based on actual runs
    });
    _saveScorecardToSupabase();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Declared Run flag set - score runs to apply'), duration: Duration(seconds: 1)),
    );
  }

  // Handle short run
  // ICC Rule: Short run reduces declared/attempted runs by exactly one
  // Apply reduced value consistently to team total and batsman runs
  // Count the ball as legal, rotate strike only if final reduced runs are odd
  // Note: This function just sets the flag - actual scoring happens in _handleScoreWithWagonWheel
  void _handleShortRun() {
    setState(() {
      _isShortRun = true;
      _isDeclaredRun = false;
      // Note: Strike rotation will happen in _handleScoreWithWagonWheel based on actual (reduced) runs
    });
    _saveScorecardToSupabase();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Short Run flag set - score runs to apply reduction'), duration: Duration(seconds: 1)),
    );
  }
}

// Match Result Screen Widget
// Expandable Innings Scorecard Widget
class _InningsScorecardWidget extends StatefulWidget {
  final _InningsData inningsData;
  final bool isExpanded;
  final bool isCurrentInnings;
  final VoidCallback onToggle;

  const _InningsScorecardWidget({
    required this.inningsData,
    required this.isExpanded,
    required this.isCurrentInnings,
    required this.onToggle,
  });

  @override
  State<_InningsScorecardWidget> createState() => _InningsScorecardWidgetState();
}

class _InningsScorecardWidgetState extends State<_InningsScorecardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_InningsScorecardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatOvers(double overs) {
    final wholeOvers = overs.floor();
    final balls = ((overs - wholeOvers) * 6).round();
    if (balls == 6) {
      return '${wholeOvers + 1}.0';
    }
    return '$wholeOvers.$balls';
  }
  
  Widget _buildExtrasRow(_ExtrasBreakdown extras) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Extras:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${extras.total} (${extras.format()})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSec,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTotalRow(_InningsData inningsData) {
    final crr = inningsData.overs > 0 
        ? (inningsData.runs / inningsData.overs) 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total ${inningsData.runs}/${inningsData.wickets} (${_formatOvers(inningsData.overs)} Ov)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            'CRR ${crr.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSec,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBowlersSection(List<_BowlerScorecardRow> bowlerStats) {
    if (bowlerStats.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.elevated.withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bowlers',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec.withOpacity(0.8),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 35,
                  child: Text(
                    'O',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec.withOpacity(0.8),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 35,
                  child: Text(
                    'M',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec.withOpacity(0.8),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 35,
                  child: Text(
                    'R',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec.withOpacity(0.8),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 35,
                  child: Text(
                    'W',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec.withOpacity(0.8),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Eco.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec.withOpacity(0.8),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bowler rows
          ...bowlerStats.asMap().entries.map((entry) {
            final index = entry.key;
            final bowler = entry.value;
            final isLast = index == bowlerStats.length - 1;
            return _buildBowlerRow(bowler, isLast);
          }),
        ],
      ),
    );
  }
  
  Widget _buildBowlerRow(_BowlerScorecardRow bowler, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.borderLight.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bowler.bowlerName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              _formatOvers(bowler.overs),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              '${bowler.maidens}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              '${bowler.runs}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              '${bowler.wickets}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              bowler.economy.toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCurrentInnings
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.borderLight.withOpacity(0.5),
          width: widget.isCurrentInnings ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          if (widget.isCurrentInnings)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
        ],
      ),
      child: Column(
        children: [
          // Innings Header (Always Visible)
          InkWell(
            onTap: widget.onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: widget.isCurrentInnings
                    ? AppColors.primary.withOpacity(0.04)
                    : AppColors.elevated.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.isCurrentInnings ? 'CURRENT INNINGS' : 'FIRST INNINGS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.isCurrentInnings
                                    ? AppColors.primary
                                    : AppColors.textSec.withOpacity(0.7),
                                letterSpacing: 1.5,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (widget.isCurrentInnings) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.urgent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.inningsData.teamName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                            fontFamily: 'Inter',
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Score section - right-aligned
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${widget.inningsData.runs}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: widget.isCurrentInnings
                                  ? AppColors.primary
                                  : AppColors.textMain,
                              fontFamily: 'Inter',
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '/${widget.inningsData.wickets}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSec.withOpacity(0.8),
                              fontFamily: 'Inter',
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatOvers(widget.inningsData.overs)} Ov',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSec.withOpacity(0.7),
                          fontFamily: 'Inter',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Expand/collapse arrow
                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.5).animate(_expandAnimation),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSec.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable Content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderLight.withOpacity(0.3),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Batting Scorecard
                      _BattingScorecardTable(
                        battingStats: widget.inningsData.battingStats,
                      ),
                      const SizedBox(height: 16),
                      // Extras
                      _buildExtrasRow(widget.inningsData.extras),
                      const SizedBox(height: 12),
                      // Total
                      _buildTotalRow(widget.inningsData),
                      const SizedBox(height: 16),
                      // Bowlers
                      _buildBowlersSection(widget.inningsData.bowlerStats),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Batting Scorecard Table Widget
class _BattingScorecardTable extends StatelessWidget {
  final List<_PlayerBattingStats> battingStats;

  const _BattingScorecardTable({required this.battingStats});

  // Fixed column widths for perfect alignment
  static const double _batterNameWidth = double.infinity; // Flexible
  static const double _statColumnWidth = 40.0; // Fixed width for R, B, 4s, 6s
  static const double _srColumnWidth = 50.0; // Slightly wider for SR
  static const double _minColumnWidth = 45.0; // Width for Min

  @override
  Widget build(BuildContext context) {
    if (battingStats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'No batting data available',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSec,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header - Perfect alignment with fixed widths
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.elevated.withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Batter name column - flexible
                Expanded(
                  child: Text(
                    'Batters',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSec.withOpacity(0.8),
                      fontFamily: 'Inter',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Fixed-width stat columns
                SizedBox(
                  width: _statColumnWidth,
                  child: _buildHeaderCell('R'),
                ),
                SizedBox(
                  width: _statColumnWidth,
                  child: _buildHeaderCell('B'),
                ),
                SizedBox(
                  width: _statColumnWidth,
                  child: _buildHeaderCell('4s'),
                ),
                SizedBox(
                  width: _statColumnWidth,
                  child: _buildHeaderCell('6s'),
                ),
                SizedBox(
                  width: _srColumnWidth,
                  child: _buildHeaderCell('SR'),
                ),
                SizedBox(
                  width: _minColumnWidth,
                  child: _buildHeaderCell('Min'),
                ),
              ],
            ),
          ),
          // Table Rows
          ...battingStats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            final isLast = index == battingStats.length - 1;
            return _buildBattingRow(stat, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSec.withOpacity(0.8),
        fontFamily: 'Inter',
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildBattingRow(_PlayerBattingStats stat, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.borderLight.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batter name column - flexible, left-aligned
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        stat.playerName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                          fontFamily: 'Inter',
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (stat.isCaptain) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(c)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSec.withOpacity(0.7),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                    if (stat.isWicketKeeper) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(wk)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSec.withOpacity(0.7),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ],
                ),
                if (stat.dismissal != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    stat.dismissal!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSec.withOpacity(0.75),
                      fontFamily: 'Inter',
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (stat.isNotOut) ...[
                  const SizedBox(height: 5),
                  Text(
                    'not out',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success.withOpacity(0.8),
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Fixed-width stat columns - center-aligned
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(
              stat.runs.toString(),
              isHighlight: true,
            ),
          ),
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(stat.balls.toString()),
          ),
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(stat.fours.toString()),
          ),
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(stat.sixes.toString()),
          ),
          SizedBox(
            width: _srColumnWidth,
            child: _buildDataCell(
              stat.strikeRate.toStringAsFixed(1),
              isStrikeRate: true,
            ),
          ),
          SizedBox(
            width: _minColumnWidth,
            child: _buildDataCell(stat.minutes.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isHighlight = false, bool isStrikeRate = false}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
        color: isStrikeRate
            ? AppColors.primary.withOpacity(0.8)
            : isHighlight
                ? AppColors.textMain
                : AppColors.textSec,
        fontFamily: 'Inter',
        height: 1.3,
      ),
    );
  }
}

class _MatchResultScreen extends StatelessWidget {
  final String winningTeam;
  final String result;
  final String team1Name;
  final String team2Name;
  final String team1Score;
  final String team2Score;
  final double team1Overs;
  final double team2Overs;
  final String? matchId;

  const _MatchResultScreen({
    required this.winningTeam,
    required this.result,
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.team1Overs,
    required this.team2Overs,
    this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Navigate to dashboard instead of going back
        if (context.mounted) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Match Result Title
              Text(
                'Match Result',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  fontFamily: 'Inter',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 40),
              // Winning Team Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      winningTeam.isNotEmpty ? winningTeam : 'Match Tied',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSec,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Team Scores
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [AppShadows.card],
                ),
                child: Column(
                  children: [
                    // Team 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team1Name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                team1Score,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${team1Overs.toStringAsFixed(1)} overs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSec,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppColors.divider,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                team2Name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.end,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                team2Score,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.end,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${team2Overs.toStringAsFixed(1)} overs',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSec,
                                  fontFamily: 'Inter',
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to dashboard instead of going back
                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
