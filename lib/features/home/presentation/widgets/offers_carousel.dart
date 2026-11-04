import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/shimmer_loader.dart';

/// Horizontally scrolling offer cards built from the `banners` table.
class OffersCarousel extends StatelessWidget {
  const OffersCarousel({super.key, required this.banners, required this.onTap});

  final List<Map<String, dynamic>> banners;
  final ValueChanged<Map<String, dynamic>> onTap;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final height = 136 + 28 * scale;
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - AppSpacing.screenHorizontal * 2) *
          (banners.length > 1 ? 0.86 : 1);
      return SizedBox(
        height: height,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal),
          scrollDirection: Axis.horizontal,
          itemCount: banners.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, i) => SizedBox(
            width: width.clamp(240.0, 400.0),
            child: _OfferCard(
              banner: banners[i],
              semanticsHint:
                  context.s.customer.offerPage(i + 1, banners.length),
              onTap: () => onTap(banners[i]),
            ),
          ),
        ),
      );
    });
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard(
      {required this.banner, required this.onTap, required this.semanticsHint});

  final Map<String, dynamic> banner;
  final VoidCallback onTap;
  final String semanticsHint;

  static const _darkText = AppColors.lightTextPrimary;

  static Color? _parse(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return null;
    final v = int.tryParse(cleaned, radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Background + readable text colour for a plain (photo-less) banner.
  static (Color, Color) colorsFor(String? hex, AppPalette p) {
    final bg = _parse(hex);
    if (bg != null) {
      final onWhite = _contrast(bg, AppColors.white);
      final onDark = _contrast(bg, _darkText);
      if (onWhite >= 4.5 && onWhite >= onDark) return (bg, AppColors.white);
      if (onDark >= 4.5) return (bg, _darkText);
    }
    return (AppColors.pine, AppColors.white);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final title = (banner['title'] as String? ?? '').trim();
    final subtitle = (banner['subtitle'] as String? ?? '').trim();
    final imageUrl = banner['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    final hasTarget = (banner['restaurant_id'] as String?)?.isNotEmpty ?? false;

    final (Color bg, Color fg) = hasImage
        ? (p.surfaceAlt, AppColors.white)
        : colorsFor(banner['color_hex'] as String?, p);
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    final text = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMedium
                          .copyWith(color: fg, height: 1.2)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall
                          .copyWith(color: fg.withValues(alpha: 0.9))),
                ],
                const Spacer(),
                if (hasTarget)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.offerOrderNow,
                          style: AppTypography.labelMedium.copyWith(color: fg)),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: fg),
                    ],
                  ),
              ],
            ),
          ),
          if (!hasImage) ...[
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(Icons.local_offer_rounded, color: fg, size: 22),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      label: [title, subtitle].where((e) => e.isNotEmpty).join('. '),
      hint: semanticsHint,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                        url: imageUrl, fallbackIcon: Icons.local_offer_rounded),
                    // Scrim so white text stays readable on any photo.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.black.withValues(alpha: 0.72),
                            AppColors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                    text,
                  ],
                )
              : text,
        ),
      ),
    );
  }
}

/// Placeholder while banners load.
class OffersCarouselSkeleton extends StatelessWidget {
  const OffersCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: AppShimmer(
          height: 136 + 28 * scale,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
    );
  }
}
