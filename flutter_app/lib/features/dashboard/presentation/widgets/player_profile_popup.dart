import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/player_model.dart';

class PlayerProfilePopup extends ConsumerWidget {
  const PlayerProfilePopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).user;
    final playerAsyncValue = ref.watch(playerDataProvider);
    final size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.85,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B5CF6), // Bright Purple
                Color(0xFF6D28D9), // Deep Purple
                Color(0xFF4C1D95), // Darkest Purple
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Bar with Close Button
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: playerAsyncValue.when(
                    data: (PlayerModel? playerData) {
                      final battingStats = playerData?.battingStats ?? {};
                      
                      return Column(
                        children: [
                          // Profile Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                // Profile Image with Animated/Dotted Border
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Dotted border effect
                                    Container(
                                      width: 120, // Reduced size
                                      height: 120, // Reduced size
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.5),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Actual Image
                                    Container(
                                      width: 95, // Reduced size
                                      height: 95, // Reduced size
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            playerData?.profileImageUrl ?? authUser?.avatar ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=${authUser?.email ?? 'User'}',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16), // Reduced spacing
                                // Name
                                Text(
                                  (playerData?.name ?? authUser?.name ?? authUser?.email?.split('@')[0] ?? 'Player Name').toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24, // Reduced size
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                
                                // Skill/Circle indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildSkillCircle(true),
                                    Container(width: 40, height: 1.5, color: Colors.cyanAccent.withOpacity(0.5)),
                                    _buildSkillCircle(true, isCenter: true),
                                    Container(width: 40, height: 1.5, color: Colors.cyanAccent.withOpacity(0.5)),
                                    _buildSkillCircle(true),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Role
                                Text(
                                  (playerData?.role ?? 'Player').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13, // Reduced size
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Stats Section
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildStatRow('MATCHES', playerData?.totalMatches?.toString() ?? '0'),
                                _buildStatRow('RUNS', battingStats['runs']?.toString() ?? '0'),
                                _buildStatRow('AVERAGE', battingStats['average']?.toString() ?? '0.0'),
                                _buildStatRow('50 / 100', '${battingStats['50s'] ?? 0} / ${battingStats['100s'] ?? 0}'),
                                _buildStatRow('STRIKE RATE', battingStats['strike_rate']?.toString() ?? '0.0'),
                                _buildStatRow('HIGHEST SCORE', battingStats['highest_score']?.toString() ?? '0'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Error loading profile',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
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

  Widget _buildStatRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCircle(bool isActive, {bool isCenter = false}) {
    return Container(
      width: isCenter ? 24 : 32,
      height: isCenter ? 24 : 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCenter ? Colors.cyan : Colors.white.withOpacity(0.2),
        border: Border.all(
          color: isCenter ? Colors.white : Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: isCenter ? [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ] : null,
      ),
      child: isCenter ? Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ) : null,
    );
  }
}

void showPlayerProfilePopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => const PlayerProfilePopup(),
  );
}
