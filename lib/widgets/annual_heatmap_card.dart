import 'package:flutter/material.dart';

import '../data/preferences_service.dart';
import '../design/stream_theme_extension.dart';
import '../models/movement.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';

class AnnualHeatmapCard extends StatelessWidget {
  final int year;
  final List<Movement> movements;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final bool compact;

  const AnnualHeatmapCard({
    super.key,
    required this.year,
    required this.movements,
    required this.selectedDay,
    required this.onDaySelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final cp = context.$chart;
    return Container(
      key: const Key('annual_heatmap'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StreamRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primary.withValues(
              alpha: p.brightness == Brightness.light ? 0.08 : 0.14,
            ),
            cp.cardBackground,
          ],
        ),
        border: Border.all(
          color: cp.cardBorderColor,
          width: cp.cardBorderWidth,
        ),
        boxShadow: cp.cardShadows,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? StreamSpacing.md : StreamSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnnualHeatmapHeader(year: year, compact: compact),
            SizedBox(height: compact ? StreamSpacing.md : StreamSpacing.lg),
            _SemesterSection(
              year: year,
              startMonth: 1,
              endMonth: 6,
              movements: movements,
              selectedDay: selectedDay,
              onDaySelected: onDaySelected,
              compact: compact,
            ),
            SizedBox(height: compact ? StreamSpacing.sm : StreamSpacing.md),
            _SemesterSection(
              year: year,
              startMonth: 7,
              endMonth: 12,
              movements: movements,
              selectedDay: selectedDay,
              onDaySelected: onDaySelected,
              compact: compact,
            ),
            if (!compact) ...[
              const SizedBox(height: StreamSpacing.lg),
              const _AnnualHeatmapLegend(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SemesterSection extends StatelessWidget {
  final int year;
  final int startMonth;
  final int endMonth;
  final List<Movement> movements;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final bool compact;

  const _SemesterSection({
    required this.year,
    required this.startMonth,
    required this.endMonth,
    required this.movements,
    required this.selectedDay,
    required this.onDaySelected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        return _SemesterGrid(
          year: year,
          startMonth: startMonth,
          endMonth: endMonth,
          movements: movements,
          selectedDay: selectedDay,
          onDaySelected: onDaySelected,
          settings: settings,
          compact: compact,
        );
      },
    );
  }
}

class _SemesterGrid extends StatelessWidget {
  final int year;
  final int startMonth;
  final int endMonth;
  final List<Movement> movements;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final HeatmapSettings settings;
  final bool compact;

  const _SemesterGrid({
    required this.year,
    required this.startMonth,
    required this.endMonth,
    required this.movements,
    required this.selectedDay,
    required this.onDaySelected,
    required this.settings,
    required this.compact,
  });

  static const _dayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
  static const _monthLabels = [
    'Gen',
    'Feb',
    'Mar',
    'Apr',
    'Mag',
    'Giu',
    'Lug',
    'Ago',
    'Set',
    'Ott',
    'Nov',
    'Dic',
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, startMonth, 1);
    final lastDay = DateTime(year, endMonth + 1, 0);
    final startMonday = firstDay.subtract(
      Duration(days: (firstDay.weekday - 1) % 7),
    );
    final endSunday = lastDay.add(Duration(days: (7 - lastDay.weekday) % 7));

    final weeks = <List<DateTime?>>[];
    var current = startMonday;
    while (!current.isAfter(endSunday)) {
      final week = <DateTime?>[];
      for (int i = 0; i < 7; i++) {
        final day = current.add(Duration(days: i));
        if (day.isBefore(firstDay) || day.isAfter(lastDay)) {
          week.add(null);
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }

    final daysInYear = <int, double>{};
    for (final m in movements) {
      if (m.isTransfer) continue;
      if (!m.isExpense) continue;
      if (m.date.year == year) {
        final key = m.date.month * 100 + m.date.day;
        daysInYear.update(key, (v) => v + m.amount, ifAbsent: () => m.amount);
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWeeks = weeks.length;
        final dayLabelWidth = compact ? 12.0 : 14.0;
        final gap = compact ? 1.0 : 1.5;
        final cellWidth =
            ((constraints.maxWidth - dayLabelWidth - gap * (totalWeeks - 1)) /
                    totalWeeks)
                .clamp(compact ? 6.0 : 8.0, compact ? 14.0 : 22.0);
        final cellHeight = cellWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMonthLabelRow(context, weeks, cellWidth, dayLabelWidth, gap),
            const SizedBox(height: 2),
            for (int dow = 0; dow < 7; dow++)
              Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: _buildDayRow(
                  context: context,
                  dow: dow,
                  weeks: weeks,
                  cellWidth: cellWidth,
                  cellHeight: cellHeight,
                  dayLabelWidth: dayLabelWidth,
                  gap: gap,
                  daysInYear: daysInYear,
                  todayDate: todayDate,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMonthLabelRow(
    BuildContext context,
    List<List<DateTime?>> weeks,
    double cellWidth,
    double dayLabelWidth,
    double gap,
  ) {
    final p = context.$palette;
    final monthChanges = <int, int>{};
    int? lastMonth;
    for (int col = 0; col < weeks.length; col++) {
      final week = weeks[col];
      final firstDayOfWeek = week.firstWhere(
        (d) => d != null,
        orElse: () => null,
      );
      if (firstDayOfWeek == null) continue;
      if (firstDayOfWeek.month != lastMonth) {
        monthChanges[col] = firstDayOfWeek.month;
        lastMonth = firstDayOfWeek.month;
      }
    }

    final labelPositions = <MapEntry<int, int>>[];
    final sortedCols = monthChanges.keys.toList()..sort();
    for (int i = 0; i < sortedCols.length; i++) {
      final col = sortedCols[i];
      final nextCol = i + 1 < sortedCols.length
          ? sortedCols[i + 1]
          : weeks.length;
      labelPositions.add(MapEntry(col, nextCol - col));
    }

    return SizedBox(
      height: cellWidth * 1.1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: dayLabelWidth),
          for (final entry in labelPositions)
            Container(
              width: entry.value * cellWidth + (entry.value - 1) * gap,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                _monthLabels[monthChanges[entry.key]! - 1],
                key: Key(
                  'annual_heatmap_month_label_${monthChanges[entry.key]}',
                ),
                style: StreamTypography.micro.copyWith(
                  color: p.textMuted,
                  fontSize: compact ? 8 : 9,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          if (labelPositions.isNotEmpty) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDayRow({
    required BuildContext context,
    required int dow,
    required List<List<DateTime?>> weeks,
    required double cellWidth,
    required double cellHeight,
    required double dayLabelWidth,
    required double gap,
    required Map<int, double> daysInYear,
    required DateTime todayDate,
  }) {
    final p = context.$palette;
    return Row(
      children: [
        SizedBox(
          width: dayLabelWidth,
          height: cellHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _dayLabels[dow],
              style: TextStyle(
                fontSize: compact ? 7 : 8,
                color: p.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        for (int col = 0; col < weeks.length; col++) ...[
          if (col > 0) SizedBox(width: gap),
          _buildCell(
            context,
            weeks[col][dow],
            cellWidth,
            cellHeight,
            daysInYear,
            todayDate,
          ),
        ],
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    DateTime? date,
    double width,
    double height,
    Map<int, double> daysInYear,
    DateTime todayDate,
  ) {
    final p = context.$palette;
    if (date == null) {
      return SizedBox(width: width, height: height);
    }

    final key = date.month * 100 + date.day;
    final total = daysInYear[key] ?? 0.0;
    final isToday = date == todayDate;
    final isSelected =
        selectedDay != null &&
        selectedDay!.year == date.year &&
        selectedDay!.month == date.month &&
        selectedDay!.day == date.day;

    final bgColor = total > 0
        ? heatmapColorForAmount(total, compact: compact, settings: settings)
        : p.surfaceElevated.withValues(
            alpha: p.brightness == Brightness.light ? 0.72 : 0.5,
          );

    return GestureDetector(
      onTap: onDaySelected != null ? () => onDaySelected!(date) : null,
      child: Container(
        key: Key('annual_heatmap_day_${date.year}_${date.month}_${date.day}'),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(2),
          border: isSelected
              ? Border.all(color: p.primary, width: 1.5)
              : isToday
              ? Border.all(color: p.primary.withValues(alpha: 0.5), width: 1)
              : total > 0
              ? Border.all(color: p.divider.withValues(alpha: 0.15), width: 0.5)
              : null,
        ),
      ),
    );
  }
}

class _AnnualHeatmapHeader extends StatelessWidget {
  final int year;
  final bool compact;

  const _AnnualHeatmapHeader({required this.year, required this.compact});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$year',
                key: const Key('annual_heatmap_year_title'),
                style: StreamTypography.h2.copyWith(
                  fontSize: compact ? 19 : 22,
                  color: p.textPrimary,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: StreamSpacing.xs),
                Text(
                  'Andamento annuale',
                  key: const Key('annual_heatmap_subtitle'),
                  style: StreamTypography.caption.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const _AnnualNavGlyph(icon: Icons.chevron_left),
        const SizedBox(width: StreamSpacing.sm),
        const _AnnualNavGlyph(icon: Icons.chevron_right),
      ],
    );
  }
}

class _AnnualNavGlyph extends StatelessWidget {
  final IconData icon;

  const _AnnualNavGlyph({required this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.full),
        border: Border.all(color: p.divider),
      ),
      child: Icon(icon, color: p.textSecondary),
    );
  }
}

class _AnnualHeatmapLegend extends StatelessWidget {
  const _AnnualHeatmapLegend();

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        final bands = settings.bands;
        return Container(
          key: const Key('annual_heatmap_legend'),
          padding: const EdgeInsets.all(StreamSpacing.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(StreamRadius.lg),
            border: Border.all(color: p.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legenda heatmap',
                style: StreamTypography.captionBold.copyWith(
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: StreamSpacing.sm),
              Wrap(
                spacing: StreamSpacing.md,
                runSpacing: StreamSpacing.sm,
                children: [
                  for (int i = 0; i < bands.length; i++)
                    _LegendItem(
                      color: Color(settings.colors[i]),
                      label: bands[i].label,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: p.divider.withValues(alpha: 0.12)),
          ),
        ),
        const SizedBox(width: StreamSpacing.sm),
        Text(
          label,
          style: StreamTypography.micro.copyWith(
            color: p.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
