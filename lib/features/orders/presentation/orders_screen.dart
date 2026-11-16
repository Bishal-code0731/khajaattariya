import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/order_provider.dart';
import '../domain/models/order_model.dart';
import 'widgets/order_card.dart';

/// The customer's orders, split into Active and Past, live-updating.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = context.s.orders;
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppTopBar(title: o.myOrders),
        body: authAsync.isLoading
            ? const AppShimmerCardList(count: 3, itemHeight: 140)
            : AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: o.loginTitle,
                subtitle: o.loginBody,
                action: AppButton(
                  label: context.s.common.login,
                  expand: false,
                  onPressed: () => context.push(RouteNames.login),
                ),
              ),
      );
    }

    final ordersAsync = ref.watch(customerOrdersStreamProvider(user.id));
    final p = context.palette;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppTopBar(
          title: o.myOrders,
          bottom: TabBar(
            labelColor: p.brand,
            unselectedLabelColor: p.textSecondary,
            indicatorColor: p.brand,
            dividerColor: p.border,
            labelStyle: AppTypography.labelLarge,
            unselectedLabelStyle: AppTypography.labelLarge,
            tabs: [
              _CountTab(
                label: o.tabActive,
                count: ordersAsync.valueOrNull
                    ?.where((x) => x.status.isActive)
                    .length,
              ),
              Tab(text: o.tabPast),
            ],
          ),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: ordersAsync.when(
                skipLoadingOnRefresh: true,
                loading: () =>
                    const AppShimmerCardList(count: 4, itemHeight: 140),
                error: (e, _) => AppErrorState(
                  error: e,
                  onRetry: () =>
                      ref.invalidate(customerOrdersStreamProvider(user.id)),
                ),
                data: (orders) {
                  Future<void> refresh() =>
                      ref.refresh(customerOrdersStreamProvider(user.id).future);
                  return TabBarView(
                    children: [
                      _OrderList(
                        orders: orders.where((x) => x.status.isActive).toList(),
                        onRefresh: refresh,
                        emptyIcon: Icons.delivery_dining_outlined,
                        emptyTitle: o.noActiveTitle,
                        emptyBody: o.noActiveBody,
                      ),
                      _OrderList(
                        orders:
                            orders.where((x) => !x.status.isActive).toList(),
                        onRefresh: refresh,
                        emptyIcon: Icons.receipt_long_outlined,
                        emptyTitle: o.noPastTitle,
                        emptyBody: o.noPastBody,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountTab extends StatelessWidget {
  const _CountTab({required this.label, this.count});
  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = count ?? 0;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (n > 0) ...[
            const SizedBox(width: AppSpacing.xs + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: p.brand,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text('$n',
                  style: AppTypography.labelSmall.copyWith(color: p.onBrand)),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final List<OrderModel> orders;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: p.brand,
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: AppEmptyState(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptyBody,
                action: AppButton(
                  label: context.s.orders.browseRestaurants,
                  leadingIcon: Icons.storefront_outlined,
                  expand: false,
                  onPressed: () => context.go(RouteNames.home),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: p.brand,
      onRefresh: onRefresh,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : (width >= 600 ? 2 : 1);
        final horizontal = width > AppSpacing.maxContentWidth
            ? (width - AppSpacing.maxContentWidth) / 2
            : AppSpacing.screenHorizontal;
        final padding = EdgeInsets.fromLTRB(
            horizontal, AppSpacing.lg, horizontal, AppSpacing.xxl);

        Widget card(OrderModel order) => OrderCard(
              order: order,
              onTap: () =>
                  context.pushOnce('${RouteNames.orderDetail}/${order.id}'),
              onOrderAgain: () => context
                  .pushOnce('${RouteNames.restaurant}/${order.restaurantId}'),
            );

        if (columns == 1) {
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: padding,
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => card(orders[i]),
          );
        }

        // Rows of [columns] cards on tablets and wide screens.
        final rows = (orders.length / columns).ceil();
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: rows,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, r) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: r * columns + c < orders.length
                      ? card(orders[r * columns + c])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}
