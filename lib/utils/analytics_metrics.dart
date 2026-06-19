import 'package:flutter/material.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/time_filter.dart';
import '../data/database.dart';
import '../theme.dart';

class ChartPoint {
  final String label;
  final double value;
  final Color color;

  const ChartPoint({required this.label, required this.value, required this.color});
}

class ChartSeries {
  final String label;
  final List<ChartPoint> points;
  final Color color;

  const ChartSeries({required this.label, required this.points, required this.color});
}

class DonutSlice {
  final String label;
  final double value;
  final Color color;

  const DonutSlice({required this.label, required this.value, required this.color});
}

const _chartColors = [
  StreamColors.primary,
  Color(0xFF34C759),
  Color(0xFFFF453A),
  Color(0xFFFFD60A),
  Color(0xFF5AC8FA),
  Color(0xFFAF52DE),
  Color(0xFFFF9500),
  Color(0xFFFF2D55),
  Color(0xFF5856D6),
  Color(0xFF00C7BE),
];

List<MapEntry<String, double>> _maybeAddAltro(
  List<MapEntry<String, double>> sorted,
  List<MapEntry<String, double>> top,
) {
  if (sorted.length <= top.length) return sorted;
  final other = sorted.skip(top.length).fold<double>(0.0, (s, e) => s + e.value);
  return [...top, MapEntry('Altro', other)];
}

List<DateTime> _daysInRange(DateTime start, DateTime end) {
  final days = <DateTime>[];
  var d = DateTime(start.year, start.month, start.day);
  final e = DateTime(end.year, end.month, end.day);
  while (!d.isAfter(e)) {
    days.add(d);
    d = d.add(const Duration(days: 1));
  }
  return days;
}

int _daysBetween(DateTime a, DateTime b) {
  return DateTime(b.year, b.month, b.day)
      .difference(DateTime(a.year, a.month, a.day))
      .inDays
      .abs();
}

List<ChartSeries> buildMovementCashflowSeries(
  List<Movement> movements,
  TimeFilter filter,
) {
  final filtered = movements.filterByTime(filter);
  final income = <String, double>{};
  final expense = <String, double>{};
  final labels = <String>[];
  final int totalDays = _daysBetween(filter.startDate, filter.endDate) + 1;

  if (totalDays <= 62) {
    final days = _daysInRange(filter.startDate, filter.endDate);
    for (final d in days) {
      final key = '${d.day}/${d.month}';
      labels.add(key);
      income[key] = 0.0;
      expense[key] = 0.0;
    }
    for (final m in filtered) {
      final key = '${m.date.day}/${m.date.month}';
      if (m.isIncome) income[key] = (income[key] ?? 0.0) + m.amount;
      if (m.isExpense) expense[key] = (expense[key] ?? 0.0) + m.amount;
    }
  } else {
    final months = <String>{};
    for (final m in filtered) {
      months.add('${m.date.month}/${m.date.year}');
    }
    final sorted = months.toList()..sort();
    for (final key in sorted) {
      labels.add(key);
      income[key] = 0.0;
      expense[key] = 0.0;
    }
    for (final m in filtered) {
      final key = '${m.date.month}/${m.date.year}';
      if (m.isIncome) income[key] = (income[key] ?? 0.0) + m.amount;
      if (m.isExpense) expense[key] = (expense[key] ?? 0.0) + m.amount;
    }
    if (labels.isEmpty) {
      final startLabel = '${filter.startDate.month}/${filter.startDate.year}';
      labels.add(startLabel);
      income[startLabel] = 0.0;
      expense[startLabel] = 0.0;
    }
  }

  if (labels.isEmpty) return [];
  final hasData = income.values.any((v) => v > 0) || expense.values.any((v) => v > 0);
  if (!hasData) return [];

  return [
    ChartSeries(
      label: 'Entrate',
      points: labels
          .map((l) => ChartPoint(label: l, value: income[l] ?? 0.0, color: StreamColors.income))
          .toList(),
      color: StreamColors.income,
    ),
    ChartSeries(
      label: 'Uscite',
      points: labels
          .map((l) => ChartPoint(label: l, value: expense[l] ?? 0.0, color: StreamColors.expense))
          .toList(),
      color: StreamColors.expense,
    ),
  ];
}

