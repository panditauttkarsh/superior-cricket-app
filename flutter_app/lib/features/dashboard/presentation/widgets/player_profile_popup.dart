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
          height: size.height * 0.7, // Reduced height to 70%
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A), // Navy Blue
                Color(0xFF1E40AF), // Royal Navy
                Color(0xFF2563EB), // Light Navy Blue
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
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling as requested
                  padding: const EdgeInsets.only(bottom: 12),
                  child: playerAsyncValue.when(
                    data: (PlayerModel? playerData) {
                      final battingStats = playerData?.battingStats ?? {};
                      final isPro = playerData?.subscriptionPlan?.toUpperCase() == 'PRO';
                      
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
                                      width: 105, // Slightly adjusted for better fit
                                      height: 105, 
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
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
                                      width: 86, // Slightly adjusted
                                      height: 86,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            playerData?.profileImageUrl ?? authUser?.avatar ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${authUser?.email ?? 'User'}',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10), // Tighter
                                // Name
                                Text(
                                  (playerData?.name ?? authUser?.name ?? authUser?.email?.split('@')[0] ?? 'Player Name').toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20, // Slightly smaller
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8), // Tighter
                                
                                // Membership Status Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: isPro ? const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                    ) : null,
                                    color: isPro ? null : Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: isPro ? Border.all(color: Colors.white.withOpacity(0.5), width: 1) : null,
                                    boxShadow: isPro ? [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ] : null,
                                  ),
                                  child: Text(
                                    isPro ? 'PRO MEMBER' : 'BASIC MEMBER',
                                    style: TextStyle(
                                      color: isPro ? Colors.black87 : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16), // Tighter

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
      padding: const EdgeInsets.symmetric(vertical: 9), // Further reduced height to hit the fit
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
              fontSize: 13, // Slightly smaller
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15, // Slightly smaller
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
