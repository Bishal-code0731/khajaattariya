import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_stat_tile.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/analytics_provider.dart';
import 'widgets/analytics_charts.dart';

class RestaurantAnalyticsTab extends ConsumerWidget {
  const RestaurantAnalyticsTab(
      {super.key, required this.restaurantId, required this.restaurantName});

  final String restaurantId;
  final String restaurantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.restaurant;
    final monthlyAsync =
        ref.watch(restaurantMonthlySalesProvider(restaurantId));
    final summaryAsync =
        ref.watch(restaurantAnalyticsSummaryProvider(restaurantId));

    return RefreshIndicator(
      onRefresh: () async => refreshRestaurantAnalytics(ref, restaurantId),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final twoUp = width >= 820;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.xxl),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.analyticsTitle, style: context.text.h2),
                      Text(s.analyticsSubtitle, style: context.text.caption),
                    ],
                  ),
                ),
                AppButton(
                  label: s.exportCsv,
                  leadingIcon: Icons.ios_share_rounded,
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.medium,
                  expand: false,
                  onPressed: () => _exportCsv(context, monthlyAsync.valueOrNull,
                      summaryAsync.valueOrNull),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _KpiGrid(
              width: width,
              kpis: monthlyAsync.valueOrNull == null
                  ? null
                  : SalesKpis.fromDaily(monthlyAsync.value!),
              summary: summaryAsync.valueOrNull,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (monthlyAsync.hasError && !monthlyAsync.hasValue)
              AppErrorState(
                  error: monthlyAsync.error,
                  onRetry: () => refreshRestaurantAnalytics(ref, restaurantId))
            else if (!monthlyAsync.hasValue)
              const AppShimmer(height: 260)
            else if (monthlyAsync.value!.isEmpty)
              AppCard(
                child: AppEmptyState(
                  icon: Icons.show_chart_rounded,
                  title: s.noSalesTitle,
                  subtitle: s.noSalesBody,
                  compact: true,
                ),
              )
            else
              ChartCard(
                  title: s.chartRevenue,
                  child: RevenueLineChart(sales: monthlyAsync.value!)),
            const SizedBox(height: AppSpacing.lg),
            ..._summarySection(context, ref, summaryAsync, twoUp),
          ],
        );
      }),
    );
  }

  List<Widget> _summarySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<RestaurantAnalyticsSummary> summaryAsync,
    bool twoUp,
  ) {
    final s = context.s.restaurant;
    if (!summaryAsync.hasValue) {
      if (summaryAsync.hasError) {
        return [
          AppErrorState(
              error: summaryAsync.error,
              onRetry: () => refreshRestaurantAnalytics(ref, restaurantId)),
        ];
      }
      return const [AppShimmer(height: 200)];
    }
    final summary = summaryAsync.value!;
    if (summary.totalOrders == 0) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(s.notEnoughHistory,
              style: context.text.secondary, textAlign: TextAlign.center),
        ),
      ];
    }

    final peak = ChartCard(
      title: s.chartPeakHours,
      hint: s.chartPeakHoursHint,
      child: PeakHoursBarChart(ordersByHour: summary.ordersByHour),
    );
    final outcomes = ChartCard(
        title: s.chartOutcomes, child: OutcomesDonut(summary: summary));
    return [
      if (twoUp)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: peak),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 2, child: outcomes),
            ],
          ),
        )
      else ...[
        peak,
        const SizedBox(height: AppSpacing.lg),
        outcomes,
      ],
      if (summary.topFoods.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        ChartCard(
            title: s.topDishes, child: _TopDishes(foods: summary.topFoods)),
      ],
    ];
  }

  static String _csvField(String v) =>
      (v.contains(',') || v.contains('"') || v.contains('\n'))
          ? '"${v.replaceAll('"', '""')}"'
          : v;

  void _exportCsv(BuildContext context, List<DailySales>? monthly,
      RestaurantAnalyticsSummary? summary) {
    final hasSales = monthly != null && monthly.isNotEmpty;
    final hasFoods = summary != null && summary.topFoods.isNotEmpty;
    if (!hasSales && !hasFoods) {
      AppSnackbar.info(context, context.s.restaurant.exportNothing);
      return;
    }
    final buffer = StringBuffer('date,orders,revenue\n');
    for (final d in monthly ?? const <DailySales>[]) {
      buffer.writeln(
          '${d.date.toIso8601String().split('T').first},${d.totalOrders},${d.totalRevenue}');
    }
    if (hasFoods) {
      buffer
        ..writeln()
        ..writeln('top_food,quantity_sold,revenue');
      for (final f in summary.topFoods) {
        buffer.writeln('${_csvField(f.name)},${f.quantitySold},${f.revenue}');
      }
    }
    Share.share(buffer.toString(),
        subject: context.s.restaurant.exportSubject(restaurantName));
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid(
      {required this.width, required this.kpis, required this.summary});

  final double width;
  final SalesKpis? kpis;
  final RestaurantAnalyticsSummary? summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final k = kpis;
    final sum = summary;
    String money(double? v) =>
        v == null ? '–' : AppFormat.money(context, v.round());
    final cancelRate = sum?.cancellationRate;

    final tiles = <Widget>[
      AppStatTile(
        label: s.kpiToday,
        value: money(k?.todayRevenue),
        caption: k == null ? null : s.ordersCount(k.todayOrders),
        icon: Icons.today_rounded,
        color: p.brand,
      ),
      AppStatTile(
        label: s.kpiWeek,
        value: money(k?.weekRevenue),
        caption: k == null ? null : s.ordersCount(k.weekOrders),
        icon: Icons.date_range_rounded,
        color: p.brand,
      ),
      AppStatTile(
        label: s.kpiMonth,
        value: money(k?.monthRevenue),
        caption: k == null ? null : s.ordersCount(k.monthOrders),
        icon: Icons.calendar_month_rounded,
        color: p.brand,
      ),
      AppStatTile(
        label: s.kpiAverageOrder,
        value: money(k?.averageOrderValue),
        icon: Icons.receipt_long_rounded,
        color: p.info,
      ),
      AppStatTile(
        label: s.kpiCancellation,
        value: cancelRate == null
            ? '–'
            : '${(cancelRate * 100).toStringAsFixed(1)}%',
        icon: Icons.cancel_outlined,
        color: cancelRate != null && cancelRate > 0.15
            ? p.error
            : AppColors.statusCancelled,
      ),
      AppStatTile(
        label: s.kpiCustomers,
        value: sum == null ? '–' : '${sum.uniqueCustomers}',
        caption: sum == null ? null : s.repeatCustomers(sum.repeatCustomers),
        icon: Icons.people_alt_outlined,
        color: p.success,
      ),
    ];

    final columns = width >= 1000 ? 6 : (width >= 600 ? 3 : 2);
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += columns) {
      final slice = tiles.sublist(i, (i + columns).clamp(0, tiles.length));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: j < slice.length ? slice[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      ));
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          rows[i],
        ],
      ],
    );
  }
}

class _TopDishes extends StatelessWidget {
  const _TopDishes({required this.foods});

  final List<TopFoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    final maxQty =
        foods.fold<int>(1, (m, f) => f.quantitySold > m ? f.quantitySold : m);
    return Column(
      children: [
        for (var i = 0; i < foods.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}',
                      style:
                          context.text.label.copyWith(color: p.textSecondary)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(foods[i].name,
                                style: context.text.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(AppFormat.money(context, foods[i].revenue),
                              style: context.text.label),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXs),
                              child: LinearProgressIndicator(
                                value: foods[i].quantitySold / maxQty,
                                minHeight: 6,
                                color: p.brand,
                                backgroundColor: p.surfaceAlt,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 72,
                            child: Text(s.soldCount(foods[i].quantitySold),
                                textAlign: TextAlign.end,
                                style: context.text.caption),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
