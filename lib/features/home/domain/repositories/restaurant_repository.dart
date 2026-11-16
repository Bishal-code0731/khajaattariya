import '../models/category_model.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_model.dart';

abstract class RestaurantRepository {
  /// Paginated — [page] is 0-indexed.
  Future<List<RestaurantModel>> getRestaurants(
      {int page = 0, int pageSize = 20});
  Future<List<RestaurantModel>> getFeaturedRestaurants();
  Future<List<FoodItemModel>> getMenuItems(String restaurantId);
  Future<List<FoodItemModel>> getPopularItems();
  Future<List<FoodItemModel>> getFoodsByCategory(String categoryId);
  Future<List<CategoryModel>> getCategories();
}
