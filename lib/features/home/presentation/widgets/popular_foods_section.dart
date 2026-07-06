import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/models/food_item_model.dart';

class PopularFoodsSection extends StatelessWidget {
  final String title;
  final List<FoodItemModel> items;
  final ValueChanged<FoodItemModel> onAddToCart;

  const PopularFoodsSection({
    super.key,
    this.title = 'Popular Items',
    required this.items,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Text(title, style: AppTypography.headingSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = items[index];
            return _FoodRow(item: item, onAddToCart: () => onAddToCart(item));
          },
        ),
      ],
    );
  }
}

class _FoodRow extends StatelessWidget {
  final FoodItemModel item;
  final VoidCallback onAddToCart;

  const _FoodRow({required this.item, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              memCacheWidth: 128,
              placeholder: (_, __) => Container(width: 64, height: 64, color: AppColors.border),
              errorWidget: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: AppColors.border,
                child: const Icon(Icons.fastfood_rounded, color: AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: AppTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.restaurantName,
                    style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text('Rs. ${item.price.toInt()}',
                    style: AppTypography.priceMedium.copyWith(fontSize: 14)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAddToCart,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
