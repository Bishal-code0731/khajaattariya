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

  bool get isCustomer => role == 'customer';
  bool get isRestaurant => role == 'restaurant';
  bool get isRider => role == 'rider';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String email) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: email,
      phone: map['phone'] as String?,
      role: map['role'] as String,
      avatarUrl: map['avatar_url'] as String?,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
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