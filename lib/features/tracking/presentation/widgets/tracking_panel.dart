import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../../orders/presentation/widgets/order_labels.dart';
import '../../domain/models/delivery_position_model.dart';

class TrackingPanel extends StatefulWidget {
  const TrackingPanel({super.key, required this.order, required this.position});

  final OrderModel? order;
  final DeliveryPositionModel? position;

  @override
  State<TrackingPanel> createState() => _TrackingPanelState();
}

class _TrackingPanelState extends State<TrackingPanel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps "updated 2m ago" honest while the screen stays open.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;
    final order = widget.order;
    final position = widget.position;

    String? stateLine;
    if (order?.status == OrderStatus.delivered) stateLine = o.trackingDelivered;
    if (order?.status == OrderStatus.cancelled) stateLine = o.trackingCancelled;

    return Material(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: p.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order != null)
              Row(
                children: [
                  AppStatusBadge(status: order.status),
                  const Spacer(),
                  Text(AppFormat.orderCode(order.id), style: text.hint),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(
                    position == null
                        ? Icons.location_searching_rounded
                        : Icons.my_location_rounded,
                    size: 20,
                    color: position == null ? p.textHint : p.brand,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      stateLine ??
                          (position == null
                              ? o.waitingForRiderTitle
                              : o.riderUpdated(AppFormat.timeAgo(
                                  context, position.recordedAt))),
                      style: text.label,
                    ),
                  ),
                ],
              ),
            ),
            if (position == null && stateLine == null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(o.waitingForRiderBody, style: text.caption),
              ),
            ],
            if (order != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(height: 1, color: p.border),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(OrderLabels.restaurant(context, order),
                            style: text.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(OrderLabels.itemsSummary(context, order),
                            style: text.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(AppFormat.money(context, order.totalAmount),
                      style: text.price),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (order != null) ...[
                  Expanded(
                    child: AppButton(
                      label: o.viewOrder,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.medium,
                      leadingIcon: Icons.receipt_long_outlined,
                      // Tracking is opened from the order detail, so going "to" the order is usually just going back.
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context
                              .push('${RouteNames.orderDetail}/${order.id}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: AppButton(
                    label: o.contactSupport,
                    variant: AppButtonVariant.tonal,
                    size: AppButtonSize.medium,
                    leadingIcon: Icons.support_agent_rounded,
                    onPressed: () => context.push(RouteNames.support),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
