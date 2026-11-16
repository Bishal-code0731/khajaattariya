import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../../cart/domain/models/cart_state.dart';
import '../data/order_repository_impl.dart';
import '../domain/models/order_model.dart';
import '../domain/repositories/order_repository.dart';

part 'order_provider.g.dart';

@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepositoryImpl();
}

// Customer orders list (future – kept for compatibility)
@Riverpod(keepAlive: true)
Future<List<OrderModel>> customerOrders(Ref ref, String customerId) {
  return ref.watch(orderRepositoryProvider).getCustomerOrders(customerId);
}

// Single order detail (future)
@Riverpod(keepAlive: true)
Future<OrderModel> orderById(Ref ref, String orderId) {
  return ref.watch(orderRepositoryProvider).getOrderById(orderId);
}

/// Restaurant columns the order screens show (name, photo, phone, map pin).
const _restaurantColumns = 'id, name, image_url, phone, latitude, longitude';

Future<List<OrderModel>> _hydrateOrders(List<Map<String, dynamic>> rows) async {
  if (rows.isEmpty) return [];

  final orderIds = rows.map((r) => r['id'] as String).toSet().toList();
  final restaurantIds =
      rows.map((r) => r['restaurant_id'] as String).toSet().toList();

  final itemsRows = await supabase
      .from('order_items')
      .select()
      .inFilter('order_id', orderIds);
  final restaurantRows = await supabase
      .from('restaurants')
      .select(_restaurantColumns)
      .inFilter('id', restaurantIds);

  final itemsByOrder = <String, List<Map<String, dynamic>>>{};
  for (final item in itemsRows) {
    (itemsByOrder[item['order_id'] as String] ??= []).add(item);
  }
  final restaurantById = {
    for (final r in restaurantRows) r['id'] as String: r,
  };

  return rows.map((row) {
    return OrderModel.fromMap({
      ...row,
      'restaurants':
          restaurantById[row['restaurant_id']] ?? const <String, dynamic>{},
      'order_items': itemsByOrder[row['id']] ?? const [],
    });
  }).toList();
}

const _ordersStreamLimit = 100;

// Restaurant incoming orders — stream for real-time updates
@riverpod
Stream<List<OrderModel>> restaurantOrders(Ref ref, String restaurantId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false)
      .limit(_ordersStreamLimit)
      .asyncMap(_hydrateOrders);
}

// Available orders for rider (status = ready, no rider assigned)
@riverpod
Stream<List<OrderModel>> availableOrders(Ref ref) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('status', 'ready')
      .order('created_at', ascending: false)
      .limit(_ordersStreamLimit)
      .map((data) => data.where((map) => map['rider_id'] == null).toList())
      .asyncMap(_hydrateOrders);
}

// Rider's active delivery
@riverpod
Stream<OrderModel?> riderActiveOrder(Ref ref, String riderId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('rider_id', riderId)
      .order('created_at', ascending: false)
      .limit(_ordersStreamLimit)
      .map((data) => data
          .where((map) =>
              map['status'] == 'picked_up' ||
              map['status'] == 'confirmed' ||
              map['status'] == 'ready')
          .toList())
      .asyncMap(_hydrateOrders)
      .map((orders) => orders.isEmpty ? null : orders.first);
}

@riverpod
Future<List<OrderModel>> riderOrdersToday(Ref ref, String riderId) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final rows = await supabase
      .from('orders')
      .select()
      .eq('rider_id', riderId)
      .gte('created_at', startOfDay.toIso8601String())
      .order('created_at', ascending: false)
      .limit(_ordersStreamLimit);
  return _hydrateOrders(List<Map<String, dynamic>>.from(rows));
}

// Customer orders – real‑time stream
@riverpod
Stream<List<OrderModel>> customerOrdersStream(Ref ref, String customerId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .limit(_ordersStreamLimit)
      .asyncMap(_hydrateOrders);
}

// Single order – real‑time stream (nullable)
@riverpod
Stream<OrderModel?> orderStream(Ref ref, String orderId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .asyncMap(_hydrateOrders)
      .map((orders) => orders.isEmpty ? null : orders.first);
}

// Checks if the current user has already rated a specific order
@Riverpod(keepAlive: true)
Future<bool> orderRating(Ref ref, String orderId) async {
  final data = await supabase
      .from('ratings')
      .select('id')
      .eq('order_id', orderId)
      .maybeSingle();
  return data != null;
}

@Riverpod(keepAlive: true)
class PlaceOrder extends _$PlaceOrder {
  @override
  AsyncValue<List<OrderModel>?> build() => const AsyncValue.data(null);

  Future<List<OrderModel>?> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => ref.read(orderRepositoryProvider).placeOrder(
              cart: cart,
              customerId: customerId,
              deliveryAddress: deliveryAddress,
              notes: notes,
            ));
    state = result;
    return result.valueOrNull;
  }
}

// Update order status notifier
@Riverpod(keepAlive: true)
class OrderStatusNotifier extends _$OrderStatusNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    state = const AsyncValue.loading();
    try {
      // Without .select(), a 0-row update (e.g.
      final updated = await supabase
          .from('orders')
          .update({'status': _statusToString(newStatus)})
          .eq('id', orderId)
          .select('id');
      if (updated.isEmpty) {
        throw Exception(
            'Order not found or you don\'t have permission to update it.');
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> assignRider(String orderId, String riderId) async {
    state = const AsyncValue.loading();
    try {
      final updated = await supabase
          .from('orders')
          .update({
            'rider_id': riderId,
            'status': 'picked_up',
          })
          .eq('id', orderId)
          .isFilter('rider_id', null)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('This order was already taken by another rider.');
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  String _statusToString(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}
