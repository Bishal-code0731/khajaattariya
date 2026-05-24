import 'cart_item_model.dart';

class CartState {
  final List<CartItem> items;
  final String? restaurantId;
  final String? restaurantName;

  const CartState({
    this.items = const [],
    this.restaurantId,
    this.restaurantName,
  });

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);
  double get totalAmount => items.fold(0, (sum, i) => sum + i.totalPrice);

  CartState copyWith({
    List<CartItem>? items,
    String? restaurantId,
    String? restaurantName,
  }) {
    return CartState(
      items: items ?? this.items,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  CartState empty() => const CartState();
}