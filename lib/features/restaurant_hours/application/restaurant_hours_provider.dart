import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../domain/models/restaurant_hours_model.dart';

part 'restaurant_hours_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<RestaurantHoursModel>> restaurantHours(Ref ref, String restaurantId) async {
  final data = await supabase
      .from('restaurant_hours')
      .select()
      .eq('restaurant_id', restaurantId)
      .order('weekday');
  return (data as List)
      .map((m) => RestaurantHoursModel.fromMap(m))
      .toList();
}

@Riverpod(keepAlive: true)
class RestaurantHoursNotifier extends _$RestaurantHoursNotifier {
  @override
  AsyncValue<void> build(String restaurantId) => const AsyncValue.data(null);

  /// Upsert all 7 days in a single call — batching (instead of one
  /// upsert per day in a loop) means a mid-save failure can't leave some
  /// days updated and others not, silently reporting overall failure
  /// while the DB is already in a mixed state.
  Future<bool> saveHours(
      List<RestaurantHoursModel> hours) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('restaurant_hours').upsert(
        [
          for (final h in hours)
            {
              'id': h.id.isEmpty ? null : h.id,
              'restaurant_id': restaurantId,
              'weekday': h.weekday,
              'is_open': h.isOpen,
              'open_time': h.isOpen ? h.openTime : null,
              'close_time': h.isOpen ? h.closeTime : null,
            },
        ],
        onConflict: 'restaurant_id,weekday',
      );
      ref.invalidate(restaurantHoursProvider(restaurantId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

/// Initializes 7 default rows if none exist
Future<void> initRestaurantHours(String restaurantId) async {
  final existing = await supabase
      .from('restaurant_hours')
      .select('id')
      .eq('restaurant_id', restaurantId);
  if ((existing as List).isNotEmpty) return;

  final rows = List.generate(
    7,
        (i) => {
      'restaurant_id': restaurantId,
      'weekday': i + 1,
      'is_open': true,
      'open_time': '09:00',
      'close_time': '22:00',
    },
  );
  await supabase.from('restaurant_hours').insert(rows);
}
