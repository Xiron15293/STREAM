import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../utils/analytics_metrics.dart';

class StreamDonutChart extends StatelessWidget {
  final List<DonutSlice> slices;

  const StreamDonutChart({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Center(
        child: Text(
          'Nessun dato',
          style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
        ),
      );
    }

    final total = slices.fold<double>(0.0, (s, sl) => s + sl.value);
    if (total == 0) {
      return Center(
        child: Text(
          'Nessun dato',
          style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
        ),
      );
    }

    final spent = slices.where((s) => s.value > 0).toList();
    if (spent.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: spent.map((s) {
                final pct = (s.value / total * 100);
                return PieChartSectionData(
                  value: s.value,
                  title: '${pct.toStringAsFixed(1)}%',
                  color: s.color,
                  radius: 50,
                  titleStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: StreamSpacing.md),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: spent.map((s) {
              final pct = (s.value / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.label,
                        style: TextStyle(fontSize: 11, color: StreamColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, color: StreamColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
