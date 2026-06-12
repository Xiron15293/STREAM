import 'package:flutter/material.dart';
import '../data/preferences_service.dart';
import '../models/movement.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';

enum ExpenseHeatmapVariant { calendar, advanced }

class ExpenseHeatmap extends StatelessWidget {
  final List<Movement> allMovements;
  final int year;
  final int month;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final bool compact;
  final bool rowCompact;
  final ExpenseHeatmapVariant variant;

  const ExpenseHeatmap({
    super.key,
    required this.allMovements,
    required this.year,
    required this.month,
    this.selectedDay,
    this.onDaySelected,
    this.compact = false,
    this.rowCompact = false,
    this.variant = ExpenseHeatmapVariant.calendar,
  });

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        if (rowCompact) return _buildRowCompact(settings);

        final daysInMonth = DateTime(year, month + 1, 0).day;
        final firstWeekday = DateTime(year, month, 1).weekday;
        final leadingEmpty = firstWeekday - 1;
        final dailyTotals = dailyExpenseTotals(year, month, allMovements);

        final isAdvanced = variant == ExpenseHeatmapVariant.advanced;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final cells = <_HeatmapCellData>[];
        for (int i = 0; i < leadingEmpty; i++) {
          cells.add(_HeatmapCellData.empty());
        }

        for (int day = 1; day <= daysInMonth; day++) {
          final total = dailyTotals[day] ?? 0.0;
          final dayDate = DateTime(year, month, day);
          final isToday = dayDate == today;
          final isSelected =
              selectedDay != null &&
              selectedDay!.year == year &&
              selectedDay!.month == month &&
              selectedDay!.day == day;

          cells.add(
            _HeatmapCellData.day(
              day: day,
              date: dayDate,
              total: total,
              isToday: isToday,
              isSelected: isSelected,
            ),
          );
        }

