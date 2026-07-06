import '../../../cart/domain/models/cart_state.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  /// Places one order per restaurant group in [cart] — a cart can hold
  /// items from multiple restaurants at once, and each becomes its own
  /// order (orders.restaurant_id is a single value in the schema, so a
  /// combined multi-restaurant order isn't representable as one row).
  Future<List<OrderModel>> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  });

  Future<List<OrderModel>> getCustomerOrders(String customerId);

  Future<OrderModel> getOrderById(String orderId);
}