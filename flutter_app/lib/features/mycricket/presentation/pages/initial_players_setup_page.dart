import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:math' as math;

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

class _InitialPlayersSetupPageState extends State<InitialPlayersSetupPage> with TickerProviderStateMixin {
  String? _striker;
  String? _nonStriker;
  String? _bowler;
  late AnimationController _animationController;
  late AnimationController _gradientController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
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
    _gradientController.dispose();
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Navigate to scorecard with all match data
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
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF1E3A8A),
                    const Color(0xFF2563EB),
                    _gradientController.value * 0.3,
                  )!,
                  const Color(0xFF2563EB),
                  Color.lerp(
                    const Color(0xFF3B82F6),
                    const Color(0xFF60A5FA),
                    _gradientController.value * 0.3,
                  )!,
                  const Color(0xFF60A5FA),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative cricket elements with rotation
              Positioned(
                top: -50,
                right: -50,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 2 * math.pi),
                  duration: const Duration(seconds: 20),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.sports_cricket,
                          size: 200,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    Icons.sports_cricket,
                    size: 150,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Main content
              Column(
                children: [
                  // Custom App Bar
                  _buildAppBar(),
                  
                  // Scrollable content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Info banner
                              _buildInfoBanner(),
                              const SizedBox(height: 32),

                              // Striker
                              _buildPlayerSelector(
                                label: 'Striker',
                                icon: Icons.sports_cricket,
                                selectedValue: _striker,
                                players: _battingTeamPlayers.where((p) => p != _nonStriker).toList(),
                                onChanged: (value) => setState(() => _striker = value),
                                delay: 0,
                                accentColor: const Color(0xFF10B981),
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
                                accentColor: const Color(0xFF10B981),
                              ),

                              const SizedBox(height: 32),
                              
                              // Divider with text
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'BOWLING',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 32),

                              // Bowler
                              _buildPlayerSelector(
                                label: 'Opening Bowler',
                                icon: Icons.sports_baseball,
                                selectedValue: _bowler,
                                players: _bowlingTeamPlayers,
                                onChanged: (value) => setState(() => _bowler = value),
                                delay: 200,
                                accentColor: const Color(0xFFF59E0B),
                              ),

                              const SizedBox(height: 120), // Space for bottom button
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom button
                  _buildBottomButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
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
                    color: Colors.white,
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
                Text(
                  'Select Players',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Choose your starting lineup',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Select the opening batsmen and the starting bowler for the match.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
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
    required Color accentColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with icon
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.8),
                        accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Dropdown container with glassmorphism
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selectedValue != null
                    ? [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.2),
                      ]
                    : [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.1),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedValue != null 
                    ? accentColor.withOpacity(0.6)
                    : Colors.white.withOpacity(0.3),
                width: selectedValue != null ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: selectedValue != null 
                      ? accentColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: selectedValue != null ? 16 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  isExpanded: true,
                  hint: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select $label',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  dropdownColor: const Color(0xFF1E3A8A),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  borderRadius: BorderRadius.circular(16),
                  items: players.map((player) {
                    return DropdownMenuItem<String>(
                      value: player,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor.withOpacity(0.8),
                                    accentColor,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  player[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  selectedItemBuilder: (context) {
                    return players.map((player) {
                      return Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withOpacity(0.8),
                                  accentColor,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                player[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              player,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isComplete = _striker != null && _nonStriker != null && _bowler != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF1E3A8A).withOpacity(0.95),
            const Color(0xFF1E3A8A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isComplete
                ? [
                    const Color(0xFF10B981),
                    const Color(0xFF059669),
                  ]
                : [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.2),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isComplete
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
            onTap: _confirmPlayers,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.sports_cricket,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isComplete ? 'Start Match' : 'Select All Players',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isComplete ? 0 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
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
}
