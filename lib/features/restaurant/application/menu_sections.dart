import '../../home/domain/models/food_item_model.dart';

/// One titled block of the restaurant menu ("Momo", "Drinks", …).
class MenuSection {
  const MenuSection(
      {required this.id, required this.title, required this.items});

  /// Category id, or [uncategorisedId] for dishes without a category.
  final String id;
  final String title;
  final List<FoodItemModel> items;

  static const uncategorisedId = '_more';
}

/// Groups [items] by category, keeping the menu's own order (sort_order) for both sections and dishes.
List<MenuSection> buildMenuSections(
  List<FoodItemModel> items, {
  required Map<String, String> categoryNames,
  required String moreTitle,
  bool vegOnly = false,
}) {
  final order = <String>[];
  final byId = <String, List<FoodItemModel>>{};
  for (final item in items) {
    if (vegOnly && !item.isVeg) continue;
    final known =
        item.categoryId != null && categoryNames.containsKey(item.categoryId);
    final id = known ? item.categoryId! : MenuSection.uncategorisedId;
    if (!byId.containsKey(id)) {
      byId[id] = [];
      if (id != MenuSection.uncategorisedId) order.add(id);
    }
    byId[id]!.add(item);
  }
  if (byId.containsKey(MenuSection.uncategorisedId)) {
    order.add(MenuSection.uncategorisedId);
  }

  return [
    for (final id in order)
      MenuSection(
        id: id,
        title:
            id == MenuSection.uncategorisedId ? moreTitle : categoryNames[id]!,
        items: byId[id]!,
      ),
  ];
}
