import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../theme.dart';
import '../../utils/analytics_metrics.dart';
import '../../utils/currency_formatter.dart';

/// Minimum slice percentage that gets an external label with leader line.
/// Smaller slices are shown only in the legend.
const _minExternalLabelPercent = 4.0;

class StreamDonutChart extends StatelessWidget {
  final List<DonutSlice> slices;

  const StreamDonutChart({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    if (slices.isEmpty) {
      return Center(child: Text('Nessun dato', style: StreamTypography.caption.copyWith(color: p.textSecondary)));
    }

    final total = slices.fold<double>(0.0, (s, sl) => s + sl.value);
    if (total == 0) {
      return Center(child: Text('Nessun dato', style: StreamTypography.caption.copyWith(color: p.textSecondary)));
    }

    final spent = slices.where((s) => s.value > 0).toList();
    if (spent.isEmpty) return const SizedBox.shrink();

    const centerRadius = 30.0;
    const outerRadius = 52.0;
    const labelDistance = 74.0;

    List<_SliceLabel> labels = [];
    double currentAngle = -math.pi / 2;
    for (final s in spent) {
      final sweep = (s.value / total) * 2 * math.pi;
      final midAngle = currentAngle + sweep / 2;
      final pct = (s.value / total * 100);
      labels.add(_SliceLabel(
        text: '${pct.toStringAsFixed(0)}%',
        angle: midAngle,
        color: s.color,
        pct: pct,
      ));
      currentAngle += sweep;
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: spent.map((s) => PieChartSectionData(
                      value: s.value,
                      color: s.color,
                      radius: outerRadius,
                      title: '',
                    )).toList(),
                    centerSpaceRadius: centerRadius,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatMovementCurrency(total, showPositiveSign: false),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textPrimary),
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                    ),
                    Text('Totale', style: TextStyle(fontSize: 8, color: p.textSecondary)),
                  ],
                ),
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _LeaderLinePainter(
                    labels: labels,
                    center: const Offset(90, 90),
                    outerRadius: outerRadius,
                    labelDistance: labelDistance,
                    dotColor: p.textSecondary,
                    lineColor: p.textSecondary.withValues(alpha: 0.4),
                    labelColor: p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: StreamSpacing.sm),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: spent.map((s) {
              final pct = (s.value / total * 100);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(s.label,
                            style: TextStyle(fontSize: 10, color: p.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${pct.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 10, color: p.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(formatMovementCurrency(s.value, showPositiveSign: false),
                        style: TextStyle(fontSize: 9, color: p.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _SliceLabel {
  final String text;
  final double angle;
  final Color color;
  final double pct;
  const _SliceLabel({required this.text, required this.angle, required this.color, required this.pct});
}

class _LeaderLinePainter extends CustomPainter {
  final List<_SliceLabel> labels;
  final Offset center;
  final double outerRadius;
  final double labelDistance;
  final Color dotColor;
  final Color lineColor;
  final Color labelColor;

  _LeaderLinePainter({
    required this.labels,
    required this.center,
    required this.outerRadius,
    required this.labelDistance,
    required this.dotColor,
    required this.lineColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (final label in labels) {
      if (label.pct < _minExternalLabelPercent) continue;

      final dx = math.cos(label.angle);
      final dy = math.sin(label.angle);

      // dot at slice edge
      final dotPos = center + Offset(dx * (outerRadius + 2), dy * (outerRadius + 2));
      canvas.drawCircle(dotPos, 2.0, dotPaint);

      // leader line
      final lineEnd = center + Offset(dx * labelDistance, dy * labelDistance);
      canvas.drawLine(dotPos, lineEnd, linePaint);

      // external percentage label
      final textSpan = TextSpan(text: label.text, style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ));
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();

      final isRight = dx >= 0;
      final labelOffset = isRight
          ? Offset(lineEnd.dx + 4, lineEnd.dy - tp.height / 2)
          : Offset(lineEnd.dx - tp.width - 4, lineEnd.dy - tp.height / 2);

      tp.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderLinePainter oldDelegate) => true;
}
