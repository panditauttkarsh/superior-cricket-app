import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/mvp_model.dart';
import './tournament_leaderboard_page.dart';

class StatsTab extends ConsumerWidget {
  final String tournamentId;

  const StatsTab({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(tournamentLeaderboardProvider(tournamentId));

    return leaderboardAsync.when(
      data: (data) {
        final players = data['mvp'] ?? [];

        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No player statistics available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: players.length,
          itemBuilder: (context, index) {
            return _buildStatBox(players[index], index + 1);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildStatBox(PlayerMvpModel player, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            '#$rank',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.playerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              player.teamName,
              style: TextStyle(fontSize: 11, color: AppColors.textSec),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            player.totalMvp.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildStatGrid('Cricket Batting', '🏏', [
                  _miniStat('R', '${player.runsScored}'),
                  _miniStat('B', '${player.ballsFaced}'),
                  _miniStat('SR', player.strikeRate?.toStringAsFixed(1) ?? '-'),
                  _miniStat('MVP', player.battingMvp.toStringAsFixed(1), highlight: true),
                ]),
                const SizedBox(height: 16),
                _buildStatGrid('Bowling', '⚾', [
                  _miniStat('W', '${player.wicketsTaken}'),
                  _miniStat('R', '${player.runsConceded}'),
                  _miniStat('EC', player.bowlingEconomy?.toStringAsFixed(1) ?? '-'),
                  _miniStat('MVP', player.bowlingMvp.toStringAsFixed(1), highlight: true),
                ]),
                const SizedBox(height: 16),
                _buildStatGrid('Fielding', '🧤', [
                  _miniStat('CT', '${player.catches}'),
                  _miniStat('RO', '${player.runOuts}'),
                  _miniStat('ST', '${player.stumpings}'),
                  _miniStat('MVP', player.fieldingMvp.toStringAsFixed(1), highlight: true),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(String title, String icon, List<Widget> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stats,
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, {bool highlight = false}) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 13,
              color: highlight ? AppColors.primary : AppColors.textMain,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
