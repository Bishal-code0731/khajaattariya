import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/image_upload.dart';
import '../../../main.dart';

part 'profile_provider.g.dart';

/// Saves the signed-in user's own name, phone and avatar.
@Riverpod(keepAlive: true)
class ProfileUpdate extends _$ProfileUpdate {
  static const _tag = 'profile';

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = await supabase
          .from('profiles')
          .update({
            'full_name': fullName,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select('id');
      if (updated.isEmpty) {
        throw StateError('profile row not updated');
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      AppLogger.warning(_tag, 'updateProfile failed: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String?> pickAndUploadAvatar(String userId) async {
    state = const AsyncValue.loading();
    try {
      final url = await ImageUpload.pickCompressAndUpload(
        supabase: supabase,
        bucket: 'avatars',
        path: '$userId/avatar.jpg',
        maxDimension: 512,
      );
      if (url == null) {
        state = const AsyncValue.data(null);
        return null;
      }
      final versioned = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      final updated = await supabase
          .from('profiles')
          .update({'avatar_url': versioned})
          .eq('id', userId)
          .select('id');
      if (updated.isEmpty) {
        throw StateError('avatar_url not updated');
      }
      state = const AsyncValue.data(null);
      return versioned;
    } catch (e, st) {
      AppLogger.warning(_tag, 'avatar upload failed: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
