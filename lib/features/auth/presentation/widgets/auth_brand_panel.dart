import 'package:flutter/material.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_logo.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s;
    final bg = context.isDark ? p.brandSoft : p.brand;
    final fg = context.isDark ? p.onBrandSoft : p.onBrand;

    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: p.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(text,
                    style: AppTypography.bodyLarge.copyWith(color: fg)),
              ),
            ],
          ),
        );

    return ColoredBox(
      color: bg,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogoMark(size: 44, tile: false),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Text(
                      s.common.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMedium
                          .copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.auth.panelHeadline,
                        style: AppTypography.displayMedium.copyWith(color: fg)),
                    const SizedBox(height: AppSpacing.xxl),
                    point(Icons.storefront_outlined, s.auth.pointRestaurants),
                    point(Icons.route_outlined, s.auth.pointTracking),
                    point(Icons.payments_outlined, s.auth.pointPayments),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                s.common.tagline,
                style: AppTypography.bodyMedium
                    .copyWith(color: fg.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
