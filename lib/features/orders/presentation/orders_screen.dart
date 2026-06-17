import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/order_provider.dart';
import '../domain/models/order_model.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Please login to view orders')),
      );
    }

    final ordersAsync = ref.watch(customerOrdersStreamProvider(user.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textHint),
              const SizedBox(height: AppSpacing.md),
              Text('Could not load orders',
                  style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () =>
                    ref.invalidate(customerOrdersStreamProvider(user.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (orders) => orders.isEmpty
            ? _EmptyOrders()
            : ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) => _OrderCard(
            order: orders[index],
            onTap: () => context.go(
              '${RouteNames.orderDetail}/${orders[index].id}',
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          const Text('No orders yet', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your order history will appear here',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextButton(
            onPressed: () => context.go(RouteNames.home),
            child: const Text('Browse Restaurants'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.restaurantName,
                  style: AppTypography.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${order.items.length} item${order.items.length == 1 ? '' : 's'} • Rs. ${order.totalAmount.toInt()}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                _formatDate(order.createdAt),
                style: AppTypography.bodySmall,
              ),
              const Spacer(),
              Text(
                'View details',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.primary),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:    return AppColors.accent;
      case OrderStatus.confirmed:  return AppColors.primary;
      case OrderStatus.preparing:  return AppColors.primary;
      case OrderStatus.ready:      return AppColors.success;
      case OrderStatus.pickedUp:   return AppColors.success;
      case OrderStatus.delivered:  return AppColors.success;
      case OrderStatus.cancelled:  return AppColors.error;
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