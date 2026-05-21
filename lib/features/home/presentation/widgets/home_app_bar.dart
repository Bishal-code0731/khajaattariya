import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

// The top bar of the home screen.
// Shows: App logo + name on left, notification bell + cart on right.
// This is a SliverAppBar — it works inside a CustomScrollView
// so it can stick to the top when the user scrolls down.

class HomeAppBar extends StatelessWidget {
  // These callbacks are passed in from the parent.
  // The app bar doesn't know what happens when you tap notif or cart —
  // the parent screen decides. This keeps the widget reusable.
  final VoidCallback onNotificationTap;
  final VoidCallback onCartTap;
  final int cartItemCount; // shows badge on cart icon

  const HomeAppBar({
    super.key,
    required this.onNotificationTap,
    required this.onCartTap,
    required this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      // Stays visible when scrolling
      floating: true,
      // Doesn't collapse into a smaller version
      pinned: false,
      backgroundColor: AppColors.background,
      elevation: 0,
      // Removes the default back button
      automaticallyImplyLeading: false,

      title: Row(
        children: [
          // App icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // App name
          const Text(
            'Khaja Attariya',
            style: AppTypography.headingMedium,
          ),
        ],
      ),

      actions: [
        // Notification bell
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
            size: 26,
          ),
        ),

        // Cart with badge
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Stack(
            children: [
              IconButton(
                onPressed: onCartTap,
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
              ),
              // Badge — only show if cart has items
              if (cartItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        // If more than 9 items show "9+"
                        cartItemCount > 9 ? '9+' : '$cartItemCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}