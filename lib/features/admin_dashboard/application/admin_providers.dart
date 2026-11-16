import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
class RestaurantApprovalNotifier extends _$RestaurantApprovalNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> approve(String restaurantId) async {
    state = const AsyncValue.loading();
    try {
      final updated = await supabase
          .from('restaurants')
          .update(
              {'is_approved': true, 'is_active': true, 'approval_note': null})
          .eq('id', restaurantId)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('Could not approve restaurant. Please try again.');
      }
      await supabase.from('audit_logs').insert({
        'actor_id': supabase.auth.currentUser?.id,
        'action': 'approve_restaurant',
        'target_table': 'restaurants',
        'target_id': restaurantId,
        'new_data': {'is_approved': true},
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reject(String restaurantId, String note) async {
    state = const AsyncValue.loading();
    try {
      final updated = await supabase
          .from('restaurants')
          .update(
              {'is_approved': false, 'is_active': false, 'approval_note': note})
          .eq('id', restaurantId)
          .select('id');
      if (updated.isEmpty) {
        throw Exception('Could not reject restaurant. Please try again.');
      }
      await supabase.from('audit_logs').insert({
        'actor_id': supabase.auth.currentUser?.id,
        'action': 'reject_restaurant',
        'target_table': 'restaurants',
        'target_id': restaurantId,
        'new_data': {'is_approved': false, 'note': note},
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> pendingRestaurants(Ref ref) async {
  final data = await supabase
      .from('restaurants')
      .select('*, profiles!owner_id(full_name, phone)')
      .eq('is_approved', false)
      .order('created_at', ascending: true);
  return List<Map<String, dynamic>>.from(data);
}

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> auditLogs(Ref ref) async {
  final data = await supabase
      .from('audit_logs')
      .select('*, profiles!actor_id(full_name)')
      .order('created_at', ascending: false)
      .limit(100);
  return List<Map<String, dynamic>>.from(data);
}

@Riverpod(keepAlive: true)
class PlatformSettingsNotifier extends _$PlatformSettingsNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> updateSetting(String key, String value) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('platform_settings').upsert({
        'key': key,
        'value': value,
        'updated_by': supabase.auth.currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await supabase.from('audit_logs').insert({
        'actor_id': supabase.auth.currentUser?.id,
        'action': 'update_setting',
        'target_table': 'platform_settings',
        'target_id': key,
        'new_data': {'value': value},
      });
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
