import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/models/restaurant_model.dart';

class NearbyRestaurantsSection extends StatelessWidget {
  final List<RestaurantModel> restaurants;
  final ValueChanged<RestaurantModel> onRestaurantTap;

  const NearbyRestaurantsSection({
    super.key,
    required this.restaurants,
    required this.onRestaurantTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Text('Nearby Restaurants', style: AppTypography.headingSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            scrollDirection: Axis.horizontal,
            itemCount: restaurants.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final r = restaurants[index];
              return _RestaurantCard(
                restaurant: r,
                onTap: () => onRestaurantTap(r),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: GlassCard(
        onTap: onTap,
        borderRadius: AppSpacing.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: restaurant.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 420,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (_, __) => Container(color: AppColors.border),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.border,
                        child: const Icon(Icons.restaurant_rounded,
                            color: AppColors.textHint, size: 32),
                      ),
                    ),
                    if (!restaurant.isOpen)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'CLOSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    if (restaurant.isFeatured)
                      Positioned(
                        top: AppSpacing.xs,
                        left: AppSpacing.xs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Text('FEATURED',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name,
                      style: AppTypography.headingSmall.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(restaurant.cuisineType,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text('${restaurant.rating}', style: AppTypography.labelSmall),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Text('${restaurant.deliveryTimeMin}m',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
