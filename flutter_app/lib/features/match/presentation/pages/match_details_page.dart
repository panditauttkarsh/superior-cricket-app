import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/mvp_model.dart';

class MatchDetailsPage extends ConsumerStatefulWidget {
  final String matchId;
  
  const MatchDetailsPage({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends ConsumerState<MatchDetailsPage> {
  List<PlayerMvpModel> _mvpData = [];
  bool _isLoadingMvp = true;

  @override
  void initState() {
    super.initState();
    _fetchMvpData();
  }

  Future<void> _fetchMvpData() async {
    try {
      final mvpRepo = ref.read(mvpRepositoryProvider);
      final data = await mvpRepo.getMatchMvpData(widget.matchId);
      setState(() {
        _mvpData = data;
        _isLoadingMvp = false;
      });
    } catch (e) {
      debugPrint('Error fetching MVP: $e');
      setState(() {
        _isLoadingMvp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6, // Added Summary tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match Details'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Summary'),
              Tab(text: 'Info'),
              Tab(text: 'Squads'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Commentary'),
              Tab(text: 'Timeline'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSummary(),
            _buildInfo(),
            _buildSquads(),
            _buildScorecard(),
            _buildCommentary(),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    if (_isLoadingMvp) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_mvpData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: AppColors.textMeta,
            ),
            const SizedBox(height: 16),
            Text(
              'MVP data not available',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMeta,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Player statistics will be calculated\nautomatically in future matches',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMeta,
              ),
            ),
          ],
        ),
      );
    }

    // Get Player of the Match
    final potm = _mvpData.firstWhere(
      (p) => p.isPlayerOfTheMatch == true,
      orElse: () => _mvpData.first,
    );

    // Get top 5 performers
    final topPerformers = _mvpData.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player of the Match
          _buildPotmCard(potm),
          
          const SizedBox(height: 24),
          
          // Top Performers Header
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Top Performers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Top performers list
          ...topPerformers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return _buildMvpCard(player, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildPotmCard(PlayerMvpModel player) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player of the Match',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMeta,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.playerName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGradeColor(player.performanceGrade),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.performanceGrade,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // MVP Breakdown
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total MVP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      player.totalMvp.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMvpBreakdownRow('🏏 Batting', player.battingMvp),
                _buildMvpBreakdownRow('⚾ Bowling', player.bowlingMvp),
                _buildMvpBreakdownRow('🧤 Fielding', player.fieldingMvp),
              ],
            ),
          ),
          
          if (player.runsScored > 0 || player.wicketsTaken > 0 || player.catches > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (player.runsScored > 0)
                  _buildStatChip('${player.runsScored} runs', Icons.sports_cricket),
                if (player.wicketsTaken > 0)
                  _buildStatChip('${player.wicketsTaken} wickets', Icons.sports_baseball),
                if (player.catches > 0)
                  _buildStatChip('${player.catches} catches', Icons.sports_handball),
                if (player.runOuts > 0)
                  _buildStatChip('${player.runOuts} run-outs', Icons.directions_run),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMvpBreakdownRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSec,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMvpCard(PlayerMvpModel player, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.textMeta.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? AppColors.primary : AppColors.textMeta,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Player Avatar
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              player.playerName[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.playerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'B: ${player.battingMvp.toStringAsFixed(1)} • Bo: ${player.bowlingMvp.toStringAsFixed(1)} • F: ${player.fieldingMvp.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSec,
                  ),
                ),
              ],
            ),
          ),
          
          // MVP Score and Grade
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                player.totalMvp.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getGradeColor(player.performanceGrade),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  player.performanceGrade,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'S': return const Color(0xFFFFD700); // Gold
      case 'A': return const Color(0xFF00D9FF); // Cyan
      case 'B': return const Color(0xFF00FF88); // Green
      case 'C': return const Color(0xFFFFA500); // Orange
      default: return AppColors.textMeta;
    }
  }

  Widget _buildInfo() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Match Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Date: March 15, 2024'),
              Text('Type: T20'),
              Text('Venue: Wankhede Stadium, Mumbai'),
              Text('Status: Completed'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquads() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Team 1 Squad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...List.generate(11, (index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('Player ${index + 1}'),
          subtitle: const Text('Batsman'),
        )),
      ],
    );
  }

  Widget _buildScorecard() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Scorecard details...'),
        ),
      ),
    );
  }

  Widget _buildCommentary() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text('16.$index'),
            title: const Text('FOUR! Beautiful cover drive.'),
            trailing: const Text('+4', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.event, color: Colors.white),
            ),
            title: Text('Event ${index + 1}'),
            subtitle: const Text('Match event description'),
            trailing: const Text('14:30'),
          ),
        );
      },
    );
  }
}
