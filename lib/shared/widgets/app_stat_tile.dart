import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_card.dart';

/// Number + label tile for dashboards.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.large = false,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final bool large;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = color ?? p.brand;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(large ? AppSpacing.lg : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, size: large ? 22 : 18, color: accent),
            ),
          SizedBox(height: large ? AppSpacing.md : AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: (large
                        ? AppTypography.priceLarge
                        : AppTypography.priceMedium)
                    .copyWith(color: p.textPrimary)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(color: p.textSecondary)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!,
                style: AppTypography.labelSmall.copyWith(color: accent)),
          ],
        ],
      ),
    );
  }
}
