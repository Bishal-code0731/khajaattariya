import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../payments/application/payment_provider.dart';
import '../../../rider/application/rider_cash_providers.dart';
import '../../../rider/application/rider_settings.dart';
import '../../../rider/domain/entities/cash_entry.dart';
import 'rider_chip.dart';
import 'rider_page.dart';
import 'settlement_form.dart';

class CashTab extends ConsumerWidget {
  const CashTab({super.key, required this.riderId});

  final String riderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.s.rider;
    final balanceAsync = ref.watch(riderCashBalanceProvider(riderId));
    final ledgerAsync = ref.watch(riderCashLedgerProvider(riderId));
    final settings =
        RiderSettings.from(ref.watch(platformSettingsProvider).valueOrNull);
    final ledger = ledgerAsync.valueOrNull ?? const <CashEntry>[];
    final pendingSettlements = ledger
        .where((e) => !e.isCollected && e.status == CashEntryStatus.pending)
        .fold<double>(0, (sum, e) => sum + e.amount);

    Future<void> refresh() async {
      ref
        ..invalidate(riderCashBalanceProvider(riderId))
        ..invalidate(riderCashLedgerProvider(riderId));
      try {
        await ref.read(riderCashBalanceProvider(riderId).future);
      } catch (_) {
        // The error is shown by the balance card.
      }
    }

    final balanceSection = balanceAsync.when(
      skipLoadingOnReload: true,
      loading: () => AppShimmer(
          height: 160,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      error: (e, _) => AppErrorState(error: e, onRetry: refresh),
      data: (cash) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCard(
              cashInHand: cash,
              limit: settings.codCashLimit,
              pendingSettlements: pendingSettlements),
          const SizedBox(height: AppSpacing.lg),
          SettlementForm(
            riderId: riderId,
            maxAmount: (cash - pendingSettlements)
                .clamp(0, double.infinity)
                .toDouble(),
          ),
        ],
      ),
    );

    final ledgerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RiderSectionTitle(title: r.ledgerTitle, subtitle: r.ledgerSubtitle),
        ledgerAsync.when(
          skipLoadingOnReload: true,
          loading: () => Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                const AppShimmer(height: 56),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          error: (e, _) => AppErrorState(
              error: e,
              onRetry: () => ref.invalidate(riderCashLedgerProvider(riderId))),
          data: (rows) => rows.isEmpty
              ? AppEmptyState(
                  compact: true,
                  icon: Icons.account_balance_wallet_outlined,
                  title: r.noLedgerTitle,
                  subtitle: r.noLedgerBody,
                )
              : _LedgerList(entries: rows),
        ),
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 1000) {
        // Wide: balance + form on the left, ledger on the right.
        return RiderPage(
          maxWidth: AppSpacing.maxContentWidth,
          onRefresh: refresh,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: balanceSection),
                const SizedBox(width: AppSpacing.xl),
                Expanded(flex: 6, child: ledgerSection),
              ],
            ),
          ],
        );
      }
      return RiderPage(
          onRefresh: refresh, children: [balanceSection, ledgerSection]);
    });
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard(
      {required this.cashInHand,
      required this.limit,
      required this.pendingSettlements});

  final double cashInHand;
  final double limit;
  final double pendingSettlements;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final ratio = limit <= 0 ? 1.0 : (cashInHand / limit).clamp(0.0, 1.0);
    final left = (limit - cashInHand).clamp(0, double.infinity);
    final atLimit = cashInHand >= limit;
    final nearLimit = !atLimit && ratio >= 0.8;
    final barColor = atLimit ? p.error : (nearLimit ? p.warning : p.brand);

    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(r.cashInHand,
                      style: AppTypography.labelMedium
                          .copyWith(color: p.textSecondary))),
              RiderChip(
                label: r.cashLimit(AppFormat.money(context, limit)),
                icon: Icons.shield_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(AppFormat.money(context, cashInHand),
              style:
                  AppTypography.displayMedium.copyWith(color: p.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: r.cashLeft(AppFormat.money(context, left)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                color: barColor,
                backgroundColor: p.surfaceAlt,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (atLimit || nearLimit) ...[
                Icon(Icons.warning_amber_rounded, size: 18, color: barColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  atLimit
                      ? r.cashLimitHit
                      : nearLimit
                          ? r.cashNearLimit
                          : r.cashLeft(AppFormat.money(context, left)),
                  style: AppTypography.bodySmall.copyWith(
                      color: (atLimit || nearLimit)
                          ? p.textPrimary
                          : p.textSecondary),
                ),
              ),
            ],
          ),
          if (pendingSettlements > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            RiderChip(
              label: r.pendingSettlement(
                  AppFormat.money(context, pendingSettlements)),
              icon: Icons.hourglass_top_rounded,
              tone: RiderTone.info,
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerList extends StatelessWidget {
  const _LedgerList({required this.entries});

  final List<CashEntry> entries;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) Divider(height: 1, color: p.border),
            _LedgerRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final CashEntry entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    final collected = entry.isCollected;
    final rejected = entry.status == CashEntryStatus.rejected;
    final detail = collected && entry.orderId != null
        ? r.orderLabel(AppFormat.orderCode(entry.orderId!))
        : (entry.note?.trim().isNotEmpty ?? false)
            ? entry.note!.trim()
            : null;

    final chip = switch (entry.status) {
      CashEntryStatus.confirmed => RiderChip(
          label: r.statusConfirmed,
          icon: Icons.check_circle_outline_rounded,
          tone: RiderTone.success),
      CashEntryStatus.pending => RiderChip(
          label: r.pending,
          icon: Icons.schedule_rounded,
          tone: RiderTone.warning),
      CashEntryStatus.rejected => RiderChip(
          label: r.statusRejected,
          icon: Icons.cancel_outlined,
          tone: RiderTone.error),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: collected ? p.accentSoft : p.brandSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              collected ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 20,
              color: collected ? p.textPrimary : p.onBrandSoft,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collected ? r.entryCollected : r.entrySettlement,
                    style: AppTypography.bodyMedium.copyWith(
                        color: p.textPrimary, fontWeight: FontWeight.w600)),
                Text(
                  [
                    if (detail != null) detail,
                    AppFormat.dateTime(context, entry.createdAt)
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTypography.bodySmall.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${collected ? '+' : '−'}${AppFormat.money(context, entry.amount)}',
                style: AppTypography.priceMedium.copyWith(
                  color: rejected ? p.textHint : p.textPrimary,
                  decoration: rejected ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              chip,
            ],
          ),
        ],
      ),
    );
  }
}
