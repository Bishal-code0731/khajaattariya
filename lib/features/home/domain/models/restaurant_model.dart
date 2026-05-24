class RestaurantModel {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisineType;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMin;
  final double deliveryFee;
  final bool isOpen;
  final bool isFeatured;
  final String? offer;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cuisineType,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTimeMin,
    required this.deliveryFee,
    required this.isOpen,
    this.isFeatured = false,
    this.offer,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) {
    return RestaurantModel(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String? ?? '',
      cuisineType: map['cuisine_type'] as String,
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['review_count'] as int,
      deliveryTimeMin: map['delivery_time_min'] as int,
      deliveryFee: (map['delivery_fee'] as num).toDouble(),
      isOpen: map['is_open'] as bool,
      isFeatured: map['is_featured'] as bool? ?? false,
      offer: map['offer'] as String?,
    );
  }
}