        final totalCells = cells.length;
        final trailingEmpty = (7 - totalCells % 7) % 7;
        for (int i = 0; i < trailingEmpty; i++) {
          cells.add(_HeatmapCellData.empty());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final gap = compact
                ? 3.0
                : isAdvanced
                ? 6.0
                : 4.0;
            final cellWidth = ((availableWidth - gap * 6) / 7)
                .clamp(28.0, 76.0)
                .toDouble();
            final cellHeight = compact
                ? cellWidth
                : isAdvanced
                ? cellWidth * 0.98
                : cellWidth * 0.92;
            final rows = <Widget>[];
            for (int i = 0; i < cells.length; i += 7) {
              rows.add(
                Row(
                  children: [
                    for (int j = 0; j < 7; j++) ...[
                      if (j > 0) SizedBox(width: gap),
                      Expanded(
                        child: _HeatmapCell(
                          data: cells[i + j],
                          height: cellHeight,
                          compact: compact,
                          isAdvanced: isAdvanced,
                          settings: settings,
                          onDaySelected: onDaySelected,
                        ),
                      ),
                    ],
                  ],
                ),
              );
              if (i + 7 < cells.length) {
                rows.add(SizedBox(height: gap));
              }
            }

            return Column(
              key: const Key('heatmap_no_horizontal_scroll_block'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: Row(
                      children: _weekdays.map((d) {
                        final isWeekend = d == 'Sab' || d == 'Dom';
                        return Expanded(
                          child: Text(
                            d.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: StreamTypography.micro.copyWith(
                              color: isWeekend
                                  ? StreamColors.textMuted
                                  : StreamColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Column(
                  key: const Key('movements_calendar_month_grid'),
                  children: rows,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRowCompact(HeatmapSettings settings) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final dailyTotals = dailyExpenseTotals(year, month, allMovements);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Row(
          children: List.generate(daysInMonth, (i) {
            final day = i + 1;
            final total = dailyTotals[day] ?? 0.0;
            final dayDate = DateTime(year, month, day);
            final isToday = dayDate == today;
            final isSelected =
                selectedDay != null &&
                selectedDay!.year == year &&
                selectedDay!.month == month &&
                selectedDay!.day == day;
            final bgColor = total > 0
                ? heatmapColorForAmount(
                    total,
                    compact: true,
                    settings: settings,
                  )
                : Colors.transparent;

            return Expanded(
              child: GestureDetector(
                onTap: onDaySelected != null
                    ? () => onDaySelected!(dayDate)
                    : null,
                child: Container(
                  key: Key('heatmap_day_cell_${month}_$day'),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(2),
                    border: isSelected
                        ? Border.all(color: StreamColors.primary, width: 1.5)
                        : isToday
                        ? Border.all(
                            color: StreamColors.primary.withValues(alpha: 0.4),
                            width: 0.5,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _HeatmapCellData {
  final int? day;
  final DateTime? date;
  final double total;
  final bool isToday;
  final bool isSelected;

  const _HeatmapCellData.empty()
    : day = null,
      date = null,
      total = 0,
      isToday = false,
      isSelected = false;

  const _HeatmapCellData.day({
    required this.day,
    required this.date,
    required this.total,
    required this.isToday,
    required this.isSelected,
  });

  bool get isEmpty => day == null || date == null;
}

class _HeatmapCell extends StatelessWidget {
  final _HeatmapCellData data;
  final double height;
  final bool compact;
  final bool isAdvanced;
  final HeatmapSettings settings;
  final ValueChanged<DateTime>? onDaySelected;

  const _HeatmapCell({
    required this.data,
    required this.height,
    required this.compact,
    required this.isAdvanced,
    required this.settings,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height);
    }

    final total = data.total;
    final bgColor = total > 0
        ? heatmapColorForAmount(total, compact: compact, settings: settings)
        : StreamColors.surfaceElevated;
    final border = data.isSelected
        ? Border.all(color: StreamColors.primary, width: 2)
        : data.isToday
        ? Border.all(
            color: StreamColors.primary.withValues(alpha: 0.45),
            width: 1,
          )
        : Border.all(color: StreamColors.divider, width: 0.7);
    final radius = isAdvanced ? 8.0 : 6.0;
    final dayColor = total > 0
        ? Colors.white
        : data.isSelected || data.isToday
        ? StreamColors.primary
        : StreamColors.textPrimary;

    return GestureDetector(
      onTap: onDaySelected != null ? () => onDaySelected!(data.date!) : null,
      child: AnimatedContainer(
        key: Key('heatmap_day_cell_${data.day}'),
        duration: const Duration(milliseconds: 120),
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(radius),
          border: border,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 6,
              top: 5,
              child: Text(
                '${data.day}',
                key: Key('heatmap_day_amount_${data.day}'),
                style: TextStyle(
                  fontSize: isAdvanced ? 14 : 13,
                  fontWeight: data.isSelected || isAdvanced
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: dayColor,
                ),
              ),
            ),
            if (total > 0 && !isAdvanced)
              Positioned(
                left: 4,
                right: 4,
                bottom: 4,
                child: Text(
                  formatHeatmapAmount(total),
                  key: Key('heatmap_day_expense_total_${data.day}'),
                  textAlign: TextAlign.center,
                  style: StreamTypography.micro.copyWith(
                    color: total > 0
                        ? Colors.white.withValues(alpha: 0.92)
                        : StreamColors.textSecondary,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            else if (total > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Center(
                  child: Container(
                    key: Key('heatmap_day_expense_total_${data.day}'),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            if (data.isSelected)
              Positioned(
                key: const Key('heatmap_selected_day'),
                right: 5,
                top: 5,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        final bands = settings.bands;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            key: const Key('heatmap_legend'),
            children: [
              for (int i = 0; i < bands.length; i++)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KeyedSubtree(
                        key: const Key('heatmap_legend_item'),
                        child: const SizedBox.shrink(),
                      ),
                      Container(
                        key: const Key('heatmap_legend_color'),
                        width: 28,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(settings.colors[i]),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bands[i].label,
                        key: const Key('heatmap_legend_label'),
                        textAlign: TextAlign.center,
                        style: StreamTypography.micro.copyWith(
                          color: StreamColors.textSecondary,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
