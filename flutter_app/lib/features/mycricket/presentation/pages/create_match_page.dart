import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class CreateMatchPage extends ConsumerStatefulWidget {
  const CreateMatchPage({super.key});

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
  
  List<String> _myTeamPlayers = [];
  List<String> _opponentTeamPlayers = [];
  // Store full player data for match_players table
  List<Map<String, dynamic>> _myTeamPlayersData = [];
  List<Map<String, dynamic>> _opponentTeamPlayersData = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Create New Match',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              children: List.generate(3, (index) {
                // Map steps: 0->0, 1->0, 2->1, 3->2
                final stepIndex = _currentStep == 0 || _currentStep == 1
                    ? 0
                    : _currentStep == 2
                        ? 1
                        : 2;
                final isActive = index <= stepIndex;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.divider.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content with animations
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ),

          // Footer button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed() ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
            const Text(
              'Match Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A5F),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildOversStep(),
            const SizedBox(height: 32),
            _buildGroundTypeStep(),
            const SizedBox(height: 32),
            _buildBallTypeStep(),
            const SizedBox(height: 32),
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
        const Text(
          'Register Teams',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        
        // Home Team
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'HOME TEAM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _myTeamController,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'My Team Name',
                  hintStyle: TextStyle(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.groups,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // VS Divider
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 1,
              width: 48,
              color: Colors.grey[300],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 2,
                ),
              ),
            ),
            Container(
              height: 1,
              width: 48,
              color: Colors.grey[300],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Away Team
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'AWAY TEAM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _opponentTeamController,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Opponent Team Name',
                  hintStyle: TextStyle(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.flag,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Info text
        Text(
          'Match details can be edited later in the match settings before the first ball is bowled.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            height: 1.5,
          ),
        ),
      ],
    );
  }


  Widget _buildOversStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer, color: Color(0xFF1E3A5F), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Overs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: TextEditingController(), // Empty controller to ensure no "kings" text
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter custom overs',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.edit, color: Colors.grey, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() => _overs = value);
              }
            },
          ),
        ),
      ],
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
        InkWell(
          onTap: () => setState(() => _overs = overs),
          child: Container(
            constraints: const BoxConstraints(minWidth: 100), // Same as ground type boxes
            padding: const EdgeInsets.all(16), // Same padding as ground type boxes
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFFF3F4F6), // Gray background like ground type boxes
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  overs,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xFF1E3A5F),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isPopular) // Always show POPULAR tag on 20 overs
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC72B32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stadium, color: Color(0xFF1E3A5F), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Ground Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _groundTypes.map((type) {
              final isSelected = _groundType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => setState(() => _groundType = type),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 100),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : const Color(0xFFF3F4F6), // Gray background like overs boxes
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey[200]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            groundIcons[type] ?? Icons.landscape,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[500],
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBallTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sports_cricket, color: Color(0xFF1E3A5F), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Ball Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBallTypeOption('Leather', true), // Default selected - should be green
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildBallTypeOption('Tennis', false), // Not default
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBallTypeOption(String type, bool isDefaultSelected) {
    final isSelected = _ballType == type;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => setState(() => _ballType = type),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey[200]!,
                width: isSelected ? 1 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
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
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF205A28),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (type == 'Tennis' ? Colors.yellow[300] : const Color(0xFFC72B32))
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Yellow circle for Tennis when selected (like HTML)
        if (type == 'Tennis' && isSelected)
          Positioned(
            bottom: -16,
            right: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.yellow[300]!.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow[300]!.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildYouTubeVideoIdStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.video_library, color: Color(0xFF205A28), size: 24),
            const SizedBox(width: 8),
            const Text(
              'YouTube Live Stream (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF205A28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (!_youtubeLiveEnabled && !_showYouTubeInput) ...[
          // Go Live Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC72B32).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate directly to Go Live screen
                  _startGoLive();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/icon youtube.webp',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Go Live on YouTube',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Or Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 12),
          
          // Connect to Existing Stream Button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC72B32), Color(0xFF8B1A1F)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showYouTubeInput = true;
                    _youtubeLiveEnabled = false;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/icon youtube.webp',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.link,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Connect to Existing Live Stream',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Skip Button
          TextButton(
            onPressed: () {
              setState(() {
                _showYouTubeInput = false;
                _youtubeLiveEnabled = false;
                _youtubeVideoIdController.clear();
              });
            },
            child: Text(
              'Skip - No Live Stream',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
        
        // YouTube Video ID Input (shown when connecting to existing stream)
        if (_showYouTubeInput) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _youtubeVideoIdController,
              style: const TextStyle(
                color: Color(0xFF205A28),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: _youtubeLiveEnabled 
                    ? 'Enter your YouTube Live Stream ID'
                    : 'e.g., dQw4w9WgXcQ (from youtube.com/watch?v=...)',
                hintStyle: TextStyle(
                  color: AppColors.primary.withOpacity(0.4),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  _youtubeLiveEnabled ? Icons.videocam : Icons.play_circle_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                suffixIcon: _showYouTubeInput
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _showYouTubeInput = false;
                            _youtubeLiveEnabled = false;
                            _youtubeVideoIdController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_youtubeLiveEnabled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF205A28),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'After starting your YouTube live stream, paste the Video ID here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _showGoLiveOptions() {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose an option:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Option 1: Start Live Stream (Go Live)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to Go Live screen to start streaming
                  _startGoLive();
                },
                icon: const Icon(Icons.videocam, color: Colors.white),
                label: const Text('Start Live Stream'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC72B32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Paste Existing Stream Link
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _showYouTubeInput = true;
                    _youtubeLiveEnabled = false;
                  });
                },
                icon: const Icon(Icons.link, color: Color(0xFFC72B32)),
                label: const Text('Paste Existing Stream Link'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC72B32), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

