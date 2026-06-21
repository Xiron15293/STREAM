import 'package:flutter/material.dart';
import '../../design/stream_chart_palette.dart';
import '../../design/stream_theme_extension.dart';
import '../../design/stream_theme_palette.dart';
import '../../theme.dart';

class HorizontalBarData {
  final String label;
  final double value;
  final String formattedValue;
  final Color barColor;
  final double? secondaryValue;
  final String? secondaryFormattedValue;
  final Color? secondaryColor;

  HorizontalBarData({
    required this.label,
    required this.value,
    required this.formattedValue,
    required this.barColor,
    this.secondaryValue,
    this.secondaryFormattedValue,
    this.secondaryColor,
  });
}

class StreamHorizontalBarChart extends StatelessWidget {
  final List<HorizontalBarData> bars;
  final String? legendLabel1;
  final String? legendLabel2;
  final double? barHeight;

  const StreamHorizontalBarChart({
    super.key,
    required this.bars,
    this.legendLabel1,
    this.legendLabel2,
    this.barHeight,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final cp = context.$chart;
    final resolvedBarHeight = barHeight ?? cp.horizontalBarHeight;
    if (bars.isEmpty) return const SizedBox.shrink();
    if (bars.every(
      (b) =>
          b.value == 0 && (b.secondaryValue == null || b.secondaryValue == 0),
    )) {
      return Center(
        child: Text(
          'Nessun dato',
          style: StreamTypography.caption.copyWith(color: p.textSecondary),
        ),
      );
    }

    final maxVal = bars.fold<double>(0.0, (m, b) {
      final total = (b.secondaryValue ?? 0.0).abs() > b.value.abs()
          ? (b.secondaryValue ?? 0.0).abs()
          : b.value.abs();
      return total > m ? total : m;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (legendLabel1 != null || legendLabel2 != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (legendLabel1 != null) ...[
                  _legendDot(bars.isNotEmpty ? bars.first.barColor : p.primary),
                  const SizedBox(width: 4),
                  Text(
                    legendLabel1!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cp.legendTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (legendLabel2 != null &&
                    bars.first.secondaryColor != null) ...[
                  _legendDot(bars.first.secondaryColor!),
                  const SizedBox(width: 4),
                  Text(
                    legendLabel2!,
                    style: TextStyle(
                      fontSize: 11,
                      color: cp.legendTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ...bars.map((bar) {
          final pct = maxVal > 0 ? (bar.value.abs() / maxVal) : 0.0;
          final secondaryPct = maxVal > 0 && bar.secondaryValue != null
              ? (bar.secondaryValue!.abs() / maxVal)
              : 0.0;
          return _SingleHorizontalBar(
            label: bar.label,
            value: bar.value,
            formattedValue: bar.formattedValue,
            barColor: bar.barColor,
            pct: pct,
            secondaryValue: bar.secondaryValue,
            secondaryFormattedValue: bar.secondaryFormattedValue,
            secondaryColor: bar.secondaryColor,
            secondaryPct: secondaryPct,
            barHeight: resolvedBarHeight,
            maxVal: maxVal,
            palette: p,
            chartPalette: cp,
          );
        }),
      ],
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SingleHorizontalBar extends StatelessWidget {
  final String label;
  final double value;
  final String formattedValue;
  final Color barColor;
  final double pct;
  final double? secondaryValue;
  final String? secondaryFormattedValue;
  final Color? secondaryColor;
  final double secondaryPct;
  final double barHeight;
  final double maxVal;
  final StreamThemePalette palette;
  final StreamChartPalette chartPalette;

  const _SingleHorizontalBar({
    required this.label,
    required this.value,
    required this.formattedValue,
    required this.barColor,
    required this.pct,
    this.secondaryValue,
    this.secondaryFormattedValue,
    this.secondaryColor,
    required this.secondaryPct,
    required this.barHeight,
    required this.maxVal,
    required this.palette,
    required this.chartPalette,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: palette.textSecondary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barMaxWidth = constraints.maxWidth;
                return SizedBox(
                  height: barHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: chartPalette.horizontalTrackColor,
                            borderRadius: BorderRadius.circular(
                              chartPalette.horizontalBarRadius,
                            ),
                          ),
                        ),
                      ),
                      if (secondaryValue != null && secondaryColor != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: barMaxWidth * secondaryPct.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(
                                chartPalette.horizontalBarRadius,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: barMaxWidth * pct.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(
                              chartPalette.horizontalBarRadius,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              formattedValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
