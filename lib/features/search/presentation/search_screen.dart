import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/l10n/s.dart';
import '../../../core/router/navigation_extensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../main.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/language_toggle.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../../cart/application/cart_notifier.dart';
import '../../cart/presentation/widgets/view_cart_bar.dart';
import '../../home/domain/models/food_item_model.dart';
import '../../home/domain/models/restaurant_model.dart';
import 'widgets/search_result_tiles.dart';

part 'search_screen.g.dart';

// Search results state
class SearchResults {
  final List<RestaurantModel> restaurants;
  final List<FoodItemModel> foodItems;

  const SearchResults({
    this.restaurants = const [],
    this.foodItems = const [],
  });

  bool get isEmpty => restaurants.isEmpty && foodItems.isEmpty;
}

// Search notifier with debounce
@Riverpod(keepAlive: true)
class Search extends _$Search {
  @override
  AsyncValue<SearchResults> build() => const AsyncValue.data(SearchResults());

  // Dedupes identical repeated queries...
  String _lastQuery = '';
  int _requestId = 0;

  Future<void> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _requestId++;
      _lastQuery = '';
      state = const AsyncValue.data(SearchResults());
      return;
    }

    if (trimmed == _lastQuery) return;
    _lastQuery = trimmed;
    final requestId = ++_requestId;

    state = const AsyncValue.loading();
    try {
      // Run both queries in parallel
      final results = await Future.wait([
        supabase
            .from('restaurants')
            .select()
            .eq('is_active', true)
            .ilike('name', '%$trimmed%')
            .order('rating', ascending: false)
            .limit(10),
        supabase
            .from('menu_items')
            .select('*, restaurants(name, rating, delivery_time_min, is_open)')
            .eq('is_available', true)
            .ilike('name', '%$trimmed%')
            .limit(15),
      ]);

      if (requestId != _requestId) return; // superseded — drop this result

      final restaurants =
          (results[0] as List).map((m) => RestaurantModel.fromMap(m)).toList();

      final foodItems =
          (results[1] as List).map((m) => FoodItemModel.fromMap(m)).toList();

      state = AsyncValue.data(
        SearchResults(restaurants: restaurants, foodItems: foodItems),
      );
    } catch (e) {
      if (requestId != _requestId) return;
      _lastQuery = '';
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void clear() {
    _requestId++;
    _lastQuery = '';
    state = const AsyncValue.data(SearchResults());
  }
}

/// Recent searches for this app session (in memory only, newest first).
class _RecentSearches {
  static final List<String> items = [];

