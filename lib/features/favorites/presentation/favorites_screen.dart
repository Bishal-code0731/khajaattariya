import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/favorites_provider.dart';
import '../domain/models/favorite_model.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      // Was `return const Scaffold();` — a genuinely blank screen with no
      // app bar, message, or way back. Now shows a proper empty state.
      return Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.safeBack(),
          ),
        ),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please login to view favorites',
          action: TextButton(
            onPressed: () => context.push(RouteNames.login),
            child: const Text('Login'),
          ),
        ),
      );
    }

    final favoritesAsync = ref.watch(favoritesProvider(user.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safeBack(),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: favoritesAsync.when(
              loading: () => const AppShimmerCardList(count: 4, itemHeight: 72),
              error: (_, __) => AppErrorState(
                message: 'Could not load favorites',
                onRetry: () => ref.invalidate(favoritesProvider(user.id)),
              ),
              data: (favorites) {
                if (favorites.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'No favorites yet',
                    subtitle: 'Heart a restaurant to save it here',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return _FavoriteTile(
                      favorite: favorites[index],
                      userId: user.id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  final FavoriteModel favorite;
  final String userId;

  const _FavoriteTile({
    required this.favorite,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBusy = ref.watch(favoriteToggleProvider(favorite.restaurantId)).isLoading;
    return GlassCard(
      onTap: () => context
          .pushOnce('${RouteNames.restaurant}/${favorite.restaurantId}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
            BorderRadius.circular(AppSpacing.radiusMd),
            child: favorite.restaurantImageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: favorite.restaurantImageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              memCacheWidth: 144,
              placeholder: (_, __) => _PlaceholderImage(),
              errorWidget: (_, __, ___) =>
                  _PlaceholderImage(),
            )
                : _PlaceholderImage(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(favorite.restaurantName,
                    style: AppTypography.headingSmall),
                const SizedBox(height: 2),
                Text(favorite.cuisineType,
                    style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.accent, size: 14),
                    const SizedBox(width: 2),
                    Text(favorite.rating.toStringAsFixed(1),
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                  )
                : const Icon(Icons.favorite_rounded, color: AppColors.error),
            onPressed: isBusy ? null : () => ref
                .read(favoriteToggleProvider(favorite.restaurantId).notifier)
                .toggle(
              userId: userId,
              restaurantId: favorite.restaurantId,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(Icons.restaurant_rounded,
          color: AppColors.primary),
    );
  }
}