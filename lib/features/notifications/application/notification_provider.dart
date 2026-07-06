import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/models/notification_model.dart';

// Called from main.dart after Firebase gives us a token
Future<void> saveFcmToken(String userId, String token) async {
  try {
    await supabase
        .from('profiles')
        .update({'fcm_token': token}).eq('id', userId);
  } catch (e) {
    // Non-fatal: push notifications just won't reach this device.
    debugPrint('saveFcmToken failed for user $userId: $e');
  }
}

// autoDispose: this realtime subscription otherwise stayed open for the
// whole app session after the first watch, even once the user left the
// Notifications screen.
final notificationsProvider =
StreamProvider.autoDispose.family<List<NotificationModel>, String>(
        (ref, userId) {
      return supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((data) =>
          data.map((m) => NotificationModel.fromMap(m)).toList());
    });

final unreadCountProvider =
Provider.autoDispose.family<AsyncValue<int>, String>((ref, userId) {
  return ref.watch(notificationsProvider(userId)).whenData(
        (list) => list.where((n) => !n.isRead).length,
  );
});

final notificationActionsProvider =
Provider<NotificationActions>((ref) => NotificationActions());

class NotificationActions {
  Future<void> markRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllRead(String userId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }
}