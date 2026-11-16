import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthException, AuthResponse, OtpType, UserAttributes;

import '../../../../core/cache/local_store.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/network/retry_queue.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../main.dart';
import '../../domain/auth_exceptions.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static String _profileDiskKey(String userId) => 'profile:$userId';
  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? termsVersion,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': role,
        if (termsVersion != null) 'terms_version': termsVersion,
      },
    );

    if (response.user == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    if (response.session == null) {
      throw EmailConfirmationRequiredException(email);
    }

    return _fetchProfileWithRetry(response.user!.id, email);
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final AuthResponse response;
    try {
      response = await supabase.auth
          .signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      final unverified = e.code == 'email_not_confirmed' ||
          e.message.toLowerCase().contains('email not confirmed');
      if (!unverified) rethrow;
      try {
        await resendEmailOtp(email);
      } on AuthException catch (resendError) {
        // Usually the 60-second cooldown: a recent code is still valid.
        AppLogger.warning('auth',
            'resend after unverified login skipped: ${resendError.code}');
      }
      throw EmailNotVerifiedException(email);
    }

    if (response.user == null) {
      throw Exception('Invalid email or password.');
    }

    final user = await _fetchProfile(response.user!.id, email);
    if (!user.isActive) {
      // A disabled account must not keep a usable session (B-02).
      await signOut();
      throw const AccountDisabledException();
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
    await RetryQueue.instance.clear();
  }

  @override
  Future<void> sendPasswordResetEmail(String email,
      {String? redirectTo}) async {
    await supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<UserModel> verifyEmailOtp(
      {required String email, required String code}) async {
    final response = await supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    final authUser = response.user;
    if (authUser == null) throw Exception('Verification failed');
    final user = await _fetchProfileWithRetry(authUser.id, email);
    if (!user.isActive) {
      await signOut();
      throw const AccountDisabledException();
    }
    return user;
  }

  @override
  Future<void> resendEmailOtp(String email) async {
    await supabase.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id, user.email ?? '');
  }

  @override
  Stream<void> get passwordRecoveryEvents => supabase.auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

  @override
  Stream<UserModel?> get authStateChanges {
    return supabase.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      final profile = await _fetchProfile(user.id, user.email ?? '');
      if (!profile.isActive) {
        AppLogger.warning('auth', 'disabled account ${user.id} — signing out');
        await signOut();
        return null;
      }
      return profile;
    });
  }

  Future<UserModel> _fetchProfile(String userId, String email) async {
    if (!await checkIsOnline()) {
      final cached = await LocalStore.instance.loadMap(_profileDiskKey(userId));
      if (cached != null) {
        AppLogger.info('auth', 'offline — serving cached profile for $userId');
        return UserModel.fromMap(cached, cached['email'] as String? ?? email);
      }
    }

    try {
      final data =
          await supabase.from('profiles').select().eq('id', userId).single();

      final user = UserModel.fromMap(data, email);
      await LocalStore.instance.saveMap(_profileDiskKey(userId), {
        ...data,
        'email': email,
      });
      return user;
    } catch (e) {
      final cached = await LocalStore.instance.loadMap(_profileDiskKey(userId));
      if (cached != null) {
        AppLogger.warning(
            'auth', 'profile fetch failed, serving cached profile: $e');
        return UserModel.fromMap(cached, cached['email'] as String? ?? email);
      }
      rethrow;
    }
  }

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
