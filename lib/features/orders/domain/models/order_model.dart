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

  /// The value stored in the database (`picked_up`, not `pickedUp`).
  String get dbValue => switch (this) {
        OrderStatus.pickedUp => 'picked_up',
        _ => name,
      };

  /// Legacy English label.
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;
}

enum OrderPaymentMethod {
  cash,
  khalti,
  esewa;

  static OrderPaymentMethod fromString(String? value) =>
      OrderPaymentMethod.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OrderPaymentMethod.cash,
      );
}

/// `orders.payment_status` — only the server changes it.
enum OrderPaymentStatus {
  pending,
  paid,
  failed,
  refunded;

  static OrderPaymentStatus fromString(String? value) =>
      OrderPaymentStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OrderPaymentStatus.pending,
      );
}

double _num(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? fallback);

double? _numOrNull(Object? v) => v is num ? v.toDouble() : null;

class OrderModel {
  final String id;
  final String customerId;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImageUrl;
  final String? restaurantPhone;
  final double? restaurantLat;
  final double? restaurantLng;
  final String? riderId;
  final OrderStatus status;

  /// Food total before fees and discounts (server-computed).
  final double subtotal;
  final double totalAmount;
  final double deliveryFee;
  final double discountAmount;
  final OrderPaymentMethod paymentMethod;
  final OrderPaymentStatus paymentStatus;
  final String? deliveryAddress;
  final String? notes;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImageUrl,
    this.restaurantPhone,
    this.restaurantLat,
    this.restaurantLng,
    this.riderId,
    required this.status,
    this.subtotal = 0,
    required this.totalAmount,
    required this.deliveryFee,
    this.discountAmount = 0,
    this.paymentMethod = OrderPaymentMethod.cash,
    this.paymentStatus = OrderPaymentStatus.pending,
    this.deliveryAddress,
    this.notes,
    this.cancelReason,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  /// Total quantity of all items (2× momo + 1× tea = 3).
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  bool get isPaid => paymentStatus == OrderPaymentStatus.paid;

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final restaurantMap = map['restaurants'] as Map<String, dynamic>? ?? {};
    final rawItems = map['order_items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((i) => OrderItemModel.fromMap(i as Map<String, dynamic>))
        .toList();
    final total = _num(map['total_amount']);
    final fee = _num(map['delivery_fee']);
    final discount = _num(map['discount_amount']);
    // Older rows (before the `subtotal` column existed) fall back to the sum of their item subtotals.
    final subtotal = map['subtotal'] is num
        ? _num(map['subtotal'])
        : items.fold<double>(0, (s, i) => s + i.subtotal);

    return OrderModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      restaurantId: map['restaurant_id'] as String,
      restaurantName: restaurantMap['name'] as String? ?? '',
      restaurantImageUrl: restaurantMap['image_url'] as String?,
      restaurantPhone: restaurantMap['phone'] as String?,
      restaurantLat: _numOrNull(restaurantMap['latitude']),
      restaurantLng: _numOrNull(restaurantMap['longitude']),
      riderId: map['rider_id'] as String?,
      status: OrderStatus.fromString(map['status'] as String? ?? 'pending'),
      subtotal: subtotal,
      totalAmount: total,
      deliveryFee: fee,
      discountAmount: discount,
      paymentMethod:
          OrderPaymentMethod.fromString(map['payment_method'] as String?),
      paymentStatus:
          OrderPaymentStatus.fromString(map['payment_status'] as String?),
      deliveryAddress: map['delivery_address'] as String?,
      notes: map['notes'] as String?,
      cancelReason: map['cancel_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'] as String),
      items: items,
    );
  }
}
