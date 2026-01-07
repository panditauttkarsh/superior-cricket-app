import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MatchesTab extends StatelessWidget {
  final String tournamentId;

  const MatchesTab({
    super.key,
    required this.tournamentId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_cricket,
                size: 64,
                color: AppColors.textMeta,
              ),
              const SizedBox(height: 16),
              Text(
                'Matches will be displayed here',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSec,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

