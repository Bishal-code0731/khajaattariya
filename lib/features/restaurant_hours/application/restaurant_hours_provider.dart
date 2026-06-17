import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../domain/models/restaurant_hours_model.dart';

final restaurantHoursProvider =
FutureProvider.family<List<RestaurantHoursModel>, String>(
        (ref, restaurantId) async {
      final data = await supabase
          .from('restaurant_hours')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('weekday');
      return (data as List)
          .map((m) => RestaurantHoursModel.fromMap(m))
          .toList();
    });

final restaurantHoursNotifierProvider = StateNotifierProvider
    .family<RestaurantHoursNotifier, AsyncValue<void>, String>(
        (ref, restaurantId) =>
        RestaurantHoursNotifier(restaurantId, ref));

class RestaurantHoursNotifier extends StateNotifier<AsyncValue<void>> {
  final String restaurantId;
  final Ref _ref;

  RestaurantHoursNotifier(this.restaurantId, this._ref)
      : super(const AsyncValue.data(null));

  /// Upsert all 7 days at once
  Future<bool> saveHours(
      List<RestaurantHoursModel> hours) async {
    state = const AsyncValue.loading();
    try {
      for (final h in hours) {
        await supabase.from('restaurant_hours').upsert(
          {
            'id': h.id.isEmpty ? null : h.id,
            'restaurant_id': restaurantId,
            'weekday': h.weekday,
            'is_open': h.isOpen,
            'open_time': h.isOpen ? h.openTime : null,
            'close_time': h.isOpen ? h.closeTime : null,
          },
          onConflict: 'restaurant_id,weekday',
        );
      }
      _ref.invalidate(restaurantHoursProvider(restaurantId));
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