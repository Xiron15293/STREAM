import 'category.dart';
import 'account.dart';

class Movement {
  final String id;
  final String title;
  final double amount;
  final MovementType type;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Movement({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.categoryId,
    String? accountId,
    this.note,
    required this.createdAt,
    DateTime? updatedAt,
  })  : accountId = accountId ?? defaultAccountId,
        updatedAt = updatedAt ?? createdAt;

  /// Orders by updatedAt desc → createdAt desc → id asc.
  /// categoryId, type, amount, title do NOT affect order.
  int compareForDisplay(Movement other) => compareMovementsForDisplay(this, other);

  Movement copyWith({
    String? id,
    String? title,
    double? amount,
    MovementType? type,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Movement(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Shared comparator for all Movement display lists.
/// Orders by updatedAt desc → createdAt desc → id asc.
/// categoryId, type, amount, title do NOT affect order.
int compareMovementsForDisplay(Movement a, Movement b) {
  final updatedCmp = b.updatedAt.compareTo(a.updatedAt);
  if (updatedCmp != 0) return updatedCmp;
  final createdCmp = b.createdAt.compareTo(a.createdAt);
  if (createdCmp != 0) return createdCmp;
  return a.id.compareTo(b.id);
}
