import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/auth/domain/models/user_model.dart';
import '../../../main.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/glass_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Profile update notifier
final profileUpdateProvider =
StateNotifierProvider<ProfileUpdateNotifier, AsyncValue<void>>(
      (ref) => ProfileUpdateNotifier(),
);

class ProfileUpdateNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileUpdateNotifier() : super(const AsyncValue.data(null));

  Future<bool> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await supabase.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<String?> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    state = const AsyncValue.loading();
    try {
      final ext = file.path.split('.').last;
      final path = '$userId/avatar.$ext';

      await supabase.storage.from('avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final url = supabase.storage.from('avatars').getPublicUrl(path);

      await supabase
          .from('profiles')
          .update({'avatar_url': url}).eq('id', userId);

      state = const AsyncValue.data(null);
      return url;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).valueOrNull;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar(String userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isLoading = true);
    final url = await ref.read(profileUpdateProvider.notifier).uploadAvatar(
      userId: userId,
      file: File(picked.path),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (url != null) {
      // Refresh auth state so side menu + avatar updates
      ref.invalidate(authStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload avatar'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(profileUpdateProvider.notifier).updateProfile(
      userId: user.id,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) _isEditing = false;
    });

    if (success) {
      ref.invalidate(authStateProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.home),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text('Edit'),
            )
          else
            TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                final user = userAsync.valueOrNull;
                if (user != null) {
                  _nameController.text = user.fullName;
                  _phoneController.text = user.phone ?? '';
                }
              }),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(
          child: Text('Could not load profile'),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: AppButton(
                label: 'Login',
                onPressed: () => context.go(RouteNames.login),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _AvatarSection(
                    user: user,
                    isLoading: _isLoading,
                    onPickImage: () => _pickAndUploadAvatar(user.id),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: AppSpacing.radiusLg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Info',
                            style: AppTypography.headingSmall),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Full Name',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline_rounded,
                          enabled: _isEditing,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Phone',
                          controller: _phoneController,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Email — read only always
                        AppTextField(
                          label: 'Email',
                          controller:
                          TextEditingController(text: user.email),
                          prefixIcon: Icons.email_outlined,
                          enabled: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Role badge card
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: AppSpacing.radiusLg,
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Type',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Save Changes',
                      isLoading: _isLoading,
                      onPressed: () => _saveProfile(user),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  // Logout button
                  AppButton(
                    label: 'Logout',
                    isOutlined: true,
                    onPressed: () =>
                        ref.read(authNotifierProvider.notifier).signOut(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final UserModel user;
  final bool isLoading;
  final VoidCallback onPickImage;

  const _AvatarSection({
    required this.user,
    required this.isLoading,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
            user.fullName.isNotEmpty
                ? user.fullName[0].toUpperCase()
                : '?',
            style: AppTypography.displayMedium
                .copyWith(color: AppColors.primary),
          )
              : null,
        ),
        if (isLoading)
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: isLoading ? null : onPickImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}