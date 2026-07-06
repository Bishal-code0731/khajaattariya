import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/rider/application/rider_provider.dart';
import '../../../features/rider/domain/models/rider_model.dart';
import '../../../features/orders/domain/models/order_model.dart';
import '../../../features/payments/application/coupon_provider.dart';
import '../../../features/payments/domain/models/coupon_model.dart';
import '../../../main.dart';
import '../../../features/payments/application/payment_provider.dart';
import '../../../features/payments/application/refund_provider.dart';
import '../../../features/support/application/support_provider.dart';
import '../../../features/support/domain/models/ticket_model.dart';
import '../../../shared/order_timeline_provider.dart';
import '../../../shared/widgets/app_gantt_chart.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_stat_tile.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../application/admin_providers.dart';

final _allUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase.from('profiles').select().order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

final _allOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase.from('orders')
      .select('*, restaurants(name), profiles!customer_id(full_name)')
      .order('created_at', ascending: false).limit(50);
  return List<Map<String, dynamic>>.from(data);
});

final _allRestaurantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase.from('restaurants')
      .select('*, profiles!owner_id(full_name)').order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});

final _analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final orders = await supabase.from('orders').select('total_amount, status, created_at');
  final total     = (orders as List).length;
  final delivered = orders.where((o) => o['status'] == 'delivered').length;
  final revenue   = orders.where((o) => o['status'] == 'delivered')
      .fold<double>(0, (s, o) => s + (o['total_amount'] as num).toDouble());
  return {'total_orders': total, 'delivered_orders': delivered, 'total_revenue': revenue};
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() { super.initState(); _tabController = TabController(length: 11, vsync: this); }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut())],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary, dividerColor: AppColors.border,
          isScrollable: true, tabAlignment: TabAlignment.start,
          tabs: const [Tab(text: 'Analytics'), Tab(text: 'Users'), Tab(text: 'Restaurants'),
            Tab(text: 'Riders'), Tab(text: 'Orders'), Tab(text: 'Timeline'), Tab(text: 'Coupons'), Tab(text: 'Support'),
            Tab(text: 'Refunds'), Tab(text: 'Audit Log'), Tab(text: 'Settings')],
        ),
      ),
      body: TabBarView(controller: _tabController, children: [
        _AnalyticsTab(), _UsersTab(), _RestaurantsTab(), _RidersTab(), _OrdersTab(), _AdminTimelineTab(), _CouponsTab(),
        _SupportTab(), _RefundsTab(), _AuditLogTab(), _SettingsTab(),
      ]),
    );
  }
}

class _AnalyticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_analyticsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load analytics')),
      data: (data) => ListView(padding: const EdgeInsets.all(AppSpacing.screenHorizontal), children: [
        const SizedBox(height: AppSpacing.md),
        Text('Platform Overview', style: AppTypography.headingSmall),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          AppStatTile(label: 'Total Orders', value: '${data['total_orders']}',
              icon: Icons.receipt_long_rounded, color: AppColors.primary, large: true),
          const SizedBox(width: AppSpacing.sm),
          AppStatTile(label: 'Delivered', value: '${data['delivered_orders']}',
              icon: Icons.check_circle_rounded, color: AppColors.success, large: true),
        ]),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
          child: Row(children: [
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 24)),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Revenue', style: AppTypography.bodySmall),
              Text('Rs. ${(data['total_revenue'] as double).toInt()}',
                  style: AppTypography.headingSmall.copyWith(color: AppColors.accent)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(_allUsersProvider);
    return AsyncValueView(
      value: usersAsync,
      errorMessage: 'Could not load users',
      onRetry: () => ref.invalidate(_allUsersProvider),
      data: (users) {
        final customers   = users.where((u) => u['role'] == UserRole.customer.name).length;
        final restaurants = users.where((u) => u['role'] == UserRole.restaurant.name).length;
        final riders      = users.where((u) => u['role'] == UserRole.rider.name).length;
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Row(children: [
              AppStatTile(label: 'Customers', value: '$customers', color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              AppStatTile(label: 'Restaurants', value: '$restaurants', color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              AppStatTile(label: 'Riders', value: '$riders', color: AppColors.riderColor),
            ]),
          )),
          SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) => _UserRow(user: users[index]),
            childCount: users.length,
          )),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ]);
      },
    );
  }
}

