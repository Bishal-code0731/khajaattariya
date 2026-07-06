import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'glass_card.dart';

/// Canonical "icon/value/label" stat tile. Replaces the three
/// near-identical private widgets that used to be duplicated inline:
/// _ACard and _Mini (admin_dashboard_screen.dart) and _StatCard
/// (restaurant_dashboard_screen.dart).
class AppStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;

  /// Centered, larger icon, more padding — matches the old _ACard look
  /// (used for headline analytics tiles). When false, matches the old
  /// _StatCard/_Mini look: left-aligned, compact, no icon required.
  final bool large;

  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = large
        ? Column(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 28),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(value, style: AppTypography.headingSmall.copyWith(color: color)),
              Text(label, style: AppTypography.bodySmall),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(value, style: AppTypography.headingSmall.copyWith(color: color)),
              Text(label, style: AppTypography.bodySmall),
            ],
          );

    return Expanded(
      child: GlassCard(
        padding: EdgeInsets.all(large ? AppSpacing.md : AppSpacing.sm),
        borderRadius: large ? AppSpacing.radiusLg : AppSpacing.radiusMd,
        child: content,
      ),
    );
  }
}
