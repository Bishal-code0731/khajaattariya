import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/order_items_list.dart';
import '../../../orders/application/order_provider.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../../payments/application/payment_provider.dart';
import '../../../rider/application/rider_cash_providers.dart';
import '../../../rider/application/rider_delivery_providers.dart';
import '../../../rider/application/rider_provider.dart';
import '../../../rider/application/rider_settings.dart';
import 'delivery_route.dart';
import 'rider_actions.dart';
import 'rider_chip.dart';

class ActiveDeliveryCard extends ConsumerStatefulWidget {
  const ActiveDeliveryCard(
      {super.key, required this.order, required this.riderId});

  final OrderModel order;
  final String riderId;

  @override
  ConsumerState<ActiveDeliveryCard> createState() => _ActiveDeliveryCardState();
}

class _ActiveDeliveryCardState extends ConsumerState<ActiveDeliveryCard> {
  bool _submitting = false;

  Future<void> _markDelivered(bool collectCash) async {
    final r = context.s.rider;
    final order = widget.order;
    final ok = await AppDialog.confirm(
      context,
      title: r.confirmDeliveredTitle,
      message: collectCash
          ? r.confirmDeliveredCash(AppFormat.money(context, order.totalAmount))
          : r.confirmDeliveredOnline,
      confirmLabel: r.markDelivered,
      icon: Icons.check_circle_outline_rounded,
    );
    if (!ok || !mounted) return;

    setState(() => _submitting = true);
    final success = await ref
        .read(orderStatusNotifierProvider.notifier)
        .updateStatus(order.id, OrderStatus.delivered);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ref
        ..invalidate(riderProfileProvider(widget.riderId))
        ..invalidate(riderEarningsProvider(widget.riderId))
        ..invalidate(riderCashBalanceProvider(widget.riderId))
        ..invalidate(riderCashLedgerProvider(widget.riderId))
        ..invalidate(riderOrdersTodayProvider(widget.riderId));
      AppSnackbar.success(context, r.deliveredSuccess);
    } else {
      AppSnackbar.error(context, ref.read(orderStatusNotifierProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final order = widget.order;
    final info =
        ref.watch(activeDeliveryInfoProvider(widget.riderId)).valueOrNull;
    final settings =
        RiderSettings.from(ref.watch(platformSettingsProvider).valueOrNull);
    final collectCash = info?.mustCollectCash ?? false;
    final dropAddress = order.deliveryAddress?.trim() ?? '';
    final pickupAddress = info?.restaurantAddress?.trim() ?? '';
    final restaurantPhone = info?.restaurantPhone?.trim() ?? '';
    final notes = order.notes?.trim() ?? '';

    return AppCard(
      elevated: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: p.brandSoft,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.delivery_dining_rounded, color: p.onBrandSoft),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(r.activeDelivery,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge
                          .copyWith(color: p.onBrandSoft)),
                ),
                Text(AppFormat.orderCode(order.id),
                    style: AppTypography.labelMedium
                        .copyWith(color: p.onBrandSoft)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeliveryStepProgress(
                    delivered: order.status == OrderStatus.delivered),
                const SizedBox(height: AppSpacing.xl),
                DeliveryStop(
                  icon: Icons.storefront_rounded,
                  label: r.pickupFrom,
                  title: order.restaurantName,
                  subtitle: pickupAddress,
                  actions: [
                    if (restaurantPhone.isNotEmpty)
                      IconButton(
                        tooltip: r.callRestaurant,
                        icon: const Icon(Icons.call_outlined),
                        onPressed: () => callPhone(context, restaurantPhone),
                      ),
                    if (pickupAddress.isNotEmpty)
                      IconButton(
                        tooltip: r.openInMaps,
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () => openAddressInMaps(
                            context, '${order.restaurantName}, $pickupAddress'),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(width: 2, height: 20, color: p.border),
                  ),
                ),
                DeliveryStop(
                  icon: Icons.location_on_rounded,
                  label: r.dropAt,
                  title: dropAddress.isEmpty ? r.noAddress : dropAddress,
                  highlight: true,
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _NoteBox(note: notes),
                ],
                const SizedBox(height: AppSpacing.lg),
                Divider(height: 1, color: p.border),
                const SizedBox(height: AppSpacing.md),
                Text('${r.itemsTitle} · ${r.itemsCount(order.items.length)}',
                    style: AppTypography.labelMedium
                        .copyWith(color: p.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                OrderItemsList(items: order.items),
                const SizedBox(height: AppSpacing.md),
                _MoneyPanel(
                    order: order,
                    collectCash: collectCash,
                    infoKnown: info != null),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: r.openInMaps,
                        leadingIcon: Icons.navigation_outlined,
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.medium,
                        onPressed: dropAddress.isEmpty
                            ? null
                            : () => openAddressInMaps(context, dropAddress),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: settings.supportPhone != null
                            ? r.callSupport
                            : r.getHelp,
                        leadingIcon: Icons.support_agent_rounded,
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.medium,
                        onPressed: () =>
                            contactSupport(context, settings.supportPhone),
                      ),
                    ),
                  ],
                ),
                if (order.status == OrderStatus.pickedUp) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: r.markDelivered,
                    leadingIcon: Icons.check_circle_rounded,
                    isLoading: _submitting,
                    onPressed:
                        _submitting ? null : () => _markDelivered(collectCash),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: p.infoSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 20, color: p.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.rider.customerNote,
                    style: AppTypography.labelSmall
                        .copyWith(color: p.textSecondary)),
                Text(note,
                    style: AppTypography.bodyMedium
                        .copyWith(color: p.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Order total plus what (if anything) the rider must collect.
class _MoneyPanel extends StatelessWidget {
  const _MoneyPanel(
      {required this.order,
      required this.collectCash,
      required this.infoKnown});

  final OrderModel order;
  final bool collectCash;
  final bool infoKnown;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final total = AppFormat.money(context, order.totalAmount);

    if (collectCash) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: p.accent),
        ),
        child: Row(
          children: [
            Icon(Icons.payments_rounded, color: p.textPrimary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.collectCash(total),
                      style: AppTypography.priceLarge
                          .copyWith(color: p.textPrimary)),
                  Text(r.collectCashHint,
                      style: AppTypography.bodySmall
                          .copyWith(color: p.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
            child: Text(r.orderTotal,
                style:
                    AppTypography.bodyMedium.copyWith(color: p.textSecondary))),
        if (infoKnown) ...[
          Flexible(
              child: RiderChip(
                  label: r.paidOnlineTag,
                  icon: Icons.verified_rounded,
                  tone: RiderTone.success)),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(total,
            style: AppTypography.priceMedium.copyWith(color: p.textPrimary)),
      ],
    );
  }
}
