import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/s.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../auth/application/auth_provider.dart';
import '../../orders/application/order_provider.dart';
import '../../orders/domain/models/order_model.dart';
import '../../rider/application/rider_cash_providers.dart';
import '../../rider/application/rider_provider.dart';
import '../../tracking/application/tracking_provider.dart';
import 'rider_schedule_gantt_view.dart';
import 'widgets/cash_tab.dart';
import 'widgets/deliveries_tab.dart';
import 'widgets/earnings_tab.dart';
import 'widgets/rider_page.dart';
import 'widgets/vehicle_tab.dart';

/// Rider home: deliveries, earnings, cash in hand, today's timeline and vehicle/approval.
class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  static const _deliveriesTab = 0;
  static const _vehicleTab = 4;

  int _tab = _deliveriesTab;
  String? _statusLoadedFor;

  Future<void> _toggleOnline(String riderId) async {
    final r = context.s.rider;
    final wasOnline =
        ref.read(riderOnlineNotifierProvider).valueOrNull ?? false;
    final error =
        await ref.read(riderOnlineNotifierProvider.notifier).toggle(riderId);
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.info(context, wasOnline ? r.wentOffline : r.wentOnline);
    }
  }

  Future<void> _refreshDeliveries(String riderId) async {
    ref
      ..invalidate(riderProfileProvider(riderId))
      ..invalidate(riderCashBalanceProvider(riderId))
      ..invalidate(availableOrdersProvider);
    await ref.read(riderOnlineNotifierProvider.notifier).loadStatus(riderId);
  }

  Future<void> _logout() async {
    final r = context.s.rider;
    final ok = await AppDialog.confirm(
      context,
      title: r.logoutConfirmTitle,
      message: r.logoutConfirmBody,
      confirmLabel: context.s.common.logout,
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!ok || !mounted) return;
    // A signed-out rider must not keep sending GPS pings.
    ref.read(riderLocationBroadcasterProvider.notifier).stop();
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.s.rider;
    final authState = ref.watch(authStateProvider);
    if (authState.isLoading) {
      return const Scaffold(body: AppLoader.fullscreen());
    }
    final user = authState.valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppTopBar(title: r.dashboardTitle, showBack: false),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: r.loginRequiredTitle,
          subtitle: r.loginRequiredBody,
          action: AppButton(
            label: context.s.common.login,
            expand: false,
            onPressed: () => context.go(RouteNames.login),
          ),
        ),
      );
    }

    if (_statusLoadedFor != user.id) {
      _statusLoadedFor = user.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(riderOnlineNotifierProvider.notifier).loadStatus(user.id);
      });
    }

    ref.listen<AsyncValue<OrderModel?>>(riderActiveOrderProvider(user.id),
        (_, next) {
      final order = next.valueOrNull;
      final broadcaster = ref.read(riderLocationBroadcasterProvider.notifier);
      if (order != null && order.status == OrderStatus.pickedUp) {
        broadcaster.start(orderId: order.id, riderId: user.id);
      } else if (!next.isLoading) {
        broadcaster.stop();
      }
    });

    final onlineState = ref.watch(riderOnlineNotifierProvider);
    final isOnline = onlineState.valueOrNull ?? false;
    final rider = ref.watch(riderProfileProvider(user.id)).valueOrNull;
    final hasActive =
        ref.watch(riderActiveOrderProvider(user.id)).valueOrNull != null;
    final firstName = user.fullName.trim().split(RegExp(r'\s+')).first;

    final destinations = [
      GlassNavItem(
        icon: Icons.delivery_dining_outlined,
        selectedIcon: Icons.delivery_dining_rounded,
        label: r.tabDeliveries,
        badgeCount: hasActive ? 1 : 0,
      ),
      GlassNavItem(
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
        label: r.tabEarnings,
      ),
      GlassNavItem(
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments_rounded,
          label: r.tabCash),
      GlassNavItem(
          icon: Icons.timeline_outlined,
          selectedIcon: Icons.timeline_rounded,
          label: r.tabSchedule),
      GlassNavItem(
          icon: Icons.two_wheeler_outlined,
          selectedIcon: Icons.two_wheeler_rounded,
          label: r.tabProfile),
    ];

    final page = switch (_tab) {
      0 => DeliveriesTab(
          riderId: user.id,
          rider: rider,
          isOnline: isOnline,
          isToggling: onlineState.isLoading,
          onToggleOnline: () => _toggleOnline(user.id),
          onOpenVehicleTab: () => setState(() => _tab = _vehicleTab),
          onRefresh: () => _refreshDeliveries(user.id),
        ),
      1 => EarningsTab(riderId: user.id, rider: rider),
      2 => CashTab(riderId: user.id),
      3 => RiderPage(
          maxWidth: 960,
          onRefresh: () async =>
              ref.invalidate(riderOrdersTodayProvider(user.id)),
          children: [RiderScheduleGanttView(riderId: user.id)],
        ),
      _ => VehicleTab(riderId: user.id, phone: user.phone, onLogout: _logout),
    };

    final isWide = MediaQuery.sizeOf(context).width >= 1000;
    final p = context.palette;

    return Scaffold(
      appBar: AppTopBar(
        title: firstName.isEmpty ? r.dashboardTitle : r.greeting(firstName),
        subtitle:
            '${r.dashboardTitle} · ${isOnline ? r.statusOnline : r.statusOffline}',
        showBack: false,
        actions: [
          IconButton(
            tooltip: r.accountTooltip,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(RouteNames.profile),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: d.badgeCount > 0
                            ? Badge.count(
                                count: d.badgeCount, child: Icon(d.icon))
                            : Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon ?? d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: p.border),
                Expanded(child: page),
              ],
            )
          : page,
      bottomNavigationBar: isWide
          ? null
          : GlassBottomNav(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              items: destinations,
            ),
    );
  }
}
