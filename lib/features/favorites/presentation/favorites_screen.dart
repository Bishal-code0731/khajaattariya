import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../application/favorites_provider.dart';
import '../domain/models/favorite_model.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const Scaffold();

    final favoritesAsync = ref.watch(favoritesProvider(user.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) =>
        const Center(child: Text('Could not load favorites')),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: AppSpacing.md),
                  Text('No favorites yet',
                      style: AppTypography.headingSmall
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Heart a restaurant to save it here',
                      style: AppTypography.bodyMedium),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.md,
            ),
            itemCount: favorites.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              return _FavoriteTile(
                favorite: favorites[index],
                userId: user.id,
              );
            },
          );
        },
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
    return GlassCard(
      onTap: () => context
          .push('${RouteNames.restaurant}/${favorite.restaurantId}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      borderRadius: AppSpacing.radiusLg,
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
            BorderRadius.circular(AppSpacing.radiusMd),
            child: favorite.restaurantImageUrl.isNotEmpty
                ? Image.network(
              favorite.restaurantImageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
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
            icon: const Icon(Icons.favorite_rounded,
                color: AppColors.error),
            onPressed: () => ref
                .read(favoriteToggleProvider.notifier)
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