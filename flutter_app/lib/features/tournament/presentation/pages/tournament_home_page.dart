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
    final dateRange = '${startDate.day} ${_getMonthName(startDate.month)}, ${startDate.year} to ${endDate.day} ${_getMonthName(endDate.month)}, ${endDate.year}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
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
                    onPressed: () => context.pop(),
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
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      // Share tournament
                    },
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
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Go Live
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
                        // Steps/Help
                      },
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Steps/help'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSec,
        indicatorColor: AppColors.primary,
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
        return MatchesTab(tournamentId: tournament.id);
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

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

