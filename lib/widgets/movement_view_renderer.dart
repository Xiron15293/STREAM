import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/preferences_service.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../screens/heatmap_settings_screen.dart';
import '../theme.dart';
import 'expense_heatmap.dart';
import 'grouped_movements_list.dart';
import 'movements_heatmap_preview_card.dart';
import 'period_heatmap_card.dart';
import 'period_summary_card.dart';

class MovementViewRenderer extends StatelessWidget {
  final MovementsViewMode viewMode;
  final TimeFilter timeFilter;
  final List<Movement> movements;
  final List<Movement> periodMovements;
  final bool hasQuery;
  final bool showNotes;
  final AppDatabase db;
  final DateTime? selectedDay;
  final DateTime? selectedPeriodDay;
  final ValueChanged<DateTime>? onDaySelected;
  final VoidCallback? onClearSelectedDay;
  final MovementType? dayFilter;
  final ValueChanged<MovementType?>? onDayFilterChanged;
  final ValueChanged<Movement> onEdit;
  final ValueChanged<Movement> onDuplicate;
  final ValueChanged<Movement> onSaveAsFavorite;
  final ValueChanged<Movement> onAddQuick;
  final ValueChanged<Movement> onDelete;

  const MovementViewRenderer({
    super.key,
    required this.viewMode,
    required this.timeFilter,
    required this.movements,
    required this.periodMovements,
    required this.hasQuery,
    required this.showNotes,
    required this.db,
    required this.selectedDay,
    this.selectedPeriodDay,
    required this.onDaySelected,
    this.onClearSelectedDay,
    required this.dayFilter,
    required this.onDayFilterChanged,
    required this.onEdit,
    required this.onDuplicate,
    required this.onSaveAsFavorite,
    required this.onAddQuick,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case MovementsViewMode.list:
        return _buildListMode(context);
      case MovementsViewMode.calendar:
        return _buildPanelMode(
          context,
          layoutKey: const Key('movements_layout_calendar'),
        );
      case MovementsViewMode.heatmap:
        return _buildPanelMode(
          context,
          layoutKey: const Key('movements_layout_heatmap'),
          includeTypeFilters: true,
        );
    }
  }

  Widget _buildListMode(BuildContext context) {
    final previewMonth = timeFilter.mode == TimeFilterMode.day
        ? selectedDay ?? timeFilter.startDate
        : timeFilter.startDate;

    return GroupedMovementsList(
      key: const Key('movements_layout_list'),
      topWidget: Column(
        children: [
          if (timeFilter.mode == TimeFilterMode.year ||
              timeFilter.mode == TimeFilterMode.week)
            PeriodHeatmapCard(
              timeFilter: timeFilter,
              movements: movements,
              selectedDay: selectedDay,
              selectedPeriodDay: selectedPeriodDay,
              onDaySelected: onDaySelected,
              onClearSelectedDay: onClearSelectedDay,
              compactHeader: true,
              categories: db.categories,
              subcategories: db.subcategories,
              db: db,
              onEdit: onEdit,
              onDuplicate: onDuplicate,
              onSaveAsFavorite: onSaveAsFavorite,
              onAddQuick: onAddQuick,
              onDelete: onDelete,
              footerAction: OutlinedButton.icon(
                key: const Key('movements_card_configure_heatmap_button'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HeatmapSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Configura heatmap'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StreamSpacing.lg,
                    vertical: StreamSpacing.md,
                  ),
                  side: BorderSide(
                    color: StreamColors.primary.withValues(alpha: 0.8),
                  ),
                  foregroundColor: StreamColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StreamRadius.md),
                  ),
                ),
              ),
            )
          else
            MovementsHeatmapPreviewCard(
              allMovements: movements,
              year: previewMonth.year,
              month: previewMonth.month,
              selectedDay: selectedDay,
              onDaySelected: onDaySelected,
              onOpenSettings: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HeatmapSettingsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      movements: movements,
      db: db,
      showNotes: showNotes,
      onEdit: onEdit,
      onDuplicate: onDuplicate,
      onSaveAsFavorite: onSaveAsFavorite,
      onAddQuick: onAddQuick,
      onDelete: onDelete,
    );
  }

