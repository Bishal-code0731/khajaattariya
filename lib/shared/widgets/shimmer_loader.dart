import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// Skeleton block.
class AppShimmer extends StatelessWidget {
  const AppShimmer(
      {super.key,
      this.width = double.infinity,
      this.height = 16,
      this.borderRadius});

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return block;
    return Shimmer.fromColors(
      baseColor: p.surfaceAlt,
      highlightColor: context.isDark ? p.border : p.surface,
      child: block,
    );
  }
}

/// List of skeleton rows (image + three text lines).
class AppShimmerCardList extends StatelessWidget {
  const AppShimmerCardList(
      {super.key,
      this.count = 4,
      this.itemHeight = 96,
      this.shrinkWrap = false});

  final int count;
  final double itemHeight;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Row(
        children: [
          AppShimmer(
              width: itemHeight,
              height: itemHeight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(height: 16),
                SizedBox(height: AppSpacing.sm),
                AppShimmer(height: 12, width: 140),
                SizedBox(height: AppSpacing.sm),
                AppShimmer(height: 12, width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
