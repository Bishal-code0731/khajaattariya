import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/models/order_model.dart';

/// Translated labels for order fields, shared by the order screens.
class OrderLabels {
  OrderLabels._();

  static String restaurant(BuildContext context, OrderModel order) =>
      order.restaurantName.trim().isEmpty
          ? context.s.orders.unknownRestaurant
          : order.restaurantName;

  static String method(BuildContext context, OrderPaymentMethod method) {
    final o = context.s.orders;
    return switch (method) {
      OrderPaymentMethod.cash => o.methodCash,
      OrderPaymentMethod.khalti => o.methodKhalti,
      OrderPaymentMethod.esewa => o.methodEsewa,
    };
  }

  /// "Paid" / "Pay on delivery" / "Payment pending" / …
  static String paymentStatus(BuildContext context, OrderModel order) {
    final o = context.s.orders;
    return switch (order.paymentStatus) {
      OrderPaymentStatus.paid => o.payPaid,
      OrderPaymentStatus.refunded => o.payRefunded,
      OrderPaymentStatus.failed => o.payFailed,
      OrderPaymentStatus.pending =>
        order.paymentMethod == OrderPaymentMethod.cash
            ? o.payOnDelivery
            : o.payPending,
    };
  }

  /// Colour pair (foreground, background) for the payment status chip.
  static (Color, Color) paymentColors(BuildContext context, OrderModel order) {
    final p = context.palette;
    return switch (order.paymentStatus) {
      OrderPaymentStatus.paid => (p.success, p.successSoft),
      OrderPaymentStatus.refunded => (p.info, p.infoSoft),
      OrderPaymentStatus.failed => (p.error, p.errorSoft),
      OrderPaymentStatus.pending =>
        order.paymentMethod == OrderPaymentMethod.cash
            ? (p.textSecondary, p.surfaceAlt)
            : (p.warning, p.warningSoft),
    };
  }

  /// "3 items · Chicken Momo, Chowmein"
  static String itemsSummary(BuildContext context, OrderModel order) {
    final count = context.s.orders.itemsCount(order.itemCount);
    if (order.items.isEmpty) return count;
    final names = order.items.map((i) => i.name).join(', ');
    return '$count · $names';
  }
}
