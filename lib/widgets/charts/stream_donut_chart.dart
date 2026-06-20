import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../design/stream_theme_extension.dart';
import '../../design/stream_theme_palette.dart';
import '../../theme.dart';
import '../../utils/analytics_metrics.dart';
import '../../utils/currency_formatter.dart';

/// Start angle offset in degrees. -90 means start from top (12 o'clock).
/// Must match between PieChartData and painter calculations.
const _donutStartDegreeOffset = -90.0;

/// Space in degrees between pie sections (must match PieChartData.sectionsSpace).
const _sectionsSpaceDeg = 2.0;
const _sectionsSpaceRad = _sectionsSpaceDeg * math.pi / 180;

/// Minimum slice percentage that gets an external label with leader line.
/// Smaller slices are shown only in the legend.
const _minExternalLabelPercent = 4.0;

/// Minimum vertical gap in logical pixels between adjacent external labels.
const _minLabelVerticalGap = 16.0;

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

    // ---- single source of truth: compute all slice geometry ----
    final sliceData = _computeSliceData(spent, total);

    const centerRadius = 30.0;
    const outerRadius = 52.0;
    const labelDistance = 74.0;

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
                    sections: sliceData.map((s) => PieChartSectionData(
                      value: s.value,
                      color: s.color,
                      radius: outerRadius,
                      title: '',
                    )).toList(),
                    centerSpaceRadius: centerRadius,
                    sectionsSpace: _sectionsSpaceDeg,
                    startDegreeOffset: _donutStartDegreeOffset,
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
                    sliceData: sliceData,
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
          child: _LegendColumn(sliceData: sliceData, palette: p),
        ),
      ],
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────

class _SliceGeometry {
  final String label;
  final double value;
  final Color color;
  final double percent;
  final double sweepRad;
  final double midAngleRad;

  const _SliceGeometry({
    required this.label,
    required this.value,
    required this.color,
    required this.percent,
    required this.sweepRad,
    required this.midAngleRad,
  });
}

/// Computes slice geometry using the same start offset and sections space
/// as fl_chart's PieChart, so leader lines and external labels align correctly
/// with the rendered sections.
///
/// fl_chart draws sections in clockwise order starting from startDegreeOffset,
/// with a gap of sectionsSpace degrees between each section.
/// This function mirrors that by accumulating sweeps + sectionsSpaceRad.
List<_SliceGeometry> _computeSliceData(List<DonutSlice> slices, double total) {
  final startRad = _donutStartDegreeOffset * math.pi / 180;
  final result = <_SliceGeometry>[];
  var currentRad = startRad;
  for (int i = 0; i < slices.length; i++) {
    final s = slices[i];
    final sweep = (s.value / total) * 2 * math.pi;
    result.add(_SliceGeometry(
      label: s.label,
      value: s.value,
      color: s.color,
      percent: s.value / total * 100,
      sweepRad: sweep,
      midAngleRad: currentRad + sweep / 2,
    ));
    currentRad += sweep + (i < slices.length - 1 ? _sectionsSpaceRad : 0);
  }
  return result;
}

// ── Legend ────────────────────────────────────────────────────────

class _LegendColumn extends StatelessWidget {
  final List<_SliceGeometry> sliceData;
  final StreamThemePalette palette;

