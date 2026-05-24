import '../models/food_item_model.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';

abstract class RestaurantRepository {
  Future<List<RestaurantModel>> getRestaurants();
  Future<List<RestaurantModel>> getFeaturedRestaurants();
  Future<List<FoodItemModel>> getMenuItems(String restaurantId);
  Future<List<FoodItemModel>> getPopularItems();
  Future<List<CategoryModel>> getCategories();
}