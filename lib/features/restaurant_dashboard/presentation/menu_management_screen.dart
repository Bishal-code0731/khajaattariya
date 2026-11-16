import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/s.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/error_state_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_loader.dart';
import '../application/menu_management_provider.dart';
import '../domain/models/owner_menu_item.dart';
import 'widgets/menu_item_form_page.dart';
import 'widgets/menu_item_row.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen(
      {super.key, required this.restaurantId, required this.restaurantName});

  final String restaurantId;
  final String restaurantName;

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _search = TextEditingController();
  String _query = '';

  /// Rows with a save in flight → the value being saved (optimistic).
  final _pending = <String, bool?>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() =>
      ref.invalidate(ownerMenuItemsProvider(widget.restaurantId));

  Future<void> _openForm([OwnerMenuItem? item]) async {
    final saved = await showMenuItemForm(context,
        restaurantId: widget.restaurantId, item: item);
    if (saved && mounted) _refresh();
  }

  Future<void> _setAvailable(OwnerMenuItem item, bool value) async {
    if (_pending.containsKey(item.id)) return;
    final s = context.s.restaurant;
    setState(() => _pending[item.id] = value);
    try {
      await ref.read(menuItemActionsProvider).setAvailable(item.id, value);
      _refresh();
      if (mounted) {
        AppSnackbar.success(context,
            value ? s.nowAvailable(item.name) : s.nowHidden(item.name));
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _pending.remove(item.id));
    }
  }

  Future<void> _delete(OwnerMenuItem item) async {
    if (_pending.containsKey(item.id)) return;
    final s = context.s.restaurant;
    final ok = await AppDialog.confirm(
      context,
      title: s.deleteDishTitle(item.name),
      message: s.deleteDishMessage,
      confirmLabel: context.s.common.delete,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _pending[item.id] = null);
    var inUse = false;
    try {
      await ref.read(menuItemActionsProvider).delete(item.id);
      _refresh();
      if (mounted) AppSnackbar.success(context, s.dishDeleted);
    } on MenuItemInUseException {
      inUse = true;
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _pending.remove(item.id));
    }
    if (!inUse || !mounted) return;
    // Ordered before → can't delete; offer to hide it instead.
    final hide = await AppDialog.confirm(
      context,
      title: s.dishInUseTitle,
      message: s.dishInUseMessage,
      confirmLabel: s.hideFromMenu,
      icon: Icons.visibility_off_outlined,
    );
    if (hide && mounted && item.isAvailable) await _setAvailable(item, false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s.restaurant;
    final p = context.palette;
    final itemsAsync = ref.watch(ownerMenuItemsProvider(widget.restaurantId));
    final categories =
        ref.watch(menuCategoriesProvider).valueOrNull ?? const <MenuCategory>[];
    final items = itemsAsync.valueOrNull;

    Widget body;
    if (items == null) {
      body = itemsAsync.hasError
          ? AppErrorState(error: itemsAsync.error, onRetry: _refresh)
          : const AppShimmerCardList(count: 6, itemHeight: 60);
    } else if (items.isEmpty) {
      body = AppEmptyState(
        icon: Icons.restaurant_menu_rounded,
        title: s.emptyMenuTitle,
        subtitle: s.emptyMenuBody,
        action: AppButton(
            label: s.addDish,
            leadingIcon: Icons.add_rounded,
            expand: false,
            onPressed: _openForm),
      );
    } else {
      body = _buildList(context, items, categories);
    }

    final hiddenCount = items?.where((i) => !i.isAvailable).length ?? 0;
    return Scaffold(
      appBar: AppTopBar(
        title: s.menuTitle,
        subtitle: items == null
            ? widget.restaurantName
            : [
                widget.restaurantName,
                s.dishesCount(items.length),
                if (hiddenCount > 0) s.hiddenCount(hiddenCount),
              ].join(' · '),
      ),
      floatingActionButton: (items == null || items.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: _openForm,
              backgroundColor: p.brand,
              foregroundColor: p.onBrand,
              icon: const Icon(Icons.add_rounded),
              label: Text(s.addDish),
            ),
      body: RefreshIndicator(onRefresh: () async => _refresh(), child: body),
    );
  }

  Widget _buildList(BuildContext context, List<OwnerMenuItem> items,
      List<MenuCategory> categories) {
    final s = context.s.restaurant;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? items
        : items
            .where((i) =>
                i.name.toLowerCase().contains(q) ||
                (i.description ?? '').toLowerCase().contains(q))
            .toList();

    // Group in admin category order; unknown / no category last.
    final groups = <String?, List<OwnerMenuItem>>{};
    for (final cat in categories) {
      final inCat = filtered.where((i) => i.categoryId == cat.id).toList();
      if (inCat.isNotEmpty) groups[cat.id] = inCat;
    }
    final known = categories.map((c) => c.id).toSet();
    final other = filtered.where((i) => !known.contains(i.categoryId)).toList();
    if (other.isNotEmpty) groups[null] = other;
    final names = {for (final c in categories) c.id: c.name};

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal,
              AppSpacing.md, AppSpacing.screenHorizontal, 112),
          children: [
            AppSearchField(
              hint: s.searchDishes,
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              onClear: _query.isEmpty
                  ? null
                  : () {
                      _search.clear();
                      setState(() => _query = '');
                    },
            ),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: s.noSearchResults(_query.trim()),
                    compact: true),
              ),
            for (final entry in groups.entries) ...[
              SectionHeader(
                title: entry.key == null
                    ? s.otherDishes
                    : (names[entry.key] ?? s.otherDishes),
                subtitle: s.dishesCount(entry.value.length),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.sm),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, color: context.palette.border),
                      _row(entry.value[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(OwnerMenuItem item) {
    final busy = _pending.containsKey(item.id);
    final optimistic = _pending[item.id];
    return MenuItemRow(
      key: ValueKey(item.id),
      item: item,
      isAvailable: optimistic ?? item.isAvailable,
      busy: busy,
      onToggle: (v) => _setAvailable(item, v),
      onEdit: () => _openForm(item),
      onDelete: () => _delete(item),
    );
  }
}
