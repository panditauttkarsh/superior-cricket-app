import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsDialog extends StatefulWidget {
  const NotificationsDialog({super.key});

  @override
  State<NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<NotificationsDialog> {
  String _selectedTab = 'All';

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
        'isUnread': true,
        'isInvitation': false,
      },
      {
        'type': 'achievement',
        'title': 'New Achievement',
        'message': 'You scored your first century! 🎉',
        'time': '5h ago',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
        'isUnread': true,
        'isInvitation': false,
      },
      {
        'type': 'award',
        'title': 'Award Received',
        'message': 'Best Bowler of the Month - Congratulations!',
        'time': '1d ago',
        'icon': Icons.military_tech,
        'color': Colors.purple,
        'isUnread': true,
        'isInvitation': true,
      },
      {
        'type': 'match',
        'title': 'Match Reminder',
        'message': 'Weekend Warriors Cup match tomorrow at 3:00 PM',
        'time': '2d ago',
        'icon': Icons.calendar_today,
        'color': Colors.green,
        'isUnread': false,
        'isInvitation': false,
      },
      {
        'type': 'achievement',
        'title': 'Milestone Reached',
        'message': 'You\'ve completed 50 matches! Keep it up!',
        'time': '3d ago',
        'icon': Icons.star,
        'color': Colors.orange,
        'isUnread': false,
        'isInvitation': false,
      },
    ];

    final filteredNotifications = _selectedTab == 'All'
        ? notifications
        : notifications.where((n) => n['isUnread'] == true).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  // Tabs
                  Row(
                    children: [
                      _buildTab('All', _selectedTab == 'All'),
                      const SizedBox(width: 16),
                      _buildTab('Unread', _selectedTab == 'Unread'),
                    ],
                  ),
                ],
              ),
            ),
            // Notifications List
            Flexible(
              child: filteredNotifications.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No notifications',
                          style: TextStyle(
                            color: AppColors.textMeta,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filteredNotifications.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final notification = filteredNotifications[index];
                        return _buildNotificationItem(
                          context,
                          notification['title'] as String,
                          notification['message'] as String,
                          notification['time'] as String,
                          notification['icon'] as IconData,
                          notification['color'] as Color,
                          notification['isUnread'] as bool,
                          notification['isInvitation'] as bool,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.textMain : AppColors.textMeta,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontFamily: 'Inter',
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
    bool isUnread,
    bool isInvitation,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Time Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textMain,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                color: AppColors.textMeta,
                                fontSize: 12,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      message,
                      style: TextStyle(
                        color: AppColors.textSec,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        height: 1.4,
                      ),
                    ),
                    // Invitation Buttons
                    if (isInvitation) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Decline logic
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(
                                  color: AppColors.borderLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Decline',
                                style: TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Accept logic
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textMain,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

