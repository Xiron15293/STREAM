import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/preferences_service.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../screens/settings_screen.dart';
import '../theme.dart';
import 'expense_heatmap.dart';
import 'grouped_movements_list.dart';
import 'movement_card.dart';
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
  final ValueChanged<DateTime>? onDaySelected;
  final MovementType? dayFilter;
  final ValueChanged<MovementType?>? onDayFilterChanged;
  final ValueChanged<Movement> onEdit;
  final ValueChanged<Movement> onDuplicate;
  final ValueChanged<Movement> onSaveAsFavorite;
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
    required this.onDaySelected,
    required this.dayFilter,
    required this.onDayFilterChanged,
    required this.onEdit,
    required this.onDuplicate,
    required this.onSaveAsFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case MovementsViewMode.list:
        return _buildListMode(context);
      case MovementsViewMode.calendar:
        return _buildPanelMode(
          layoutKey: const Key('movements_layout_calendar'),
        );
      case MovementsViewMode.heatmap:
        return _buildPanelMode(
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
          if (timeFilter.mode == TimeFilterMode.year)
              PeriodHeatmapCard(
                timeFilter: timeFilter,
                movements: movements,
                selectedDay: selectedDay,
                onDaySelected: onDaySelected,
                compactHeader: true,
                categories: db.categories,
              footerAction: OutlinedButton.icon(
                key: const Key('movements_open_calendar_default_settings'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SettingsScreen(db: db)),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Vista calendario predefinita'),
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
                  MaterialPageRoute(builder: (_) => SettingsScreen(db: db)),
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
      onDelete: onDelete,
    );
  }

  Widget _buildPanelMode({
    required Key layoutKey,
    bool includeTypeFilters = false,
  }) {
    final displayedMovements = includeTypeFilters && dayFilter != null
        ? movements.where((movement) => movement.type == dayFilter).toList()
        : movements;

    return ListView(
      key: layoutKey,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        PeriodSummaryCard(timeFilter: timeFilter, movements: movements),
        const SizedBox(height: StreamSpacing.md),
        PeriodHeatmapCard(
          timeFilter: timeFilter,
          movements: movements,
          selectedDay: selectedDay,
          onDaySelected: onDaySelected,
          categories: db.categories,
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
          dayFilter: dayFilter,
          onDayFilterChanged: onDayFilterChanged,
          db: db,
          onEdit: onEdit,
        ),
      ],
    );
  }
}

class _MovementPanel extends StatelessWidget {
  final List<Movement> movements;
  final List<Movement> periodMovements;
  final bool hasQuery;
  final bool includeTypeFilters;
  final MovementType? dayFilter;
  final ValueChanged<MovementType?>? onDayFilterChanged;
  final AppDatabase db;
  final ValueChanged<Movement> onEdit;

  const _MovementPanel({
    required this.movements,
    required this.periodMovements,
    required this.hasQuery,
    required this.includeTypeFilters,
    required this.dayFilter,
    required this.onDayFilterChanged,
    required this.db,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
          movements.isEmpty
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
              : _buildMovementsList(),
        ],
      ),
    );
  }

  Widget _buildDayFilterChips() {
    return Padding(
      key: const Key('advanced_heatmap_kpi_panel'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _dayFilterChip('Tutti', null, 'day_filter_all'),
          const SizedBox(width: 4),
          _dayFilterChip('Entrate', MovementType.income, 'day_filter_income'),
          const SizedBox(width: 4),
          _dayFilterChip('Uscite', MovementType.expense, 'day_filter_expense'),
          const SizedBox(width: 4),
          _dayFilterChip(
            'Transfer',
            MovementType.transfer,
            'day_filter_transfer',
          ),
        ],
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

  Widget _buildMovementsList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movements.length,
      separatorBuilder: (_, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final movement = movements[index];
        final category = db.categories
            .where((category) => category.id == movement.categoryId)
            .firstOrNull;
        final account = db.accounts
            .where((account) => account.id == movement.accountId)
            .firstOrNull;
        final destinationAccount = movement.destinationAccountId == null
            ? null
            : db.accounts
                  .where(
                    (account) => account.id == movement.destinationAccountId,
                  )
                  .firstOrNull;
        final subcategory = movement.subcategoryId == null
            ? null
            : db.subcategories
                  .where((sub) => sub.id == movement.subcategoryId)
                  .firstOrNull;

        return MovementCard(
          movement: movement,
          category: category,
          subcategory: subcategory,
          account: account,
          destinationAccount: destinationAccount,
          onTap: () => onEdit(movement),
        );
      },
    );
  }
}
