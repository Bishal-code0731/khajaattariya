import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';
import '../domain/models/user_model.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
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

    // Wait a moment for the trigger to create the profile
    await Future.delayed(const Duration(milliseconds: 500));

    return _fetchProfile(response.user!.id, email);
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
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromMap(data, email);
  }
}