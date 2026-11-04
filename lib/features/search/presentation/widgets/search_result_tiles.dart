import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/rating_badge.dart';
import '../../../home/domain/models/food_item_model.dart';
import '../../../home/domain/models/restaurant_model.dart';
import '../../../home/presentation/widgets/restaurant_card.dart';
import '../../../restaurant/presentation/widgets/veg_mark.dart';

/// Compact restaurant row in search results.
class RestaurantResultTile extends StatelessWidget {
  const RestaurantResultTile(
      {super.key, required this.restaurant, required this.onTap});

  final RestaurantModel restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final r = restaurant;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.md),
        child: Row(
          children: [
            AppNetworkImage(
              url: r.imageUrl,
              width: 72,
              height: 72,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              fallbackIcon: Icons.storefront_rounded,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.h3),
                  Text(r.cuisineType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      RatingBadge(
                          rating: r.rating,
                          count: r.reviewCount,
                          newLabel: s.newRestaurant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          r.isOpen
                              ? restaurantInfoLine(context, r)
                              : s.closedNow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                              color: r.isOpen ? p.textSecondary : p.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textHint),
          ],
        ),
      ),
    );
  }
}

/// Dish row in search results: tap opens its restaurant; the stepper adds it straight to the cart.
class DishResultTile extends StatelessWidget {
  const DishResultTile({
    super.key,
    required this.food,
    required this.quantity,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  final FoodItemModel food;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final canAdd = food.restaurantOpen || quantity > 0;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.md),
        child: Row(
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: food.imageUrl,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  fallbackIcon: Icons.fastfood_rounded,
                ),
                Positioned(
                    top: 6,
                    left: 6,
                    child: VegMark(isVeg: food.isVeg, size: 13)),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.h3),
                  Text(s.fromRestaurant(food.restaurantName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(AppFormat.money(context, food.price),
                      style: context.text.price),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (canAdd)
              QuantityStepper(
                compact: true,
                quantity: quantity,
                addLabel: s.add,
                onIncrement: onAdd,
                onDecrement: onRemove,
              )
            else
              Text(s.closedNow,
                  style: AppTypography.labelSmall.copyWith(color: p.error)),
          ],
        ),
      ),
    );
  }
}
