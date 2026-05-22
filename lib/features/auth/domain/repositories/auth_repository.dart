import '../models/user_model.dart';

// The contract — defines what auth can do
// The actual implementation lives in data/auth_repository_impl.dart
// This separation means we can swap Supabase for Firebase
// without touching a single screen or provider

abstract class AuthRepository {
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;
}