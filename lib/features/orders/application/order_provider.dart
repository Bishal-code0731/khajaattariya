import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../cart/domain/models/cart_state.dart';
import '../data/order_repository_impl.dart';
import '../domain/models/order_model.dart';
import '../domain/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl();
});

// Customer orders list (future – kept for compatibility)
final customerOrdersProvider =
FutureProvider.family<List<OrderModel>, String>((ref, customerId) {
  return ref.watch(orderRepositoryProvider).getCustomerOrders(customerId);
});

// Single order detail (future)
final orderByIdProvider =
FutureProvider.family<OrderModel, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).getOrderById(orderId);
});

// Restaurant incoming orders — stream for real-time updates
final restaurantOrdersProvider =
StreamProvider.family<List<OrderModel>, String>((ref, restaurantId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false)
      .map((data) => data
      .map((map) async {
    final items = await supabase
        .from('order_items')
        .select()
        .eq('order_id', map['id'] as String);
    final restaurant = await supabase
        .from('restaurants')
        .select('name')
        .eq('id', restaurantId)
        .single();
    return OrderModel.fromMap({
      ...map,
      'restaurants': restaurant,
      'order_items': items,
    });
  })
      .toList())
      .asyncMap((futures) async => await Future.wait(futures));
});

// Available orders for rider (status = ready, no rider assigned)
final availableOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('status', 'ready')
      .order('created_at', ascending: false)
      .map((data) => data
      .where((map) => map['rider_id'] == null)
      .map((map) async {
    final items = await supabase
        .from('order_items')
        .select()
        .eq('order_id', map['id'] as String);
    final restaurant = await supabase
        .from('restaurants')
        .select('name')
        .eq('id', map['restaurant_id'] as String)
        .single();
    return OrderModel.fromMap({
      ...map,
      'restaurants': restaurant,
      'order_items': items,
    });
  })
      .toList())
      .asyncMap((futures) async => await Future.wait(futures));
});

// Rider's active delivery
final riderActiveOrderProvider =
StreamProvider.family<OrderModel?, String>((ref, riderId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('rider_id', riderId)
      .order('created_at', ascending: false)
      .map((data) => data
      .where((map) =>
  map['status'] == 'picked_up' ||
      map['status'] == 'confirmed' ||
      map['status'] == 'ready')
      .map((map) async {
    final items = await supabase
        .from('order_items')
        .select()
        .eq('order_id', map['id'] as String);
    final restaurant = await supabase
        .from('restaurants')
        .select('name')
        .eq('id', map['restaurant_id'] as String)
        .single();
    return OrderModel.fromMap({
      ...map,
      'restaurants': restaurant,
      'order_items': items,
    });
  })
      .toList())
      .asyncMap((futures) async {
    final results = await Future.wait(futures);
    return results.isEmpty ? null : results.first;
  });
});

// Customer orders – real‑time stream
final customerOrdersStreamProvider =
StreamProvider.family<List<OrderModel>, String>((ref, customerId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)
      .order('created_at', ascending: false)
      .map((data) => data
      .map((map) async {
    final items = await supabase
        .from('order_items')
        .select()
        .eq('order_id', map['id'] as String);
    final restaurant = await supabase
        .from('restaurants')
        .select('name')
        .eq('id', map['restaurant_id'] as String)
        .single();
    return OrderModel.fromMap({
      ...map,
      'restaurants': restaurant,
      'order_items': items,
    });
  })
      .toList())
      .asyncMap((futures) async => await Future.wait(futures));
});

// Single order – real‑time stream (nullable)
final orderStreamProvider =
StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .map((data) => data
      .map((map) async {
    final items = await supabase
        .from('order_items')
        .select()
        .eq('order_id', map['id'] as String);
    final restaurant = await supabase
        .from('restaurants')
        .select('name')
        .eq('id', map['restaurant_id'] as String)
        .single();
    return OrderModel.fromMap({
      ...map,
      'restaurants': restaurant,
      'order_items': items,
    });
  })
      .toList())
      .asyncMap((futures) async =>
  futures.isEmpty ? null : (await Future.wait(futures)).first);
});

// Checks if the current user has already rated a specific order
final orderRatingProvider =
FutureProvider.family<bool, String>((ref, orderId) async {
  final data = await supabase
      .from('ratings')
      .select('id')
      .eq('order_id', orderId)
      .maybeSingle();
  return data != null;
});

// Place order notifier
final placeOrderProvider =
StateNotifierProvider<PlaceOrderNotifier, AsyncValue<OrderModel?>>(
      (ref) => PlaceOrderNotifier(ref.watch(orderRepositoryProvider)),
);

class PlaceOrderNotifier extends StateNotifier<AsyncValue<OrderModel?>> {
  final OrderRepository _repository;

  PlaceOrderNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<OrderModel?> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() => _repository.placeOrder(
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
final orderStatusNotifierProvider =
StateNotifierProvider<OrderStatusNotifier, AsyncValue<void>>(
      (ref) => OrderStatusNotifier(),
);

class OrderStatusNotifier extends StateNotifier<AsyncValue<void>> {
  OrderStatusNotifier() : super(const AsyncValue.data(null));

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    state = const AsyncValue.loading();
    try {
      await supabase
          .from('orders')
          .update({'status': _statusToString(newStatus)}).eq('id', orderId);
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
      await supabase.from('orders').update({
        'rider_id': riderId,
        'status': 'picked_up',
      }).eq('id', orderId);
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