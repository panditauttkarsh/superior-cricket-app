import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/tournament_model.dart';
import '../providers/tournament_providers.dart';
import 'teams_tab.dart';
import 'matches_tab.dart';
import 'points_table_tab.dart';
import 'leaderboard_tab.dart';
import 'stats_tab.dart';
import '../providers/tournament_providers.dart';
import '../../services/test_data_seeder.dart';

class TournamentHomePage extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentHomePage({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentHomePage> createState() => _TournamentHomePageState();
}

class _TournamentHomePageState extends ConsumerState<TournamentHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 1; // Teams tab is default

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tournamentAsync.when(
        data: (tournament) {
          if (tournament == null) {
            return const Center(child: Text('Tournament not found'));
          }
          return Column(
            children: [
              // Header Section
              _buildHeader(tournament),
              // Tabs
              _buildTabs(),
              // Tab Content
              Expanded(
                child: _buildTabContent(tournament),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHeader(TournamentModel tournament) {
    final startDate = tournament.startDate;
    final endDate = tournament.endDate;
    final endDateStr = endDate != null 
        ? ' to ${endDate.day} ${_getMonthName(endDate.month)}, ${endDate.year}' 
        : '';
    final dateRange = '${startDate.day} ${_getMonthName(startDate.month)}, ${startDate.year}$endDateStr';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary, // Fallback color
      ),
      child: Stack(
        children: [
          // Tournament Banner Background
          if (tournament.bannerUrl != null && tournament.bannerUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                tournament.bannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient if image fails
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            // Fallback to gradient if no banner
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          // Light overlay for text readability (brighter banner)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2), // Lighter at top (brighter)
                    Colors.black.withOpacity(0.35), // Lighter at bottom (brighter)
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.go('/'),
                      ),
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'edit') {
                            context.push('/create-tournament', extra: tournament);
                          } else if (value == 'seed_test_data') {
                            _seedIntoKPL(context, ref);
                          } else if (value == 'share') {
                            // Share tournament
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit Tournament Details'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'seed_test_data',
                            child: Row(
                              children: [
                                Icon(Icons.science, size: 20),
                                SizedBox(width: 8),
                                Text('Seed Test Data (KPL)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 20),
                                SizedBox(width: 8),
                                Text('Share'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tournament Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Logo
                      if (tournament.logoUrl != null)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              tournament.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.sports_cricket, color: AppColors.primary);
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.sports_cricket, color: AppColors.primary),
                        ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateRange,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Views count (placeholder)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '1 Views',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons - Only Go Live (centered)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Navigate to Go Live screen with tournament context
                                context.push(
                                  '/go-live',
                                  extra: {
                                    'matchId': tournament.id, // Using tournament ID as context
                                    'matchTitle': tournament.name,
                                    'isDraft': false,
                                  },
                                );
                              },
                              icon: const Icon(Icons.play_arrow, color: Colors.white),
                              label: const Text('Go Live', style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Show Help Dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Tournament Help'),
                                    content: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('• Use "Go Live" to stream matches for this tournament.'),
                                        SizedBox(height: 8),
                                        Text('• Check "Matches" tab for schedule.'),
                                        SizedBox(height: 8),
                                        Text('• "Teams" tab shows all participating squads.'),
                                        SizedBox(height: 8),
                                        Text('• Detailed stats are available in "Stats" tab.'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.help_outline),
                              label: const Text('Help'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 4),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSec,
        indicatorColor: AppColors.primary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: const [
          Tab(text: 'Matches'),
          Tab(text: 'Teams'),
          Tab(text: 'Points Table'),
          Tab(text: 'Leaderboard'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildTabContent(TournamentModel tournament) {
    switch (_selectedTab) {
      case 0:
        return MatchesTab(
          tournamentId: tournament.id,
          tournament: tournament,
        );
      case 1:
        return TeamsTab(tournamentId: tournament.id);
      case 2:
        return PointsTableTab(tournamentId: tournament.id);
      case 3:
        return LeaderboardTab(tournamentId: tournament.id);
      case 4:
        return StatsTab(tournamentId: tournament.id);
      default:
        return TeamsTab(tournamentId: tournament.id);
    }
  }

  Future<void> _seedIntoKPL(BuildContext context, WidgetRef ref) async {
    final seeder = TournamentTestDataSeeder();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final tournamentId = await seeder.seedIntoExistingTournament(ref, 'KPL');
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test data seeded successfully into KPL! Check the Points Table tab.'),
            duration: Duration(seconds: 4),
          ),
        );
        
        // Refresh the current page
        setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to seed test data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
