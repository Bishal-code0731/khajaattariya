import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../application/favorites_provider.dart';
import '../domain/models/favorite_model.dart';
import 'widgets/favorite_restaurant_card.dart';

/// Restaurants the customer saved with the heart button.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, String userId,
      FavoriteModel f) async {
    final provider = favoriteToggleProvider(f.restaurantId);
    await ref
        .read(provider.notifier)
        .toggle(userId: userId, restaurantId: f.restaurantId);
    if (!context.mounted) return;
    final a = context.s.account;
    if (ref.read(provider).hasError) {
      AppSnackbar.warning(context, a.favoriteQueued);
    } else {
      AppSnackbar.success(context, a.favoriteRemoved);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.s.account;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
          appBar: AppTopBar(title: a.favoritesTitle),
          body: const AppShimmerCardList(itemHeight: 96));
    }
    final async = ref.watch(favoritesProvider(user.id));
    final count = async.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppTopBar(
          title: a.favoritesTitle,
          subtitle: count > 0 ? a.savedCount(count) : null),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: async.when(
              skipLoadingOnReload: true,
              loading: () => const AppShimmerCardList(count: 4, itemHeight: 96),
              error: (e, _) => AppErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(favoritesProvider(user.id))),
              data: (favorites) {
                if (favorites.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: a.noFavoritesTitle,
                    subtitle: a.noFavoritesBody,
                    action: AppButton(
                      label: a.browseRestaurants,
                      leadingIcon: Icons.restaurant_menu_rounded,
                      expand: false,
                      onPressed: () => context.go(RouteNames.home),
                    ),
                  );
                }
                return _FavoritesGrid(
                  favorites: favorites,
                  itemBuilder: (f) => Consumer(
                    builder: (context, ref, _) => FavoriteRestaurantCard(
                      favorite: f,
                      isRemoving: ref
                          .watch(favoriteToggleProvider(f.restaurantId))
                          .isLoading,
                      onOpen: () => context.pushOnce(
                          '${RouteNames.restaurant}/${f.restaurantId}'),
                      onRemove: () => _remove(context, ref, user.id, f),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.favorites, required this.itemBuilder});

  final List<FavoriteModel> favorites;
  final Widget Function(FavoriteModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final columns = w >= 1000 ? 3 : (w >= 600 ? 2 : 1);
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 114 + 16 * (textScale - 1) * 4,
              ),
              itemCount: favorites.length,
              itemBuilder: (_, i) => itemBuilder(favorites[i]),
            );
          },
        ),
      ),
    );
  }
}
