import 'package:flutter/material.dart';
import '../../../../core/models/mvp_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Premium MVP Award Card Widget
class MvpAwardCard extends StatelessWidget {
  final PlayerMvpModel mvpData;
  final bool isPlayerOfTheMatch;
  final VoidCallback? onTap;

  const MvpAwardCard({
    super.key,
    required this.mvpData,
    this.isPlayerOfTheMatch = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isPlayerOfTheMatch
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isPlayerOfTheMatch
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            
            // MVP Score Section
            _buildMvpScore(),
            
            // Performance Breakdown
            _buildPerformanceBreakdown(),
            
            // Stats Section
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final textColor = isPlayerOfTheMatch ? Colors.white : Colors.black87;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Player Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isPlayerOfTheMatch ? Colors.white : AppColors.primary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: mvpData.playerAvatar != null
                  ? Image.network(
                      mvpData.playerAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mvpData.playerName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPlayerOfTheMatch)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '👑',
                              style: TextStyle(fontSize: 12),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'POTM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mvpData.teamName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: isPlayerOfTheMatch ? Colors.white.withOpacity(0.2) : Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 30,
        color: isPlayerOfTheMatch ? Colors.white : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildMvpScore() {
    final textColor = isPlayerOfTheMatch ? Colors.white : Colors.black87;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            'MVP SCORE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                mvpData.formattedMvpScore,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  mvpData.performanceEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            mvpData.performanceGrade,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBreakdown() {
    final breakdown = mvpData.getMvpBreakdown();
    final textColor = isPlayerOfTheMatch ? Colors.white : Colors.black87;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPlayerOfTheMatch
            ? Colors.white.withOpacity(0.15)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERFORMANCE BREAKDOWN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          
          // Batting
          _buildBreakdownItem(
            icon: '🏏',
            label: 'Batting',
            value: mvpData.battingMvp.toStringAsFixed(2),
            percentage: breakdown['batting']!,
            color: const Color(0xFF10B981),
            textColor: textColor,
          ),
          
          const SizedBox(height: 8),
          
          // Bowling
          _buildBreakdownItem(
            icon: '⚡',
            label: 'Bowling',
            value: mvpData.bowlingMvp.toStringAsFixed(2),
            percentage: breakdown['bowling']!,
            color: const Color(0xFF3B82F6),
            textColor: textColor,
          ),
          
          const SizedBox(height: 8),
          
          // Fielding
          _buildBreakdownItem(
            icon: '🧤',
            label: 'Fielding',
            value: mvpData.fieldingMvp.toStringAsFixed(2),
            percentage: breakdown['fielding']!,
            color: const Color(0xFFF59E0B),
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String icon,
    required String label,
    required String value,
    required double percentage,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: isPlayerOfTheMatch
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final textColor = isPlayerOfTheMatch ? Colors.white : Colors.black87;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Runs',
            value: mvpData.runsScored.toString(),
            textColor: textColor,
          ),
          _buildStatItem(
            label: 'Wickets',
            value: mvpData.wicketsTaken.toString(),
            textColor: textColor,
          ),
          _buildStatItem(
            label: 'Catches',
            value: mvpData.catches.toString(),
            textColor: textColor,
          ),
          if (mvpData.strikeRate != null)
            _buildStatItem(
              label: 'SR',
              value: mvpData.strikeRate!.toStringAsFixed(1),
              textColor: textColor,
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
