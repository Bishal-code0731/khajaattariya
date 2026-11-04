import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/order_timeline_provider.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../domain/models/order_model.dart';
import 'order_progress_stepper.dart';

class OrderStatusCard extends ConsumerWidget {
  const OrderStatusCard({
    super.key,
    required this.order,
    required this.isCustomer,
  });

  final OrderModel order;
  final bool isCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.text;
    final events = ref.watch(orderTimelineProvider(order.id));
    final style = OrderStatusStyle.of(order.status);
    final cancelled = order.status == OrderStatus.cancelled;
    final accent = cancelled ? p.error : p.brand;
    final accentSoft = cancelled ? p.errorSoft : p.brandSoft;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: accentSoft,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(style.icon,
                      color: cancelled ? p.surface : p.onBrand, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          cancelled
                              ? context.s.orders.orderCancelledTitle
                              : OrderStatusStyle.label(context, order.status),
                          style: text.h2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(_hint(context, events.valueOrNull),
                          style: text.secondary),
                      if (cancelled &&
                          (order.cancelReason ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.s.orders
                              .cancelReasonLine(order.cancelReason!.trim()),
                          style: text.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: events.when(
              skipLoadingOnRefresh: true,
              loading: () => Column(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.lg),
                    const AppShimmer(height: 18),
                  ],
                ],
              ),
              // The timeline only adds times; the steps still show.
              error: (_, __) =>
                  OrderProgressStepper(status: order.status, events: const []),
              data: (list) =>
                  OrderProgressStepper(status: order.status, events: list),
            ),
          ),
        ],
      ),
    );
  }

  String _hint(BuildContext context, List<OrderTimelineEvent>? events) {
    final o = context.s.orders;
    DateTime? at(String status) {
      for (final e in events ?? const <OrderTimelineEvent>[]) {
        if (e.status == status) return e.createdAt;
      }
      return null;
    }

    switch (order.status) {
      case OrderStatus.pending:
        return isCustomer ? o.hintPendingCustomer : o.hintPending;
      case OrderStatus.confirmed:
        return o.hintConfirmed;
      case OrderStatus.preparing:
        return o.hintPreparing;
      case OrderStatus.ready:
        return o.hintReady;
      case OrderStatus.pickedUp:
        return isCustomer ? o.hintPickedUp : o.hintPickedUpOther;
      case OrderStatus.delivered:
        final when = at('delivered') ?? order.updatedAt;
        if (when == null) return OrderStatusStyle.label(context, order.status);
        final time = AppFormat.time(context, when);
        return isCustomer ? o.deliveredAt(time) : o.deliveredAtOther(time);
      case OrderStatus.cancelled:
        final when = at('cancelled') ?? order.updatedAt;
        return when == null
            ? o.hintCancelled
            : o.cancelledAt(AppFormat.dateTime(context, when));
    }
  }
}
