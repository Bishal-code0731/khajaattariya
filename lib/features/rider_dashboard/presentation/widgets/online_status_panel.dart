import 'package:flutter/material.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class OnlineStatusPanel extends StatelessWidget {
  const OnlineStatusPanel({
    super.key,
    required this.isOnline,
    required this.isBusy,
    required this.canGoOnline,
    required this.onToggle,
  });

  final bool isOnline;
  final bool isBusy;

  /// False until the rider is approved (the server refuses otherwise).
  final bool canGoOnline;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final enabled = !isBusy && (isOnline || canGoOnline);
    final bg = isOnline ? p.successSoft : p.surface;
    final fg = p.textPrimary;
    final fgSoft = p.textSecondary;

    final subtitle = isOnline
        ? r.onlineSubtitle
        : canGoOnline
            ? r.offlineSubtitle
            : r.lockedSubtitle;

    return Semantics(
      toggled: isOnline,
      enabled: enabled,
      button: true,
      label: '${isOnline ? r.onlineTitle : r.offlineTitle}. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: enabled ? onToggle : null,
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: isOnline ? p.success : p.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOnline ? p.success : p.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline
                        ? Icons.delivery_dining_rounded
                        : Icons.power_settings_new_rounded,
                    color: isOnline ? p.onBrand : p.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isOnline ? r.onlineTitle : r.offlineTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.headingMedium.copyWith(color: fg)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTypography.bodyMedium.copyWith(color: fgSoft)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 64,
                  height: 48,
                  child: Center(
                    child: isBusy
                        ? AppLoader(size: 24, color: p.brand)
                        : Transform.scale(
                            scale: 1.2,
                            child: Switch(
                              value: isOnline,
                              onChanged: enabled ? (_) => onToggle() : null,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
