import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/retry_queue.dart';
import '../../../main.dart';
import '../domain/models/favorite_model.dart';

part 'favorites_provider.g.dart';

const favoriteToggleRequestType = 'favorite_toggle';

Future<void> performFavoriteToggle(Map<String, dynamic> payload) async {
  final userId = payload['userId'] as String;
  final restaurantId = payload['restaurantId'] as String;

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
}

@riverpod
Stream<List<FavoriteModel>> favorites(Ref ref, String userId) {
  return supabase
      .from('favorites')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .asyncMap((data) async {
        if (data.isEmpty) return const <FavoriteModel>[];

        final restaurantIds =
            data.map((m) => m['restaurant_id'] as String).toSet().toList();
        final restaurantRows = await supabase
            .from('restaurants')
            .select(
                'id, name, image_url, cuisine_type, rating, delivery_time_min')
            .inFilter('id', restaurantIds);
        final restaurantById = {
          for (final r in restaurantRows) r['id'] as String: r,
        };

        return data
            .map((map) => FavoriteModel.fromMap({
                  ...map,
                  'restaurants': restaurantById[map['restaurant_id']] ?? {},
                }))
            .toList();
      });
}

// Whether a specific restaurant is favorited
@riverpod
Future<bool> isFavorite(
    Ref ref, ({String userId, String restaurantId}) args) async {
  final data = await supabase
      .from('favorites')
      .select('id')
      .eq('user_id', args.userId)
      .eq('restaurant_id', args.restaurantId)
      .maybeSingle();
  return data != null;
}

@riverpod
class FavoriteToggle extends _$FavoriteToggle {
  @override
  AsyncValue<void> build(String restaurantId) => const AsyncValue.data(null);

  Future<void> toggle({
    required String userId,
    required String restaurantId,
  }) async {
    if (state.isLoading) return;

    final payload = {'userId': userId, 'restaurantId': restaurantId};

    if (!await checkIsOnline()) {
      await RetryQueue.instance.enqueue(favoriteToggleRequestType, payload);
      state = AsyncValue.error(
        Exception("You're offline — this will sync once you're back online."),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      await performFavoriteToggle(payload);
      ref.invalidate(
          isFavoriteProvider((userId: userId, restaurantId: restaurantId)));
      ref.invalidate(favoritesProvider(userId));
      state = const AsyncValue.data(null);
    } catch (e) {
      // The connectivity check passed but the request still failed (e.g.
      await RetryQueue.instance.enqueue(favoriteToggleRequestType, payload);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