class _UserRow extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const _UserRow({required this.user});

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _isToggling = false;

  Future<void> _toggleActive(bool isActive) async {
    if (_isToggling) return;
    // Blocking a user is destructive (locks them out immediately) —
    // confirm before doing it, but not before re-activating.
    if (isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Block this user?'),
          content: Text('${widget.user['full_name'] ?? 'This user'} will be signed out and unable to use the app until unblocked.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Block', style: TextStyle(color: Colors.white))),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _isToggling = true);
    try {
      final updated = await supabase
          .from('profiles')
          .update({'is_active': !isActive}).eq('id', widget.user['id'] as String)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('permission denied or user not found');
      }
      ref.invalidate(_allUsersProvider);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not update user: $e');
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.user['is_active'] as bool? ?? true;
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text((widget.user['full_name'] as String? ?? '?').isNotEmpty
                ? (widget.user['full_name'] as String)[0].toUpperCase() : '?',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary))),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.user['full_name'] as String? ?? 'Unknown', style: AppTypography.bodyMedium,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(widget.user['phone'] as String? ?? 'No phone', style: AppTypography.bodySmall),
        ])),
        _RoleBadge(role: widget.user['role'] as String? ?? ''),
        const SizedBox(width: AppSpacing.sm),
        _isToggling
            ? const SizedBox(width: 18, height: 18, child: AppLoader(size: 18))
            : IconButton(
                icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                    size: 18, color: isActive ? AppColors.error : AppColors.success),
                onPressed: () => _toggleActive(isActive)),
      ]),
    );
  }
}

class _RestaurantsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allRestaurantsProvider);
    return AsyncValueView(
      value: async,
      errorMessage: 'Could not load restaurants',
      onRetry: () => ref.invalidate(_allRestaurantsProvider),
      data: (restaurants) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: restaurants.length,
        itemBuilder: (context, index) => _RestaurantRow(restaurant: restaurants[index]),
      ),
    );
  }
}

class _RestaurantRow extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;
  const _RestaurantRow({required this.restaurant});

  @override
  ConsumerState<_RestaurantRow> createState() => _RestaurantRowState();
}

class _RestaurantRowState extends ConsumerState<_RestaurantRow> {
  bool _isApproving = false;
  bool _isTogglingActive = false;

