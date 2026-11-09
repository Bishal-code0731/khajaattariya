import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/l10n/strings/admin_strings.dart';
import '../../../../core/router/navigation_extensions.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_status_badge.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../orders/domain/models/order_model.dart';
import '../../application/admin_queries.dart';
import '../../domain/admin_models.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_list.dart';

String paymentLabel(AdminStrings s, String method) => switch (method) {
      'khalti' => s.payKhalti,
      'esewa' => s.payEsewa,
      _ => s.payCash,
    };

/// Latest orders: filter by status, search by order code, open detail.
class OrdersSection extends ConsumerStatefulWidget {
  const OrdersSection({super.key});

  @override
  ConsumerState<OrdersSection> createState() => _OrdersSectionState();
}

class _OrdersSectionState extends ConsumerState<OrdersSection> {
  final _search = TextEditingController();
  String _query = '';
  OrderStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AdminOrder o) {
    if (_status != null && OrderStatus.fromString(o.status) != _status) {
      return false;
    }
    if (_query.isEmpty) return true;
    final q = _query.replaceAll('#', '').toUpperCase();
    return AppFormat.orderCode(o.id).contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final async = ref.watch(adminOrdersProvider);
    final all = async.valueOrNull ?? const <AdminOrder>[];
    int count(OrderStatus st) =>
        all.where((o) => OrderStatus.fromString(o.status) == st).length;

    return AdminAsyncList<AdminOrder>(
      value: async.whenData((list) => list.where(_matches).toList()),
      onRefresh: () => ref.refresh(adminOrdersProvider.future),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.xs),
            child: AppSearchField(
              hint: s.searchOrders,
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              onClear: _query.isEmpty
                  ? null
                  : () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
            ),
          ),
          AdminFilterBar<OrderStatus?>(
            selected: _status,
            onSelected: (v) => setState(() => _status = v),
            options: [
              AdminFilterOption(null, s.all, count: all.length),
              for (final st in OrderStatus.values)
                AdminFilterOption(st, OrderStatusStyle.label(context, st),
                    count: count(st)),
            ],
          ),
        ],
      ),
      empty: AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: all.isEmpty ? s.ordersEmpty : s.noResults,
        subtitle: all.isEmpty ? s.ordersEmptyHint : s.noResultsHint,
        compact: true,
      ),
      itemBuilder: (context, o) => _OrderRow(order: o),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final s = context.s.admin;
    final o = order;
    final code = AppFormat.orderCode(o.id);
    return AdminRow(
      onTap: () => context.pushOnce('${RouteNames.orderDetail}/${o.id}'),
      semanticLabel: '${s.openOrder} $code',
      title: '$code · ${o.restaurantName ?? s.unknown}',
      trailing: Text(AppFormat.money(context, o.totalAmount),
          style: context.text.price),
      lines: [
        '${s.customerLine(o.customerName ?? s.unknown)} · ${paymentLabel(s, o.paymentMethod)} · '
            '${AppFormat.timeAgo(context, o.createdAt)}',
      ],
      tags: [
        AppStatusBadge(status: OrderStatus.fromString(o.status), compact: true)
      ],
    );
  }
}
