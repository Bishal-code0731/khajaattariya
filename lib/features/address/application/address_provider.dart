import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../main.dart';
import '../domain/models/address_model.dart';

part 'address_provider.g.dart';

// keepAlive: true matches the old StreamProvider.family (not .autoDispose)
// — the address list stream should keep running for the whole session,
// not tear down and re-subscribe every time the address book screen
// briefly unmounts.
@Riverpod(keepAlive: true)
Stream<List<AddressModel>> addressList(Ref ref, String userId) {
  return supabase
      .from('addresses')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('is_default', ascending: false)
      .map((data) =>
      data.map((m) => AddressModel.fromMap(m)).toList());
}

@Riverpod(keepAlive: true)
class AddressNotifier extends _$AddressNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> addAddress({
    required String userId,
    required String label,
    required String fullAddress,
    String? landmark,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Insert the new row first, then unset any other default — that
      // way if the second step fails partway, the user still has one
      // default address (the new one) instead of zero.
      final inserted = await supabase.from('addresses').insert({
        'user_id': userId,
        'label': label,
        'full_address': fullAddress,
        'landmark': landmark,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      }).select('id').single();
      if (isDefault) {
        await supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .neq('id', inserted['id'] as String);
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> updateAddress({
    required String addressId,
    required String userId,
    required String label,
    required String fullAddress,
    String? landmark,
    bool isDefault = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Update this row (including is_default) first, then unset any
      // other default — same ordering rationale as addAddress: a
      // mid-operation failure leaves one default standing, not zero.
      final updated = await supabase.from('addresses').update({
        'label': label,
        'full_address': fullAddress,
        'landmark': landmark,
        'is_default': isDefault,
      }).eq('id', addressId).select('id');
      if (updated.isEmpty) {
        throw Exception('Address not found or you don\'t have permission to update it.');
      }
      if (isDefault) {
        await supabase
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .neq('id', addressId);
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> setDefault({
    required String addressId,
    required String userId,
  }) async {
    try {
      final updated = await supabase
          .from('addresses')
          .update({'is_default': true}).eq('id', addressId).select('id');
      if (updated.isEmpty) return false;
      await supabase
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .neq('id', addressId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId, String userId) async {
    try {
      final deleted = await supabase
          .from('addresses')
          .delete()
          .eq('id', addressId)
          .select('is_default');
      if (deleted.isEmpty) return false;
      final wasDefault = deleted.first['is_default'] as bool? ?? false;
      if (wasDefault) {
        // Promote the most-recently-added remaining address so the user
        // isn't left with zero default addresses.
        final remaining = await supabase
            .from('addresses')
            .select('id')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1);
        if (remaining.isNotEmpty) {
          await supabase
              .from('addresses')
              .update({'is_default': true})
              .eq('id', remaining.first['id'] as String);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}