import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/order_provider.dart';
import '../domain/models/order_model.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.orders),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(
          child: Text('Could not load order details'),
        ),
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusTracker(status: order.status),
              const SizedBox(height: AppSpacing.lg),
              _RestaurantInfo(order: order),
              const SizedBox(height: AppSpacing.lg),
              _ItemsList(order: order),
              const SizedBox(height: AppSpacing.lg),
              _BillSummary(order: order),
              const SizedBox(height: AppSpacing.lg),
              if (order.deliveryAddress != null)
                _InfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Delivery Address',
                  value: order.deliveryAddress!,
                ),
              if (order.notes != null)
                _InfoTile(
                  icon: Icons.note_outlined,
                  label: 'Notes',
                  value: order.notes!,
                ),
              _InfoTile(
                icon: Icons.confirmation_number_outlined,
                label: 'Order ID',
                value: order.id.substring(0, 8).toUpperCase(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  final OrderStatus status;

  const _StatusTracker({required this.status});

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
    OrderStatus.pickedUp,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusLg,
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text('Order Cancelled',
                style: AppTypography.headingSmall
                    .copyWith(color: AppColors.error)),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(status);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Status', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connector line
                final stepIndex = i ~/ 2;
                final isCompleted = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                );
              }
              // Step dot
              final stepIndex = i ~/ 2;
              final isCompleted = stepIndex <= currentIndex;
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                    : null,
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              status.label,
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantInfo extends StatelessWidget {
  final OrderModel order;

  const _RestaurantInfo({required this.order});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.store_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.restaurantName,
                    style: AppTypography.headingSmall),
                const SizedBox(height: 2),
                Text(
                  'Ordered on ${_formatDate(order.createdAt)}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ItemsList extends StatelessWidget {
  final OrderModel order;

  const _ItemsList({required this.order});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          ...order.items.map(
                (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Text(
                    '${item.quantity}×',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(item.name, style: AppTypography.bodyMedium),
                  ),
                  Text(
                    'Rs. ${item.subtotal.toInt()}',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillSummary extends StatelessWidget {
  final OrderModel order;

  const _BillSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final subtotal = order.totalAmount - order.deliveryFee;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill Summary', style: AppTypography.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: 'Subtotal',
              value: 'Rs. ${subtotal.toInt()}'),
          const SizedBox(height: AppSpacing.xs),
          _Row(label: 'Delivery fee',
              value: 'Rs. ${order.deliveryFee.toInt()}'),
          const Divider(height: AppSpacing.lg),
          _Row(
            label: 'Total',
            value: 'Rs. ${order.totalAmount.toInt()}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _Row({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: isTotal
                ? AppTypography.headingSmall
                : AppTypography.bodyMedium),
        Text(value,
            style: isTotal
                ? AppTypography.priceMedium
                : AppTypography.bodyMedium),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusLg,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value, style: AppTypography.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}