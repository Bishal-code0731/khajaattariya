import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/food_item_model.dart';

// Vertical list of popular food items.
// Each item shows image, name, restaurant, price, and add to cart button.

class PopularFoodsSection extends StatelessWidget {
  final List<FoodItemModel> items;
  final Function(FoodItemModel) onAddToCart;

  const PopularFoodsSection({
    super.key,
    required this.items,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: const Text('Popular Items',
              style: AppTypography.headingSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        // We use ListView children inside a Column here because
        // this list is inside a CustomScrollView — it doesn't need
        // its own scroll. The parent handles scrolling.
        ...items.map((item) => _FoodItemTile(
          item: item,
          onAddToCart: () => onAddToCart(item),
        )),
      ],
    );
  }
}

class _FoodItemTile extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback onAddToCart;

  const _FoodItemTile({
    required this.item,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Food image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.network(
                  item.imageUrl,
                  width: AppSpacing.menuItemImageSize,
                  height: AppSpacing.menuItemImageSize,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: AppSpacing.menuItemImageSize,
                      height: AppSpacing.menuItemImageSize,
                      color: AppColors.border,
                    );
                  },
                  // If image fails, show a food icon placeholder
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: AppSpacing.menuItemImageSize,
                      height: AppSpacing.menuItemImageSize,
                      color: AppColors.border,
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: AppColors.textHint,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
              // Veg / Non-veg indicator
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: item.isVeg ? AppColors.success : AppColors.error,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: item.isVeg
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.sm),

          // Food details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + offer badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.offer != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.offer!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.restaurantName,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.accent, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      '${item.rating}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.circle,
                        size: 3, color: AppColors.textHint),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${item.deliveryTimeMin} min',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price + Add to cart
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${item.price.toInt()}',
                style: AppTypography.priceMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}