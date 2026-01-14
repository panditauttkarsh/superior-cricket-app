import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/tournament_model.dart';
import '../../../mycricket/presentation/widgets/enhanced_create_match_dialog.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../widgets/notifications_dialog.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../../core/providers/theme_provider.dart';
import '../widgets/player_profile_popup.dart';

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
  
  late PageController _tournamentPageController;
  double _tournamentCurrentPage = 0.0;
  Timer? _autoSwipeTimer;
  
  // Notification toggle states
  bool _activitiesNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _tournamentPageController = PageController(viewportFraction: 0.88);
    _tournamentPageController.addListener(() {
      if (mounted) {
        setState(() {
          _tournamentCurrentPage = _tournamentPageController.page ?? 0.0;
        });
      }
    });

    // Load data after first build when ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_featuredTournaments.isEmpty) return;
      
      final nextPage = (_tournamentPageController.page?.toInt() ?? 0) + 1;
      if (nextPage >= _featuredTournaments.length) {
        _tournamentPageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _tournamentPageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _tournamentPageController.dispose();
    _autoSwipeTimer?.cancel();
    super.dispose();
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
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      
      // Get matches: live matches + matches user is part of (upcoming/live/completed)
      List<MatchModel> allMatches = [];
      
      // 1. Get all live matches (visible to everyone)
      final liveMatches = await matchRepo.getMatches(
        status: 'live',
        limit: 10,
      );
      allMatches.addAll(liveMatches);
      
      // 2. If user is logged in, get matches they're part of (from match_players)
      if (userId != null) {
        final playerMatches = await matchRepo.getPlayerMatches(userId);
        // Add matches that aren't already in the list
        for (var match in playerMatches) {
          if (!allMatches.any((m) => m.id == match.id)) {
            allMatches.add(match);
          }
        }
        
        // 3. Also get matches created by user or where user's team is involved
        final userMatches = await matchRepo.getMatches(
          userId: userId,
          includePlayerMatches: true,
          limit: 10,
        );
        for (var match in userMatches) {
          if (!allMatches.any((m) => m.id == match.id)) {
            allMatches.add(match);
          }
        }
      }
      
      // Sort by created_at (newest first) and limit to 5
      allMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (allMatches.length > 5) {
        allMatches = allMatches.take(5).toList();
      }
      
      if (mounted) {
        setState(() {
          _liveMatches = allMatches;
          _isLoadingMatches = false;
        });
      }
    } catch (e) {
      print('Error loading matches: $e');
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
      // Fetch more tournaments initially to allow for filtering
      final allTournaments = await tournamentRepo.getTournaments(
        status: 'registration_open',
        limit: 10,
      );

      // Filter out KPL (but keep KCPL)
      final filteredTournaments = allTournaments.where((t) {
        final name = t.name.toUpperCase();
        if (name.contains('KCPL')) return true; // Explicitly allow KCPL
        return !name.contains('KPL');
      }).toList();

      TournamentModel? kcplTournament;
      TournamentModel? splTournament;
      TournamentModel? splS4Tournament;
      final otherTournaments = <TournamentModel>[];

      for (var t in filteredTournaments) {
        final name = t.name.toUpperCase();
        if (name.contains('KCPL')) {
          kcplTournament = t;
        } else if (name.contains('SPL S-4')) {
          splS4Tournament = t;
        } else if (name == 'SPL' || (name.contains('SPL') && !name.contains('S-4'))) {
          splTournament = t;
        } else {
          otherTournaments.add(t);
        }
      }

      final finalTournaments = <TournamentModel>[];
      if (kcplTournament != null) finalTournaments.add(kcplTournament);
      if (splTournament != null) finalTournaments.add(splTournament);
      if (splS4Tournament != null) finalTournaments.add(splS4Tournament);
      finalTournaments.addAll(otherTournaments);

      // Take top 3
      final displayTournaments = finalTournaments.take(3).toList();

      if (mounted) {
        setState(() {
          _featuredTournaments = displayTournaments;
          if (_featuredTournaments.isEmpty) {
            // Fallback data if no real tournaments matched
             _featuredTournaments = [
              TournamentModel(
                id: 'kcpl_0',
                name: 'KCPL',
                startDate: DateTime.now().add(const Duration(days: 1)),
                status: 'registration_open',
                imageUrl: 'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&q=80',
                prizePool: 75000,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              TournamentModel(
                id: '0',
                name: 'SPL', 
                startDate: DateTime.now().add(const Duration(days: 2)),
                status: 'registration_open',
                imageUrl: 'https://images.unsplash.com/photo-1624526267942-ab0ff8a3e972?w=800&q=80',
                prizePool: 100000,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              TournamentModel(
                id: '1',
                name: 'SPL S-4', 
                startDate: DateTime.now().add(const Duration(days: 3)),
                status: 'registration_open',
                imageUrl: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&q=80',
                prizePool: 50000,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ];
          }
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

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  
                  const SizedBox(height: 30),
                  
                  // Pro Membership Section
                  _buildProMembershipSection(),
                  
                  const SizedBox(height: 130), // Increased space to ensure content clears floating footer
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    final user = ref.read(authStateProvider).user;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - Hamburger Menu and Avatar shifted to touch edge
        Transform.translate(
          offset: const Offset(-20, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.textMain),
                onPressed: () => _showHamburgerMenu(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
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
                    user?.avatar ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=$userName&backgroundColor=ffd5dc',
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
            ],
          ),
        ),
        const Spacer(),
        // Notification Button with Badge
        Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authStateProvider);
            final userId = authState.user?.id;
            
            if (userId == null) {
              return Container(
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
                  onPressed: () => context.push('/notifications'),
                ),
              );
            }
            
            // Use the unread count provider from notifications page
            final unreadCountAsync = ref.watch(unreadCountProvider(userId));
            final unreadCount = unreadCountAsync.value ?? 0;
            
            return Stack(
              children: [
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
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
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
            Text(
              'My Matches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color ?? AppColors.textMain,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/my-cricket?tab=Matches'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: Colors.white,
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
                        'No matches yet',
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
                      children: _liveMatches.asMap().entries.map((entry) {
                        final index = entry.key;
                        final match = entry.value;
                        final scorecard = match.scorecard ?? {};
                        final team1Score = scorecard['team1_score'] ?? {};
                        final team2Score = scorecard['team2_score'] ?? {};
                        
                        // Extract raw values
                        final t1Runs = (team1Score['runs'] as num?)?.toInt() ?? 0;
                        final t1Wickets = (team1Score['wickets'] as num?)?.toInt() ?? 0;
                        final t1Overs = (team1Score['overs'] as num?)?.toDouble() ?? 0.0;
                        
                        final t2Runs = (team2Score['runs'] as num?)?.toInt() ?? 0;
                        final t2Wickets = (team2Score['wickets'] as num?)?.toInt() ?? 0;
                        final t2Overs = (team2Score['overs'] as num?)?.toDouble() ?? 0.0;

                        // Format strings
                        final team1ScoreStr = '$t1Runs/$t1Wickets';
                        final team1OversStr = '${t1Overs.toStringAsFixed(1)} Ov';
                        
                        final team2ScoreStr = '$t2Runs/$t2Wickets';
                        final team2OversStr = '${t2Overs.toStringAsFixed(1)} Ov';
                        
                        String statusText = match.status == 'live' ? 'Live' : 
                                          match.status == 'upcoming' ? 'Upcoming' : 
                                          match.status == 'completed' ? 'Completed' : 'Match';
                                          
                        // Calculate Result logic if completed
                        if (match.status == 'completed' && match.winnerId != null) {
                           if (match.winnerId == match.team1Id) {
                             final runsDiff = t1Runs - t2Runs;
                             final wicketsDiff = 10 - t1Wickets; // Assuming 10 wickets roughly, but usually calculated from chasing team logic
                             // Simplified result text based solely on runs for batting first or wickets if chasing. 
                             // Since we don't have accurate 'who batted first' easily here without parsing logic:
                             // We will just use generic "Won" text or run diff if huge
                             // Better: Reuse standard logic.
                             if (runsDiff > 0) {
                               statusText = '${match.team1Name ?? "Team 1"} won by $runsDiff runs';
                             } else {
                               statusText = '${match.team1Name ?? "Team 1"} won';
                             }
                           } else {
                             final runsDiff = t2Runs - t1Runs;
                             if (runsDiff > 0) {
                               statusText = '${match.team2Name ?? "Team 2"} won by $runsDiff runs';
                             } else {
                               statusText = '${match.team2Name ?? "Team 2"} won'; 
                             }
                           }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => context.go('/matches/${match.id}'),
                            child: _buildLiveMatchCard(
                              team1: match.team1Name ?? 'Team 1',
                              team2: match.team2Name ?? 'Team 2',
                              team1Score: team1ScoreStr,
                              team1Overs: team1OversStr,
                              team2Score: team2ScoreStr,
                              team2Overs: team2OversStr,
                              status: statusText,
                              matchStatus: match.status,
                              index: index,
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
    required String team1,
    required String team2,
    required String team1Score,
    required String team1Overs,
    required String team2Score,
    required String team2Overs,
    required String status,
    required String matchStatus,
    int index = 0,
  }) {
    // List of available stadium/cricket background images
    final backgroundImages = [
      'assets/images/DD66A1F5-EBCD-4452-9B72-7E3F5E0C7CA9.jpeg',
      'assets/images/CA1BF7B6-0C33-4D59-AEC3-5518ACCB1354.png',
      'assets/images/86AC2243-B5A7-413E-84A3-634401C99C23_4_5005_c.jpeg',
    ];
    
    final imageIndex = index % backgroundImages.length;
    final bannerImagePath = backgroundImages[imageIndex];
    final isLive = matchStatus.toLowerCase() == 'live';
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                bannerImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1a4d2e),
                          Color(0xFF0d2818), 
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Overlay
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
                  // Header (Badge + Title)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive ? AppColors.urgent.withOpacity(0.9) : Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLive) ...[ 
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              // Show winning team name for completed matches, otherwise show status
                              matchStatus.toLowerCase() == 'completed' && status.contains('won') 
                                ? status.split(' won')[0] // Extract team name before "won"
                                : matchStatus.toUpperCase(),
                              style: const TextStyle(
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
                          'T20 Match',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Teams and Scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Team 1
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Text(
                              team1Score,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                           Text(
                            team1Overs,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
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
                      
                      // VS Center
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      // Team 2
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Text(
                              team2Score,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                           Text(
                            team2Overs,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
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
                  
                  const Spacer(),
                  
                  // Bottom Status Bar
                  Container(
                    width: double.infinity,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        color: Theme.of(context).cardTheme.color,
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
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.primary,
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
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
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
                      color: Colors.white,
                      size: 24,
                    )
                  : const SizedBox()),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Featured Tournaments',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingTournaments
            ? const SizedBox(
                height: 260,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            : _featuredTournaments.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'No featured tournaments',
                        style: TextStyle(
                          color: AppColors.textSec,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : Container(
                    height: 240, // Reduced height (from 290)
                    child: PageView.builder(
                      controller: _tournamentPageController,
                      itemCount: _featuredTournaments.length,
                      clipBehavior: Clip.none,
                      itemBuilder: (context, index) {
                        final tournament = _featuredTournaments[index];
                        final now = DateTime.now();
                        
                        // Scaling logic
                        double scale = 1.0;
                        double diff = index - _tournamentCurrentPage;
                        scale = 1.0 - (diff.abs() * 0.15).clamp(0.0, 1.0);
                        
                        // Status logic
                        String statusText;
                        Color statusColor;
                        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                        
                        if (tournament.status == 'ongoing') {
                          statusText = 'ONGOING';
                          statusColor = AppColors.urgent;
                        } else if (tournament.status == 'completed') {
                          statusText = 'COMPLETED';
                          statusColor = isDarkMode ? Colors.white : AppColors.textSec;
                        } else {
                          if (tournament.endDate != null && now.isAfter(tournament.endDate!)) {
                            statusText = 'ENDED';
                            statusColor = isDarkMode ? Colors.white : AppColors.textSec;
                          } else if (now.isBefore(tournament.startDate)) {
                            statusText = 'REGISTRATION OPEN';
                            statusColor = AppColors.primary;
                          } else {
                            statusText = 'REGISTRATION CLOSED';
                            statusColor = AppColors.error; 
                          }
                        }
                        
                        final startDate = tournament.startDate;
                        final formattedDate = '${startDate.day} ${_getMonthName(startDate.month)} ${startDate.year}';
                        
                        final prizePoolText = tournament.prizePool != null
                            ? '₹${tournament.prizePool!.toStringAsFixed(0)}'
                            : 'TBA';

                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: scale.clamp(0.6, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(6, 0, 6, 20), // Reduced bottom padding, tighter horizontal
                              child: _buildTournamentCard(
                                imageUrl: tournament.bannerUrl ?? tournament.imageUrl ?? '',
                                status: statusText,
                                statusColor: statusColor,
                                teams: tournament.registeredTeams ?? tournament.totalTeams ?? 0,
                                title: tournament.name,
                                startDate: formattedDate,
                                prizePool: prizePoolText,
                                onTap: () => context.go('/tournament/${tournament.id}'),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildProMembershipSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
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
            'Pro Membership',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1221),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Tech Lines Background
                Positioned.fill(
                  child: CustomPaint(
                    painter: TechLinesPainter(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Left Content: Icon + Text
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium,
                                    color: Color(0xFFFFD700),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'UNLOCK YOUR POTENTIAL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Right Content: Button + Feature text
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Buy Now Button
                                InkWell(
                                  onTap: () => context.go('/pro'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'BUY NOW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.call_made, color: Color(0xFFFFD700), size: 12),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Bottom Feature text
                                Text(
                                  'Ad-Free. Priority Support.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'GO PRO TODAY. UNLIMITED ACCESS.',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
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
    const String defaultCricketImage = 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&q=80';
    
    return GestureDetector(
      onTap: onTap ?? () => context.go('/my-cricket?tab=Tournaments'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6, // Increased Image flex for taller visual
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl.trim().isNotEmpty ? imageUrl : defaultCricketImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.network(
                        defaultCricketImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Lighter white fading effect starting later
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.4),
                              Colors.white,
                            ],
                            stops: const [0.82, 0.94, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Teams Count
                    if (teams > 0)
                      Positioned(
                        bottom: 10,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$teams Teams',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Tournament Info Footer - Reduced Padding and Improved Typography
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain,
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'START DATE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: AppColors.textSec.withOpacity(0.8),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  startDate,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'PRIZE POOL',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.textSec.withOpacity(0.8),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                prizePool,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
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
        ),
      ),
    );
  }

  Future<void> _handleProfileImageUpdate(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    
    // Show dialog to choose source
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    
    if (source == null) return;
    
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return;
      
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile picture...')),
        );
      }
      
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      
      if (userId == null) return;
      
      final imageFile = File(pickedFile.path);
      final repo = ref.read(profileRepositoryProvider);
      
      // Upload execution
      final imageUrl = await repo.uploadProfileImage(userId, imageFile);
      await repo.updateProfileImage(userId, imageUrl);
      
      // Refresh Auth State to reflect changes
      await ref.read(authStateProvider.notifier).refreshAuth();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
        
        // Close the hamburger menu to refresh the view (as it uses local state from when it was built)
        // Or trigger a rebuild. Since we refreshed auth state, closing and reopening is cleanest for UX.
        Navigator.pop(context); 
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    }
  }

  void _showHamburgerMenu(BuildContext context) {
    final user = ref.read(authStateProvider).user;
    // Local state for toggles inside the dialog
    bool activitiesNotifications = _activitiesNotifications;
    bool emailNotifications = _emailNotifications;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
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
                          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Menu Items in Sections - Now includes profile header
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fine-tuned Profile Section
                          Container(
                            color: Colors.grey[100],
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                showPlayerProfilePopup(context);
                              },
                              child: Row(
                                children: [
                                  // Profile Image with Camera Icon Overlay
                                  Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.network(
                                            user?.avatar ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${user?.email ?? 'User'}',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: AppColors.surface,
                                              child: const Icon(Icons.person, size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E88E5), // Brighter blue like the image
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
                                  const SizedBox(width: 16),
                                  // User Details & Badge
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (user?.name ?? 'UTTKARSH PANDITA').toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF263238),
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user?.email ?? 'uttkarshpandita@gmail.com',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueGrey[400],
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Compact Orange Pill Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'BASIC MEMBER',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Circular Shadowed Arrow with Teal Border
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF009688).withOpacity(0.4), // Teal-ish border
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF90A4AE),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Menu Items
                          Padding(
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
                            icon: Icons.notifications_active_outlined,
                            title: 'Activities',
                            subtitle: 'Payment, tournaments & matches',
                            value: activitiesNotifications,
                            onChanged: (value) {
                              setDialogState(() {
                                activitiesNotifications = value;
                              });
                              setState(() {
                                _activitiesNotifications = value;
                              });
                            },
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final isDarkMode = ref.watch(isDarkModeProvider);
                                return _buildMenuTileWithToggle(
                                  icon: Icons.dark_mode_outlined,
                                  title: 'Dark Mode',
                                  value: isDarkMode,
                                  onChanged: (value) {
                                    ref.read(isDarkModeProvider.notifier).state = value;
                                  },
                                );
                            },
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
                            icon: Icons.logout_rounded,
                            title: 'Logout',
                            onTap: () {
                              Navigator.pop(context);
                              ref.read(authStateProvider.notifier).logout();
                              context.go('/login');
                            },
                            color: Colors.redAccent,
                          ),
                          
                          const SizedBox(height: 32),
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
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.white;
    final textColor = color ?? Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textMain;
    
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
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.white;
    
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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

// Custom Painter for Tech/Circuitry background lines
class TechLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final goldPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Top patterns
    for (var i = 0; i < 4; i++) {
      path.reset();
      double y = size.height * (0.1 + i * 0.15);
      path.moveTo(0, y);
      path.lineTo(size.width * 0.2, y);
      path.lineTo(size.width * 0.25, y - 20);
      path.lineTo(size.width * 0.5, y - 20);
      canvas.drawPath(path, i % 2 == 0 ? paint : goldPaint);
    }

    // Bottom patterns
    for (var i = 0; i < 4; i++) {
      path.reset();
      double y = size.height * (0.9 - i * 0.15);
      path.moveTo(size.width, y);
      path.lineTo(size.width * 0.8, y);
      path.lineTo(size.width * 0.75, y + 20);
      path.lineTo(size.width * 0.4, y + 20);
      canvas.drawPath(path, i % 2 != 0 ? paint : goldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
