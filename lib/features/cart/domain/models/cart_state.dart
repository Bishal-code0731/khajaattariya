import 'cart_item_model.dart';

/// One restaurant's items within the cart.
class CartRestaurantGroup {
  final String restaurantId;
  final String restaurantName;
  final List<CartItem> items;

  const CartRestaurantGroup({
    required this.restaurantId,
    required this.restaurantName,
    this.items = const [],
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  CartRestaurantGroup copyWith({List<CartItem>? items}) {
    return CartRestaurantGroup(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      items: items ?? this.items,
    );
  }
}

class CartState {
  final List<CartRestaurantGroup> groups;

  const CartState({this.groups = const []});

  bool get isEmpty => groups.isEmpty;
  int get totalItems => groups.fold(0, (sum, g) => sum + g.totalItems);
  double get totalAmount => groups.fold(0.0, (sum, g) => sum + g.subtotal);

  /// How many of one dish are in the cart (0 when absent).
  int quantityOf(String restaurantId, String foodId) {
    for (final g in groups) {
      if (g.restaurantId != restaurantId) continue;
      for (final i in g.items) {
        if (i.food.id == foodId) return i.quantity;
      }
    }
    return 0;
  }

  CartState copyWith({List<CartRestaurantGroup>? groups}) {
    return CartState(groups: groups ?? this.groups);
  }
}
