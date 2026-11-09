import 'package:flutter/material.dart';
import '../../../../core/l10n/strings/admin_strings.dart';
import '../../domain/admin_models.dart';

/// The eleven areas of the admin console, in navigation order.
enum AdminSection {
  overview(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  users(Icons.people_outline_rounded, Icons.people_rounded),
  restaurants(Icons.storefront_outlined, Icons.storefront_rounded),
  riders(Icons.two_wheeler_outlined, Icons.two_wheeler_rounded),
  orders(Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  coupons(Icons.local_offer_outlined, Icons.local_offer_rounded),
  support(Icons.support_agent_outlined, Icons.support_agent_rounded),
  refunds(Icons.currency_exchange_outlined, Icons.currency_exchange_rounded),
  cash(Icons.payments_outlined, Icons.payments_rounded),
  audit(Icons.history_outlined, Icons.history_rounded),
  settings(Icons.tune_outlined, Icons.tune_rounded);

  const AdminSection(this.icon, this.selectedIcon);
  final IconData icon;
  final IconData selectedIcon;

  String label(AdminStrings s) => switch (this) {
        overview => s.navOverview,
        users => s.navUsers,
        restaurants => s.navRestaurants,
        riders => s.navRiders,
        orders => s.navOrders,
        coupons => s.navCoupons,
        support => s.navSupport,
        refunds => s.navRefunds,
        cash => s.navCash,
        audit => s.navAudit,
        settings => s.navSettings,
      };

  String subtitle(AdminStrings s) => switch (this) {
        overview => s.subOverview,
        users => s.subUsers,
        restaurants => s.subRestaurants,
        riders => s.subRiders,
        orders => s.subOrders,
        coupons => s.subCoupons,
        support => s.subSupport,
        refunds => s.subRefunds,
        cash => s.subCash,
        audit => s.subAudit,
        settings => s.subSettings,
      };

  /// Items waiting for an admin in this section (navigation badge).
  int badge(AdminOverview? o) {
    if (o == null) return 0;
    return switch (this) {
      restaurants => o.pendingRestaurants,
      riders => o.pendingRiders,
      support => o.openTickets,
      refunds => o.pendingRefunds,
      cash => o.pendingSettlements,
      _ => 0,
    };
  }
}
