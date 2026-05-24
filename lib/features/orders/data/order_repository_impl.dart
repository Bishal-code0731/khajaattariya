import '../../../main.dart';
import '../../cart/domain/models/cart_state.dart';
import '../domain/models/order_model.dart';
import '../domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<OrderModel> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  }) async {
    const deliveryFee = 30.0;
    final totalAmount = cart.totalAmount + deliveryFee;

    // Insert order
    final orderData = await supabase
        .from('orders')
        .insert({
      'customer_id': customerId,
      'restaurant_id': cart.restaurantId,
      'total_amount': totalAmount,
      'delivery_fee': deliveryFee,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'status': 'pending',
    })
        .select()
        .single();

    final orderId = orderData['id'] as String;

    // Insert order items
    final orderItems = cart.items.map((cartItem) => {
      'order_id': orderId,
      'menu_item_id': cartItem.food.id,
      'name': cartItem.food.name,
      'price': cartItem.food.price,
      'quantity': cartItem.quantity,
      'subtotal': cartItem.totalPrice,
    }).toList();

    await supabase.from('order_items').insert(orderItems);

    // Return full order
    return getOrderById(orderId);
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