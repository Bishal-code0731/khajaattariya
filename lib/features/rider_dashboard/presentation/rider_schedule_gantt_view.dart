import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/s.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/order_timeline_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_gantt_chart.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../orders/application/order_provider.dart';

class RiderScheduleGanttView extends ConsumerWidget {
  const RiderScheduleGanttView({super.key, required this.riderId});

  final String riderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.s.rider;
    final ordersAsync = ref.watch(riderOrdersTodayProvider(riderId));
    Widget skeleton() => AppShimmer(
        height: 220, borderRadius: BorderRadius.circular(AppSpacing.radiusLg));

    return ordersAsync.when(
      skipLoadingOnReload: true,
      loading: skeleton,
      error: (e, _) => AppErrorState(
        message: r.scheduleError,
        error: e,
        onRetry: () => ref.invalidate(riderOrdersTodayProvider(riderId)),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return AppEmptyState(
            icon: Icons.route_outlined,
            title: r.noScheduleTitle,
            subtitle: r.noScheduleBody,
          );
        }

        final orderIds = orders.map((o) => o.id).toList();
        final timelinesAsync = ref.watch(orderTimelinesBatchProvider(orderIds));

        return timelinesAsync.when(
          skipLoadingOnReload: true,
          loading: skeleton,
          error: (e, _) => AppErrorState(
            message: r.scheduleError,
            error: e,
            onRetry: () =>
                ref.invalidate(orderTimelinesBatchProvider(orderIds)),
          ),
          data: (timelines) {
            final p = context.palette;
            final now = DateTime.now();
            final first = orders
                .map((o) => o.createdAt.toLocal())
                .reduce((a, b) => a.isBefore(b) ? a : b);
            final rangeStart =
                DateTime(first.year, first.month, first.day, first.hour);
            final rows = orders.map((order) {
              final events = timelines[order.id] ?? [];
              return GanttRow(
                label: order.restaurantName,
                subtitle:
                    '${AppFormat.orderCode(order.id)} · ${AppFormat.money(context, order.totalAmount)}',
                stages: ganttStagesFromTimeline(events, now),
              );
            }).toList();

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.scheduleTitle,
                                style: AppTypography.headingSmall
                                    .copyWith(color: p.textPrimary)),
                            Text(r.scheduleSubtitle,
                                style: AppTypography.bodySmall
                                    .copyWith(color: p.textSecondary)),
                          ],
                        ),
                      ),
                      Text(r.deliveriesCount(orders.length),
                          style: AppTypography.labelMedium
                              .copyWith(color: p.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppGanttChart(
                    rows: rows,
                    rangeStart: rangeStart,
                    rangeEnd: now,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
