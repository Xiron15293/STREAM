import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_icon_library.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/subcategory.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';
import '../utils/movement_period_metrics.dart';
import 'annual_heatmap_card.dart';
import 'expense_heatmap.dart';
import 'movement_card.dart';
import 'stream_kpi_card.dart';

class PeriodHeatmapCard extends StatelessWidget {
  final TimeFilter timeFilter;
  final List<Movement> movements;
  final DateTime? selectedDay;
  final DateTime? selectedPeriodDay;
  final ValueChanged<DateTime>? onDaySelected;
  final VoidCallback? onClearSelectedDay;
  final Widget? footerAction;
  final bool compactHeader;
  final bool annualCompact;
  final List<Category>? categories;
  final List<Subcategory>? subcategories;
  final AppDatabase? db;
  final ValueChanged<Movement>? onEdit;
  final ValueChanged<Movement>? onDuplicate;
  final ValueChanged<Movement>? onSaveAsFavorite;
  final ValueChanged<Movement>? onAddQuick;
  final ValueChanged<Movement>? onDelete;

  const PeriodHeatmapCard({
    super.key,
    required this.timeFilter,
    required this.movements,
    this.selectedDay,
    this.selectedPeriodDay,
    this.onDaySelected,
    this.onClearSelectedDay,
    this.footerAction,
    this.compactHeader = false,
    this.annualCompact = false,
    this.categories,
    this.subcategories,
    this.db,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onAddQuick,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cp = context.$chart;
    return Container(
      key: const Key('heatmap_summary_kpi'),
      padding: const EdgeInsets.all(StreamSpacing.lg),
      decoration: BoxDecoration(
        color: cp.cardBackground,
        borderRadius: BorderRadius.circular(cp.cardRadius),
        border: Border.all(
          color: cp.cardBorderColor,
          width: cp.cardBorderWidth,
        ),
        boxShadow: cp.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (footerAction != null) ...[
            const SizedBox(height: StreamSpacing.sm),
            Align(alignment: Alignment.centerLeft, child: footerAction!),
          ],
          const SizedBox(height: StreamSpacing.md),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final p = context.$palette;
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
          Icon(Icons.chevron_left, color: p.textMuted),
          const SizedBox(width: StreamSpacing.sm),
          Icon(Icons.chevron_right, color: p.textMuted),
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
          style: StreamTypography.body.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }

  String get _subtitle {
    switch (timeFilter.mode) {
      case TimeFilterMode.day:
        return '';
      case TimeFilterMode.week:
        return 'Heatmap settimanale del periodo selezionato';
      case TimeFilterMode.month:
        return 'Heatmap mensile del periodo selezionato';
      case TimeFilterMode.year:
        return 'Distribuzione movimenti nell\'anno';
      case TimeFilterMode.customRange:
        return 'Heatmap limitata all\'intervallo selezionato';
    }
  }

  Widget _buildBody(BuildContext context) {
    final effectiveSelectedDay = selectedPeriodDay ?? selectedDay;

    switch (timeFilter.mode) {
      case TimeFilterMode.day:
        return _buildDaySurface(context);
      case TimeFilterMode.week:
        return _buildWeekSurface(context);
      case TimeFilterMode.month:
        return KeyedSubtree(
          key: const Key('period_heatmap_month_surface'),
          child: Column(
            children: [
              if (selectedPeriodDay != null)
                _buildSelectedPeriodDayChip(context, selectedPeriodDay!),
              ExpenseHeatmap(
                key: const Key('period_heatmap_month_grid'),
                allMovements: movements,
                year: timeFilter.startDate.year,
                month: timeFilter.startDate.month,
                selectedDay: effectiveSelectedDay,
                onDaySelected: onDaySelected,
                variant: ExpenseHeatmapVariant.calendar,
              ),
            ],
          ),
        );
      case TimeFilterMode.year:
        return KeyedSubtree(
          key: const Key('period_heatmap_year_surface'),
          child: Column(
            children: [
              if (selectedPeriodDay != null)
                _buildSelectedPeriodDayChip(context, selectedPeriodDay!),
              AnnualHeatmapCard(
                year: timeFilter.startDate.year,
                movements: movements,
                selectedDay: effectiveSelectedDay,
                onDaySelected: onDaySelected,
                compact: annualCompact,
              ),
            ],
          ),
        );
      case TimeFilterMode.customRange:
        return _buildRangeSurface(context);
    }
  }

  Widget _buildDaySurface(BuildContext context) {
    final p = context.$palette;
    final dayDate = timeFilter.startDate;
    final dayMoves = movementsForDay(dayDate, movements);
    final income = dayIncomeTotal(dayDate, movements);
    final expense = dayExpenseTotal(dayDate, movements);
    final balance = dayBalance(dayDate, movements);
    final count = dayMovementCount(dayDate, movements);

    dayMoves.sort((a, b) => a.date.compareTo(b.date));
    final firstExpense = dayMoves.where((m) => m.isExpense).firstOrNull;
    final lastExpense = dayMoves.where((m) => m.isExpense).lastOrNull;

    final topCategory = _topCategoryForDay(dayDate);

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final isToday = dayDate == todayDate;

    final balanceColor = balance > 0
        ? p.income
        : balance < 0
        ? p.expense
        : p.textPrimary;

    return Container(
      key: const Key('day_period_card'),
      padding: const EdgeInsets.fromLTRB(
        StreamSpacing.lg,
        StreamSpacing.lg,
        StreamSpacing.lg,
        StreamSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StreamRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primary.withValues(
              alpha: p.brightness == Brightness.light ? 0.12 : 0.18,
            ),
            p.surfaceElevated,
          ],
        ),
        border: Border.all(color: p.divider.withValues(alpha: 0.9)),
        boxShadow: StreamSurfaceTokens.card(p, elevated: true).shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'OGGI' : 'GIORNO',
                      key: const Key('day_period_title'),
                      style: StreamTypography.h3.copyWith(
                        color: p.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(dayDate),
                      key: const Key('day_period_date'),
                      style: StreamTypography.caption.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: StreamSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(StreamRadius.full),
                ),
                child: Text(
                  'Giorno',
                  style: StreamTypography.micro.copyWith(
                    color: p.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.lg),
          Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.sm,
            children: [
              if (firstExpense != null)
                _DayChip(
                  keyName: 'day_period_first_movement',
                  icon: Icons.arrow_upward,
                  label: 'Prima uscita',
                  value: formatEuro(firstExpense.amount),
                  color: p.expense,
                ),
              if (lastExpense != null && lastExpense != firstExpense)
                _DayChip(
                  keyName: 'day_period_last_movement',
                  icon: Icons.arrow_downward,
                  label: 'Ultima uscita',
                  value: formatEuro(lastExpense.amount),
                  color: p.expense,
                ),
              if (topCategory != null)
                _DayChip(
                  keyName: 'day_period_top_category',
                  icon: Icons.category_outlined,
                  label: topCategory.$1,
                  value: formatEuro(topCategory.$2),
                  color: topCategory.$3,
                )
              else
                _DayChip(
                  keyName: 'day_period_top_category',
                  icon: Icons.category_outlined,
                  label: 'Nessuna uscita',
                  value: '—',
                  color: p.textMuted,
                ),
              _DayChip(
                keyName: 'day_period_movements_count',
                icon: Icons.receipt_long_outlined,
                label: 'Movimenti',
                value: '$count',
                color: p.primary,
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.md),
          Container(height: 1, color: p.divider.withValues(alpha: 0.08)),
          const SizedBox(height: StreamSpacing.md),
          Row(
            children: [
              _DayKpi(
                keyName: 'day_period_income',
                label: 'Entrate',
                value: formatEuro(income),
                color: p.income,
                semanticType: StreamKpiSemanticType.income,
              ),
              const SizedBox(width: StreamSpacing.md),
              _DayKpi(
                keyName: 'day_period_expense',
                label: 'Uscite',
                value: formatEuro(expense),
                color: p.expense,
                semanticType: StreamKpiSemanticType.expense,
              ),
              const SizedBox(width: StreamSpacing.md),
              _DayKpi(
                keyName: 'day_period_balance',
                label: 'Saldo',
                value:
                    '${balance > 0
                        ? '+'
                        : balance < 0
                        ? '-'
                        : ''}${formatEuro(balance.abs())}',
                color: balanceColor,
                semanticType: StreamKpiSemanticType.balance,
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.md),
          Container(height: 1, color: p.divider.withValues(alpha: 0.08)),
          const SizedBox(height: StreamSpacing.md),
          _DayExpenseBreakdown(
            dayDate: dayDate,
            movements: dayMoves,
            categories: categories ?? [],
            subcategories: subcategories ?? [],
            db: db,
            onEdit: onEdit,
            onDuplicate: onDuplicate,
            onSaveAsFavorite: onSaveAsFavorite,
            onAddQuick: onAddQuick,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSurface(BuildContext context) {
    final p = context.$palette;
    final start = timeFilter.startDate;
    final metrics = MovementPeriodMetrics.fromMovements(movements);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final effectiveSelectedDay = selectedPeriodDay ?? selectedDay;

    final balanceColor = metrics.netBalance > 0
        ? p.income
        : metrics.netBalance < 0
        ? p.expense
        : p.textPrimary;

    final dailyTotals = <int, double>{};
    for (final m in movements) {
      if (m.isTransfer) continue;
      if (!m.isExpense) continue;
      final offset = m.date.difference(start).inDays;
      if (offset >= 0 && offset < 7) {
        dailyTotals.update(
          offset,
          (v) => v + m.amount,
          ifAbsent: () => m.amount,
        );
      }
    }

    return Container(
      key: const Key('week_period_card'),
      padding: const EdgeInsets.fromLTRB(
        StreamSpacing.lg,
        StreamSpacing.lg,
        StreamSpacing.lg,
        StreamSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StreamRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.primary.withValues(
              alpha: p.brightness == Brightness.light ? 0.1 : 0.16,
            ),
            p.surfaceElevated,
          ],
        ),
        border: Border.all(color: p.divider),
        boxShadow: StreamSurfaceTokens.card(p, elevated: true).shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settimana',
                      key: const Key('week_period_title'),
                      style: StreamTypography.h3.copyWith(
                        color: p.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFilter.label,
                      key: const Key('week_period_range'),
                      style: StreamTypography.caption.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  keyName: 'week_period_income',
                  label: 'Entrate',
                  value: formatEuro(metrics.totalIncome),
                  color: p.income,
                  semanticType: StreamKpiSemanticType.income,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'week_period_expense',
                  label: 'Uscite',
                  value: formatEuro(metrics.totalExpense),
                  color: p.expense,
                  semanticType: StreamKpiSemanticType.expense,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'week_period_balance',
                  label: 'Saldo',
                  value:
                      '${metrics.netBalance > 0
                          ? '+'
                          : metrics.netBalance < 0
                          ? '-'
                          : ''}${formatEuro(metrics.netBalance.abs())}',
                  color: balanceColor,
                  semanticType: StreamKpiSemanticType.balance,
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          _MetricChip(
            keyName: 'week_period_movements_count',
            label: 'Movimenti della settimana',
            value: '${metrics.movementCount}',
            color: p.textPrimary,
            semanticType: StreamKpiSemanticType.count,
          ),
          if (selectedPeriodDay != null) ...[
            const SizedBox(height: StreamSpacing.md),
            _buildSelectedPeriodDayChip(context, selectedPeriodDay!),
          ],
          const SizedBox(height: StreamSpacing.md),
          ValueListenableBuilder<HeatmapSettings>(
            valueListenable: PreferencesService.heatmapSettingsNotifier,
            builder: (context, settings, _) {
              return Row(
                key: const Key('week_heatmap'),
                children: List.generate(7, (index) {
                  final dayDate = start.add(Duration(days: index));
                  final total = dailyTotals[index] ?? 0.0;
                  final isSelected =
                      effectiveSelectedDay != null &&
                      effectiveSelectedDay.year == dayDate.year &&
                      effectiveSelectedDay.month == dayDate.month &&
                      effectiveSelectedDay.day == dayDate.day;
                  final isToday = dayDate == todayDate;
                  final bgColor = total > 0
                      ? heatmapColorForAmount(total, settings: settings)
                      : p.surfaceElevated.withValues(
                          alpha: p.brightness == Brightness.light ? 0.72 : 0.5,
                        );
                  final onBg = StreamSurfaceTokens.onAccent(bgColor);

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
                      child: GestureDetector(
                        onTap: onDaySelected != null
                            ? () => onDaySelected!(dayDate)
                            : null,
                        child: Container(
                          key: Key(
                            'week_heatmap_day_${dayDate.year}_${dayDate.month}_${dayDate.day}',
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(
                              StreamRadius.md,
                            ),
                            border: isSelected
                                ? Border.all(color: p.primary, width: 2)
                                : isToday
                                ? Border.all(
                                    color: p.primary.withValues(alpha: 0.45),
                                    width: 1,
                                  )
                                : total > 0
                                ? Border.all(
                                    color: p.divider.withValues(alpha: 0.15),
                                    width: 0.5,
                                  )
                                : Border.all(
                                    color: p.divider.withValues(alpha: 0.06),
                                    width: 0.5,
                                  ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _weekdayLabels[index],
                                style: StreamTypography.micro.copyWith(
                                  color: p.textSecondary.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dayDate.day}',
                                style: StreamTypography.captionBold.copyWith(
                                  color: total > 0 ? onBg : p.textMuted,
                                ),
                              ),
                              if (total > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  formatEuro(total),
                                  style: StreamTypography.micro.copyWith(
                                    color: onBg.withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  (String, double, Color)? _topCategoryForDay(DateTime day) {
    final dayMoves = movementsForDay(day, movements);
    final expenseByCat = <String, double>{};
    for (final m in dayMoves) {
      if (m.isTransfer) continue;
      if (!m.isExpense) continue;
      expenseByCat.update(
        m.categoryId,
        (v) => v + m.amount,
        ifAbsent: () => m.amount,
      );
    }
    if (expenseByCat.isEmpty) return null;
    final topId = expenseByCat.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final cat = categories?.firstWhere(
      (c) => c.id == topId,
      orElse: () => Category(
        id: topId,
        name: topId,
        type: MovementType.expense,
        color: 0xFF888888,
      ),
    );
    if (cat == null) {
      return (topId, expenseByCat[topId]!, const Color(0xFF888888));
    }
    return (cat.name, expenseByCat[topId]!, Color(cat.color));
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  static const _monthNames = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];

  Widget _buildRangeSurface(BuildContext context) {
    final p = context.$palette;
    final start = timeFilter.startDate;
    final end = timeFilter.endDate;
    final totalDays = end.difference(start).inDays + 1;

    final metrics = MovementPeriodMetrics.fromMovements(movements);
    final balanceColor = metrics.netBalance > 0
        ? p.income
        : metrics.netBalance < 0
        ? p.expense
        : p.textPrimary;

    final effectiveSelectedDay = selectedPeriodDay ?? selectedDay;

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
                  color: p.income,
                  semanticType: StreamKpiSemanticType.income,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'range_period_expense',
                  label: 'Uscite',
                  value: formatEuro(metrics.totalExpense),
                  color: p.expense,
                  semanticType: StreamKpiSemanticType.expense,
                ),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: _MetricChip(
                  keyName: 'range_period_balance',
                  label: 'Saldo',
                  value:
                      '${metrics.netBalance > 0
                          ? '+'
                          : metrics.netBalance < 0
                          ? '-'
                          : ''}${formatEuro(metrics.netBalance.abs())}',
                  color: balanceColor,
                  semanticType: StreamKpiSemanticType.balance,
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          _MetricChip(
            keyName: 'range_period_movements_count',
            label: 'Movimenti',
            value: '${metrics.movementCount}',
            color: p.textPrimary,
            semanticType: StreamKpiSemanticType.count,
          ),
          if (selectedPeriodDay != null) ...[
            const SizedBox(height: StreamSpacing.md),
            _buildSelectedPeriodDayChip(context, selectedPeriodDay!),
          ],
          const SizedBox(height: StreamSpacing.md),
          if (totalDays <= 31)
            _buildShortRangeGrid(start, end, effectiveSelectedDay)
          else if (totalDays <= 183)
            _buildLongRangeGrid(start, end, effectiveSelectedDay)
          else
            _buildSemesterRangeGrid(start, end, effectiveSelectedDay),
          if (totalDays > 31) ...[
            const SizedBox(height: StreamSpacing.md),
            const _RangeHeatmapLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedPeriodDayChip(BuildContext context, DateTime day) {
    final p = context.$palette;
    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];
    final label = '${day.day} ${months[day.month - 1]} ${day.year}';

    String clearLabel;
    Key chipKey;
    Key clearKey;
    switch (timeFilter.mode) {
      case TimeFilterMode.week:
        clearLabel = 'Tutta settimana';
        chipKey = const Key('period_selected_day_chip');
        clearKey = const Key('week_clear_selected_day');
      case TimeFilterMode.month:
        clearLabel = 'Tutto mese';
        chipKey = const Key('period_selected_day_chip');
        clearKey = const Key('month_clear_selected_day');
      case TimeFilterMode.year:
        clearLabel = 'Tutto anno';
        chipKey = const Key('period_selected_day_chip');
        clearKey = const Key('year_clear_selected_day');
      case TimeFilterMode.customRange:
        clearLabel = 'Tutto intervallo';
        chipKey = const Key('range_selected_day_chip');
        clearKey = const Key('range_clear_selected_day');
      case TimeFilterMode.day:
        clearLabel = 'Tutto il giorno';
        chipKey = const Key('period_selected_day_chip');
        clearKey = const Key('day_clear_selected_day');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            key: chipKey,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: p.primary.withValues(
                alpha: p.brightness == Brightness.light ? 0.14 : 0.24,
              ),
              borderRadius: BorderRadius.circular(StreamRadius.full),
              border: Border.all(color: p.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.today, size: 14, color: p.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  key: Key(
                    'period_selected_day_${day.year}_${day.month}_${day.day}',
                  ),
                  style: StreamTypography.micro.copyWith(
                    color: p.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: StreamSpacing.sm),
          TextButton.icon(
            key: clearKey,
            icon: const Icon(Icons.close, size: 14),
            label: Text(clearLabel),
            style: TextButton.styleFrom(
              foregroundColor: p.textSecondary,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: onClearSelectedDay,
          ),
        ],
      ),
    );
  }

  Widget _buildShortRangeGrid(
    DateTime start,
    DateTime end,
    DateTime? effectiveSelectedDay,
  ) {
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
        final p = context.$palette;
        final cells = <Widget>[];
        for (int i = 0; i < firstWeekday - 1; i++) {
          cells.add(const SizedBox.shrink());
        }
        for (int offset = 0; offset < totalDays; offset++) {
          final dayDate = start.add(Duration(days: offset));
          final total = dailyTotals[offset] ?? 0.0;
          final isSelected =
              effectiveSelectedDay != null &&
              effectiveSelectedDay.year == dayDate.year &&
              effectiveSelectedDay.month == dayDate.month &&
              effectiveSelectedDay.day == dayDate.day;
          final bgColor = total > 0
              ? heatmapColorForAmount(total, settings: settings)
              : p.surfaceElevated.withValues(
                  alpha: p.brightness == Brightness.light ? 0.72 : 0.5,
                );
          final onBg = StreamSurfaceTokens.onAccent(bgColor);

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
                      ? Border.all(color: p.primary, width: 2)
                      : total > 0
                      ? Border.all(
                          color: p.divider.withValues(alpha: 0.15),
                          width: 0.5,
                        )
                      : Border.all(
                          color: p.divider.withValues(alpha: 0.06),
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
                    color: total > 0 ? onBg : p.textMuted,
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
                    color: isWeekend ? p.textMuted : p.textSecondary,
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
                    Expanded(child: cells[i + j]),
                  ],
                ],
              ),
            ),
          );
        }

        return KeyedSubtree(
          key: const Key('range_heatmap'),
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        );
      },
    );
  }

  Widget _buildLongRangeGrid(
    DateTime start,
    DateTime end,
    DateTime? effectiveSelectedDay,
  ) {
    final firstDay = start;
    final lastDay = end;
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
                ((constraints.maxWidth -
                            dayLabelWidth -
                            gap * (totalWeeks - 1)) /
                        totalWeeks)
                    .clamp(8.0, 22.0);
            final cellHeight = cellWidth;

            return Column(
              key: const Key('range_heatmap'),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRangeMonthLabelRow(
                  context,
                  weeks,
                  cellWidth,
                  dayLabelWidth,
                  gap,
                ),
                const SizedBox(height: 2),
                for (int dow = 0; dow < 7; dow++)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: _buildRangeDayRow(
                      context: context,
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
                      effectiveSelectedDay: effectiveSelectedDay,
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
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                _rangeMonthLabels[monthChanges[entry.key]! - 1],
                style: StreamTypography.micro.copyWith(
                  color: p.textMuted,
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
    required BuildContext context,
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
    required DateTime? effectiveSelectedDay,
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
              _rangeDayLabels[dow],
              style: TextStyle(
                fontSize: 8,
                color: p.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        for (int col = 0; col < weeks.length; col++) ...[
          if (col > 0) SizedBox(width: gap),
          _buildRangeCell(
            context,
            weeks[col][dow],
            cellWidth,
            cellHeight,
            daysInRange,
            todayDate,
            settings,
            start,
            end,
            effectiveSelectedDay,
          ),
        ],
      ],
    );
  }

  Widget _buildRangeCell(
    BuildContext context,
    DateTime? date,
    double width,
    double height,
    Map<int, double> daysInRange,
    DateTime todayDate,
    HeatmapSettings settings,
    DateTime start,
    DateTime end,
    DateTime? effectiveSelectedDay,
  ) {
    final p = context.$palette;
    if (date == null) {
      return SizedBox(width: width, height: height);
    }

    final key = date.month * 100 + date.day;
    final total = daysInRange[key] ?? 0.0;
    final isToday = date == todayDate;
    final sel = effectiveSelectedDay;
    final isSelected =
        sel != null &&
        sel.year == date.year &&
        sel.month == date.month &&
        sel.day == date.day;

    final bgColor = total > 0
        ? heatmapColorForAmount(total, settings: settings)
        : Colors.transparent;

    return GestureDetector(
      onTap: onDaySelected != null ? () => onDaySelected!(date) : null,
      child: Container(
        key: Key('range_heatmap_day_${date.year}_${date.month}_${date.day}'),
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

  Widget _buildSemesterRangeGrid(
    DateTime start,
    DateTime end,
    DateTime? effectiveSelectedDay,
  ) {
    final semesterBlocks = <_SemesterBlock>[];
    var cursor = DateTime(start.year, start.month, 1);

    while (!cursor.isAfter(end)) {
      final semStartMonth = cursor.month <= 6 ? 1 : 7;
      final semEndMonth = semStartMonth == 1 ? 6 : 12;
      final blockStart = DateTime(cursor.year, semStartMonth, 1);
      final blockEnd = DateTime(cursor.year, semEndMonth + 1, 0);

      semesterBlocks.add(
        _SemesterBlock(
          startDate: blockStart.isBefore(start) ? start : blockStart,
          endDate: blockEnd.isAfter(end) ? end : blockEnd,
          year: cursor.year,
          startMonth: blockStart.month,
          endMonth: blockEnd.month,
        ),
      );

      cursor = DateTime(cursor.year, semEndMonth + 1, 1);
    }

    return KeyedSubtree(
      key: const Key('range_semester_heatmap'),
      child: ValueListenableBuilder<HeatmapSettings>(
        valueListenable: PreferencesService.heatmapSettingsNotifier,
        builder: (context, settings, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final block in semesterBlocks)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: block == semesterBlocks.last ? 0 : StreamSpacing.md,
                  ),
                  child: _RangeSemesterGrid(
                    startDate: block.startDate,
                    endDate: block.endDate,
                    year: block.year,
                    startMonth: block.startMonth,
                    endMonth: block.endMonth,
                    movements: movements,
                    effectiveSelectedDay: effectiveSelectedDay,
                    onDaySelected: onDaySelected,
                    settings: settings,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static const _weekdayLabels = [
    'Lun',
    'Mar',
    'Mer',
    'Gio',
    'Ven',
    'Sab',
    'Dom',
  ];
  static const _rangeDayLabels = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
  static const _rangeMonthLabels = [
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
}

class _SemesterBlock {
  final DateTime startDate;
  final DateTime endDate;
  final int year;
  final int startMonth;
  final int endMonth;

  const _SemesterBlock({
    required this.startDate,
    required this.endDate,
    required this.year,
    required this.startMonth,
    required this.endMonth,
  });
}

class _RangeSemesterGrid extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final int year;
  final int startMonth;
  final int endMonth;
  final List<Movement> movements;
  final DateTime? effectiveSelectedDay;
  final ValueChanged<DateTime>? onDaySelected;
  final HeatmapSettings settings;

  const _RangeSemesterGrid({
    required this.startDate,
    required this.endDate,
    required this.year,
    required this.startMonth,
    required this.endMonth,
    required this.movements,
    required this.effectiveSelectedDay,
    required this.onDaySelected,
    required this.settings,
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
    final firstDay = startDate;
    final lastDay = endDate;
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

    final daysInRange = <int, double>{};
    for (final m in movements) {
      if (m.isTransfer) continue;
      if (!m.isExpense) continue;
      if (!m.date.isBefore(firstDay) && !m.date.isAfter(lastDay)) {
        final key = m.date.month * 100 + m.date.day;
        daysInRange.update(key, (v) => v + m.amount, ifAbsent: () => m.amount);
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWeeks = weeks.length;
        final dayLabelWidth = 14.0;
        final gap = 1.5;
        final cellWidth =
            ((constraints.maxWidth - dayLabelWidth - gap * (totalWeeks - 1)) /
                    totalWeeks)
                .clamp(8.0, 22.0);
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
                  daysInRange: daysInRange,
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
              padding: const EdgeInsets.only(left: 2, bottom: 2),
              child: Text(
                _monthLabels[monthChanges[entry.key]! - 1],
                style: StreamTypography.micro.copyWith(
                  color: p.textMuted,
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

  Widget _buildDayRow({
    required BuildContext context,
    required int dow,
    required List<List<DateTime?>> weeks,
    required double cellWidth,
    required double cellHeight,
    required double dayLabelWidth,
    required double gap,
    required Map<int, double> daysInRange,
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
                fontSize: 8,
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
            daysInRange,
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
    Map<int, double> daysInRange,
    DateTime todayDate,
  ) {
    final p = context.$palette;
    if (date == null) {
      return SizedBox(width: width, height: height);
    }

    final key = date.month * 100 + date.day;
    final total = daysInRange[key] ?? 0.0;
    final isToday = date == todayDate;
    final sel = effectiveSelectedDay;
    final isSelected =
        sel != null &&
        sel.year == date.year &&
        sel.month == date.month &&
        sel.day == date.day;

    final bgColor = total > 0
        ? heatmapColorForAmount(total, settings: settings)
        : Colors.transparent;

    return GestureDetector(
      onTap: onDaySelected != null ? () => onDaySelected!(date) : null,
      child: Container(
        key: Key('range_semester_day_${date.year}_${date.month}_${date.day}'),
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

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String keyName;
  final StreamKpiSemanticType semanticType;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.keyName,
    required this.semanticType,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 100),
      child: StreamKpiCard(
        cardKey: Key(keyName),
        title: label,
        value: value,
        semanticType: semanticType,
        accentColor: color,
        density: StreamKpiDensity.tight,
        layout: StreamKpiLayout.stacked,
        uppercaseTitle: false,
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String keyName;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DayChip({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Container(
      key: Key(keyName),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: StreamTypography.micro.copyWith(color: p.textSecondary),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: StreamTypography.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayKpi extends StatelessWidget {
  final String keyName;
  final String label;
  final String value;
  final Color color;
  final StreamKpiSemanticType semanticType;

  const _DayKpi({
    required this.keyName,
    required this.label,
    required this.value,
    required this.color,
    required this.semanticType,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamKpiCard(
        cardKey: Key(keyName),
        title: label,
        value: value,
        semanticType: semanticType,
        accentColor: color,
        density: StreamKpiDensity.compact,
        layout: StreamKpiLayout.centered,
        uppercaseTitle: false,
      ),
    );
  }
}

class _DayExpenseBreakdown extends StatelessWidget {
  final DateTime dayDate;
  final List<Movement> movements;
  final List<Category> categories;
  final List<Subcategory> subcategories;
  final AppDatabase? db;
  final ValueChanged<Movement>? onEdit;
  final ValueChanged<Movement>? onDuplicate;
  final ValueChanged<Movement>? onSaveAsFavorite;
  final ValueChanged<Movement>? onAddQuick;
  final ValueChanged<Movement>? onDelete;

  const _DayExpenseBreakdown({
    required this.dayDate,
    required this.movements,
    required this.categories,
    required this.subcategories,
    this.db,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onAddQuick,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final expenseByCat = <String, double>{};
    for (final m in movements) {
      if (m.isTransfer || !m.isExpense) continue;
      expenseByCat.update(
        m.categoryId,
        (v) => v + m.amount,
        ifAbsent: () => m.amount,
      );
    }
    if (expenseByCat.isEmpty) return const SizedBox.shrink();

    final total = expenseByCat.values.fold(0.0, (a, b) => a + b);
    final entries = expenseByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final catMap = {for (final c in categories) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ripartizione spese',
              style: StreamTypography.captionBold.copyWith(
                color: p.textSecondary,
              ),
            ),
            if (entries.length > 1)
              TextButton.icon(
                key: const Key('day_detail_button'),
                icon: const Icon(Icons.chevron_right, size: 16),
                label: const Text('Vedi dettaglio'),
                style: TextButton.styleFrom(
                  foregroundColor: p.primary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showDetailSheet(context),
              ),
          ],
        ),
        const SizedBox(height: StreamSpacing.sm),
        ...entries.map((e) {
          final cat = catMap[e.key];
          final catColor = Color(cat?.color ?? 0xFF888888);
          final catIcon = cat != null
              ? StreamIconLibrary.getIcon(cat.iconKey)
              : Icons.category;
          final fraction = total > 0 ? e.value / total : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(catIcon, size: 14, color: catColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cat?.name ?? e.key,
                        style: StreamTypography.micro.copyWith(
                          color: p.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatEuro(e.value),
                      style: StreamTypography.micro.copyWith(
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    backgroundColor: catColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(catColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showDetailSheet(BuildContext context) {
    final p = context.$palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _DayExpenseDetailSheet(
            dayDate: dayDate,
            movements: movements,
            categories: categories,
            subcategories: subcategories,
            scrollController: scrollController,
            db: db,
            onEdit: onEdit,
            onDuplicate: onDuplicate,
            onSaveAsFavorite: onSaveAsFavorite,
            onAddQuick: onAddQuick,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }
}

class _DayExpenseDetailSheet extends StatelessWidget {
  final DateTime dayDate;
  final List<Movement> movements;
  final List<Category> categories;
  final List<Subcategory> subcategories;
  final ScrollController scrollController;
  final AppDatabase? db;
  final ValueChanged<Movement>? onEdit;
  final ValueChanged<Movement>? onDuplicate;
  final ValueChanged<Movement>? onSaveAsFavorite;
  final ValueChanged<Movement>? onAddQuick;
  final ValueChanged<Movement>? onDelete;

  const _DayExpenseDetailSheet({
    required this.dayDate,
    required this.movements,
    required this.categories,
    required this.subcategories,
    required this.scrollController,
    this.db,
    this.onEdit,
    this.onDuplicate,
    this.onSaveAsFavorite,
    this.onAddQuick,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final expenseMoves =
        movements.where((m) => !m.isTransfer && m.isExpense).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final total = expenseMoves.fold(0.0, (sum, m) => sum + m.amount);

    final catMap = {for (final c in categories) c.id: c};
    final subcatMap = {for (final s in subcategories) s.id: s};
    final hasCallbacks =
        onEdit != null ||
        onDuplicate != null ||
        onSaveAsFavorite != null ||
        onAddQuick != null ||
        onDelete != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: p.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Dettaglio spese — ${_formatDate(dayDate)}',
            style: StreamTypography.h3.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${expenseMoves.length} movimenti · ${formatEuro(total)}',
            style: StreamTypography.caption.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: expenseMoves.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final m = expenseMoves[index];
                final cat = catMap[m.categoryId];
                final subcat = m.subcategoryId != null
                    ? subcatMap[m.subcategoryId]
                    : null;
                final account = db?.accounts
                    .where((a) => a.id == m.accountId)
                    .firstOrNull;
                final destAccount = m.destinationAccountId != null
                    ? db?.accounts
                          .where((a) => a.id == m.destinationAccountId)
                          .firstOrNull
                    : null;
                final beneficiaryProfile = db?.resolveBeneficiaryProfile(
                  m.payee,
                );

                return MovementCard(
                  movement: m,
                  category: cat,
                  subcategory: subcat,
                  account: account,
                  destinationAccount: destAccount,
                  beneficiaryDisplayName: db?.resolveBeneficiaryDisplayName(
                    m.payee,
                  ),
                  beneficiaryIconKey: beneficiaryProfile?.iconKey,
                  beneficiaryColor: beneficiaryProfile?.color,
                  showNotes: false,
                  showDate: true,
                  onTap: hasCallbacks && onEdit != null
                      ? () => onEdit!(m)
                      : null,
                  onEdit: onEdit != null ? () => onEdit!(m) : null,
                  onDuplicate: onDuplicate != null
                      ? () => onDuplicate!(m)
                      : null,
                  onSaveAsFavorite: onSaveAsFavorite != null
                      ? () => onSaveAsFavorite!(m)
                      : null,
                  onAddQuick: onAddQuick != null ? () => onAddQuick!(m) : null,
                  onDelete: onDelete != null ? () => onDelete!(m) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _RangeHeatmapLegend extends StatelessWidget {
  const _RangeHeatmapLegend();

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return ValueListenableBuilder<HeatmapSettings>(
      valueListenable: PreferencesService.heatmapSettingsNotifier,
      builder: (context, settings, _) {
        final bands = settings.bands;
        return Container(
          key: const Key('range_heatmap_legend'),
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
