import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/l10n/strings/admin_strings.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../application/admin_actions.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_busy.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_list.dart';
import '../widgets/admin_tag.dart';

(String, IconData, AdminTone) refundStatusStyle(
        AdminStrings s, String status) =>
    switch (status) {
      'approved' => (s.approved, Icons.check_circle_rounded, AdminTone.success),
      'processed' => (
          s.refundProcessed,
          Icons.task_alt_rounded,
          AdminTone.success
        ),
      'rejected' => (s.rejected, Icons.block_rounded, AdminTone.error),
      _ => (s.pending, Icons.schedule_rounded, AdminTone.warning),
    };

/// Refund requests: review pending ones, see what was handled.
class RefundsSection extends ConsumerStatefulWidget {
  const RefundsSection({super.key});

  @override
  ConsumerState<RefundsSection> createState() => _RefundsSectionState();
}

class _RefundsSectionState extends ConsumerState<RefundsSection> {
  bool _pending = true;

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final async = ref.watch(adminRefundsProvider);
    final all = async.valueOrNull ?? const <AdminRefund>[];
    final pendingCount = all.where((r) => r.status == 'pending').length;

    return AdminAsyncList<AdminRefund>(
      value: async.whenData((list) {
        final items =
            list.where((r) => (r.status == 'pending') == _pending).toList();
        if (_pending) items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return items;
      }),
      onRefresh: () => ref.refresh(adminRefundsProvider.future),
      header: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: AdminFilterBar<bool>(
          selected: _pending,
          onSelected: (v) => setState(() => _pending = v),
          options: [
            AdminFilterOption(true, s.pending, count: pendingCount),
            AdminFilterOption(false, s.handled,
                count: all.length - pendingCount),
          ],
        ),
      ),
      empty: AppEmptyState(
        icon: Icons.currency_exchange_rounded,
        title: s.refundsEmpty,
        subtitle: _pending ? s.refundsEmptyHint : null,
        compact: true,
      ),
      itemBuilder: (context, r) => _RefundRow(key: ValueKey(r.id), refund: r),
    );
  }
}

class _RefundRow extends ConsumerStatefulWidget {
  const _RefundRow({super.key, required this.refund});
  final AdminRefund refund;

  @override
  ConsumerState<_RefundRow> createState() => _RefundRowState();
}

class _RefundRowState extends ConsumerState<_RefundRow> with AdminBusy {
  Future<void> _decide(bool approve) async {
    final s = context.s.admin;
    final amount = AppFormat.money(context, widget.refund.amount);
    final ok = await AppDialog.confirm(
      context,
      title:
          approve ? s.approveRefundTitle(amount) : s.rejectRefundTitle(amount),
      message: approve ? s.approveRefundMessage : s.rejectRefundMessage,
      confirmLabel: approve ? s.approve : s.reject,
      destructive: !approve,
      icon: approve ? Icons.currency_exchange_rounded : Icons.block_rounded,
    );
    if (!ok || !mounted) return;
    await runAction(
        approve ? 'approve' : 'reject',
        () => ref
            .read(adminActionsProvider)
            .decideRefund(widget.refund.id, approve: approve),
        success: approve ? s.refundApproved : s.refundRejected);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final p = context.palette;
    final r = widget.refund;
    final (label, icon, tone) = refundStatusStyle(s, r.status);
    return AdminRow(
      title: r.customerName ?? s.unknown,
      trailing:
          Text(AppFormat.money(context, r.amount), style: context.text.price),
      lines: [
        r.reason?.trim().isNotEmpty == true ? s.reason(r.reason!) : s.noReason,
        [
          if (r.orderTotal != null)
            s.orderTotal(AppFormat.money(context, r.orderTotal!)),
          AppFormat.timeAgo(context, r.createdAt),
        ].join(' · '),
      ],
      tags: [AdminTag(label: label, icon: icon, tone: tone)],
      below: r.orderId == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                label: '${s.openOrder} ${AppFormat.orderCode(r.orderId!)}',
                leadingIcon: Icons.receipt_long_outlined,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                expand: false,
                onPressed: () =>
                    context.pushOnce('${RouteNames.orderDetail}/${r.orderId}'),
              ),
            ),
      actions: r.status != 'pending'
          ? const []
          : [
              AppButton(
                label: s.reject,
                variant: AppButtonVariant.outline,
                color: p.error,
                size: AppButtonSize.small,
                expand: false,
                isLoading: busy == 'reject',
                onPressed: isBusy ? null : () => _decide(false),
              ),
              AppButton(
                label: s.approve,
                leadingIcon: Icons.check_rounded,
                size: AppButtonSize.small,
                expand: false,
                isLoading: busy == 'approve',
                onPressed: isBusy ? null : () => _decide(true),
              ),
            ],
    );
  }
}
