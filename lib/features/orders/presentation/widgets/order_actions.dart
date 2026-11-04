import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../payments/application/payment_provider.dart';
import '../../../payments/application/refund_provider.dart';
import '../../../reviews/presentation/rate_order_sheet.dart';
import '../../application/order_provider.dart';
import '../../domain/models/order_model.dart';
import 'order_labels.dart';
import 'refund_request_sheet.dart';

bool _needsPayment(WidgetRef ref, OrderModel order) {
  if (!order.status.isActive || order.isPaid) return false;
  final payments =
      ref.watch(customerPaymentsProvider(order.customerId)).valueOrNull;
  if (payments == null) return false;
  return !payments.any((p) =>
      p.orderId == order.id &&
      (p.status == 'pending' || p.status == 'completed'));
}

void _openRating(BuildContext context, OrderModel order) {
  RateOrderSheet.show(
    context,
    orderId: order.id,
    customerId: order.customerId,
    restaurantId: order.restaurantId,
    restaurantName: OrderLabels.restaurant(context, order),
  );
}

class OrderActionBar extends ConsumerStatefulWidget {
  const OrderActionBar({super.key, required this.order});
  final OrderModel order;

  @override
  ConsumerState<OrderActionBar> createState() => _OrderActionBarState();
}

class _OrderActionBarState extends ConsumerState<OrderActionBar> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final o = context.s.orders;
    final confirmed = await AppDialog.confirm(
      context,
      title: o.cancelConfirmTitle,
      message: o.cancelConfirmBody,
      confirmLabel: o.cancelOrder,
      cancelLabel: o.keepOrder,
      destructive: true,
      icon: Icons.cancel_outlined,
    );
    if (!confirmed || !mounted) return;
    setState(() => _cancelling = true);
    final ok = await ref
        .read(orderStatusNotifierProvider.notifier)
        .updateStatus(widget.order.id, OrderStatus.cancelled);
    if (!mounted) return;
    if (ok) {
      setState(() => _cancelling = false);
      ref.invalidate(customerPaymentsProvider(widget.order.customerId));
      AppSnackbar.success(context, o.cancelledSuccess);
      return;
    }
    final error = ref.read(orderStatusNotifierProvider).error;
    // The usual reason: the restaurant accepted it a moment ago.
    var tooLate = false;
    try {
      final fresh =
          await ref.read(orderRepositoryProvider).getOrderById(widget.order.id);
      tooLate = fresh.status != OrderStatus.pending;
    } catch (_) {}
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (tooLate) {
      AppSnackbar.error(context, o.cancelTooLate);
    } else {
      AppSnackbar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final o = context.s.orders;
    final p = context.palette;

    Widget? primary;
    if (order.status == OrderStatus.pickedUp) {
      primary = AppButton(
        label: o.trackRider,
        leadingIcon: Icons.map_outlined,
        onPressed: () => context.push('${RouteNames.tracking}/${order.id}'),
      );
    } else if (_needsPayment(ref, order)) {
      primary = AppButton(
        label: o.payNow,
        leadingIcon: Icons.account_balance_wallet_outlined,
        onPressed: () => context.push(RouteNames.payment, extra: {
          'orderAmounts': {order.id: order.totalAmount},
        }),
      );
    } else if (order.status == OrderStatus.delivered &&
        ref.watch(orderRatingProvider(order.id)).valueOrNull == false) {
      primary = AppButton(
        label: o.rateOrder,
        leadingIcon: Icons.star_outline_rounded,
        onPressed: () => _openRating(context, order),
      );
    }

    final canCancel = order.status == OrderStatus.pending;
    if (primary == null && !canCancel) return const SizedBox.shrink();

    final cancel = AppButton(
      label: o.cancelOrder,
      variant: AppButtonVariant.outline,
      color: p.error,
      isLoading: _cancelling,
      onPressed: _cancelling ? null : _cancel,
    );

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                  AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.md),
              child: Row(
                children: [
                  if (canCancel) Expanded(child: cancel),
                  if (canCancel && primary != null)
                    const SizedBox(width: AppSpacing.md),
                  if (primary != null) Expanded(flex: 2, child: primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Need help?" — rating confirmation, refund request/status and support.
class OrderHelpSection extends ConsumerWidget {
  const OrderHelpSection({super.key, required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = context.text;
    final o = context.s.orders;

    final rated = order.status == OrderStatus.delivered &&
        ref.watch(orderRatingProvider(order.id)).valueOrNull == true;

    // Refunds only make sense once money was captured and the order is over.
    final refundable = order.isPaid && !order.status.isActive;
    String? refundStatus;
    if (refundable || order.paymentStatus == OrderPaymentStatus.refunded) {
      final refunds =
          ref.watch(customerRefundsProvider(order.customerId)).valueOrNull;
      final mine = refunds?.where((r) => r.orderId == order.id).toList() ?? [];
      if (mine.isNotEmpty) {
        refundStatus = switch (mine.first.status) {
          'approved' => o.refundApproved,
          'rejected' => o.refundRejected,
          'processed' => o.refundProcessed,
          _ => o.refundPending,
        };
      }
    }
    final canRequestRefund = refundable &&
        (refundStatus == null || refundStatus == o.refundRejected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rated) ...[
          _Note(
            icon: Icons.star_rounded,
            color: p.accent,
            background: p.accentSoft,
            text: o.youRated,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (refundStatus != null) ...[
          _Note(
            icon: Icons.currency_exchange_rounded,
            color: p.info,
            background: p.infoSoft,
            text: refundStatus,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.sm, top: AppSpacing.sm),
          child: Text(o.needHelp, style: text.h3),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (canRequestRefund) ...[
                _HelpTile(
                  icon: Icons.currency_exchange_rounded,
                  title: o.requestRefund,
                  subtitle: o.requestRefundBody,
                  onTap: () => RefundRequestSheet.show(context, order),
                ),
                Divider(height: 1, color: p.border),
              ],
              _HelpTile(
                icon: Icons.support_agent_rounded,
                title: o.getHelp,
                subtitle: o.getHelpBody,
                onTap: () => context.push(RouteNames.support),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: p.textSecondary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.label),
                      Text(subtitle, style: text.caption),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: context.text.body)),
        ],
      ),
    );
  }
}
