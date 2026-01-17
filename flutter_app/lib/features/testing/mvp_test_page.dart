import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mvp_calculation_service.dart';
import '../../../core/repositories/mvp_repository.dart';
import '../../../core/models/mvp_model.dart';
import '../../../core/providers/repository_providers.dart';
import '../match/presentation/widgets/mvp_award_card.dart';

/// MVP Testing Page - For testing the MVP system
class MvpTestPage extends ConsumerStatefulWidget {
  const MvpTestPage({super.key});

  @override
  ConsumerState<MvpTestPage> createState() => _MvpTestPageState();
}

class _MvpTestPageState extends ConsumerState<MvpTestPage> {
  String _testResult = '';
  PlayerMvpModel? _sampleMvpData;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MVP System Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple.shade300],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.science, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'MVP System Testing',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Test all MVP calculations and database operations',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test Buttons
            _buildTestButton(
              icon: Icons.calculate,
              title: 'Test 1: Calculate Batting MVP',
              description: 'Calculate MVP for 75 runs in 50 balls',
              color: Colors.green,
              onPressed: _testBattingMvp,
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.sports_cricket,
              title: 'Test 2: Calculate Bowling MVP',
              description: 'Calculate MVP for 3 wickets + 1 maiden',
              color: Colors.blue,
              onPressed: _testBowlingMvp,
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.sports_handball,
              title: 'Test 3: Calculate Fielding MVP',
              description: 'Calculate MVP for 2 catches',
              color: Colors.orange,
              onPressed: _testFieldingMvp,
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.save,
              title: 'Test 4: Save to Database',
              description: 'Save sample MVP data to Supabase',
              color: Colors.purple,
              onPressed: _testSaveToDatabase,
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.download,
              title: 'Test 5: Load from Database',
              description: 'Retrieve MVP data from Supabase',
              color: Colors.teal,
              onPressed: _testLoadFromDatabase,
            ),

            const SizedBox(height: 12),

            _buildTestButton(
              icon: Icons.emoji_events,
              title: 'Test 6: Full Match MVP',
              description: 'Calculate and save MVP for entire match',
              color: Colors.red,
              onPressed: _testFullMatchMvp,
            ),

            const SizedBox(height: 24),

            // Results Section
            if (_testResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.terminal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Test Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _testResult,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // MVP Card Preview
            if (_sampleMvpData != null) ...[
              const Text(
                'MVP Card Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              MvpAwardCard(
                mvpData: _sampleMvpData!,
                isPlayerOfTheMatch: true,
                onTap: () {
                  _showMvpDetails();
                },
              ),
            ],

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  // Test 1: Batting MVP
  void _testBattingMvp() {
    setState(() {
      _testResult = '🏏 Testing Batting MVP Calculation...\n\n';
    });

    final battingMvp = MvpCalculationService.calculateBattingMvp(
      runsScored: 75,
      ballsFaced: 50,
      battingOrder: 1,
      teamTotalRuns: 180,
      teamTotalBalls: 120,
    );

    final grade = MvpCalculationService.getPerformanceGrade(battingMvp);

    setState(() {
      _testResult += 'Input:\n';
      _testResult += '  Runs: 75\n';
      _testResult += '  Balls: 50\n';
      _testResult += '  Strike Rate: 150.0\n';
      _testResult += '  Batting Order: 1 (Opener)\n\n';
      _testResult += 'Result:\n';
      _testResult += '  ✅ Batting MVP: ${battingMvp.toStringAsFixed(2)}\n';
      _testResult += '  ✅ Grade: $grade\n\n';
      _testResult += 'Expected: 7.5-8.5 points (Very Good 🔥)\n';
      _testResult += battingMvp >= 7.5 && battingMvp <= 8.5
          ? '✅ TEST PASSED!'
          : '⚠️ TEST WARNING: Value outside expected range';
    });
  }

  // Test 2: Bowling MVP
  void _testBowlingMvp() {
    setState(() {
      _testResult = '⚡ Testing Bowling MVP Calculation...\n\n';
    });

    final bowlingMvp = MvpCalculationService.calculateBowlingMvp(
      wickets: [
        {'battingOrder': 1, 'dismissalType': 'bowled', 'runsScored': 15},
        {'battingOrder': 5, 'dismissalType': 'caught', 'runsScored': 10},
        {'battingOrder': 9, 'dismissalType': 'lbw', 'runsScored': 1},
      ],
      runsConceded: 30,
      ballsBowled: 24,
      maidenOvers: 1,
      teamTotalRuns: 180,
      teamTotalBalls: 120,
      totalOvers: 20,
    );

    final grade = MvpCalculationService.getPerformanceGrade(bowlingMvp);

    setState(() {
      _testResult += 'Input:\n';
      _testResult += '  Wickets: 3 (orders: 1, 5, 9)\n';
      _testResult += '  Runs Conceded: 30\n';
      _testResult += '  Balls Bowled: 24 (4 overs)\n';
      _testResult += '  Maiden Overs: 1\n';
      _testResult += '  Economy: 7.5\n\n';
      _testResult += 'Result:\n';
      _testResult += '  ✅ Bowling MVP: ${bowlingMvp.toStringAsFixed(2)}\n';
      _testResult += '  ✅ Grade: $grade\n\n';
      _testResult += 'Expected: 3.0-5.0 points (Average-Good)\n';
      _testResult += bowlingMvp >= 3.0 && bowlingMvp <= 5.0
          ? '✅ TEST PASSED!'
          : '⚠️ TEST WARNING: Value outside expected range';
    });
  }

  // Test 3: Fielding MVP
  void _testFieldingMvp() {
    setState(() {
      _testResult = '🧤 Testing Fielding MVP Calculation...\n\n';
    });

    final fieldingMvp = MvpCalculationService.calculateFieldingMvp(
      assists: [
        {'battingOrder': 3},
        {'battingOrder': 5},
      ],
      runOuts: [],
      totalOvers: 20,
    );

    final grade = MvpCalculationService.getPerformanceGrade(fieldingMvp);

    setState(() {
      _testResult += 'Input:\n';
      _testResult += '  Catches: 2 (batting orders: 3, 5)\n';
      _testResult += '  Run Outs: 0\n';
      _testResult += '  Stumpings: 0\n\n';
      _testResult += 'Result:\n';
      _testResult += '  ✅ Fielding MVP: ${fieldingMvp.toStringAsFixed(2)}\n';
      _testResult += '  ✅ Grade: $grade\n\n';
      _testResult += 'Expected: 0.3-0.8 points\n';
      _testResult += fieldingMvp >= 0.3 && fieldingMvp <= 0.8
          ? '✅ TEST PASSED!'
          : '⚠️ TEST WARNING: Value outside expected range';
    });
  }

  // Test 4: Save to Database
  Future<void> _testSaveToDatabase() async {
    setState(() {
      _isLoading = true;
      _testResult = '💾 Testing Save to Database...\n\n';
    });

    try {
      final mvpRepo = ref.read(mvpRepositoryProvider);

      // Create sample MVP data
      final mvpData = PlayerMvpModel(
        playerId: 'test-player-${DateTime.now().millisecondsSinceEpoch}',
        playerName: 'Virat Kohli',
        matchId: 'test-match-${DateTime.now().millisecondsSinceEpoch}',
        teamId: 'test-team-1',
        teamName: 'Royal Challengers',
        battingMvp: 7.5,
        bowlingMvp: 0.0,
        fieldingMvp: 0.4,
        totalMvp: 7.9,
        runsScored: 75,
        ballsFaced: 50,
        wicketsTaken: 0,
        runsConceded: 0,
        ballsBowled: 0,
        catches: 2,
        runOuts: 0,
        stumpings: 0,
        battingOrder: 3,
        strikeRate: 150.0,
        performanceGrade: 'Very Good 🔥',
        calculatedAt: DateTime.now(),
        isPlayerOfTheMatch: true,
      );

      final saved = await mvpRepo.saveMvpData(mvpData);

      setState(() {
        _testResult += 'Data to Save:\n';
        _testResult += '  Player: ${mvpData.playerName}\n';
        _testResult += '  Total MVP: ${mvpData.formattedMvpScore}\n';
        _testResult += '  Grade: ${mvpData.performanceGrade}\n\n';
        _testResult += 'Result:\n';
        _testResult += '  ✅ Successfully saved to database!\n';
        _testResult += '  ✅ Record ID: ${saved.playerId}\n';
        _testResult += '  ✅ POTM: ${saved.isPlayerOfTheMatch}\n\n';
        _testResult += '✅ TEST PASSED!\n\n';
        _testResult += 'Check Supabase dashboard → player_mvp table';

        _sampleMvpData = saved;
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ ERROR: $e\n\n';
        _testResult += 'Troubleshooting:\n';
        _testResult += '1. Check if player_mvp table exists\n';
        _testResult += '2. Verify RLS policies allow INSERT\n';
        _testResult += '3. Check network connection';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test 5: Load from Database
  Future<void> _testLoadFromDatabase() async {
    setState(() {
      _isLoading = true;
      _testResult = '📥 Testing Load from Database...\n\n';
    });

    try {
      final mvpRepo = ref.read(mvpRepositoryProvider);

      // Try to get top MVP players
      final topPlayers = await mvpRepo.getTopMvpPlayers(limit: 5);

      setState(() {
        _testResult += 'Query: Get Top 5 MVP Players\n\n';
        _testResult += 'Result:\n';
        _testResult += '  ✅ Found ${topPlayers.length} players\n\n';

        if (topPlayers.isNotEmpty) {
          _testResult += 'Top Players:\n';
          for (int i = 0; i < topPlayers.length; i++) {
            final player = topPlayers[i];
            _testResult += '  ${i + 1}. ${player['player_name']}\n';
            _testResult += '     MVP: ${player['total_mvp_points']}\n';
            _testResult += '     Matches: ${player['total_matches']}\n';
            _testResult += '     POTM: ${player['potm_count']}\n\n';
          }
          _testResult += '✅ TEST PASSED!';
        } else {
          _testResult += '⚠️ No data found in database\n';
          _testResult += 'Run Test 4 first to insert sample data';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ ERROR: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test 6: Full Match MVP
  Future<void> _testFullMatchMvp() async {
    setState(() {
      _isLoading = true;
      _testResult = '🏆 Testing Full Match MVP Flow...\n\n';
    });

    try {
      final mvpRepo = ref.read(mvpRepositoryProvider);
      final matchId = 'test-match-${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _testResult += 'Creating match with 2 players...\n\n';
      });

      // Player 1: Batter
      final player1Mvp = PlayerMvpModel(
        playerId: 'player-1-${DateTime.now().millisecondsSinceEpoch}',
        playerName: 'Virat Kohli',
        matchId: matchId,
        teamId: 'team-1',
        teamName: 'Team A',
        battingMvp: 8.5,
        bowlingMvp: 0.0,
        fieldingMvp: 0.4,
        totalMvp: 8.9,
        runsScored: 85,
        ballsFaced: 60,
        wicketsTaken: 0,
        runsConceded: 0,
        ballsBowled: 0,
        catches: 2,
        runOuts: 0,
        stumpings: 0,
        battingOrder: 3,
        strikeRate: 141.67,
        performanceGrade: 'Excellent 💎',
        calculatedAt: DateTime.now(),
      );

      // Player 2: Bowler
      final player2Mvp = PlayerMvpModel(
        playerId: 'player-2-${DateTime.now().millisecondsSinceEpoch}',
        playerName: 'Jasprit Bumrah',
        matchId: matchId,
        teamId: 'team-1',
        teamName: 'Team A',
        battingMvp: 0.5,
        bowlingMvp: 4.2,
        fieldingMvp: 0.0,
        totalMvp: 4.7,
        runsScored: 5,
        ballsFaced: 8,
        wicketsTaken: 3,
        runsConceded: 28,
        ballsBowled: 24,
        catches: 0,
        runOuts: 0,
        stumpings: 0,
        battingOrder: 11,
        bowlingEconomy: 7.0,
        performanceGrade: 'Good ⭐',
        calculatedAt: DateTime.now(),
      );

      // Save both players
      await mvpRepo.saveBatchMvpData([player1Mvp, player2Mvp]);

      // Update POTM
      await mvpRepo.updatePlayerOfTheMatch(matchId);

      // Get POTM
      final potm = await mvpRepo.getPlayerOfTheMatch(matchId);

      setState(() {
        _testResult += 'Player 1: ${player1Mvp.playerName}\n';
        _testResult += '  Total MVP: ${player1Mvp.formattedMvpScore}\n';
        _testResult += '  Grade: ${player1Mvp.performanceGrade}\n\n';

        _testResult += 'Player 2: ${player2Mvp.playerName}\n';
        _testResult += '  Total MVP: ${player2Mvp.formattedMvpScore}\n';
        _testResult += '  Grade: ${player2Mvp.performanceGrade}\n\n';

        _testResult += '👑 PLAYER OF THE MATCH:\n';
        if (potm != null) {
          _testResult += '  ${potm.playerName}\n';
          _testResult += '  MVP: ${potm.formattedMvpScore} ${potm.performanceEmoji}\n\n';
          _testResult += '✅ TEST PASSED!';

          _sampleMvpData = potm;
        } else {
          _testResult += '  ❌ POTM not determined\n';
          _testResult += '⚠️ TEST FAILED';
        }
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ ERROR: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMvpDetails() {
    if (_sampleMvpData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_sampleMvpData!.playerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total MVP: ${_sampleMvpData!.formattedMvpScore}'),
            Text('Batting: ${_sampleMvpData!.battingMvp.toStringAsFixed(2)}'),
            Text('Bowling: ${_sampleMvpData!.bowlingMvp.toStringAsFixed(2)}'),
            Text('Fielding: ${_sampleMvpData!.fieldingMvp.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Text('Grade: ${_sampleMvpData!.performanceGrade}'),
            Text('POTM: ${_sampleMvpData!.isPlayerOfTheMatch ? "Yes 👑" : "No"}'),
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
  }
}
