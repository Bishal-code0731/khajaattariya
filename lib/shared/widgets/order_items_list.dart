import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/orders/domain/models/order_item_model.dart';

/// Canonical "qty × item name" list used inside order cards.
/// Replaces the near-identical item-row mapping that used to be
/// duplicated inline in restaurant_dashboard_screen.dart's
/// _RestaurantOrderCard and rider_dashboard_screen.dart's
/// _ActiveDeliveryCard.
class OrderItemsList extends StatelessWidget {
  final List<OrderItemModel> items;

  /// When true, shows each item's subtotal on the right (used by the
  /// restaurant view); rider views only need quantity + name.
  final bool showSubtotals;

  const OrderItemsList({
    super.key,
    required this.items,
    this.showSubtotals = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            Text('${item.quantity}×  ',
                style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
            Expanded(child: Text(item.name, style: AppTypography.bodySmall)),
            if (showSubtotals)
              Text('Rs. ${item.subtotal.toInt()}', style: AppTypography.bodySmall),
          ],
        ),
      )).toList(),
    );
  }
}