  const _LegendColumn({required this.sliceData, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sliceData.map((s) {
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
                  Text('${s.percent.toStringAsFixed(1)}%',
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
    );
  }
}

// ── External label layout (pure function for testability) ─────────

class _LabelLayout {
  final String text;
  final Color color;
  final double midAngleRad;
  final Offset dotPos;
  final Offset lineEnd;
  final Offset labelOffset;
  final bool show;

  const _LabelLayout({
    required this.text,
    required this.color,
    required this.midAngleRad,
    required this.dotPos,
    required this.lineEnd,
    required this.labelOffset,
    required this.show,
  });
}

/// Computes external label positions and applies collision avoidance.
///
/// Strategy:
/// 1. Split labels into right (dx >= 0) and left (dx < 0) groups.
/// 2. Sort each group by y coordinate.
/// 3. Enforce minimum vertical gap between adjacent labels within each group.
/// 4. The threshold filter (_minExternalLabelPercent) sets [show] to false;
///    such slices are omitted from external display but remain in the legend.
///
/// This is a pure function so it can be tested without a canvas.
List<_LabelLayout> _layoutLabels({
  required List<_SliceGeometry> sliceData,
  required Offset center,
  required double outerRadius,
  required double labelDistance,
  required double minVerticalGap,
}) {
  if (sliceData.isEmpty) return [];

  final results = <_LabelLayout>[];

  for (final s in sliceData) {
    final show = s.percent >= _minExternalLabelPercent;
    final dx = math.cos(s.midAngleRad);
    final dy = math.sin(s.midAngleRad);
    final dotPos = center + Offset(dx * (outerRadius + 2), dy * (outerRadius + 2));
    final lineEnd = center + Offset(dx * labelDistance, dy * labelDistance);
    // Label horizontal position: right-aligned on left side, left-aligned on right side
    const pad = 4.0;
    final labelOffset = dx >= 0
        ? Offset(lineEnd.dx + pad, lineEnd.dy)
        : Offset(lineEnd.dx - pad, lineEnd.dy);

    results.add(_LabelLayout(
      text: '${s.percent.toStringAsFixed(0)}%',
      color: s.color,
      midAngleRad: s.midAngleRad,
      dotPos: dotPos,
      lineEnd: lineEnd,
      labelOffset: labelOffset,
      show: show,
    ));
  }

  // Collision avoidance: enforce vertical gap within each side group
    void spaceGroup(List<int> indices) {
    if (indices.length <= 1) return;
    indices.sort((a, b) => results[a].labelOffset.dy.compareTo(results[b].labelOffset.dy));
    for (int j = 1; j < indices.length; j++) {
      final prev = indices[j - 1];
      final curr = indices[j];
      final prevDy = results[prev].labelOffset.dy;
      final currDy = results[curr].labelOffset.dy;
      if (currDy < prevDy + minVerticalGap) {
        final adjustedDy = prevDy + minVerticalGap;
        final currEntry = results[curr];
        final isRight = math.cos(currEntry.midAngleRad) >= 0;
        results[curr] = _LabelLayout(
          text: currEntry.text,
          color: currEntry.color,
          midAngleRad: currEntry.midAngleRad,
          dotPos: currEntry.dotPos,
          lineEnd: Offset(currEntry.lineEnd.dx, adjustedDy),
          labelOffset: isRight
              ? Offset(currEntry.labelOffset.dx, adjustedDy)
              : Offset(currEntry.labelOffset.dx, adjustedDy),
          show: currEntry.show,
        );
      }
    }
  }

  final right = <int>[];
  final left = <int>[];
  for (int i = 0; i < results.length; i++) {
    if (!results[i].show) continue;
    if (math.cos(results[i].midAngleRad) >= 0) {
      right.add(i);
    } else {
      left.add(i);
    }
  }
  spaceGroup(right);
  spaceGroup(left);

  return results;
}

// ── Painter ───────────────────────────────────────────────────────

class _LeaderLinePainter extends CustomPainter {
  final List<_SliceGeometry> sliceData;
  final Offset center;
  final double outerRadius;
  final double labelDistance;
  final Color dotColor;
  final Color lineColor;
  final Color labelColor;

  _LeaderLinePainter({
    required this.sliceData,
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

    final layouts = _layoutLabels(
      sliceData: sliceData,
      center: center,
      outerRadius: outerRadius,
      labelDistance: labelDistance,
      minVerticalGap: _minLabelVerticalGap,
    );

    for (final l in layouts) {
      if (!l.show) continue;

      // dot on slice edge
      canvas.drawCircle(l.dotPos, 2.0, dotPaint);

      // leader line: from dot to horizontal break, then to label
      final isRight = math.cos(l.midAngleRad) >= 0;
      final breakX = isRight
          ? l.labelOffset.dx - 4
          : l.labelOffset.dx + 4;
      final midY = l.labelOffset.dy;
      canvas.drawLine(l.dotPos, Offset(breakX, midY), linePaint);

      // render text
      final textSpan = TextSpan(text: l.text, style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ));
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      final finalOffset = isRight
          ? Offset(l.labelOffset.dx, l.labelOffset.dy - tp.height / 2)
          : Offset(l.labelOffset.dx - tp.width, l.labelOffset.dy - tp.height / 2);
      tp.paint(canvas, finalOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderLinePainter oldDelegate) => true;
}
