import '../../../main.dart';
import '../../cart/domain/models/cart_state.dart';
import '../domain/models/order_model.dart';
import '../domain/repositories/order_repository.dart';

/// Order columns plus the restaurant and item details the screens show.
const _orderSelect =
    '*, restaurants(id, name, image_url, phone, latitude, longitude), order_items(*)';

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<List<OrderModel>> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  }) async {
    // Placed via the place_orders() Postgres function so a multi-restaurant checkout is atomic.
    final groupsPayload = cart.groups
        .map((group) => {
              'restaurant_id': group.restaurantId,
              'items': group.items
                  .map((cartItem) => {
                        'menu_item_id': cartItem.food.id,
                        'name': cartItem.food.name,
                        'price': cartItem.food.price,
                        'quantity': cartItem.quantity,
                        'subtotal': cartItem.totalPrice,
                      })
                  .toList(),
            })
        .toList();

    final rows = await supabase.rpc('place_orders', params: {
      'p_customer_id': customerId,
      'p_delivery_address': deliveryAddress,
      'p_notes': notes,
      'p_groups': groupsPayload,
    }) as List;

    final orderIds =
        rows.map((r) => (r as Map<String, dynamic>)['id'] as String).toList();
    final orders = await getOrdersByIds(orderIds);
    return orders;
  }

  @override
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final data = await supabase
        .from('orders')
        .select(_orderSelect)
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((map) => OrderModel.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    final data = await supabase
        .from('orders')
        .select(_orderSelect)
        .eq('id', orderId)
        .single();

    return OrderModel.fromMap(data);
  }

  @override
  Future<List<OrderModel>> getOrdersByIds(List<String> orderIds) async {
    if (orderIds.isEmpty) return const [];
    final data = await supabase
        .from('orders')
        .select(_orderSelect)
        .inFilter('id', orderIds)
        .order('created_at', ascending: true);
    return (data as List)
        .map((map) => OrderModel.fromMap(map as Map<String, dynamic>))
        .toList();
  }
}
