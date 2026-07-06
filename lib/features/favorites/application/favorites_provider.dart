import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/retry_queue.dart';
import '../../../main.dart';
import '../domain/models/favorite_model.dart';

part 'favorites_provider.g.dart';

const favoriteToggleRequestType = 'favorite_toggle';

/// The actual insert/delete, factored out so both the live toggle path
/// and the retry-queue replay (see [retryQueueFlusherProvider]) share
/// one implementation instead of duplicating the existing-row check.
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
    await supabase.from('favorites').delete().eq('id', existing['id'] as String);
  } else {
    await supabase.from('favorites').insert({
      'user_id': userId,
      'restaurant_id': restaurantId,
    });
  }
}

// autoDispose (the @riverpod default): without it this realtime
// subscription stayed open for the entire app session the moment any
// screen watched it once, even after the user navigated away from
// Favorites — a standing memory/battery/bandwidth cost for a screen
// most sessions only visit briefly (see notificationsProvider below for
// the same fix).
@riverpod
Stream<List<FavoriteModel>> favorites(Ref ref, String userId) {
  return supabase
      .from('favorites')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .asyncMap((data) async {
    if (data.isEmpty) return const <FavoriteModel>[];

    // Single batched lookup instead of one query per favorite row per
    // stream emission (was O(n) round trips on every change).
    final restaurantIds = data.map((m) => m['restaurant_id'] as String).toSet().toList();
    final restaurantRows = await supabase
        .from('restaurants')
        .select('id, name, image_url, cuisine_type, rating')
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
Future<bool> isFavorite(Ref ref, ({String userId, String restaurantId}) args) async {
  final data = await supabase
      .from('favorites')
      .select('id')
      .eq('user_id', args.userId)
      .eq('restaurant_id', args.restaurantId)
      .maybeSingle();
  return data != null;
}

// Keyed per restaurant so toggling one restaurant's favorite heart
// doesn't block toggling a different one while the first is in flight
// (a single shared notifier's isLoading guard used to do exactly that).
@riverpod
class FavoriteToggle extends _$FavoriteToggle {
  @override
  AsyncValue<void> build(String restaurantId) => const AsyncValue.data(null);

  Future<void> toggle({
    required String userId,
    required String restaurantId,
  }) async {
    // Guards against a rapid double-tap firing two overlapping
    // insert/delete calls for the same favorite before the first
    // request's result comes back.
    if (state.isLoading) return;

    final payload = {'userId': userId, 'restaurantId': restaurantId};

    // Known offline up front — don't even attempt the round trip, queue
    // it for replay once connectivity returns (see
    // retryQueueFlusherProvider) and let the UI show a "queued" message
    // instead of a hard error.
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
      ref.invalidate(isFavoriteProvider(
          (userId: userId, restaurantId: restaurantId)));
      ref.invalidate(favoritesProvider(userId));
      state = const AsyncValue.data(null);
    } catch (e) {
      // The connectivity check passed but the request still failed
      // (e.g. connection dropped mid-flight) — queue it too rather than
      // silently losing the user's action.
      await RetryQueue.instance.enqueue(favoriteToggleRequestType, payload);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}