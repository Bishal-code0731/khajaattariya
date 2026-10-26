import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// Bottom navigation for the customer app (Material 3 NavigationBar, no glass/blur).
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = const [
      GlassNavItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home'),
      GlassNavItem(icon: Icons.search_rounded, label: 'Search'),
      GlassNavItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          label: 'Orders'),
      GlassNavItem(
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'Account'),
    ],
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: p.border))),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: item.badgeCount > 0
                  ? Badge.count(count: item.badgeCount, child: Icon(item.icon))
                  : Icon(item.icon),
              selectedIcon: item.badgeCount > 0
                  ? Badge.count(
                      count: item.badgeCount,
                      child: Icon(item.selectedIcon ?? item.icon))
                  : Icon(item.selectedIcon ?? item.icon),
              label: item.label,
              tooltip: item.label,
            ),
        ],
      ),
    );
  }
}

class GlassNavItem {
  const GlassNavItem(
      {required this.icon,
      required this.label,
      this.selectedIcon,
      this.badgeCount = 0});

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final int badgeCount;
}
