import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? termsVersion,
  });

  Future<UserModel> signIn({required String email, required String password});

  Future<void> signOut();

  /// [redirectTo] is the link the reset email opens (deep link / web URL).
  Future<void> sendPasswordResetEmail(String email, {String? redirectTo});

  /// Sets a new password for the signed-in (or password-recovery) session.
  Future<void> updatePassword(String newPassword);

  /// Checks the 6-digit code emailed at signup and signs the user in.
  Future<UserModel> verifyEmailOtp(
      {required String email, required String code});

  /// Sends a new signup code (the backend allows one every 60 seconds).
  Future<void> resendEmailOtp(String email);

  Future<UserModel?> getCurrentUser();

  /// Emits null when signed out or when the account is disabled.
  Stream<UserModel?> get authStateChanges;

  Stream<void> get passwordRecoveryEvents;
}
