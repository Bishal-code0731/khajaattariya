import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_stat_tile.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../rider/application/rider_provider.dart';
import '../../../rider/domain/models/rider_earning_model.dart';
import '../../../rider/domain/models/rider_model.dart';
import 'rider_chip.dart';
import 'rider_page.dart';

/// KPI tiles + list of earnings (the rider's share of each delivery fee).
class EarningsTab extends ConsumerWidget {
  const EarningsTab({super.key, required this.riderId, required this.rider});

  final String riderId;
  final RiderModel? rider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.s.rider;
    final p = context.palette;
    final earningsAsync = ref.watch(riderEarningsProvider(riderId));
    final earnings = earningsAsync.valueOrNull ?? const <RiderEarningModel>[];

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Weeks start on Sunday in Nepal.
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday % 7));
    double sumSince(DateTime from) => earnings
        .where((e) => !e.createdAt.toLocal().isBefore(from))
        .fold(0, (sum, e) => sum + e.amount);

    final tiles = [
      AppStatTile(
        label: r.today,
        value: AppFormat.money(context, sumSince(startOfToday)),
        icon: Icons.today_rounded,
        color: p.brand,
      ),
      AppStatTile(
        label: r.thisWeek,
        value: AppFormat.money(context, sumSince(startOfWeek)),
        icon: Icons.date_range_rounded,
        color: p.info,
      ),
      AppStatTile(
        label: r.totalDeliveries,
        value: '${rider?.totalDeliveries ?? 0}',
        icon: Icons.delivery_dining_rounded,
        color: p.accent,
      ),
      AppStatTile(
        label: r.totalEarned,
        value: AppFormat.money(context, rider?.totalEarnings ?? 0),
        icon: Icons.account_balance_wallet_rounded,
        color: p.success,
      ),
    ];

    return RiderPage(
      maxWidth: 960,
      onRefresh: () async {
        ref
          ..invalidate(riderEarningsProvider(riderId))
          ..invalidate(riderProfileProvider(riderId));
        await ref
            .read(riderEarningsProvider(riderId).future)
            .catchError((_) => <RiderEarningModel>[]);
      },
      children: [
        LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth >= 600 ? 4 : 2;
          final width = (c.maxWidth - AppSpacing.md * (columns - 1)) / columns;
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [for (final t in tiles) SizedBox(width: width, child: t)],
          );
        }),
        RiderSectionTitle(
            title: r.earningsHistory, subtitle: r.earningsHistorySubtitle),
        earningsAsync.when(
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
              onRetry: () => ref.invalidate(riderEarningsProvider(riderId))),
          data: (rows) {
            if (rows.isEmpty) {
              return AppEmptyState(
                compact: true,
                icon: Icons.receipt_long_outlined,
                title: r.noEarningsTitle,
                subtitle: r.noEarningsBody,
              );
            }
            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: p.border),
                    _EarningRow(earning: rows[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EarningRow extends StatelessWidget {
  const _EarningRow({required this.earning});

  final RiderEarningModel earning;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = context.s.rider;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.orderLabel(AppFormat.orderCode(earning.orderId)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                        color: p.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xxs),
                Text(AppFormat.dateTime(context, earning.createdAt),
                    style: AppTypography.bodySmall
                        .copyWith(color: p.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${AppFormat.money(context, earning.amount)}',
                  style:
                      AppTypography.priceMedium.copyWith(color: p.textPrimary)),
              const SizedBox(height: AppSpacing.xxs),
              earning.isPaid
                  ? RiderChip(
                      label: r.paid,
                      icon: Icons.check_circle_outline_rounded,
                      tone: RiderTone.success)
                  : RiderChip(
                      label: r.pending,
                      icon: Icons.schedule_rounded,
                      tone: RiderTone.warning),
            ],
          ),
        ],
      ),
    );
  }
}
