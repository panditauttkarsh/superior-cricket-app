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
    
    // Calculate result text
    String? resultText;
    if (match.status == 'completed' && match.winnerId != null) {
      if (match.winnerId == match.team1Id) {
        final runsDiff = team1Runs - team2Runs;
        final wicketsDiff = team2Wickets - team1Wickets;
        if (runsDiff > 0) {
          resultText = '${match.team1Name ?? "Team 1"} won by $runsDiff runs';
        } else if (wicketsDiff > 0) {
          resultText = '${match.team1Name ?? "Team 1"} won by $wicketsDiff wicket${wicketsDiff > 1 ? 's' : ''}';
        }
      } else {
        final runsDiff = team2Runs - team1Runs;
        final wicketsDiff = team1Wickets - team2Wickets;
        if (runsDiff > 0) {
          resultText = '${match.team2Name ?? "Team 2"} won by $runsDiff runs';
        } else if (wicketsDiff > 0) {
          resultText = '${match.team2Name ?? "Team 2"} won by $wicketsDiff wicket${wicketsDiff > 1 ? 's' : ''}';
        }
      }
    }

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
      'stage': null, 
      'tournamentName': widget.tournament?.name,
      'resultText': resultText,
      'winnerId': match.winnerId,
      'createdBy': match.createdBy,
      'currentUserId': ref.read(authStateProvider).user?.id,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildMatchCard(matchData),
    );
  }

  // --- Helper Methods Ported from MyCricketPage ---

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final status = match['status'] as String? ?? 'upcoming';
    final isCompleted = status == 'completed';
    final isUpcoming = status == 'upcoming';
    final isLive = status == 'live';
    
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
    final matchId = match['id'] as String?;
    final createdBy = match['createdBy'] as String?;
    final currentUserId = match['currentUserId'] as String?;
    final isCreator = createdBy != null && currentUserId != null && createdBy == currentUserId;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF90A4AE).withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: const Color(0xFF607D8B).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (matchId != null) {
              context.go('/matches/$matchId');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          dateTime,
                          style: const TextStyle(
                            fontSize: 12,
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
                        const Icon(Icons.location_on, size: 14, color: AppColors.textSec),
                        const SizedBox(width: 4),
                        Text(
                          venue,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSec,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildUpcomingTeamRow(team1Name),
                const SizedBox(height: 4),
                _buildUpcomingTeamRow(team2Name),
                const SizedBox(height: 6),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Limited $overs overs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSec,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (isCreator)
                      ElevatedButton.icon(
                        onPressed: () {
                          if (matchId != null) {
                            context.push('/scorecard', extra: {'matchId': matchId});
                          }
                        },
                        icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                        label: const Text(
                          'Start',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLiveMatchCard(Map<String, dynamic> match) {
    final date = match['date'] as String? ?? 'Date TBA';
    final tournamentName = match['tournamentName'] as String?;
    final team1Name = match['team1Name'] as String? ?? 'Team 1';
    final team2Name = match['team2Name'] as String? ?? 'Team 2';
    final team1Runs = match['team1Runs'] as int;
    final team1Wickets = match['team1Wickets'] as int;
    final team1Overs = match['team1Overs'] as double;
    final team2Runs = match['team2Runs'] as int;
    final team2Wickets = match['team2Wickets'] as int;
    final team2Overs = match['team2Overs'] as double;
    final matchId = match['id'] as String?;
    final createdBy = match['createdBy'] as String?;
    final currentUserId = match['currentUserId'] as String?;
    final isScorer = createdBy != null && currentUserId != null && createdBy == currentUserId;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF90A4AE).withOpacity(0.2), 
            blurRadius: 24, 
            offset: const Offset(0, 8), 
            spreadRadius: 5, 
          ),
          BoxShadow(
            color: const Color(0xFF607D8B).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4), 
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: AppColors.success),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textSec, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                  (tournamentName?.isNotEmpty == true ? tournamentName! : 'MATCH').toUpperCase(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildTeamScoreColumn(team1Name, team1Runs, team1Wickets, team1Overs, false)),
                          _buildVsDivider(),
                          Expanded(child: _buildTeamScoreColumn(team2Name, team2Runs, team2Wickets, team2Overs, true)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: AppColors.success.withOpacity(0.05),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Match in progress...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success))),
                          ElevatedButton(
                            onPressed: () {
                              if (isScorer) {
                                if (matchId != null) context.go('/scorecard', extra: {'matchId': matchId});
                              } else {
                                if (matchId != null) context.go('/matches/$matchId');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCE5A46),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Row(
                              children: [
                                Text(isScorer ? 'Continue Scoring' : 'Match Centre', style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompletedMatchCard(Map<String, dynamic> match) {
    final tournamentName = match['tournamentName'] as String?;
    final date = match['date'] as String? ?? 'Date TBA';
    final team1Name = match['team1Name'] as String? ?? 'Team 1';
    final team2Name = match['team2Name'] as String? ?? 'Team 2';
    final team1Runs = match['team1Runs'] as int;
    final team1Wickets = match['team1Wickets'] as int;
    final team1Overs = match['team1Overs'] as double;
    final team2Runs = match['team2Runs'] as int;
    final team2Wickets = match['team2Wickets'] as int;
    final team2Overs = match['team2Overs'] as double;
    final resultText = match['resultText'] as String? ?? 'Match Completed';
    final matchId = match['id'] as String?;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF90A4AE).withOpacity(0.2), 
            blurRadius: 24, 
            offset: const Offset(0, 8), 
            spreadRadius: 5, 
          ),
          BoxShadow(
            color: const Color(0xFF607D8B).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4), 
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: Colors.blue),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textSec, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(
                                  (tournamentName?.isNotEmpty == true ? tournamentName! : 'MATCH').toUpperCase(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _buildTeamScoreColumn(team1Name, team1Runs, team1Wickets, team1Overs, false)),
                          _buildVsDivider(),
                          Expanded(child: _buildTeamScoreColumn(team2Name, team2Runs, team2Wickets, team2Overs, true)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.blue.withOpacity(0.05),
                      child: Row(
                        children: [
                          Expanded(child: Text(resultText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          ElevatedButton(
                            onPressed: () {
                              if (matchId != null) context.go('/matches/$matchId');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCE5A46),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Row(
                              children: const [
                                Text('Match Centre', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamScoreColumn(String teamName, int runs, int wickets, double overs, bool isSecondaryColor) {
    return Column(
      crossAxisAlignment: isSecondaryColor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('$runs/$wickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isSecondaryColor ? const Color(0xFFF57C00) : Colors.black)),
        Text('(${overs.toStringAsFixed(1)} Ov)', style: const TextStyle(fontSize: 11, color: AppColors.textSec)),
      ],
    );
  }
  
  Widget _buildVsDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 30, width: 1, color: Colors.grey[300]),
          Container(padding: const EdgeInsets.all(4), color: AppColors.surface, child: Text('VS', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildUpcomingTeamRow(String teamName) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.1)),
          child: const Icon(Icons.sports_cricket, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            teamName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain, fontFamily: 'Inter'),
          ),
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
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}
