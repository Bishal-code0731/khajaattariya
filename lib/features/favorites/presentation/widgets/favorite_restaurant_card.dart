import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/rating_badge.dart';
import '../../domain/models/favorite_model.dart';

class FavoriteRestaurantCard extends StatelessWidget {
  const FavoriteRestaurantCard({
    super.key,
    required this.favorite,
    required this.isRemoving,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoriteModel favorite;
  final bool isRemoving;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = context.s.account;
    final minutes = favorite.deliveryTimeMin;
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          AppNetworkImage(
            url: favorite.restaurantImageUrl,
            width: 96,
            height: 96,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            semanticLabel: favorite.restaurantName,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(favorite.restaurantName,
                    style: context.text.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (favorite.cuisineType.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(favorite.cuisineType,
                      style: context.text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    RatingBadge(
                        rating: favorite.rating, newLabel: a.newRestaurant),
                    if (minutes != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.schedule_rounded,
                          size: 14, color: p.textSecondary),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(a.deliveryMinutes(minutes),
                            style: context.text.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: a.removeFavorite,
            onPressed: isRemoving ? null : onRemove,
            icon: isRemoving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: p.error))
                : Icon(Icons.favorite_rounded, color: p.error),
          ),
        ],
      ),
    );
  }
}
