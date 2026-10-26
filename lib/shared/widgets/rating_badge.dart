import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// "★ 4.3 (120)" chip on restaurant cards and pages.
class RatingBadge extends StatelessWidget {
  const RatingBadge(
      {super.key, required this.rating, this.count, this.newLabel = 'New'});

  final double rating;
  final int? count;

  /// Shown instead of a number when there are no reviews yet.
  final String newLabel;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0 && (count ?? 1) > 0;
    final bg = hasRating
        ? (rating >= 4
            ? AppColors.success
            : rating >= 3
                ? AppColors.marigoldDeep
                : AppColors.statusCancelled)
        : AppColors.pine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasRating) ...[
            const Icon(Icons.star_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            hasRating ? rating.toStringAsFixed(1) : newLabel,
            style: AppTypography.labelSmall.copyWith(color: Colors.white),
          ),
          if (hasRating && count != null) ...[
            const SizedBox(width: 3),
            Text('($count)',
                style: AppTypography.labelSmall
                    .copyWith(color: Colors.white.withValues(alpha: 0.85))),
          ],
        ],
      ),
    );
  }
}
