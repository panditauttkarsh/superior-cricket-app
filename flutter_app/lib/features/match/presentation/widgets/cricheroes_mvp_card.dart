import 'package:flutter/material.dart';
import '../../../../core/models/mvp_model.dart';
import '../../../../core/theme/app_colors.dart';

/// CricHeroes MVP Card - Modern UI matching app design
class CricHeroesMvpCard extends StatelessWidget {
  final PlayerMvpModel mvpData;
  final bool isPlayerOfTheMatch;
  final bool isCompact;
  final String? customBadgeText;

  const CricHeroesMvpCard({
    super.key,
    required this.mvpData,
    this.isPlayerOfTheMatch = false,
    this.isCompact = false,
    this.customBadgeText,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard();
    }

    if (isPlayerOfTheMatch) {
      return _buildPlayerOfTheMatchCard();
    }

    return _buildStandardCard();
  }

  Widget _buildPlayerOfTheMatchCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Player Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                  child: mvpData.playerAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            mvpData.playerAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarInitials(),
                          ),
                        )
                      : _buildAvatarInitials(),
                ),
                const SizedBox(width: 16),
                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PLAYER OF THE MATCH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mvpData.playerName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mvpData.teamName,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSec,
                        ),
                      ),
                    ],
                  ),
                ),
                // MVP Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'MVP',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSec,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mvpData.totalMvp.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildStatsSection(),
          ),
          // Breakdown Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: _buildBreakdownSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.elevated,
            ),
            child: mvpData.playerAvatar != null
                ? ClipOval(
                    child: Image.network(
                      mvpData.playerAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarInitials(compact: true),
                    ),
                  )
                : _buildAvatarInitials(compact: true),
          ),
          const SizedBox(width: 12),
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mvpData.playerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mvpData.teamName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSec,
                  ),
                ),
              ],
            ),
          ),
          // MVP Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mvpData.totalMvp.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'MVP',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSec,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Badge
          if (customBadgeText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                customBadgeText!,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          if (customBadgeText != null) const SizedBox(width: 8),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.elevated,
            ),
            child: mvpData.playerAvatar != null
                ? ClipOval(
                    child: Image.network(
                      mvpData.playerAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarInitials(compact: true),
                    ),
                  )
                : _buildAvatarInitials(compact: true),
          ),
          const SizedBox(width: 10),
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mvpData.playerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  mvpData.teamName,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSec,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // MVP Score
          Text(
            mvpData.totalMvp.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Batting Stats
        if (mvpData.runsScored > 0)
          _buildStatItem(
            label: 'Batting',
            value: '${mvpData.runsScored}${mvpData.isNotOut ? '*' : ''}(${mvpData.ballsFaced})',
            subtitle: mvpData.strikeRate != null
                ? 'SR: ${mvpData.strikeRate!.toStringAsFixed(1)}'
                : null,
          ),
        // Bowling Stats
        if (mvpData.wicketsTaken > 0 || mvpData.ballsBowled > 0)
          _buildStatItem(
            label: 'Bowling',
            value: '${mvpData.wicketsTaken}/${mvpData.runsConceded}',
            subtitle: mvpData.ballsBowled > 0
                ? '${(mvpData.ballsBowled / 6).toStringAsFixed(1)} Ov'
                : null,
          ),
        // Fielding Stats
        if (mvpData.catches > 0 || mvpData.runOuts > 0 || mvpData.stumpings > 0)
          _buildStatItem(
            label: 'Fielding',
            value: '${mvpData.catches + mvpData.runOuts + mvpData.stumpings}',
            subtitle: 'C:${mvpData.catches} RO:${mvpData.runOuts} ST:${mvpData.stumpings}',
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSec,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMeta,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MVP Breakdown',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSec,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBreakdownItem(
                'Batting',
                mvpData.battingMvp,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBreakdownItem(
                'Bowling',
                mvpData.bowlingMvp,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBreakdownItem(
                'Fielding',
                mvpData.fieldingMvp,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSec,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitials({bool compact = false}) {
    final initials = mvpData.playerName
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0].toUpperCase() : '')
        .join();
    
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: compact ? 16 : 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

