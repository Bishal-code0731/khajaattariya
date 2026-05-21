import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/restaurant_model.dart';

class NearbyRestaurantsSection extends StatelessWidget {
  final List<RestaurantModel> restaurants;
  final Function(RestaurantModel) onRestaurantTap;

  const NearbyRestaurantsSection({
    super.key,
    required this.restaurants,
    required this.onRestaurantTap,
  });

  @override
  Widget build(BuildContext context) {
    // Card width = 42% of screen
    // Card height = image (65% of cardWidth) + info section (80px)
    // We calculate this once here and pass it down
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.42;
    final imageHeight = cardWidth * 0.65;
    final cardHeight = imageHeight + 90; // image + info section below

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Restaurants',
                style: AppTypography.headingSmall,
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See all'),
              ),
            ],
          ),
        ),

        // The SizedBox height is now calculated dynamically
        // so it always fits the card content perfectly
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              return _RestaurantCard(
                restaurant: restaurants[index],
                cardWidth: cardWidth,
                imageHeight: imageHeight,
                onTap: () => onRestaurantTap(restaurants[index]),
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
  // Sizes passed in from parent — calculated once, used here
  final double cardWidth;
  final double imageHeight;

  const _RestaurantCard({
    required this.restaurant,
    required this.onTap,
    required this.cardWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // take only as much height as needed
          children: [

            // Restaurant image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    topRight: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: Image.network(
                    restaurant.imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: imageHeight,
                        color: AppColors.border,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: imageHeight,
                        color: AppColors.border,
                        child: const Center(
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: AppColors.textHint,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Offer badge
                if (restaurant.offer != null)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        restaurant.offer!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                // Closed overlay
                if (!restaurant.isOpen)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSpacing.radiusLg),
                        topRight: Radius.circular(AppSpacing.radiusLg),
                      ),
                      child: Container(
                        color: AppColors.overlay60,
                        child: const Center(
                          child: Text(
                            'CLOSED',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Restaurant info below image
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    restaurant.name,
                    style: AppTypography.headingSmall.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant.cuisineType,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${restaurant.rating}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.circle,
                        size: 3,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        // Flexible prevents text overflow in small cards
                        child: Text(
                          '${restaurant.deliveryTimeMin} min',
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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