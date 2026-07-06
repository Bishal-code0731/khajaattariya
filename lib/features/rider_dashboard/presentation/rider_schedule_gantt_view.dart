import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/order_timeline_provider.dart';
import '../../../shared/widgets/app_gantt_chart.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../orders/application/order_provider.dart';

/// A rider's delivery schedule for today — one row per job, showing how
/// long each spent assigned/picked-up/delivering so a rider (or later,
/// an admin) can see the day's pacing at a glance.
class RiderScheduleGanttView extends ConsumerWidget {
  final String riderId;

  const RiderScheduleGanttView({super.key, required this.riderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(riderOrdersTodayProvider(riderId));

    return AsyncValueView(
      value: ordersAsync,
      errorMessage: 'Could not load today\'s schedule',
      onRetry: () => ref.invalidate(riderOrdersTodayProvider(riderId)),
      data: (orders) {
        if (orders.isEmpty) {
          return const AppEmptyState(
            icon: Icons.route_outlined,
            title: 'No deliveries yet today',
            subtitle: 'Your accepted jobs will show up here as a timeline',
          );
        }

        final orderIds = orders.map((o) => o.id).toList();
        final timelinesAsync = ref.watch(orderTimelinesBatchProvider(orderIds));

        return timelinesAsync.when(
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load timeline',
          ),
          data: (timelines) {
            final now = DateTime.now();
            final rows = orders.map((order) {
              final events = timelines[order.id] ?? [];
              return GanttRow(
                label: order.restaurantName,
                subtitle: 'Rs. ${order.totalAmount.toInt()}',
                stages: ganttStagesFromTimeline(events, now),
              );
            }).toList();

            final startOfDay = DateTime(now.year, now.month, now.day);

            return GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: AppSpacing.radiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Schedule", style: AppTypography.headingSmall),
                  const SizedBox(height: AppSpacing.md),
                  AppGanttChart(
                    rows: rows,
                    rangeStart: startOfDay,
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
