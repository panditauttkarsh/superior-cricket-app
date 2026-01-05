import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/enhanced_create_match_dialog.dart';

class MyCricketPage extends ConsumerStatefulWidget {
  final String? initialTab;
  
  const MyCricketPage({super.key, this.initialTab});

  @override
  ConsumerState<MyCricketPage> createState() => _MyCricketPageState();
}

class _MyCricketPageState extends ConsumerState<MyCricketPage> {
  late String _activeTab;
  
  String _statsFilter = 'Batting';
  String _matchesFilter = 'My';
  String _teamsFilter = 'My';
  String _tournamentFilter = 'All';
  
  // Supabase data
  List<MatchModel> _allMatches = [];
  List<TeamModel> _allTeams = [];
  List<TournamentModel> _allTournaments = [];
  
  // Loading states
  bool _isLoadingMatches = false;
  bool _isLoadingTeams = false;
  bool _isLoadingTournaments = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab ?? 'Matches';
    
    // Load data after first build when ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMatches(),
      _loadTeams(),
      _loadTournaments(),
    ]);
  }

  Future<void> _loadMatches() async {
    if (mounted) {
      setState(() {
        _isLoadingMatches = true;
      });
    }
    
    try {
      final matchRepo = ref.read(matchRepositoryProvider);
      final user = ref.read(authStateProvider).user;
      
      final matches = await matchRepo.getMatches(
        userId: user?.id,
        limit: 50,
      );
      
      if (mounted) {
        setState(() {
          _allMatches = matches;
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMatches = false;
        });
      }
    }
  }

  Future<void> _loadTeams() async {
    if (mounted) {
      setState(() {
        _isLoadingTeams = true;
      });
    }
    
    try {
      final teamRepo = ref.read(teamRepositoryProvider);
      final user = ref.read(authStateProvider).user;
      
      final teams = await teamRepo.getTeams(
        userId: user?.id,
        limit: 50,
      );
      
      if (mounted) {
        setState(() {
          _allTeams = teams;
          _isLoadingTeams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTeams = false;
        });
      }
    }
  }

  Future<void> _loadTournaments() async {
    if (mounted) {
      setState(() {
        _isLoadingTournaments = true;
      });
    }
    
    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      
      final tournaments = await tournamentRepo.getTournaments(
        limit: 50,
      );
      
      if (mounted) {
        setState(() {
          _allTournaments = tournaments;
          _isLoadingTournaments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTournaments = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tabs
            _buildTabs(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTabContent(),
                  ),
                ),
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textMain, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                'My Cricket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () {
              context.push('/create-match');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Matches', 'Tournaments', 'Teams', 'Stats'];
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isActive = _activeTab == tab;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                margin: EdgeInsets.only(right: index < tabs.length - 1 ? 24 : 0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.textSec,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'Matches':
        return _buildMatchesContent();
      case 'Tournaments':
        return _buildTournamentsContent();
      case 'Teams':
        return _buildTeamsContent();
      case 'Stats':
        return Container(
          color: AppColors.background, // Off-white background (less bright)
          child: _buildStatsContent(),
        );
      default:
        return _buildMatchesContent();
    }
  }

  Widget _buildMatchesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Want to start a match section - similar to tournament section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Want to start a match?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                context.push('/create-match');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textMain,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              child: const Text('Start'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Filter tabs - matching second screenshot design
        Row(
          children: [
            _buildFilterTab('My', _matchesFilter == 'My'),
            _buildFilterTab('Upcoming', _matchesFilter == 'Upcoming'),
            _buildFilterTab('Nearby', _matchesFilter == 'Nearby'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Match list based on filter
        _buildMatchesList(),
      ],
    );
  }

  Widget _buildMatchesList() {
    if (_isLoadingMatches) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    List<MatchModel> filteredMatches = [];
    final user = ref.read(authStateProvider).user;
    
    if (_matchesFilter == 'My') {
      // Get matches where user's team is involved, but only started matches (live or completed)
      filteredMatches = _allMatches.where((match) {
        // Check if user's teams are involved (simplified - you might need to check team membership)
        final isUserMatch = match.createdBy == user?.id || 
                           match.team1Id == user?.id || 
                           match.team2Id == user?.id;
        // Only include matches that have been started (live or completed), exclude upcoming
        final isStarted = match.status == 'live' || match.status == 'completed';
        return isUserMatch && isStarted;
      }).toList();
    } else if (_matchesFilter == 'Upcoming') {
      // Show all upcoming matches
      filteredMatches = _allMatches.where((match) => match.status == 'upcoming').toList();
    } else if (_matchesFilter == 'Nearby') {
      // Coming soon
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 64, color: AppColors.textSec),
              const SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSec,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find nearby matches feature will be available soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMeta,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (filteredMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No matches found',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSec,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: filteredMatches.map((match) {
        // Convert MatchModel to the format expected by _buildMatchCard
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
        String? winningTeam;
        if (match.status == 'completed' && match.winnerId != null) {
          if (match.winnerId == match.team1Id) {
            winningTeam = match.team1Name ?? 'Team 1';
            final runsDiff = team1Runs - team2Runs;
            final wicketsDiff = team2Wickets - team1Wickets;
            if (runsDiff > 0) {
              resultText = '${match.team1Name ?? "Team 1"} won by $runsDiff runs';
            } else if (wicketsDiff > 0) {
              resultText = '${match.team1Name ?? "Team 1"} won by $wicketsDiff wicket${wicketsDiff > 1 ? 's' : ''}';
            }
          } else {
            winningTeam = match.team2Name ?? 'Team 2';
            final runsDiff = team2Runs - team1Runs;
            final wicketsDiff = team1Wickets - team2Wickets;
            if (runsDiff > 0) {
              resultText = '${match.team2Name ?? "Team 2"} won by $runsDiff runs';
            } else if (wicketsDiff > 0) {
              resultText = '${match.team2Name ?? "Team 2"} won by $wicketsDiff wicket${wicketsDiff > 1 ? 's' : ''}';
            }
          }
        }
        
        // Format date for display
        final matchDate = match.scheduledAt ?? match.completedAt ?? match.createdAt;
        final dateStr = _formatMatchDate(matchDate);
        final dateTimeStr = match.scheduledAt != null 
            ? _formatMatchDateTime(match.scheduledAt!)
            : null;
        
        // Format venue (using groundType as venue placeholder)
        final venue = match.groundType.isNotEmpty 
            ? match.groundType 
            : 'Venue TBA';
        
        // Get tournament info if available - check if match has tournament association
        // For now, tournament info would come from a tournament_id field if it exists
        // or from a join query. Since it's not in the current model, we'll leave it null
        final tournamentName = null; // Will be populated when tournament relation is available
        
        final matchData = {
          'id': match.id,
          'team1Id': match.team1Id,
          'team2Id': match.team2Id,
          'team1Name': match.team1Name ?? 'Team 1',
          'team2Name': match.team2Name ?? 'Team 2',
          'team1Runs': team1Runs,
          'team1Wickets': team1Wickets,
          'team1Overs': team1Overs,
          'team2Runs': team2Runs,
          'team2Wickets': team2Wickets,
          'team2Overs': team2Overs,
          'overs': match.overs,
          'venue': venue,
          'date': dateStr,
          'dateTime': dateTimeStr,
          'tournamentName': tournamentName,
          'stage': null, // Will be populated when tournament relation is available
          'status': match.status,
          'winnerId': match.winnerId,
          'resultText': resultText,
          'winningTeam': winningTeam,
        };
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: () {
              // Navigate to match details page with real-time data
              context.go('/matches/${match.id}');
            },
            child: _buildMatchCard(matchData),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else {
      // Format: "22 Dec, 2025" to match screenshot
      return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
    }
  }

  String _formatMatchDate(DateTime date) {
    // Format: "06-Dec-25" to match the design
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    final year = date.year.toString().substring(2);
    return '$day-$month-$year';
  }

  String _formatMatchDateTime(DateTime date) {
    // Format: "Wed, 5 Jun 2024, 10:30AM" to match the reference design
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    final day = date.day;
    final month = _getFullMonthName(date.month);
    final year = date.year;
    
    // Format time
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$weekday, $day $month $year, $hour:$minute$amPm';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
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
    // Format overs as "19.5 Ov" or "20.0 Ov"
    return '${overs.toStringAsFixed(1)} Ov';
  }
  
  String _formatOversLabel(int overs) {
    // Format: "Limited 10 overs" for match format display
    return 'Limited $overs overs';
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final status = match['status'] as String? ?? 'upcoming';
    final isCompleted = status == 'completed';
    final isUpcoming = status == 'upcoming';
    
    // For upcoming matches, show the new design
    if (isUpcoming) {
      return _buildUpcomingMatchCard(match);
    }
    
    // For completed matches, show the detailed design
    return _buildCompletedMatchCard(match);
  }
  
  Widget _buildUpcomingMatchCard(Map<String, dynamic> match) {
    final dateTime = match['dateTime'] as String? ?? 'Date TBA';
    final venue = match['venue'] as String? ?? 'Venue TBA';
    final overs = match['overs'] as int? ?? 20;
    final team1Name = match['team1Name'] as String? ?? 'Team 1';
    final team2Name = match['team2Name'] as String? ?? 'Team 2';
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to match details with real-time data
            if (matchId != null) {
              context.go('/matches/$matchId');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date/Time and Venue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date/Time centered
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
                // Venue with icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSec,
                    ),
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
            
            // Team 1
            _buildUpcomingTeamRow(team1Name),
            
            const SizedBox(height: 16),
            
            // Team 2
            _buildUpcomingTeamRow(team2Name),
            
            const SizedBox(height: 20),
            
            // Divider
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            
            const SizedBox(height: 16),
            
            // Footer: Match Format and Start Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Match Format
                Text(
                  _formatOversLabel(overs),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSec,
                    fontFamily: 'Inter',
                  ),
                ),
                // Start Button
                ElevatedButton.icon(
                  onPressed: () {
                    // Start match logic
                  },
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Inter',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35), // Orange color from reference
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
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
  
  Widget _buildUpcomingTeamRow(String teamName) {
    return Row(
      children: [
        // Circular Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
          ),
          child: Icon(
            Icons.sports_cricket,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        // Team Name
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
  
  Widget _buildCompletedMatchCard(Map<String, dynamic> match) {
    final stage = match['stage'] as String?;
    final tournamentName = match['tournamentName'] as String?;
    final venue = match['venue'] as String? ?? 'Venue TBA';
    final date = match['date'] as String? ?? 'Date TBA';
    final overs = match['overs'] as int? ?? 20;
    
    // Build header text - only show if tournament exists
    final headerText = tournamentName != null && tournamentName.isNotEmpty
        ? (stage != null && stage.isNotEmpty 
            ? '$stage, $tournamentName' 
            : tournamentName)
        : null;
    
    final team1Name = match['team1Name'] as String? ?? 'Team 1';
    final team2Name = match['team2Name'] as String? ?? 'Team 2';
    final team1Runs = (match['team1Runs'] as num?)?.toInt() ?? 0;
    final team1Wickets = (match['team1Wickets'] as num?)?.toInt() ?? 0;
    final team1Overs = (match['team1Overs'] as num?)?.toDouble() ?? 0.0;
    final team2Runs = (match['team2Runs'] as num?)?.toInt() ?? 0;
    final team2Wickets = (match['team2Wickets'] as num?)?.toInt() ?? 0;
    final team2Overs = (match['team2Overs'] as num?)?.toDouble() ?? 0.0;
    
    final winnerId = match['winnerId'] as String?;
    final winningTeam = match['winningTeam'] as String?;
    final resultText = match['resultText'] as String?;
    final team1Id = match['team1Id'] as String;
    final team2Id = match['team2Id'] as String;
    
    final isTeam1Winner = winnerId != null && winnerId == team1Id;
    final isTeam2Winner = winnerId != null && winnerId == team2Id;
    
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to match details with real-time data
            if (matchId != null) {
              context.go('/matches/$matchId');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match Stage and Tournament - only show if tournament exists
                      if (headerText != null) ...[
                        Text(
                          headerText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      // Venue, Date, and Overs
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
                // Result Button
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textMain,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
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
          ),
          
          // Teams and Scores Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Team 1
                _buildTeamRow(
                  team1Name,
                  team1Runs,
                  team1Wickets,
                  team1Overs,
                  isTeam1Winner,
                ),
                const SizedBox(height: 12),
                // Team 2
                _buildTeamRow(
                  team2Name,
                  team2Runs,
                  team2Wickets,
                  team2Overs,
                  isTeam2Winner,
                ),
              ],
            ),
          ),
          
          // Result Summary
          if (resultText != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                resultText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
          
          // Action Links
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionLink('Insights', () {}),
                const SizedBox(width: 20),
                _buildActionLink('Table', () {}),
                const SizedBox(width: 20),
                _buildActionLink('Leaderboard', () {}),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamRow(String teamName, int runs, int wickets, double overs, bool isWinner) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Name
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
        // Score and Overs
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
  
  Widget _buildActionLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _matchesFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface : AppColors.background,
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : AppColors.textSec,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBox({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSec,
                    ),
                  ),
                ],
              ),
            ),
            if (isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Want to start a tournament section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Want to start a tournament?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate directly to Add Tournament screen
                  context.go('/tournament/add');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textSec, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search tournaments, leagues...',
                    style: TextStyle(color: AppColors.textSec, fontSize: 14),
                  ),
                ),
                Icon(Icons.tune, color: AppColors.textSec, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter Tabs
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              children: ['All', 'Live Now', 'Upcoming', 'T20 Bash'].map((tab) {
                final isActive = _tournamentFilter == tab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _tournamentFilter = tab;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: EdgeInsets.symmetric(
                      horizontal: tab == 'Upcoming' ? 24 : 20, // More padding for "Upcoming"
                      vertical: 12,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 80, // Ensure minimum width
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: isActive ? Colors.white : AppColors.divider,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tab == 'Live Now') ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.urgent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isActive ? AppColors.textMain : AppColors.textSec,
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          
          // Content based on filter
          _buildTournamentContent(),
        ],
      ),
    );
  }

  Widget _buildTournamentContent() {
    // Filter tournaments based on selected tab
    switch (_tournamentFilter) {
      case 'All':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedEventSection(),
            const SizedBox(height: 28),
            _buildOpenTournamentsSection(),
          ],
        );
      case 'Live Now':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedEventSection(), // Show live featured event
            const SizedBox(height: 28),
            _buildOpenTournamentsSection(filter: 'Live'),
          ],
        );
      case 'Upcoming':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOpenTournamentsSection(filter: 'Upcoming'),
          ],
        );
      case 'T20 Bash':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOpenTournamentsSection(filter: 'T20'),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedEventSection(),
            const SizedBox(height: 28),
            _buildOpenTournamentsSection(),
          ],
        );
    }
  }

  Widget _buildFeaturedEventSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Event',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Featured Image
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=400&h=250&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badges
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.urgent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.surface,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'T20 Format',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMain,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Featured Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Super League',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The biggest T20 showdown of the year is here.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSec,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRIZE POOL',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSec,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '\$500,000',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textMain,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Register Now',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
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
      ],
    );
  }

  Widget _buildOpenTournamentsSection({String? filter}) {
    if (_isLoadingTournaments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    List<TournamentModel> filteredTournaments = [];
    
    // Filter tournaments based on selected filter
    if (filter == null || filter == 'All') {
      filteredTournaments = _allTournaments;
    } else if (filter == 'Live') {
      filteredTournaments = _allTournaments.where((t) => t.status == 'ongoing').toList();
    } else if (filter == 'Upcoming') {
      filteredTournaments = _allTournaments.where((t) => t.status == 'registration_open' || t.status == 'upcoming').toList();
    } else if (filter == 'T20') {
      // For now, all tournaments (you can add format field to TournamentModel if needed)
      filteredTournaments = _allTournaments;
    }
    
    // Convert TournamentModel to the format expected by the UI
    final tournaments = filteredTournaments.map((tournament) {
      final teamsText = tournament.totalTeams != null
          ? '${tournament.registeredTeams ?? 0}/${tournament.totalTeams} Teams'
          : '${tournament.registeredTeams ?? 0} Teams';
      
      final startDate = tournament.startDate;
      final formattedDate = '${startDate.day} ${_getMonthName(startDate.month)}';
      
      final daysLeft = startDate.difference(DateTime.now()).inDays;
      final daysLeftText = daysLeft > 0 ? '$daysLeft Days Left' : daysLeft == 0 ? 'Starts Today' : 'Started';
      
      return {
        'id': tournament.id,
        'imageUrl': tournament.imageUrl ?? 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=120&h=100&fit=crop',
        'title': tournament.name,
        'entryFee': tournament.prizePool != null ? '₹${tournament.prizePool!.toStringAsFixed(0)}' : 'Free',
        'entryFeeColor': tournament.prizePool != null ? AppColors.warning : AppColors.primary,
        'teams': teamsText,
        'date': formattedDate,
        'daysLeft': daysLeftText,
        'participants': tournament.registeredTeams ?? 0,
        'isLocked': tournament.status == 'completed',
        'status': tournament.status == 'ongoing' ? 'Live' : tournament.status == 'registration_open' ? 'Upcoming' : 'Completed',
        'format': 'T20', // You can add format to TournamentModel if needed
      };
    }).toList();
    
    if (tournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No tournaments found',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSec,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          filter == null || filter == 'All' 
              ? 'Open Tournaments' 
              : filter == 'Live' 
                  ? 'Live Tournaments'
                  : filter == 'Upcoming'
                      ? 'Upcoming Tournaments'
                      : 'T20 Tournaments',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),
        ...tournaments.map((tournament) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildTournamentCard(
              imageUrl: tournament['imageUrl'] as String,
              title: tournament['title'] as String,
              entryFee: tournament['entryFee'] as String,
              entryFeeColor: tournament['entryFeeColor'] as Color,
              teams: tournament['teams'] as String,
              date: tournament['date'] as String,
              daysLeft: tournament['daysLeft'] as String?,
              participants: tournament['participants'] as int?,
              specialTag: tournament['specialTag'] as String?,
              isLocked: tournament['isLocked'] as bool,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTournamentCard({
    required String imageUrl,
    required String title,
    required String entryFee,
    required Color entryFeeColor,
    required String teams,
    required String date,
    String? daysLeft,
    int? participants,
    String? specialTag,
    required bool isLocked,
  }) {
    return Opacity(
      opacity: isLocked ? 0.7 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Tournament Image
            Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (daysLeft != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        daysLeft,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Tournament Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark_border,
                          color: AppColors.textMeta,
                          size: 18,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Entry Fee
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec,
                      ),
                      children: [
                        const TextSpan(text: 'Entry: '),
                        TextSpan(
                          text: entryFee,
                          style: TextStyle(
                            color: entryFeeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Meta
                  Row(
                    children: [
                      _buildMetaItem(Icons.people_outline, teams),
                      if (date.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        _buildMetaItem(Icons.calendar_today, date),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (participants != null)
                        _buildParticipants(participants)
                      else if (specialTag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            specialTag,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (isLocked)
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMeta,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF205A28), width: 1.5),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'JOIN NOW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
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
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSec),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSec,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipants(int moreCount) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://api.dicebear.com/7.x/avataaars/svg?seed=1',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              left: 16,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://api.dicebear.com/7.x/avataaars/svg?seed=2',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          '+$moreCount',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSec,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Teams',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            TextButton(
              onPressed: () => _showCreateTeamDialog(),
              child: const Text(
                'Create',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Filter tabs
        Row(
          children: [
            _buildTeamFilterTab('My', _teamsFilter == 'My'),
            _buildTeamFilterTab('Opponents', _teamsFilter == 'Opponents'),
            _buildTeamFilterTab('Following', _teamsFilter == 'Following'),
          ],
        ),
        const SizedBox(height: 16),
        
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textSec, size: 20),
              const SizedBox(width: 12),
              Text(
                'Quick search',
                style: TextStyle(color: AppColors.textSec, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Team cards based on filter
        _buildTeamsList(),
      ],
    );
  }

  Widget _buildTeamsList() {
    if (_isLoadingTeams) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    List<TeamModel> filteredTeams = [];
    final user = ref.read(authStateProvider).user;
    
    if (_teamsFilter == 'My') {
      // Teams created by user
      filteredTeams = _allTeams.where((team) => team.createdBy == user?.id).toList();
    } else if (_teamsFilter == 'Opponents') {
      // Teams user has played against (simplified - get all other teams)
      filteredTeams = _allTeams.where((team) => team.createdBy != user?.id).toList();
    } else if (_teamsFilter == 'Following') {
      // For now, show all teams (you can add a following system later)
      filteredTeams = _allTeams;
    }
    
    // Convert TeamModel to the format expected by the UI
    final teams = filteredTeams.map((team) {
      return {
        'id': team.id,
        'name': team.name,
        'location': team.location ?? team.city ?? 'Location TBA',
        'captain': team.captainName ?? 'Captain TBA',
        'logo': team.logoUrl ?? (team.name.length >= 2 ? team.name.substring(0, 2) : team.name).toUpperCase(),
        'status': team.totalMatches != null && team.totalMatches! > 0 ? 'Active' : 'New',
        'matches': team.totalMatches != null ? '${team.totalMatches} matches' : '0 matches',
        'isFollowing': false, // You can add following logic later
      };
    }).toList();
    
    if (teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            _teamsFilter == 'My'
                ? 'No teams found. Create a team to get started!'
                : 'No teams found',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSec,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: teams.map((team) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              // Handle team card click
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening ${team['name']} details...'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: _buildTeamCardDetailed(
              name: team['name'] as String,
              location: team['location'] as String,
              captain: team['captain'] as String,
              logo: team['logo'] as String,
              status: team['status'] as String?,
              matches: team['matches'] as String?,
              isFollowing: team['isFollowing'] as bool? ?? false,
              onFollow: _teamsFilter == 'Following' ? () {
                setState(() {
                  team['isFollowing'] = !(team['isFollowing'] as bool? ?? false);
                });
              } : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final captainController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Create New Team',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF205A28),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: captainController,
                decoration: const InputDecoration(
                  labelText: 'Captain Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                // Create team in Supabase
                try {
                  final teamRepo = ref.read(teamRepositoryProvider);
                  final user = ref.read(authStateProvider).user;
                  
                  await teamRepo.createTeam({
                    'name': nameController.text,
                    'location': locationController.text.isNotEmpty
                        ? locationController.text
                        : 'Not specified',
                    'city': locationController.text.isNotEmpty
                        ? locationController.text
                        : 'Not specified',
                    'captain_name': captainController.text.isNotEmpty
                        ? captainController.text
                        : 'TBD',
                    'created_by': user?.id,
                  });
                  
                  // Reload teams
                  await _loadTeams();
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Team created successfully!'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF205A28),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create team: ${e.toString()}'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Team'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFilterTab(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _teamsFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface : AppColors.background,
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.textMain : AppColors.textSec,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCardDetailed({
    required String name,
    required String location,
    required String captain,
    required String logo,
    String? status,
    String? matches,
    bool isFollowing = false,
    VoidCallback? onFollow,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                logo,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.textSec),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSec,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      captain,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSec,
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'Playing' || status == 'Active'
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: status == 'Playing' || status == 'Active'
                                ? AppColors.primary
                                : AppColors.textSec,
                          ),
                        ),
                      ),
                    ],
                    if (matches != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        matches,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onFollow != null)
            IconButton(
              icon: Text(
                isFollowing ? '❤️' : '🤍',
                style: const TextStyle(fontSize: 24),
              ),
              onPressed: onFollow,
            )
          else
            IconButton(
              icon: const Icon(Icons.qr_code, color: Colors.grey),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Overall',
                    style: TextStyle(color: AppColors.textMain),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.compare_arrows, size: 16),
                  label: const Text('Compare'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMain,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Filter tabs
        Row(
          children: [
            _buildStatsFilterTab('Batting', _statsFilter == 'Batting'),
            _buildStatsFilterTab('Bowling', _statsFilter == 'Bowling'),
            _buildStatsFilterTab('Fielding', _statsFilter == 'Fielding'),
            _buildStatsFilterTab('Captain', _statsFilter == 'Captain'),
          ],
        ),
        const SizedBox(height: 24),
        
        // Stats Grid - Dynamic based on filter
        _buildStatsGrid(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    List<Map<String, dynamic>> stats = [];
    
    switch (_statsFilter) {
      case 'Batting':
        stats = [
          {'title': 'Matches', 'value': '25', 'icon': Icons.calendar_today, 'color': Colors.blue},
          {'title': 'Runs', 'value': '1,245', 'icon': Icons.trending_up, 'color': AppColors.primary},
          {'title': 'Average', 'value': '49.8', 'icon': Icons.bar_chart, 'color': Colors.orange},
          {'title': 'Strike Rate', 'value': '142.5', 'icon': Icons.speed, 'color': Colors.purple},
          {'title': '50s', 'value': '8', 'icon': Icons.star, 'color': Colors.red},
          {'title': '100s', 'value': '3', 'icon': Icons.emoji_events, 'color': Colors.amber},
        ];
        break;
      case 'Bowling':
        stats = [
          {'title': 'Matches', 'value': '20', 'icon': Icons.calendar_today, 'color': Colors.blue},
          {'title': 'Wickets', 'value': '42', 'icon': Icons.sports_cricket, 'color': AppColors.primary},
          {'title': 'Average', 'value': '18.5', 'icon': Icons.bar_chart, 'color': Colors.orange},
          {'title': 'Economy', 'value': '7.2', 'icon': Icons.speed, 'color': Colors.purple},
          {'title': 'Best', 'value': '5/25', 'icon': Icons.emoji_events, 'color': Colors.red},
          {'title': '4 Wickets', 'value': '3', 'icon': Icons.star, 'color': Colors.amber},
        ];
        break;
      case 'Fielding':
        stats = [
          {'title': 'Matches', 'value': '25', 'icon': Icons.calendar_today, 'color': Colors.blue},
          {'title': 'Catches', 'value': '18', 'icon': Icons.handshake, 'color': AppColors.primary},
          {'title': 'Stumpings', 'value': '5', 'icon': Icons.sports_handball, 'color': Colors.orange},
          {'title': 'Run Outs', 'value': '7', 'icon': Icons.running_with_errors, 'color': Colors.purple},
        ];
        break;
      case 'Captain':
        stats = [
          {'title': 'Matches', 'value': '15', 'icon': Icons.calendar_today, 'color': Colors.blue},
          {'title': 'Won', 'value': '10', 'icon': Icons.emoji_events, 'color': AppColors.primary},
          {'title': 'Lost', 'value': '4', 'icon': Icons.thumb_down, 'color': Colors.red},
          {'title': 'Win %', 'value': '66.7%', 'icon': Icons.trending_up, 'color': Colors.orange},
        ];
        break;
    }
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatBox(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
          imageUrl: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=200&h=200&fit=crop',
        );
      },
    );
  }

  Widget _buildStatsFilterTab(String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _statsFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.surface : AppColors.background,
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.textMain : AppColors.textSec,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Pure white - brighter than page background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider!),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
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
          ),
    );
  }

  Widget _buildBottomNavBar() {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isMyCricketActive = currentLocation == '/my-cricket' || 
                              currentLocation.startsWith('/my-cricket');
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.home, 
                'Home', 
                currentLocation == '/', 
                () => context.go('/'),
              ),
              _buildNavItem(
                Icons.sports_cricket, 
                'My Matches', 
                isMyCricketActive, 
                () => context.go('/my-cricket'),
              ),
              _buildNavItem(
                Icons.rss_feed, 
                'Feed', 
                currentLocation == '/feed', 
                () => context.go('/feed'),
              ),
              _buildNavItem(
                Icons.person, 
                'Profile', 
                currentLocation == '/profile', 
                () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textSec,
                size: 24,
              ),
              if (isActive)
                Positioned(
                  top: 4,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSec,
            ),
          ),
        ],
      ),
    );
  }
}
