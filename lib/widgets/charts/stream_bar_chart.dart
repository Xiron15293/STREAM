import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../theme.dart';
import '../../utils/analytics_metrics.dart';

class StreamBarChart extends StatelessWidget {
  final List<ChartSeries> series;
  final bool stacked;

  const StreamBarChart({super.key, required this.series, this.stacked = false});

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

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
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
                if (value == 0) return const SizedBox.shrink();
                return Text('${value.toInt()}',
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
          horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(color: cp.gridColor, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(allLabels.length, (i) {
          final rods = series.asMap().entries.map((e) {
            final point = e.value.points.where((p) => p.label == allLabels[i]).firstOrNull;
            return BarChartRodData(
              toY: point?.value ?? 0.0,
              color: e.value.color,
              width: series.length > 1 ? 8 : 14,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
            );
          }).toList();
          return BarChartGroupData(x: i, barRods: rods);
        }),
      ),
    );
  }
}
