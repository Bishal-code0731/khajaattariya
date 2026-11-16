import 'package:flutter/material.dart';
import '../../core/l10n/s.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/orders/domain/models/order_model.dart';

class OrderStatusStyle {
  const OrderStatusStyle(this.color, this.icon);
  final Color color;
  final IconData icon;

  static OrderStatusStyle of(OrderStatus status) => switch (status) {
        OrderStatus.pending => const OrderStatusStyle(
            AppColors.statusPending, Icons.schedule_rounded),
        OrderStatus.confirmed => const OrderStatusStyle(
            AppColors.statusConfirmed, Icons.thumb_up_alt_rounded),
        OrderStatus.preparing => const OrderStatusStyle(
            AppColors.statusPreparing, Icons.soup_kitchen_rounded),
        OrderStatus.ready => const OrderStatusStyle(
            AppColors.statusReady, Icons.inventory_2_rounded),
        OrderStatus.pickedUp => const OrderStatusStyle(
            AppColors.statusDelivering, Icons.delivery_dining_rounded),
        OrderStatus.delivered => const OrderStatusStyle(
            AppColors.statusDelivered, Icons.check_circle_rounded),
        OrderStatus.cancelled => const OrderStatusStyle(
            AppColors.statusCancelled, Icons.cancel_rounded),
      };

  static String label(BuildContext context, OrderStatus status) {
    final c = context.s.common;
    return switch (status) {
      OrderStatus.pending => c.statusPending,
      OrderStatus.confirmed => c.statusConfirmed,
      OrderStatus.preparing => c.statusPreparing,
      OrderStatus.ready => c.statusReady,
      OrderStatus.pickedUp => c.statusPickedUp,
      OrderStatus.delivered => c.statusDelivered,
      OrderStatus.cancelled => c.statusCancelled,
    };
  }
}

/// Order status pill: icon + text (never colour alone).
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({super.key, required this.status, this.compact = false});

  final OrderStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = OrderStatusStyle.of(status);
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(style.color, Colors.white, 0.35)!
        : style.color;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(OrderStatusStyle.label(context, status),
              style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
