import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/order_provider.dart';
import '../domain/models/order_model.dart';
import 'widgets/order_actions.dart';
import 'widgets/order_info_sections.dart';
import 'widgets/order_status_card.dart';

/// One order, live.
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = context.s.orders;
    final orderAsync = ref.watch(orderStreamProvider(orderId));
    final userId = ref.watch(authStateProvider).valueOrNull?.id;
    final order = orderAsync.valueOrNull;
    final isCustomer =
        order != null && userId != null && order.customerId == userId;

    return Scaffold(
      appBar: AppTopBar(
        title: o.orderTitle(AppFormat.orderCode(orderId)),
        subtitle: order == null
            ? null
            : o.placedOn(AppFormat.dateTime(context, order.createdAt)),
      ),
      bottomNavigationBar:
          order != null && isCustomer ? OrderActionBar(order: order) : null,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: orderAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const _DetailSkeleton(),
              error: (e, _) => AppErrorState(
                error: e,
                onRetry: () => ref.invalidate(orderStreamProvider(orderId)),
              ),
              data: (order) {
                if (order == null) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: o.orderNotFoundTitle,
                    subtitle: o.orderNotFoundBody,
                    action: AppButton(
                      label: o.backToOrders,
                      expand: false,
                      onPressed: () => context.safeBack(RouteNames.orders),
                    ),
                  );
                }
                return _DetailBody(order: order, isCustomer: isCustomer);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.order, required this.isCustomer});
  final OrderModel order;
  final bool isCustomer;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.md);
    final status = OrderStatusCard(order: order, isCustomer: isCustomer);
    final restaurant = OrderRestaurantCard(order: order, showCall: isCustomer);
    final bill = OrderBillCard(order: order);
    final delivery = OrderDeliveryPaymentCard(order: order);
    final help = isCustomer ? OrderHelpSection(order: order) : null;

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      final horizontal = constraints.maxWidth > AppSpacing.maxContentWidth
          ? (constraints.maxWidth - AppSpacing.maxContentWidth) / 2
          : (wide ? AppSpacing.xl : AppSpacing.screenHorizontal);
      final padding = EdgeInsets.fromLTRB(
          horizontal, AppSpacing.lg, horizontal, AppSpacing.xxl);

      if (!wide) {
        return ListView(
          padding: padding,
          children: [
            status,
            gap,
            restaurant,
            gap,
            bill,
            gap,
            delivery,
            if (help != null) ...[gap, help],
          ],
        );
      }

      return SingleChildScrollView(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [status, gap, bill],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  restaurant,
                  gap,
                  delivery,
                  if (help != null) ...[gap, help],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        AppShimmer(
            height: 260,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        const SizedBox(height: AppSpacing.md),
        AppShimmer(
            height: 80,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        const SizedBox(height: AppSpacing.md),
        AppShimmer(
            height: 200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ],
    );
  }
}
