import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Skeleton-loading block using the `shimmer` package (already a
/// dependency but previously unused everywhere — every screen used a
/// spinner instead). Use for list/card placeholders on first load.
class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const AppShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurface : AppColors.surface,
      highlightColor: isDark ? AppColors.darkSurfaceAlt : AppColors.background,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

/// A row of shimmer blocks shaped like a restaurant/food card, for
/// home/search list placeholders.
class AppShimmerCardList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const AppShimmerCardList({super.key, this.count = 4, this.itemHeight = 96});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Row(
        children: [
          AppShimmer(
            width: itemHeight,
            height: itemHeight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(height: 16, width: double.infinity),
                const SizedBox(height: AppSpacing.sm),
                AppShimmer(height: 12, width: 120),
                const SizedBox(height: AppSpacing.sm),
                AppShimmer(height: 12, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
