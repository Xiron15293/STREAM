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
  final String? destinationAccountId;
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
    this.destinationAccountId,
    this.note,
    required this.createdAt,
    DateTime? updatedAt,
  }) : accountId = accountId ?? defaultAccountId,
       updatedAt = updatedAt ?? createdAt;

  /// Orders by updatedAt desc → createdAt desc → id asc.
  /// categoryId, type, amount, title do NOT affect order.
  int compareForDisplay(Movement other) =>
      compareMovementsForDisplay(this, other);

  bool get isIncome => type == MovementType.income;
  bool get isExpense => type == MovementType.expense;
  bool get isTransfer => type == MovementType.transfer;

  Movement copyWith({
    String? id,
    String? title,
    double? amount,
    MovementType? type,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? destinationAccountId,
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
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double impactForAccount(String accountId) {
    switch (type) {
      case MovementType.income:
        return this.accountId == accountId ? amount : 0.0;
      case MovementType.expense:
        return this.accountId == accountId ? -amount : 0.0;
      case MovementType.transfer:
        double impact = 0.0;
        if (this.accountId == accountId) impact -= amount;
        if (destinationAccountId == accountId) impact += amount;
        return impact;
    }
  }
}

double sumIncome(Iterable<Movement> movements) {
  return movements
      .where((m) => m.isIncome)
      .fold<double>(0.0, (sum, m) => sum + m.amount);
}

double sumExpenses(Iterable<Movement> movements) {
  return movements
      .where((m) => m.isExpense)
      .fold<double>(0.0, (sum, m) => sum + m.amount);
}

double sumTransfers(Iterable<Movement> movements) {
  return movements
      .where((m) => m.isTransfer)
      .fold<double>(0.0, (sum, m) => sum + m.amount);
}

double netIncomeExpense(Iterable<Movement> movements) {
  return sumIncome(movements) - sumExpenses(movements);
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
