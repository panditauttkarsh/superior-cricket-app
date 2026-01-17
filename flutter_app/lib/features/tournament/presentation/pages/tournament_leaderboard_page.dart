import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/mvp_model.dart';
import '../../../../core/providers/repository_providers.dart';

/// Provider for tournament leaderboard data
final tournamentLeaderboardProvider = FutureProvider.autoDispose.family<
  Map<String, List<PlayerMvpModel>>, 
  String
>((ref, tournamentId) async {
  final mvpRepo = ref.watch(mvpRepositoryProvider);
  
  // Get all MVP data for the tournament (aggregated across all matches)
  final allMvpData = await mvpRepo.getTournamentMvpData(tournamentId);
  
  if (allMvpData.isEmpty) {
    return {
      'mvp': [],
      'batting': [],
      'bowling': [],
    };
  }
  
  // Sort by different criteria
  final mvpList = List<PlayerMvpModel>.from(allMvpData)
    ..sort((a, b) => b.totalMvp.compareTo(a.totalMvp));
  
  final battingList = List<PlayerMvpModel>.from(allMvpData)
    ..sort((a, b) => b.battingMvp.compareTo(a.battingMvp));
  
  final bowlingList = List<PlayerMvpModel>.from(allMvpData)
    ..sort((a, b) => b.bowlingMvp.compareTo(a.bowlingMvp));
  
  return {
    'mvp': mvpList,
    'batting': battingList,
    'bowling': bowlingList,
  };
});

class TournamentLeaderboardPage extends ConsumerStatefulWidget {
  final String tournamentId;
  
  const TournamentLeaderboardPage({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentLeaderboardPage> createState() => _TournamentLeaderboardPageState();
}

class _TournamentLeaderboardPageState extends ConsumerState<TournamentLeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(tournamentLeaderboardProvider(widget.tournamentId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tournament Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'MVP'),
            Tab(text: 'Batting'),
            Tab(text: 'Bowling'),
          ],
        ),
      ),
      body: leaderboardAsync.when(
        data: (data) {
          final mvpList = data['mvp'] ?? [];
          final battingList = data['batting'] ?? [];
          final bowlingList = data['bowling'] ?? [];

          if (mvpList.isEmpty && battingList.isEmpty && bowlingList.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'How is Most Valuable Players Calculated?',
                    style: TextStyle(fontSize: 11, color: Colors.teal[600], fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardList(mvpList, 'mvp'),
                    _buildLeaderboardList(battingList, 'batting'),
                    _buildLeaderboardList(bowlingList, 'bowling'),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text('No leaderboard data found', style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<PlayerMvpModel> players, String type) {
    if (players.isEmpty) {
      return Center(child: Text('No $type data found', style: const TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: players.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        return _buildExpandableLeaderboardRow(players[index], index + 1, type);
      },
    );
  }

  Widget _buildExpandableLeaderboardRow(PlayerMvpModel player, int rank, String type) {
    double score = type == 'mvp' 
        ? player.totalMvp 
        : type == 'batting' 
            ? player.battingMvp 
            : player.bowlingMvp;

    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox(
        width: 80,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: rank <= 3 ? Border.all(color: Colors.red, width: 1.5) : null,
              ),
              child: ClipOval(
                child: player.playerAvatar != null
                    ? Image.network(player.playerAvatar!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          player.playerName[0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: rank <= 3 ? Colors.red : Colors.grey, fontSize: 18),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.playerName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            player.teamName.toUpperCase(),
            style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[500], letterSpacing: 0.5),
          ),
        ],
      ),
      trailing: Text(
        score.toStringAsFixed(3),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          color: Colors.grey[50],
          child: Column(
            children: [
              const Divider(),
              const SizedBox(height: 8),
              if (type == 'mvp')
                Text(
                  'Batting: ${player.battingMvp.toStringAsFixed(3)} + Bowling: ${player.bowlingMvp.toStringAsFixed(3)} + Fielding: ${player.fieldingMvp.toStringAsFixed(3)} = ${player.totalMvp.toStringAsFixed(3)}',
                  style: TextStyle(fontSize: 11, color: Colors.teal[700], fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMiniStatBox('Batting', [
                    _miniStat('R', '${player.runsScored}'),
                    _miniStat('B', '${player.ballsFaced}'),
                    _miniStat('SR', player.strikeRate?.toStringAsFixed(1) ?? '-'),
                  ])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStatBox('Bowling', [
                    _miniStat('W', '${player.wicketsTaken}'),
                    _miniStat('R', '${player.runsConceded}'),
                    _miniStat('EC', player.bowlingEconomy?.toStringAsFixed(1) ?? '-'),
                  ])),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMiniStatBox('Fielding', [
                    _miniStat('C', '${player.catches}'),
                    _miniStat('RO', '${player.runOuts}'),
                    _miniStat('ST', '${player.stumpings}'),
                  ])),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatBox(String title, List<Widget> stats) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 8),
          ...stats,
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
