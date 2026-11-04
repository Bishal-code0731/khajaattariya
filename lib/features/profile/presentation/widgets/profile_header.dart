import 'package:flutter/material.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../auth/domain/models/user_model.dart';

/// Translated name of a role ("Restaurant partner" / "रेस्टुरेन्ट साझेदार").
String roleLabel(BuildContext context, UserRole role) {
  final a = context.s.account;
  return switch (role) {
    UserRole.customer => a.roleCustomer,
    UserRole.restaurant => a.roleRestaurant,
    UserRole.rider => a.roleRider,
    UserRole.admin => a.roleAdmin,
  };
}

/// Up to two initials from a name; '?' when the name is empty.
String initialsOf(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters.first;
  final last = parts.length > 1 ? parts.last.characters.first : '';
  return (first + last).toUpperCase();
}

/// Round avatar with an initials fallback and an optional camera button.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.url,
    this.size = 72,
    this.isUploading = false,
    this.onChangePhoto,
  });

  final String name;
  final String? url;
  final double size;
  final bool isUploading;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: size,
              height: size,
              decoration:
                  BoxDecoration(color: p.brandSoft, shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: hasUrl
                  ? AppNetworkImage(
                      url: url,
                      width: size,
                      height: size,
                      fallbackIcon: Icons.person_rounded)
                  : Text(
                      initialsOf(name),
                      style: AppTypography.headingLarge
                          .copyWith(color: p.onBrandSoft),
                    ),
            ),
          ),
          if (isUploading)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                    color: p.surface.withValues(alpha: 0.7),
                    shape: BoxShape.circle),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: p.brand),
                ),
              ),
            ),
          if (onChangePhoto != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Tooltip(
                message: context.s.account.changePhoto,
                child: Material(
                  color: p.brand,
                  shape: CircleBorder(
                      side: BorderSide(color: p.surface, width: 2)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isUploading ? null : onChangePhoto,
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(Icons.photo_camera_outlined,
                          size: 16, color: p.onBrand),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Top of the account hub: who is signed in and how to edit it.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.isUploadingPhoto,
    required this.onChangePhoto,
    required this.onEdit,
  });

  final UserModel user;
  final bool isUploadingPhoto;
  final VoidCallback onChangePhoto;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = context.s.account;
    final phone = user.phone?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfileAvatar(
              name: user.fullName,
              url: user.avatarUrl,
              isUploading: isUploadingPhoto,
              onChangePhoto: onChangePhoto,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isEmpty ? user.email : user.fullName,
                    style: context.text.h2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.brandSoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 13, color: p.onBrandSoft),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            roleLabel(context, user.userRole),
                            style: context.text.overline
                                .copyWith(color: p.onBrandSoft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ContactLine(icon: Icons.mail_outline_rounded, text: user.email),
        const SizedBox(height: AppSpacing.xs),
        _ContactLine(
          icon: Icons.phone_outlined,
          text: phone.isEmpty ? a.noPhone : AppFormat.phone(phone),
          muted: phone.isEmpty,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: a.editProfile,
          onPressed: onEdit,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
          leadingIcon: Icons.edit_outlined,
        ),
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine(
      {required this.icon, required this.text, this.muted = false});

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Icon(icon, size: 16, color: p.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: muted ? context.text.hint : context.text.secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
