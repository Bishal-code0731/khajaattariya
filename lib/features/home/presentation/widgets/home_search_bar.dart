import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

// The search bar on the home screen.
// This is NOT a real text field — it's a tappable container
// that navigates to the full search screen when tapped.
// Real typing happens on the search screen, not here.
// This pattern is used by Swiggy, Zomato, and Daraz.

class HomeSearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchBar({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      child: GestureDetector(
        // GestureDetector detects taps on any widget —
        // even ones that aren't normally tappable like Container.
        onTap: onTap,
        child: Container(
          height: AppSpacing.inputHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.search_rounded,
                color: AppColors.textHint,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Search food, restaurant...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}