import '../../../core/cache/local_store.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/retry_queue.dart';
import '../../../core/utils/app_logger.dart';
import '../../../main.dart';
import '../domain/models/user_model.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static String _profileDiskKey(String userId) => 'profile:$userId';
  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': role,
      },
    );

    if (response.user == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    if (response.session == null) {
      throw Exception('Please confirm your email then log in.');
    }

    // The `handle_new_user` DB trigger creates the profiles row
    // asynchronously right after auth.users gets the new user, so a
    // fixed delay here would either be too short under load or waste
    // time when the trigger is instant. Poll briefly instead.
    return _fetchProfileWithRetry(response.user!.id, email);
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid email or password.');
    }

    return _fetchProfile(response.user!.id, email);
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
    // A queued offline write belongs to this account — replaying it
    // after a different user logs in on the same device would apply
    // it under the wrong session.
    await RetryQueue.instance.clear();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id, user.email ?? '');
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return _fetchProfile(user.id, user.email ?? '');
    });
  }

  Future<UserModel> _fetchProfile(String userId, String email) async {
    // Skip the network round trip (and its timeout) entirely when we
    // already know we're offline and have something cached to show.
    if (!await checkIsOnline()) {
      final cached = await LocalStore.instance.loadMap(_profileDiskKey(userId));
      if (cached != null) {
        AppLogger.info('auth', 'offline — serving cached profile for $userId');
        return UserModel.fromMap(cached, cached['email'] as String? ?? email);
      }
    }

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel.fromMap(data, email);
      // Write-through: the profile is small and rarely changes, so
      // caching it makes "offline profile" work with no extra plumbing —
      // just persist on every successful read.
      await LocalStore.instance.saveMap(_profileDiskKey(userId), {
        ...data,
        'email': email,
      });
      return user;
    } catch (e) {
      final cached = await LocalStore.instance.loadMap(_profileDiskKey(userId));
      if (cached != null) {
        AppLogger.warning('auth', 'profile fetch failed, serving cached profile: $e');
        return UserModel.fromMap(cached, cached['email'] as String? ?? email);
      }
      rethrow;
    }
  }

  /// Retries fetching the just-created profile a few times with
  /// backoff to tolerate normal replication lag on the `handle_new_user`
  /// trigger, instead of assuming a fixed delay is always enough.
  Future<UserModel> _fetchProfileWithRetry(String userId, String email) async {
    const attempts = 5;
    for (var i = 0; i < attempts; i++) {
      try {
        return await _fetchProfile(userId, email);
      } catch (_) {
        if (i == attempts - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
      }
    }
    // Unreachable: the loop above always returns or rethrows.
    throw Exception('Could not load your profile. Please try logging in.');
  }
}