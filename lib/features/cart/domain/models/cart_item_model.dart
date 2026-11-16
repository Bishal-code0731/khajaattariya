import '../../../home/domain/models/food_item_model.dart';

class CartItem {
  final FoodItemModel food;
  final int quantity;

  const CartItem({required this.food, required this.quantity});

  double get totalPrice => food.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(food: food, quantity: quantity ?? this.quantity);
  }
}
