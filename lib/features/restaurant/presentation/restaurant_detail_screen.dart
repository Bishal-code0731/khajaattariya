import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../auth/application/auth_provider.dart';
import '../../cart/application/cart_notifier.dart';
import '../../cart/presentation/widgets/view_cart_bar.dart';
import '../../home/application/restaurant_provider.dart';
import '../../home/domain/models/food_item_model.dart';
import '../../home/domain/models/restaurant_model.dart';
import '../../home/presentation/widgets/favourite_button.dart';
import '../../restaurant_hours/application/restaurant_hours_provider.dart';
import '../../restaurant_hours/domain/models/restaurant_hours_model.dart';
import '../application/menu_sections.dart';
import 'widgets/menu_item_tile.dart';
import 'widgets/menu_section_bar.dart';
import 'widgets/restaurant_hero_app_bar.dart';
import 'widgets/restaurant_info_header.dart';
import 'widgets/restaurant_info_section.dart';
import 'widgets/restaurant_reviews_section.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  static const _reviewsId = '_reviews';
  static const _infoId = '_info';
  static const _maxBodyWidth = 820.0;

  final _scroll = ScrollController();
  final _keys = <String, GlobalKey>{};
  List<String> _targetOrder = const [];
  bool _collapsed = false;
  bool _vegOnly = false;
  bool _jumping = false;
  String? _activeId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  double _heroHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 280 : 220;

  double _barExtent(BuildContext context) =>
      40 +
      16 * (MediaQuery.textScalerOf(context).scale(14) / 14) +
      AppSpacing.sm;

  double _pinnedExtent(BuildContext context) =>
      kToolbarHeight + MediaQuery.paddingOf(context).top + _barExtent(context);

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, () => GlobalKey());

  double? _offsetOf(String id) {
    final ro = _keys[id]?.currentContext?.findRenderObject();
    if (ro == null || !ro.attached) return null;
    final viewport = RenderAbstractViewport.maybeOf(ro);
    if (viewport == null) return null;
    return viewport.getOffsetToReveal(ro, 0).offset;
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final collapsed = _scroll.offset >
        _heroHeight(context) -
            kToolbarHeight -
            MediaQuery.paddingOf(context).top -
            8;
    String? active = _activeId;
    if (!_jumping) {
      final line = _scroll.offset + _pinnedExtent(context) + 1;
      active = _targetOrder.isEmpty ? null : _targetOrder.first;
      for (final id in _targetOrder) {
        final o = _offsetOf(id);
        if (o != null && o <= line) active = id;
      }
    }
    if (collapsed != _collapsed || active != _activeId) {
      setState(() {
        _collapsed = collapsed;
        _activeId = active;
      });
    }
  }

  Future<void> _jumpTo(String id) async {
    final o = _offsetOf(id);
    if (o == null || !_scroll.hasClients) return;
    setState(() {
      _activeId = id;
      _jumping = true;
    });
    final target = (o - _pinnedExtent(context))
        .clamp(0.0, _scroll.position.maxScrollExtent);
    await _scroll.animateTo(target,
        duration: AppMotion.normal * 2, curve: AppMotion.curve);
    if (mounted) setState(() => _jumping = false);
  }

  void _add(RestaurantModel restaurant, FoodItemModel item) {
    if (!restaurant.isOpen) {
      AppSnackbar.warning(context, context.s.customer.restaurantClosedCantAdd);
      return;
    }
    if (!item.isAvailable) return;
    ref.read(cartNotifierProvider.notifier).addItem(item);
  }

  Widget _boxed(Widget child) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxBodyWidth),
            child: child),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s.customer;
    final async = ref.watch(restaurantByIdProvider(widget.restaurantId));
    final restaurant = async.valueOrNull;

    if (restaurant == null) {
      Widget body;
      if (async.isLoading) {
        body = const AppShimmerCardList(count: 5);
      } else if (async.hasError) {
        body = AppErrorState(
          error: async.error,
          onRetry: () =>
              ref.invalidate(restaurantByIdProvider(widget.restaurantId)),
        );
      } else {
        body = AppEmptyState(
          icon: Icons.storefront_outlined,
          title: s.restaurantNotFoundTitle,
          subtitle: s.restaurantNotFoundBody,
          action: AppButton(
            label: s.backToHome,
            expand: false,
            onPressed: () => context.go(RouteNames.home),
          ),
        );
      }
      return Scaffold(
        appBar: const AppTopBar(title: ''),
        body: Column(children: [const OfflineBanner(), Expanded(child: body)]),
      );
    }
    return _buildPage(context, restaurant);
  }

  Widget _buildPage(BuildContext context, RestaurantModel restaurant) {
    final p = context.palette;
    final s = context.s.customer;
    final user = ref.watch(authStateProvider).valueOrNull;
    final favIds = watchFavouriteIds(ref, user?.id);
    final menuAsync = ref.watch(menuItemsProvider(restaurant.id));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final hours = ref.watch(restaurantHoursProvider(restaurant.id)).valueOrNull;
    final cart = ref.watch(cartNotifierProvider);

    RestaurantHoursModel? today;
    for (final h in hours ?? const <RestaurantHoursModel>[]) {
      if (h.weekday == DateTime.now().weekday) today = h;
    }

    final items = menuAsync.valueOrNull;
    var sections = items == null
        ? const <MenuSection>[]
        : buildMenuSections(
            items,
            categoryNames: {for (final c in categories) c.id: c.name},
            moreTitle: s.menuMore,
            vegOnly: _vegOnly,
          );
    if (sections.length == 1 &&
        sections.first.id == MenuSection.uncategorisedId) {
      sections = [
        MenuSection(
            id: sections.first.id,
            title: s.menuAll,
            items: sections.first.items)
      ];
    }

    final targets = [
      for (final sec in sections) MenuJumpTarget(id: sec.id, label: sec.title),
      MenuJumpTarget(id: _reviewsId, label: s.reviewsTab),
      MenuJumpTarget(id: _infoId, label: s.infoTab),
    ];
    _targetOrder = [for (final t in targets) t.id];
    final activeId =
        _targetOrder.contains(_activeId) ? _activeId : _targetOrder.first;

    final menuSlivers = <Widget>[];
    if (items == null && menuAsync.isLoading) {
      menuSlivers.add(SliverToBoxAdapter(
          child: _boxed(const AppShimmerCardList(count: 4, shrinkWrap: true))));
    } else if (items == null) {
      menuSlivers.add(SliverToBoxAdapter(
        child: _boxed(AppErrorState(
          message: s.menuLoadFailed,
          onRetry: () =>
              ref.read(menuItemsProvider(restaurant.id).notifier).refresh(),
        )),
      ));
    } else if (items.isEmpty) {
      menuSlivers.add(SliverToBoxAdapter(
        child: _boxed(AppEmptyState(
          compact: true,
          icon: Icons.restaurant_menu_rounded,
          title: s.menuEmptyTitle,
          subtitle: s.menuEmptyBody,
        )),
      ));
    } else if (sections.isEmpty) {
      menuSlivers.add(SliverToBoxAdapter(
        child: _boxed(Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Text(s.menuVegEmpty, style: context.text.secondary),
        )),
      ));
    } else {
      for (final sec in sections) {
        menuSlivers.add(SliverToBoxAdapter(
          key: _keyFor(sec.id),
          child: _boxed(_MenuSectionView(
            section: sec,
            builder: (item) => MenuItemTile(
              key: ValueKey(item.id),
              item: item,
              quantity: cart.quantityOf(restaurant.id, item.id),
              canOrder: restaurant.isOpen,
              onAdd: () => _add(restaurant, item),
              onRemove: () => ref
                  .read(cartNotifierProvider.notifier)
                  .decrementQuantity(restaurant.id, item.id),
            ),
          )),
        ));
      }
    }

    return Scaffold(
      backgroundColor: p.surface,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                RestaurantHeroAppBar(
                  restaurant: restaurant,
                  collapsed: _collapsed,
                  expandedHeight: _heroHeight(context),
                  userId: user?.id,
                  isFavourite: favIds.contains(restaurant.id),
                ),
                SliverToBoxAdapter(
                  child: _boxed(RestaurantInfoHeader(
                    restaurant: restaurant,
                    today: today,
                    onRatingTap: () => _jumpTo(_reviewsId),
                  )),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: MenuSectionBarDelegate(
                    extent: _barExtent(context),
                    background: p.surface,
                    border: p.border,
                    child: _boxed(MenuSectionBar(
                      targets: targets,
                      activeId: activeId,
                      vegOnly: _vegOnly,
                      onVegOnlyChanged: (v) => setState(() => _vegOnly = v),
                      onJump: _jumpTo,
                    )),
                  ),
                ),
                ...menuSlivers,
                SliverToBoxAdapter(
                  key: _keyFor(_reviewsId),
                  child: _boxed(Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: RestaurantReviewsSection(restaurant: restaurant),
                  )),
                ),
                SliverToBoxAdapter(
                  key: _keyFor(_infoId),
                  child: _boxed(Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: RestaurantInfoSection(
                        restaurant: restaurant, hours: hours),
                  )),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ViewCartBar(),
    );
  }
}

class _MenuSectionView extends StatelessWidget {
  const _MenuSectionView({required this.section, required this.builder});

  final MenuSection section;
  final Widget Function(FoodItemModel) builder;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.xl, AppSpacing.screenHorizontal, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: Semantics(
                      header: true,
                      child: Text(section.title, style: context.text.h2))),
              Text('${section.items.length}', style: context.text.hint),
            ],
          ),
        ),
        for (var i = 0; i < section.items.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: AppSpacing.screenHorizontal,
              endIndent: AppSpacing.screenHorizontal,
              color: p.border,
            ),
          builder(section.items[i]),
        ],
      ],
    );
  }
}
