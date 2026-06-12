import 'package:flutter/material.dart';

import '../data/preferences_service.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';
import '../utils/movement_period_metrics.dart';
import 'annual_heatmap_card.dart';
import 'expense_heatmap.dart';

class PeriodHeatmapCard extends StatelessWidget {
  final TimeFilter timeFilter;
  final List<Movement> movements;
  final DateTime? selectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final Widget? footerAction;
  final bool compactHeader;
  final bool annualCompact;

  const PeriodHeatmapCard({
    super.key,
    required this.timeFilter,
    required this.movements,
    this.selectedDay,
    this.onDaySelected,
    this.footerAction,
    this.compactHeader = false,
    this.annualCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('period_heatmap_card'),
      padding: const EdgeInsets.all(StreamSpacing.lg),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        border: Border.all(color: StreamColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: StreamSpacing.md),
          _buildBody(),
          if (footerAction != null) ...[
            const SizedBox(height: StreamSpacing.lg),
            Center(child: footerAction!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (compactHeader) {
      return Row(
        children: [
          Expanded(
            child: Text(
              formatTimeFilterTitle(timeFilter),
              key: const Key('period_heatmap_title'),
              style: StreamTypography.h3,
            ),
          ),
          Icon(Icons.chevron_left, color: StreamColors.textMuted),
          const SizedBox(width: StreamSpacing.sm),
          Icon(Icons.chevron_right, color: StreamColors.textMuted),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatTimeFilterTitle(timeFilter),
          key: const Key('period_heatmap_title'),
          style: StreamTypography.h3,
        ),
        const SizedBox(height: StreamSpacing.sm),
        Text(
          _subtitle,
          style: StreamTypography.body.copyWith(
            color: StreamColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String get _subtitle {
    switch (timeFilter.mode) {
      case TimeFilterMode.day:
        return 'Dettaglio del giorno selezionato';
      case TimeFilterMode.month:
        return 'Heatmap mensile del periodo selezionato';
      case TimeFilterMode.year:
        return 'Distribuzione movimenti nell\'anno';
      case TimeFilterMode.customRange:
        return 'Heatmap limitata all\'intervallo selezionato';
    }
  }

  Widget _buildBody() {
    switch (timeFilter.mode) {
      case TimeFilterMode.day:
        return _buildDaySurface();
      case TimeFilterMode.month:
        return KeyedSubtree(
          key: const Key('period_heatmap_month_surface'),
          child: ExpenseHeatmap(
            key: const Key('period_heatmap_month_grid'),
            allMovements: movements,
            year: timeFilter.startDate.year,
            month: timeFilter.startDate.month,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
            variant: ExpenseHeatmapVariant.calendar,
          ),
        );
      case TimeFilterMode.year:
        return KeyedSubtree(
          key: const Key('period_heatmap_year_surface'),
          child: AnnualHeatmapCard(
            year: timeFilter.startDate.year,
            movements: movements,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
            compact: annualCompact,
          ),
        );
      case TimeFilterMode.customRange:
        return _buildRangeSurface();
    }
  }

  Widget _buildDaySurface() {
    final dayDate = timeFilter.startDate;
    final dayMoves = movementsForDay(dayDate, movements);
    final income = dayIncomeTotal(dayDate, movements);
    final expense = dayExpenseTotal(dayDate, movements);
    final balance = dayBalance(dayDate, movements);
    final count = dayMovementCount(dayDate, movements);

    dayMoves.sort((a, b) => a.date.compareTo(b.date));
    final firstExpense = dayMoves.where((m) => m.isExpense).firstOrNull;
    final lastExpense = dayMoves.where((m) => m.isExpense).lastOrNull;
    final firstIncome = dayMoves.where((m) => m.isIncome).firstOrNull;

    final balanceColor = balance > 0
        ? StreamColors.income
        : balance < 0
        ? StreamColors.expense
        : StreamColors.textPrimary;

    return Container(
      key: const Key('day_period_card'),
      padding: const EdgeInsets.all(StreamSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StreamRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StreamColors.surfaceHighlight.withValues(alpha: 0.72),
            StreamColors.surface.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_outlined,
                  color: StreamColors.primary, size: 20),
              const SizedBox(width: StreamSpacing.sm),
              Expanded(
                child: Text(
                  _formatDayHeader(dayDate),
                  key: const Key('day_period_date'),
                  style: StreamTypography.h2.copyWith(
                    color: StreamColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  keyName: 'day_period_income',
                  label: 'Entrate',
                  value: formatEuro(income),
                  color: StreamColors.income,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'day_period_expense',
                  label: 'Uscite',
                  value: formatEuro(expense),
                  color: StreamColors.expense,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'day_period_balance',
                  label: 'Saldo',
                  value:
                      '${balance > 0 ? '+' : balance < 0 ? '-' : ''}${formatEuro(balance.abs())}',
                  color: balanceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.md),
          _MetricChip(
            keyName: 'day_period_movements_count',
            label: 'Movimenti del giorno',
            value: '$count',
            color: StreamColors.textPrimary,
          ),
          if (firstExpense != null || firstIncome != null) ...[
            const SizedBox(height: StreamSpacing.md),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            const SizedBox(height: StreamSpacing.md),
            if (firstExpense != null) ...[
              _MovementRow(
                keyName: 'day_period_first_movement',
                label: 'Primo movimento',
                movement: firstExpense,
              ),
              const SizedBox(height: StreamSpacing.sm),
            ],
            if (firstIncome != null && firstIncome != firstExpense) ...[
              _MovementRow(
                keyName: 'day_period_first_income',
                label: 'Prima entrata',
                movement: firstIncome,
              ),
              const SizedBox(height: StreamSpacing.sm),
            ],
            if (lastExpense != null && lastExpense != firstExpense) ...[
              _MovementRow(
                keyName: 'day_period_last_movement',
                label: 'Ultima uscita',
                movement: lastExpense,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDayHeader(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  static const _monthNames = [
    'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
    'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
  ];

  Widget _buildRangeSurface() {
    final start = timeFilter.startDate;
    final end = timeFilter.endDate;
    final totalDays = end.difference(start).inDays + 1;

    final metrics = MovementPeriodMetrics.fromMovements(movements);
    final balanceColor = metrics.netBalance > 0
        ? StreamColors.income
        : metrics.netBalance < 0
        ? StreamColors.expense
        : StreamColors.textPrimary;

    return Container(
      key: const Key('period_heatmap_range_surface'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  keyName: 'range_period_income',
                  label: 'Entrate',
                  value: formatEuro(metrics.totalIncome),
                  color: StreamColors.income,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'range_period_expense',
                  label: 'Uscite',
                  value: formatEuro(metrics.totalExpense),
                  color: StreamColors.expense,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'range_period_balance',
                  label: 'Saldo',
                  value:
                      '${metrics.netBalance > 0 ? '+' : metrics.netBalance < 0 ? '-' : ''}${formatEuro(metrics.netBalance.abs())}',
                  color: balanceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          _MetricChip(
            keyName: 'range_period_movements_count',
            label: 'Movimenti',
            value: '${metrics.movementCount}',
            color: StreamColors.textPrimary,
          ),
          const SizedBox(height: StreamSpacing.md),
          if (totalDays <= 31) _buildShortRangeGrid(start, end)
          else _buildLongRangeGrid(start, end),
          if (totalDays > 31) ...[
            const SizedBox(height: StreamSpacing.md),
            const _RangeHeatmapLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildShortRangeGrid(DateTime start, DateTime end) {
    final totalDays = end.difference(start).inDays + 1;
    final firstWeekday = start.weekday;
    final dailyTotals = <int, double>{};
    for (final m in movements) {
      if (m.isTransfer) continue;
      if (!m.isExpense) continue;
      if (!m.date.isBefore(start) && !m.date.isAfter(end)) {
        final dayOffset = m.date.difference(start).inDays;
        dailyTotals.update(
          dayOffset,
          (v) => v + m.amount,
          ifAbsent: () => m.amount,
        );
      }
    }

    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        final cells = <Widget>[];
        for (int i = 0; i < firstWeekday - 1; i++) {
          cells.add(const SizedBox.shrink());
        }
        for (int offset = 0; offset < totalDays; offset++) {
          final dayDate = start.add(Duration(days: offset));
          final total = dailyTotals[offset] ?? 0.0;
          final isSelected = selectedDay != null &&
              selectedDay!.year == dayDate.year &&
              selectedDay!.month == dayDate.month &&
              selectedDay!.day == dayDate.day;
          final bgColor = total > 0
              ? heatmapColorForAmount(total, settings: settings)
              : Colors.transparent;

          cells.add(
            GestureDetector(
              onTap: onDaySelected != null
                  ? () => onDaySelected!(dayDate)
                  : null,
              child: Container(
                key: Key(
                  'range_heatmap_day_${dayDate.year}_${dayDate.month}_${dayDate.day}',
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? Border.all(color: StreamColors.primary, width: 2)
                      : total > 0
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.5,
                            )
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                              width: 0.5,
                            ),
                ),
                padding: const EdgeInsets.all(6),
                child: Text(
                  '${dayDate.day}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: total > 0
                        ? Colors.white
                        : StreamColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }

        final trailingEmpty = (7 - cells.length % 7) % 7;
        for (int i = 0; i < trailingEmpty; i++) {
          cells.add(const SizedBox.shrink());
        }

        final rows = <Widget>[];
        rows.add(
          Row(
            children: _weekdayLabels.map((d) {
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
        );
        rows.add(const SizedBox(height: StreamSpacing.sm));

        for (int i = 0; i < cells.length; i += 7) {
          rows.add(
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (int j = 0; j < 7; j++) ...[
                    if (j > 0) const SizedBox(width: 4),
                    Expanded(
                      child: cells[i + j],
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return KeyedSubtree(
          key: const Key('range_heatmap'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: rows,
          ),
        );
      },
    );
  }

  Widget _buildLongRangeGrid(DateTime start, DateTime end) {
    final firstDay = start;
    final lastDay = end;
    final startMonday = firstDay.subtract(
      Duration(days: (firstDay.weekday - 1) % 7),
    );
    final endSunday = lastDay.add(
      Duration(days: (7 - lastDay.weekday) % 7),
    );

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

    final daysInRange = <int, double>{};
    for (final m in movements) {
      if (m.isTransfer) continue;
      if (!m.isExpense) continue;
      if (!m.date.isBefore(start) && !m.date.isAfter(end)) {
        final key = m.date.month * 100 + m.date.day;
        daysInRange.update(key, (v) => v + m.amount, ifAbsent: () => m.amount);
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWeeks = weeks.length;
            final gap = 1.5;
            final dayLabelWidth = 14.0;
            final cellWidth =
                ((constraints.maxWidth - dayLabelWidth - gap * (totalWeeks - 1)) /
                        totalWeeks)
                    .clamp(8.0, 22.0);
            final cellHeight = cellWidth;

            return Column(
              key: const Key('range_heatmap'),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRangeMonthLabelRow(
                  weeks, cellWidth, dayLabelWidth, gap),
                const SizedBox(height: 2),
                for (int dow = 0; dow < 7; dow++)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: _buildRangeDayRow(
                      dow: dow,
                      weeks: weeks,
                      cellWidth: cellWidth,
                      cellHeight: cellHeight,
                      dayLabelWidth: dayLabelWidth,
                      gap: gap,
                      daysInRange: daysInRange,
                      todayDate: todayDate,
                      settings: settings,
                      start: start,
                      end: end,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRangeMonthLabelRow(
    List<List<DateTime?>> weeks,
    double cellWidth,
    double dayLabelWidth,
    double gap,
  ) {
    final monthChanges = <int, int>{};
    int? lastMonth;
    for (int col = 0; col < weeks.length; col++) {
      final week = weeks[col];
      final firstDayOfWeek =
          week.firstWhere((d) => d != null, orElse: () => null);
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
      final nextCol =
          i + 1 < sortedCols.length ? sortedCols[i + 1] : weeks.length;
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
              width:
                  entry.value * cellWidth + (entry.value - 1) * gap,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                _rangeMonthLabels[monthChanges[entry.key]! - 1],
                style: StreamTypography.micro.copyWith(
                  color: StreamColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          if (labelPositions.isNotEmpty) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildRangeDayRow({
    required int dow,
    required List<List<DateTime?>> weeks,
    required double cellWidth,
    required double cellHeight,
    required double dayLabelWidth,
    required double gap,
    required Map<int, double> daysInRange,
    required DateTime todayDate,
    required HeatmapSettings settings,
    required DateTime start,
    required DateTime end,
  }) {
    return Row(
      children: [
        SizedBox(
          width: dayLabelWidth,
          height: cellHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _rangeDayLabels[dow],
              style: TextStyle(
                fontSize: 8,
                color: StreamColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        for (int col = 0; col < weeks.length; col++) ...[
          if (col > 0) SizedBox(width: gap),
          _buildRangeCell(
            weeks[col][dow],
            cellWidth,
            cellHeight,
            daysInRange,
            todayDate,
            settings,
            start,
            end,
          ),
        ],
      ],
    );
  }

  Widget _buildRangeCell(
    DateTime? date,
    double width,
    double height,
    Map<int, double> daysInRange,
    DateTime todayDate,
    HeatmapSettings settings,
    DateTime start,
    DateTime end,
  ) {
    if (date == null) {
      return SizedBox(width: width, height: height);
    }

    final key = date.month * 100 + date.day;
    final total = daysInRange[key] ?? 0.0;
    final isToday = date == todayDate;
    final isSelected = selectedDay != null &&
        selectedDay!.year == date.year &&
        selectedDay!.month == date.month &&
        selectedDay!.day == date.day;

    final bgColor = total > 0
        ? heatmapColorForAmount(total, settings: settings)
        : Colors.transparent;

    return GestureDetector(
      onTap: onDaySelected != null ? () => onDaySelected!(date) : null,
      child: Container(
        key: Key(
          'range_heatmap_day_${date.year}_${date.month}_${date.day}',
        ),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(2),
          border: isSelected
              ? Border.all(color: StreamColors.primary, width: 1.5)
              : isToday
                  ? Border.all(
                      color: StreamColors.primary.withValues(alpha: 0.5),
                      width: 1,
                    )
                  : total > 0
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        )
                      : null,
        ),
      ),
    );
  }

  static const _weekdayLabels = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const _rangeDayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
  static const _rangeMonthLabels = [
    'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
    'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic',
  ];
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String keyName;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.keyName,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100),
      child: Column(
        key: Key(keyName),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: StreamTypography.captionBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final String keyName;
  final String label;
  final Movement movement;

  const _MovementRow({
    required this.keyName,
    required this.label,
    required this.movement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: Key(keyName),
      children: [
        Icon(
          movement.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: movement.isExpense
              ? StreamColors.expense
              : StreamColors.income,
        ),
        const SizedBox(width: StreamSpacing.sm),
        Expanded(
          child: Text(
            movement.title,
            style: StreamTypography.caption.copyWith(
              color: StreamColors.textPrimary,
            ),
          ),
        ),
        Text(
          '${movement.isExpense ? '-' : '+'}${formatEuro(movement.amount)}',
          style: StreamTypography.captionBold.copyWith(
            color: movement.isExpense
                ? StreamColors.expense
                : StreamColors.income,
          ),
        ),
      ],
    );
  }
}

class _RangeHeatmapLegend extends StatelessWidget {
  const _RangeHeatmapLegend();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        final bands = settings.bands;
        return Container(
          key: const Key('range_heatmap_legend'),
          padding: const EdgeInsets.all(StreamSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(StreamRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legenda heatmap',
                style: StreamTypography.captionBold.copyWith(
                  color: StreamColors.textPrimary,
                ),
              ),
              const SizedBox(height: StreamSpacing.sm),
              Wrap(
                spacing: StreamSpacing.md,
                runSpacing: StreamSpacing.sm,
                children: [
                  for (int i = 0; i < bands.length; i++)
                    _RangeLegendItem(
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

class _RangeLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _RangeLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        const SizedBox(width: StreamSpacing.sm),
        Text(
          label,
          style: StreamTypography.micro.copyWith(
            color: StreamColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}
