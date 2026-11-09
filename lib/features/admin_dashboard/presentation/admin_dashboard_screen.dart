import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/application/auth_provider.dart';
import '../../payments/application/payment_provider.dart';
import '../../rider/application/rider_provider.dart';
import '../../support/application/support_provider.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/admin_queries.dart';
import '../domain/admin_models.dart';
import 'sections/audit_section.dart';
import 'sections/cash_section.dart';
import 'sections/coupons_section.dart';
import 'sections/orders_section.dart';
import 'sections/overview_section.dart';
import 'sections/refunds_section.dart';
import 'sections/restaurants_section.dart';
import 'sections/riders_section.dart';
import 'sections/settings_section.dart';
import 'sections/support_section.dart';
import 'sections/users_section.dart';
import 'widgets/admin_section.dart';

/// Admin console shell.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  AdminSection _section = AdminSection.overview;

  void _go(AdminSection section) => setState(() => _section = section);

  void _refresh() {
    ref.invalidate(adminOverviewProvider);
    switch (_section) {
      case AdminSection.overview:
        ref.invalidate(adminOrdersProvider);
      case AdminSection.users:
        ref.invalidate(adminUsersProvider);
      case AdminSection.restaurants:
        ref.invalidate(adminRestaurantsProvider);
      case AdminSection.riders:
        ref.invalidate(allRidersProvider);
        ref.invalidate(adminRiderCashProvider);
      case AdminSection.orders:
        ref.invalidate(adminOrdersProvider);
      case AdminSection.coupons:
        ref.invalidate(adminCouponsProvider);
      case AdminSection.support:
        ref.invalidate(allTicketsProvider);
      case AdminSection.refunds:
        ref.invalidate(adminRefundsProvider);
      case AdminSection.cash:
        ref.invalidate(adminSettlementsProvider);
        ref.invalidate(adminRiderCashProvider);
      case AdminSection.audit:
        ref.invalidate(adminAuditProvider);
      case AdminSection.settings:
        ref.invalidate(platformSettingsProvider);
    }
  }

  Future<void> _logout() async {
    final s = context.s.admin;
    final ok = await AppDialog.confirm(context,
        title: s.logoutConfirmTitle,
        confirmLabel: s.logout,
        icon: Icons.logout_rounded);
    if (ok && mounted) await ref.read(authNotifierProvider.notifier).signOut();
  }

  Widget _content() => switch (_section) {
        AdminSection.overview => OverviewSection(onNavigate: _go),
        AdminSection.users => const UsersSection(),
        AdminSection.restaurants => const RestaurantsSection(),
        AdminSection.riders => const RidersSection(),
        AdminSection.orders => const OrdersSection(),
        AdminSection.coupons => const CouponsSection(),
        AdminSection.support => const SupportSection(),
        AdminSection.refunds => const RefundsSection(),
        AdminSection.cash => const CashSection(),
        AdminSection.audit => const AuditSection(),
        AdminSection.settings => const SettingsSection(),
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final overview = ref.watch(adminOverviewProvider).valueOrNull;
    final maxWidth =
        _section == AdminSection.settings ? 760.0 : AppSpacing.maxContentWidth;

    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: KeyedSubtree(key: ValueKey(_section), child: _content()),
      ),
    );

    final topBar = AppTopBar(
      title: _section.label(s),
      subtitle: _section.subtitle(s),
      showBack: false,
      actions: [
        IconButton(
            tooltip: s.refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh),
        if (!wide)
          IconButton(
              tooltip: s.logout,
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logout),
      ],
      bottom: wide
          ? null
          : _SectionTabs(
              selected: _section, overview: overview, onSelected: _go),
    );

    if (!wide) {
      return Scaffold(appBar: topBar, body: SafeArea(top: false, child: body));
    }

    return Scaffold(
      body: Row(
        children: [
          _Rail(
              selected: _section,
              overview: overview,
              onSelected: _go,
              onLogout: _logout),
          VerticalDivider(width: 1, color: context.palette.border),
          Expanded(child: Scaffold(appBar: topBar, body: body)),
        ],
      ),
    );
  }
}

Widget _badged(IconData icon, int count, BuildContext context) {
  final p = context.palette;
  return Badge(
    isLabelVisible: count > 0,
    backgroundColor: p.accent,
    textColor: p.onAccent,
    label: Text(count > 99 ? '99+' : '$count'),
    child: Icon(icon),
  );
}

class _Rail extends StatelessWidget {
  const _Rail(
      {required this.selected,
      required this.overview,
      required this.onSelected,
      required this.onLogout});

  final AdminSection selected;
  final AdminOverview? overview;
  final ValueChanged<AdminSection> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              selectedIndex: selected.index,
              onDestinationSelected: (i) => onSelected(AdminSection.values[i]),
              labelType: NavigationRailLabelType.all,
              minWidth: 88,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(children: [
                  const AppLogoMark(size: 40),
                  const SizedBox(height: AppSpacing.xs),
                  Text(s.roleAdmin, style: context.text.overline),
                ]),
              ),
              trailing: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: IconButton(
                  tooltip: s.logout,
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: onLogout,
                ),
              ),
              destinations: [
                for (final section in AdminSection.values)
                  NavigationRailDestination(
                    icon:
                        _badged(section.icon, section.badge(overview), context),
                    selectedIcon: _badged(
                        section.selectedIcon, section.badge(overview), context),
                    label: Text(section.label(s), textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Phone section picker: icon + label tabs that scroll sideways.
class _SectionTabs extends StatefulWidget implements PreferredSizeWidget {
  const _SectionTabs(
      {required this.selected,
      required this.overview,
      required this.onSelected});

  final AdminSection selected;
  final AdminOverview? overview;
  final ValueChanged<AdminSection> onSelected;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  State<_SectionTabs> createState() => _SectionTabsState();
}

class _SectionTabsState extends State<_SectionTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
      length: AdminSection.values.length,
      vsync: this,
      initialIndex: widget.selected.index);

  @override
  void didUpdateWidget(covariant _SectionTabs old) {
    super.didUpdateWidget(old);
    if (_controller.index != widget.selected.index) {
      _controller.animateTo(widget.selected.index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    return TabBar(
      controller: _controller,
      isScrollable: true,
      onTap: (i) => widget.onSelected(AdminSection.values[i]),
      tabs: [
        for (final section in AdminSection.values)
          Tab(
            height: 48,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _badged(
                  section == widget.selected
                      ? section.selectedIcon
                      : section.icon,
                  section.badge(widget.overview),
                  context),
              const SizedBox(width: AppSpacing.sm),
              Text(section.label(s)),
            ]),
          ),
      ],
    );
  }
}
