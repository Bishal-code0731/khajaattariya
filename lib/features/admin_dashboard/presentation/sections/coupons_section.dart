import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/l10n/strings/admin_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../application/admin_actions.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_busy.dart';
import '../widgets/admin_list.dart';
import '../widgets/admin_tag.dart';
import '../widgets/coupon_form.dart';

/// Discount codes: status, usage, create / edit, on / off.
class CouponsSection extends ConsumerWidget {
  const CouponsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.admin;
    final async = ref.watch(adminCouponsProvider);
    return AdminAsyncList<AdminCoupon>(
      value: async,
      onRefresh: () => ref.refresh(adminCouponsProvider.future),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
            AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.xs),
        child: Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            label: s.newCoupon,
            leadingIcon: Icons.add_rounded,
            size: AppButtonSize.medium,
            expand: false,
            onPressed: () => showCouponForm(context),
          ),
        ),
      ),
      empty: AppEmptyState(
        icon: Icons.local_offer_outlined,
        title: s.couponsEmpty,
        subtitle: s.couponsEmptyHint,
        compact: true,
      ),
      itemBuilder: (context, c) => _CouponRow(key: ValueKey(c.id), coupon: c),
    );
  }
}

(String, IconData, AdminTone) couponStateStyle(
        AdminStrings s, CouponState state) =>
    switch (state) {
      CouponState.live => (
          s.couponLive,
          Icons.check_circle_rounded,
          AdminTone.success
        ),
      CouponState.paused => (
          s.couponPaused,
          Icons.pause_circle_rounded,
          AdminTone.neutral
        ),
      CouponState.scheduled => (
          s.couponScheduled,
          Icons.schedule_rounded,
          AdminTone.info
        ),
      CouponState.expired => (
          s.couponExpired,
          Icons.event_busy_rounded,
          AdminTone.error
        ),
      CouponState.usedUp => (
          s.couponUsedUp,
          Icons.do_not_disturb_on_rounded,
          AdminTone.warning
        ),
    };

class _CouponRow extends ConsumerStatefulWidget {
  const _CouponRow({super.key, required this.coupon});
  final AdminCoupon coupon;

  @override
  ConsumerState<_CouponRow> createState() => _CouponRowState();
}

class _CouponRowState extends ConsumerState<_CouponRow> with AdminBusy {
  Future<void> _toggle(bool v) {
    final s = context.s.admin;
    return runAction(
        'toggle',
        () =>
            ref.read(adminActionsProvider).setCouponActive(widget.coupon.id, v),
        success: v ? s.couponEnabled : s.couponDisabled);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final p = context.palette;
    final c = widget.coupon;
    final value = c.isPercent
        ? s.percentOff(
            c.discountValue.toStringAsFixed(c.discountValue % 1 == 0 ? 0 : 1))
        : s.amountOff(AppFormat.money(context, c.discountValue));
    final (label, icon, tone) = couponStateStyle(s, c.stateAt(DateTime.now()));
    final now = DateTime.now();
    final dates = c.validFrom.isAfter(now)
        ? s.startsOn(AppFormat.date(context, c.validFrom))
        : c.validUntil != null
            ? s.validUntil(AppFormat.date(context, c.validUntil!))
            : s.noExpiry;

    return AdminRow(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: p.accentSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        child: Icon(Icons.local_offer_rounded,
            color: context.isDark ? p.accent : p.onAccent, size: 22),
      ),
      title: c.code,
      trailing: Text(value, style: context.text.label.copyWith(color: p.brand)),
      lines: [
        [
          if (c.isPercent && c.maxDiscount != null)
            s.upTo(AppFormat.money(context, c.maxDiscount!)),
          s.minOrder(AppFormat.money(context, c.minOrderAmount)),
          s.usage(c.usesCount, c.maxUses),
          dates,
        ].join(' · '),
        if (c.description?.trim().isNotEmpty == true) c.description!,
      ],
      tags: [AdminTag(label: label, icon: icon, tone: tone)],
      actions: [
        AppButton(
          label: context.s.common.edit,
          leadingIcon: Icons.edit_outlined,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.small,
          expand: false,
          onPressed: isBusy ? null : () => showCouponForm(context, coupon: c),
        ),
        Semantics(
          label: s.toggleCoupon,
          child: SizedBox(
            height: 48,
            child: Center(
              child: busy == 'toggle'
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppLoader(size: 20))
                  : Tooltip(
                      message: s.toggleCoupon,
                      child: Switch(
                          value: c.isActive,
                          onChanged: isBusy ? null : _toggle),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
