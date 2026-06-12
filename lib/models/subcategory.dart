class Subcategory {
  final String id;
  final String categoryId;
  final String name;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.archived = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;
}
