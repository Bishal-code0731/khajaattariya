import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/app_logger.dart';
import '../../../main.dart';
import '../domain/models/address_model.dart';

part 'address_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<AddressModel>> addressList(Ref ref, String userId) {
  return supabase
      .from('addresses')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('is_default', ascending: false)
      .map((data) => data.map((m) => AddressModel.fromMap(m)).toList());
}

/// Address mutations.
@Riverpod(keepAlive: true)
class AddressNotifier extends _$AddressNotifier {
  static const _tag = 'address';

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addAddress({
    required String userId,
    required String label,
    required String fullAddress,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) =>
      _guard('addAddress', () async {
        final inserted = await supabase
            .from('addresses')
            .insert({
              'user_id': userId,
              'label': label,
              'full_address': fullAddress,
              'landmark': landmark,
              'latitude': latitude,
              'longitude': longitude,
              'is_default': isDefault,
            })
            .select('id')
            .single();
        if (isDefault) {
          await _unsetOtherDefaults(userId, inserted['id'] as String);
        }
      });

  Future<void> updateAddress({
    required String addressId,
    required String userId,
    required String label,
    required String fullAddress,
    String? landmark,
    bool isDefault = false,
  }) =>
      _guard('updateAddress', () async {
        final updated = await supabase
            .from('addresses')
            .update({
              'label': label,
              'full_address': fullAddress,
              'landmark': landmark,
              'is_default': isDefault,
            })
            .eq('id', addressId)
            .select('id');
        if (updated.isEmpty) {
          throw StateError('address not updated (missing or not owned)');
        }
        if (isDefault) await _unsetOtherDefaults(userId, addressId);
      });

  Future<void> setDefault({
    required String addressId,
    required String userId,
  }) =>
      _guard('setDefault', () async {
        final updated = await supabase
            .from('addresses')
            .update({'is_default': true})
            .eq('id', addressId)
            .select('id');
        if (updated.isEmpty) {
          throw StateError('address not updated (missing or not owned)');
        }
        await _unsetOtherDefaults(userId, addressId);
      });

  Future<void> deleteAddress(String addressId, String userId) =>
      _guard('deleteAddress', () async {
        final deleted = await supabase
            .from('addresses')
            .delete()
            .eq('id', addressId)
            .select('is_default');
        if (deleted.isEmpty) {
          throw StateError('address not deleted (missing or not owned)');
        }
        final wasDefault = deleted.first['is_default'] as bool? ?? false;
        if (wasDefault) {
          final remaining = await supabase
              .from('addresses')
              .select('id')
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(1);
          if (remaining.isNotEmpty) {
            await supabase.from('addresses').update({'is_default': true}).eq(
                'id', remaining.first['id'] as String);
          }
        }
      });

  Future<void> _unsetOtherDefaults(String userId, String keepId) async {
    await supabase
        .from('addresses')
        .update({'is_default': false})
        .eq('user_id', userId)
        .neq('id', keepId);
  }

  Future<void> _guard(String action, Future<void> Function() body) async {
    state = const AsyncValue.loading();
    try {
      await body();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.warning(_tag, '$action failed: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
