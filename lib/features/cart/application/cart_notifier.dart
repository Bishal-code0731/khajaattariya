import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/cart_item_model.dart';
import '../domain/models/cart_state.dart';
import '../../home/domain/models/food_item_model.dart';

final cartNotifierProvider =
StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  // Returns true if added, false if restaurant conflict
  bool addItem(FoodItemModel food) {
    // First item — set restaurant context
    if (state.isEmpty) {
      state = CartState(
        restaurantId: food.restaurantId,
        restaurantName: food.restaurantName,
        items: [CartItem(food: food, quantity: 1)],
      );
      return true;
    }

    // Different restaurant — signal conflict to UI
    if (state.restaurantId != food.restaurantId) {
      return false;
    }

    // Same restaurant — increment if exists, else add
    final existingIndex =
    state.items.indexWhere((i) => i.food.id == food.id);

    if (existingIndex >= 0) {
      final updated = [...state.items];
      updated[existingIndex] = updated[existingIndex]
          .copyWith(quantity: updated[existingIndex].quantity + 1);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(food: food, quantity: 1)],
      );
    }
    return true;
  }

  void incrementQuantity(String foodId) {
    final updated = state.items.map((i) {
      if (i.food.id == foodId) return i.copyWith(quantity: i.quantity + 1);
      return i;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void decrementQuantity(String foodId) {
    final updated = state.items
        .map((i) {
      if (i.food.id == foodId) return i.copyWith(quantity: i.quantity - 1);
      return i;
    })
        .where((i) => i.quantity > 0)
        .toList();

    if (updated.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void removeItem(String foodId) {
    final updated = state.items.where((i) => i.food.id != foodId).toList();
    if (updated.isEmpty) {
      state = const CartState();
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void clearCart() => state = const CartState();
}