import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../application/analytics_provider.dart';

/// Card with a title, an optional hint and a chart body.
class ChartCard extends StatelessWidget {
  const ChartCard(
      {super.key, required this.title, required this.child, this.hint});

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: context.text.h3)),
          if (hint != null) Text(hint!, style: context.text.caption),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

TextStyle _axisStyle(BuildContext context) => context.text.caption
    .copyWith(fontSize: 11, color: context.palette.textSecondary);

String _compact(num v) => NumberFormat.compact(locale: 'en').format(v);

/// Daily revenue for the last 30 days (days without sales show as 0).
class RevenueLineChart extends StatelessWidget {
  const RevenueLineChart({super.key, required this.sales});

  final List<DailySales> sales;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final byDay = <DateTime, double>{
      for (final d in sales)
        DateTime(d.date.year, d.date.month, d.date.day): d.totalRevenue,
    };
    final days = [for (var i = 0; i < 30; i++) start.add(Duration(days: i))];
    final values = [for (final d in days) byDay[d] ?? 0.0];
    final maxV = values.fold<double>(0, math.max);
    final maxY = maxV <= 0 ? 100.0 : maxV * 1.2;
    final total = values.fold<double>(0, (a, b) => a + b);
    final dayFmt = DateFormat.MMMd(context.s.isNe ? 'ne' : 'en');

    return Semantics(
      label: context.s.restaurant
          .chartRevenueSemantics(AppFormat.money(context, total)),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 29,
              minY: 0,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: p.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max) return const SizedBox.shrink();
                      return Text(_compact(value), style: _axisStyle(context));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= days.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(dayFmt.format(days[i]),
                            style: _axisStyle(context)),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => p.textPrimary,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      LineTooltipItem(
                        '${dayFmt.format(days[spot.x.round()])}\n${AppFormat.money(context, spot.y)}',
                        context.text.label.copyWith(color: p.surface),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot(i.toDouble(), values[i])
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: p.brand,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: p.brand.withValues(alpha: 0.12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Orders by hour of day; the busiest hour is drawn in the brand colour.
class PeakHoursBarChart extends StatelessWidget {
  const PeakHoursBarChart({super.key, required this.ordersByHour});

  final Map<int, int> ordersByHour;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    var peakHour = 0;
    var peak = 0;
    ordersByHour.forEach((h, n) {
      if (n > peak) {
        peak = n;
        peakHour = h;
      }
    });
    final maxY = math.max(peak, 1) * 1.2;

    return Semantics(
      label: context.s.restaurant.peakHourSemantics(peakHour, peak),
      child: ExcludeSemantics(
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: math.max(1, (maxY / 4).ceilToDouble()),
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: p.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: math.max(1, (maxY / 4).ceilToDouble()),
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max) return const SizedBox.shrink();
                      return Text(value.toInt().toString(),
                          style: _axisStyle(context));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final h = value.toInt();
                      if (h % 3 != 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(h.toString().padLeft(2, '0'),
                            style: _axisStyle(context)),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => p.textPrimary,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${group.x.toString().padLeft(2, '0')}:00\n${context.s.restaurant.ordersCount(rod.toY.toInt())}',
                    context.text.label.copyWith(color: p.surface),
                  ),
                ),
              ),
              barGroups: [
                for (var h = 0; h < 24; h++)
                  BarChartGroupData(x: h, barRods: [
                    BarChartRodData(
                      toY: (ordersByHour[h] ?? 0).toDouble(),
                      color: h == peakHour && peak > 0
                          ? p.brand
                          : AppColors.marigold,
                      width: 7,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Delivered vs cancelled vs still in progress, as a donut + labelled legend.
class OutcomesDonut extends StatelessWidget {
  const OutcomesDonut({super.key, required this.summary});

  final RestaurantAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.s.common;
    final s = context.s.restaurant;
    final other = math.max(
        0,
        summary.totalOrders -
            summary.completedOrders -
            summary.cancelledOrders);
    final parts = [
      (c.statusDelivered, summary.completedOrders, AppColors.statusDelivered),
      (c.statusCancelled, summary.cancelledOrders, AppColors.statusCancelled),
      (s.outcomeInProgress, other, AppColors.statusPreparing),
    ];
    final total = math.max(1, summary.totalOrders);

    return Row(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                sections: [
                  for (final part in parts)
                    if (part.$2 > 0)
                      PieChartSectionData(
                          value: part.$2.toDouble(),
                          color: part.$3,
                          showTitle: false,
                          radius: 22),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final part in parts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: part.$3,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(part.$1,
                            style: context.text.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${part.$2}', style: context.text.label),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${(part.$2 * 100 / total).round()}%',
                          textAlign: TextAlign.end,
                          style: context.text.caption
                              .copyWith(color: p.textSecondary),
                        ),
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