  Future<void> _approve() async {
    if (_isApproving) return;
    setState(() => _isApproving = true);
    try {
      final ok = await ref
          .read(restaurantApprovalNotifierProvider.notifier)
          .approve(widget.restaurant['id'] as String);
      if (ok) {
        ref.invalidate(_allRestaurantsProvider);
      } else if (mounted) {
        AppSnackbar.error(context, 'Could not approve restaurant');
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _toggleActive(bool isActive) async {
    if (_isTogglingActive) return;
    // Deactivating hides the restaurant from customers and blocks new
    // orders immediately — confirm before doing it, but not before
    // re-activating.
    if (isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Deactivate this restaurant?'),
          content: Text('${widget.restaurant['name'] ?? 'This restaurant'} will be hidden from customers and unable to receive new orders.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Deactivate', style: TextStyle(color: Colors.white))),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _isTogglingActive = true);
    try {
      final updated = await supabase
          .from('restaurants')
          .update({'is_active': !isActive}).eq('id', widget.restaurant['id'] as String)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('permission denied or restaurant not found');
      }
      ref.invalidate(_allRestaurantsProvider);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not update restaurant: $e');
    } finally {
      if (mounted) setState(() => _isTogglingActive = false);
    }
  }

  void _showRejectDialog() {
    final ctrl = TextEditingController();
    final restaurantId = widget.restaurant['id'] as String;
    var isRejecting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Reject Restaurant'),
            content: TextField(controller: ctrl,
                decoration: const InputDecoration(hintText: 'Reason (optional)', labelText: 'Note')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: isRejecting ? null : () async {
                    setDialogState(() => isRejecting = true);
                    final ok = await ref
                        .read(restaurantApprovalNotifierProvider.notifier)
                        .reject(restaurantId, ctrl.text.trim());
                    if (ok) ref.invalidate(_allRestaurantsProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: isRejecting
                      ? const AppLoader.button(color: Colors.white)
                      : const Text('Reject', style: TextStyle(color: Colors.white))),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final owner = r['profiles'] as Map<String, dynamic>? ?? {};
    final isApproved = r['is_approved'] as bool? ?? false;
    final isActive = r['is_active'] as bool? ?? true;
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              child: const Icon(Icons.restaurant_rounded, color: AppColors.textHint, size: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['name'] as String? ?? 'Unknown', style: AppTypography.bodyMedium),
            Text('Owner: ${owner['full_name'] ?? 'Unknown'}', style: AppTypography.bodySmall),
          ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                  color: isApproved ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              child: Text(isApproved ? 'Approved' : 'Pending',
                  style: AppTypography.labelSmall.copyWith(
                      color: isApproved ? AppColors.success : AppColors.warning))),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          if (!isApproved) Expanded(child: OutlinedButton(
              onPressed: _isApproving ? null : _approve,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.success)),
              child: _isApproving
                  ? const AppLoader.button(color: AppColors.success)
                  : const Text('Approve', style: TextStyle(color: AppColors.success)))),
          if (!isApproved) const SizedBox(width: AppSpacing.sm),
          if (!isApproved) Expanded(child: OutlinedButton(
              onPressed: _showRejectDialog,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
              child: const Text('Reject', style: TextStyle(color: AppColors.error)))),
          if (!isApproved) const SizedBox(width: AppSpacing.sm),
          Expanded(child: OutlinedButton(
              onPressed: _isTogglingActive ? null : () => _toggleActive(isActive),
              style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isActive ? AppColors.error : AppColors.success)),
              child: _isTogglingActive
                  ? AppLoader.button(color: isActive ? AppColors.error : AppColors.success)
                  : Text(isActive ? 'Deactivate' : 'Activate',
                      style: TextStyle(color: isActive ? AppColors.error : AppColors.success)))),
        ]),
      ]),
    );
  }
}

class _RidersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridersAsync = ref.watch(allRidersProvider);
    return AsyncValueView(
      value: ridersAsync,
      errorMessage: 'Could not load riders',
      onRetry: () => ref.invalidate(allRidersProvider),
      data: (riders) {
        if (riders.isEmpty) return const Center(child: Text('No riders registered'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: riders.length,
          itemBuilder: (context, index) => _RiderRow(rider: riders[index]),
        );
      },
    );
  }

}

class _RiderRow extends ConsumerStatefulWidget {
  final RiderModel rider;
  const _RiderRow({required this.rider});

  @override
  ConsumerState<_RiderRow> createState() => _RiderRowState();
}

class _RiderRowState extends ConsumerState<_RiderRow> {
  bool _isApproving = false;

  Future<void> _approve() async {
    if (_isApproving) return;
    setState(() => _isApproving = true);
    try {
      final ok = await ref.read(riderApprovalNotifierProvider.notifier).approveRider(widget.rider.id);
      if (ok) ref.invalidate(allRidersProvider);
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  void _showRejectDialog() {
    final ctrl = TextEditingController();
    final riderId = widget.rider.id;
    var isRejecting = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Reject Rider'),
            content: TextField(controller: ctrl,
                decoration: const InputDecoration(hintText: 'Reason (optional)', labelText: 'Note')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: isRejecting ? null : () async {
                    setDialogState(() => isRejecting = true);
                    await ref
                        .read(riderApprovalNotifierProvider.notifier)
                        .rejectRider(riderId, ctrl.text.trim());
                    ref.invalidate(allRidersProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: isRejecting
                      ? const AppLoader.button(color: Colors.white)
                      : const Text('Reject', style: TextStyle(color: Colors.white))),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 20, backgroundColor: AppColors.riderColor.withValues(alpha: 0.15),
              child: Text(rider.fullName.isNotEmpty ? rider.fullName[0].toUpperCase() : 'R',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.riderColor))),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rider.fullName, style: AppTypography.bodyMedium),
            Text('${rider.vehicleType.toUpperCase()} · ${rider.totalDeliveries} deliveries',
                style: AppTypography.bodySmall),
          ])),
          Container(width: 10, height: 10,
              decoration: BoxDecoration(
                  color: rider.isOnline ? AppColors.success : AppColors.textHint,
                  shape: BoxShape.circle)),
        ]),
        if (!rider.isApproved) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: ElevatedButton(
                onPressed: _isApproving ? null : _approve,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs)),
                child: _isApproving
                    ? const AppLoader.button(color: Colors.white)
                    : const Text('Approve', style: TextStyle(color: Colors.white)))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: OutlinedButton(
                onPressed: _showRejectDialog,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs)),
                child: const Text('Reject', style: TextStyle(color: AppColors.error)))),
          ]),
        ] else Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(children: [
            const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Text('Approved Rider', style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
            const Spacer(),
            Text('Rs. ${rider.totalEarnings.toInt()} earned', style: AppTypography.bodySmall),
          ]),
        ),
      ]),
    );
  }
}