List<ChartSeries> buildMovementCountByDay(List<Movement> movements, TimeFilter filter) {
  final filtered = movements.filterByTime(filter);
  final days = _daysInRange(filter.startDate, filter.endDate);
  final counts = <String, int>{};
  for (final d in days) {
    counts['${d.day}/${d.month}'] = 0;
  }
  for (final m in filtered) {
    final key = '${m.date.day}/${m.date.month}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final labels = days.map((d) => '${d.day}/${d.month}').toList();
  return [
    ChartSeries(
      label: 'Movimenti',
      points: labels
          .map((l) => ChartPoint(label: l, value: counts[l]!.toDouble(), color: StreamColors.primary))
          .toList(),
      color: StreamColors.primary,
    ),
  ];
}

List<DonutSlice> buildMovementTypeBreakdown(List<Movement> movements, TimeFilter filter) {
  final filtered = movements.filterByTime(filter);
  double income = 0, expense = 0, transfer = 0;
  for (final m in filtered) {
    if (m.isIncome) income += m.amount;
    if (m.isExpense) expense += m.amount;
    if (m.isTransfer) transfer += m.amount;
  }
  final slices = <DonutSlice>[];
  if (income > 0) slices.add(DonutSlice(label: 'Entrate', value: income, color: StreamColors.income));
  if (expense > 0) slices.add(DonutSlice(label: 'Uscite', value: expense, color: StreamColors.expense));
  if (transfer > 0) slices.add(DonutSlice(label: 'Trasferimenti', value: transfer, color: StreamColors.neutral));
  return slices;
}

List<ChartSeries> buildTopSpendingDays(List<Movement> movements, TimeFilter filter) {
  final filtered = movements.filterByTime(filter).where((m) => m.isExpense).toList();
  final byDay = <String, double>{};
  for (final m in filtered) {
    final key = '${m.date.day}/${m.date.month}';
    byDay[key] = (byDay[key] ?? 0.0) + m.amount;
  }
  final sorted = byDay.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.take(7).toList();
  if (top.isEmpty) return [];
  final entries = _maybeAddAltro(sorted, top);
  return [
    ChartSeries(
      label: 'Spesa',
      points: entries
          .asMap()
          .entries
          .map((e) => ChartPoint(
                label: e.value.key,
                value: e.value.value,
                color: _chartColors[e.key % _chartColors.length],
              ))
          .toList(),
      color: StreamColors.expense,
    ),
  ];
}

List<ChartSeries> buildCategoryTopSeries(
  List<Movement> movements,
  List<Category> categories,
  TimeFilter filter,
  MovementType? typeFilter,
) {
  final filtered = movements.filterByTime(filter).where((m) => !m.isTransfer).toList();
  final byCategory = <String, double>{};
  for (final m in filtered) {
    if (typeFilter != null && m.type != typeFilter) continue;
    final cat = categories.where((c) => c.id == m.categoryId).firstOrNull;
    final name = cat?.name ?? m.categoryId;
    byCategory[name] = (byCategory[name] ?? 0.0) + m.amount;
  }
  final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.take(7).toList();
  if (top.isEmpty) return [];
  final entries = _maybeAddAltro(sorted, top);
  return [
    ChartSeries(
      label: typeFilter == MovementType.income ? 'Entrate' : 'Spese',
      points: entries
          .asMap()
          .entries
          .map((e) => ChartPoint(
                label: e.value.key,
                value: e.value.value,
                color: _chartColors[e.key % _chartColors.length],
              ))
          .toList(),
      color: typeFilter == MovementType.income ? StreamColors.income : StreamColors.expense,
    ),
  ];
}

List<DonutSlice> buildCategoryComposition(
  List<Movement> movements,
  List<Category> categories,
  TimeFilter filter,
  MovementType? typeFilter,
) {
  final filtered = movements.filterByTime(filter).where((m) => !m.isTransfer).toList();
  final byCategory = <String, double>{};
  for (final m in filtered) {
    if (typeFilter != null && m.type != typeFilter) continue;
    final cat = categories.where((c) => c.id == m.categoryId).firstOrNull;
    final name = cat?.name ?? m.categoryId;
    byCategory[name] = (byCategory[name] ?? 0.0) + m.amount;
  }
  final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  if (sorted.isEmpty) return [];

  final List<MapEntry<String, double>> slices;
  if (sorted.length > 7) {
    final top = sorted.take(6).toList();
    final otherTotal = sorted.skip(6).fold<double>(0.0, (s, e) => s + e.value);
    slices = [...top, MapEntry('Altro', otherTotal)];
  } else {
    slices = sorted;
  }

  return slices
      .asMap()
      .entries
      .map((e) => DonutSlice(
            label: e.value.key,
            value: e.value.value,
            color: _chartColors[e.key % _chartColors.length],
          ))
      .toList();
}

List<ChartPoint> buildAccountBalanceSeries(
  List<Account> accounts,
  AppDatabase db,
) {
  final active = accounts.where((a) => !a.archived).toList();
  if (active.isEmpty) return [];
  return active.asMap().entries.map((e) {
    final a = e.value;
    final balance = db.getAccountBalance(a);
    return ChartPoint(
      label: a.name,
      value: balance,
      color: Color(a.color),
    );
  }).toList();
}

List<ChartSeries> buildAccountFlowSeries(
  List<Movement> movements,
  List<Account> accounts,
  TimeFilter filter,
) {
  final filtered = movements.filterByTime(filter);
  final active = accounts.where((a) => !a.archived).toList();
  final income = <String, double>{};
  final expense = <String, double>{};
  for (final a in active) {
    income[a.id] = 0.0;
    expense[a.id] = 0.0;
  }
  for (final m in filtered) {
    if (m.isIncome) income[m.accountId] = (income[m.accountId] ?? 0.0) + m.amount;
    if (m.isExpense) expense[m.accountId] = (expense[m.accountId] ?? 0.0) + m.amount;
  }
  if (active.isEmpty) return [];
  return [
    ChartSeries(
      label: 'Entrate',
      points: active
          .map((a) => ChartPoint(label: a.name, value: income[a.id] ?? 0.0, color: StreamColors.income))
          .toList(),
      color: StreamColors.income,
    ),
    ChartSeries(
      label: 'Uscite',
      points: active
          .map((a) => ChartPoint(label: a.name, value: expense[a.id] ?? 0.0, color: StreamColors.expense))
          .toList(),
      color: StreamColors.expense,
    ),
  ];
}

List<ChartSeries> buildAccountActivitySeries(
  List<Movement> movements,
  List<Account> accounts,
  TimeFilter filter,
) {
  final filtered = movements.filterByTime(filter);
  final active = accounts.where((a) => !a.archived).toList();
  final counts = <String, int>{};
  for (final a in active) {
    counts[a.id] = 0;
  }
  for (final m in filtered) {
    counts[m.accountId] = (counts[m.accountId] ?? 0) + 1;
    if (m.destinationAccountId != null) {
      counts[m.destinationAccountId!] = (counts[m.destinationAccountId!] ?? 0) + 1;
    }
  }
  final series = active.map((a) {
    return ChartPoint(
      label: a.name,
      value: (counts[a.id] ?? 0).toDouble(),
      color: Color(a.color),
    );
  }).toList();
  if (series.isEmpty) return [];
  return [
    ChartSeries(
      label: 'Movimenti',
      points: series,
      color: StreamColors.primary,
    ),
  ];
}

List<ChartSeries> buildBeneficiaryTopSeries(
  List<Movement> movements,
  TimeFilter filter,
) {
  final filtered = movements.filterByTime(filter).where((m) => !m.isTransfer).toList();
  final byPayee = <String, double>{};
  for (final m in filtered) {
    if (m.payee == null || m.payee!.trim().isEmpty) continue;
    byPayee[m.payee!] = (byPayee[m.payee!] ?? 0.0) + m.amount;
  }
  final sorted = byPayee.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.take(7).toList();
  if (top.isEmpty) return [];
  final entries = _maybeAddAltro(sorted, top);
  return [
    ChartSeries(
      label: 'Importo',
      points: entries
          .asMap()
          .entries
          .map((e) => ChartPoint(
                label: e.value.key,
                value: e.value.value,
                color: _chartColors[e.key % _chartColors.length],
              ))
          .toList(),
      color: StreamColors.primary,
    ),
  ];
}

List<ChartSeries> buildBeneficiaryFrequencySeries(
  List<Movement> movements,
  TimeFilter filter,
) {
  final filtered = movements.filterByTime(filter).where((m) => !m.isTransfer).toList();
  final byPayee = <String, int>{};
  for (final m in filtered) {
    if (m.payee == null || m.payee!.trim().isEmpty) continue;
    byPayee[m.payee!] = (byPayee[m.payee!] ?? 0) + 1;
  }
  final sorted = byPayee.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.take(7).toList();
  if (top.isEmpty) return [];
  final entries = _maybeAddAltro(sorted.map((e) => MapEntry(e.key, e.value.toDouble())).toList(),
      top.map((e) => MapEntry(e.key, e.value.toDouble())).toList());
  return [
    ChartSeries(
      label: 'Frequenza',
      points: entries
          .asMap()
          .entries
          .map((e) => ChartPoint(
                label: e.value.key,
                value: e.value.value,
                color: _chartColors[e.key % _chartColors.length],
              ))
          .toList(),
      color: StreamColors.primary,
    ),
  ];
}
