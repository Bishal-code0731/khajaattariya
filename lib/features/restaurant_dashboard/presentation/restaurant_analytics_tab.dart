import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/analytics_provider.dart';

/// Restaurant-facing analytics: revenue/order trends, peak hours, top
/// foods, and cancellation/customer stats, all derived from data the
/// app already has (daily_sales + orders/order_items) — no separate
/// analytics backend needed.
class RestaurantAnalyticsTab extends ConsumerWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantAnalyticsTab({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(restaurantMonthlySalesProvider(restaurantId));
    final summaryAsync = ref.watch(restaurantAnalyticsSummaryProvider(restaurantId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(restaurantMonthlySalesProvider(restaurantId));
        ref.invalidate(restaurantAnalyticsSummaryProvider(restaurantId));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Analytics', style: AppTypography.headingLarge),
              TextButton.icon(
                onPressed: () => _exportCsv(monthlyAsync.valueOrNull, summaryAsync.valueOrNull),
                icon: const Icon(Icons.ios_share_rounded, size: 16, color: AppColors.primary),
                label: Text('Export', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Weekly / monthly revenue + order-count summary cards
          AsyncValueView(
            value: monthlyAsync,
            errorMessage: 'Could not load sales trend',
            data: (monthly) {
              final now = DateTime.now();
              final weekAgo = now.subtract(const Duration(days: 7));
              final weekly = monthly.where((d) => d.date.isAfter(weekAgo));
              final weeklyRevenue = weekly.fold<double>(0, (s, d) => s + d.totalRevenue);
              final monthlyRevenue = monthly.fold<double>(0, (s, d) => s + d.totalRevenue);
              final monthlyOrders = monthly.fold<int>(0, (s, d) => s + d.totalOrders);

              return Column(
                children: [
                  Row(children: [
                    _StatTile(label: 'This Week', value: 'Rs. ${weeklyRevenue.toInt()}', color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    _StatTile(label: 'This Month', value: 'Rs. ${monthlyRevenue.toInt()}', color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    _StatTile(label: '30d Orders', value: '$monthlyOrders', color: AppColors.accent),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _RevenueTrendChart(sales: monthly),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          AsyncValueView(
            value: summaryAsync,
            errorMessage: 'Could not load analytics summary',
            data: (summary) {
              if (summary.totalOrders == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text('Not enough order history yet for deeper analytics.'),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _StatTile(
                      label: 'Cancellation Rate',
                      value: '${(summary.cancellationRate * 100).toStringAsFixed(1)}%',
                      color: summary.cancellationRate > 0.15 ? AppColors.error : AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _StatTile(label: 'Customers (30d)', value: '${summary.uniqueCustomers}', color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    _StatTile(label: 'Repeat Customers', value: '${summary.repeatCustomers}', color: AppColors.primary),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  if (summary.ordersByHour.isNotEmpty) ...[
                    Text('Peak Order Hours', style: AppTypography.headingSmall),
                    const SizedBox(height: AppSpacing.sm),
                    _PeakHoursChart(ordersByHour: summary.ordersByHour),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text('Order Outcomes', style: AppTypography.headingSmall),
                  const SizedBox(height: AppSpacing.sm),
                  _OutcomePieChart(summary: summary),
                  const SizedBox(height: AppSpacing.lg),
                  if (summary.topFoods.isNotEmpty) ...[
                    Text('Top Foods (30d)', style: AppTypography.headingSmall),
                    const SizedBox(height: AppSpacing.sm),
                    ...summary.topFoods.map((f) => _TopFoodRow(food: f)),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _exportCsv(List<DailySales>? monthly, RestaurantAnalyticsSummary? summary) {
    final buffer = StringBuffer('date,orders,revenue\n');
    for (final d in monthly ?? const <DailySales>[]) {
      buffer.writeln('${d.date.toIso8601String().split('T').first},${d.totalOrders},${d.totalRevenue}');
    }
    if (summary != null && summary.topFoods.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('top_food,quantity_sold,revenue');
      for (final f in summary.topFoods) {
        buffer.writeln('${f.name},${f.quantitySold},${f.revenue}');
      }
    }
    Share.share(buffer.toString(), subject: '$restaurantName — sales export');
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        borderRadius: AppSpacing.radiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.headingSmall.copyWith(color: color)),
            Text(label, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  final List<DailySales> sales;
  const _RevenueTrendChart({required this.sales});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) {
      return const GlassCard(
        padding: EdgeInsets.all(AppSpacing.md),
        borderRadius: AppSpacing.radiusMd,
        child: SizedBox(height: 120, child: Center(child: Text('No sales data yet'))),
      );
    }
    final maxY = sales.fold<double>(1, (m, s) => s.totalRevenue > m ? s.totalRevenue : m);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      borderRadius: AppSpacing.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Text('30-Day Revenue Trend', style: AppTypography.labelMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < sales.length; i++)
                        FlSpot(i.toDouble(), sales[i].totalRevenue),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeakHoursChart extends StatelessWidget {
  final Map<int, int> ordersByHour;
  const _PeakHoursChart({required this.ordersByHour});

  @override
  Widget build(BuildContext context) {
    final maxY = ordersByHour.values.fold<int>(1, (m, v) => v > m ? v : m).toDouble();
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusMd,
      child: SizedBox(
        height: 140,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  interval: 4,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}h',
                    style: AppTypography.bodySmall.copyWith(fontSize: 9),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var h = 0; h < 24; h++)
                BarChartGroupData(x: h, barRods: [
                  BarChartRodData(
                    toY: (ordersByHour[h] ?? 0).toDouble(),
                    color: AppColors.accent,
                    width: 5,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomePieChart extends StatelessWidget {
  final RestaurantAnalyticsSummary summary;
  const _OutcomePieChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final other = summary.totalOrders - summary.completedOrders - summary.cancelledOrders;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusMd,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 24,
                sections: [
                  PieChartSectionData(
                    value: summary.completedOrders.toDouble(),
                    color: AppColors.success,
                    showTitle: false,
                    radius: 20,
                  ),
                  PieChartSectionData(
                    value: summary.cancelledOrders.toDouble(),
                    color: AppColors.error,
                    showTitle: false,
                    radius: 20,
                  ),
                  if (other > 0)
                    PieChartSectionData(
                      value: other.toDouble(),
                      color: AppColors.textHint,
                      showTitle: false,
                      radius: 20,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(color: AppColors.success, label: 'Delivered', value: summary.completedOrders),
                _LegendRow(color: AppColors.error, label: 'Cancelled', value: summary.cancelledOrders),
                if (other > 0) _LegendRow(color: AppColors.textHint, label: 'In progress', value: other),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: AppTypography.bodySmall)),
        Text('$value', style: AppTypography.labelSmall),
      ]),
    );
  }
}

class _TopFoodRow extends StatelessWidget {
  final TopFoodItem food;
  const _TopFoodRow({required this.food});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        borderRadius: AppSpacing.radiusMd,
        child: Row(children: [
          Expanded(
            child: Text(food.name, style: AppTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text('${food.quantitySold} sold', style: AppTypography.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          Text('Rs. ${food.revenue.toInt()}',
              style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
        ]),
      ),
    );
  }
}
