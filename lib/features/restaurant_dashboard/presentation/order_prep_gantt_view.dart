import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/route_names.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/order_timeline_provider.dart';
import '../../../shared/widgets/app_gantt_chart.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../orders/application/order_provider.dart';

/// Kitchen order-prep pipeline: one row per active order, showing how
/// long it's spent in each status so a restaurant can spot orders stuck
/// "preparing" too long at a glance instead of reading a plain list.
class OrderPrepGanttView extends ConsumerWidget {
  final String restaurantId;

  const OrderPrepGanttView({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(restaurantOrdersProvider(restaurantId));

    return AsyncValueView(
      value: ordersAsync,
      errorMessage: 'Could not load order pipeline',
      onRetry: () => ref.invalidate(restaurantOrdersProvider(restaurantId)),
      data: (orders) {
        final active = orders.where((o) => o.status.isActive).toList();
        if (active.isEmpty) {
          return const AppEmptyState(
            icon: Icons.timeline_rounded,
            title: 'No active orders',
            subtitle: 'Orders in progress will show their prep timeline here',
          );
        }

        final orderIds = active.map((o) => o.id).toList();
        final timelinesAsync = ref.watch(orderTimelinesBatchProvider(orderIds));

        return timelinesAsync.when(
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load timeline',
          ),
          data: (timelines) {
            final now = DateTime.now();
            final rows = active.map((order) {
              final events = timelines[order.id] ?? [];
              return GanttRow(
                label: 'Order #${order.id.substring(0, 8).toUpperCase()}',
                subtitle: '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                stages: ganttStagesFromTimeline(events, now),
                onTap: () => context.pushOnce('${RouteNames.orderDetail}/${order.id}'),
              );
            }).toList();

            final earliestStart = active
                .map((o) => o.createdAt)
                .fold<DateTime>(now, (min, d) => d.isBefore(min) ? d : min);

            return GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: AppSpacing.radiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Prep Timeline', style: AppTypography.headingSmall),
                  const SizedBox(height: AppSpacing.md),
                  AppGanttChart(
                    rows: rows,
                    rangeStart: earliestStart,
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
