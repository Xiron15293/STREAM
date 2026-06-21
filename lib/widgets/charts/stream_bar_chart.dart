import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../theme.dart';
import '../../utils/analytics_metrics.dart';

class StreamBarChart extends StatelessWidget {
  final List<ChartSeries> series;
  final bool stacked;
  final bool currencyAxis;

  const StreamBarChart({
    super.key,
    required this.series,
    this.stacked = false,
    this.currencyAxis = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final cp = context.$chart;
    if (series.isEmpty) return const SizedBox.shrink();
    if (series.every((s) => s.points.every((p) => p.value == 0))) {
      return Center(child: Text('Nessun dato', style: StreamTypography.caption.copyWith(color: p.textSecondary)));
    }

    final allLabels = series.expand((s) => s.points.map((p) => p.label)).toSet().toList();
    final maxVal = series
        .expand((s) => s.points.map((p) => p.value.abs()))
        .reduce((a, b) => a > b ? a : b);

    if (allLabels.isEmpty) return const SizedBox.shrink();

    final chartMaxY = _chartMaxY(maxVal);
    final interval = _axisInterval(chartMaxY);
    final tickValues = _tickValues(chartMaxY, interval);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        minY: 0,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= allLabels.length) return const SizedBox.shrink();
                final label = allLabels[i];
                final show = allLabels.length > 15 ? i % 3 == 0 : true;
                if (!show) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                    style: TextStyle(fontSize: 9, color: cp.axisTextColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                final showTick = tickValues.any(
                  (tick) => (tick - value).abs() < 0.001,
                );
                if (!showTick || value <= 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _formatAxisValue(value),
                  style: TextStyle(fontSize: 9, color: cp.axisTextColor),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(color: cp.gridColor, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(allLabels.length, (i) {
          final rods = series.asMap().entries.map((e) {
            final point = e.value.points.where((p) => p.label == allLabels[i]).firstOrNull;
            return BarChartRodData(
              toY: point?.value ?? 0.0,
              color: e.value.color,
              width: series.length > 1 ? cp.groupedBarWidth : cp.singleBarWidth,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(cp.barTopRadius),
                topRight: Radius.circular(cp.barTopRadius),
              ),
            );
          }).toList();
          return BarChartGroupData(x: i, barRods: rods);
        }),
      ),
    );
  }

  double _chartMaxY(double maxVal) {
    if (maxVal <= 0) return 4;
    final padded = maxVal * 1.2;
    return padded == maxVal ? maxVal + 1 : padded;
  }

  double _axisInterval(double maxY) {
    if (maxY <= 0) return 1;
    final raw = maxY / 4;
    final magnitude = _pow10(raw);
    final normalized = raw / magnitude;
    final nice = normalized <= 1
        ? 1.0
        : normalized <= 2
        ? 2.0
        : normalized <= 5
        ? 5.0
        : 10.0;
    return nice * magnitude;
  }

  List<double> _tickValues(double maxY, double interval) {
    final ticks = <double>{};
    if (interval <= 0) return const [];
    for (double value = interval; value <= maxY + 0.001; value += interval) {
      ticks.add(double.parse(value.toStringAsFixed(6)));
    }
    return ticks.toList()..sort();
  }

  double _pow10(double value) {
    if (value <= 0) return 1;
    var magnitude = 1.0;
    while (value >= 10) {
      value /= 10;
      magnitude *= 10;
    }
    while (value < 1) {
      value *= 10;
      magnitude /= 10;
    }
    return magnitude;
  }

  String _formatAxisValue(double value) {
    if (currencyAxis) {
      final rounded = value.abs() >= 100
          ? value.toStringAsFixed(0)
          : value % 1 == 0
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
      return '€$rounded';
    }
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }
}
