import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/auth/application/auth_provider.dart';

class HomeAppBar extends ConsumerWidget {
  final int cartItemCount;
  final VoidCallback onCartTap;
  final VoidCallback onNotificationTap;

  const HomeAppBar({
    super.key,
    required this.cartItemCount,
    required this.onCartTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
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
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Khaja Attariya', style: AppTypography.headingSmall),
              if (user != null)
                Text(
                  'Hi, ${user.fullName.split(' ').first}! 👋',
                  style: AppTypography.bodySmall,
                ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textPrimary,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: onCartTap,
              icon: const Icon(Icons.shopping_bag_outlined),
              color: AppColors.textPrimary,
            ),
            if (cartItemCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
