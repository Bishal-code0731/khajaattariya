import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/address_model.dart';

/// Stored label values for the three presets.
const addressLabelHome = 'Home';
const addressLabelWork = 'Work';
const addressLabelOther = 'Other';

IconData addressLabelIcon(String label) => switch (label.toLowerCase()) {
      'home' => Icons.home_outlined,
      'work' => Icons.work_outline_rounded,
      'other' => Icons.place_outlined,
      _ => Icons.bookmark_border_rounded,
    };

/// Shows preset labels in the current language; custom labels as typed.
String addressLabelText(BuildContext context, String label) {
  final a = context.s.account;
  return switch (label.toLowerCase()) {
    'home' => a.labelHome,
    'work' => a.labelWork,
    'other' => a.labelOther,
    _ => label,
  };
}

enum _AddressAction { edit, delete }

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.isBusy,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final AddressModel address;
  final bool isBusy;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = context.s.account;
    final c = context.s.common;
    final landmark = address.landmark?.trim() ?? '';
    return AppCard(
      onTap: isBusy ? null : onEdit,
      borderColor: address.isDefault ? p.brand : null,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.xs, AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: address.isDefault ? p.brandSoft : p.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                addressLabelIcon(address.label),
                size: 20,
                color: address.isDefault ? p.onBrandSoft : p.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(addressLabelText(context, address.label),
                          style: context.text.h3),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 1),
                          decoration: BoxDecoration(
                            color: p.brandSoft,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXs),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 12, color: p.onBrandSoft),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(a.defaultTag,
                                  style: context.text.overline
                                      .copyWith(color: p.onBrandSoft)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(address.fullAddress,
                      style: context.text.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  if (landmark.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(a.near(landmark),
                        style: context.text.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (!address.isDefault) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: a.setDefault,
                      onPressed: isBusy ? null : onSetDefault,
                      variant: AppButtonVariant.tonal,
                      size: AppButtonSize.small,
                      leadingIcon: Icons.check_circle_outline_rounded,
                      expand: false,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            PopupMenuButton<_AddressAction>(
              tooltip: a.addressOptions,
              icon: Icon(Icons.more_vert_rounded, color: p.textSecondary),
              onSelected: (action) => switch (action) {
                _AddressAction.edit => onEdit(),
                _AddressAction.delete => onDelete(),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _AddressAction.edit,
                  child: _MenuRow(icon: Icons.edit_outlined, label: c.edit),
                ),
                PopupMenuItem(
                  value: _AddressAction.delete,
                  child: _MenuRow(
                      icon: Icons.delete_outline_rounded,
                      label: c.delete,
                      color: p.error),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.palette.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: context.text.body.copyWith(color: fg)),
      ],
    );
  }
}
