/// A dish as its restaurant owner manages it (hidden items included).
class OwnerMenuItem {
  const OwnerMenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isVeg,
    required this.isAvailable,
    this.description,
    this.imageUrl,
    this.offer,
    this.categoryId,
  });

  final String id;
  final String name;
  final double price;
  final bool isVeg;
  final bool isAvailable;
  final String? description;
  final String? imageUrl;
  final String? offer;
  final String? categoryId;

  factory OwnerMenuItem.fromMap(Map<String, dynamic> map) {
    return OwnerMenuItem(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      isVeg: map['is_veg'] as bool? ?? false,
      isAvailable: map['is_available'] as bool? ?? true,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      offer: map['offer'] as String?,
      categoryId: map['category_id'] as String?,
    );
  }
}

/// Values from the add / edit dish form.
class MenuItemInput {
  const MenuItemInput({
    required this.name,
    required this.price,
    required this.isVeg,
    this.description,
    this.imageUrl,
    this.offer,
    this.categoryId,
  });

  final String name;
  final double price;
  final bool isVeg;
  final String? description;
  final String? imageUrl;
  final String? offer;
  final String? categoryId;

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'is_veg': isVeg,
        'description': description,
        'image_url': imageUrl,
        'offer': offer,
        'category_id': categoryId,
      };
}

/// Admin-managed food category (read-only for owners).
class MenuCategory {
  const MenuCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory MenuCategory.fromMap(Map<String, dynamic> map) =>
      MenuCategory(id: map['id'] as String, name: map['name'] as String? ?? '');
}
