import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import 'dart:async';

class ScorecardPage extends ConsumerStatefulWidget {
  final String? matchId;
  final String? team1;
  final String? team2;
  final int? overs;
  final String? youtubeVideoId; // YouTube video ID for live stream
  
  const ScorecardPage({
    super.key,
    this.matchId,
    this.team1,
    this.team2,
    this.overs,
    this.youtubeVideoId,
  });

  @override
  ConsumerState<ScorecardPage> createState() => _ScorecardPageState();
}

class _ScorecardPageState extends ConsumerState<ScorecardPage> {
  Timer? _saveTimer;
  // Match state
  String _battingTeam = 'Warriors';
  String _bowlingTeam = 'Titans';
  int _currentOver = 16;
  int _currentBall = 4;
  int _totalRuns = 142;
  int _wickets = 3;
  String _striker = 'V. Kohli';
  String _nonStriker = 'R. Sharma';
  String _bowler = 'J. Bumrah';
  
  int _strikerRuns = 45;
  int _strikerBalls = 32;
  double _strikerSR = 140.6;
  
  int _nonStrikerRuns = 12;
  int _nonStrikerBalls = 8;
  double _nonStrikerSR = 150.0;
  
  double _bowlerOvers = 2.4;
  int _bowlerRuns = 18;
  int _bowlerWickets = 1;
  
  double _crr = 8.45;
  int _projected = 175;
  
  List<String> _recentBalls = ['1', '0', '4', '1', 'W', ''];
  List<String> _battingTeamPlayers = [];
  List<String> _bowlingTeamPlayers = [];
  
  // YouTube Player
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    final extra = widget.matchId == null ? null : null; // Get from route extra if needed
    if (widget.team1 != null) _battingTeam = widget.team1!;
    if (widget.team2 != null) _bowlingTeam = widget.team2!;
    
    _battingTeamPlayers = ['V. Kohli', 'R. Sharma', 'S. Gill', 'Y. Jaiswal'];
    _bowlingTeamPlayers = ['J. Bumrah', 'M. Shami', 'R. Khan', 'T. Boult'];
    
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
        
        final scorecard = {
          'team1_score': {
            'runs': _totalRuns,
            'wickets': _wickets,
            'overs': _currentOver + (_currentBall / 6),
          },
          'team2_score': {
            'runs': 0, // Will be updated when team 2 bats
            'wickets': 0,
            'overs': 0,
          },
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
          'recent_balls': _recentBalls,
        };
        
