import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../application/notification_provider.dart';
import '../domain/models/notification_model.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _markingAll = false;
  final _markingIds = <String>{};

  final _hiddenIds = <String>{};

  NotificationActions get _actions => ref.read(notificationActionsProvider);

  Future<void> _markAllRead(String userId) async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _actions.markAllRead(userId);
      if (mounted) {
        AppSnackbar.success(context, context.s.account.allMarkedRead);
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  void _open(NotificationModel n) {
    if (!n.isRead && _markingIds.add(n.id)) {
      _actions.markRead(n.id).catchError((Object e) {
        if (mounted) AppSnackbar.error(context, e);
      }).whenComplete(() => _markingIds.remove(n.id));
    }
    if (n.orderId != null) {
      context.pushOnce('${RouteNames.orderDetail}/${n.orderId}');
    }
  }

  Future<void> _delete(NotificationModel n) async {
    setState(() => _hiddenIds.add(n.id));
    try {
      await _actions.deleteNotification(n.id);
      if (mounted) {
        AppSnackbar.success(context, context.s.account.notificationDeleted);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _hiddenIds.remove(n.id));
      AppSnackbar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.s.account;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppTopBar(title: a.notificationsTitle),
        body: const AppShimmerCardList(itemHeight: 48),
      );
    }

    final async = ref.watch(notificationsProvider(user.id));
    final list =
        async.valueOrNull?.where((n) => !_hiddenIds.contains(n.id)).toList() ??
            const [];
    final unread = list.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppTopBar(
        title: a.notificationsTitle,
        subtitle: unread > 0 ? a.unreadCount(unread) : null,
        actions: [
          if (unread > 0)
            IconButton(
              tooltip: a.markAllRead,
              onPressed: _markingAll ? null : () => _markAllRead(user.id),
              icon: _markingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const AppShimmerCardList(count: 6, itemHeight: 48),
        error: (e, _) => AppErrorState(
            error: e,
            onRetry: () => ref.invalidate(notificationsProvider(user.id))),
        data: (_) {
          if (list.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_none_rounded,
              title: a.noNotificationsTitle,
              subtitle: a.noNotificationsBody,
            );
          }
          return _GroupedList(items: list, onOpen: _open, onDelete: _delete);
        },
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList(
      {required this.items, required this.onOpen, required this.onDelete});

  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onOpen;
  final ValueChanged<NotificationModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final a = context.s.account;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final today = items
        .where((n) => !n.createdAt.toLocal().isBefore(startOfToday))
        .toList();
    final earlier = items
        .where((n) => n.createdAt.toLocal().isBefore(startOfToday))
        .toList();

    final children = <Widget>[];
    void addGroup(String title, List<NotificationModel> group) {
      if (group.isEmpty) return;
      children.add(_GroupHeader(title: title));
      for (var i = 0; i < group.length; i++) {
        if (i > 0) children.add(const Divider(height: 1, indent: 68));
        final n = group[i];
        children.add(NotificationTile(
          key: ValueKey(n.id),
          notification: n,
          onTap: () => onOpen(n),
          onDismissed: () => onDelete(n),
        ));
      }
    }

    addGroup(a.today, today);
    addGroup(a.earlier, earlier);
    children.add(Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(a.swipeToDelete,
          textAlign: TextAlign.center, style: context.text.hint),
    ));

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(children: children),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.palette.background,
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
          AppSpacing.xl, AppSpacing.screenHorizontal, AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(title.toUpperCase(),
            style: context.text.overline.copyWith(letterSpacing: 0.8)),
      ),
    );
  }
}