class _OrdersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_allOrdersProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load orders')),
      data: (orders) {
        if (orders.isEmpty) return const Center(child: Text('No orders yet'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o          = orders[index];
            final restaurant = o['restaurants'] as Map<String, dynamic>? ?? {};
            final customer   = o['profiles'] as Map<String, dynamic>? ?? {};
            final status     = o['status'] as String? ?? 'pending';
            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(restaurant['name'] as String? ?? 'Unknown', style: AppTypography.bodyMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('By: ${customer['full_name'] ?? 'Unknown'}', style: AppTypography.bodySmall),
                  Text('Rs. ${(o['total_amount'] as num?)?.toInt() ?? 0}',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                ])),
                AppStatusBadge(status: OrderStatus.fromString(status)),
              ]),
            );
          },
        );
      },
    );
  }
}

/// Cross-role order timeline — one row per recent order, showing every
/// status transition from placed through delivered/cancelled, sourced
/// directly from `order_timeline` (which already logs each transition
/// with a timestamp) so admins can spot bottlenecks (e.g. orders stuck
/// "preparing" too long) across the whole platform at a glance.
class _AdminTimelineTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_allOrdersProvider);
    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(child: Text('Could not load orders')),
      data: (orders) {
        if (orders.isEmpty) {
          return const AppEmptyState(icon: Icons.timeline_rounded, title: 'No orders yet');
        }

        final orderIds = orders.map((o) => o['id'] as String).toList();
        final timelinesAsync = ref.watch(orderTimelinesBatchProvider(orderIds));

        return timelinesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (_, __) => const Center(child: Text('Could not load timeline')),
          data: (timelines) {
            final now = DateTime.now();
            final rows = orders.map((o) {
              final restaurant = o['restaurants'] as Map<String, dynamic>? ?? {};
              final customer = o['profiles'] as Map<String, dynamic>? ?? {};
              final events = timelines[o['id']] ?? [];
              return GanttRow(
                label: restaurant['name'] as String? ?? 'Unknown',
                subtitle: customer['full_name'] as String? ?? 'Unknown',
                stages: ganttStagesFromTimeline(events, now),
              );
            }).toList();

            final earliestStart = events(rows).isEmpty
                ? now
                : events(rows).map((s) => s.start).reduce((a, b) => a.isBefore(b) ? a : b);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  borderRadius: AppSpacing.radiusLg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Timeline (last ${orders.length})', style: AppTypography.headingSmall),
                      const SizedBox(height: AppSpacing.md),
                      AppGanttChart(
                        rows: rows,
                        rangeStart: earliestStart,
                        rangeEnd: now,
                        labelWidth: 120,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<GanttStage> events(List<GanttRow> rows) => rows.expand((r) => r.stages).toList();
}

class _CouponsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allCouponsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Coupon', style: TextStyle(color: Colors.white)),
      ),
      body: AsyncValueView(
        value: async,
        errorMessage: 'Could not load coupons',
        onRetry: () => ref.invalidate(allCouponsProvider),
        data: (coupons) {
          if (coupons.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.discount_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text('No coupons created yet', style: AppTypography.bodyMedium),
          ]));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: coupons.length,
            itemBuilder: (context, index) => _CouponRow(coupon: coupons[index]),
          );
        },
      ),
    );
  }

  void _showCreate(BuildContext context, WidgetRef ref) {
    final formKey   = GlobalKey<FormState>();
    final codeCtrl  = TextEditingController();
    final valueCtrl = TextEditingController();
    final minCtrl   = TextEditingController(text: '0');
    String type     = 'percent';
    bool isCreating = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Create Coupon'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Code'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => Validators.required(v, field: 'Code')),
          const SizedBox(height: 8),
          SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'percent', label: Text('Percent')),
                ButtonSegment(value: 'fixed', label: Text('Fixed'))],
              selected: {type}, onSelectionChanged: (s) => setState(() => type = s.first)),
          const SizedBox(height: 8),
          TextFormField(controller: valueCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: type == 'percent' ? 'Discount %' : 'Amount (Rs.)'),
              validator: (v) => Validators.price(v, field: 'Discount value')),
          const SizedBox(height: 8),
          TextFormField(controller: minCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min Order (Rs.)'),
              validator: (v) => Validators.nonNegativeNumber(v, field: 'Min order amount')),
        ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: isCreating ? null : () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                setState(() => isCreating = true);
                final ok = await ref.read(createCouponProvider.notifier).create(
                    code: codeCtrl.text, discountType: type,
                    discountValue: double.tryParse(valueCtrl.text) ?? 0,
                    minOrderAmount: double.tryParse(minCtrl.text) ?? 0);
                if (ok) {
                  ref.invalidate(allCouponsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } else {
                  setState(() => isCreating = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isCreating
                  ? const AppLoader.button(color: Colors.white)
                  : const Text('Create', style: TextStyle(color: Colors.white))),
        ],
      ),
    ));
  }
}

