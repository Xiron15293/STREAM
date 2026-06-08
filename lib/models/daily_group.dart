import 'movement.dart';
import 'category.dart';

class DailyMovementGroup {
  final DateTime date;
  final List<Movement> movements;

  DailyMovementGroup({required this.date, required this.movements});

  double get totalIncome {
    double sum = 0;
    for (final m in movements) {
      if (m.type == MovementType.income) sum += m.amount;
    }
    return sum;
  }

  double get totalExpenses {
    double sum = 0;
    for (final m in movements) {
      if (m.type == MovementType.expense) sum += m.amount;
    }
    return sum;
  }

  double get balance => totalIncome - totalExpenses;
}

List<DailyMovementGroup> groupMovementsByDay(List<Movement> movements) {
  if (movements.isEmpty) return [];

  final map = <String, List<Movement>>{};
  for (final m in movements) {
    final key = '${m.date.year}-${m.date.month}-${m.date.day}';
    map.putIfAbsent(key, () => []).add(m);
  }

  final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));

  final result = <DailyMovementGroup>[];
  for (final key in keys) {
    final dayMovements = map[key]!;
    final first = dayMovements.first;
    final date = DateTime(first.date.year, first.date.month, first.date.day);
    dayMovements.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    result.add(DailyMovementGroup(date: date, movements: dayMovements));
  }
  return result;
}
