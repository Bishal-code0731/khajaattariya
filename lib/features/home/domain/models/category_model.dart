class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? iconEmoji;
  final bool isActive;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.iconEmoji,
    required this.isActive,
    required this.sortOrder,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      // The categories table has no image_url column — imageUrl stays
      // null until/unless that's added; the real per-category visual is
      // the emoji column below.
      imageUrl: map['image_url'] as String?,
      // Was reading 'icon_emoji', a column that doesn't exist in the
      // live schema (the actual column is just 'emoji') — every
      // category silently fell back to the default 🍽️ regardless of
      // what was actually set in the database.
      iconEmoji: map['emoji'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
