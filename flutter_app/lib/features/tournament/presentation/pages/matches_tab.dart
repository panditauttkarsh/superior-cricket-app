import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/tournament_model.dart';
import '../../../../core/providers/auth_provider.dart';

class MatchesTab extends ConsumerStatefulWidget {
  final String tournamentId;
  final TournamentModel? tournament;

  const MatchesTab({
    super.key,
    required this.tournamentId,
    this.tournament,
  });

  @override
  ConsumerState<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<MatchesTab> {
  List<MatchModel> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  Future<void> _loadMatches() async {
    try {
      final matchRepo = ref.read(matchRepositoryProvider);
      final matches = await matchRepo.getTournamentMatches(widget.tournamentId);
      
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load matches: $e')),
        );
      }
    }
  }

  Future<void> _navigateToCreateMatch() async {
    await context.push('/create-match', extra: {'tournamentId': widget.tournamentId});
    _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Action Row
            _buildCreateMatchHeader(),
            
            const SizedBox(height: 0),
            
            // Matches List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMatchItem(match),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool get _isTournamentCompleted {
    final status = widget.tournament?.status;
    final endDate = widget.tournament?.endDate;
    final now = DateTime.now();
    
    // Check explicit status
    if (status == 'completed' || status == 'ended') return true;
    
    // Check date (if end date is in the past, consider it completed)
    if (endDate != null && now.isAfter(endDate)) return true;
    
    return false;
  }

  Widget _buildEmptyState() {
    final isCompleted = _isTournamentCompleted;
    final emptyText = isCompleted 
        ? 'No matches were played in this tournament' 
        : 'Matches will be displayed here';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_cricket,
                size: 64,
                color: AppColors.textMeta,
              ),
              const SizedBox(height: 16),
              Text(
                emptyText,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSec,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isCompleted) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToCreateMatch,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Match'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateMatchHeader() {
    if (_isTournamentCompleted) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Create a new match',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
          onPressed: _navigateToCreateMatch,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildMatchItem(MatchModel match) {
    // Process match data for display
    final scorecard = match.scorecard ?? {};
    final team1Score = scorecard['team1_score'] ?? {};
    final team2Score = scorecard['team2_score'] ?? {};
    final team1Runs = (team1Score['runs'] as num?)?.toInt() ?? 0;
    final team1Wickets = (team1Score['wickets'] as num?)?.toInt() ?? 0;
    final team1Overs = (team1Score['overs'] as num?)?.toDouble() ?? 0.0;
    final team2Runs = (team2Score['runs'] as num?)?.toInt() ?? 0;
    final team2Wickets = (team2Score['wickets'] as num?)?.toInt() ?? 0;
    final team2Overs = (team2Score['overs'] as num?)?.toDouble() ?? 0.0;
    
    // Convert to map for helper method reuse
    final matchData = {
      'id': match.id,
      'status': match.status,
      'venue': match.groundType.isNotEmpty ? match.groundType : 'Venue TBA',
      'date': _formatMatchDate(match.scheduledAt ?? match.completedAt ?? match.createdAt),
      'dateTime': match.scheduledAt != null ? _formatMatchDateTime(match.scheduledAt!) : 'Date TBA',
      'overs': match.overs,
      'team1Name': match.team1Name ?? 'Team 1',
      'team2Name': match.team2Name ?? 'Team 2',
      'team1Runs': team1Runs,
      'team1Wickets': team1Wickets,
      'team1Overs': team1Overs,
      'team2Runs': team2Runs,
      'team2Wickets': team2Wickets,
      'team2Overs': team2Overs,
      'stage': null, // Need to fetch stage if available
      'tournamentName': null,
      'createdBy': match.createdBy,
      'currentUserId': ref.read(authStateProvider).user?.id,
    };

    return GestureDetector(
      onTap: () {
        context.push('/matches/${match.id}');
      },
      child: _buildMatchCard(matchData),
    );
  }

  // --- Helper Methods Copied/Adapted from MyCricketPage ---

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final status = match['status'] as String? ?? 'upcoming';
    final isLive = status == 'live';
    final isUpcoming = status == 'upcoming';

    if (isUpcoming) {
      return _buildUpcomingMatchCard(match);
    }
    
    if (isLive) {
      return _buildLiveMatchCard(match);
    }
    
    return _buildCompletedMatchCard(match);
  }

  Widget _buildUpcomingMatchCard(Map<String, dynamic> match) {
    final dateTime = match['dateTime'] as String? ?? 'Date TBA';
    final venue = match['venue'] as String? ?? 'Venue TBA';
    final overs = match['overs'] as int? ?? 20;
    final team1Name = match['team1Name'] as String? ?? 'Team 1';
    final team2Name = match['team2Name'] as String? ?? 'Team 2';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      dateTime,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMain,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.textSec),
                    const SizedBox(width: 4),
                    Text(
                      venue,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSec,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildUpcomingTeamRow(team1Name),
            const SizedBox(height: 16),
            _buildUpcomingTeamRow(team2Name),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Limited $overs overs',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSec,
                    fontFamily: 'Inter',
                  ),
                ),
                // Could add Start/Edit button here if creator
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMatchCard(Map<String, dynamic> match) {
    final venue = match['venue'] as String? ?? 'Venue TBA';
    final date = match['date'] as String? ?? 'Date TBA';
    final overs = match['overs'] as int? ?? 20;
    final team1Name = match['team1Name'] as String? ?? 'Team 1';
    final team2Name = match['team2Name'] as String? ?? 'Team 2';
    final team1Runs = match['team1Runs'] as int;
    final team1Wickets = match['team1Wickets'] as int;
    final team1Overs = match['team1Overs'] as double;
    final team2Runs = match['team2Runs'] as int;
    final team2Wickets = match['team2Wickets'] as int;
    final team2Overs = match['team2Overs'] as double;
    
    final createdBy = match['createdBy'] as String?;
    final currentUserId = match['currentUserId'] as String?;
    final isScorer = createdBy != null && currentUserId != null && createdBy == currentUserId;
    final matchId = match['id'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$venue | $date | $overs Ov.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSec,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Inter',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildTeamRow(team1Name, team1Runs, team1Wickets, team1Overs, false),
                const SizedBox(height: 16),
                _buildTeamRow(team2Name, team2Runs, team2Wickets, team2Overs, false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isScorer)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (matchId != null) {
                      context.push('/scorecard', extra: {'matchId': matchId});
                    }
                  },
                  icon: const Icon(Icons.edit_note, size: 20, color: Colors.white),
                  label: const Text(
                    'Continue Scoring',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCompletedMatchCard(Map<String, dynamic> match) {
    final venue = match['venue'] as String? ?? 'Venue TBA';
    final date = match['date'] as String? ?? 'Date TBA';
    final overs = match['overs'] as int? ?? 20;
    
    final team1Name = match['team1Name'] as String? ?? 'Team 1';
    final team2Name = match['team2Name'] as String? ?? 'Team 2';
    final team1Runs = match['team1Runs'] as int;
    final team1Wickets = match['team1Wickets'] as int;
    final team1Overs = match['team1Overs'] as double;
    final team2Runs = match['team2Runs'] as int;
    final team2Wickets = match['team2Wickets'] as int;
    final team2Overs = match['team2Overs'] as double;

    // Calculate winner for highlighting
    // This is simple logic, ideally we use 'winnerId' or 'resultText' from match data
    // For now we assume typical Cricket logic if not provided
    bool team1Won = false;
    bool team2Won = false;
    
    // Simple visual check for bolding
    if (team1Runs > team2Runs) team1Won = true; // Very naive, ignores wickets/second innings logic
    else if (team2Runs > team1Runs) team2Won = true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$venue | $date | $overs Ov.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSec,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textMain,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Result',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTeamRow(team1Name, team1Runs, team1Wickets, team1Overs, team1Won),
            const SizedBox(height: 16),
            _buildTeamRow(team2Name, team2Runs, team2Wickets, team2Overs, team2Won),
            const SizedBox(height: 16),
            // Could add Result Text Summary here like "Team A won by X runs"
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTeamRow(String teamName) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
          ),
          child: Icon(Icons.sports_cricket, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            teamName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRow(String teamName, int runs, int wickets, double overs, bool isWinner) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textMain,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$runs/$wickets',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.w600,
                color: AppColors.textMain,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatOvers(overs),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: AppColors.textSec,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatMatchDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    final year = date.year.toString().substring(2);
    return '$day-$month-$year';
  }

  String _formatMatchDateTime(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = _getFullMonthName(date.month);
    final year = date.year;
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $day $month $year, $hour:$minute$amPm';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _getFullMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatOvers(double overs) {
    return '${overs.toStringAsFixed(1)} Ov';
  }
}
