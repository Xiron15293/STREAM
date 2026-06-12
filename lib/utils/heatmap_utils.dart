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

class HeatmapSettings {
  static const defaultThresholds = [1.0, 5.0, 20.0, 50.0, 150.0, 500.0];
  static const defaultColors = [
    0xFFC8E6C9, // < 1€
    0xFFA5D6A7, // 1–5€
    0xFF81C784, // 5–20€
    0xFFEF9A9A, // 20–50€
    0xFFE57373, // 50–150€
    0xFFEF5350, // 150–500€
    0xFFC62828, // > 500€
  ];

  final List<double> thresholds;
  final List<int> colors;

  const HeatmapSettings({
    this.thresholds = defaultThresholds,
    this.colors = defaultColors,
  });

  static const defaults = HeatmapSettings();

  List<({double max, String label})> get bands {
    return [
      for (var i = 0; i <= thresholds.length; i++)
        (
          max: i < thresholds.length ? thresholds[i] : double.infinity,
          label: rangeLabel(i, thresholds),
        ),
    ];
  }

  bool get isValid =>
      validateThresholds(thresholds) && colors.length == thresholds.length + 1;

  HeatmapSettings copyWith({List<double>? thresholds, List<int>? colors}) {
    return HeatmapSettings(
      thresholds: List.unmodifiable(thresholds ?? this.thresholds),
      colors: List.unmodifiable(colors ?? this.colors),
    );
  }

  static bool validateThresholds(List<double> values) {
    if (values.isEmpty) return false;
    var previous = 0.0;
    for (final value in values) {
      if (!value.isFinite || value <= 0 || value <= previous) return false;
      previous = value;
    }
    return true;
  }

  static String rangeLabel(int index, List<double> thresholds) {
    if (index == 0) return '< ${formatHeatmapAmount(thresholds.first)}';
    if (index == thresholds.length) {
      return '> ${formatHeatmapAmount(thresholds.last)}';
    }
    return '${_formatThresholdLabel(thresholds[index - 1])}–${formatHeatmapAmount(thresholds[index])}';
  }

  static String _formatThresholdLabel(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

List<({double max, String label})> get heatmapBands =>
    HeatmapSettings.defaults.bands;

int heatmapBandIndex(double amount, {HeatmapSettings? settings}) {
  if (amount <= 0) return -1;
  final bands = (settings ?? HeatmapSettings.defaults).bands;
  for (int i = 0; i < bands.length; i++) {
    if (amount <= bands[i].max) return i;
  }
  return bands.length - 1;
}

Color heatmapColorForAmount(
  double amount, {
  bool compact = false,
  HeatmapSettings? settings,
}) {
  final config = settings ?? HeatmapSettings.defaults;
  final band = heatmapBandIndex(amount, settings: config);
  if (band < 0) return compact ? Colors.transparent : const Color(0xFFF5F5F5);
  final colors = config.colors;
  return Color(colors[band.clamp(0, colors.length - 1)]);
}

String formatEuro(double value) {
  final isNegative = value < 0;
  final parts = value.abs().toStringAsFixed(2).split('.');
  final whole = parts[0];
  final cents = parts[1];
  final buffer = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write('.');
    buffer.write(whole[i]);
  }
  return '${isNegative ? '-' : ''}${buffer.toString()},$cents €';
}

String formatHeatmapAmount(double value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  if (value == value.truncateToDouble()) return '${value.toInt()}€';
  return '${value.toStringAsFixed(1)}€';
}
