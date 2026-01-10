import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/repositories/match_repository.dart';
import '../../../../core/repositories/match_player_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'commentary_page.dart';
import '../../../live/presentation/pages/go_live_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Match Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(matchDetailProvider(widget.matchId));
              ref.invalidate(matchPlayersProvider(widget.matchId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share match functionality
            },
          ),
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

          return Column(
            children: [
              // Match Header Card
              _buildMatchHeader(match, currentUserId),
              
              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Info'),
                    Tab(text: 'Squads'),
                    Tab(text: 'Scorecard'),
                    Tab(text: 'Commentary'),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(match),
                    _buildSquadsTab(match, playersAsync),
                    _buildScorecardTab(match),
                    _buildCommentaryTab(match),
                  ],
                ),
              ),
            ],
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
    final statusColor = _getStatusColor(match.status);
    final statusText = match.status.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Teams
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (match.team1Name ?? 'Team 1').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.team1Name ?? 'Team 1',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (match.team2Name ?? 'Team 2').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.team2Name ?? 'Team 2',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Go Live Button (only for match creator)
          if (currentUserId != null && match.createdBy == currentUserId)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/go-live',
                    extra: {
                      'matchId': match.id,
                      'matchTitle': '${match.team1Name ?? 'Team 1'} vs ${match.team2Name ?? 'Team 2'}',
                    },
                  );
                },
                icon: const Icon(Icons.videocam, color: Colors.white),
                label: const Text(
                  'GO LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
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
            ),
          // Show current innings
          _InningsScorecardWidget(
            teamName: secondInningsTeam,
            runs: currentRuns,
            wickets: currentWickets,
            overs: currentOvers,
            isCurrentInnings: true,
            battingStats: _buildBattingStatsFromScorecard(scorecard, secondInningsTeam, isCurrent: true),
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
      
      for (final player in players) {
        final playerStats = statsMap[player] as Map<String, dynamic>;
        final runs = (playerStats['runs'] as num?)?.toInt() ?? 0;
        final balls = (playerStats['balls'] as num?)?.toInt() ?? 0;
        final fours = (playerStats['fours'] as num?)?.toInt() ?? 0;
        final sixes = (playerStats['sixes'] as num?)?.toInt() ?? 0;
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
  });

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
