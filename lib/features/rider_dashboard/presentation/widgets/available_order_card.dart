import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../orders/application/order_provider.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../../rider/application/rider_cash_providers.dart';
import '../../../rider/application/rider_settings.dart';
import '../../../rider/domain/entities/delivery_info.dart';
import 'delivery_route.dart';
import 'rider_chip.dart';

class AvailableOrderCard extends ConsumerStatefulWidget {
  const AvailableOrderCard({
    super.key,
    required this.order,
    required this.riderId,
    required this.settings,
    this.info,
    this.cashInHand,
    this.canAccept = true,
  });

  final OrderModel order;
  final String riderId;
  final RiderSettings settings;

  /// Payment method / pickup address; null while loading.
  final DeliveryInfo? info;

  /// Null while the balance is loading.
  final double? cashInHand;
  final bool canAccept;

  @override
  ConsumerState<AvailableOrderCard> createState() => _AvailableOrderCardState();
}

class _AvailableOrderCardState extends ConsumerState<AvailableOrderCard> {
  bool _accepting = false;

  bool get _overCashLimit {
    final info = widget.info;
    final cash = widget.cashInHand;
    if (info == null || !info.mustCollectCash || cash == null) return false;
    return widget.settings.wouldExceedLimit(
        cashInHand: cash, orderTotal: widget.order.totalAmount);
  }

  Future<void> _accept() async {
    final r = context.s.rider;
    final limitText = AppFormat.money(context, widget.settings.codCashLimit);
    if (_overCashLimit) {
      AppSnackbar.warning(context, r.cashLimitReached(limitText));
      return;
    }
    setState(() => _accepting = true);
    final success = await ref
        .read(orderStatusNotifierProvider.notifier)
        .assignRider(widget.order.id, widget.riderId);
    if (!mounted) return;
    setState(() => _accepting = false);

    if (success) {
      ref.invalidate(riderOrdersTodayProvider(widget.riderId));
      AppSnackbar.success(context, r.acceptedSuccess);
      return;
    }

    final error = ref.read(orderStatusNotifierProvider).error;
    final raw = error?.toString().toLowerCase() ?? '';
    if (raw.contains('already taken') || raw.contains('cannot take')) {
      ref.invalidate(riderCashBalanceProvider(widget.riderId));
      final isCash = widget.info?.mustCollectCash ?? false;
      final cash = widget.cashInHand;
      final overLimit = isCash &&
          cash != null &&
          widget.settings.wouldExceedLimit(
              cashInHand: cash, orderTotal: widget.order.totalAmount);
      AppSnackbar.warning(
          context, overLimit ? r.cashLimitReached(limitText) : r.alreadyTaken);
    } else {
      AppSnackbar.error(
          context, error ?? UserFacingException(context.s.common.errGeneric));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final order = widget.order;
    final info = widget.info;
    final earning = widget.settings.estimatedEarning(order.deliveryFee);
    final pickup = [
      order.restaurantName,
      if ((info?.restaurantAddress ?? '').trim().isNotEmpty)
        info!.restaurantAddress!.trim()
    ].join(', ');
    final drop = (order.deliveryAddress ?? '').trim().isEmpty
        ? r.noAddress
        : order.deliveryAddress!.trim();
    final overLimit = _overCashLimit;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.restaurantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingSmall
                            .copyWith(color: p.textPrimary)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${AppFormat.orderCode(order.id)} · ${r.itemsCount(order.items.length)} · '
                      '${AppFormat.timeAgo(context, order.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall
                          .copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(AppFormat.money(context, earning),
                      style: AppTypography.priceLarge.copyWith(color: p.brand)),
                  Text(r.youEarn,
                      style: AppTypography.labelSmall
                          .copyWith(color: p.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RouteSummary(pickup: pickup, dropOff: drop),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (info != null)
                info.mustCollectCash
                    ? RiderChip(
                        label:
                            '${r.cashTag} ${AppFormat.money(context, order.totalAmount)}',
                        icon: Icons.payments_outlined,
                        tone: RiderTone.warning,
                      )
                    : RiderChip(
                        label: r.paidOnlineTag,
                        icon: Icons.verified_outlined,
                        tone: RiderTone.success),
              if (overLimit)
                RiderChip(
                    label: r.overCashLimit,
                    icon: Icons.block_rounded,
                    tone: RiderTone.error),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: r.accept,
            leadingIcon: Icons.check_rounded,
            isLoading: _accepting,
            onPressed:
                (!widget.canAccept || overLimit || _accepting) ? null : _accept,
          ),
        ],
      ),
    );
  }
}
