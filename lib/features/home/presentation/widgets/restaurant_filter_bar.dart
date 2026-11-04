import 'package:flutter/material.dart';
import '../../../../core/l10n/s.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/restaurant_filter.dart';

/// Sort button + quick filter chips above the restaurant list.
class RestaurantFilterBar extends StatelessWidget {
  const RestaurantFilterBar(
      {super.key, required this.filter, required this.onChanged});

  final RestaurantFilter filter;
  final ValueChanged<RestaurantFilter> onChanged;

  String _sortLabel(BuildContext context, RestaurantSort sort) {
    final s = context.s.customer;
    return switch (sort) {
      RestaurantSort.recommended => s.sort,
      RestaurantSort.rating => s.sortRating,
      RestaurantSort.fastest => s.sortFastest,
    };
  }

  Future<void> _pickSort(BuildContext context) async {
    final s = context.s.customer;
    final picked = await showModalBottomSheet<RestaurantSort>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: RadioGroup<RestaurantSort>(
            groupValue: filter.sort,
            onChanged: (v) => Navigator.of(ctx).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                  child: Text(s.sortBy, style: ctx.text.h2),
                ),
                for (final (value, label) in [
                  (RestaurantSort.recommended, s.sortRecommended),
                  (RestaurantSort.rating, s.sortRating),
                  (RestaurantSort.fastest, s.sortFastest),
                ])
                  RadioListTile<RestaurantSort>(
                    value: value,
                    title: Text(label, style: ctx.text.bodyLarge),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (picked != null) onChanged(filter.copyWith(sort: picked));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.customer;
    final p = context.palette;
    final sortActive = filter.sort != RestaurantSort.recommended;

    Widget toggle(
            String label, bool value, RestaurantFilter Function(bool) update,
            {IconData? icon}) =>
        FilterChip(
          label: Text(label),
          avatar: icon == null || value
              ? null
              : Icon(icon, size: 16, color: p.textSecondary),
          selected: value,
          showCheckmark: true,
          onSelected: (v) => onChanged(update(v)),
        );

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal, vertical: AppSpacing.sm),
      children: [
        ActionChip(
          avatar: Icon(Icons.swap_vert_rounded,
              size: 18, color: sortActive ? p.onBrandSoft : p.textPrimary),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_sortLabel(context, filter.sort)),
              Icon(Icons.expand_more_rounded,
                  size: 18,
                  color: sortActive ? p.onBrandSoft : p.textSecondary),
            ],
          ),
          backgroundColor: sortActive ? p.brandSoft : null,
          labelStyle: sortActive
              ? context.text.label.copyWith(color: p.onBrandSoft)
              : null,
          tooltip: s.sortBy,
          onPressed: () => _pickSort(context),
        ),
        const SizedBox(width: AppSpacing.sm),
        toggle(s.filterRating4, filter.minRating4,
            (v) => filter.copyWith(minRating4: v),
            icon: Icons.star_rounded),
        const SizedBox(width: AppSpacing.sm),
        toggle(s.filterFast, filter.fastDelivery,
            (v) => filter.copyWith(fastDelivery: v),
            icon: Icons.bolt_rounded),
        const SizedBox(width: AppSpacing.sm),
        toggle(s.filterOffers, filter.offersOnly,
            (v) => filter.copyWith(offersOnly: v),
            icon: Icons.local_offer_outlined),
        const SizedBox(width: AppSpacing.sm),
        toggle(
            s.filterOpenNow, filter.openNow, (v) => filter.copyWith(openNow: v),
            icon: Icons.schedule_rounded),
      ],
    );
  }
}

/// Pins [RestaurantFilterBar] under the header while scrolling.
class RestaurantFilterBarDelegate extends SliverPersistentHeaderDelegate {
  RestaurantFilterBarDelegate(
      {required this.child,
      required this.extent,
      required this.background,
      required this.border});

  final Widget child;
  final double extent;
  final Color background;
  final Color border;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: overlapsContent || shrinkOffset > 0
            ? Border(bottom: BorderSide(color: border))
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(RestaurantFilterBarDelegate old) =>
      old.child != child ||
      old.extent != extent ||
      old.background != background ||
      old.border != border;
}