        await matchRepo.updateScorecard(widget.matchId!, scorecard);
      } catch (e) {
        // Silently fail - don't interrupt user experience
        debugPrint('Failed to save scorecard: $e');
      }
    });
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

  void _handleScore(int runs) {
    setState(() {
      _totalRuns += runs;
      _strikerRuns += runs;
      _strikerBalls += 1;
      _strikerSR = _strikerBalls > 0 ? (_strikerRuns / _strikerBalls) * 100 : 0.0;
      _bowlerRuns += runs;
      
      // Increment ball
      _currentBall += 1;
      
      // Check if over is complete (6 balls)
      bool overComplete = false;
      if (_currentBall >= 6) {
        _currentBall = 0;
        _currentOver += 1;
        overComplete = true;
        // Update bowler overs
        _bowlerOvers = _bowlerOvers + 1.0;
      }
      
      // Swap batsmen if:
      // 1. Odd runs scored (1, 3, 5) - batsmen swap ends
      // 2. End of over (6 balls) - batsmen always swap
      if (runs % 2 == 1 || overComplete) {
        _swapBatsmen();
      }
      
      // Update CRR and projected score
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      // Update recent balls
      _recentBalls.insert(0, runs.toString());
      if (_recentBalls.length > 6) _recentBalls.removeLast();
    });
    
    // Save to Supabase (debounced)
    _saveScorecardToSupabase();
  }

  void _handleWide() {
    setState(() {
      _totalRuns += 1;
      _bowlerRuns += 1;
      // Wide doesn't count as a ball, but if runs are scored, batsmen swap on odd runs
      // For wide, we swap if it's an odd run (1 run from wide = swap)
      if (1 % 2 == 1) {
        _swapBatsmen();
      }
      
      // Update CRR
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      _recentBalls.insert(0, 'WD');
      if (_recentBalls.length > 6) _recentBalls.removeLast();
    });
    _saveScorecardToSupabase();
  }

  void _handleNoBall() {
    setState(() {
      _totalRuns += 1;
      _bowlerRuns += 1;
      // No ball doesn't count as a ball, but if runs are scored, batsmen swap on odd runs
      // For no ball, we swap if it's an odd run (1 run from no ball = swap)
      if (1 % 2 == 1) {
        _swapBatsmen();
      }
      
      // Update CRR
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      _recentBalls.insert(0, 'NB');
      if (_recentBalls.length > 6) _recentBalls.removeLast();
    });
    _saveScorecardToSupabase();
  }

  void _handleByes(int runs) {
    setState(() {
      _totalRuns += runs;
      // Byes count as a ball and can result in runs
      _currentBall += 1;
      
      // Check if over is complete
      bool overComplete = false;
      if (_currentBall >= 6) {
        _currentBall = 0;
        _currentOver += 1;
        overComplete = true;
        // Update bowler overs
        _bowlerOvers = _bowlerOvers + 1.0;
      }
      
      // Swap batsmen if odd runs or end of over
      if (runs % 2 == 1 || overComplete) {
        _swapBatsmen();
      }
      
      // Update CRR
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      _recentBalls.insert(0, 'B$runs');
      if (_recentBalls.length > 6) _recentBalls.removeLast();
    });
    _saveScorecardToSupabase();
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
            _recentBalls = List<String>.from(scorecard['recent_balls'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load match data: $e');
    }
  }

  void _handleWicket() {
    setState(() {
      _wickets += 1;
      _bowlerWickets += 1;
      
      // Wicket counts as a ball
      _currentBall += 1;
      
      // Check if over is complete
      bool overComplete = false;
      if (_currentBall >= 6) {
        _currentBall = 0;
        _currentOver += 1;
        overComplete = true;
        // Update bowler overs
        _bowlerOvers = _bowlerOvers + 1.0;
      }
      
      // New batsman comes in at the striker's end
      // Select new batsman (simplified - next player in the list)
      if (_battingTeamPlayers.length > _wickets + 1) {
        _striker = _battingTeamPlayers[_wickets + 1];
        _strikerRuns = 0;
        _strikerBalls = 0;
        _strikerSR = 0.0;
      }
      
      // If over is complete, swap batsmen (non-striker becomes striker)
      if (overComplete) {
        _swapBatsmen();
      }
      
      // Update CRR
      final totalOvers = _currentOver + (_currentBall / 6);
      _crr = totalOvers > 0 ? _totalRuns / totalOvers : 0.0;
      _projected = (_crr * (widget.overs ?? 20)).round();
      
      _recentBalls.insert(0, 'W');
      if (_recentBalls.length > 6) _recentBalls.removeLast();
    });
    _saveScorecardToSupabase();
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
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
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
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.textMain),
                    onPressed: () {},
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_youtubeController != null) const SizedBox(height: 16),
                    // Live Scorecard Header
                    if (_youtubeController != null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Live Scorecard',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    // Main Scorecard Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          AppShadows.card,
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Blurry cricket ground background
                            Positioned.fill(
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Image.asset(
                                  'assets/images/Screenshot 2025-12-26 at 4.44.26 PM.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(color: AppColors.surface);
                                  },
                                ),
                              ),
                            ),
                            // Dark overlay for readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                            // Content
                            Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '1ST INNINGS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSec,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _battingTeam,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.urgent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.urgent.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.textMain,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: AppColors.textMain,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'CRR: $_crr',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSec,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_totalRuns',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                '/$_wickets',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_currentOver.$_currentBall',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                ' Ov',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vs $_bowlingTeam',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                'Projected: $_projected',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Recent Balls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: _recentBalls.take(6).map((ball) {
                              final isWicket = ball == 'W';
                              final isWide = ball == 'WD' || ball == 'NB';
                              final isEmpty = ball.isEmpty;
                              return Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: isEmpty
                                      ? Colors.transparent
                                      : isWicket
                                          ? const Color(0xFFC72B32)
                                          : ball == '4'
                                              ? const Color(0xFF205A28)
                                              : Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: isEmpty
                                      ? Border.all(
                                          color: const Color(0xFF205A28),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: isEmpty
                                    ? null
                                    : Center(
                                        child: Text(
                                          ball,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isWicket || ball == '4'
                                                ? Colors.white
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                    ),
                  ),
                ),

                    const SizedBox(height: 16),

                    // Batter and Bowler Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.textMain,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
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
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    'R',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    'B',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    'SR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Striker
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.sports_cricket,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_striker *',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '$_strikerRuns',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '$_strikerBalls',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSec,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    _strikerSR.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSec,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Non-Striker
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 24),
                                  child: Text(
                                    _nonStriker,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '$_nonStrikerRuns',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '$_nonStrikerBalls',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSec,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    _nonStrikerSR.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSec,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey[100], height: 1),
                          const SizedBox(height: 16),
                          // Bowler
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC72B32),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BOWLER',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _bowler,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'O',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _bowlerOvers.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      Text(
                                        'R',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_bowlerRuns',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      Text(
                                        'W',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_bowlerWickets',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC72B32),
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

                    const SizedBox(height: 16),

                    // Scoring Control
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.textMain,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border.all(color: Colors.grey[100]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCORING CONTROL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            children: [
                              _buildScoreButton('0', () => _handleScore(0), false),
                              _buildScoreButton('1', () => _handleScore(1), false),
                              _buildScoreButton('2', () => _handleScore(2), false),
                              _buildScoreButton('3', () => _handleScore(3), false),
                              _buildScoreButton('4', () => _handleScore(4), true),
                              _buildScoreButton('6', () => _handleScore(6), true),
                              _buildExtrasButton('WIDE', () => _handleWide()),
                              _buildExtrasButton('NO\nBALL', () => _handleNoBall()),
                              _buildExtrasButton('BYES', () => _handleByes(1), isGreen: true),
                              _buildExtrasButton('LEG\nBYES', () => _handleByes(1), isGreen: true),
                              _buildExtrasButton('PENALTY\nRUNS', () => _handleByes(1)),
                              _buildOutButton(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // Undo last action
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Undo functionality coming soon')),
                                  );
                                },
                                icon: const Icon(Icons.undo, size: 16, color: Colors.grey),
                                label: const Text(
                                  'Undo Last',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  _showFullScorecard();
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                                label: const Text(
                                  'View Full Scorecard',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildScoreButton(String label, VoidCallback onTap, bool isHighlighted) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFF205A28)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFF205A28)
                : const Color(0xFF205A28).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : const Color(0xFF205A28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtrasButton(String label, VoidCallback onTap, {bool isGreen = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isGreen
              ? Colors.green[50]
              : Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isGreen
                ? const Color(0xFF205A28).withOpacity(0.2)
                : const Color(0xFFC72B32).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isGreen
                  ? const Color(0xFF205A28)
                  : const Color(0xFFC72B32),
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutButton() {
    return InkWell(
      onTap: _handleWicket,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFC72B32),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC72B32).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_baseball, color: Colors.white, size: 18),
              const SizedBox(width: 4),
              const Text(
                'OUT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
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
              _buildTableCell(_bowlerOvers.toStringAsFixed(1), isHeader: false),
              _buildTableCell('0', isHeader: false),
              _buildTableCell('$_bowlerRuns', isHeader: false),
              _buildTableCell('$_bowlerWickets', isHeader: false),
              _buildTableCell((_bowlerRuns / _bowlerOvers).toStringAsFixed(2), isHeader: false),
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
          Text('1st Wicket: ${(_totalRuns * 0.3).round()}/${_wickets} (${_currentOver - 2}.${_currentBall})'),
          if (_wickets > 1)
            Text('2nd Wicket: ${(_totalRuns * 0.5).round()}/${_wickets} (${_currentOver - 1}.${_currentBall})'),
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
}
