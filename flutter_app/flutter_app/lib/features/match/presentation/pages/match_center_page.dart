import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class MatchCenterPage extends StatefulWidget {
  const MatchCenterPage({super.key});

  @override
  State<MatchCenterPage> createState() => _MatchCenterPageState();
}

class _MatchCenterPageState extends State<MatchCenterPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7), // background-light
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        
                        // Live Match Card 1
                        _buildLiveMatchCard(
                          isLive: true,
                          innings: '1st Innings',
                          team1Name: 'Mumbai Indians',
                          team1Score: '142',
                          team1Wickets: '3',
                          team1Overs: '16.4 ov',
                          runRate: 'RR: 8.68',
                          team2Name: 'Chennai Kings',
                          team2Target: 'Target: 143',
                          team2Score: '0/0',
                          team2Overs: '0.0 ov',
                          progress: 0.75,
                          projectedScore: 'Projected: 168',
                          winProb: 'Win Prob: 62%',
                          winProbColor: const Color(0xFFC72B32),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Live Match Card 2
                        _buildLiveMatchCard(
                          isLive: true,
                          innings: '2nd Innings',
                          team1Name: 'Royal Challengers',
                          team1Score: '89',
                          team1Wickets: '1',
                          team1Overs: '9.2 ov',
                          runRate: 'RR: 9.54',
                          team2Name: 'Delhi Caps',
                          team2Target: 'Target: 192',
                          team2Score: '',
                          team2Overs: 'Needs 103 off 64 balls',
                          progress: 0.45,
                          projectedScore: 'Req RR: 9.65',
                          winProb: 'Win Prob: 48%',
                          winProbColor: AppColors.primary,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Upcoming Match Card
                        _buildUpcomingMatchCard(),
                        
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7).withOpacity(0.8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const Expanded(
            child: Text(
              'Match Center',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, size: 20),
            color: Colors.grey[600],
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard({
    required bool isLive,
    required String innings,
    required String team1Name,
    required String team1Score,
    required String team1Wickets,
    required String team1Overs,
    required String runRate,
    required String team2Name,
    required String team2Target,
    required String team2Score,
    required String team2Overs,
    required double progress,
    required String projectedScore,
    required String winProb,
    required Color winProbColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background glow effect
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              // Header with LIVE badge and innings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Pulsing LIVE indicator
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC72B32).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC72B32),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFFC72B32),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      innings,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Match Score Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Team 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team1Name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              team1Score,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '/$team1Wickets',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '($team1Overs) • $runRate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // VS
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  
                  // Team 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          team2Name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          team2Target,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          team2Score.isNotEmpty ? '$team2Score ($team2Overs)' : team2Overs,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Progress Bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: progress > 0.5 ? AppColors.primary : const Color(0xFFC72B32),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    if (progress > 0.5)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Projected and Win Prob
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    projectedScore,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    winProb,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: winProbColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // View Full Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/matches/1'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'View Full Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatchCard() {
    return Opacity(
      opacity: 0.9,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UPCOMING • TODAY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '7:30 PM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Team 1
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'SRH',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Sunrisers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // VS
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
                // Team 2
                Row(
                  children: [
                    const Text(
                      'Knights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'KKR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Match Preview',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', false, () => context.go('/')),
              _buildNavItem(Icons.sports_cricket, 'Matches', true, () {}),
              const SizedBox(width: 60), // Space for center button
              _buildNavItem(Icons.leaderboard, 'Stats', false, () {}),
              _buildNavItem(Icons.person, 'Profile', false, () => context.go('/profile')),
            ],
          ),
          // Center Add Button
          Center(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          // Bottom indicator
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 128,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Icon(
            icon,
            color: isActive ? AppColors.primary : Colors.grey[400],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
