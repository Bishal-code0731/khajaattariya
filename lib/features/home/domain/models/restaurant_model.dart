// A Restaurant is one food place listed on the home screen.
// Contains everything needed to show the restaurant card.

class RestaurantModel {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisineType;    // "Nepali, Chinese"
  final double rating;         // 4.5
  final int reviewCount;       // 120 reviews
  final int deliveryTimeMin;   // 20 minutes
  final double deliveryFee;    // Rs. 30
  final bool isOpen;           // is the restaurant open right now
  final bool isFeatured;       // show featured badge
  final String? offer;         // "20% off" — null if no offer

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
}