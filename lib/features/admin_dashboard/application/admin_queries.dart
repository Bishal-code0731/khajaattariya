import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../../shared/order_timeline_provider.dart';
import '../domain/admin_models.dart';

// Read side of the admin console.

List<Map<String, dynamic>> _rows(Object data) =>
    List<Map<String, dynamic>>.from(data as List);

String _startOfTodayUtc() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
}

/// Every account, newest first.
final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  final data = await supabase
      .from('profiles')
      .select('id, full_name, phone, role, is_active, created_at')
      .order('created_at', ascending: false);
  return _rows(data).map(AdminUser.fromMap).toList();
});

/// Every restaurant with its owner, newest first.
final adminRestaurantsProvider =
    FutureProvider<List<AdminRestaurant>>((ref) async {
  final data = await supabase
      .from('restaurants')
      .select('*, profiles!owner_id(full_name, phone)')
      .order('created_at', ascending: false);
  return _rows(data).map(AdminRestaurant.fromMap).toList();
});

/// Latest 100 orders across the platform.
final adminOrdersProvider = FutureProvider<List<AdminOrder>>((ref) async {
  final data = await supabase
      .from('orders')
      .select('id, status, total_amount, payment_method, created_at, '
          'restaurants(name), profiles!customer_id(full_name)')
      .order('created_at', ascending: false)
      .limit(100);
  return _rows(data).map(AdminOrder.fromMap).toList();
});

final adminCouponsProvider = FutureProvider<List<AdminCoupon>>((ref) async {
  final data = await supabase
      .from('coupons')
      .select()
      .order('created_at', ascending: false);
  return _rows(data).map(AdminCoupon.fromMap).toList();
});

/// Refund requests, newest first.
final adminRefundsProvider = FutureProvider<List<AdminRefund>>((ref) async {
  final data = await supabase
      .from('refunds')
      .select('*, orders(total_amount, profiles!customer_id(full_name))')
      .order('created_at', ascending: false)
      .limit(200);
  return _rows(data).map(AdminRefund.fromMap).toList();
});

/// Rider cash settlement requests (pending and handled), newest first.
final adminSettlementsProvider =
    FutureProvider<List<AdminSettlement>>((ref) async {
  final data = await supabase
      .from('rider_cash_ledger')
      .select('id, rider_id, amount, status, note, created_at, confirmed_at, '
          'riders(profiles(full_name, phone))')
      .eq('entry_type', 'settlement')
      .order('created_at', ascending: false)
      .limit(200);
  return _rows(data).map(AdminSettlement.fromMap).toList();
});

/// Cash each rider holds right now (confirmed ledger rows only), by rider id.
final adminRiderCashProvider = FutureProvider<Map<String, double>>((ref) async {
  final data = await supabase
      .from('rider_cash_balances')
      .select('rider_id, cash_in_hand');
  return {
    for (final row in _rows(data))
      row['rider_id'] as String: (row['cash_in_hand'] as num?)?.toDouble() ?? 0,
  };
});

/// Latest 100 audit entries with the actor's name.
final adminAuditProvider = FutureProvider<List<AdminAuditEntry>>((ref) async {
  final data = await supabase
      .from('audit_logs')
      .select(
          'id, action, target_table, target_id, created_at, profiles!actor_id(full_name)')
      .order('created_at', ascending: false)
      .limit(100);
  return _rows(data).map(AdminAuditEntry.fromMap).toList();
});

/// Overview counts.
final adminOverviewProvider = FutureProvider<AdminOverview>((ref) async {
  final today = _startOfTodayUtc();
  final results = await Future.wait<Object>([
    supabase
        .from('orders')
        .select('status, total_amount')
        .gte('created_at', today),
    supabase
        .from('restaurants')
        .select('is_approved, is_active, approval_note'),
    supabase
        .from('riders')
        .select('is_approved, approval_note')
        .eq('is_approved', false),
    supabase
        .from('support_tickets')
        .select('id')
        .inFilter('status', ['open', 'in_progress']),
    supabase.from('refunds').select('id').eq('status', 'pending'),
    supabase
        .from('rider_cash_ledger')
        .select('amount')
        .eq('entry_type', 'settlement')
        .eq('status', 'pending'),
  ]);
  final orders = _rows(results[0]);
  final restaurants = _rows(results[1])
      .map((m) => AdminRestaurant.fromMap({...m, 'id': ''}))
      .toList();
  final riders = _rows(results[2]);
  final settlements = _rows(results[5]);
  final delivered = orders.where((o) => o['status'] == 'delivered');
  return AdminOverview(
    ordersToday: orders.length,
    deliveredToday: delivered.length,
    deliveredValueToday: delivered.fold<double>(
        0, (s, o) => s + ((o['total_amount'] as num?)?.toDouble() ?? 0)),
    activeRestaurants:
        restaurants.where((r) => r.queue == RestaurantQueue.active).length,
    pendingRestaurants:
        restaurants.where((r) => r.queue == RestaurantQueue.pending).length,
    pendingRiders: riders
        .where(
            (r) => (r['approval_note'] as String?)?.trim().isNotEmpty != true)
        .length,
    openTickets: _rows(results[3]).length,
    pendingRefunds: _rows(results[4]).length,
    pendingSettlements: settlements.length,
    pendingSettlementAmount: settlements.fold<double>(
        0, (s, o) => s + ((o['amount'] as num?)?.toDouble() ?? 0)),
  );
});

class AdminTimeline {
  const AdminTimeline(this.orders, this.events);
  final List<AdminOrder> orders;
  final Map<String, List<OrderTimelineEvent>> events;
}

/// The last 12 orders with their status history, for the overview chart.
final adminTimelineProvider =
    FutureProvider.autoDispose<AdminTimeline>((ref) async {
  final orders =
      (await ref.watch(adminOrdersProvider.future)).take(12).toList();
  if (orders.isEmpty) return const AdminTimeline([], {});
  final ids = orders.map((o) => o.id).toList();
  final events = await ref.watch(orderTimelinesBatchProvider(ids).future);
  return AdminTimeline(orders, events);
});
