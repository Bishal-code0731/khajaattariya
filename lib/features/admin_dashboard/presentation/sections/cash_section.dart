import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../application/admin_actions.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_busy.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_list.dart';
import '../widgets/admin_tag.dart';

/// Rider cash settlements: confirm cash handed over, or reject it.
class CashSection extends ConsumerStatefulWidget {
  const CashSection({super.key});

  @override
  ConsumerState<CashSection> createState() => _CashSectionState();
}

class _CashSectionState extends ConsumerState<CashSection> {
  bool _pending = true;

  Future<void> _refresh() async {
    ref.invalidate(adminRiderCashProvider);
    ref.invalidate(adminSettlementsProvider);
    await ref.read(adminSettlementsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final async = ref.watch(adminSettlementsProvider);
    final cash = ref.watch(adminRiderCashProvider).valueOrNull ??
        const <String, double>{};
    final all = async.valueOrNull ?? const <AdminSettlement>[];
    final pending = all.where((e) => e.status == 'pending').toList();
    final pendingTotal = pending.fold<double>(0, (sum, e) => sum + e.amount);

    return AdminAsyncList<AdminSettlement>(
      value: async.whenData((list) {
        final items =
            list.where((e) => (e.status == 'pending') == _pending).toList();
        if (_pending) items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return items;
      }),
      onRefresh: _refresh,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                  AppSpacing.md, AppSpacing.screenHorizontal, 0),
              child: AppCard(
                color: context.palette.warningSoft,
                borderColor: context.palette.warningSoft,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(children: [
                  Icon(Icons.payments_rounded, color: context.palette.warning),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.pendingTotal, style: context.text.caption),
                          Text(AppFormat.money(context, pendingTotal),
                              style: context.text.priceLarge),
                        ]),
                  ),
                  Text(s.requests(pending.length), style: context.text.label),
                ]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AdminFilterBar<bool>(
              selected: _pending,
              onSelected: (v) => setState(() => _pending = v),
              options: [
                AdminFilterOption(true, s.pending, count: pending.length),
                AdminFilterOption(false, s.history,
                    count: all.length - pending.length),
              ],
            ),
          ),
        ],
      ),
      empty: AppEmptyState(
        icon: _pending ? Icons.task_alt_rounded : Icons.history_rounded,
        title: _pending ? s.settlementsEmpty : s.historyEmpty,
        subtitle: _pending ? s.settlementsEmptyHint : null,
        compact: true,
      ),
      itemBuilder: (context, e) => _SettlementRow(
          key: ValueKey(e.id), entry: e, cashInHand: cash[e.riderId] ?? 0),
    );
  }
}

class _SettlementRow extends ConsumerStatefulWidget {
  const _SettlementRow(
      {super.key, required this.entry, required this.cashInHand});
  final AdminSettlement entry;
  final double cashInHand;

  @override
  ConsumerState<_SettlementRow> createState() => _SettlementRowState();
}

class _SettlementRowState extends ConsumerState<_SettlementRow> with AdminBusy {
  Future<void> _decide(bool confirm) async {
    final s = context.s.admin;
    final e = widget.entry;
    final amount = AppFormat.money(context, e.amount);
    final name = e.riderName ?? s.unknown;
    final ok = await AppDialog.confirm(
      context,
      title: confirm
          ? s.confirmSettlementTitle(amount, name)
          : s.rejectSettlementTitle(amount, name),
      message: confirm ? s.confirmSettlementMessage : s.rejectSettlementMessage,
      confirmLabel: confirm ? s.confirmReceived : s.reject,
      destructive: !confirm,
      icon: confirm ? Icons.payments_rounded : Icons.block_rounded,
    );
    if (!ok || !mounted) return;
    await runAction(
        confirm ? 'confirm' : 'reject',
        () => ref
            .read(adminActionsProvider)
            .decideSettlement(e.id, confirm: confirm),
        success: confirm ? s.settlementConfirmed : s.settlementRejected);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final p = context.palette;
    final e = widget.entry;
    final name = e.riderName ?? s.unknown;
    final isPending = e.status == 'pending';
    return AdminRow(
      leading: AdminAvatar(name: name, color: UserRole.rider.color),
      title: name,
      trailing:
          Text(AppFormat.money(context, e.amount), style: context.text.price),
      lines: [
        [
          if (e.riderPhone?.isNotEmpty == true) AppFormat.phone(e.riderPhone!),
          s.nowHolds(AppFormat.money(context, widget.cashInHand)),
        ].join(' · '),
        isPending
            ? AppFormat.timeAgo(context, e.createdAt)
            : AppFormat.dateTime(context, e.confirmedAt ?? e.createdAt),
        if (e.note?.trim().isNotEmpty == true) e.note!,
      ],
      tags: [
        switch (e.status) {
          'confirmed' => AdminTag(
              label: s.confirmedLabel,
              icon: Icons.check_circle_rounded,
              tone: AdminTone.success),
          'rejected' => AdminTag(
              label: s.rejected,
              icon: Icons.block_rounded,
              tone: AdminTone.error),
          _ => AdminTag(
              label: s.pending,
              icon: Icons.schedule_rounded,
              tone: AdminTone.warning),
        },
      ],
      actions: !isPending
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
                label: s.confirmReceived,
                leadingIcon: Icons.check_rounded,
                size: AppButtonSize.small,
                expand: false,
                isLoading: busy == 'confirm',
                onPressed: isBusy ? null : () => _decide(true),
              ),
            ],
    );
  }
}
