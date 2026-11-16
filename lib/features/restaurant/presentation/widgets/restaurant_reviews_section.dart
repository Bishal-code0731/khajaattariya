import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../home/domain/models/restaurant_model.dart';
import '../../../reviews/application/rating_provider.dart';
import '../../../reviews/domain/models/rating_model.dart';

/// Rating summary and the latest reviews (first 3, expandable).
class RestaurantReviewsSection extends ConsumerStatefulWidget {
  const RestaurantReviewsSection({super.key, required this.restaurant});

  final RestaurantModel restaurant;

  @override
  ConsumerState<RestaurantReviewsSection> createState() =>
      _RestaurantReviewsSectionState();
}

class _RestaurantReviewsSectionState
    extends ConsumerState<RestaurantReviewsSection> {
  static const _collapsedCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s.customer;
    final r = widget.restaurant;
    final async = ref.watch(restaurantRatingsProvider(r.id));
    final ratings = async.valueOrNull;

    Widget body;
    if (async.isLoading && ratings == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmer(height: 14, width: 160),
            SizedBox(height: AppSpacing.sm),
            AppShimmer(height: 12),
            SizedBox(height: AppSpacing.lg),
            AppShimmer(height: 14, width: 120),
            SizedBox(height: AppSpacing.sm),
            AppShimmer(height: 12),
          ],
        ),
      );
    } else if (ratings == null) {
      body = Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(s.reviewsLoadFailed, style: context.text.secondary)),
            TextButton(
              onPressed: () => ref.invalidate(restaurantRatingsProvider(r.id)),
              child: Text(context.s.common.retry),
            ),
          ],
        ),
      );
    } else if (ratings.isEmpty) {
      body = AppEmptyState(
        compact: true,
        icon: Icons.rate_review_outlined,
        title: s.noReviewsTitle,
        subtitle: s.noReviewsBody,
      );
    } else {
      final shown =
          _expanded ? ratings : ratings.take(_collapsedCount).toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppSpacing.xl,
                indent: AppSpacing.screenHorizontal,
                endIndent: AppSpacing.screenHorizontal,
                color: context.palette.border,
              ),
            _ReviewRow(rating: shown[i]),
          ],
          if (ratings.length > _collapsedCount)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, 0, 0),
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded
                    ? s.showFewerReviews
                    : s.showAllReviews(ratings.length)),
              ),
            ),
        ],
      );
    }

    final count = ratings?.length ?? r.reviewCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: s.reviewsTitle,
          subtitle: count > 0
              ? s.reviewsSummary(r.rating.toStringAsFixed(1), count)
              : null,
        ),
        body,
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.rating});

  final RatingModel rating;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final name = (rating.customerName?.trim().isNotEmpty ?? false)
        ? rating.customerName!.trim()
        : s.anonymous;
    final stars = rating.rating.clamp(0, 5);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: p.brandSoft,
            child: Text(name.characters.first.toUpperCase(),
                style: context.text.label.copyWith(color: p.onBrandSoft)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.label),
                    ),
                    Text(AppFormat.timeAgo(context, rating.createdAt),
                        style: context.text.hint),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Semantics(
                  label: s.starsSemantics(stars),
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: i < stars ? AppColors.marigold : p.textHint,
                        ),
                    ],
                  ),
                ),
                if (rating.review != null &&
                    rating.review!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(rating.review!.trim(), style: context.text.body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
