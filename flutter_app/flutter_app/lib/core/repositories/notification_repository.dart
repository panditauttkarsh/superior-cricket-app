import 'dart:async';
import '../config/supabase_config.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _supabase = SupabaseConfig.client;

  /// Get all notifications for a user, ordered by newest first
  Future<List<NotificationModel>> getNotificationsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Create a new notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'is_read': false,
        'action_url': actionUrl,
        'metadata': metadata ?? {},
      };

      final response = await _supabase
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return NotificationModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  /// Stream notifications for real-time updates
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => (data as List)
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}

