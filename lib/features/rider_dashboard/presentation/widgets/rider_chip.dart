import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

enum RiderTone { success, warning, error, info, neutral }

/// Soft background + foreground colours for a [RiderTone].
({Color bg, Color fg}) riderToneColors(BuildContext context, RiderTone tone) {
  final p = context.palette;
  return switch (tone) {
    RiderTone.success => (bg: p.successSoft, fg: p.success),
    RiderTone.warning => (bg: p.warningSoft, fg: p.warning),
    RiderTone.error => (bg: p.errorSoft, fg: p.error),
    RiderTone.info => (bg: p.infoSoft, fg: p.info),
    RiderTone.neutral => (bg: p.surfaceAlt, fg: p.textSecondary),
  };
}

/// Small status label with an icon (never colour-only): "Paid", "Cash", "Pending", …
class RiderChip extends StatelessWidget {
  const RiderChip(
      {super.key,
      required this.label,
      required this.icon,
      this.tone = RiderTone.neutral});

  final String label;
  final IconData icon;
  final RiderTone tone;

  @override
  Widget build(BuildContext context) {
    final c = riderToneColors(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.fg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(color: c.fg)),
          ),
        ],
      ),
    );
  }
}
