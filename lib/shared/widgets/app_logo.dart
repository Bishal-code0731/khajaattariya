import 'package:flutter/material.dart';
import '../../core/l10n/s.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import 'app_logo_painter.dart';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 48, this.tile = true});

  final double size;

  /// Draw the pine rounded-square background (false = pin only, for use on an existing brand background).
  final bool tile;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: context.s.common.appName,
        child: CustomPaint(
            size: Size.square(size), painter: AppLogoPainter(tile: tile)),
      );
}

/// Logo with the wordmark beside it.
class AppLogo extends StatelessWidget {
  const AppLogo(
      {super.key,
      this.size = 40,
      this.showTagline = false,
      this.onBrand = false});

  final double size;
  final bool showTagline;

  /// White text, for placing on the pine brand colour.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.s.common;
    final textColor = onBrand ? Colors.white : p.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(size: size),
        SizedBox(width: size * 0.3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.appName,
                style: AppTypography.headingMedium.copyWith(
                    color: textColor,
                    fontSize: size * 0.48,
                    fontWeight: FontWeight.w800,
                    height: 1.1)),
            if (showTagline)
              Text(c.tagline,
                  style: AppTypography.bodySmall.copyWith(
                      color: onBrand
                          ? Colors.white.withValues(alpha: 0.85)
                          : p.textSecondary)),
          ],
        ),
      ],
    );
  }
}
