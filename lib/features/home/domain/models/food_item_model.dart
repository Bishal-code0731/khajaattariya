// A FoodItem is one dish shown in the Popular Foods section.

class FoodItemModel {
  final String id;
  final String name;
  final String imageUrl;
  final double price;           // Rs. 120
  final String restaurantName;
  final String restaurantId;
  final double rating;
  final int deliveryTimeMin;
  final bool isVeg;             // veg or non-veg indicator
  final String? offer;          // "10% off" — null if no offer

  const FoodItemModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.restaurantName,
    required this.restaurantId,
    required this.rating,
    required this.deliveryTimeMin,
    required this.isVeg,
    this.offer,
  });
}