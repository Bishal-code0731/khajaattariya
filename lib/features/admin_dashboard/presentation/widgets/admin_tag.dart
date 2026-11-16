import 'package:flutter/material.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum AdminTone { neutral, brand, success, warning, error, info }

/// Small square-cornered status tag: icon + text, so meaning never relies on colour alone.
class AdminTag extends StatelessWidget {
  const AdminTag(
      {super.key,
      required this.label,
      this.icon,
      this.tone = AdminTone.neutral});

  final String label;
  final IconData? icon;
  final AdminTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color fg) = switch (tone) {
      AdminTone.neutral => (p.surfaceAlt, p.textSecondary),
      AdminTone.brand => (p.brandSoft, p.onBrandSoft),
      AdminTone.success => (p.successSoft, p.success),
      AdminTone.warning => (p.warningSoft, p.warning),
      AdminTone.error => (p.errorSoft, p.error),
      AdminTone.info => (p.infoSoft, p.info),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}
