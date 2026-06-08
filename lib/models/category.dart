import '../design/stream_icon_library.dart';

enum MovementType { income, expense, transfer }

class Category {
  final String id;
  final String name;
  final MovementType type;
  final int color;
  final String iconKey;
  final bool archived;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.iconKey = StreamIconLibrary.defaultCategoryIcon,
    this.archived = false,
  });
}