class _CouponRow extends ConsumerStatefulWidget {
  final CouponModel coupon;
  const _CouponRow({required this.coupon});

  @override
  ConsumerState<_CouponRow> createState() => _CouponRowState();
}

class _CouponRowState extends ConsumerState<_CouponRow> {
  bool _isToggling = false;

  Future<void> _toggle(bool v) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      final ok = await ref.read(createCouponProvider.notifier).toggleActive(widget.coupon.id, v);
      if (ok) {
        ref.invalidate(allCouponsProvider);
      } else if (mounted) {
        AppSnackbar.error(context, 'Could not update coupon');
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coupon;
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
      child: Row(children: [
        Container(padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            child: const Icon(Icons.discount_rounded, color: AppColors.accent, size: 20)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.code, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          Text(c.discountType == 'percent'
              ? '${c.discountValue.toInt()}% off' : 'Rs. ${c.discountValue.toInt()} off',
              style: AppTypography.bodyMedium),
          Text('Used: ${c.usesCount}${c.maxUses != null ? '/${c.maxUses}' : ''} · Min: Rs. ${c.minOrderAmount.toInt()}',
              style: AppTypography.bodySmall),
        ])),
        _isToggling
            ? const SizedBox(width: 20, height: 20, child: AppLoader(size: 20))
            : Switch(value: c.isActive, onChanged: _toggle, activeColor: AppColors.success),
      ]),
    );
  }
}

class _SupportTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(allTicketsProvider);
    return AsyncValueView(
      value: ticketsAsync,
      errorMessage: 'Could not load tickets',
      onRetry: () => ref.invalidate(allTicketsProvider),
      data: (tickets) {
        if (tickets.isEmpty) {
          return const AppEmptyState(
            icon: Icons.support_agent_rounded,
            title: 'No support tickets',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final t = tickets[index];
            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
              onTap: () => _openTicket(context, ref, t),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(t.subject, style: AppTypography.bodyMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      child: Text(t.status.label, style: AppTypography.labelSmall.copyWith(color: AppColors.primary))),
                ]),
                const SizedBox(height: 2),
                Text('From: ${t.customerName ?? 'Unknown'}', style: AppTypography.bodySmall),
                Text(t.message, style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        );
      },
    );
  }

  void _openTicket(BuildContext context, WidgetRef ref, TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AdminTicketSheet(ticket: ticket),
    );
  }
}

