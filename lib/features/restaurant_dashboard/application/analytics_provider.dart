import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/memory_cache.dart';
import '../../../main.dart';

class DailySales {
  final DateTime date;
  final int totalOrders;
  final double totalRevenue;

  const DailySales({
    required this.date,
    required this.totalOrders,
    required this.totalRevenue,
  });

  factory DailySales.fromMap(Map<String, dynamic> map) {
    return DailySales(
      date: DateTime.parse(map['date'] as String),
      totalOrders: map['total_orders'] as int,
      totalRevenue: (map['total_revenue'] as num).toDouble(),
    );
  }
}

final restaurantDailySalesProvider =
    FutureProvider.family<List<DailySales>, String>((ref, restaurantId) async {
  final since = DateTime.now().subtract(const Duration(days: 6));
  final data = await supabase
      .from('daily_sales')
      .select('date, total_orders, total_revenue')
      .eq('restaurant_id', restaurantId)
      .gte('date', since.toIso8601String().split('T').first)
      .order('date', ascending: true);
  return (data as List)
      .map((m) => DailySales.fromMap(m as Map<String, dynamic>))
      .toList();
});

final restaurantMonthlySalesProvider =
    FutureProvider.family<List<DailySales>, String>((ref, restaurantId) async {
  final since = DateTime.now().subtract(const Duration(days: 29));
  final data = await supabase
      .from('daily_sales')
      .select('date, total_orders, total_revenue')
      .eq('restaurant_id', restaurantId)
      .gte('date', since.toIso8601String().split('T').first)
      .order('date', ascending: true);
  return (data as List)
      .map((m) => DailySales.fromMap(m as Map<String, dynamic>))
      .toList();
});

class SalesKpis {
  const SalesKpis({
    required this.todayRevenue,
    required this.todayOrders,
    required this.weekRevenue,
    required this.weekOrders,
    required this.monthRevenue,
    required this.monthOrders,
  });

  final double todayRevenue;
  final int todayOrders;
  final double weekRevenue;
  final int weekOrders;
  final double monthRevenue;
  final int monthOrders;

  /// Average delivered-order value over 30 days (0 when no orders).
  double get averageOrderValue =>
      monthOrders == 0 ? 0 : monthRevenue / monthOrders;

  factory SalesKpis.fromDaily(List<DailySales> monthly, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfWeek = startOfToday.subtract(const Duration(days: 6));
    var tRev = 0.0, wRev = 0.0, mRev = 0.0;
    var tOrd = 0, wOrd = 0, mOrd = 0;
    for (final d in monthly) {
      final day = DateTime(d.date.year, d.date.month, d.date.day);
      mRev += d.totalRevenue;
      mOrd += d.totalOrders;
      if (!day.isBefore(startOfWeek)) {
        wRev += d.totalRevenue;
        wOrd += d.totalOrders;
      }
      if (day == startOfToday) {
        tRev += d.totalRevenue;
        tOrd += d.totalOrders;
      }
    }
    return SalesKpis(
      todayRevenue: tRev,
      todayOrders: tOrd,
      weekRevenue: wRev,
      weekOrders: wOrd,
      monthRevenue: mRev,
      monthOrders: mOrd,
    );
  }
}

/// Clears cached analytics so pull-to-refresh really reloads.
void refreshRestaurantAnalytics(WidgetRef ref, String restaurantId) {
  MemoryCache.instance.invalidate('analytics_summary:$restaurantId');
  ref.invalidate(restaurantMonthlySalesProvider(restaurantId));
  ref.invalidate(restaurantAnalyticsSummaryProvider(restaurantId));
  ref.invalidate(restaurantDailySalesProvider(restaurantId));
}

class TopFoodItem {
  final String name;
  final int quantitySold;
  final double revenue;
  const TopFoodItem(
      {required this.name, required this.quantitySold, required this.revenue});
}

class RestaurantAnalyticsSummary {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double cancellationRate; // 0..1
  final int uniqueCustomers;
  final int repeatCustomers;
  final List<TopFoodItem> topFoods;
  final Map<int, int> ordersByHour; // 0..23 -> count, for peak-hours chart

  const RestaurantAnalyticsSummary({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.cancellationRate,
    required this.uniqueCustomers,
    required this.repeatCustomers,
    required this.topFoods,
    required this.ordersByHour,
  });

  static const empty = RestaurantAnalyticsSummary(
    totalOrders: 0,
    completedOrders: 0,
    cancelledOrders: 0,
    cancellationRate: 0,
    uniqueCustomers: 0,
    repeatCustomers: 0,
    topFoods: [],
    ordersByHour: {},
  );
}

final restaurantAnalyticsSummaryProvider =
    FutureProvider.family<RestaurantAnalyticsSummary, String>(
        (ref, restaurantId) async {
  return MemoryCache.instance.fetch('analytics_summary:$restaurantId',
      () async {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final orders = await supabase
        .from('orders')
        .select('id, status, customer_id, created_at')
        .eq('restaurant_id', restaurantId)
        .gte('created_at', since.toIso8601String());

    final orderRows = (orders as List).cast<Map<String, dynamic>>();
    if (orderRows.isEmpty) return RestaurantAnalyticsSummary.empty;

    final totalOrders = orderRows.length;
    final completed = orderRows.where((o) => o['status'] == 'delivered').length;
    final cancelled = orderRows.where((o) => o['status'] == 'cancelled').length;

    final customerCounts = <String, int>{};
    final ordersByHour = <int, int>{};
    for (final o in orderRows) {
      final customerId = o['customer_id'] as String?;
      if (customerId != null) {
        customerCounts[customerId] = (customerCounts[customerId] ?? 0) + 1;
      }
      final createdAt = DateTime.tryParse(o['created_at'] as String? ?? '');
      if (createdAt != null) {
        final hour = createdAt.toLocal().hour;
        ordersByHour[hour] = (ordersByHour[hour] ?? 0) + 1;
      }
    }
    final uniqueCustomers = customerCounts.length;
    final repeatCustomers = customerCounts.values.where((c) => c > 1).length;

    final orderIds = orderRows.map((o) => o['id'] as String).toList();
    final items = orderIds.isEmpty
        ? const []
        : await supabase
            .from('order_items')
            .select('name, quantity, subtotal')
            .inFilter('order_id', orderIds);

    final byFood = <String, TopFoodItem>{};
    for (final row in items.cast<Map<String, dynamic>>()) {
      final name = row['name'] as String? ?? '-';
      final qty = (row['quantity'] as num?)?.toInt() ?? 0;
      final subtotal = (row['subtotal'] as num?)?.toDouble() ?? 0;
      final existing = byFood[name];
      byFood[name] = TopFoodItem(
        name: name,
        quantitySold: (existing?.quantitySold ?? 0) + qty,
        revenue: (existing?.revenue ?? 0) + subtotal,
      );
    }
    final topFoods = byFood.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return RestaurantAnalyticsSummary(
      totalOrders: totalOrders,
      completedOrders: completed,
      cancelledOrders: cancelled,
      cancellationRate: totalOrders == 0 ? 0 : cancelled / totalOrders,
      uniqueCustomers: uniqueCustomers,
      repeatCustomers: repeatCustomers,
      topFoods: topFoods.take(5).toList(),
      ordersByHour: ordersByHour,
    );
  }, ttl: const Duration(minutes: 5));
});
