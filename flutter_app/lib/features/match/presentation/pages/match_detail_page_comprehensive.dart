import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/repositories/match_repository.dart';
import '../../../../core/repositories/match_player_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'commentary_page.dart';
import '../../../live/presentation/pages/go_live_screen.dart';
import '../widgets/assign_scorer_dialog.dart';
import '../../../../core/models/mvp_model.dart';

/// Provider for match data
final matchDetailProvider = StreamProvider.autoDispose.family<MatchModel?, String>((ref, matchId) {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.streamMatchById(matchId);
});

/// Provider for match players
final matchPlayersProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, matchId) async {
  final repository = ref.watch(matchPlayerRepositoryProvider);
  return await repository.getMatchPlayers(matchId);
});

// MVP data provider
final matchMvpProvider = FutureProvider.autoDispose.family<List<PlayerMvpModel>, String>((ref, matchId) async {
  final repository = ref.watch(mvpRepositoryProvider);
  return await repository.getMatchMvpData(matchId);
});

class MatchDetailPageComprehensive extends ConsumerStatefulWidget {
  final String matchId;

  const MatchDetailPageComprehensive({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<MatchDetailPageComprehensive> createState() => _MatchDetailPageComprehensiveState();
}

class _MatchDetailPageComprehensiveState extends ConsumerState<MatchDetailPageComprehensive>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));
    final playersAsync = ref.watch(matchPlayersProvider(widget.matchId));
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Match Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          // Refresh Button with Animation
          AnimatedRotation(
            turns: _isRefreshing ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
              onPressed: _isRefreshing
                  ? null
                  : () async {
                      setState(() {
                        _isRefreshing = true;
                      });

                      // Invalidate providers to refresh data
                      ref.invalidate(matchDetailProvider(widget.matchId));
                      ref.invalidate(matchPlayersProvider(widget.matchId));

                      // Wait a bit for the animation and data refresh
                      await Future.delayed(const Duration(milliseconds: 500));

                      if (mounted) {
                        setState(() {
                          _isRefreshing = false;
                        });

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Match data refreshed'),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
            ),
          ),
          // Share Button
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share',
            onPressed: () async {
              final matchAsync = ref.read(matchDetailProvider(widget.matchId));
              matchAsync.whenData((match) {
                if (match != null) {
                  final team1 = match.team1Name ?? 'Team 1';
                  final team2 = match.team2Name ?? 'Team 2';
                  final status = match.status.toUpperCase();
                  
                  String shareText = '🏏 $team1 vs $team2\n';
                  shareText += '📊 Status: $status\n';
                  
                  // Add score if available
                  final scorecard = match.scorecard;
                  if (scorecard != null && scorecard.isNotEmpty) {
                    final team1Score = scorecard['team1_score'] as Map<String, dynamic>? ?? {};
                    final team2Score = scorecard['team2_score'] as Map<String, dynamic>? ?? {};
                    
                    if (team1Score.isNotEmpty) {
                      final runs = team1Score['runs'] ?? 0;
                      final wickets = team1Score['wickets'] ?? 0;
                      final overs = team1Score['overs'] ?? 0.0;
                      shareText += '$team1: $runs/$wickets (${_formatOvers(overs)} Ov)\n';
                    }
                    
                    if (team2Score.isNotEmpty) {
                      final runs = team2Score['runs'] ?? 0;
                      final wickets = team2Score['wickets'] ?? 0;
                      final overs = team2Score['overs'] ?? 0.0;
                      shareText += '$team2: $runs/$wickets (${_formatOvers(overs)} Ov)\n';
                    }
                  }
                  
                  shareText += '\n⚡ Format: ${match.overs} Overs\n';
                  shareText += '📍 Ground: ${match.groundType}\n';
                  
                  if (match.winnerId != null) {
                    final winner = _getTeamName(match, match.winnerId!);
                    shareText += '🏆 Winner: $winner\n';
                  }
                  
                  shareText += '\nShared from Superior Cricket App';
                  
                  // Share the text
                  Share.share(
                    shareText,
                    subject: '$team1 vs $team2 - Match Details',
                  );
                }
              });
            },
          ),
          // Assign Scorer Button (only for match creator)
          matchAsync.when(
            data: (match) {
              if (match != null && currentUserId != null && match.createdBy == currentUserId) {
                return IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  tooltip: 'Assign Scorer',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AssignScorerDialog(
                        matchId: widget.matchId,
                        currentScorerId: match.currentScorerId,
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Match not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Match Header Card
                SliverToBoxAdapter(
                  child: _buildMatchHeader(match, currentUserId),
                ),
                
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontSize: 13),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: const [
                        Tab(text: 'Info'),
                        Tab(text: 'Summary'),
                        Tab(text: 'Squads'),
                        Tab(text: 'Scorecard'),
                        Tab(text: 'Comms'),
                        Tab(text: 'MVP'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(match),
                _buildSummaryTab(match),
                _buildSquadsTab(match, playersAsync),
                _buildScorecardTab(match),
                _buildCommentaryTab(match),
                _buildMvpTab(match),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading match',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(matchDetailProvider(widget.matchId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHeader(MatchModel match, String? currentUserId) {
    return AspectRatio(
      aspectRatio: 2.5 / 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/cricket_stadium_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  child: currentUserId != null && match.createdBy == currentUserId
                      ? _buildGlassmorphicGoLiveButton(match)
                      : Container(), // Empty container if not the creator
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphicGoLiveButton(MatchModel match) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              context.push(
                '/go-live',
                extra: {
                  'matchId': match.id,
                  'matchTitle': '${match.team1Name ?? 'Team 1'} vs ${match.team2Name ?? 'Team 2'}',
                },
              );
            },
            child: const Text(
              'Go Live',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMvpBreakdownRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSec)),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S': return const Color(0xFFFFD700);
      case 'A': return const Color(0xFF00D9FF);
      case 'B': return const Color(0xFF00FF88);
      case 'C': return const Color(0xFFFFA500);
      default: return AppColors.textMeta;
    }
  }

  Widget _buildSummaryTab(MatchModel match) {
    final scorecard = match.scorecard;
    
    if (scorecard == null || scorecard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scoreboard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Match summary not available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match.status == 'upcoming'
                  ? 'Match has not started yet'
                  : 'Summary will appear here once the match starts',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Extract data from scorecard
    final currentInnings = scorecard['current_innings'] as int? ?? 1;
    final team1Score = scorecard['team1_score'] as Map<String, dynamic>? ?? {};
    final team2Score = scorecard['team2_score'] as Map<String, dynamic>? ?? {};
    final crr = (scorecard['crr'] as num?)?.toDouble() ?? 0.0;
    final projected = scorecard['projected'] as int? ?? 0;
    
    // Current batting team data
    final currentScore = currentInnings == 1 ? team1Score : team2Score;
    final currentRuns = (currentScore['runs'] as num?)?.toInt() ?? 0;
    final currentWickets = (currentScore['wickets'] as num?)?.toInt() ?? 0;
    final currentOvers = (currentScore['overs'] as num?)?.toDouble() ?? 0.0;
    
    // Previous innings data
    final previousScore = currentInnings == 2 ? team1Score : null;
    final previousRuns = previousScore != null ? ((previousScore['runs'] as num?)?.toInt() ?? 0) : null;
    
    // Team names
    final currentBattingTeam = currentInnings == 1 ? (match.team1Name ?? 'Team 1') : (match.team2Name ?? 'Team 2');
    
    // Current batsmen
    final striker = scorecard['striker'] as String? ?? '';
    final nonStriker = scorecard['non_striker'] as String? ?? '';
    final strikerRuns = scorecard['striker_runs'] as int? ?? 0;
    final strikerBalls = scorecard['striker_balls'] as int? ?? 0;
    final nonStrikerRuns = scorecard['non_striker_runs'] as int? ?? 0;
    final nonStrikerBalls = scorecard['non_striker_balls'] as int? ?? 0;
    
    // Current bowler
    final bowler = scorecard['bowler'] as String? ?? '';
    final bowlerOvers = (scorecard['bowler_overs'] as num?)?.toDouble() ?? 0.0;
    final bowlerRuns = scorecard['bowler_runs'] as int? ?? 0;
    final bowlerWickets = (scorecard['bowler_wickets'] as num?)?.toInt() ?? 0;
    
    // Get player stats from map
    final playerStatsMap = scorecard['player_stats_map'] as Map<String, dynamic>? ?? {};
    final strikerStats = playerStatsMap[striker] as Map<String, dynamic>? ?? {};
    final nonStrikerStats = playerStatsMap[nonStriker] as Map<String, dynamic>? ?? {};
    
    final strikerFours = (strikerStats['fours'] as num?)?.toInt() ?? 0;
    final strikerSixes = (strikerStats['sixes'] as num?)?.toInt() ?? 0;
    final nonStrikerFours = (nonStrikerStats['fours'] as num?)?.toInt() ?? 0;
    final nonStrikerSixes = (nonStrikerStats['sixes'] as num?)?.toInt() ?? 0;
    
    // Calculate strike rates
    final strikerSR = strikerBalls > 0 ? (strikerRuns / strikerBalls) * 100 : 0.0;
    final nonStrikerSR = nonStrikerBalls > 0 ? (nonStrikerRuns / nonStrikerBalls) * 100 : 0.0;
    
    // Calculate partnership
    final partnershipRuns = strikerRuns + nonStrikerRuns;
    final partnershipBalls = strikerBalls + nonStrikerBalls;
    
    // Calculate bowler economy
    final bowlerEconomy = bowlerOvers > 0 ? bowlerRuns / bowlerOvers : 0.0;
    
    // Get bowler stats from map
    final bowlerStatsMap = scorecard['bowler_stats_map'] as Map<String, dynamic>? ?? {};
    final bowlerStats = bowlerStatsMap[bowler] as Map<String, dynamic>? ?? {};
    final bowlerMaidens = (bowlerStats['maidens'] as num?)?.toInt() ?? 0;
    
    // Calculate target info for second innings
    int? runsRequired;
    int? ballsRemaining;
    double? requiredRunRate;
    if (currentInnings == 2 && previousRuns != null) {
      runsRequired = (previousRuns + 1) - currentRuns;
      final totalBalls = match.overs * 6;
      final ballsPlayed = (currentOvers * 6).round();
      ballsRemaining = totalBalls - ballsPlayed;
      requiredRunRate = ballsRemaining > 0 ? (runsRequired / (ballsRemaining / 6.0)) : 0.0;
    }

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Name Header - Simple text
            Text(
              currentBattingTeam,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 20),
            
            // Score and Overs - Reduced size
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$currentRuns',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/$currentWickets',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '(${_formatOvers(currentOvers)} Ov)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          
          // CRR and REQ - Enhanced with better visual separation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _buildMetricItem('CRR', crr.toStringAsFixed(2)),
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.grey[300],
                ),
                _buildMetricItem(
                  requiredRunRate != null ? 'REQ' : 'Proj',
                  requiredRunRate != null 
                      ? requiredRunRate.toStringAsFixed(2)
                      : projected.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Target Info - Simple text, left-aligned
          if (runsRequired != null && ballsRemaining != null) ...[
            Text(
              '$currentBattingTeam require $runsRequired runs in $ballsRemaining balls',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Divider with better styling
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[300]!,
                  Colors.grey[200]!,
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Batsmen Section - Enhanced
          if (striker.isNotEmpty || nonStriker.isNotEmpty) ...[
            _buildBatsmenTableCompact(
              striker: striker,
              strikerRuns: strikerRuns,
              strikerBalls: strikerBalls,
              strikerFours: strikerFours,
              strikerSixes: strikerSixes,
              strikerSR: strikerSR,
              nonStriker: nonStriker,
              nonStrikerRuns: nonStrikerRuns,
              nonStrikerBalls: nonStrikerBalls,
              nonStrikerFours: nonStrikerFours,
              nonStrikerSixes: nonStrikerSixes,
              nonStrikerSR: nonStrikerSR,
            ),
            const SizedBox(height: 16),
            
            // Partnership - Enhanced with better styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Partnership',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$partnershipRuns($partnershipBalls)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'More',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Bowlers Section - Enhanced
          if (bowler.isNotEmpty) ...[
            _buildBowlersTableCompact(
              bowler: bowler,
              overs: bowlerOvers,
              maidens: bowlerMaidens,
              runs: bowlerRuns,
              wickets: bowlerWickets,
              economy: bowlerEconomy,
            ),
          ],
          
          // MVP SECTION - NEW!
          const SizedBox(height: 32),
          Consumer(
            builder: (context, ref, child) {
              final mvpAsync = ref.watch(matchMvpProvider(widget.matchId));
              
              return mvpAsync.when(
                data: (mvpData) {
                  if (mvpData.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  final potm = mvpData.firstWhere(
                    (p) => p.isPlayerOfTheMatch == true,
                    orElse: () => mvpData.first,
                  );
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MVP Header
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Top Performers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Player of the Match Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.accent.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events, color: AppColors.primary, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Player of the Match',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textMeta,
                                        ),
                                      ),
                                      Text(
                                        potm.playerName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(potm.performanceGrade),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    potm.performanceGrade,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.elevated,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total MVP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text(
                                        potm.totalMvp.toStringAsFixed(2),
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMvpBreakdownRow('🏏 Batting', potm.battingMvp),
                                  _buildMvpBreakdownRow('⚾ Bowling', potm.bowlingMvp),
                                  _buildMvpBreakdownRow('🧤 Fielding', potm.fieldingMvp),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Top 5 Performers
                      ...mvpData.take(5).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final player = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: index < 3 ? AppColors.primary.withOpacity(0.2) : AppColors.textMeta.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: index < 3 ? AppColors.primary : AppColors.textMeta,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player.playerName,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'B: ${player.battingMvp.toStringAsFixed(1)} • Bo: ${player.bowlingMvp.toStringAsFixed(1)} • F: ${player.fieldingMvp.toStringAsFixed(1)}',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSec),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                player.totalMvp.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(MatchModel match) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Match Information',
            [
              _buildInfoRow('Status', match.status.toUpperCase()),
              _buildInfoRow('Format', '${match.overs} Overs'),
              _buildInfoRow('Ground Type', match.groundType),
              _buildInfoRow('Ball Type', match.ballType),
              if (match.scheduledAt != null)
                _buildInfoRow('Scheduled', _formatDateTime(match.scheduledAt!)),
              if (match.startedAt != null)
                _buildInfoRow('Started', _formatDateTime(match.startedAt!)),
              if (match.completedAt != null)
                _buildInfoRow('Completed', _formatDateTime(match.completedAt!)),
            ],
          ),
          const SizedBox(height: 16),
          if (match.tossWinnerId != null || match.tossDecision != null)
            _buildInfoCard(
              'Toss',
              [
                if (match.tossWinnerId != null)
                  _buildInfoRow('Winner', _getTeamName(match, match.tossWinnerId!)),
                if (match.tossDecision != null)
                  _buildInfoRow('Decision', match.tossDecision!.toUpperCase()),
              ],
            ),
          const SizedBox(height: 16),
          if (match.winnerId != null)
            _buildInfoCard(
              'Result',
              [
                _buildInfoRow('Winner', _getTeamName(match, match.winnerId!)),
              ],
            ),
          const SizedBox(height: 16),
          if (match.youtubeVideoId != null)
            _buildInfoCard(
              'Live Stream',
              [
                ListTile(
                  leading: const Icon(Icons.live_tv, color: Colors.red),
                  title: const Text('Watch Live'),
                  subtitle: const Text('YouTube Live Stream'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.push('/live?videoId=${match.youtubeVideoId}');
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSquadsTab(MatchModel match, AsyncValue<List<Map<String, dynamic>>> playersAsync) {
    return playersAsync.when(
      data: (players) {
        final team1Players = players.where((p) => p['team_type'] == 'team1').toList();
        final team2Players = players.where((p) => p['team_type'] == 'team2').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team 1 Squad
              _buildSquadSection(
                match.team1Name ?? 'Team 1',
                team1Players,
                AppColors.primary,
              ),
              const SizedBox(height: 24),
              // Team 2 Squad
              _buildSquadSection(
                match.team2Name ?? 'Team 2',
                team2Players,
                Colors.blue,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error loading players: $error'),
      ),
    );
  }

  Widget _buildSquadSection(String teamName, List<Map<String, dynamic>> players, Color teamColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: teamColor.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: teamColor.withOpacity(0.1),
        shape: const Border(), // Remove default border
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: teamColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              teamName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: teamColor,
              ),
            ),
            const Spacer(),
            Text(
              '${players.length} Players',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No players added yet',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...players.map((player) => _buildPlayerCard(player)),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> playerData) {
    final profile = playerData['profiles'] as Map<String, dynamic>?;
    final playerName = profile?['full_name'] as String? ?? 
                      profile?['username'] as String? ?? 
                      'Unknown Player';
    final avatarUrl = profile?['avatar_url'] as String?;
    final role = playerData['role'] as String? ?? 'Player';
    final isCaptain = playerData['is_captain'] as bool? ?? false;
    final isWicketKeeper = playerData['is_wicket_keeper'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarInitials(playerName),
                    ),
                  )
                : _buildAvatarInitials(playerName),
          ),
          const SizedBox(width: 12),
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        playerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (isCaptain)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isWicketKeeper)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'WK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitials(String name) {
    final initials = name
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .join();
    
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScorecardTab(MatchModel match) {
    final scorecard = match.scorecard;
    
    if (scorecard == null || scorecard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scoreboard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Scorecard not available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match.status == 'upcoming'
                  ? 'Match has not started yet'
                  : 'Scorecard will appear here once the match starts',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Extract innings data
    final team1Score = scorecard['team1_score'] as Map<String, dynamic>? ?? {};
    final team2Score = scorecard['team2_score'] as Map<String, dynamic>? ?? {};
    final currentInnings = scorecard['current_innings'] as int? ?? 1;
    final firstInningsRuns = scorecard['first_innings_runs'] as int? ?? 0;
    final firstInningsWickets = scorecard['first_innings_wickets'] as int? ?? 0;
    final firstInningsOvers = (scorecard['first_innings_overs'] as num?)?.toDouble() ?? 0.0;
    
    // Determine team names
    final team1Name = match.team1Name ?? 'Team 1';
    final team2Name = match.team2Name ?? 'Team 2';
    
    // Determine which team batted first (based on current innings)
    final firstInningsTeam = currentInnings == 2 ? team1Name : team2Name;
    final secondInningsTeam = currentInnings == 2 ? team2Name : team1Name;
    
    // Get current innings data
    final currentScore = currentInnings == 1 ? team1Score : team2Score;
    final currentRuns = (currentScore['runs'] as num?)?.toInt() ?? 0;
    final currentWickets = (currentScore['wickets'] as num?)?.toInt() ?? 0;
    final currentOvers = (currentScore['overs'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scorecard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          // Show first innings if second innings has started
          if (currentInnings == 2)
            _InningsScorecardWidget(
              teamName: firstInningsTeam,
              runs: firstInningsRuns,
              wickets: firstInningsWickets,
              overs: firstInningsOvers,
              isCurrentInnings: false,
              battingStats: _buildBattingStatsFromScorecard(scorecard, firstInningsTeam),
              bowlingStats: _buildBowlingStatsFromScorecard(scorecard, firstInningsTeam),
            ),
          // Show current innings
          _InningsScorecardWidget(
            teamName: secondInningsTeam,
            runs: currentRuns,
            wickets: currentWickets,
            overs: currentOvers,
            isCurrentInnings: true,
            battingStats: _buildBattingStatsFromScorecard(scorecard, secondInningsTeam, isCurrent: true),
            bowlingStats: _buildBowlingStatsFromScorecard(scorecard, secondInningsTeam, isCurrent: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaryTab(MatchModel match) {
    return Stack(
      children: [
        // Commentary content
        CommentaryPage(matchId: match.id),
        // View Full Commentary button at bottom-right
        Positioned(
          bottom: 20,
          right: 20,
          child: TextButton(
            onPressed: () {
              context.push('/commentary/${match.id}');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Full Commentary',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMvpTab(MatchModel match) {
    final mvpAsync = ref.watch(matchMvpProvider(match.id));

    return mvpAsync.when(
      data: (players) {
        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'MVP data not available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Calculation Link
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 12, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'How is Most Valuable Players Calculated?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Player List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemCount: players.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) {
                  return _buildExpandableMvpRow(players[index], index + 1);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildExpandableMvpRow(PlayerMvpModel player, int rank) {
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox(
        width: 80,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: rank <= 3 ? Border.all(color: Colors.red, width: 1.5) : null,
              ),
              child: ClipOval(
                child: player.playerAvatar != null
                    ? Image.network(player.playerAvatar!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          player.playerName[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: rank <= 3 ? Colors.red : Colors.grey, 
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.playerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            player.teamName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      trailing: Text(
        player.totalMvp.toStringAsFixed(3),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          color: Colors.grey[50],
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 8),
              // Breakdown String
              Text(
                'Batting: ${player.battingMvp.toStringAsFixed(3)} + Bowling: ${player.bowlingMvp.toStringAsFixed(3)} + Fielding: ${player.fieldingMvp.toStringAsFixed(3)} = ${player.totalMvp.toStringAsFixed(3)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.teal[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Detailed Stat Boxes
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMiniStatBox('Batting', [
                    _miniStat('R', '${player.runsScored}'),
                    _miniStat('B', '${player.ballsFaced}'),
                    _miniStat('SR', player.strikeRate?.toStringAsFixed(1) ?? '-'),
                  ])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStatBox('Bowling', [
                    _miniStat('W', '${player.wicketsTaken}'),
                    _miniStat('R', '${player.runsConceded}'),
                    _miniStat('EC', player.bowlingEconomy?.toStringAsFixed(1) ?? '-'),
                  ])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStatBox('Fielding', [
                    _miniStat('C', '${player.catches}'),
                    _miniStat('RO', '${player.runOuts}'),
                    _miniStat('ST', '${player.stumpings}'),
                  ])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatBox(String title, List<Widget> stats) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          ...stats,
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatsmenTable({
    required String striker,
    required int strikerRuns,
    required int strikerBalls,
    required int strikerFours,
    required int strikerSixes,
    required double strikerSR,
    required String nonStriker,
    required int nonStrikerRuns,
    required int nonStrikerBalls,
    required int nonStrikerFours,
    required int nonStrikerSixes,
    required double nonStrikerSR,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Batsman',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildTableHeader('R'),
                _buildTableHeader('B'),
                _buildTableHeader('4s'),
                _buildTableHeader('6s'),
                _buildTableHeader('SR'),
              ],
            ),
          ),
          // Striker Row
          if (striker.isNotEmpty)
            _buildBatsmanRow(
              name: striker,
              runs: strikerRuns,
              balls: strikerBalls,
              fours: strikerFours,
              sixes: strikerSixes,
              sr: strikerSR,
              isStriker: true,
            ),
          // Non-Striker Row
          if (nonStriker.isNotEmpty)
            _buildBatsmanRow(
              name: nonStriker,
              runs: nonStrikerRuns,
              balls: nonStrikerBalls,
              fours: nonStrikerFours,
              sixes: nonStrikerSixes,
              sr: nonStrikerSR,
              isStriker: false,
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBatsmanRow({
    required String name,
    required int runs,
    required int balls,
    required int fours,
    required int sixes,
    required double sr,
    required bool isStriker,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isStriker ? AppColors.primary.withOpacity(0.05) : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isStriker ? FontWeight.bold : FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isStriker)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '*',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildTableCell(runs.toString()),
          _buildTableCell(balls.toString()),
          _buildTableCell(fours.toString()),
          _buildTableCell(sixes.toString()),
          _buildTableCell(sr.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBowlerTable({
    required String bowler,
    required double overs,
    required int maidens,
    required int runs,
    required int wickets,
    required double economy,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Bowler',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildTableHeader('O'),
                _buildTableHeader('M'),
                _buildTableHeader('R'),
                _buildTableHeader('W'),
                _buildTableHeader('Eco'),
              ],
            ),
          ),
          // Bowler Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    bowler,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildTableCell(_formatOvers(overs)),
                _buildTableCell(maidens.toString()),
                _buildTableCell(runs.toString()),
                _buildTableCell(wickets.toString()),
                _buildTableCell(economy.toStringAsFixed(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatsmenTableCompact({
    required String striker,
    required int strikerRuns,
    required int strikerBalls,
    required int strikerFours,
    required int strikerSixes,
    required double strikerSR,
    required String nonStriker,
    required int nonStrikerRuns,
    required int nonStrikerBalls,
    required int nonStrikerFours,
    required int nonStrikerSixes,
    required double nonStrikerSR,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Batters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildCompactHeaderCell('R'),
              _buildCompactHeaderCell('B'),
              _buildCompactHeaderCell('4s'),
              _buildCompactHeaderCell('6s'),
              _buildCompactHeaderCell('SR'),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 12),
          // Striker Row
          if (striker.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            striker,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '*',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCompactDataCell(strikerRuns.toString(), isBold: true),
                  _buildCompactDataCell(strikerBalls.toString()),
                  _buildCompactDataCell(strikerFours.toString()),
                  _buildCompactDataCell(strikerSixes.toString()),
                  _buildCompactDataCell(strikerSR.toStringAsFixed(1)),
                ],
              ),
            ),
          // Non-Striker Row
          if (nonStriker.isNotEmpty)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    nonStriker,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildCompactDataCell(nonStrikerRuns.toString()),
                _buildCompactDataCell(nonStrikerBalls.toString()),
                _buildCompactDataCell(nonStrikerFours.toString()),
                _buildCompactDataCell(nonStrikerSixes.toString()),
                _buildCompactDataCell(nonStrikerSR.toStringAsFixed(1)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBowlersTableCompact({
    required String bowler,
    required double overs,
    required int maidens,
    required int runs,
    required int wickets,
    required double economy,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Bowlers',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _buildCompactHeaderCell('O'),
              _buildCompactHeaderCell('M'),
              _buildCompactHeaderCell('R'),
              _buildCompactHeaderCell('W'),
              _buildCompactHeaderCell('Eco'),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[200], height: 1),
          const SizedBox(height: 12),
          // Bowler Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  bowler,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildCompactDataCell(_formatOvers(overs)),
              _buildCompactDataCell(maidens.toString()),
              _buildCompactDataCell(runs.toString(), isBold: true),
              _buildCompactDataCell(wickets.toString(), isBold: true),
              _buildCompactDataCell(economy.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeaderCell(String text) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCompactDataCell(String text, {bool isBold = false}) {
    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  String _formatOvers(double overs) {
    final wholeOvers = overs.floor();
    final balls = ((overs - wholeOvers) * 6).round();
    if (balls == 6) {
      return '${wholeOvers + 1}.0';
    }
    return '$wholeOvers.$balls';
  }

  String _getTeamName(MatchModel match, String teamId) {
    if (match.team1Id == teamId) {
      return match.team1Name ?? 'Team 1';
    } else if (match.team2Id == teamId) {
      return match.team2Name ?? 'Team 2';
    }
    return 'Unknown Team';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Build batting stats from scorecard data
  List<_PlayerBattingStat> _buildBattingStatsFromScorecard(
    Map<String, dynamic> scorecard,
    String teamName, {
    bool isCurrent = false,
  }) {
    final stats = <_PlayerBattingStat>[];
    
    // Determine which stats map to use
    Map<String, dynamic>? statsMap;
    // If we're displaying the current innings, use 'player_stats_map'
    // If we're displaying the first innings (and it's not current), use 'first_innings_player_stats'
    
    // Note: The scorecard structure saves 'player_stats_map' for the ACTIVE innings.
    // So if isCurrent is true, we always look at 'player_stats_map'.
    // If isCurrent is false, it means we are looking at the prev innings, so we check 'first_innings_player_stats'.
    
    if (isCurrent) {
      statsMap = scorecard['player_stats_map'] as Map<String, dynamic>?;
    } else {
      statsMap = scorecard['first_innings_player_stats'] as Map<String, dynamic>?;
    }
    
    // If stats map exists, use it as the primary source of truth
    if (statsMap != null && statsMap.isNotEmpty) {
      final dismissalTypes = scorecard['dismissal_types'] as Map<String, dynamic>? ?? {};
      final dismissedPlayers = (scorecard['dismissed_players'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
      // Get all players in the stats map
      final players = statsMap.keys.toList();
      
      // Get active players for override (to match Summary tab consistency)
      final striker = isCurrent ? (scorecard['striker'] as String? ?? '') : '';
      final nonStriker = isCurrent ? (scorecard['non_striker'] as String? ?? '') : '';
      
      for (final player in players) {
        final playerStats = statsMap[player] as Map<String, dynamic>;
        
        // Default values from map
        int runs = (playerStats['runs'] as num?)?.toInt() ?? 0;
        int balls = (playerStats['balls'] as num?)?.toInt() ?? 0;
        int fours = (playerStats['fours'] as num?)?.toInt() ?? 0;
        int sixes = (playerStats['sixes'] as num?)?.toInt() ?? 0;
        
        // Use values from the stats map - the single source of truth recalculated from deliveries
        
        final strikeRate = balls > 0 ? (runs / balls) * 100 : 0.0;
        // startTime -> minutes calculation omitted for brevity/simplicity in read-only view
        
        final isDismissed = dismissedPlayers.contains(player) || (playerStats['dismissal'] != null);
        final dismissal = (playerStats['dismissal'] as String?) ?? (isDismissed ? dismissalTypes[player] as String? : null);
        
        stats.add(_PlayerBattingStat(
          playerName: player,
          runs: runs,
          balls: balls,
          fours: fours,
          sixes: sixes,
          strikeRate: strikeRate,
          minutes: 0,
          dismissal: dismissal,
          isNotOut: !isDismissed,
        ));
      }
      
      // Also add striker/non-striker if they are missing from stats map (shouldn't happen but safe fallback)
      if (isCurrent) {
        final striker = scorecard['striker'] as String? ?? '';
        final nonStriker = scorecard['non_striker'] as String? ?? '';
        
        if (striker.isNotEmpty && !stats.any((s) => s.playerName == striker)) {
           // Fallback for striker if somehow missing
           final strikerRuns = (scorecard['striker_runs'] as num?)?.toInt() ?? 0;
           final strikerBalls = (scorecard['striker_balls'] as num?)?.toInt() ?? 0;
           stats.add(_PlayerBattingStat(
             playerName: striker,
             runs: strikerRuns,
             balls: strikerBalls,
             fours: 0, sixes: 0,
             strikeRate: strikerBalls > 0 ? (strikerRuns / strikerBalls) * 100 : 0.0,
             minutes: 0,
             isNotOut: true
           ));
        }
        if (nonStriker.isNotEmpty && !stats.any((s) => s.playerName == nonStriker)) {
           // Fallback for non-striker
           final nonStrikerRuns = (scorecard['non_striker_runs'] as num?)?.toInt() ?? 0;
           final nonStrikerBalls = (scorecard['non_striker_balls'] as num?)?.toInt() ?? 0;
           stats.add(_PlayerBattingStat(
             playerName: nonStriker,
             runs: nonStrikerRuns,
             balls: nonStrikerBalls,
             fours: 0, sixes: 0,
             strikeRate: nonStrikerBalls > 0 ? (nonStrikerRuns / nonStrikerBalls) * 100 : 0.0,
             minutes: 0,
             isNotOut: true
           ));
        }
      }
      
      return stats;
    }
    
    // Legacy/Fallback Logic (if map is missing)
    // Get dismissal types
    final dismissalTypes = scorecard['dismissal_types'] as Map<String, dynamic>? ?? {};
    final dismissedPlayers = (scorecard['dismissed_players'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    // For current innings, get striker and non-striker stats
    if (isCurrent) {
      final striker = scorecard['striker'] as String? ?? '';
      final nonStriker = scorecard['non_striker'] as String? ?? '';
      final strikerRuns = (scorecard['striker_runs'] as num?)?.toInt() ?? 0;
      final strikerBalls = (scorecard['striker_balls'] as num?)?.toInt() ?? 0;
      final nonStrikerRuns = (scorecard['non_striker_runs'] as num?)?.toInt() ?? 0;
      final nonStrikerBalls = (scorecard['non_striker_balls'] as num?)?.toInt() ?? 0;
      
      if (striker.isNotEmpty) {
        final isDismissed = dismissedPlayers.contains(striker);
        final strikeRate = strikerBalls > 0 ? (strikerRuns / strikerBalls) * 100 : 0.0;
        stats.add(_PlayerBattingStat(
          playerName: striker,
          runs: strikerRuns,
          balls: strikerBalls,
          fours: 0, // Not tracked in current scorecard structure
          sixes: 0,
          strikeRate: strikeRate,
          minutes: 0,
          dismissal: isDismissed ? (dismissalTypes[striker] as String?) : null,
          isNotOut: !isDismissed,
        ));
      }
      
      if (nonStriker.isNotEmpty) {
        final isDismissed = dismissedPlayers.contains(nonStriker);
        final strikeRate = nonStrikerBalls > 0 ? (nonStrikerRuns / nonStrikerBalls) * 100 : 0.0;
        stats.add(_PlayerBattingStat(
          playerName: nonStriker,
          runs: nonStrikerRuns,
          balls: nonStrikerBalls,
          fours: 0,
          sixes: 0,
          strikeRate: strikeRate,
          minutes: 0,
          dismissal: isDismissed ? (dismissalTypes[nonStriker] as String?) : null,
          isNotOut: !isDismissed,
        ));
      }
      
      // Add dismissed players
      for (final player in dismissedPlayers) {
        if (player != striker && player != nonStriker) {
          final dismissal = dismissalTypes[player] as String?;
          stats.add(_PlayerBattingStat(
            playerName: player,
            runs: 0, // Not available in current structure
            balls: 0,
            fours: 0,
            sixes: 0,
            strikeRate: 0.0,
            minutes: 0,
            dismissal: dismissal,
            isNotOut: false,
          ));
        }
      }
    } else {
      // For first innings, show dismissed players
      for (final player in dismissedPlayers) {
        final dismissal = dismissalTypes[player] as String?;
        stats.add(_PlayerBattingStat(
          playerName: player,
          runs: 0,
          balls: 0,
          fours: 0,
          sixes: 0,
          strikeRate: 0.0,
          minutes: 0,
          dismissal: dismissal,
          isNotOut: false,
          ));
      }
    }
    
    return stats;
  }

  // Build bowling stats from scorecard data
  List<_PlayerBowlingStat> _buildBowlingStatsFromScorecard(
    Map<String, dynamic> scorecard,
    String teamName, {
    bool isCurrent = false,
  }) {
    final stats = <_PlayerBowlingStat>[];
    
    // Determine which stats map to use
    // For bowling, we need the bowlers from the OPPOSING team's innings
    // If we are displaying Team A's batting scorecard (isCurrent=true), 
    // we need Team B's bowlers (from 'bowler_stats_map' if isCurrent is true)
    
    // Wait, the scorecard argument structure in _buildScorecardTab passes:
    // _InningsScorecardWidget(teamName: BattingTeam ...)
    // So 'teamName' is the Batting Team.
    // We want the bowlers who bowled AGAINST this team.
    
    // In the Summary tab logic:
    // final bowlerStatsMap = scorecard['bowler_stats_map']
    // This 'bowler_stats_map' contains bowlers for the CURRENT active innings.
    
    Map<String, dynamic>? statsMap;
    
    if (isCurrent) {
      // Current innings bowlers (bowling against the current batting team)
      statsMap = scorecard['bowler_stats_map'] as Map<String, dynamic>?;
    } else {
      // First innings bowlers (bowled against the first batting team)
      statsMap = scorecard['first_innings_bowler_stats'] as Map<String, dynamic>?;
    }
    
    if (statsMap != null && statsMap.isNotEmpty) {
      final bowlers = statsMap.keys.toList();
      
      // Get active bowler for override
      final currentBowler = isCurrent ? (scorecard['bowler'] as String? ?? '') : '';

      for (final bowler in bowlers) {
        final bowlerStats = statsMap[bowler] as Map<String, dynamic>;
        
        double overs = (bowlerStats['overs'] as num?)?.toDouble() ?? 0.0;
        int maidens = (bowlerStats['maidens'] as num?)?.toInt() ?? 0;
        int runs = (bowlerStats['runs'] as num?)?.toInt() ?? 0;
        int wickets = (bowlerStats['wickets'] as num?)?.toInt() ?? 0;
        
        // Use values from the stats map - the single source of truth recalculated from deliveries
        final economy = overs > 0 ? runs / overs : 0.0;
        
        stats.add(_PlayerBowlingStat(
          bowlerName: bowler,
          overs: overs,
          maidens: maidens,
          runs: runs,
          wickets: wickets,
          economy: economy,
        ));
      }
    }
    
    return stats;
  }
}

// Delegate for the pinned TabBar in NestedScrollView
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// Player batting statistics
class _PlayerBattingStat {
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final int minutes;
  final String? dismissal;
  final bool isNotOut;

  _PlayerBattingStat({
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    required this.minutes,
    this.dismissal,
    this.isNotOut = false,
  });
}

// Player bowling statistics
class _PlayerBowlingStat {
  final String bowlerName;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;

  _PlayerBowlingStat({
    required this.bowlerName,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });
}

// Expandable Innings Scorecard Widget
class _InningsScorecardWidget extends StatefulWidget {
  final String teamName;
  final int runs;
  final int wickets;
  final double overs;
  final bool isCurrentInnings;
  final List<_PlayerBattingStat> battingStats;

  const _InningsScorecardWidget({
    required this.teamName,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.isCurrentInnings,
    required this.battingStats,
    required this.bowlingStats,
  });

  final List<_PlayerBowlingStat> bowlingStats;

  @override
  State<_InningsScorecardWidget> createState() => _InningsScorecardWidgetState();
}

class _InningsScorecardWidgetState extends State<_InningsScorecardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

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
    // Current innings starts expanded, previous starts collapsed
    _isExpanded = widget.isCurrentInnings;
    if (_isExpanded) {
      _animationController.value = 1.0;
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
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
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
                          widget.teamName,
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
                            '${widget.runs}',
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
                            '/${widget.wickets}',
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
                        '${_formatOvers(widget.overs)} Ov',
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
                  child: _BattingScorecardTable(
                    battingStats: widget.battingStats,
                  ),
                ),
                if (widget.bowlingStats.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _BowlingScorecardTable(
                      bowlingStats: widget.bowlingStats,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Bowling Scorecard Table Widget
class _BowlingScorecardTable extends StatelessWidget {
  final List<_PlayerBowlingStat> bowlingStats;

  const _BowlingScorecardTable({required this.bowlingStats});

  // Fixed column widths
  static const double _statColumnWidth = 45.0; 

  @override
  Widget build(BuildContext context) {
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
          // Table Header
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
                  width: _statColumnWidth,
                  child: _buildHeaderCell('O'),
                ),
                SizedBox(
                  width: _statColumnWidth,
                  child: _buildHeaderCell('M'),
                ),
                SizedBox(
                  width: _statColumnWidth,
                  child: _buildHeaderCell('R'),
                ),
                SizedBox(
                  width: _statColumnWidth,
                  child: _buildHeaderCell('W'),
                ),
                SizedBox(
                  width: 50,
                  child: _buildHeaderCell('Eco'),
                ),
              ],
            ),
          ),
          // Table Rows
          ...bowlingStats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            final isLast = index == bowlingStats.length - 1;
            return _buildBowlingRow(stat, isLast);
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

  Widget _buildBowlingRow(_PlayerBowlingStat stat, bool isLast) {
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
              stat.bowlerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(_formatOvers(stat.overs)),
          ),
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(stat.maidens.toString()),
          ),
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(stat.runs.toString(), isBold: true),
          ),
          SizedBox(
            width: _statColumnWidth,
            child: _buildDataCell(stat.wickets.toString(), isBold: true),
          ),
          SizedBox(
            width: 50,
            child: _buildDataCell(stat.economy.toStringAsFixed(1)),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBold = false}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
        color: AppColors.textMain,
      ),
    );
  }

  String _formatOvers(double overs) {
    final wholeOvers = overs.floor();
    final balls = ((overs - wholeOvers) * 6).round();
    if (balls == 6) {
      return '${wholeOvers + 1}.0';
    }
    return '$wholeOvers.$balls';
  }
}


// Batting Scorecard Table Widget
class _BattingScorecardTable extends StatelessWidget {
  final List<_PlayerBattingStat> battingStats;

  const _BattingScorecardTable({required this.battingStats});

  // Fixed column widths for perfect alignment
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

  Widget _buildBattingRow(_PlayerBattingStat stat, bool isLast) {
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
                Text(
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
