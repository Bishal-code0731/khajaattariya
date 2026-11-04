import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';

/// Estimated bill.
class BillDetailsCard extends StatelessWidget {
  const BillDetailsCard({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.orderCount,
  });

  final int subtotal;
  final int deliveryFee;
  final int discount;
  final int orderCount;

  int get total => subtotal + deliveryFee - discount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;

    Widget line(String label, String value, {TextStyle? style, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                  child: Text(label, style: style ?? context.text.secondary)),
              Text(value,
                  style: (style ?? context.text.body).copyWith(color: color)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.billTitle, style: context.text.h3),
          const SizedBox(height: AppSpacing.sm),
          line(s.itemsSubtotal, AppFormat.money(context, subtotal)),
          line(orderCount > 1 ? s.deliveryFeeOrders(orderCount) : s.deliveryFee,
              AppFormat.money(context, deliveryFee)),
          if (discount > 0)
            line(s.discount, '− ${AppFormat.money(context, discount)}',
                color: p.success),
          Divider(height: AppSpacing.xl, color: p.border),
          line(s.estimatedTotal, AppFormat.money(context, total),
              style: context.text.priceLarge.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: p.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                  child: Text(s.estimateNote, style: context.text.caption)),
            ],
          ),
        ],
      ),
    );
  }
}
