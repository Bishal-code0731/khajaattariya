import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../orders/application/order_provider.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../../payments/application/payment_provider.dart';
import '../../../rider/application/rider_cash_providers.dart';
import '../../../rider/application/rider_delivery_providers.dart';
import '../../../rider/application/rider_settings.dart';
import '../../../rider/domain/models/rider_model.dart';
import 'active_delivery_card.dart';
import 'approval_banner.dart';
import 'available_order_card.dart';
import 'online_status_panel.dart';
import 'rider_page.dart';

/// Main tab: online switch, then either the current job or the list of orders ready for pickup.
class DeliveriesTab extends ConsumerWidget {
  const DeliveriesTab({
    super.key,
    required this.riderId,
    required this.rider,
    required this.isOnline,
    required this.isToggling,
    required this.onToggleOnline,
    required this.onOpenVehicleTab,
    required this.onRefresh,
  });

  final String riderId;
  final RiderModel? rider;
  final bool isOnline;
  final bool isToggling;
  final VoidCallback onToggleOnline;
  final VoidCallback onOpenVehicleTab;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.s.rider;
    final approval = approvalStateOf(rider);
    final isApproved = approval == RiderApprovalState.approved;
    final activeAsync = ref.watch(riderActiveOrderProvider(riderId));

    return RiderPage(
      onRefresh: onRefresh,
      maxWidth: 960,
      children: [
        OnlineStatusPanel(
          isOnline: isOnline,
          isBusy: isToggling,
          canGoOnline: isApproved,
          onToggle: onToggleOnline,
        ),
        if (!isApproved) ...[
          const SizedBox(height: AppSpacing.md),
          ApprovalBanner(
            rider: rider,
            onAction: onOpenVehicleTab,
            actionLabel: approval == RiderApprovalState.notRegistered
                ? r.registerNow
                : r.viewDetails,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        activeAsync.when(
          skipLoadingOnReload: true,
          loading: () => const _CardSkeletons(count: 1),
          error: (e, _) => AppErrorState(
              error: e,
              onRetry: () => ref.invalidate(riderActiveOrderProvider(riderId))),
          data: (active) {
            if (active != null) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ActiveDeliveryCard(order: active, riderId: riderId),
                ),
              );
            }
            if (!isOnline) {
              return AppEmptyState(
                icon: Icons.power_settings_new_rounded,
                title: r.offlineTitle,
                subtitle: isApproved ? r.offlineEmptyBody : r.lockedSubtitle,
                action: isApproved
                    ? AppButton(
                        label: r.goOnline,
                        leadingIcon: Icons.power_settings_new_rounded,
                        expand: false,
                        isLoading: isToggling,
                        onPressed: onToggleOnline,
                      )
                    : null,
              );
            }
            return _AvailableOrders(riderId: riderId, canAccept: isApproved);
          },
        ),
      ],
    );
  }
}

class _AvailableOrders extends ConsumerWidget {
  const _AvailableOrders({required this.riderId, required this.canAccept});

  final String riderId;
  final bool canAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.s.rider;
    final ordersAsync = ref.watch(availableOrdersProvider);
    final infoMap =
        ref.watch(availableDeliveryInfoProvider).valueOrNull ?? const {};
    final cashInHand = ref.watch(riderCashBalanceProvider(riderId)).valueOrNull;
    final settings =
        RiderSettings.from(ref.watch(platformSettingsProvider).valueOrNull);

    return ordersAsync.when(
      skipLoadingOnReload: true,
      loading: () => const _CardSkeletons(count: 3),
      error: (e, _) => AppErrorState(
          error: e, onRetry: () => ref.invalidate(availableOrdersProvider)),
      data: (orders) {
        if (orders.isEmpty) {
          return AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: r.noOrdersTitle,
            subtitle: r.noOrdersBody,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RiderSectionTitle(
                title: r.availableTitle,
                subtitle: r.availableSubtitle(orders.length)),
            _OrderGrid(
              orders: orders,
              builder: (order) => AvailableOrderCard(
                key: ValueKey(order.id),
                order: order,
                riderId: riderId,
                settings: settings,
                info: infoMap[order.id],
                cashInHand: cashInHand,
                canAccept: canAccept,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One column on phones, two from 600 px.
class _OrderGrid extends StatelessWidget {
  const _OrderGrid({required this.orders, required this.builder});

  final List<OrderModel> orders;
  final Widget Function(OrderModel) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final o in orders) SizedBox(width: width, child: builder(o))
          ],
        );
      },
    );
  }
}

class _CardSkeletons extends StatelessWidget {
  const _CardSkeletons({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          AppShimmer(
              height: 180,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        ],
      ],
    );
  }
}
