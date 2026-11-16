class RatingModel {
  final String id;
  final String orderId;
  final String customerId;
  final String restaurantId;
  final int rating;
  final String? review;
  final String? customerName;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    required this.rating,
    this.review,
    this.customerName,
    required this.createdAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    final customer = map['profiles'] as Map<String, dynamic>?;
    return RatingModel(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      customerId: map['customer_id'] as String,
      restaurantId: map['restaurant_id'] as String,
      rating: map['rating'] as int,
      review: map['review'] as String?,
      customerName: customer?['full_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
