import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../orders/application/order_provider.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../application/analytics_provider.dart';
import 'restaurant_order_card.dart';

/// Board columns, in kitchen order.
enum OrderBoardSegment { fresh, inKitchen, ready, done }

extension OrderBoardSegmentX on OrderBoardSegment {
  bool matches(OrderModel o, DateTime startOfToday) => switch (this) {
        OrderBoardSegment.fresh => o.status == OrderStatus.pending,
        OrderBoardSegment.inKitchen => o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.preparing,
        OrderBoardSegment.ready =>
          o.status == OrderStatus.ready || o.status == OrderStatus.pickedUp,
        OrderBoardSegment.done => (o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled) &&
            !o.createdAt.toLocal().isBefore(startOfToday),
      };
}

/// Live orders, split into New / Preparing / Ready / Done today.
class OrdersBoard extends ConsumerStatefulWidget {
  const OrdersBoard({
    super.key,
    required this.restaurantId,
    required this.segment,
    required this.onSegmentChanged,
  });

  final String restaurantId;
  final OrderBoardSegment segment;
  final ValueChanged<OrderBoardSegment> onSegmentChanged;

  @override
  ConsumerState<OrdersBoard> createState() => _OrdersBoardState();
}

class _OrdersBoardState extends ConsumerState<OrdersBoard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keeps "5m ago" / "Waiting 6 min" fresh without new data.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync =
        ref.watch(restaurantOrdersProvider(widget.restaurantId));
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    if (!ordersAsync.hasValue) {
      if (ordersAsync.hasError) {
        return AppErrorState(
          error: ordersAsync.error,
          onRetry: () =>
              ref.invalidate(restaurantOrdersProvider(widget.restaurantId)),
        );
      }
      return const AppShimmerCardList(count: 3, itemHeight: 112);
    }

    final orders = ordersAsync.value!;
    final counts = {
      for (final seg in OrderBoardSegment.values)
        seg: orders.where((o) => seg.matches(o, startOfToday)).length,
    };
    final visible = orders
        .where((o) => widget.segment.matches(o, startOfToday))
        .toList()
      // Oldest first for work in progress (first in, first out).
      ..sort((a, b) => widget.segment == OrderBoardSegment.done
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.sm),
          child: _SegmentBar(
              selected: widget.segment,
              counts: counts,
              onChanged: widget.onSegmentChanged),
        ),
        _TodayStrip(restaurantId: widget.restaurantId),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(restaurantOrdersProvider(widget.restaurantId)),
            child: visible.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [_EmptySegment(segment: widget.segment)],
                  )
                : _OrderList(orders: visible),
          ),
        ),
      ],
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const pad = EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
          AppSpacing.sm, AppSpacing.screenHorizontal, AppSpacing.xxl);
      final columns = constraints.maxWidth >= 1100
          ? 3
          : (constraints.maxWidth >= 720 ? 2 : 1);
      if (columns == 1) {
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: pad,
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) => RestaurantOrderCard(
              key: ValueKey(orders[i].id), order: orders[i]),
        );
      }
      final cols = List.generate(columns, (_) => <OrderModel>[]);
      for (var i = 0; i < orders.length; i++) {
        cols[i % columns].add(orders[i]);
      }
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: pad,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  children: [
                    for (final o in cols[c])
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child:
                            RestaurantOrderCard(key: ValueKey(o.id), order: o),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar(
      {required this.selected, required this.counts, required this.onChanged});

  final OrderBoardSegment selected;
  final Map<OrderBoardSegment, int> counts;
  final ValueChanged<OrderBoardSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.restaurant;
    String label(OrderBoardSegment seg) => switch (seg) {
          OrderBoardSegment.fresh => s.filterNew,
          OrderBoardSegment.inKitchen => s.filterPreparing,
          OrderBoardSegment.ready => s.filterReady,
          OrderBoardSegment.done => s.filterDone,
        };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          for (final seg in OrderBoardSegment.values)
            Expanded(
              child: _SegmentTab(
                label: label(seg),
                count: counts[seg] ?? 0,
                selected: seg == selected,
                // Only waiting work deserves a loud count.
                alert: seg == OrderBoardSegment.fresh,
                onTap: () => onChanged(seg),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.alert,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final bool alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final loud = alert && count > 0;
    final badgeBg = loud ? p.accent : (selected ? p.brandSoft : p.border);
    final badgeFg =
        loud ? p.onAccent : (selected ? p.onBrandSoft : p.textSecondary);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: Material(
        color: selected ? p.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: 2,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label.copyWith(
                        color: selected ? p.textPrimary : p.textSecondary),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs)),
                    child: Text('$count',
                        textAlign: TextAlign.center,
                        style: context.text.overline.copyWith(color: badgeFg)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayStrip extends ConsumerWidget {
  const _TodayStrip({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales =
        ref.watch(restaurantDailySalesProvider(restaurantId)).valueOrNull;
    if (sales == null) return const SizedBox(height: AppSpacing.xs);
    final kpis = SalesKpis.fromDaily(sales);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 0,
          AppSpacing.screenHorizontal, AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.today_rounded,
              size: 16, color: context.palette.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.s.restaurant.todayStrip(kpis.todayOrders,
                  AppFormat.money(context, kpis.todayRevenue)),
              style: context.text.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySegment extends StatelessWidget {
  const _EmptySegment({required this.segment});

  final OrderBoardSegment segment;

  @override
  Widget build(BuildContext context) {
    final s = context.s.restaurant;
    final (IconData icon, String title, String body) = switch (segment) {
      OrderBoardSegment.fresh => (
          Icons.notifications_none_rounded,
          s.emptyNewTitle,
          s.emptyNewBody
        ),
      OrderBoardSegment.inKitchen => (
          Icons.soup_kitchen_outlined,
          s.emptyPreparingTitle,
          s.emptyPreparingBody
        ),
      OrderBoardSegment.ready => (
          Icons.inventory_2_outlined,
          s.emptyReadyTitle,
          s.emptyReadyBody
        ),
      OrderBoardSegment.done => (
          Icons.task_alt_rounded,
          s.emptyDoneTitle,
          s.emptyDoneBody
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: AppEmptyState(
          icon: icon, title: title, subtitle: body, compact: true),
    );
  }
}