class _AdminTicketSheet extends ConsumerStatefulWidget {
  final TicketModel ticket;
  const _AdminTicketSheet({required this.ticket});

  @override
  ConsumerState<_AdminTicketSheet> createState() => _AdminTicketSheetState();
}

class _AdminTicketSheetState extends ConsumerState<_AdminTicketSheet> {
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _replyController.text.trim();
    final adminId = supabase.auth.currentUser?.id;
    if (text.isEmpty || adminId == null) return;
    setState(() => _isSending = true);
    final ok = await ref.read(supportActionsProvider.notifier).reply(
        ticketId: widget.ticket.id, actorId: adminId, message: text);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (ok) {
      _replyController.clear();
      ref.invalidate(ticketRepliesProvider(widget.ticket.id));
    } else {
      AppSnackbar.error(context, 'Could not send reply');
    }
  }

  bool _isResolving = false;

  Future<void> _resolve() async {
    if (_isResolving) return;
    setState(() => _isResolving = true);
    final ok = await ref.read(supportActionsProvider.notifier)
        .updateStatus(widget.ticket.id, TicketStatus.resolved);
    if (!mounted) return;
    if (ok) {
      ref.invalidate(allTicketsProvider);
      Navigator.pop(context);
    } else {
      setState(() => _isResolving = false);
      AppSnackbar.error(context, 'Could not update ticket');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repliesAsync = ref.watch(ticketRepliesProvider(widget.ticket.id));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.9, minChildSize: 0.5, expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.ticket.subject, style: AppTypography.headingSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(widget.ticket.message, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AsyncValueView(
                value: repliesAsync,
                errorMessage: 'Could not load replies',
                data: (replies) => ListView.builder(
                  controller: scrollController,
                  itemCount: replies.length,
                  itemBuilder: (_, i) {
                    final r = replies[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text('${r.actorName ?? 'User'}: ${r.message}',
                          style: AppTypography.bodySmall),
                    );
                  },
                ),
              ),
            ),
            Row(children: [
              Expanded(child: TextField(controller: _replyController,
                  decoration: const InputDecoration(hintText: 'Reply...'))),
              IconButton.filled(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const AppLoader.button(color: Colors.white)
                      : const Icon(Icons.send_rounded)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: _isResolving ? null : _resolve,
                child: _isResolving
                    ? const AppLoader.button(color: AppColors.primary)
                    : const Text('Mark Resolved'))),
          ]),
        ),
      ),
    );
  }
}

class _RefundsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsAsync = ref.watch(allRefundsProvider);
    return AsyncValueView(
      value: refundsAsync,
      errorMessage: 'Could not load refund requests',
      onRetry: () => ref.invalidate(allRefundsProvider),
      data: (refunds) {
        if (refunds.isEmpty) {
          return const AppEmptyState(
            icon: Icons.currency_exchange_rounded,
            title: 'No refund requests',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: refunds.length,
          itemBuilder: (context, index) => _RefundRow(refund: refunds[index]),
        );
      },
    );
  }
}

class _RefundRow extends ConsumerStatefulWidget {
  final Map<String, dynamic> refund;
  const _RefundRow({required this.refund});

  @override
  ConsumerState<_RefundRow> createState() => _RefundRowState();
}

class _RefundRowState extends ConsumerState<_RefundRow> {
  bool _isApproving = false;
  bool _isRejecting = false;

