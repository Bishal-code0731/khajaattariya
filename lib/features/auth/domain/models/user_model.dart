import '../../../../core/enums/user_role.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  /// Typed view of [role] — prefer this over comparing raw strings.
  UserRole get userRole => UserRole.fromString(role);

  bool get isCustomer => userRole == UserRole.customer;
  bool get isRestaurant => userRole == UserRole.restaurant;
  bool get isRider => userRole == UserRole.rider;
  bool get isAdmin => userRole == UserRole.admin;

  factory UserModel.fromMap(Map<String, dynamic> map, String email) {
    // The handle_new_user trigger can momentarily leave columns
    // unpopulated right after signup (this is exactly why
    // _fetchProfileWithRetry exists) — defaulting instead of a hard
    // cast means a transiently-null column degrades gracefully instead
    // of throwing a TypeError that skips the retry logic entirely.
    return UserModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      email: email,
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'customer',
      avatarUrl: map['avatar_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'is_active': isActive,
    };
  }
}