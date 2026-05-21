// A Category is one food type shown in the horizontal scroll.
// For example: Momo, Thali, Chowmein, Pizza, Burger.
// Every category has an id, name, and an emoji icon.

class CategoryModel {
  final String id;
  final String name;
  final String emoji;    // We use emoji for now, real icons later
  final String? imageUrl; // Optional — for when we have real images

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.imageUrl,
  });
}