  Widget _buildPanelMode(
    BuildContext context, {
    required Key layoutKey,
    bool includeTypeFilters = false,
  }) {
    final displayedMovements = includeTypeFilters && dayFilter != null
        ? movements.where((movement) => movement.type == dayFilter).toList()
        : movements;

    return SingleChildScrollView(
      key: layoutKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        child: Column(
          children: [
            PeriodSummaryCard(timeFilter: timeFilter, movements: movements),
            const SizedBox(height: StreamSpacing.md),
            PeriodHeatmapCard(
              timeFilter: timeFilter,
              movements: movements,
              selectedDay: selectedDay,
              selectedPeriodDay: selectedPeriodDay,
              onDaySelected: onDaySelected,
              onClearSelectedDay: onClearSelectedDay,
              categories: db.categories,
              subcategories: db.subcategories,
              db: db,
              onEdit: onEdit,
              onDuplicate: onDuplicate,
              onSaveAsFavorite: onSaveAsFavorite,
              onAddQuick: onAddQuick,
              onDelete: onDelete,
              footerAction: OutlinedButton.icon(
                key: const Key('movements_card_configure_heatmap_button'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HeatmapSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Configura heatmap'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StreamSpacing.lg,
                    vertical: StreamSpacing.md,
                  ),
                  side: BorderSide(
                    color: StreamColors.primary.withValues(alpha: 0.8),
                  ),
                  foregroundColor: StreamColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StreamRadius.md),
                  ),
                ),
              ),
            ),
            if (timeFilter.mode != TimeFilterMode.day)
              Padding(
                padding: EdgeInsets.only(top: StreamSpacing.md),
                child: HeatmapLegend(),
              ),
            const SizedBox(height: StreamSpacing.md),
            _MovementPanel(
              movements: displayedMovements,
              periodMovements: periodMovements,
              hasQuery: hasQuery,
              includeTypeFilters: includeTypeFilters,
              showNotes: showNotes,
              dayFilter: dayFilter,
              onDayFilterChanged: onDayFilterChanged,
              db: db,
              onEdit: onEdit,
              onDuplicate: onDuplicate,
              onSaveAsFavorite: onSaveAsFavorite,
              onAddQuick: onAddQuick,
              onDelete: onDelete,
              selectedPeriodDay: selectedPeriodDay,
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementPanel extends StatelessWidget {
  final List<Movement> movements;
  final List<Movement> periodMovements;
  final bool hasQuery;
  final bool includeTypeFilters;
  final bool showNotes;
  final MovementType? dayFilter;
  final ValueChanged<MovementType?>? onDayFilterChanged;
  final AppDatabase db;
  final ValueChanged<Movement> onEdit;
  final ValueChanged<Movement> onDuplicate;
  final ValueChanged<Movement> onSaveAsFavorite;
  final ValueChanged<Movement> onAddQuick;
  final ValueChanged<Movement> onDelete;
  final DateTime? selectedPeriodDay;

  const _MovementPanel({
    required this.movements,
    required this.periodMovements,
    required this.hasQuery,
    required this.includeTypeFilters,
    required this.showNotes,
    required this.dayFilter,
    required this.onDayFilterChanged,
    required this.db,
    required this.onEdit,
    required this.onDuplicate,
    required this.onSaveAsFavorite,
    required this.onAddQuick,
    required this.onDelete,
    this.selectedPeriodDay,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMovements = selectedPeriodDay != null
        ? movements
              .where(
                (m) =>
                    m.date.year == selectedPeriodDay!.year &&
                    m.date.month == selectedPeriodDay!.month &&
                    m.date.day == selectedPeriodDay!.day,
              )
              .toList()
        : movements;

    return Container(
      key: const Key('day_movements_panel'),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: Border.all(color: StreamColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeTypeFilters) ...[
            const SizedBox(height: StreamSpacing.sm),
            _buildDayFilterChips(),
            const Divider(height: 1, color: StreamColors.divider),
          ],
          effectiveMovements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(StreamSpacing.xl),
                  child: Center(
                    child: Text(
                      hasQuery
                          ? 'Nessun risultato in questo periodo'
                          : periodMovements.isEmpty
                          ? 'Nessun movimento in questo periodo'
                          : 'Nessun movimento per questo filtro',
                      style: StreamTypography.body.copyWith(
                        color: StreamColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildMovementsList(effectiveMovements),
        ],
      ),
    );
  }

  Widget _buildDayFilterChips() {
    return Padding(
      key: const Key('advanced_heatmap_kpi_panel'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _dayFilterChip('Tutti', null, 'day_filter_all'),
            const SizedBox(width: 4),
            _dayFilterChip('Entrate', MovementType.income, 'day_filter_income'),
            const SizedBox(width: 4),
            _dayFilterChip(
              'Uscite',
              MovementType.expense,
              'day_filter_expense',
            ),
            const SizedBox(width: 4),
            _dayFilterChip(
              'Transfer',
              MovementType.transfer,
              'day_filter_transfer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayFilterChip(String label, MovementType? type, String keyName) {
    final selected = dayFilter == type;
    return GestureDetector(
      onTap: () => onDayFilterChanged?.call(type),
      child: Container(
        key: Key(keyName),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? StreamColors.primary : StreamColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: StreamTypography.micro.copyWith(
            color: selected ? Colors.white : StreamColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMovementsList(List<Movement> items) {
    return GroupedMovementsList(
      movements: items,
      db: db,
      showNotes: showNotes,
      filterType: dayFilter,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onEdit: (m) => onEdit(m),
      onDuplicate: (m) => onDuplicate(m),
      onSaveAsFavorite: (m) => onSaveAsFavorite(m),
      onAddQuick: (m) => onAddQuick(m),
      onDelete: (m) => onDelete(m),
    );
  }
}
