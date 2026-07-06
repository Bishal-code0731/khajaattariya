import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/order_provider.dart';
import '../domain/models/order_model.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.safeBack(),
          ),
        ),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please login to view orders',
          action: TextButton(
            onPressed: () => context.push(RouteNames.login),
            child: const Text('Login'),
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(customerOrdersStreamProvider(user.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safeBack(),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ordersAsync.when(
              loading: () => const AppShimmerCardList(count: 4, itemHeight: 88),
              error: (e, _) => AppErrorState(
                message: 'Could not load orders',
                onRetry: () => ref.invalidate(customerOrdersStreamProvider(user.id)),
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
                        onTap: () => context.pushOnce(
                          '${RouteNames.orderDetail}/${orders[index].id}',
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No orders yet',
      subtitle: 'Your order history will appear here',
      action: TextButton(
        onPressed: () => context.safeBack(),
        child: const Text('Browse Restaurants'),
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
              AppStatusBadge(status: order.status),
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

