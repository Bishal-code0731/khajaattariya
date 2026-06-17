import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/orders/application/order_provider.dart';
import '../../../features/orders/domain/models/order_model.dart';
import '../../../features/restaurant_dashboard/presentation/menu_management_screen.dart'; // Added for Manage Menu
import '../../../shared/widgets/glass_card.dart';
import '../../../main.dart';

class RestaurantDashboardScreen extends ConsumerWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );

    // Restaurant owner needs their restaurant id
    // For now we fetch it from restaurants table by owner_id
    return _RestaurantDashboardBody(ownerId: user.id, ownerName: user.fullName);
  }
}

class _RestaurantDashboardBody extends ConsumerWidget {
  final String ownerId;
  final String ownerName;

  const _RestaurantDashboardBody({
    required this.ownerId,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch this owner's restaurant id first
    final restaurantAsync = ref.watch(_ownerRestaurantProvider(ownerId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: restaurantAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(
          child: Text('Could not load restaurant data'),
        ),
        data: (restaurant) {
          if (restaurant == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.md),
                  Text('No restaurant found',
                      style: AppTypography.headingSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your restaurant profile is not set up yet.',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return _OrdersView(
            restaurantId: restaurant['id'] as String,
            restaurantName: restaurant['name'] as String,
          );
        },
      ),
    );
  }
}

// Fetches the restaurant owned by this user
final _ownerRestaurantProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, ownerId) async {
  final data = await supabase
      .from('restaurants')
      .select('id, name')
      .eq('owner_id', ownerId)
      .maybeSingle();
  return data;
});

class _OrdersView extends ConsumerWidget {
  final String restaurantId;
  final String restaurantName;

  const _OrdersView({
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(restaurantOrdersProvider(restaurantId));

    return ordersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Could not load orders', style: AppTypography.bodyMedium),
            TextButton(
              onPressed: () =>
                  ref.invalidate(restaurantOrdersProvider(restaurantId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (orders) {
        final active = orders
            .where((o) => o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
            .toList();
        final completed = orders
            .where((o) =>
        o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled)
            .toList();

        // Today's stats
        final today = DateTime.now();
        final todayOrders = orders.where((o) =>
        o.createdAt.day == today.day &&
            o.createdAt.month == today.month &&
            o.createdAt.year == today.year);
        final todayRevenue = todayOrders
            .where((o) => o.status == OrderStatus.delivered)
            .fold(0.0, (sum, o) => sum + o.totalAmount);
        final pendingCount = orders
            .where((o) => o.status == OrderStatus.pending)
            .length;

        return CustomScrollView(
          slivers: [
            // Stats bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurantName,
                        style: AppTypography.headingLarge),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MenuManagementScreen(
                            restaurantId: restaurantId,
                            restaurantName: restaurantName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.restaurant_menu_rounded,
                          size: 16, color: AppColors.primary),
                      label: Text('Manage Menu',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.primary)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _StatCard(
                          label: "Today's Orders",
                          value: '${todayOrders.length}',
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatCard(
                          label: "Revenue",
                          value: 'Rs. ${todayRevenue.toInt()}',
                          icon: Icons.payments_outlined,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatCard(
                          label: "Pending",
                          value: '$pendingCount',
                          icon: Icons.pending_outlined,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Active orders
            if (active.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Text('Active Orders',
                      style: AppTypography.headingSmall),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _RestaurantOrderCard(
                    order: active[index],
                    isRestaurant: true,
                  ),
                  childCount: active.length,
                ),
              ),
            ],

            // Completed orders
            if (completed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.md,
                    AppSpacing.screenHorizontal,
                    AppSpacing.sm,
                  ),
                  child: Text('Completed',
                      style: AppTypography.headingSmall),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _RestaurantOrderCard(
                    order: completed[index],
                    isRestaurant: true,
                  ),
                  childCount: completed.length,
                ),
              ),
            ],

            if (orders.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: AppSpacing.md),
                      Text('No orders yet',
                          style: AppTypography.headingSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'New orders will appear here in real-time',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        borderRadius: AppSpacing.radiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.xs),
            Text(value,
                style: AppTypography.headingSmall
                    .copyWith(color: color)),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RestaurantOrderCard extends ConsumerWidget {
  final OrderModel order;
  final bool isRestaurant;

  const _RestaurantOrderCard({
    required this.order,
    required this.isRestaurant,
  });

  OrderStatus? get _nextStatus {
    switch (order.status) {
      case OrderStatus.pending:   return OrderStatus.confirmed;
      case OrderStatus.confirmed: return OrderStatus.preparing;
      case OrderStatus.preparing: return OrderStatus.ready;
      default: return null;
    }
  }

  String? get _actionLabel {
    switch (order.status) {
      case OrderStatus.pending:   return 'Confirm Order';
      case OrderStatus.confirmed: return 'Start Preparing';
      case OrderStatus.preparing: return 'Mark Ready';
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(orderStatusNotifierProvider).isLoading;

    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: AppTypography.headingSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} item${order.items.length == 1 ? '' : 's'} • Rs. ${order.totalAmount.toInt()}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          if (order.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            ...order.items.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Text('${item.quantity}×  ',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.primary)),
                    Expanded(
                      child: Text(item.name,
                          style: AppTypography.bodySmall),
                    ),
                    Text('Rs. ${item.subtotal.toInt()}',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),
          ],
          if (order.notes != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.note_outlined,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(order.notes!,
                      style: AppTypography.bodySmall),
                ),
              ],
            ),
          ],
          if (_nextStatus != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                  final success = await ref
                      .read(orderStatusNotifierProvider.notifier)
                      .updateStatus(order.id, _nextStatus!);
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update status'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  _actionLabel!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
          if (order.status == OrderStatus.cancelled) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Text('Cancelled',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.error)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:   return AppColors.accent;
      case OrderStatus.confirmed: return AppColors.primary;
      case OrderStatus.preparing: return AppColors.primary;
      case OrderStatus.ready:     return AppColors.success;
      case OrderStatus.pickedUp:  return AppColors.success;
      case OrderStatus.delivered: return AppColors.success;
      case OrderStatus.cancelled: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelSmall.copyWith(color: _color),
      ),
    );
  }
}