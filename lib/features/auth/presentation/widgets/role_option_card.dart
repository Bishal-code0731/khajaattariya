import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// One selectable account type on the signup form.
class RoleOptionCard extends StatelessWidget {
  const RoleOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: Material(
        color: selected ? p.brandSoft : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
              color: selected ? p.brand : p.border, width: selected ? 1.6 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? p.brand : p.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon,
                      size: 22, color: selected ? p.onBrand : p.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.label),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(description, style: context.text.caption),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: selected ? p.brand : p.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
