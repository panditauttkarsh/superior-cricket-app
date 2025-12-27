import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsDialog extends StatelessWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'type': 'match',
        'title': 'Upcoming Match',
        'message': 'Your match against Royal Strikers starts in 2 hours',
        'time': '2h ago',
        'icon': Icons.sports_cricket,
        'color': Colors.blue,
      },
      {
        'type': 'achievement',
        'title': 'New Achievement',
        'message': 'You scored your first century! 🎉',
        'time': '5h ago',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
      {
        'type': 'award',
        'title': 'Award Received',
        'message': 'Best Bowler of the Month - Congratulations!',
        'time': '1d ago',
        'icon': Icons.military_tech,
        'color': Colors.purple,
      },
      {
        'type': 'match',
        'title': 'Match Reminder',
        'message': 'Weekend Warriors Cup match tomorrow at 3:00 PM',
        'time': '2d ago',
        'icon': Icons.calendar_today,
        'color': Colors.green,
      },
      {
        'type': 'achievement',
        'title': 'Milestone Reached',
        'message': 'You\'ve completed 50 matches! Keep it up!',
        'time': '3d ago',
        'icon': Icons.star,
        'color': Colors.orange,
      },
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Notifications List
            Expanded(
              child: notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(
                          context,
                          notification['title'] as String,
                          notification['message'] as String,
                          notification['time'] as String,
                          notification['icon'] as IconData,
                          notification['color'] as Color,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String message,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

