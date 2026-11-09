import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../payments/application/payment_provider.dart';
import '../../../rider/application/rider_provider.dart';
import '../../../rider/domain/models/rider_model.dart';
import '../../application/admin_actions.dart';
import '../../application/admin_queries.dart';
import '../widgets/admin_busy.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_list.dart';
import '../widgets/admin_note_dialog.dart';
import '../widgets/admin_tag.dart';

/// Rider approvals plus each rider's vehicle and cash in hand.
class RidersSection extends ConsumerStatefulWidget {
  const RidersSection({super.key});

  @override
  ConsumerState<RidersSection> createState() => _RidersSectionState();
}

class _RidersSectionState extends ConsumerState<RidersSection> {
  bool _approved = false;

  Future<void> _refresh() async {
    ref.invalidate(adminRiderCashProvider);
    ref.invalidate(allRidersProvider);
    await ref.read(allRidersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final async = ref.watch(allRidersProvider);
    final cash = ref.watch(adminRiderCashProvider).valueOrNull ??
        const <String, double>{};
    final limit = double.tryParse(
        ref.watch(platformSettingsProvider).valueOrNull?['cod_cash_limit'] ??
            '');
    final all = async.valueOrNull ?? const <RiderModel>[];

    return AdminAsyncList<RiderModel>(
      value: async.whenData((list) {
        final items = list.where((r) => r.isApproved == _approved).toList();
        if (!_approved) {
          // Never-reviewed first, oldest first.
          int rank(RiderModel r) =>
              (r.approvalNote?.trim().isNotEmpty ?? false) ? 1 : 0;
          items.sort((a, b) {
            final byRank = rank(a).compareTo(rank(b));
            return byRank != 0 ? byRank : a.createdAt.compareTo(b.createdAt);
          });
        }
        return items;
      }),
      onRefresh: _refresh,
      header: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: AdminFilterBar<bool>(
          selected: _approved,
          onSelected: (v) => setState(() => _approved = v),
          options: [
            AdminFilterOption(false, s.pending,
                count: all.where((r) => !r.isApproved).length),
            AdminFilterOption(true, s.approved,
                count: all.where((r) => r.isApproved).length),
          ],
        ),
      ),
      empty: AppEmptyState(
        icon: _approved ? Icons.two_wheeler_rounded : Icons.task_alt_rounded,
        title: _approved ? s.ridersEmpty : s.ridersPendingEmpty,
        subtitle: _approved ? null : s.ridersPendingEmptyHint,
        compact: true,
      ),
      itemBuilder: (context, r) => _RiderRow(
          key: ValueKey(r.id),
          rider: r,
          cashInHand: cash[r.id] ?? 0,
          cashLimit: limit),
    );
  }
}

class _RiderRow extends ConsumerStatefulWidget {
  const _RiderRow(
      {super.key,
      required this.rider,
      required this.cashInHand,
      required this.cashLimit});
  final RiderModel rider;
  final double cashInHand;
  final double? cashLimit;

  @override
  ConsumerState<_RiderRow> createState() => _RiderRowState();
}

class _RiderRowState extends ConsumerState<_RiderRow> with AdminBusy {
  String get _name => widget.rider.fullName.isEmpty
      ? context.s.admin.unknown
      : widget.rider.fullName;

  Future<void> _approve() async {
    final s = context.s.admin;
    final ok = await AppDialog.confirm(context,
        title: s.approveRiderTitle(_name),
        message: s.approveRiderMessage,
        confirmLabel: s.approve,
        icon: Icons.verified_rounded);
    if (!ok || !mounted) return;
    await runAction('approve',
        () => ref.read(adminActionsProvider).approveRider(widget.rider.id),
        success: s.riderApproved);
  }

  Future<void> _reject() async {
    final s = context.s.admin;
    final note =
        await showAdminNoteDialog(context, title: s.rejectRiderTitle(_name));
    if (note == null || !mounted) return;
    await runAction('reject',
        () => ref.read(adminActionsProvider).rejectRider(widget.rider.id, note),
        success: s.riderRejected);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final p = context.palette;
    final r = widget.rider;
    final rejected =
        !r.isApproved && (r.approvalNote?.trim().isNotEmpty ?? false);
    final overLimit =
        widget.cashLimit != null && widget.cashInHand > widget.cashLimit!;
    final vehicle = [
      s.vehicle(r.vehicleType),
      if (r.vehicleNumber?.isNotEmpty == true) r.vehicleNumber!
    ].join(' · ');

    return AdminRow(
      leading: AdminAvatar(name: _name, color: UserRole.rider.color),
      title: _name,
      lines: [
        [if (r.phone?.isNotEmpty == true) AppFormat.phone(r.phone!), vehicle]
            .join(' · '),
        if (r.isApproved)
          '${s.deliveries(r.totalDeliveries)} · ${s.cashInHand(AppFormat.money(context, widget.cashInHand))}'
        else
          AppFormat.date(context, r.createdAt),
      ],
      tags: [
        if (r.isApproved)
          r.isOnline
              ? AdminTag(
                  label: s.online, icon: Icons.circle, tone: AdminTone.success)
              : AdminTag(label: s.offline, icon: Icons.circle_outlined),
        if (overLimit)
          AdminTag(
              label: s.overCashLimit,
              icon: Icons.warning_amber_rounded,
              tone: AdminTone.warning),
        if (rejected)
          AdminTag(
              label: s.rejectedNote(r.approvalNote!),
              icon: Icons.block_rounded,
              tone: AdminTone.error),
      ],
      actions: r.isApproved
          ? const []
          : [
              AppButton(
                label: s.reject,
                variant: AppButtonVariant.outline,
                color: p.error,
                size: AppButtonSize.small,
                expand: false,
                isLoading: busy == 'reject',
                onPressed: isBusy || rejected ? null : _reject,
              ),
              AppButton(
                label: s.approve,
                leadingIcon: Icons.check_rounded,
                size: AppButtonSize.small,
                expand: false,
                isLoading: busy == 'approve',
                onPressed: isBusy ? null : _approve,
              ),
            ],
    );
  }
}
