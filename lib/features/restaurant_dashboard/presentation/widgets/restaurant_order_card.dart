import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/order_items_list.dart';
import '../../../orders/application/order_provider.dart';
import '../../../orders/domain/models/order_model.dart';

/// New orders waiting longer than this get a "Waiting N min" warning.
const _urgentAfter = Duration(minutes: 5);

/// One order on the kitchen board, with a big button for the next step.
class RestaurantOrderCard extends ConsumerStatefulWidget {
  const RestaurantOrderCard({super.key, required this.order});

  final OrderModel order;

  @override
  ConsumerState<RestaurantOrderCard> createState() =>
      _RestaurantOrderCardState();
}

class _RestaurantOrderCardState extends ConsumerState<RestaurantOrderCard> {
  /// The status this card is moving to (shows the spinner on that button).
  OrderStatus? _busyTarget;

  Future<void> _move(OrderStatus next) async {
    if (_busyTarget != null) return;
    final s = context.s.restaurant;
    if (next == OrderStatus.cancelled) {
      final ok = await AppDialog.confirm(
        context,
        title: s.rejectTitle,
        message: s.rejectMessage,
        confirmLabel: s.rejectConfirm,
        destructive: true,
        icon: Icons.block_rounded,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busyTarget = next);
    final notifier = ref.read(orderStatusNotifierProvider.notifier);
    final ok = await notifier.updateStatus(widget.order.id, next);
    if (!mounted) return;
    setState(() => _busyTarget = null);
    if (ok) {
      AppSnackbar.success(
          context,
          switch (next) {
            OrderStatus.confirmed => s.acceptedToast,
            OrderStatus.cancelled => s.rejectedToast,
            OrderStatus.preparing => s.preparingToast,
            _ => s.readyToast,
          });
    } else {
      AppSnackbar.error(context, ref.read(orderStatusNotifierProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final p = context.palette;
    final s = context.s.restaurant;
    final waited = DateTime.now().difference(order.createdAt.toLocal());
    final urgent =
        order.status == OrderStatus.pending && waited >= _urgentAfter;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: urgent ? p.warning : null,
      onTap: () => context.pushOnce('${RouteNames.orderDetail}/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      hint: s.openOrderHint,
                      child: Text(AppFormat.orderCode(order.id),
                          style: context.text.h3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormat.timeAgo(context, order.createdAt)} · ${AppFormat.time(context, order.createdAt)}',
                      style: context.text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppStatusBadge(status: order.status),
            ],
          ),
          if (urgent) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: p.warning),
                const SizedBox(width: AppSpacing.xs),
                Text(s.waitingMinutes(waited.inMinutes),
                    style: context.text.label.copyWith(color: p.warning)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: p.border),
          const SizedBox(height: AppSpacing.sm),
          OrderItemsList(items: order.items),
          if ((order.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _NoteBox(note: order.notes!.trim()),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                    s.itemsCount(
                        order.items.fold<int>(0, (n, i) => n + i.quantity)),
                    style: context.text.caption),
              ),
              Text(AppFormat.money(context, order.totalAmount),
                  style: context.text.price),
            ],
          ),
          ..._actions(context, order.status),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, OrderStatus status) {
    final s = context.s.restaurant;
    final busy = _busyTarget != null;
    Widget primary(String label, IconData icon, OrderStatus next) => AppButton(
          label: label,
          leadingIcon: icon,
          isLoading: _busyTarget == next,
          onPressed: busy ? null : () => _move(next),
        );

    final Widget? action = switch (status) {
      OrderStatus.pending => Row(
          children: [
            Expanded(
              flex: 2,
              child: AppButton(
                label: s.reject,
                variant: AppButtonVariant.danger,
                isLoading: _busyTarget == OrderStatus.cancelled,
                onPressed: busy ? null : () => _move(OrderStatus.cancelled),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                flex: 3,
                child: primary(
                    s.accept, Icons.check_rounded, OrderStatus.confirmed)),
          ],
        ),
      OrderStatus.confirmed => primary(
          s.startPreparing, Icons.soup_kitchen_outlined, OrderStatus.preparing),
      OrderStatus.preparing =>
        primary(s.markReady, Icons.inventory_2_outlined, OrderStatus.ready),
      OrderStatus.ready => _InfoStrip(
          icon: Icons.delivery_dining_rounded, label: s.waitingForRider),
      OrderStatus.pickedUp =>
        _InfoStrip(icon: Icons.two_wheeler_rounded, label: s.withRider),
      _ => null,
    };
    if (action == null) return const [];
    return [const SizedBox(height: AppSpacing.md), action];
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 18, color: p.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.s.restaurant.customerNote,
                    style: context.text.overline),
                const SizedBox(height: 2),
                Text(note, style: context.text.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.infoSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: p.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(label,
                  style: context.text.label.copyWith(color: p.info))),
        ],
      ),
    );
  }
}
