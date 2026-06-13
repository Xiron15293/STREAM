import '../models/movement.dart';
import '../models/time_filter.dart';

class MovementPeriodMetrics {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final int movementCount;

  const MovementPeriodMetrics({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.movementCount,
  });

  factory MovementPeriodMetrics.fromMovements(Iterable<Movement> movements) {
    double income = 0;
    double expense = 0;
    int count = 0;

    for (final movement in movements) {
      count += 1;
      if (movement.isTransfer) continue;
      if (movement.isIncome) {
        income += movement.amount;
      } else if (movement.isExpense) {
        expense += movement.amount;
      }
    }

    return MovementPeriodMetrics(
      totalIncome: income,
      totalExpense: expense,
      netBalance: income - expense,
      movementCount: count,
    );
  }
}

String formatTimeFilterTitle(TimeFilter filter) {
  switch (filter.mode) {
    case TimeFilterMode.day:
      return _formatFullDate(filter.startDate);
    case TimeFilterMode.week:
      return filter.label;
    case TimeFilterMode.month:
      return '${_capitalize(_monthName(filter.startDate.month))} ${filter.startDate.year}';
    case TimeFilterMode.year:
      return '${filter.startDate.year}';
    case TimeFilterMode.customRange:
      return '${_formatShortDate(filter.startDate)} – ${_formatShortDate(filter.endDate)}';
  }
}

String timeFilterPeriodLabel(TimeFilterMode mode) {
  switch (mode) {
    case TimeFilterMode.day:
      return 'giorno';
    case TimeFilterMode.week:
      return 'settimana';
    case TimeFilterMode.month:
      return 'mese';
    case TimeFilterMode.year:
      return 'anno';
    case TimeFilterMode.customRange:
      return 'intervallo';
  }
}

List<DateTime> monthsCoveredByFilter(TimeFilter filter) {
  final months = <DateTime>[];
  var cursor = DateTime(filter.startDate.year, filter.startDate.month, 1);
  final end = DateTime(filter.endDate.year, filter.endDate.month, 1);
  while (!cursor.isAfter(end)) {
    months.add(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  return months;
}

String _formatFullDate(DateTime date) {
  return '${date.day} ${_monthName(date.month)} ${date.year}';
}

String _formatShortDate(DateTime date) {
  return '${date.day} ${_shortMonthName(date.month)} ${date.year}';
}

String _monthName(int month) => _monthNames[month - 1];

String _shortMonthName(int month) => _shortMonthNames[month - 1];

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

const _monthNames = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

const _shortMonthNames = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];
