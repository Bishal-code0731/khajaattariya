import '../../../main.dart';
import '../../cart/domain/models/cart_state.dart';
import '../domain/models/order_model.dart';
import '../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<List<OrderModel>> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  }) async {
    const deliveryFee = 30.0;

    // Placed via the place_orders() Postgres function (see
    // supabase_migration_place_orders_rpc.sql) so a multi-restaurant
    // checkout is atomic — a failure partway through used to leave an
    // orphaned order with no items, or skip later restaurant groups
    // while earlier ones were already committed.
    final groupsPayload = cart.groups.map((group) => {
      'restaurant_id': group.restaurantId,
      'items': group.items.map((cartItem) => {
        'menu_item_id': cartItem.food.id,
        'name': cartItem.food.name,
        'price': cartItem.food.price,
        'quantity': cartItem.quantity,
        'subtotal': cartItem.totalPrice,
      }).toList(),
    }).toList();

    final rows = await supabase.rpc('place_orders', params: {
      'p_customer_id': customerId,
      'p_delivery_address': deliveryAddress,
      'p_notes': notes,
      'p_delivery_fee': deliveryFee,
      'p_groups': groupsPayload,
    }) as List;

    final orderIds = rows.map((r) => (r as Map<String, dynamic>)['id'] as String);
    final orders = <OrderModel>[];
    for (final orderId in orderIds) {
      orders.add(await getOrderById(orderId));
    }
    return orders;
  }

  @override
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final data = await supabase
        .from('orders')
        .select('*, restaurants(name), order_items(*)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((map) => OrderModel.fromMap(map))
        .toList();
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    final data = await supabase
        .from('orders')
        .select('*, restaurants(name), order_items(*)')
        .eq('id', orderId)
        .single();

    return OrderModel.fromMap(data);
  }
}