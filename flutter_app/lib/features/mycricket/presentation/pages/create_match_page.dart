import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class CreateMatchPage extends ConsumerStatefulWidget {
  final String? tournamentId;

  const CreateMatchPage({super.key, this.tournamentId});

  @override
  ConsumerState<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends ConsumerState<CreateMatchPage> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _myTeamController = TextEditingController();
  final TextEditingController _opponentTeamController = TextEditingController();
  final TextEditingController _youtubeVideoIdController = TextEditingController();
  String? _overs;
  String? _groundType;
  String? _ballType;
  double _tossPrice = 0.0;
  String? _tossWinner;
  String? _tossChoice;
  bool _showYouTubeInput = false;
  bool _youtubeLiveEnabled = false;
  String? _youtubeVideoId;
  
  List<String> _myTeamPlayers = [];
  List<String> _opponentTeamPlayers = [];
  // Store full player data for match_players table
  List<Map<String, dynamic>> _myTeamPlayersData = [];
  List<Map<String, dynamic>> _opponentTeamPlayersData = [];

  // Tournament specific fields
  List<String> _tournamentTeamNames = [];
  bool _isLoadingTournamentTeams = false;
  String? _selectedMyTeam;
  String? _selectedOpponentTeam;

  @override
  void initState() {
    super.initState();
    // Set default values
    _overs = '20'; // Default to 20 overs
    _groundType = 'Turf'; // Default to Turf
    _ballType = 'Leather'; // Default to Leather
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();

    // Load tournament teams if tournamentId is present
    if (widget.tournamentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTournamentTeams();
      });
    }
  }

  Future<void> _loadTournamentTeams() async {
    setState(() {
      _isLoadingTournamentTeams = true;
    });

    try {
      final teamRepo = ref.read(tournamentTeamRepositoryProvider);
      final tournamentTeams = await teamRepo.getTournamentTeams(widget.tournamentId!);
      
      if (mounted) {
        setState(() {
          _tournamentTeamNames = tournamentTeams.map((t) => t.teamName).toList();
          _isLoadingTournamentTeams = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTournamentTeams = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tournament teams: $e')),
        );
      }
    }
  }

  final List<String> _oversOptions = ['5', '10', '15', '20', '25', '50'];
  final List<String> _groundTypes = ['Turf', 'Cemented', 'Grassed', 'Synthetic', 'Clay'];
  final List<String> _ballTypes = ['Leather', 'Tennis', 'Rubber', 'Cork'];

  @override
  void dispose() {
    _animationController.dispose();
    _myTeamController.dispose();
    _opponentTeamController.dispose();
    _youtubeVideoIdController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _myTeamController.text.trim().isNotEmpty &&
            _opponentTeamController.text.trim().isNotEmpty;
      case 1:
        // Can proceed if both squads are completed
        return _myTeamPlayers.isNotEmpty && _opponentTeamPlayers.isNotEmpty;
      case 2:
        return _overs != null && _groundType != null && _ballType != null;
      default:
        return false;
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Select Squads';
      case 1:
        return 'Continue to Settings';
      case 2:
        return 'Next Step';
      default:
        return 'Next Step';
    }
  }

  Future<void> _handleNext() async {
    switch (_currentStep) {
      case 0:
        // Step 1: Navigate to My Team Squad
        if (_myTeamPlayersData.isEmpty) {
          final myTeamPlayersData = await context.push<List<Map<String, dynamic>>>(
            '/my-team-squad',
            extra: {
              'teamName': _myTeamController.text,
              'players': _myTeamPlayersData,
            },
          );
          if (myTeamPlayersData != null && myTeamPlayersData.isNotEmpty) {
            setState(() {
              _myTeamPlayersData = myTeamPlayersData;
              // Also update string list for display
              _myTeamPlayers = myTeamPlayersData.map((p) => p['name'] as String? ?? '').toList();
            });
          } else {
            return; // User cancelled, don't proceed
          }
        }
        
        // Step 2: Navigate to Opponent Team Squad
        if (_opponentTeamPlayersData.isEmpty) {
          final opponentPlayersData = await context.push<List<Map<String, dynamic>>>(
            '/opponent-team-squad',
            extra: {
              'teamName': _opponentTeamController.text,
              'players': _opponentTeamPlayersData,
            },
          );
          if (opponentPlayersData != null && opponentPlayersData.isNotEmpty) {
            setState(() {
              _opponentTeamPlayersData = opponentPlayersData;
              // Also update string list for display
              _opponentTeamPlayers = opponentPlayersData.map((p) => p['name'] as String? ?? '').toList();
              _currentStep = 2; // Move to Match Settings
            });
          }
        } else {
          // Both squads already completed, move to Match Settings
          setState(() {
            _currentStep = 2;
          });
        }
        break;
      case 1:
        // If on step 1, navigate to Opponent Team Squad
        final opponentPlayersData = await context.push<List<Map<String, dynamic>>>(
          '/opponent-team-squad',
          extra: {
            'teamName': _opponentTeamController.text,
            'players': _opponentTeamPlayersData,
          },
        );
        if (opponentPlayersData != null && opponentPlayersData.isNotEmpty) {
          setState(() {
            _opponentTeamPlayersData = opponentPlayersData;
            // Also update string list for display
            _opponentTeamPlayers = opponentPlayersData.map((p) => p['name'] as String? ?? '').toList();
            _currentStep = 2;
          });
        }
        break;
      case 2:
        // Match Settings - All settings in one step, navigate to Initial Players Setup
        if (_overs == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select number of overs')),
          );
          return;
        }
        if (_groundType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select ground type')),
          );
          return;
        }
        if (_ballType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select ball type')),
          );
          return;
        }
        // Create teams and match in Supabase before navigating
        try {
          final teamRepo = ref.read(teamRepositoryProvider);
          final matchRepo = ref.read(matchRepositoryProvider);
          final authState = ref.read(authStateProvider);
          final user = authState.user;
          
          // Check if user is logged in
          if (user == null || !authState.isAuthenticated) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please log in to create a match'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
          
          // Create or get my team
          String team1Id;
          try {
            // For now, we'll create teams without player_ids (empty array)
            // Player names are stored separately and can be linked later
            final myTeam = await teamRepo.createTeam({
              'name': _myTeamController.text,
              'player_ids': <String>[], // Empty array for now - player names are handled separately
              'created_by': user?.id,
            });
            team1Id = myTeam.id;
          } catch (e) {
            // Team might already exist, try to find it
            try {
              final teams = await teamRepo.getTeams(userId: user?.id);
              final existingTeam = teams.firstWhere(
                (t) => t.name == _myTeamController.text,
                orElse: () => throw Exception('Team not found'),
              );
              team1Id = existingTeam.id;
            } catch (findError) {
              // If team doesn't exist and creation failed, show the actual error
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create team: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return; // Don't proceed if team creation fails
            }
          }
          
          // Create or get opponent team
          String team2Id;
          try {
            // For now, we'll create teams without player_ids (empty array)
            final opponentTeam = await teamRepo.createTeam({
              'name': _opponentTeamController.text,
              'player_ids': <String>[], // Empty array for now
              'created_by': user?.id,
            });
            team2Id = opponentTeam.id;
          } catch (e) {
            // Team might already exist
            try {
              final teams = await teamRepo.getTeams();
              final existingTeam = teams.firstWhere(
                (t) => t.name == _opponentTeamController.text,
                orElse: () => throw Exception('Team not found'),
              );
              team2Id = existingTeam.id;
            } catch (findError) {
              // If team doesn't exist and creation failed, show the actual error
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create opponent team: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return; // Don't proceed if team creation fails
            }
          }
          
          // Create match in Supabase
          final match = await matchRepo.createMatch({
            'team1_id': team1Id,
            'team2_id': team2Id,
            'team1_name': _myTeamController.text,
            'team2_name': _opponentTeamController.text,
            'overs': int.parse(_overs!),
            'ground_type': _groundType!.toLowerCase(),
            'ball_type': _ballType!.toLowerCase(),
            'youtube_video_id': _youtubeVideoIdController.text.trim().isNotEmpty 
                ? _youtubeVideoIdController.text.trim() 
                : null,
            'status': 'upcoming',
            'scheduled_at': DateTime.now().toIso8601String(),
            'created_by': user?.id,
            if (widget.tournamentId != null) 'tournament_id': widget.tournamentId,
          });
          
          // Save players to match_players table (this will trigger notifications)
          final matchPlayerRepo = ref.read(matchPlayerRepositoryProvider);
          try {
            // Add my team players (use full player data with IDs)
            if (_myTeamPlayersData.isNotEmpty) {
              await matchPlayerRepo.addPlayersToMatch(
                matchId: match.id,
                players: _myTeamPlayersData,
                teamType: 'team1',
                addedBy: user?.id,
              );
              print('MatchPlayer: Added ${_myTeamPlayersData.length} players to team1');
            }
            
            // Add opponent team players (use full player data with IDs)
            if (_opponentTeamPlayersData.isNotEmpty) {
              await matchPlayerRepo.addPlayersToMatch(
                matchId: match.id,
                players: _opponentTeamPlayersData,
                teamType: 'team2',
                addedBy: user?.id,
              );
              print('MatchPlayer: Added ${_opponentTeamPlayersData.length} players to team2');
            }
          } catch (playerError) {
            print('Error: Failed to save players to match: $playerError');
            // Don't block navigation if player saving fails, but log the error
          }
          
          // Navigate to Toss page (AFTER match settings, BEFORE initial players setup)
          if (mounted) {
            context.push(
              '/toss',
              extra: {
                'matchId': match.id,
                'team1Id': team1Id,
                'team2Id': team2Id,
                'myTeam': _myTeamController.text,
                'opponentTeam': _opponentTeamController.text,
                'overs': _overs!,
                'groundType': _groundType!,
                'ballType': _ballType!,
                'myTeamPlayers': _myTeamPlayers,
                'opponentTeamPlayers': _opponentTeamPlayers,
                'youtubeVideoId': _youtubeVideoIdController.text.trim().isNotEmpty 
                    ? _youtubeVideoIdController.text.trim() 
                    : null,
              },
            );
          }
        } catch (e) {
          if (mounted) {
            // Extract a cleaner error message
            String errorMsg = e.toString();
            if (errorMsg.contains('Exception: ')) {
              errorMsg = errorMsg.split('Exception: ').last;
            }
            if (errorMsg.contains('Failed to create team')) {
              errorMsg = errorMsg.split('Failed to create team: ').last;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create match: $errorMsg'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
        break;
      case 5:
        // Navigate to Toss page (if we reach this step)
        if (mounted) {
          context.push(
            '/toss',
            extra: {
              'myTeam': _myTeamController.text,
              'opponentTeam': _opponentTeamController.text,
              'overs': _overs ?? '20',
              'groundType': _groundType ?? 'Turf',
              'ballType': _ballType ?? 'Leather',
              'myTeamPlayers': _myTeamPlayers,
              'opponentTeamPlayers': _opponentTeamPlayers,
              'youtubeVideoId': _youtubeVideoIdController.text.trim().isNotEmpty 
                  ? _youtubeVideoIdController.text.trim() 
                  : null,
            },
          );
        }
        break;
    }
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only apply gradient background for Match Settings step (step 2)
    final isMatchSettings = _currentStep == 2;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Professional App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Match',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isMatchSettings ? 'Configure match settings' : 'Set up your cricket match',
                          style: TextStyle(
                            color: AppColors.textMeta,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: List.generate(3, (index) {
                  final stepIndex = _currentStep == 0 || _currentStep == 1
                      ? 0
                      : _currentStep == 2
                          ? 1
                          : 2;
                  final isActive = index <= stepIndex;
                  final isCurrent = index == stepIndex;
                  
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      height: 6,
                      margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),

              // Content with animations
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey<int>(_currentStep),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: _buildStepContent(),
                  ),
                ),
              ),

              // Footer button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: isMatchSettings
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1E3A8A).withOpacity(0.95),
                            const Color(0xFF1E3A8A),
                          ],
                        )
                      : null,
                  color: isMatchSettings ? null : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: _canProceed()
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF10B981),
                                Color(0xFF059669),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: isMatchSettings
                                  ? [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.2),
                                    ]
                                  : [
                                      Colors.grey[300]!,
                                      Colors.grey[400]!,
                                    ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _canProceed()
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _canProceed() ? _handleNext : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _canProceed() ? Icons.check_circle : Icons.sports_cricket,
                                color: Colors.white,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _getButtonText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildRegisterTeamsStep();
      case 1:
        // Show status - should not reach here if flow is correct
        // But if we do, show squad status
        if (_myTeamPlayers.isEmpty || _opponentTeamPlayers.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                color: Color(0xFF205A28),
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Complete Squad Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF205A28),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _myTeamPlayers.isEmpty
                    ? 'My Team: Not completed\nOpponent Team: ${_opponentTeamPlayers.length} players'
                    : 'My Team: ${_myTeamPlayers.length} players\nOpponent Team: Not completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF205A28),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Squad Management Completed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF205A28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'My Team: ${_myTeamPlayers.length} players\nOpponent Team: ${_opponentTeamPlayers.length} players',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      case 2:
        // Match Settings - All sections together
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure your match preferences',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildOversStep(),
            const SizedBox(height: 24),
            _buildGroundTypeStep(),
            const SizedBox(height: 24),
            _buildBallTypeStep(),
            const SizedBox(height: 24),
            _buildYouTubeVideoIdStep(),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildRegisterTeamsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Register Teams',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your teams and opponents',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMeta,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        
        // Home Team Section
        _buildStaggeredEntry(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeamLabel('HOME TEAM'),
              const SizedBox(height: 12),
              _PremiumTeamCard(
                controller: _myTeamController,
                hintText: 'Your Team Name',
                icon: Icons.groups_rounded,
                isTournament: widget.tournamentId != null,
                isLoading: _isLoadingTournamentTeams,
                items: widget.tournamentId != null ? _tournamentTeamNames : [],
                selectedItem: _selectedMyTeam,
                onChanged: (value) {
                  setState(() {
                    if (widget.tournamentId != null) {
                      _selectedMyTeam = value;
                      _myTeamController.text = value ?? '';
                    } else {
                      // Handled by controller
                    }
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Animated VS Badge
        const _AnimatedVSBadge(),

        const SizedBox(height: 12),

        // Away Team Section
        _buildStaggeredEntry(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeamLabel('AWAY TEAM'),
              const SizedBox(height: 12),
              _PremiumTeamCard(
                controller: _opponentTeamController,
                hintText: 'Opponent Team Name',
                icon: Icons.flag_rounded,
                isTournament: widget.tournamentId != null,
                isLoading: _isLoadingTournamentTeams,
                items: widget.tournamentId != null ? _tournamentTeamNames : [],
                selectedItem: _selectedOpponentTeam,
                onChanged: (value) {
                  setState(() {
                    if (widget.tournamentId != null) {
                      _selectedOpponentTeam = value;
                      _opponentTeamController.text = value ?? '';
                    } else {
                      // Handled by controller
                    }
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Info text
        _buildStaggeredEntry(
          index: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.tournamentId != null 
                        ? 'Select teams registered in this tournament.'
                        : 'Match details can be edited later.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildStaggeredEntry({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 150)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: child,
    );
  }


  Widget _buildOversStep() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildSectionContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Overs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOversOption('10', 'Quick', false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOversOption('20', 'Standard', true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOversOption('50', 'ODI', false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.transparent),
              ),
              child: TextField(
                controller: TextEditingController(),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Custom overs...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.edit_outlined, color: Colors.grey[500], size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() => _overs = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOversOption(String overs, String label, bool isPopular) {
    final isSelected = _overs == overs || (overs == '20' && _overs == null);
    if (isSelected && overs == '20' && _overs == null) {
      _overs = '20'; // Set default
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[200]!,
              width: 1.5,
            ),
            // No shadow for flatter look inside card
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _overs = overs),
              child: Center(
                 child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      overs,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.grey[500],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: -8,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroundTypeStep() {
    final groundIcons = {
      'Turf': Icons.grass,
      'Cemented': Icons.foundation,
      'Grassed': Icons.landscape,
      'Synthetic': Icons.landscape,
      'Clay': Icons.landscape,
    };
    
    // Set default to Turf if not selected
    if (_groundType == null) {
      _groundType = 'Turf';
    }
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildSectionContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.grass_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Ground Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _groundTypes.map((type) {
                  final isSelected = _groundType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      constraints: const BoxConstraints(minWidth: 90),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _groundType = type),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  groundIcons[type] ?? Icons.landscape,
                                  color: isSelected ? Colors.white : Colors.grey[400],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBallTypeStep() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildSectionContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sports_cricket_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Ball Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBallTypeOption('Leather', true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBallTypeOption('Tennis', false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBallTypeOption(String type, bool isDefaultSelected) {
    final isSelected = _ballType == type;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _ballType = type),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF1F2937),
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildYouTubeVideoIdStep() {
    return _buildSectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.video_library, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'YouTube Live Stream',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
          const SizedBox(height: 24),
          
          if (!_youtubeLiveEnabled && !_showYouTubeInput) ...[
            // Go Live Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDC2626).withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _startGoLive,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.videocam, color: Color(0xFFDC2626), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Go Live on YouTube',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start a new broadcast immediately',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
            ),
            
            // Connect Existing Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _showYouTubeInput = true),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.link, color: Colors.grey[700], size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Connect Existing Stream',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter video ID manually',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          if (_showYouTubeInput) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter YouTube Video ID',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        prefixIcon: Icon(Icons.youtube_searched_for, color: Colors.grey[500]),
                      ),
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (value) => setState(() => _youtubeVideoId = value),
                    ),
                  ),
                  if (_youtubeVideoId?.isNotEmpty ?? false)
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                      onPressed: () {
                        setState(() {
                          _youtubeLiveEnabled = true;
                          _showYouTubeInput = false;
                        });
                      },
                    ),
                ],
              ),
            ),
            
            TextButton(
              onPressed: () => setState(() => _showYouTubeInput = false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startGoLive() {
    // Create a temporary match ID or use existing match if available
    // For now, we'll create a draft match first, then go live
    // Or navigate to Go Live with a temporary ID that will be updated after match creation
    
    // Get match title from form
    final matchTitle = '${_myTeamController.text} vs ${_opponentTeamController.text}';
    
    // Generate temporary match ID (will be replaced with actual match ID after creation)
    final tempMatchId = const Uuid().v4();
    
    // Navigate to Go Live screen
    context.push(
      '/go-live',
      extra: {
        'matchId': tempMatchId,
        'matchTitle': matchTitle.isNotEmpty ? matchTitle : 'Live Match',
        'isDraft': true, // Flag to indicate this is a draft match
      },
    );
  }

  void _openPitchPointChannel() {
    // Navigate directly to Live Screen - NO external browser/app
    // The Live Screen will check for live stream and play it in-app
    context.push('/live?channel=@PITCH-POINT');
  }

  void _showGoLiveInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam, color: Color(0xFFC72B32)),
            SizedBox(width: 8),
            Text('Go Live on YouTube'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To start a YouTube live stream:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInstructionStep('1', 'Open YouTube Studio on your computer or mobile'),
              _buildInstructionStep('2', 'Click "Go Live" or "Create" → "Go Live"'),
              _buildInstructionStep('3', 'Set up your stream (title, description, etc.)'),
              _buildInstructionStep('4', 'Start streaming'),
              _buildInstructionStep('5', 'Copy the Video ID from the stream URL'),
              _buildInstructionStep('6', 'Paste it in the field below'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: The Video ID is the part after "v=" in the URL',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC72B32),
            ),
            child: const Text('Got it, I\'ll start streaming'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTossPriceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toss Price',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF205A28),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: Color(0xFF205A28),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            hintStyle: TextStyle(
              color: AppColors.primary.withOpacity(0.4),
            ),
            prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF205A28)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF205A28), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            setState(() {
              _tossPrice = double.tryParse(value) ?? 0.0;
            });
          },
        ),
      ],
    );
  }
}

class _PremiumTeamCard extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isTournament;
  final bool isLoading;
  final List<String> items;
  final String? selectedItem;
  final Function(String?) onChanged;

  const _PremiumTeamCard({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isTournament = false,
    this.isLoading = false,
    this.items = const [],
    this.selectedItem,
    required this.onChanged,
  });

  @override
  State<_PremiumTeamCard> createState() => _PremiumTeamCardState();
}

class _PremiumTeamCardState extends State<_PremiumTeamCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.divider.withOpacity(0.5),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused 
                ? AppColors.primary.withOpacity(0.15) 
                : Colors.black.withOpacity(0.03),
            blurRadius: _isFocused ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.isTournament
          ? widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : DropdownButtonFormField<String>(
                  value: widget.selectedItem,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: AppColors.textMeta.withOpacity(0.5)),
                    prefixIcon: Icon(widget.icon, color: AppColors.primary, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
                  items: widget.items.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    widget.onChanged(value);
                  },
                )
          : Focus(
              onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: AppColors.textMeta.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    widget.icon,
                    color: _isFocused ? AppColors.primary : AppColors.textMeta.withOpacity(0.6),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) => widget.onChanged(value),
              ),
            ),
    );
  }
}

class _AnimatedVSBadge extends StatefulWidget {
  const _AnimatedVSBadge();

  @override
  State<_AnimatedVSBadge> createState() => _AnimatedVSBadgeState();
}

class _AnimatedVSBadgeState extends State<_AnimatedVSBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Glow
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 36 + (8 * _controller.value),
                height: 36 + (8 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              );
            },
          ),
          // VS Circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          // Lines
          Positioned(
            left: -60,
            child: Container(height: 1.5, width: 60, color: AppColors.divider.withOpacity(0.5)),
          ),
          Positioned(
            right: -60,
            child: Container(height: 1.5, width: 60, color: AppColors.divider.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

