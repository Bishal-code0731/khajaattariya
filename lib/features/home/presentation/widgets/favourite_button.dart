import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../favorites/application/favorites_provider.dart';

/// The set of restaurant ids the user has saved, or an empty set while loading / for guests.
Set<String> watchFavouriteIds(WidgetRef ref, String? userId) {
  if (userId == null) return const {};
  final favs = ref.watch(favoritesProvider(userId)).valueOrNull ?? const [];
  return {for (final f in favs) f.restaurantId};
}

/// Heart toggle for a restaurant, shown in a round chip so it reads on top of photos.
class FavouriteButton extends ConsumerStatefulWidget {
  const FavouriteButton({
    super.key,
    required this.userId,
    required this.restaurantId,
    required this.isFavourite,
    this.overPhoto = true,
  });

  final String userId;
  final String restaurantId;
  final bool isFavourite;

  /// Dark translucent chip with a white icon (on a photo) vs.
  final bool overPhoto;

  @override
  ConsumerState<FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends ConsumerState<FavouriteButton> {
  bool? _optimistic;

  @override
  void didUpdateWidget(covariant FavouriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavourite != widget.isFavourite) _optimistic = null;
  }

  Future<void> _toggle() async {
    final s = context.s.customer;
    final next = !(_optimistic ?? widget.isFavourite);
    setState(() => _optimistic = next);
    final notifier =
        ref.read(favoriteToggleProvider(widget.restaurantId).notifier);
    await notifier.toggle(
        userId: widget.userId, restaurantId: widget.restaurantId);
    if (!mounted) return;
    final result = ref.read(favoriteToggleProvider(widget.restaurantId));
    if (result.hasError) {
      setState(() => _optimistic = null);
      AppSnackbar.error(context, result.error);
    } else {
      AppSnackbar.success(
          context, next ? s.savedToFavourites : s.removedFromFavourites);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final fav = _optimistic ?? widget.isFavourite;
    final busy =
        ref.watch(favoriteToggleProvider(widget.restaurantId)).isLoading;

    final icon = Icon(
      fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      size: 22,
      color: fav
          ? (widget.overPhoto ? AppColors.marigold : p.error)
          : (widget.overPhoto ? AppColors.white : p.textPrimary),
    );

    return Semantics(
      toggled: fav,
      child: IconButton(
        tooltip: fav ? s.removeFavourite : s.addFavourite,
        onPressed: busy ? null : _toggle,
        style: widget.overPhoto
            ? IconButton.styleFrom(
                backgroundColor: AppColors.black.withValues(alpha: 0.42))
            : null,
        icon: icon,
      ),
    );
  }
}
