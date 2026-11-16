import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/order_timeline_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_gantt_chart.dart';
import '../../../shared/widgets/app_status_badge.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../orders/application/order_provider.dart';
import '../../orders/domain/models/order_model.dart';

class OrderPrepGanttView extends ConsumerStatefulWidget {
  const OrderPrepGanttView({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<OrderPrepGanttView> createState() => _OrderPrepGanttViewState();
}

class _OrderPrepGanttViewState extends ConsumerState<OrderPrepGanttView> {
  List<String> _ids = const [];

  List<String> _stableIds(List<String> ids) {
    if (!listEquals(ids, _ids)) _ids = List.unmodifiable(ids);
    return _ids;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.restaurant;
    final ordersAsync =
        ref.watch(restaurantOrdersProvider(widget.restaurantId));

    Widget body;
    if (!ordersAsync.hasValue) {
      body = ordersAsync.hasError
          ? AppErrorState(
              error: ordersAsync.error,
              onRetry: () =>
                  ref.invalidate(restaurantOrdersProvider(widget.restaurantId)),
            )
          : const AppShimmerCardList(
              count: 3, itemHeight: 40, shrinkWrap: true);
    } else {
      final active = ordersAsync.value!.where((o) => o.status.isActive).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      body = active.isEmpty
          ? AppEmptyState(
              icon: Icons.timeline_rounded,
              title: s.timelineEmptyTitle,
              subtitle: s.timelineEmptyBody,
              compact: true,
            )
          : _Chart(
              orders: active,
              ids: _stableIds(active.map((o) => o.id).toList()));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        Text(s.timelineTitle, style: context.text.h2),
        const SizedBox(height: AppSpacing.xs),
        Text(s.timelineSubtitle, style: context.text.secondary),
        const SizedBox(height: AppSpacing.md),
        const _Legend(),
        const SizedBox(height: AppSpacing.lg),
        body,
      ],
    );
  }
}

class _Chart extends ConsumerWidget {
  const _Chart({required this.orders, required this.ids});

  final List<OrderModel> orders;
  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.restaurant;
    final timelinesAsync = ref.watch(orderTimelinesBatchProvider(ids));
    if (!timelinesAsync.hasValue) {
      return timelinesAsync.hasError
          ? AppErrorState(
              error: timelinesAsync.error,
              onRetry: () => ref.invalidate(orderTimelinesBatchProvider(ids)))
          : const AppShimmerCardList(
              count: 3, itemHeight: 40, shrinkWrap: true);
    }
    final timelines = timelinesAsync.value!;
    final now = DateTime.now();
    final rows = [
      for (final order in orders)
        GanttRow(
          label: AppFormat.orderCode(order.id),
          subtitle:
              '${s.itemsCount(order.items.length)} · ${AppFormat.timeAgo(context, order.createdAt)}',
          stages: ganttStagesFromTimeline(timelines[order.id] ?? const [], now),
          onTap: () =>
              context.pushOnce('${RouteNames.orderDetail}/${order.id}'),
        ),
    ];
    final earliest = orders
        .map((o) => o.createdAt)
        .fold<DateTime>(now, (min, d) => d.isBefore(min) ? d : min);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(AppFormat.time(context, earliest),
                      style: context.text.hint)),
              Text(AppFormat.time(context, now), style: context.text.hint),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppGanttChart(
              rows: rows,
              rangeStart: earliest,
              rangeEnd: now,
              labelWidth: 112,
              rowHeight: 40),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready
    ];
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        for (final st in statuses)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: OrderStatusStyle.of(st).color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(OrderStatusStyle.label(context, st),
                  style: context.text.caption.copyWith(color: p.textSecondary)),
            ],
          ),
      ],
    );
  }
}
