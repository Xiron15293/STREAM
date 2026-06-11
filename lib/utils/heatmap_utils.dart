import 'package:flutter/material.dart';
import '../models/movement.dart';

double dailyExpenseTotal(DateTime date, List<Movement> movements) {
  return movements.fold<double>(0.0, (sum, m) {
    if (m.isTransfer) return sum;
    if (!m.isExpense) return sum;
    if (m.date.year != date.year ||
        m.date.month != date.month ||
        m.date.day != date.day) {
      return sum;
    }
    return sum + m.amount;
  });
}

double dayIncomeTotal(DateTime date, List<Movement> movements) {
  return movements.fold<double>(0.0, (sum, m) {
    if (m.isTransfer) return sum;
    if (!m.isIncome) return sum;
    if (m.date.year != date.year ||
        m.date.month != date.month ||
        m.date.day != date.day) {
      return sum;
    }
    return sum + m.amount;
  });
}

double dayExpenseTotal(DateTime date, List<Movement> movements) {
  return dailyExpenseTotal(date, movements);
}

double dayBalance(DateTime date, List<Movement> movements) {
  return dayIncomeTotal(date, movements) - dayExpenseTotal(date, movements);
}

int dayMovementCount(DateTime date, List<Movement> movements) {
  return movements
      .where(
        (m) =>
            m.date.year == date.year &&
            m.date.month == date.month &&
            m.date.day == date.day,
      )
      .length;
}

List<Movement> movementsForDay(DateTime date, List<Movement> movements) {
  return movements
      .where(
        (m) =>
            m.date.year == date.year &&
            m.date.month == date.month &&
            m.date.day == date.day,
      )
      .toList();
}

Map<int, double> dailyExpenseTotals(
  int year,
  int month,
  List<Movement> movements,
) {
  final result = <int, double>{};
  for (final m in movements) {
    if (m.isTransfer) continue;
    if (!m.isExpense) continue;
    if (m.date.year == year && m.date.month == month) {
      result.update(m.date.day, (v) => v + m.amount, ifAbsent: () => m.amount);
    }
  }
  return result;
}

const heatmapBands = [
  (max: 1.0, label: '< 1€'),
  (max: 5.0, label: '1–5€'),
  (max: 20.0, label: '5–20€'),
  (max: 50.0, label: '20–50€'),
  (max: 150.0, label: '50–150€'),
  (max: 500.0, label: '150–500€'),
  (max: double.infinity, label: '> 500€'),
];

int heatmapBandIndex(double amount) {
  if (amount <= 0) return -1;
  for (int i = 0; i < heatmapBands.length; i++) {
    if (amount <= heatmapBands[i].max) return i;
  }
  return heatmapBands.length - 1;
}

Color heatmapColorForAmount(double amount, {bool compact = false}) {
  final band = heatmapBandIndex(amount);
  if (band < 0) return compact ? Colors.transparent : const Color(0xFFF5F5F5);
  final colors = [
    const Color(0xFFC8E6C9), // < 1€
    const Color(0xFFA5D6A7), // 1–5€
    const Color(0xFF81C784), // 5–20€
    const Color(0xFFEF9A9A), // 20–50€
    const Color(0xFFE57373), // 50–150€
    const Color(0xFFEF5350), // 150–500€
    const Color(0xFFC62828), // > 500€
  ];
  return colors[band.clamp(0, colors.length - 1)];
}

String formatHeatmapAmount(double value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  if (value == value.truncateToDouble()) return '${value.toInt()}€';
  return '${value.toStringAsFixed(1)}€';
}
