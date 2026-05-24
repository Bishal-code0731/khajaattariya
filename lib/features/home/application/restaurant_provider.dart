import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/restaurant_repository_impl.dart';
import '../domain/models/category_model.dart';
import '../domain/models/food_item_model.dart';
import '../domain/models/restaurant_model.dart';
import '../domain/repositories/restaurant_repository.dart';
import '../../../main.dart';

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepositoryImpl();
});

// All restaurants — used in home screen
final restaurantsProvider = FutureProvider<List<RestaurantModel>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getRestaurants();
});

// Popular items — used in home screen
final popularItemsProvider = FutureProvider<List<FoodItemModel>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getPopularItems();
});

// Categories — used in home screen category section
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(restaurantRepositoryProvider).getCategories();
});

// Menu items per restaurant — used in restaurant detail screen
// Takes restaurantId as a parameter
final menuItemsProvider =
FutureProvider.family<List<FoodItemModel>, String>((ref, restaurantId) {
  return ref.watch(restaurantRepositoryProvider).getMenuItems(restaurantId);
});

final restaurantByIdProvider =
FutureProvider.family<RestaurantModel?, String>((ref, id) async {
  final data = await supabase
      .from('restaurants')
      .select()
      .eq('id', id)
      .maybeSingle();
  if (data == null) return null;
  return RestaurantModel.fromMap(data);
});