  Future<void> _updateStatus(String status) async {
    if (_isApproving || _isRejecting) return;
    setState(() => status == 'approved' ? _isApproving = true : _isRejecting = true);
    try {
      final ok = await ref.read(refundNotifierProvider.notifier)
          .updateStatus(widget.refund['id'] as String, status);
      if (ok) {
        ref.invalidate(allRefundsProvider);
      } else if (mounted) {
        AppSnackbar.error(context, 'Could not ${status == 'approved' ? 'approve' : 'reject'} refund');
      }
    } finally {
      if (mounted) setState(() { _isApproving = false; _isRejecting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.refund;
    final order = r['orders'] as Map<String, dynamic>? ?? {};
    final customer = order['profiles'] as Map<String, dynamic>? ?? {};
    final status = r['status'] as String? ?? 'pending';
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Rs. ${(r['amount'] as num).toInt()}',
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
              decoration: BoxDecoration(
                  color: status == 'pending' ? AppColors.warningLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
              child: Text(status.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                      color: status == 'pending' ? AppColors.warning : AppColors.success))),
        ]),
        const SizedBox(height: 2),
        Text('From: ${customer['full_name'] ?? 'Unknown'}', style: AppTypography.bodySmall),
        if (r['reason'] != null)
          Text('Reason: ${r['reason']}', style: AppTypography.bodySmall),
        if (status == 'pending') ...[
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: (_isApproving || _isRejecting) ? null : () => _updateStatus('approved'),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.success)),
                child: _isApproving
                    ? const AppLoader.button(color: AppColors.success)
                    : const Text('Approve', style: TextStyle(color: AppColors.success)))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: OutlinedButton(
                onPressed: (_isApproving || _isRejecting) ? null : () => _updateStatus('rejected'),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                child: _isRejecting
                    ? const AppLoader.button(color: AppColors.error)
                    : const Text('Reject', style: TextStyle(color: AppColors.error)))),
          ]),
        ],
      ]),
    );
  }
}

class _AuditLogTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);
    return AsyncValueView(
      value: logsAsync,
      errorMessage: 'Could not load audit log',
      onRetry: () => ref.invalidate(auditLogsProvider),
      data: (logs) {
        if (logs.isEmpty) {
          return const AppEmptyState(icon: Icons.history_rounded, title: 'No activity yet');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final actor = log['profiles'] as Map<String, dynamic>?;
            return GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((log['action'] as String? ?? '').replaceAll('_', ' '), style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text('By: ${actor?['full_name'] ?? 'System'}', style: AppTypography.bodySmall),
                if (log['target_table'] != null)
                  Text('${log['target_table']} · ${log['target_id']}', style: AppTypography.bodySmall),
              ]),
            );
          },
        );
      },
    );
  }
}

class _SettingsTab extends ConsumerWidget {
  static const _knownKeys = [
    'khalti_enabled', 'stripe_enabled', 'cash_enabled', 'commission_percent', 'default_delivery_fee',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(platformSettingsProvider);
    return AsyncValueView(
      value: settingsAsync,
      errorMessage: 'Could not load settings',
      onRetry: () => ref.invalidate(platformSettingsProvider),
      data: (settings) {
        final keys = {..._knownKeys, ...settings.keys}.toList()..sort();
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final key = keys[index];
            return _SettingRow(settingKey: key, value: settings[key]);
          },
        );
      },
    );
  }
}

class _SettingRow extends ConsumerStatefulWidget {
  final String settingKey;
  final String? value;
  const _SettingRow({required this.settingKey, required this.value});

  @override
  ConsumerState<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends ConsumerState<_SettingRow> {
  late final TextEditingController _controller = TextEditingController(text: widget.value ?? '');
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final ok = await ref
        .read(platformSettingsNotifierProvider.notifier)
        .updateSetting(widget.settingKey, _controller.text.trim());
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (ok) {
      ref.invalidate(platformSettingsProvider);
      if (context.mounted) AppSnackbar.success(context, 'Setting saved');
    } else if (context.mounted) {
      AppSnackbar.error(context, 'Could not save setting');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusLg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.settingKey, style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(child: TextField(controller: _controller,
                decoration: const InputDecoration(isDense: true))),
            const SizedBox(width: AppSpacing.sm),
            _isSaving
                ? const AppLoader.button()
                : IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded, color: AppColors.success)),
          ]),
        ]),
      ),
    );
  }
}

// ── Shared helper widgets ──────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  UserRole get _role => UserRole.fromString(role);

  @override
  Widget build(BuildContext context) {
    final color = _role.color;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(_role.label.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: color)));
  }
}

