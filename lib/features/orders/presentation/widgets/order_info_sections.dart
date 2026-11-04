import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/order_items_list.dart';
import '../../domain/models/order_model.dart';
import 'order_labels.dart';

/// Restaurant name and photo, with a call button for the customer.
class OrderRestaurantCard extends StatelessWidget {
  const OrderRestaurantCard({
    super.key,
    required this.order,
    required this.showCall,
  });

  final OrderModel order;
  final bool showCall;

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
    final ok = await launchUrl(uri).catchError((_) => false);
    if (!ok && context.mounted) {
      AppSnackbar.error(context, context.s.orders.callFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final phone = order.restaurantPhone?.trim() ?? '';
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AppNetworkImage(
            url: order.restaurantImageUrl,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(OrderLabels.restaurant(context, order),
                    style: text.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (phone.isNotEmpty)
                  Text(AppFormat.phone(phone), style: text.caption),
              ],
            ),
          ),
          if (showCall && phone.isNotEmpty)
            IconButton.filledTonal(
              tooltip: context.s.orders.callRestaurant,
              style: IconButton.styleFrom(
                backgroundColor: p.brandSoft,
                foregroundColor: p.onBrandSoft,
                minimumSize: const Size(48, 48),
              ),
              onPressed: () => _call(context, phone),
              icon: const Icon(Icons.call_outlined),
            ),
        ],
      ),
    );
  }
}

/// Items with their subtotals, then the bill from the order row.
class OrderBillCard extends StatelessWidget {
  const OrderBillCard({super.key, required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(o.sectionItems, style: text.h3),
          const SizedBox(height: AppSpacing.md),
          OrderItemsList(items: order.items, showSubtotals: true),
          const SizedBox(height: AppSpacing.lg),
          Divider(height: 1, color: p.border),
          const SizedBox(height: AppSpacing.md),
          _BillRow(
              label: o.itemTotal,
              value: AppFormat.money(context, order.subtotal)),
          _BillRow(
              label: o.deliveryFee,
              value: AppFormat.money(context, order.deliveryFee)),
          if (order.discountAmount > 0)
            _BillRow(
              label: o.discount,
              value: '− ${AppFormat.money(context, order.discountAmount)}',
              valueColor: p.success,
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(o.total, style: text.h3)),
              Text(AppFormat.money(context, order.totalAmount),
                  style: text.priceLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.secondary)),
          Text(value,
              style: valueColor == null
                  ? text.body
                  : text.body.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

/// Payment method + status, delivery address and the customer's note.
class OrderDeliveryPaymentCard extends StatelessWidget {
  const OrderDeliveryPaymentCard({super.key, required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = context.s.orders;
    final (fg, bg) = OrderLabels.paymentColors(context, order);
    final address = order.deliveryAddress?.trim() ?? '';
    final notes = order.notes?.trim() ?? '';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: order.paymentMethod == OrderPaymentMethod.cash
                ? Icons.payments_outlined
                : Icons.account_balance_wallet_outlined,
            title: o.sectionPayment,
            body: OrderLabels.method(context, order.paymentMethod),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(OrderLabels.paymentStatus(context, order),
                  style: AppTypography.labelSmall.copyWith(color: fg)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: p.border),
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            title: o.sectionDelivery,
            body: address.isEmpty ? o.noAddress : address,
          ),
          if (notes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: p.border),
            ),
            _InfoRow(
              icon: Icons.sticky_note_2_outlined,
              title: o.sectionNotes,
              body: notes,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: p.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.overline),
              const SizedBox(height: AppSpacing.xxs),
              Text(body, style: text.body),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
