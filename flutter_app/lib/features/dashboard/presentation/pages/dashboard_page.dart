import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/tournament_model.dart';
import '../../../mycricket/presentation/widgets/enhanced_create_match_dialog.dart';
import '../widgets/notifications_dialog.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String _activeNav = 'home';
  List<MatchModel> _liveMatches = [];
  List<TournamentModel> _featuredTournaments = [];
  bool _isLoadingMatches = true;
  bool _isLoadingTournaments = true;

  @override
  void initState() {
    super.initState();
    // Load data after first build when ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadLiveMatches(),
      _loadFeaturedTournaments(),
    ]);
  }

  Future<void> _loadLiveMatches() async {
    try {
      final matchRepo = ref.read(matchRepositoryProvider);
      final matches = await matchRepo.getMatches(
        status: 'live',
        limit: 5,
      );
      if (mounted) {
        setState(() {
          _liveMatches = matches;
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

  Future<void> _loadFeaturedTournaments() async {
    try {
      final tournamentRepo = ref.read(tournamentRepositoryProvider);
      final tournaments = await tournamentRepo.getTournaments(
        status: 'registration_open',
        limit: 3,
      );
      if (mounted) {
        setState(() {
          _featuredTournaments = tournaments;
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

  String _getCapitalizedName(String? email) {
    if (email == null || email.isEmpty) return 'User';
    final userName = email.split('@')[0];
    if (userName.isEmpty) return 'User';
    return userName[0].toUpperCase() + userName.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final capitalizedName = _getCapitalizedName(user?.email);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          
                          // Header
                          _buildHeader(capitalizedName),
                          
                          const SizedBox(height: 30),
                          
                          // Live Matches Section
                          _buildLiveMatchesSection(),
                          
                          const SizedBox(height: 30),
                          
                          // Quick Actions Section
                          _buildQuickActionsSection(),
                          
                          const SizedBox(height: 30),
                          
                          // Featured Tournaments Section
                          _buildFeaturedTournamentsSection(),
                          
                          const SizedBox(height: 100), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom Navigation
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Hamburger Menu - closer to left
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textMain),
            onPressed: () => _showHamburgerMenu(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        const SizedBox(width: 8),
        // Avatar only (no greeting text)
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.network(
              'https://api.dicebear.com/7.x/avataaars/svg?seed=$userName&backgroundColor=ffd5dc',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.person, color: AppColors.textMain),
                );
              },
            ),
          ),
        ),
        const Spacer(),
        // Notification Button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 24,
            ),
            onPressed: () => _showNotificationsDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Live Matches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/match-center'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoadingMatches
            ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            : _liveMatches.isEmpty
                ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No live matches',
                        style: TextStyle(
                          color: AppColors.textSec,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 20),
                      children: _liveMatches.map((match) {
                        final scorecard = match.scorecard ?? {};
                        final team1Score = scorecard['team1_score'] ?? {};
                        final team2Score = scorecard['team2_score'] ?? {};
                        final team1Runs = team1Score['runs'] ?? 0;
                        final team1Wickets = team1Score['wickets'] ?? 0;
                        final team1Overs = team1Score['overs'] ?? 0.0;
                        final team2Runs = team2Score['runs'] ?? 0;
                        final team2Wickets = team2Score['wickets'] ?? 0;
                        final team2Overs = team2Score['overs'] ?? 0.0;
                        
                        // Determine which team is batting (simplified logic)
                        final isTeam1Batting = team1Overs < team2Overs || 
                                             (team1Overs == team2Overs && team1Runs < team2Runs);
                        final battingScore = isTeam1Batting ? team1Score : team2Score;
                        final battingRuns = battingScore['runs'] ?? 0;
                        final battingWickets = battingScore['wickets'] ?? 0;
                        final battingOvers = battingScore['overs'] ?? 0.0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => context.go('/matches/${match.id}'),
                            child: _buildLiveMatchCard(
                              team1: match.team1Name ?? 'Team 1',
                              team2: match.team2Name ?? 'Team 2',
                              score: '$battingRuns/$battingWickets',
                              overs: '${battingOvers.toStringAsFixed(1)} Ov',
                              status: 'Live',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
      ],
    );
  }

  Widget _buildLiveMatchCard({
    String team1 = 'IND',
    String team2 = 'AUS',
    String score = '142/3',
    String overs = '18.2 Ov',
    String status = 'India need 24 runs in 10 balls',
  }) {
    // Night cricket stadium banner image
    const bannerImagePath = 'assets/images/night cricket.webp';
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Night Cricket Stadium Background Banner
            Positioned.fill(
              child: Image.asset(
                bannerImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient if image not found
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1a4d2e), // Dark green like cricket field
                          Color(0xFF0d2818), // Darker green
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Dark gradient overlay for text readability
            // Top opacity ~0.35, Bottom opacity ~0.75
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Match Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Live Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.urgent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
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
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'T20 World Cup',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Match Content
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Team 1
                      Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.textMain.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Text(_getFlagEmoji(team1), style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            team1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            overs,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF00D26A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Team 2
                      Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.textMain.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Text(_getFlagEmoji(team2), style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            team2,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Match Status
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
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

  String _getFlagEmoji(String team) {
    final flags = {
      'IND': '🇮🇳',
      'AUS': '🇦🇺',
      'ENG': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'NZ': '🇳🇿',
      'PAK': '🇵🇰',
      'SA': '🇿🇦',
    };
    return flags[team] ?? '🏏';
  }

  Widget _buildUpcomingMatchCard() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.background,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A3D30),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'UPCOMING',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              const Text(
                'CSK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CSK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionItem(
                customIcon: _buildStatsIcon(),
                label: 'My Stats',
                onTap: () => context.go('/my-cricket?tab=Stats'),
              ),
              _buildActionItem(
                customIcon: _buildTrophyIcon(),
                label: 'Tournaments',
                onTap: () => context.go('/my-cricket?tab=Tournaments'),
              ),
              _buildActionItem(
                customIcon: _buildAcademyIcon(),
                label: 'Academy',
                onTap: () => context.go('/academy'),
              ),
              _buildActionItem(
                customIcon: Icon(
                  Icons.shopping_bag,
                  color: AppColors.primary,
                  size: 24,
                ),
                label: 'Store',
                onTap: () => context.go('/shop'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    Widget? customIcon,
    IconData? icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.divider,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: customIcon ?? (icon != null
                  ? Icon(
                      icon,
                      color: AppColors.primary,
                      size: 24,
                    )
                  : const SizedBox()),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSec,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTournamentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Featured Tournaments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        const SizedBox(height: 16),
        _isLoadingTournaments
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            : _featuredTournaments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No featured tournaments',
                        style: TextStyle(
                          color: AppColors.textSec,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: _featuredTournaments.map((tournament) {
                      final statusText = tournament.status == 'registration_open'
                          ? 'REGISTRATION OPEN'
                          : tournament.status == 'ongoing'
                              ? 'ONGOING'
                              : 'COMPLETED';
                      final statusColor = tournament.status == 'registration_open'
                          ? AppColors.primary
                          : tournament.status == 'ongoing'
                              ? AppColors.urgent
                              : AppColors.textSec;
                      
                      final startDate = tournament.startDate;
                      final formattedDate = '${startDate.day} ${_getMonthName(startDate.month)}';
                      final prizePoolText = tournament.prizePool != null
                          ? '₹${tournament.prizePool!.toStringAsFixed(0)} Prize Pool'
                          : 'Prize Pool TBA';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTournamentCard(
                          imageUrl: tournament.imageUrl ?? '',
                          status: statusText,
                          statusColor: statusColor,
                          teams: tournament.registeredTeams ?? tournament.totalTeams ?? 0,
                          title: tournament.name,
                          startDate: formattedDate,
                          prizePool: prizePoolText,
                          onTap: () => context.go('/tournaments/${tournament.id}'),
                        ),
                      );
                    }).toList(),
                  ),
        ],
      ),
    );
  }

  // Custom Stats Icon - Professional color-coded bar chart
  Widget _buildStatsIcon() {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
          painter: StatsBarPainter(),
        ),
      ),
    );
  }

  // Custom Trophy Icon - Yellow colored
  Widget _buildTrophyIcon() {
    return Icon(
      Icons.emoji_events,
      color: Colors.amber.shade700,
      size: 24,
    );
  }

  // Custom Academy Icon - Ground with flood lights
  Widget _buildAcademyIcon() {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
          painter: AcademyGroundPainter(),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildTournamentCard({
    required String imageUrl,
    required String status,
    required Color statusColor,
    required int teams,
    required String title,
    required String startDate,
    required String prizePool,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => context.go('/my-cricket?tab=Tournaments'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Tournament Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                ),
              ),
              child: imageUrl.isEmpty
                  ? Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.image, color: Colors.white),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            // Tournament Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $teams Teams',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMeta,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Starts $startDate • $prizePool',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSec,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow Button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.divider.withOpacity(0.5),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.textSec,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 'home'),
          _buildNavItem(Icons.sports_cricket, 'My Cricket', 'my-matches'),
          // Center Plus Button
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  AppShadows.glow,
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.push('/create-match');
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.textMain,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          _buildNavItem(Icons.rss_feed, 'Feed', 'feed'),
          _buildNavItem(Icons.person, 'Profile', 'profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String navKey) {
    final isActive = _activeNav == navKey;
    return GestureDetector(
      onTap: () {
        setState(() => _activeNav = navKey);
        switch (navKey) {
          case 'home':
            context.go('/');
            break;
          case 'my-matches':
            context.go('/my-cricket');
            break;
          case 'feed':
            context.go('/feed');
            break;
          case 'profile':
            context.go('/profile');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textSec,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSec,
            ),
          ),
        ],
      ),
    );
  }

  void _showHamburgerMenu(BuildContext context) {
    final user = ref.read(authStateProvider).user;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with back arrow and title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Profile Picture - Centered
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://api.dicebear.com/7.x/avataaars/svg?seed=${user?.email ?? 'User'}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.surface,
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.textSec,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Camera icon overlay - top right
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    user?.name ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Menu Items in Sections
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PROFILE Section
                          _buildSectionLabel('PROFILE'),
                          const SizedBox(height: 12),
                          _buildMenuTile(
                            icon: Icons.person_outline,
                            title: 'Account details',
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/profile');
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.emoji_events_outlined,
                            title: 'Tournaments',
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/my-cricket?tab=Tournaments');
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.sports_cricket_outlined,
                            title: 'My Cricket',
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/my-cricket');
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Store',
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/shop');
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.school_outlined,
                            title: 'Academy',
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/academy');
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // NOTIFICATIONS Section
                          _buildSectionLabel('NOTIFICATIONS'),
                          const SizedBox(height: 12),
                          _buildMenuTileWithToggle(
                            icon: Icons.bar_chart_outlined,
                            title: 'Activities notifications',
                            subtitle: 'Payment Success, Failed and other activities',
                            value: true,
                            onChanged: (value) {},
                          ),
                          _buildMenuTileWithToggle(
                            icon: Icons.email_outlined,
                            title: 'Email notification',
                            value: false,
                            onChanged: (value) {},
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Settings
                          _buildMenuTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            onTap: () {
                              Navigator.pop(context);
                              context.go('/settings');
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          _buildMenuTile(
                            icon: Icons.logout,
                            title: 'Logout',
                            onTap: () {
                              Navigator.pop(context);
                              ref.read(authStateProvider.notifier).logout();
                              context.go('/login');
                            },
                            color: AppColors.urgent,
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSec,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.primary;
    final textColor = color ?? AppColors.textMain;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSec,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTileWithToggle({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSec,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationsDialog(),
    );
  }

  void _showStartMatchPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Start a New Match',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        content: const Text(
          'Would you like to create a new match?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => const EnhancedCreateMatchDialog(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Match'),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Professional Color-Coded Stats Bar
class StatsBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw 4 bars with different colors (professional color coding)
    final barWidth = size.width / 5;
    final spacing = barWidth / 4;
    
    // Bar 1 - Blue (highest)
    paint.color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.2, barWidth, size.height * 0.8),
        const Radius.circular(2),
      ),
      paint,
    );
    
    // Bar 2 - Green
    paint.color = Colors.green.shade600;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barWidth + spacing, size.height * 0.4, barWidth, size.height * 0.6),
        const Radius.circular(2),
      ),
      paint,
    );
    
    // Bar 3 - Orange
    paint.color = Colors.orange.shade600;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((barWidth + spacing) * 2, size.height * 0.5, barWidth, size.height * 0.5),
        const Radius.circular(2),
      ),
      paint,
    );
    
    // Bar 4 - Red (lowest)
    paint.color = Colors.red.shade600;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH((barWidth + spacing) * 3, size.height * 0.7, barWidth, size.height * 0.3),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Academy Ground with Flood Lights
class AcademyGroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.green.shade700;
    
    // Draw ground (oval/cricket field)
    paint.color = Colors.green.shade500;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.5),
      paint,
    );
    
    // Draw ground outline
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.5),
      strokePaint,
    );
    
    // Draw center circle
    strokePaint.color = Colors.white;
    strokePaint.strokeWidth = 1;
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.55),
      size.width * 0.15,
      strokePaint,
    );
    
    // Draw flood lights (4 lights at corners)
    paint.color = Colors.amber.shade300;
    final lightSize = size.width * 0.08;
    
    // Top left light
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.15), lightSize, paint);
    // Top right light
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.15), lightSize, paint);
    // Bottom left light
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.85), lightSize, paint);
    // Bottom right light
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.85), lightSize, paint);
    
    // Draw light beams (yellow glow)
    paint.color = Colors.amber.shade100.withOpacity(0.3);
    paint.style = PaintingStyle.fill;
    
    // Light beam from top left
    final path1 = Path()
      ..moveTo(size.width * 0.05, size.height * 0.15)
      ..lineTo(size.width * 0.2, size.height * 0.35)
      ..lineTo(size.width * 0.1, size.height * 0.4)
      ..close();
    canvas.drawPath(path1, paint);
    
    // Light beam from top right
    final path2 = Path()
      ..moveTo(size.width * 0.95, size.height * 0.15)
      ..lineTo(size.width * 0.8, size.height * 0.35)
      ..lineTo(size.width * 0.9, size.height * 0.4)
      ..close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
