import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../reviews/presentation/rate_order_sheet.dart';
import '../../application/order_provider.dart';
import '../../domain/models/order_model.dart';
import 'order_labels.dart';
import 'order_progress_stepper.dart';

/// One order in the "Your orders" list.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onOrderAgain,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onOrderAgain;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final name = OrderLabels.restaurant(context, order);
    final statusLabel = OrderStatusStyle.label(context, order.status);

    return Semantics(
      container: true,
      label: context.s.orders.orderCardLabel(name, statusLabel),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkImage(
                  url: order.restaurantImageUrl,
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: text.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${AppFormat.orderCode(order.id)} · ${AppFormat.dateTime(context, order.createdAt)}',
                        style: text.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppStatusBadge(status: order.status, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              OrderLabels.itemsSummary(context, order),
              style: text.secondary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (order.status.isActive) ...[
              const SizedBox(height: AppSpacing.md),
              OrderProgressBar(status: order.status),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: p.border),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppFormat.money(context, order.totalAmount),
                    style: text.price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.textHint),
              ],
            ),
            if (!order.status.isActive) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (order.status == OrderStatus.delivered)
                    _RateButton(order: order),
                  Expanded(
                    child: AppButton(
                      label: context.s.orders.orderAgain,
                      leadingIcon: Icons.replay_rounded,
                      variant: AppButtonVariant.tonal,
                      size: AppButtonSize.medium,
                      onPressed: onOrderAgain,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Rate" — only while the delivered order has no rating yet.
class _RateButton extends ConsumerWidget {
  const _RateButton({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rated = ref.watch(orderRatingProvider(order.id)).valueOrNull;
    if (rated != false) return const SizedBox.shrink();
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: AppButton(
          label: context.s.orders.rate,
          leadingIcon: Icons.star_outline_rounded,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
          onPressed: () => RateOrderSheet.show(
            context,
            orderId: order.id,
            customerId: order.customerId,
            restaurantId: order.restaurantId,
            restaurantName: OrderLabels.restaurant(context, order),
          ),
        ),
      ),
    );
  }
}
