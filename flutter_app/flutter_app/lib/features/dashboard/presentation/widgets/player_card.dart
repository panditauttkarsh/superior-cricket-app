import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final String role;
  final int matches;
  final int? runs;
  final int? wickets;
  final double avg;
  final bool isFollowing;

  const PlayerCard({
    super.key,
    required this.name,
    required this.role,
    required this.matches,
    this.runs,
    this.wickets,
    required this.avg,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF334155),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF1B5E20),
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatChip('Matches', matches.toString()),
                      const SizedBox(width: 8),
                      if (runs != null)
                        _buildStatChip('Runs', runs.toString())
                      else if (wickets != null)
                        _buildStatChip('Wickets', wickets.toString()),
                      const SizedBox(width: 8),
                      _buildStatChip('Avg', avg.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Button
            ElevatedButton(
              onPressed: () {
                // View profile or follow/unfollow
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Colors.grey[700]
                    : const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
        ),
      ),
    );
  }
}

