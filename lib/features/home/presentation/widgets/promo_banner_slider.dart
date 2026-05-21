import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

// Auto-sliding promotional banner.
// Shows offers, popular items, and promotions.
// Slides automatically every 3 seconds.
// User can also swipe manually.

class PromoBannerSlider extends StatefulWidget {
  final List<Map<String, dynamic>> banners;

  const PromoBannerSlider({
    super.key,
    required this.banners,
  });

  @override
  State<PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<PromoBannerSlider> {
  // PageController controls which page is visible.
  // It's like a scroll controller but for PageView.
  final PageController _pageController = PageController();

  // Tracks which banner is currently showing
  int _currentIndex = 0;

  // Timer triggers the auto-slide every 3 seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      // If we're on the last banner, go back to first
      // Otherwise go to next banner
      final nextIndex = _currentIndex < widget.banners.length - 1
          ? _currentIndex + 1
          : 0;

      // animateToPage smoothly slides to the next page
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    // Always cancel the timer when widget is removed
    // Otherwise it keeps running and causes memory leaks
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The sliding banner area
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            // Called every time the page changes
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _BannerCard(banner: banner);
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Dot indicators — shows which banner is active
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
                (index) => _DotIndicator(isActive: index == _currentIndex),
          ),
        ),
      ],
    );
  }
}

// A single banner card
class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        decoration: BoxDecoration(
          // Each banner has its own color from dummy data
          color: Color(banner['color'] as int),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Offer badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'LIMITED OFFER',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    banner['title'] as String,
                    style: AppTypography.headingMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    banner['subtitle'] as String,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Emoji on the right
            Text(
              banner['emoji'] as String,
              style: const TextStyle(fontSize: 64),
            ),
          ],
        ),
      ),
    );
  }
}

// A single dot indicator
class _DotIndicator extends StatelessWidget {
  final bool isActive;

  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      // AnimatedContainer smoothly transitions between sizes
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 20 : 6,   // active dot is wider
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }
}