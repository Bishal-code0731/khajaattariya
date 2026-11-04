class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String? iconEmoji;

  /// Optional icon key (`icon_name` column) mapped to a Material icon in the UI.
  final String? iconName;
  final bool isActive;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.iconEmoji,
    this.iconName,
    required this.isActive,
    required this.sortOrder,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: map['image_url'] as String?,
      iconEmoji: map['emoji'] as String?,
      iconName: map['icon_name'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
