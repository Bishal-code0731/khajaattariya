import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/s.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/language_toggle.dart';
import 'widgets/loading_dots.dart';

/// Shown briefly while auth state resolves.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final dark = context.isDark;
    final bg = dark ? p.background : p.brand;
    final fg = dark ? p.textPrimary : p.onBrand;
    final s = context.s;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogoMark(size: 104, tile: dark),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      s.common.appName,
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium
                          .copyWith(color: fg, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      s.common.tagline,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge
                          .copyWith(color: fg.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.xxl,
              child: Center(
                child: LoadingDots(
                  color: dark ? p.brand : p.accent,
                  semanticLabel: s.auth.splashLoading,
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.lg,
              // Dark mode sits on the normal background, where the default toggle colours are the readable ones.
              child: LanguageToggle(onDark: !dark),
            ),
          ],
        ),
      ),
    );
  }
}
