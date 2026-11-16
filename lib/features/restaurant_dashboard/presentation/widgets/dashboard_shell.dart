import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/glass_bottom_nav.dart';
import '../../../orders/application/order_provider.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../domain/models/owner_restaurant.dart';
import '../order_prep_gantt_view.dart';
import '../restaurant_analytics_tab.dart';
import 'approval_banner.dart';
import 'dashboard_header.dart';
import 'orders_board.dart';
import 'restaurant_settings_tab.dart';

/// Width from which the dashboard switches to a NavigationRail layout.
const _railBreakpoint = 1000.0;

/// Orders / Timeline / Analytics / Settings.
class RestaurantDashboardShell extends ConsumerStatefulWidget {
  const RestaurantDashboardShell(
      {super.key, required this.restaurant, required this.ownerId});

  final OwnerRestaurant restaurant;
  final String ownerId;

  @override
  ConsumerState<RestaurantDashboardShell> createState() =>
      _RestaurantDashboardShellState();
}

class _RestaurantDashboardShellState
    extends ConsumerState<RestaurantDashboardShell> {
  int _index = 0;
  OrderBoardSegment _segment = OrderBoardSegment.fresh;

  Widget _page() {
    final r = widget.restaurant;
    return switch (_index) {
      0 => OrdersBoard(
          restaurantId: r.id,
          segment: _segment,
          onSegmentChanged: (seg) => setState(() => _segment = seg),
        ),
      1 => OrderPrepGanttView(restaurantId: r.id),
      2 => RestaurantAnalyticsTab(restaurantId: r.id, restaurantName: r.name),
      _ => RestaurantSettingsTab(restaurant: r, ownerId: widget.ownerId),
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final newCount =
        ref.watch(restaurantOrdersProvider(widget.restaurant.id).select(
      (a) =>
          a.valueOrNull?.where((o) => o.status == OrderStatus.pending).length ??
          0,
    ));

    final items = [
      (
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        s.navOrders,
        newCount
      ),
      (
        Icons.view_timeline_outlined,
        Icons.view_timeline_rounded,
        s.navTimeline,
        0
      ),
      (Icons.insights_outlined, Icons.insights_rounded, s.navAnalytics, 0),
      (Icons.storefront_outlined, Icons.storefront_rounded, s.navSettings, 0),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= _railBreakpoint;
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardHeader(
              restaurant: widget.restaurant,
              ownerId: widget.ownerId,
              wide: wide),
          ApprovalBanner(restaurant: widget.restaurant),
          Expanded(
            child: wide
                ? Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth),
                      child: _page(),
                    ),
                  )
                : _page(),
          ),
        ],
      );

      if (!wide) {
        return Scaffold(
          body: content,
          bottomNavigationBar: GlassBottomNav(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: [
              for (final it in items)
                GlassNavItem(
                    icon: it.$1,
                    selectedIcon: it.$2,
                    label: it.$3,
                    badgeCount: it.$4),
            ],
          ),
        );
      }

      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                backgroundColor: p.surface,
                minWidth: 88,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: AppLogoMark(),
                ),
                destinations: [
                  for (final it in items)
                    NavigationRailDestination(
                      icon: it.$4 > 0
                          ? Badge.count(count: it.$4, child: Icon(it.$1))
                          : Icon(it.$1),
                      selectedIcon: it.$4 > 0
                          ? Badge.count(count: it.$4, child: Icon(it.$2))
                          : Icon(it.$2),
                      label: Text(it.$3),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: p.border),
            Expanded(child: content),
          ],
        ),
      );
    });
  }
}
