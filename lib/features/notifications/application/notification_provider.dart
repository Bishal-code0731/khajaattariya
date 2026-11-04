import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';
import '../../../main.dart';
import '../domain/models/notification_model.dart';

const _tag = 'notifications';

/// Stores this device's push token on the user's profile.
Future<void> saveFcmToken(String userId, String token) async {
  try {
    await supabase
        .from('profiles')
        .update({'fcm_token': token}).eq('id', userId);
  } catch (e) {
    // Non-fatal: push notifications just won't reach this device.
    AppLogger.warning(_tag, 'saveFcmToken failed: $e');
  }
}

final notificationsProvider = StreamProvider.autoDispose
    .family<List<NotificationModel>, String>((ref, userId) {
  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((m) => NotificationModel.fromMap(m)).toList());
});

final unreadCountProvider =
    Provider.autoDispose.family<AsyncValue<int>, String>((ref, userId) {
  return ref.watch(notificationsProvider(userId)).whenData(
        (list) => list.where((n) => !n.isRead).length,
      );
});

final notificationActionsProvider =
    Provider<NotificationActions>((ref) => NotificationActions());

/// Mutations on the user's own notifications.
class NotificationActions {
  Future<void> markRead(String notificationId) => _run('markRead', () async {
        await supabase
            .from('notifications')
            .update({'is_read': true}).eq('id', notificationId);
      });

  Future<void> markAllRead(String userId) => _run('markAllRead', () async {
        await supabase
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', userId)
            .eq('is_read', false);
      });

  Future<void> deleteNotification(String notificationId) =>
      _run('delete', () async {
        await supabase.from('notifications').delete().eq('id', notificationId);
      });

  Future<void> _run(String action, Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      AppLogger.warning(_tag, '$action failed: $e');
      rethrow;
    }
  }
}
