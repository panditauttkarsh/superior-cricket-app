import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LeaderboardTab extends StatelessWidget {
  final String tournamentId;

  const LeaderboardTab({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: AppColors.textMeta,
          ),
          const SizedBox(height: 16),
          Text(
            'Leaderboard will be displayed here',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSec,
            ),
          ),
        ],
      ),
    );
  }
}

