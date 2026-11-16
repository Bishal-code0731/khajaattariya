import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../../orders/presentation/widgets/order_labels.dart';

/// Order summary using the totals the server calculated for each order of this checkout.
class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({super.key, required this.orders});
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;
    double sum(double Function(OrderModel) f) =>
        orders.fold(0, (s, x) => s + f(x));
    final subtotal = sum((x) => x.subtotal);
    final fees = sum((x) => x.deliveryFee);
    final discount = sum((x) => x.discountAmount);
    final total = sum((x) => x.totalAmount);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(o.summaryTitle, style: text.h3),
          const SizedBox(height: AppSpacing.md),
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(OrderLabels.restaurant(context, order),
                            style: text.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(OrderLabels.itemsSummary(context, order),
                            style: text.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(AppFormat.money(context, order.subtotal),
                      style: text.body),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: p.border),
          ),
          _Line(label: o.itemTotal, value: AppFormat.money(context, subtotal)),
          _Line(label: o.deliveryFee, value: AppFormat.money(context, fees)),
          if (discount > 0)
            _Line(
              label: o.discount,
              value: '− ${AppFormat.money(context, discount)}',
              color: p.success,
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(o.totalToPay, style: text.h3)),
              Text(AppFormat.money(context, total), style: text.priceLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, size: 16, color: p.textHint),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(o.serverTotalsNote, style: text.hint)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.secondary)),
          Text(value,
              style:
                  color == null ? text.body : text.body.copyWith(color: color)),
        ],
      ),
    );
  }
}
