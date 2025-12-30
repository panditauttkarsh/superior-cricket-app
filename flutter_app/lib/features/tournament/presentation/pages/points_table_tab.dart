import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PointsTableTab extends StatelessWidget {
  final String tournamentId;

  const PointsTableTab({
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
            Icons.table_chart,
            size: 64,
            color: AppColors.textMeta,
          ),
          const SizedBox(height: 16),
          Text(
            'Points table will be displayed here',
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

