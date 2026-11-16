import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/supabase/auth_repository_impl.dart';
import '../domain/models/user_model.dart';
import '../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl();
}

@riverpod
Stream<UserModel?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<UserModel?> build() {
    ref.listen(authStateProvider, (_, next) {
      next.whenData((user) => state = AsyncValue.data(user));
    });
    return const AsyncValue.loading();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? termsVersion,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            role: role,
            termsVersion: termsVersion,
          ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // Without this, a transient failure here (e.g.
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendPasswordReset(String email, {String? redirectTo}) async {
    await ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email, redirectTo: redirectTo);
  }

  Future<UserModel?> updatePassword(String newPassword) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.updatePassword(newPassword);
    try {
      return await repo.getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  /// Verifies the emailed 6-digit code; on success the user is signed in.
  Future<UserModel> verifyEmailOtp(
      {required String email, required String code}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .verifyEmailOtp(email: email, code: code);
    state = AsyncValue.data(user);
    return user;
  }

  Future<void> resendEmailOtp(String email) =>
      ref.read(authRepositoryProvider).resendEmailOtp(email);
}
