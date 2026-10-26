import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../features/orders/domain/models/order_item_model.dart';

/// "2 × Chicken Momo .........
class OrderItemsList extends StatelessWidget {
  const OrderItemsList(
      {super.key, required this.items, this.showSubtotals = false});

  final List<OrderItemModel> items;
  final bool showSubtotals;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.brandSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text('${item.quantity}×',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall
                          .copyWith(color: p.onBrandSoft)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(item.name,
                      style: AppTypography.bodyMedium
                          .copyWith(color: p.textPrimary)),
                ),
                if (showSubtotals)
                  Text(AppFormat.money(context, item.subtotal),
                      style: AppTypography.priceSmall
                          .copyWith(color: p.textSecondary)),
              ],
            ),
          ),
      ],
    );
  }
}
