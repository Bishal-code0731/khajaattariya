import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../restaurant/presentation/widgets/veg_mark.dart';
import '../../application/cart_notifier.dart';
import '../../domain/models/cart_item_model.dart';
import '../../domain/models/cart_state.dart';

class CartGroupCard extends ConsumerWidget {
  const CartGroupCard({super.key, required this.group});

  final CartRestaurantGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = context.s.customer;
    final notifier = ref.read(cartNotifierProvider.notifier);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.xs, AppSpacing.xs),
            child: Row(
              children: [
                Icon(Icons.storefront_rounded, size: 20, color: p.brand),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(group.restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.h3),
                ),
                TextButton.icon(
                  onPressed: () => context.pushOnce(
                      '${RouteNames.restaurant}/${group.restaurantId}'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(s.addMoreItems),
                ),
              ],
            ),
          ),
          for (var i = 0; i < group.items.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                  color: p.border),
            _CartItemRow(
              item: group.items[i],
              onAdd: () => notifier.incrementQuantity(
                  group.restaurantId, group.items[i].food.id),
              onRemove: () => notifier.decrementQuantity(
                  group.restaurantId, group.items[i].food.id),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow(
      {required this.item, required this.onAdd, required this.onRemove});

  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = context.s.customer;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: VegMark(isVeg: item.food.isVeg, size: 12),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.food.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label),
                Text(s.eachPrice(AppFormat.money(context, item.food.price)),
                    style: context.text.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              QuantityStepper(
                  compact: true,
                  quantity: item.quantity,
                  onIncrement: onAdd,
                  onDecrement: onRemove),
              const SizedBox(height: AppSpacing.xs),
              Text(AppFormat.money(context, item.totalPrice),
                  style: context.text.price),
            ],
          ),
        ],
      ),
    );
  }
}
