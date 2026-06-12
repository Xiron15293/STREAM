class Subcategory {
  final String id;
  final String categoryId;
  final String name;
  final String? iconKey;
  final int? color;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.iconKey,
    this.color,
    this.archived = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;
}
