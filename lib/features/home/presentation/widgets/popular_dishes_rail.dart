import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../cart/application/cart_notifier.dart';
import '../../../restaurant/presentation/widgets/veg_mark.dart';
import '../../domain/models/food_item_model.dart';

/// Horizontal list of dish cards with an inline add/quantity control.
class PopularDishesRail extends ConsumerWidget {
  const PopularDishesRail({
    super.key,
    required this.items,
    required this.onAdd,
    required this.onOpenRestaurant,
  });

  final List<FoodItemModel> items;
  final ValueChanged<FoodItemModel> onAdd;
  final ValueChanged<FoodItemModel> onOpenRestaurant;

  static const _cardWidth = 164.0;
  static const _imageHeight = 118.0;

  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return _imageHeight + 18 + 86 * scale;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    return SizedBox(
      height: heightFor(context),
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          final item = items[i];
          return _DishCard(
            item: item,
            quantity: cart.quantityOf(item.restaurantId, item.id),
            onAdd: () => onAdd(item),
            onRemove: () => ref
                .read(cartNotifierProvider.notifier)
                .decrementQuantity(item.restaurantId, item.id),
            onTap: () => onOpenRestaurant(item),
          );
        },
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onTap,
  });

  final FoodItemModel item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    return SizedBox(
      width: PopularDishesRail._cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: PopularDishesRail._imageHeight + 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Semantics(
                  button: true,
                  label:
                      '${item.name}, ${s.fromRestaurant(item.restaurantName)}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: AppNetworkImage(
                      url: item.imageUrl,
                      width: PopularDishesRail._cardWidth,
                      height: PopularDishesRail._imageHeight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      fallbackIcon: Icons.fastfood_rounded,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: VegMark(isVeg: item.isVeg),
                ),
                if (item.restaurantOpen || quantity > 0)
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: 0,
                    child: QuantityStepper(
                      compact: true,
                      quantity: quantity,
                      addLabel: s.add,
                      onIncrement: onAdd,
                      onDecrement: onRemove,
                    ),
                  )
                else
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: p.border),
                      ),
                      child: Text(s.closedNow, style: context.text.overline),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.label),
          Text(item.restaurantName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(AppFormat.money(context, item.price), style: context.text.price),
        ],
      ),
    );
  }
}

/// Skeleton for [PopularDishesRail].
class PopularDishesSkeleton extends StatelessWidget {
  const PopularDishesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PopularDishesRail.heightFor(context),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, __) => SizedBox(
          width: PopularDishesRail._cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmer(
                height: PopularDishesRail._imageHeight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppShimmer(height: 14, width: 120),
              const SizedBox(height: AppSpacing.sm),
              const AppShimmer(height: 12, width: 90),
            ],
          ),
        ),
      ),
    );
  }
}
