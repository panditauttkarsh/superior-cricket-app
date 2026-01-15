import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class InitialPlayersSetupPage extends StatefulWidget {
  final String myTeam;
  final String opponentTeam;
  final String overs;
  final String groundType;
  final String ballType;
  final List<String> myTeamPlayers;
  final List<String> opponentTeamPlayers;
  final String? tossWinner;
  final String? tossChoice;
  final String? matchId;
  final String? youtubeVideoId;
  final String? team1Id;
  final String? team2Id;

  const InitialPlayersSetupPage({
    super.key,
    required this.myTeam,
    required this.opponentTeam,
    required this.overs,
    required this.groundType,
    required this.ballType,
    this.myTeamPlayers = const [],
    this.opponentTeamPlayers = const [],
    this.tossWinner,
    this.tossChoice,
    this.matchId,
    this.youtubeVideoId,
    this.team1Id,
    this.team2Id,
  });

  @override
  State<InitialPlayersSetupPage> createState() => _InitialPlayersSetupPageState();
}

class _InitialPlayersSetupPageState extends State<InitialPlayersSetupPage> with SingleTickerProviderStateMixin {
  String? _striker;
  String? _nonStriker;
  String? _bowler;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _battingTeamPlayers {
    // Determine batting team based on toss
    if (widget.tossWinner == widget.myTeam && widget.tossChoice == 'Bat') {
      return widget.myTeamPlayers.isNotEmpty ? widget.myTeamPlayers : ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
    } else if (widget.tossWinner == widget.opponentTeam && widget.tossChoice == 'Bat') {
      return widget.opponentTeamPlayers.isNotEmpty ? widget.opponentTeamPlayers : ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
    } else if (widget.tossWinner == widget.myTeam && widget.tossChoice == 'Bowl') {
      return widget.opponentTeamPlayers.isNotEmpty ? widget.opponentTeamPlayers : ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
    } else {
      return widget.myTeamPlayers.isNotEmpty ? widget.myTeamPlayers : ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
    }
  }

  List<String> get _bowlingTeamPlayers {
    // Determine bowling team based on toss
    if (widget.tossWinner == widget.myTeam && widget.tossChoice == 'Bowl') {
      // myTeam won and chose to bowl → myTeam bowls
      return widget.myTeamPlayers.isNotEmpty ? widget.myTeamPlayers : ['Bowler 1', 'Bowler 2', 'Bowler 3', 'Bowler 4'];
    } else if (widget.tossWinner == widget.opponentTeam && widget.tossChoice == 'Bowl') {
      // opponentTeam won and chose to bowl → opponentTeam bowls
      return widget.opponentTeamPlayers.isNotEmpty ? widget.opponentTeamPlayers : ['Bowler 1', 'Bowler 2', 'Bowler 3', 'Bowler 4'];
    } else if (widget.tossWinner == widget.myTeam && widget.tossChoice == 'Bat') {
      // myTeam won and chose to bat → opponentTeam bowls
      return widget.opponentTeamPlayers.isNotEmpty ? widget.opponentTeamPlayers : ['Bowler 1', 'Bowler 2', 'Bowler 3', 'Bowler 4'];
    } else {
      // opponentTeam won and chose to bat → myTeam bowls
      return widget.myTeamPlayers.isNotEmpty ? widget.myTeamPlayers : ['Bowler 1', 'Bowler 2', 'Bowler 3', 'Bowler 4'];
    }
  }

  void _confirmPlayers() {
    if (_striker == null || _nonStriker == null || _bowler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select all players'),
          backgroundColor: AppColors.urgent,
        ),
      );
      return;
    }

    // Navigate to scorecard with all match data
    // Batting/bowling styles will be collected on the scorecard page
    if (mounted) {
      // Calculate max overs per bowler based on match format
      final oversInt = int.tryParse(widget.overs) ?? 20;
      final maxOversPerBowler = oversInt <= 20 ? 4 : 10; // T20=4, ODI=10
      
      context.push('/scorecard', extra: {
        'matchId': widget.matchId,
        'myTeam': widget.myTeam,
        'opponentTeam': widget.opponentTeam,
        'overs': widget.overs,
        'maxOversPerBowler': maxOversPerBowler,
        'groundType': widget.groundType,
        'ballType': widget.ballType,
        'tossWinner': widget.tossWinner,
        'tossChoice': widget.tossChoice,
        'myTeamPlayers': widget.myTeamPlayers,
        'opponentTeamPlayers': widget.opponentTeamPlayers,
        'initialStriker': _striker,
        'initialNonStriker': _nonStriker,
        'initialBowler': _bowler,
        'youtubeVideoId': widget.youtubeVideoId,
        'team1Id': widget.team1Id,
        'team2Id': widget.team2Id,
      });
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
          'Select Players',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // Background decoration with blue gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select the opening batsmen and the starting bowler for the match.',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Striker
                    _buildPlayerSelector(
                      label: 'Striker',
                      icon: Icons.sports_cricket,
                      selectedValue: _striker,
                      players: _battingTeamPlayers.where((p) => p != _nonStriker).toList(),
                      onChanged: (value) => setState(() => _striker = value),
                      delay: 0,
                    ),

                    const SizedBox(height: 24),

                    // Non-Striker
                    _buildPlayerSelector(
                      label: 'Non-Striker',
                      icon: Icons.sports_cricket,
                      selectedValue: _nonStriker,
                      players: _battingTeamPlayers.where((p) => p != _striker).toList(),
                      onChanged: (value) => setState(() => _nonStriker = value),
                      delay: 100,
                    ),

                    const SizedBox(height: 24),
                    Divider(color: AppColors.divider.withOpacity(0.3)),
                    const SizedBox(height: 24),

                    // Bowler
                    _buildPlayerSelector(
                      label: 'Bowler',
                      icon: Icons.sports_baseball,
                      selectedValue: _bowler,
                      players: _bowlingTeamPlayers,
                      onChanged: (value) => setState(() => _bowler = value),
                      delay: 200,
                    ),

                    const SizedBox(height: 150), // Space for bottom button
                  ],
                ),
              ),

              // Bottom button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(color: AppColors.divider.withOpacity(0.3)),
                    ),
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: _confirmPlayers,
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
                          const Text(
                            'Start Match',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelector({
    required String label,
    required IconData icon,
    required String? selectedValue,
    required List<String> players,
    required Function(String?) onChanged,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                '$label:',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedValue != null ? AppColors.primary : AppColors.divider.withOpacity(0.3),
                width: selectedValue != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: selectedValue != null 
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: selectedValue != null ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                hint: Text(
                  'Select $label',
                  style: TextStyle(
                    color: AppColors.textSec,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                icon: Icon(
                  Icons.expand_circle_down,
                  color: AppColors.primary,
                ),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                items: players.map((player) {
                  return DropdownMenuItem<String>(
                    value: player,
                    child: Text(player),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
