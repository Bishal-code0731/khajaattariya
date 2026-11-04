import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/cart_item_model.dart';
import '../domain/models/cart_state.dart';
import '../../home/domain/models/food_item_model.dart';

part 'cart_notifier.g.dart';

@Riverpod(keepAlive: true)
class CartNotifier extends _$CartNotifier {
  @override
  CartState build() => const CartState();

  void addItem(FoodItemModel food) {
    final groups = [...state.groups];
    final groupIndex =
        groups.indexWhere((g) => g.restaurantId == food.restaurantId);

    if (groupIndex == -1) {
      groups.add(CartRestaurantGroup(
        restaurantId: food.restaurantId,
        restaurantName: food.restaurantName,
        items: [CartItem(food: food, quantity: 1)],
      ));
    } else {
      final group = groups[groupIndex];
      final itemIndex = group.items.indexWhere((i) => i.food.id == food.id);
      final updatedItems = [...group.items];
      if (itemIndex >= 0) {
        updatedItems[itemIndex] = updatedItems[itemIndex]
            .copyWith(quantity: updatedItems[itemIndex].quantity + 1);
      } else {
        updatedItems.add(CartItem(food: food, quantity: 1));
      }
      groups[groupIndex] = group.copyWith(items: updatedItems);
    }

    state = state.copyWith(groups: groups);
  }

  void incrementQuantity(String restaurantId, String foodId) {
    _updateGroup(restaurantId, (items) {
      return items.map((i) {
        if (i.food.id == foodId) return i.copyWith(quantity: i.quantity + 1);
        return i;
      }).toList();
    });
  }

  void decrementQuantity(String restaurantId, String foodId) {
    _updateGroup(restaurantId, (items) {
      return items
          .map((i) {
            if (i.food.id == foodId) {
              return i.copyWith(quantity: i.quantity - 1);
            }
            return i;
          })
          .where((i) => i.quantity > 0)
          .toList();
    });
  }

  void removeItem(String restaurantId, String foodId) {
    _updateGroup(restaurantId,
        (items) => items.where((i) => i.food.id != foodId).toList());
  }

  /// Removes just one restaurant's items, leaving the others untouched.
  void clearRestaurant(String restaurantId) {
    final groups =
        state.groups.where((g) => g.restaurantId != restaurantId).toList();
    state = state.copyWith(groups: groups);
  }

  void clearCart() => state = const CartState();

  void _updateGroup(
      String restaurantId, List<CartItem> Function(List<CartItem>) update) {
    final groups = [...state.groups];
    final groupIndex = groups.indexWhere((g) => g.restaurantId == restaurantId);
    if (groupIndex == -1) return;

    final updatedItems = update(groups[groupIndex].items);
    if (updatedItems.isEmpty) {
      groups.removeAt(groupIndex);
    } else {
      groups[groupIndex] = groups[groupIndex].copyWith(items: updatedItems);
    }
    state = state.copyWith(groups: groups);
  }
}
