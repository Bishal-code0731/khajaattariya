import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/notification_provider.dart';
import '../domain/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Guards against double-tapping "Mark all read" (or tapping a
  // notification twice before its markRead call resolves) firing the
  // same bulk update twice.
  bool _isMarkingAllRead = false;
  final _markingReadIds = <String>{};

  Future<void> _markAllRead(String userId, NotificationActions actions) async {
    if (_isMarkingAllRead) return;
    setState(() => _isMarkingAllRead = true);
    try {
      await actions.markAllRead(userId);
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _markRead(String id, NotificationActions actions) async {
    if (_markingReadIds.contains(id)) return;
    _markingReadIds.add(id);
    try {
      await actions.markRead(id);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not mark as read');
    } finally {
      _markingReadIds.remove(id);
    }
  }

  Future<void> _deleteNotification(String id, NotificationActions actions) async {
    try {
      await actions.deleteNotification(id);
    } catch (e) {
      // The Dismissible already removed the tile optimistically; a
      // failed delete means it'll reappear on the next stream emission,
      // which is confusing without this explaining why.
      if (mounted) AppSnackbar.error(context, 'Could not delete notification — it will reappear');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.safeBack(),
          ),
        ),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please login to view notifications',
          action: TextButton(
            onPressed: () => context.push(RouteNames.login),
            child: const Text('Login'),
          ),
        ),
      );
    }

    final notificationsAsync = ref.watch(notificationsProvider(user.id));
    final actions = ref.read(notificationActionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safeBack(),
        ),
        actions: [
          TextButton(
            onPressed: _isMarkingAllRead ? null : () => _markAllRead(user.id, actions),
            child: _isMarkingAllRead
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const AppShimmerCardList(itemHeight: 40),
        error: (_, __) => AppErrorState(
          message: 'Could not load notifications',
          onRetry: () => ref.invalidate(notificationsProvider(user.id)),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: "You're all caught up!",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.md,
            ),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(
                notification: n,
                onTap: () {
                  if (!n.isRead) _markRead(n.id, actions);
                  if (n.orderId != null) {
                    context.pushOnce(
                        '${RouteNames.orderDetail}/${n.orderId}');
                  }
                },
                onDismiss: () => _deleteNotification(n.id, actions),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'order_status':
        return Icons.receipt_long_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case 'order_status':
        return AppColors.primary;
      case 'promo':
        return AppColors.accent;
      default:
        return AppColors.info;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusLg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius:
                BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: notification.isRead
                              ? AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary)
                              : AppTypography.labelMedium,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_timeAgo(notification.createdAt),
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textHint, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}