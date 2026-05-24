import '../models/order_model.dart';
import '../../../cart/domain/models/cart_state.dart';

abstract class OrderRepository {
  Future<OrderModel> placeOrder({
    required CartState cart,
    required String customerId,
    String? deliveryAddress,
    String? notes,
  });

  Future<List<OrderModel>> getCustomerOrders(String customerId);
  Future<OrderModel> getOrderById(String orderId);
}