import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class PromoBannerSlider extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final ValueChanged<Map<String, dynamic>>? onBannerTap;

  const PromoBannerSlider({super.key, required this.banners, this.onBannerTap});

  @override
  State<PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<PromoBannerSlider> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The banners table has no image column — real banners here means a
  /// colored card (from the row's own `color_hex`) with its `emoji` as
  /// the visual centerpiece, not a broken image_url lookup that always
  /// silently fell back to an identical gradient for every banner.
  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceAll('#', '');
    final value = int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return value == null ? fallback : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final title = banner['title'] as String? ?? '';
              final subtitle = banner['subtitle'] as String? ?? '';
              final emoji = banner['emoji'] as String? ?? '🍽️';
              final baseColor = _parseColor(
                banner['color_hex'] as String?,
                AppColors.primary,
              );

              return GestureDetector(
                onTap: widget.onBannerTap == null ? null : () => widget.onBannerTap!(banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [baseColor, Color.lerp(baseColor, Colors.black, 0.35)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Opacity(
                            opacity: 0.25,
                            child: Text(emoji, style: const TextStyle(fontSize: 110)),
                          ),
                        ),
                        Positioned(
                          bottom: AppSpacing.md,
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              if (title.isNotEmpty)
                                Text(
                                  title,
                                  style: AppTypography.headingSmall
                                      .copyWith(color: AppColors.white),
                                ),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.white),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.banners.asMap().entries.map((e) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == e.key ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == e.key
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
