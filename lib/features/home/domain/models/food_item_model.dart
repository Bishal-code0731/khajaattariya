class FoodItemModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String restaurantName;
  final String restaurantId;
  final String? categoryId;
  final double rating;
  final int deliveryTimeMin;
  final bool isVeg;
  final String? offer;

  const FoodItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.restaurantName,
    required this.restaurantId,
    this.categoryId,
    required this.rating,
    required this.deliveryTimeMin,
    required this.isVeg,
    this.offer,
  });

  factory FoodItemModel.fromMap(Map<String, dynamic> map) {
    // restaurant data is joined as a nested map
    final restaurant = map['restaurants'] as Map<String, dynamic>? ?? {};
    return FoodItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String? ?? '',
      price: (map['price'] as num).toDouble(),
      restaurantName: restaurant['name'] as String? ?? '',
      restaurantId: map['restaurant_id'] as String,
      categoryId: map['category_id'] as String?,
      rating: (restaurant['rating'] as num?)?.toDouble() ?? 0.0,
      deliveryTimeMin: restaurant['delivery_time_min'] as int? ?? 30,
      isVeg: map['is_veg'] as bool? ?? false,
      offer: map['offer'] as String?,
    );
  }
}