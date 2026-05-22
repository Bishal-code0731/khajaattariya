import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository_impl.dart';
import '../domain/models/user_model.dart';
import '../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// The repository provider — creates one instance used everywhere
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl();
}

// Watches auth state — automatically updates when user logs in/out
// Every widget that needs to know if user is logged in watches this
@riverpod
Stream<UserModel?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// The main auth notifier — handles all auth actions
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<UserModel?> build() {
    return const AsyncValue.loading();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(authRepositoryProvider).signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          role: role,
        ));
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(authRepositoryProvider).signIn(
          email: email,
          password: password,
        ));
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> sendPasswordReset(String email) async {
    await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
  }
}