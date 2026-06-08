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
    final d = DateTime(m.date.year, m.date.month, m.date.day);
    final key = '${d.year}-${d.month}-${d.day}';
    map.putIfAbsent(key, () => []).add(m);
  }

  final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));

  final result = <DailyMovementGroup>[];
  for (final key in keys) {
    final parts = key.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final dayMovements = map[key]!;
    dayMovements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    result.add(DailyMovementGroup(date: date, movements: dayMovements));
  }
  return result;
}
