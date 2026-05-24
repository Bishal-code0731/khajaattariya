class CategoryModel {
  final String id;
  final String name;
  final String emoji;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    this.imageUrl,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      imageUrl: map['image_url'] as String?,
    );
  }
}