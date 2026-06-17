import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/models/favorite_model.dart';

final favoritesProvider =
StreamProvider.family<List<FavoriteModel>, String>((ref, userId) {
  return supabase
      .from('favorites')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .asyncMap((data) async {
    final List<FavoriteModel> favorites = [];
    for (final map in data) {
      final restaurant = await supabase
          .from('restaurants')
          .select('name, image_url, cuisine_type, rating')
          .eq('id', map['restaurant_id'] as String)
          .maybeSingle();
      favorites.add(FavoriteModel.fromMap({
        ...map,
        'restaurants': restaurant ?? {},
      }));
    }
    return favorites;
  });
});

// Whether a specific restaurant is favorited
final isFavoriteProvider =
FutureProvider.family<bool, ({String userId, String restaurantId})>(
        (ref, args) async {
      final data = await supabase
          .from('favorites')
          .select('id')
          .eq('user_id', args.userId)
          .eq('restaurant_id', args.restaurantId)
          .maybeSingle();
      return data != null;
    });

final favoriteToggleProvider =
StateNotifierProvider<FavoriteToggleNotifier, AsyncValue<void>>(
        (ref) => FavoriteToggleNotifier(ref));

class FavoriteToggleNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  FavoriteToggleNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> toggle({
    required String userId,
    required String restaurantId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final existing = await supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('favorites')
            .delete()
            .eq('id', existing['id'] as String);
      } else {
        await supabase.from('favorites').insert({
          'user_id': userId,
          'restaurant_id': restaurantId,
        });
      }

      _ref.invalidate(isFavoriteProvider(
          (userId: userId, restaurantId: restaurantId)));
      _ref.invalidate(favoritesProvider(userId));
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}