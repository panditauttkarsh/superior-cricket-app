import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/models/mvp_model.dart';
import '../../../../core/theme/app_colors.dart';

enum MvpStatDisplayMode { all, battingOnly, bowlingOnly }

/// Premium MVP Award Card Widget
class MvpAwardCard extends StatelessWidget {
  final PlayerMvpModel mvpData;
  final bool isPlayerOfTheMatch;
  final VoidCallback? onTap;
  final bool isCompact;
  final String? customBadgeText;
  final MvpStatDisplayMode statDisplayMode;

  const MvpAwardCard({
    super.key,
    required this.mvpData,
    this.isPlayerOfTheMatch = false,
    this.onTap,
    this.isCompact = false,
    this.customBadgeText,
    this.statDisplayMode = MvpStatDisplayMode.all,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPlayerOfTheMatch && !isCompact && customBadgeText == null) {
       // Return compact card for list if it's not a special card
       return _buildCompactCard();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 12, 
          vertical: 8
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP SECTION: Player Image & Badge
            SizedBox(
              height: isCompact ? 130 : 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Image Layers (Blurred Background + Sharp Foreground)
                  if (mvpData.playerAvatar != null) ...[
                    // Layer 1: Blurred Background (Zoomed to fill)
                    Image.network(
                      mvpData.playerAvatar!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                    ),
                    ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                        child: Container(
                          color: Colors.black.withOpacity(0.05), // Darker subtle overlay to reduce white washout
                        ),
                      ),
                    ),
                    
                    // Layer 2: Main Image (Contained but scaled up 35%)
                    Transform.scale(
                      scale: 1.35,
                      alignment: Alignment.bottomCenter,
                      child: Image.network(
                        mvpData.playerAvatar!,
                         fit: BoxFit.contain,
                         alignment: Alignment.bottomCenter,
                         errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                      ),
                    ),
                  ] else
                    _buildDefaultAvatar(),
                  
                  // 2. Badge Overlay (Bottom Left of Image)
                  if (customBadgeText != null || isPlayerOfTheMatch)
                  Positioned(
                    bottom: isCompact ? 8 : 12,
                    left: isCompact ? 8 : 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        customBadgeText ?? 'PLAYER OF THE MATCH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 8 : 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BOTTOM SECTION: Content & Stats
            Container(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Name + MVP Points
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player Name & Team
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                mvpData.playerName,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: isCompact ? 15 : 22, // Reduced from 18 to 15
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mvpData.teamName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: isCompact ? 11 : 14, // Reduced from 12 to 11
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // MVP Points (Top Right)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'MVP',
                              style: TextStyle(
                                fontSize: isCompact ? 9 : 10, // Reduced from 10 to 9
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            Text(
                              mvpData.formattedMvpScore,
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 20, // Reduced from 16 to 14
                                fontWeight: FontWeight.w900,
                                color: Colors.orange.shade900,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    // Divider
                    Divider(height: 1, color: Colors.grey.shade200),
                    const SizedBox(height: 12),

                    // Stats Line
                    _buildStatsLine(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildStatsLine() {
       String statsText = '';

       final battingStats = '${mvpData.runsScored}${mvpData.isNotOut ? '*' : ''}(${mvpData.ballsFaced})';
       final bowlingStats = '${(mvpData.ballsBowled ~/ 6)}.${mvpData.ballsBowled % 6} - ${mvpData.runsConceded} - ${mvpData.wicketsTaken}';

       switch (statDisplayMode) {
         case MvpStatDisplayMode.battingOnly:
           statsText = '🏏 $battingStats';
           break;
         case MvpStatDisplayMode.bowlingOnly:
           statsText = '⚾ $bowlingStats';
           break;
         case MvpStatDisplayMode.all:
         default:
           statsText = '$battingStats | $bowlingStats';
           break;
       }

        return Text(
          statsText,
          style: TextStyle(
            fontSize: isCompact ? 12 : 16, // Reduced from 14 to 12
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
  }

  // Keep old design for non-POTM cards (Top Performers list) to ensure they fit in the list
  Widget _buildCompactCard() {
    return Container(
      width: 160,
      height: 220, // Added fixed height to prevent Expanded crash in unbounded vertical lists
      margin: const EdgeInsets.only(right: 12, bottom: 12), // Added bottom margin for vertical stacking
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
           )
        ]
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: mvpData.playerAvatar != null 
                  ? Image.network(mvpData.playerAvatar!, fit: BoxFit.cover, width: double.infinity)
                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.person, size: 40, color: Colors.grey)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mvpData.playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('MVP: ${mvpData.formattedMvpScore}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w900)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(
          Icons.person,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }
}
