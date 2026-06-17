class FavoriteModel {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImageUrl;
  final String cuisineType;
  final double rating;
  final DateTime createdAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImageUrl,
    required this.cuisineType,
    required this.rating,
    required this.createdAt,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    final r = map['restaurants'] as Map<String, dynamic>? ?? {};
    return FavoriteModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      restaurantId: map['restaurant_id'] as String,
      restaurantName: r['name'] as String? ?? '',
      restaurantImageUrl: r['image_url'] as String? ?? '',
      cuisineType: r['cuisine_type'] as String? ?? '',
      rating: (r['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}