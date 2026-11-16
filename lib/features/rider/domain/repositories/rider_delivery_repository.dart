import '../entities/delivery_info.dart';

/// Read-only delivery facts (payment method, pickup address) for orders a rider can see.
abstract class RiderDeliveryRepository {
  /// Keyed by order id.
  Future<Map<String, DeliveryInfo>> fetchDeliveryInfo(List<String> orderIds);
}
