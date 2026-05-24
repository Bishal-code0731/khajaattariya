import 'order_item_model.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  pickedUp,
  delivered,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
          (e) => e.name == _toCamelCase(value),
      orElse: () => OrderStatus.pending,
    );
  }

  static String _toCamelCase(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:    return 'Pending';
      case OrderStatus.confirmed:  return 'Confirmed';
      case OrderStatus.preparing:  return 'Preparing';
      case OrderStatus.ready:      return 'Ready for Pickup';
      case OrderStatus.pickedUp:   return 'On the Way';
      case OrderStatus.delivered:  return 'Delivered';
      case OrderStatus.cancelled:  return 'Cancelled';
    }
  }

  // Color code handled in UI layer via AppColors
  bool get isActive => this != OrderStatus.delivered &&
      this != OrderStatus.cancelled;
}

class OrderModel {
  final String id;
  final String customerId;
  final String restaurantId;
  final String restaurantName;
  final String? riderId;
  final OrderStatus status;
  final double totalAmount;
  final double deliveryFee;
  final String? deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.restaurantName,
    this.riderId,
    required this.status,
    required this.totalAmount,
    required this.deliveryFee,
    this.deliveryAddress,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final restaurantMap = map['restaurants'] as Map<String, dynamic>? ?? {};
    final rawItems = map['order_items'] as List<dynamic>? ?? [];

    return OrderModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      restaurantId: map['restaurant_id'] as String,
      restaurantName: restaurantMap['name'] as String? ?? '',
      riderId: map['rider_id'] as String?,
      status: OrderStatus.fromString(map['status'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      deliveryFee: (map['delivery_fee'] as num).toDouble(),
      deliveryAddress: map['delivery_address'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: rawItems
          .map((i) => OrderItemModel.fromMap(i as Map<String, dynamic>))
          .toList(),
    );
  }
}