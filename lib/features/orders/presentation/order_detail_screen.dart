import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/orders/application/order_provider.dart';
import '../../../features/orders/domain/models/order_model.dart';
import '../../../features/payments/application/refund_provider.dart';
import '../../../features/reviews/presentation/rate_order_sheet.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/order_timeline_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync    = ref.watch(orderStreamProvider(orderId));
    final timelineAsync = ref.watch(orderTimelineProvider(orderId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Order #${orderId.substring(0, 8).toUpperCase()}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const Center(child: Text('Could not load order')),
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            children: [
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.md), borderRadius: AppSpacing.radiusLg,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(order.restaurantName, style: AppTypography.headingSmall),
                    _StatusChip(status: order.status),
                  ]),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Placed on ${_fmt(order.createdAt)}', style: AppTypography.bodySmall),
                  if (order.status == OrderStatus.pickedUp) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Track Rider on Map',
                      isOutlined: true,
                      leadingIcon: Icons.map_outlined,
                      onPressed: () => context.push('${RouteNames.tracking}/${order.id}'),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Items', style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(children: [
                  Text('${item.quantity}×', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item.name, style: AppTypography.bodyMedium)),
                  Text('Rs. ${(item.price * item.quantity).toInt()}', style: AppTypography.bodyMedium),
                ]),
              )),
              const Divider(height: AppSpacing.lg),
              _Row('Subtotal', 'Rs. ${(order.totalAmount - order.deliveryFee).toInt()}'),
              _Row('Delivery Fee', 'Rs. ${order.deliveryFee.toInt()}'),
              _Row('Total', 'Rs. ${order.totalAmount.toInt()}', bold: true),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(order.deliveryAddress!, style: AppTypography.bodySmall)),
                ]),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Order Timeline', style: AppTypography.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              timelineAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
                error: (_, __) => const SizedBox.shrink(),
                data: (events) {
                  if (events.isEmpty) return Text('No timeline events yet', style: AppTypography.bodySmall);
                  return Column(children: events.asMap().entries
                      .map((e) => _TimelineItem(event: e.value, isLast: e.key == events.length - 1))
                      .toList());
                },
              ),
              if (order.status == OrderStatus.delivered) ...[
                const SizedBox(height: AppSpacing.lg),
                Consumer(builder: (context, ref, _) {
                  final ratedAsync = ref.watch(orderRatingProvider(order.id));
                  return ratedAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (alreadyRated) {
                      if (alreadyRated) {
                        return Row(children: [
                          const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text('You reviewed this order', style: AppTypography.bodyMedium),
                        ]);
                      }
                      return AppButton(
                        label: 'Rate Your Order',
                        isOutlined: true,
                        onPressed: () => RateOrderSheet.show(
                          context,
                          orderId: order.id,
                          customerId: order.customerId,
                          restaurantId: order.restaurantId,
                          restaurantName: order.restaurantName,
                        ),
                      );
                    },
                  );
                }),
              ],
              if (order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showRefundDialog(context, order),
                    icon: const Icon(Icons.currency_exchange_rounded, size: 16),
                    label: const Text('Request Refund'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  void _showRefundDialog(BuildContext context, OrderModel order) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Rs. ${order.totalAmount.toInt()} will be requested for review.',
              style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Reason', hintText: 'What went wrong?'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          Consumer(builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ref.read(refundNotifierProvider.notifier).requestRefund(
                      orderId: order.id,
                      amount: order.totalAmount,
                      reason: reasonController.text.trim().isEmpty
                          ? null
                          : reasonController.text.trim(),
                    );
                if (context.mounted) {
                  if (ok) {
                    AppSnackbar.success(context, 'Refund requested. We\'ll review it shortly.');
                  } else {
                    AppSnackbar.error(context, 'Could not request refund. Please try again.');
                  }
                }
              },
              child: const Text('Submit Request'),
            );
          }),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:   return AppColors.statusPending;
      case OrderStatus.confirmed: return AppColors.statusConfirmed;
      case OrderStatus.preparing: return AppColors.statusPreparing;
      case OrderStatus.ready:     return AppColors.statusReady;
      case OrderStatus.pickedUp:  return AppColors.statusDelivering;
      case OrderStatus.delivered: return AppColors.statusDelivered;
      case OrderStatus.cancelled: return AppColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: _color.withValues(alpha: 0.3))),
      child: Text(status.label, style: AppTypography.labelSmall.copyWith(color: _color)),
    );
  }
}

class _Row extends StatelessWidget {
  final String label; final String value; final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final s = bold ? AppTypography.headingSmall : AppTypography.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: s),
        Text(value, style: s.copyWith(color: bold ? AppColors.primary : null)),
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final OrderTimelineEvent event; final bool isLast;
  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 24, child: Column(children: [
        Container(width: 12, height: 12,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
      ])),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(event.statusLabel, style: AppTypography.bodyMedium),
          Text('${event.createdAt.hour}:${event.createdAt.minute.toString().padLeft(2, '0')}',
              style: AppTypography.bodySmall),
        ]),
      )),
    ]));
  }
}