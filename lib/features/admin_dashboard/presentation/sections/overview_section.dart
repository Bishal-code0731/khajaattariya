import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_gantt_chart.dart';
import '../../../../shared/widgets/app_stat_tile.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_section.dart';

/// Today's numbers, the queues that need an admin, and the order flow chart.
class OverviewSection extends ConsumerWidget {
  const OverviewSection({super.key, required this.onNavigate});

  final ValueChanged<AdminSection> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(adminOverviewProvider);
    Future<void> refresh() async {
      ref.invalidate(adminOrdersProvider);
      ref.invalidate(adminOverviewProvider);
      await ref.read(adminOverviewProvider.future);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          if (overview.hasValue)
            _Kpis(data: overview.value!, onNavigate: onNavigate)
          else if (overview.hasError)
            AppErrorState(error: overview.error, onRetry: refresh)
          else
            const _KpiSkeleton(),
          const _TimelineCard(),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({required this.data, required this.onNavigate});

  final AdminOverview data;
  final ValueChanged<AdminSection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final p = context.palette;
    Color queue(int n) => n > 0 ? p.warning : p.textSecondary;

    final today = [
      AppStatTile(
        label: s.kpiOrdersToday,
        value: '${data.ordersToday}',
        icon: Icons.receipt_long_rounded,
        color: p.brand,
        large: true,
        onTap: () => onNavigate(AdminSection.orders),
      ),
      AppStatTile(
        label: s.kpiDeliveredToday,
        value: '${data.deliveredToday}',
        icon: Icons.check_circle_rounded,
        color: p.success,
        large: true,
        onTap: () => onNavigate(AdminSection.orders),
      ),
      AppStatTile(
        label: s.kpiRevenueToday,
        value: AppFormat.money(context, data.deliveredValueToday),
        icon: Icons.account_balance_wallet_rounded,
        color: p.accent,
        large: true,
        onTap: () => onNavigate(AdminSection.orders),
      ),
      AppStatTile(
        label: s.kpiActiveRestaurants,
        value: '${data.activeRestaurants}',
        icon: Icons.storefront_rounded,
        color: p.info,
        large: true,
        onTap: () => onNavigate(AdminSection.restaurants),
      ),
    ];

    final attention = [
      AppStatTile(
        label: s.kpiPendingApprovals,
        value: '${data.pendingApprovals}',
        caption:
            s.restaurantsAndRiders(data.pendingRestaurants, data.pendingRiders),
        icon: Icons.how_to_reg_rounded,
        color: queue(data.pendingApprovals),
        onTap: () => onNavigate(
            data.pendingRestaurants > 0 || data.pendingRiders == 0
                ? AdminSection.restaurants
                : AdminSection.riders),
      ),
      AppStatTile(
        label: s.kpiOpenTickets,
        value: '${data.openTickets}',
        icon: Icons.support_agent_rounded,
        color: queue(data.openTickets),
        onTap: () => onNavigate(AdminSection.support),
      ),
      AppStatTile(
        label: s.kpiPendingRefunds,
        value: '${data.pendingRefunds}',
        icon: Icons.currency_exchange_rounded,
        color: queue(data.pendingRefunds),
        onTap: () => onNavigate(AdminSection.refunds),
      ),
      AppStatTile(
        label: s.kpiPendingCash,
        value: '${data.pendingSettlements}',
        caption: data.pendingSettlements > 0
            ? AppFormat.money(context, data.pendingSettlementAmount)
            : null,
        icon: Icons.payments_rounded,
        color: queue(data.pendingSettlements),
        onTap: () => onNavigate(AdminSection.cash),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: s.todayHeading, subtitle: s.subOverview),
        _TileGrid(children: today),
        SectionHeader(title: s.needsAttention, subtitle: s.needsAttentionHint),
        _TileGrid(children: attention),
      ],
    );
  }
}

/// Equal-height tiles: 2 per row on phones, 4 from 720 px.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 720 ? 4 : 2;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final slice = children.skip(i).take(cols).toList();
          rows.add(IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: j < slice.length
                          ? slice[j]
                          : const SizedBox.shrink()),
                ],
              ],
            ),
          ));
        }
        return Column(
          children: [
            for (final (i, r) in rows.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              r,
            ],
          ],
        );
      }),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    final block = AppShimmer(
        height: 118, borderRadius: BorderRadius.circular(AppSpacing.radiusLg));
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
          AppSpacing.xl, AppSpacing.screenHorizontal, 0),
      child: Column(
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: block),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: block),
            ]),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends ConsumerWidget {
  const _TimelineCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.admin;
    final timeline = ref.watch(adminTimelineProvider);
    final count = timeline.valueOrNull?.orders.length ?? 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
            title: s.timelineTitle, subtitle: s.timelineSubtitle(count)),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal),
          child: AppCard(
            child: timeline.when(
              skipLoadingOnRefresh: true,
              loading: () => Column(children: [
                for (var i = 0; i < 5; i++)
                  const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppShimmer(height: 28)),
              ]),
              error: (e, _) => AppErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(adminTimelineProvider)),
              data: (data) => data.orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(s.timelineEmpty,
                          style: context.text.secondary,
                          textAlign: TextAlign.center),
                    )
                  : _Chart(data: data),
            ),
          ),
        ),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.data});
  final AdminTimeline data;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final unknown = context.s.admin.unknown;
    final rows = [
      for (final o in data.orders)
        GanttRow(
          label: o.restaurantName ?? unknown,
          subtitle:
              '${AppFormat.orderCode(o.id)} · ${o.customerName ?? unknown}',
          stages: ganttStagesFromTimeline(data.events[o.id] ?? const [], now),
          onTap: () => context.pushOnce('${RouteNames.orderDetail}/${o.id}'),
        ),
    ];
    final starts = rows.expand((r) => r.stages).map((st) => st.start);
    final start = starts.isEmpty
        ? now.subtract(const Duration(hours: 1))
        : starts.reduce((a, b) => a.isBefore(b) ? a : b);
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            for (final status in OrderStatus.values)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: OrderStatusStyle.of(status).color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                Text(OrderStatusStyle.label(context, status),
                    style: context.text.caption),
              ]),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppGanttChart(
            rows: rows,
            rangeStart: start,
            rangeEnd: now,
            labelWidth: wide ? 180 : 110),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            SizedBox(width: (wide ? 180 : 110) + AppSpacing.sm),
            Text(AppFormat.dateTime(context, start), style: context.text.hint),
            const Spacer(),
            Text(AppFormat.time(context, now), style: context.text.hint),
          ],
        ),
      ],
    );
  }
}
