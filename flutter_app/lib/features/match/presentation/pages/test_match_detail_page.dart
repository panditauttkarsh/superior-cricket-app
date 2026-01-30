import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/cricket_engine/models/delivery_model.dart';
import '../../../../core/cricket_engine/models/scorecard_model.dart';
import '../../../../core/cricket_engine/engine/scorecard_engine.dart';
import '../../../../core/cricket_engine/adapter/scorecard_adapter.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/match_model.dart';
import 'match_detail_page_comprehensive.dart'; // Reuse UI components

/// Test page using new ScorecardEngine
/// This page uses the new engine logic but reuses existing UI components
class TestMatchDetailPage extends ConsumerStatefulWidget {
  final String matchId;

  const TestMatchDetailPage({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<TestMatchDetailPage> createState() =>
      _TestMatchDetailPageState();
}

class _TestMatchDetailPageState extends ConsumerState<TestMatchDetailPage> {
  ScorecardModel? _firstInningsScorecard;
  ScorecardModel? _secondInningsScorecard;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScorecard();
  }

  Future<void> _loadScorecard() async {
    try {
      final matchRepo = ref.read(matchRepositoryProvider);
      final match = await matchRepo.getMatchById(widget.matchId);

      if (match == null || !mounted) return;

      final scorecard = match.scorecard;
      if (scorecard == null) {
        setState(() {
          _isLoading = false;
          _error = 'No scorecard data available';
        });
        return;
      }

      // Load deliveries
      final firstInningsDeliveriesJson =
          scorecard['first_innings_deliveries'] as List<dynamic>? ?? [];
      final currentDeliveriesJson =
          scorecard['deliveries'] as List<dynamic>? ?? [];

      // Convert to DeliveryModel
      final firstInningsDeliveries =
          ScorecardAdapter.deliveriesFromJson(firstInningsDeliveriesJson);
      final currentDeliveries =
          ScorecardAdapter.deliveriesFromJson(currentDeliveriesJson);

      // Calculate scorecards using new engine
      final currentInnings = (scorecard['current_innings'] as num?)?.toInt() ?? 1;
      final isSuperOver = scorecard['is_super_over'] as bool? ?? false;
      final superOverNumber = (scorecard['super_over_number'] as num?)?.toInt();

      // Get team names
      final team1Name = match.team1Name ?? 'Team 1';
      final team2Name = match.team2Name ?? 'Team 2';

      // Calculate first innings
      if (firstInningsDeliveries.isNotEmpty) {
        _firstInningsScorecard = ScorecardEngine.calculateScorecard(
          deliveries: firstInningsDeliveries,
          teamName: team1Name,
          isSuperOver: isSuperOver && superOverNumber == 1,
          superOverNumber: isSuperOver && superOverNumber == 1 ? 1 : null,
        );
      }

      // Calculate current/second innings
      if (currentDeliveries.isNotEmpty) {
        final teamName = currentInnings == 1 ? team1Name : team2Name;
        _secondInningsScorecard = ScorecardEngine.calculateScorecard(
          deliveries: currentDeliveries,
          teamName: teamName,
          isSuperOver: isSuperOver && superOverNumber == 2,
          superOverNumber: isSuperOver && superOverNumber == 2 ? 2 : null,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading scorecard: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Match Details')),
        body: Center(child: Text(_error!)),
      );
    }

    // Reuse the existing UI but with new engine data
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Match Details (New Engine)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_firstInningsScorecard != null) ...[
              _buildScorecardSection('FIRST INNINGS', _firstInningsScorecard!),
              const SizedBox(height: 24),
            ],
            if (_secondInningsScorecard != null) ...[
              _buildScorecardSection('SECOND INNINGS', _secondInningsScorecard!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardSection(String title, ScorecardModel scorecard) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${scorecard.teamName}: ${scorecard.totalRuns}/${scorecard.totalWickets} '
              '(${scorecard.formattedOvers} Ov)',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildBattingTable(scorecard.battingStats),
            const SizedBox(height: 16),
            _buildBowlingTable(scorecard.bowlingStats),
            const SizedBox(height: 16),
            _buildExtrasSection(scorecard.extras),
            if (scorecard.fallOfWickets.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildFallOfWickets(scorecard.fallOfWickets),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBattingTable(List<BattingStat> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BATTING',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
          },
          children: [
            const TableRow(
              children: [
                Text('Batter', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('R', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('B', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('4s', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('6s', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('SR', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            ...stats.map((stat) => TableRow(
                  children: [
                    Text('${stat.playerName}${stat.isNotOut ? '*' : ''}'),
                    Text(stat.runs.toString()),
                    Text(stat.balls.toString()),
                    Text(stat.fours.toString()),
                    Text(stat.sixes.toString()),
                    Text(stat.strikeRate.toStringAsFixed(1)),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildBowlingTable(List<BowlingStat> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BOWLING',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1),
          },
          children: [
            const TableRow(
              children: [
                Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('O', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('R', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Eco', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            ...stats.map((stat) => TableRow(
                  children: [
                    Text(stat.bowlerName),
                    Text(stat.formattedOvers),
                    Text(stat.maidens.toString()),
                    Text(stat.runs.toString()),
                    Text(stat.wickets.toString()),
                    Text(stat.economy.toStringAsFixed(1)),
                  ],
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildExtrasSection(ExtrasBreakdown extras) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXTRAS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Wides: ${extras.wides}, No Balls: ${extras.noBalls}, '
          'Byes: ${extras.byes}, Leg Byes: ${extras.legByes}',
        ),
        Text('Total Extras: ${extras.total}'),
      ],
    );
  }

  Widget _buildFallOfWickets(List<FallOfWicket> fallOfWickets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FALL OF WICKETS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...fallOfWickets.map((fow) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${fow.wicketNumber}. ${fow.player} ${fow.runs}/${fow.wicketNumber} '
                '(${fow.formattedOvers} Ov) - ${fow.dismissalType}',
              ),
            )),
      ],
    );
  }
}

