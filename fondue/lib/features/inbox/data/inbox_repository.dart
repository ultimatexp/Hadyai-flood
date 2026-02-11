import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notification.dart';

class InboxRepository {
  final SupabaseClient _client;

  InboxRepository(this._client);

  Future<List<AppNotification>> fetchNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => AppNotification.fromJson(data))
          .toList();
    } catch (e) {
      // If table doesn't exist or error, return empty list (or throw)
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}
