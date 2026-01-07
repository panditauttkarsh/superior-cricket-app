import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';

class TossPage extends ConsumerStatefulWidget {
  final String myTeam;
  final String opponentTeam;
  final String overs;
  final String groundType;
  final String ballType;
  final List<String> myTeamPlayers;
  final List<String> opponentTeamPlayers;
  final String? initialStriker;
  final String? initialNonStriker;
  final String? initialBowler;
  final String? youtubeVideoId;
  final String? matchId;
  final String? team1Id;
  final String? team2Id;

  const TossPage({
    super.key,
    required this.myTeam,
    required this.opponentTeam,
    this.overs = '20',
    this.groundType = 'Turf',
    this.ballType = 'Leather',
    this.myTeamPlayers = const [],
    this.opponentTeamPlayers = const [],
    this.initialStriker,
    this.initialNonStriker,
    this.initialBowler,
    this.youtubeVideoId,
    this.matchId,
    this.team1Id,
    this.team2Id,
  });

  @override
  ConsumerState<TossPage> createState() => _TossPageState();
}

class _TossPageState extends ConsumerState<TossPage> with SingleTickerProviderStateMixin {
  late AnimationController _coinController;
  late Animation<double> _coinAnimation;
  String? _tossWinner;
  String? _tossChoice; // 'Bat' or 'Bowl'
  bool _isFlipping = false;
  String _myTeamInitial = '';
  String _opponentTeamInitial = '';
  bool _coinResult = false; // false = heads, true = tails

  @override
  void initState() {
    super.initState();
    _myTeamInitial = widget.myTeam.isNotEmpty ? widget.myTeam[0].toUpperCase() : 'W';
    _opponentTeamInitial = widget.opponentTeam.isNotEmpty ? widget.opponentTeam[0].toUpperCase() : 'T';
    
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Longer for 3D effect
      vsync: this,
    );
    
    _coinAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _flipCoin() {
    if (_isFlipping) return;
    
    setState(() {
      _isFlipping = true;
      _tossWinner = null; // Clear previous selection
      _coinResult = Random().nextBool(); // Random heads or tails
    });
    
    _coinController.forward(from: 0).then((_) {
      // Randomly determine winner after animation based on coin result
      final winner = _coinResult ? widget.myTeam : widget.opponentTeam;
      
      setState(() {
        _tossWinner = winner;
        _tossChoice = 'Bat'; // Default choice
        _isFlipping = false;
      });
      
      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_coinResult ? "Tails" : "Heads"}! $winner won the toss!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _startMatch() async {
    if (_tossWinner == null || _tossChoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the toss first')),
      );
      return;
    }

    // Update match in Supabase with toss result
    if (widget.matchId != null) {
      try {
        final matchRepo = ref.read(matchRepositoryProvider);
        final tossWinnerId = _tossWinner == widget.myTeam 
            ? widget.team1Id 
            : widget.team2Id;
        
        await matchRepo.updateMatch(widget.matchId!, {
          'toss_winner_id': tossWinnerId,
          'toss_decision': _tossChoice!.toLowerCase(),
          'status': 'live',
          'started_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update match: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Navigate to initial players setup (AFTER toss)
    if (mounted) {
      context.push('/initial-players-setup', extra: {
        'matchId': widget.matchId,
        'myTeam': widget.myTeam,
        'opponentTeam': widget.opponentTeam,
        'overs': widget.overs,
        'groundType': widget.groundType,
        'ballType': widget.ballType,
        'tossWinner': _tossWinner!,
        'tossChoice': _tossChoice!,
        'myTeamPlayers': widget.myTeamPlayers,
        'opponentTeamPlayers': widget.opponentTeamPlayers,
        'initialStriker': widget.initialStriker ?? (widget.myTeamPlayers.isNotEmpty ? widget.myTeamPlayers[0] : 'Player 1'),
        'initialNonStriker': widget.initialNonStriker ?? (widget.myTeamPlayers.length > 1 ? widget.myTeamPlayers[1] : 'Player 2'),
        'initialBowler': widget.initialBowler ?? (widget.opponentTeamPlayers.isNotEmpty ? widget.opponentTeamPlayers[0] : 'Bowler 1'),
        'youtubeVideoId': widget.youtubeVideoId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  const Text(
                    'Toss & Start Match',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 6,
                        width: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Setup Phase',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Teams Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _myTeamInitial,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.myTeam,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _opponentTeamInitial,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.opponentTeam,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Coin Flip Section
            Column(
              children: [
                SizedBox(
                  height: 120,
                  child: AnimatedBuilder(
                    animation: _coinAnimation,
                    builder: (context, child) {
                      // Calculate rotation angle (multiple flips for 3D effect)
                      final rotation = _coinAnimation.value * 1440; // 4 full rotations (1440 degrees)
                      final isFlipping = _coinAnimation.value < 1.0;
                      
                      // Determine which side to show based on rotation (flip every 180 degrees)
                      final rotationMod = (rotation / 180).floor() % 2;
                      final showHeads = isFlipping 
                          ? (rotationMod == 0)
                          : !_coinResult;
                      
                      // Calculate opacity for smooth transition
                      final opacity = isFlipping
                          ? (sin(rotation * pi / 180).abs())
                          : 1.0;
                      
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspective for 3D effect
                          ..rotateY(rotation * pi / 180),
                        child: Opacity(
                          opacity: opacity < 0.3 ? 0.3 : opacity,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFFA500),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: showHeads
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.amber[900],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.amber[700]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'H',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'HEADS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFFA500),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.amber[900]!,
                                              width: 3,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'T',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFFFA500),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'TAILS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFFA500),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isFlipping ? null : _flipCoin,
                  icon: Icon(_isFlipping ? Icons.hourglass_empty : Icons.refresh),
                  label: Text(_isFlipping ? 'Flipping...' : 'Flip Coin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Who Won the Toss
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Color(0xFF205A28),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Who Won the Toss?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF205A28),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTossOption(
                                widget.myTeam,
                                _tossWinner == widget.myTeam,
                                () => setState(() => _tossWinner = widget.myTeam),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTossOption(
                                widget.opponentTeam,
                                _tossWinner == widget.opponentTeam,
                                () => setState(() => _tossWinner = widget.opponentTeam),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Choose to Bat or Bowl
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.sports_cricket,
                              color: Color(0xFF205A28),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Chose to Bat or Bowl?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF205A28),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildChoiceOption(
                                'Bat',
                                _tossChoice == 'Bat',
                                () => setState(() => _tossChoice = 'Bat'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildChoiceOption(
                                'Bowl',
                                _tossChoice == 'Bowl',
                                () => setState(() => _tossChoice = 'Bowl'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Summary Box
                    if (_tossWinner != null && _tossChoice != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '$_tossWinner won the toss and chose to $_tossChoice first.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF205A28),
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(
            top: BorderSide(color: Colors.grey[100]!),
          ),
        ),
        child: ElevatedButton(
          onPressed: _startMatch,
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
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_arrow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTossOption(String team, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                team,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.grey[500],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF205A28),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceOption(String choice, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            choice,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}

