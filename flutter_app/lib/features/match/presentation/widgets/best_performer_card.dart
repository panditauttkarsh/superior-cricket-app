import 'package:flutter/material.dart';
import '../../../../core/models/mvp_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact card for Best Batsman or Best Bowler
class BestPerformerCard extends StatelessWidget {
  final PlayerMvpModel mvpData;
  final String performerType; // 'batsman' or 'bowler'
  final VoidCallback? onTap;

  const BestPerformerCard({
    super.key,
    required this.mvpData,
    required this.performerType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isBatsman = performerType == 'batsman';
    final gradientColors = isBatsman
        ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
        : [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
    
    final title = isBatsman ? 'Best Batsman' : 'Best Bowler';
    
    // Calculate overs from balls for bowler
    String primaryStat;
    if (isBatsman) {
      primaryStat = '${mvpData.runsScored}(${mvpData.ballsFaced})';
    } else {
      final overs = mvpData.ballsBowled ~/ 6;
      final remainingBalls = mvpData.ballsBowled % 6;
      final overString = remainingBalls > 0 ? '$overs.$remainingBalls' : '$overs';
      primaryStat = '$overString-${mvpData.runsConceded}-${mvpData.wicketsTaken}';
    }

    final secondaryStat = isBatsman
        ? mvpData.strikeRate != null ? 'SR: ${mvpData.strikeRate!.toStringAsFixed(1)}' : ''
        : mvpData.bowlingEconomy != null ? 'Eco: ${mvpData.bowlingEconomy!.toStringAsFixed(2)}' : '';

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.85, // Slightly shorter than 0.80
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Top Image Section (similar to Player of the Match)
              Expanded(
                flex: 2, // Image section (67%)
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Player Avatar as Background
                    if (mvpData.playerAvatar != null)
                      Image.network(
                        mvpData.playerAvatar!,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatarBg(gradientColors),
                      )
                    else
                      _buildDefaultAvatarBg(gradientColors),
                    
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.5, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                    // Title Text at Bottom of Image
                    Positioned(
                      bottom: 6,
                      left: 10,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom Info Section
              Expanded(
                flex: 1, // Content section (33%)
                child: ClipRect(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Name and Team
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Player Name
                            Text(
                              mvpData.playerName,
                              style: TextStyle(
                                fontSize: 15, // Updated to 15 as requested
                                fontWeight: FontWeight.bold,
                                color: gradientColors[0],
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Team Name
                            Text(
                              mvpData.teamName,
                              style: TextStyle(
                                fontSize: 11, // Updated to 11 as requested
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              primaryStat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (secondaryStat.isNotEmpty)
                              Text(
                                secondaryStat,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatarBg(List<Color> gradientColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white.withOpacity(0.5),
          size: 60,
        ),
      ),
    );
  }

}