  static void add(String q) {
    final t = q.trim();
    if (t.length < 2) return;
    items.removeWhere((e) => e.toLowerCase() == t.toLowerCase());
    items.insert(0, t);
    if (items.length > 6) items.removeLast();
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  late final Search _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(searchProvider.notifier);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _notifier.clear();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // show / hide the clear button
    // A single cancellable Timer instead of a new Future per keystroke.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) ref.read(searchProvider.notifier).search(value);
    });
  }

  void _searchNow(String value) {
    _debounce?.cancel();
    _controller.value = TextEditingValue(
        text: value, selection: TextSelection.collapsed(offset: value.length));
    _RecentSearches.add(value);
    setState(() {});
    ref.read(searchProvider.notifier).search(value);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(searchProvider.notifier).clear();
    setState(() {});
  }

  void _openRestaurant(String id) {
    _RecentSearches.add(_controller.text);
    context.pushOnce('${RouteNames.restaurant}/$id');
  }

  void _addDish(FoodItemModel item) {
    if (!item.restaurantOpen) {
      AppSnackbar.warning(context, context.s.customer.restaurantClosedCantAdd);
      return;
    }
    _RecentSearches.add(_controller.text);
    ref.read(cartNotifierProvider.notifier).addItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = context.s.customer;
    final state = ref.watch(searchProvider);
    final query = _controller.text.trim();

    Widget body;
    if (query.isEmpty) {
      body = _IdleView(
          onPick: _searchNow,
          onClearRecent: () => setState(_RecentSearches.items.clear));
    } else {
      body = state.when(
        loading: () => const AppShimmerCardList(count: 6, itemHeight: 72),
        error: (e, _) => AppErrorState(
            error: e,
            onRetry: () => ref.read(searchProvider.notifier).search(query)),
        data: (results) => results.isEmpty
            ? AppEmptyState(
                icon: Icons.search_off_rounded,
                title: s.noResultsTitle(query),
                subtitle: s.noResultsBody,
              )
            : _ResultsList(
                results: results,
                onOpenRestaurant: _openRestaurant,
                onAddDish: _addDish,
              ),
      );
    }

    return Scaffold(
      backgroundColor: p.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: 72,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safeBack(),
        ),
        title: AppSearchField(
          hint: s.searchHint,
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: _searchNow,
          onClear: query.isEmpty ? null : _clear,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.md),
            child: Center(child: LanguageToggle()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: p.border),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: body),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ViewCartBar(),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPick, required this.onClearRecent});

  final ValueChanged<String> onPick;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context) {
    final s = context.s.customer;
    final p = context.palette;
    final recent = _RecentSearches.items;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (recent.isNotEmpty) ...[
          SectionHeader(
              title: s.recentSearches,
              actionLabel: s.clearRecent,
              onAction: onClearRecent),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final q in recent)
                  ActionChip(
                    avatar: Icon(Icons.history_rounded,
                        size: 18, color: p.textSecondary),
                    label: Text(q),
                    onPressed: () => onPick(q),
                  ),
              ],
            ),
          ),
        ],
        SectionHeader(title: s.trySearching),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (label, term) in s.suggestions)
                ActionChip(
                  avatar: Icon(Icons.search_rounded, size: 18, color: p.brand),
                  label: Text(label),
                  onPressed: () => onPick(term),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppEmptyState(
          compact: true,
          icon: Icons.travel_explore_rounded,
          title: s.searchIdleTitle,
          subtitle: s.searchIdleBody,
        ),
      ],
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList(
      {required this.results,
      required this.onOpenRestaurant,
      required this.onAddDish});

  final SearchResults results;
  final ValueChanged<String> onOpenRestaurant;
  final ValueChanged<FoodItemModel> onAddDish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s.customer;
    final p = context.palette;
    final cart = ref.watch(cartNotifierProvider);
    Widget divider() => Divider(
          height: 1,
          indent: AppSpacing.screenHorizontal + 72 + AppSpacing.md,
          endIndent: AppSpacing.screenHorizontal,
          color: p.border,
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        if (results.restaurants.isNotEmpty) ...[
          SectionHeader(
            title: s.resultsRestaurants,
            subtitle: s.resultsCount(results.restaurants.length),
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                AppSpacing.lg, AppSpacing.screenHorizontal, AppSpacing.xs),
          ),
          for (var i = 0; i < results.restaurants.length; i++) ...[
            if (i > 0) divider(),
            RestaurantResultTile(
              restaurant: results.restaurants[i],
              onTap: () => onOpenRestaurant(results.restaurants[i].id),
            ),
          ],
        ],
        if (results.foodItems.isNotEmpty) ...[
          SectionHeader(
            title: s.resultsDishes,
            subtitle: s.resultsCount(results.foodItems.length),
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
                AppSpacing.xl, AppSpacing.screenHorizontal, AppSpacing.xs),
          ),
          for (var i = 0; i < results.foodItems.length; i++) ...[
            if (i > 0) divider(),
            Builder(builder: (context) {
              final f = results.foodItems[i];
              return DishResultTile(
                food: f,
                quantity: cart.quantityOf(f.restaurantId, f.id),
                onTap: () => onOpenRestaurant(f.restaurantId),
                onAdd: () => onAddDish(f),
                onRemove: () => ref
                    .read(cartNotifierProvider.notifier)
                    .decrementQuantity(f.restaurantId, f.id),
              );
            }),
          ],
        ],
      ],
    );
  }
}
