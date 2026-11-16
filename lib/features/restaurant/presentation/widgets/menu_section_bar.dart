import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';

/// One jump target in the sticky bar (a menu section, Reviews or Info).
class MenuJumpTarget {
  const MenuJumpTarget({required this.id, required this.label});
  final String id;
  final String label;
}

class MenuSectionBar extends StatefulWidget {
  const MenuSectionBar({
    super.key,
    required this.targets,
    required this.activeId,
    required this.vegOnly,
    required this.onVegOnlyChanged,
    required this.onJump,
  });

  final List<MenuJumpTarget> targets;
  final String? activeId;
  final bool vegOnly;
  final ValueChanged<bool> onVegOnlyChanged;
  final ValueChanged<String> onJump;

  @override
  State<MenuSectionBar> createState() => _MenuSectionBarState();
}

class _MenuSectionBarState extends State<MenuSectionBar> {
  final _keys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(covariant MenuSectionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeId != widget.activeId && widget.activeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[widget.activeId]?.currentContext;
        if (ctx != null && mounted) {
          Scrollable.ensureVisible(ctx,
              alignment: 0.3,
              duration: AppMotion.normal,
              curve: AppMotion.curve);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    return Semantics(
      container: true,
      label: s.jumpToSection,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm),
        children: [
          FilterChip(
            avatar: widget.vegOnly
                ? null
                : Icon(Icons.eco_outlined, size: 16, color: p.success),
            label: Text(s.vegOnly),
            selected: widget.vegOnly,
            onSelected: widget.onVegOnlyChanged,
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: p.border,
          ),
          for (final t in widget.targets) ...[
            ChoiceChip(
              key: _keys.putIfAbsent(t.id, () => GlobalKey()),
              label: Text(t.label),
              selected: t.id == widget.activeId,
              showCheckmark: false,
              onSelected: (_) => widget.onJump(t.id),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Pins [MenuSectionBar] below the collapsed hero bar.
class MenuSectionBarDelegate extends SliverPersistentHeaderDelegate {
  MenuSectionBarDelegate(
      {required this.child,
      required this.extent,
      required this.background,
      required this.border});

  final Widget child;
  final double extent;
  final Color background;
  final Color border;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      DecoratedBox(
        decoration: BoxDecoration(
            color: background,
            border: Border(bottom: BorderSide(color: border))),
        child: child,
      );

  @override
  bool shouldRebuild(MenuSectionBarDelegate old) =>
      old.child != child ||
      old.extent != extent ||
      old.background != background ||
      old.border != border;
}
