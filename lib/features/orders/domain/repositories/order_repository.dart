import '../../../cart/domain/models/cart_state.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  });

  Future<List<OrderModel>> getCustomerOrders(String customerId);

  Future<OrderModel> getOrderById(String orderId);

  /// Orders by id, e.g.
  Future<List<OrderModel>> getOrdersByIds(List<String> orderIds);
}
