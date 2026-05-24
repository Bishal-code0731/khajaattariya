import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/orders/application/order_provider.dart';
import '../../../features/orders/domain/models/order_model.dart';
import '../../../shared/widgets/glass_card.dart';

class RiderDashboardScreen extends ConsumerWidget {
  const RiderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final availableAsync = ref.watch(availableOrdersProvider);
    final activeAsync = ref.watch(riderActiveOrderProvider(user.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Rider greeting
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, ${user.fullName.split(' ').first} 👋',
                      style: AppTypography.headingLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Ready to deliver?',
                      style: AppTypography.bodyMedium),
                ],
              ),
            ),
          ),

          // Active delivery section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
              ),
              child: Text('My Active Delivery',
                  style: AppTypography.headingSmall),
            ),
          ),

          SliverToBoxAdapter(
            child: activeAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (activeOrder) => activeOrder == null
                  ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  borderRadius: AppSpacing.radiusLg,
                  child: Row(
                    children: [
                      const Icon(Icons.delivery_dining_rounded,
                          color: AppColors.textHint, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'No active delivery',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : _ActiveDeliveryCard(
                order: activeOrder,
                riderId: user.id,
              ),
            ),
          ),

          // Available orders section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.sm,
              ),
              child: Text('Available Pickups',
                  style: AppTypography.headingSmall),
            ),
          ),

          availableAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Center(
                child: Text('Could not load orders',
                    style: AppTypography.bodyMedium),
              ),
            ),
            data: (orders) => orders.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  borderRadius: AppSpacing.radiusLg,
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No orders ready for pickup',
                        style: AppTypography.bodyMedium,
                      ),
                      Text(
                        'Check back in a moment',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _AvailableOrderCard(
                  order: orders[index],
                  riderId: user.id,
                ),
                childCount: orders.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }
}

class _ActiveDeliveryCard extends ConsumerWidget {
  final OrderModel order;
  final String riderId;

  const _ActiveDeliveryCard({
    required this.order,
    required this.riderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = ref.watch(orderStatusNotifierProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining_rounded,
                      color: AppColors.success),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.restaurantName,
                          style: AppTypography.headingSmall),
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
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
                  ],
                ),
              ),
            ),
            if (order.deliveryAddress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress!,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            if (order.status == OrderStatus.pickedUp)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                    final success = await ref
                        .read(orderStatusNotifierProvider.notifier)
                        .updateStatus(
                        order.id, OrderStatus.delivered);
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
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
                      : const Text('Mark as Delivered',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvailableOrderCard extends ConsumerWidget {
  final OrderModel order;
  final String riderId;

  const _AvailableOrderCard({
    required this.order,
    required this.riderId,
  });

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
                    Text(order.restaurantName,
                        style: AppTypography.headingSmall),
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${order.totalAmount.toInt()}',
                style: AppTypography.priceMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
            style: AppTypography.bodySmall,
          ),
          if (order.deliveryAddress != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress!,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                final success = await ref
                    .read(orderStatusNotifierProvider.notifier)
                    .assignRider(order.id, riderId);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to accept order'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                  : const Text('Accept & Pick Up',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
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
      case OrderStatus.ready:     return AppColors.success;
      case OrderStatus.pickedUp:  return AppColors.primary;
      case OrderStatus.delivered: return AppColors.success;
      default:                    return AppColors.textSecondary;
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