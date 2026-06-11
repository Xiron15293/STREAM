import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';
import '../utils/movement_search.dart';
import '../widgets/expense_heatmap.dart';
import '../widgets/grouped_movements_list.dart';
import '../widgets/movement_card.dart';
import '../widgets/movement_picker.dart';
import '../widgets/movements_heatmap_preview_card.dart';
import '../widgets/time_filter_bar.dart';

class MovementsScreen extends StatefulWidget {
  final AppDatabase db;

  const MovementsScreen({super.key, required this.db});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showNotes = false;
  late TimeFilter _activeFilter;
  String _searchQuery = '';
  DateTime? _selectedDay;
  late DateTime _visibleCalendarMonth;
  DateTime? _lastPickedDate;
  MovementType? _dayFilter;
  late final VoidCallback _modeListener;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _activeFilter = TimeFilter.month(now.year, now.month);
    _selectedDay = now;
    _visibleCalendarMonth = DateTime(now.year, now.month, 1);
    _loadShowNotes();
    _initViewMode();
    PreferencesService.loadHeatmapSettings();
    _modeListener = () {
      if (mounted) setState(() {});
    };
    PreferencesService.movementsViewModeNotifier.addListener(_modeListener);
  }

  @override
  void dispose() {
    PreferencesService.movementsViewModeNotifier.removeListener(_modeListener);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShowNotes() async {
    final showNotes = await PreferencesService.loadShowNotes();
    if (mounted) setState(() => _showNotes = showNotes);
  }

  Future<void> _initViewMode() async {
    final mode = await PreferencesService.loadMovementsViewMode();
    PreferencesService.movementsViewModeNotifier.value = mode;
  }

  Future<void> _toggleShowNotes(bool value) async {
    await PreferencesService.saveShowNotes(value);
    if (mounted) setState(() => _showNotes = value);
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(
            StreamSpacing.lg,
            StreamSpacing.lg,
            StreamSpacing.lg,
            StreamSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Impostazioni lista', style: StreamTypography.h3),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: StreamSpacing.md),
              SwitchListTile(
                title: const Text('Mostra note nei movimenti'),
                subtitle: const Text(
                  'Visualizza la nota sotto ogni movimento nella lista',
                ),
                value: _showNotes,
                onChanged: (value) {
                  _showNotes = value;
                  setSheetState(() {});
                  _toggleShowNotes(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimenti'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _showNotes ? StreamColors.primary : StreamColors.textMuted,
            ),
            tooltip: 'Impostazioni lista',
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final allMovements = widget.db.movements;
          final periodFilteredMovements = allMovements.filterByTime(
            _activeFilter,
          );
          final searchFilteredMovements = searchMovements(
            movements: allMovements,
            query: _searchQuery,
            filter: _activeFilter,
            categories: widget.db.categories,
            accounts: widget.db.accounts,
          );
          final hasQuery = _searchQuery.trim().isNotEmpty;
          final viewMode = PreferencesService.movementsViewModeNotifier.value;

          Widget body;
          if (allMovements.isEmpty) {
            body = _buildEmptyAll();
          } else if (viewMode == MovementsViewMode.listHeatmap) {
            if (searchFilteredMovements.isEmpty) {
              body = hasQuery ? _buildEmptySearch() : _buildEmptyPeriod();
            } else {
              body = GroupedMovementsList(
                key: const Key('movements_layout_list_heatmap'),
                topWidget: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StreamSpacing.lg,
                    0,
                    StreamSpacing.lg,
                    0,
                  ),
                  child: MovementsHeatmapPreviewCard(
                    allMovements: searchFilteredMovements,
                    year: _visibleCalendarMonth.year,
                    month: _visibleCalendarMonth.month,
                    selectedDay: _selectedDay,
                    onDaySelected: (day) => setState(() => _selectedDay = day),
                    onOpenCalendar: () {
                      PreferencesService.saveMovementsViewMode(
                        MovementsViewMode.calendar,
                      );
                    },
                  ),
                ),
                movements: searchFilteredMovements,
                db: widget.db,
                showNotes: _showNotes || _searchQuery.trim().isNotEmpty,
                onEdit: (m) => _showPicker(context, prefill: m),
                onDuplicate: (m) {
                  widget.db.duplicateMovement(m);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Movimento duplicato')),
                  );
                },
                onSaveAsFavorite: (m) {
                  widget.db.saveMovementAsFavorite(m);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Salvato nei preferiti')),
                  );
                },
                onDelete: (m) {
                  widget.db.deleteMovement(m.id);
                },
              );
            }
          } else if (viewMode == MovementsViewMode.calendar) {
            body = _buildCalendar(
              periodFilteredMovements: periodFilteredMovements,
              searchFilteredMovements: searchFilteredMovements,
              hasQuery: hasQuery,
            );
          } else {
            body = _buildAdvancedHeatmap(
              periodFilteredMovements: periodFilteredMovements,
              searchFilteredMovements: searchFilteredMovements,
              hasQuery: hasQuery,
            );
          }

          return Column(
            children: [
              _buildInlineSelector(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  0,
                  StreamSpacing.lg,
                  0,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Cerca titolo, nota, categoria o conto',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Pulisci ricerca',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                  ),
                ),
              ),
              TimeFilterBar(
                activeFilter: _activeFilter,
                onChanged: _setActiveFilter,
                onDatePicked: _rememberPickedDate,
              ),
              const SizedBox(height: StreamSpacing.xs),
              Expanded(child: body),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'movements_fab',
        onPressed: () => _showPicker(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildInlineSelector() {
    final viewMode = PreferencesService.movementsViewModeNotifier.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StreamSpacing.lg,
        0,
        StreamSpacing.lg,
        0,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<MovementsViewMode>(
          key: const Key('movements_mode_inline_selector'),
          segments: [
            ButtonSegment<MovementsViewMode>(
              value: MovementsViewMode.listHeatmap,
              label: const KeyedSubtree(
                key: Key('movements_mode_inline_list'),
                child: Text('Lista'),
              ),
              icon: const Icon(Icons.list, size: 18),
            ),
            ButtonSegment<MovementsViewMode>(
              value: MovementsViewMode.calendar,
              label: const KeyedSubtree(
                key: Key('movements_mode_inline_calendar'),
                child: Text('Calendario'),
              ),
              icon: const Icon(Icons.calendar_month, size: 18),
            ),
            ButtonSegment<MovementsViewMode>(
              value: MovementsViewMode.advancedHeatmap,
              label: const KeyedSubtree(
                key: Key('movements_mode_inline_advanced'),
                child: Text('Heatmap'),
              ),
              icon: const Icon(Icons.analytics_outlined, size: 18),
            ),
          ],
          selected: {viewMode},
          onSelectionChanged: (Set<MovementsViewMode> v) {
            PreferencesService.saveMovementsViewMode(v.first);
          },
          showSelectedIcon: false,
        ),
      ),
    );
  }

  void _rememberPickedDate(DateTime date) {
    _lastPickedDate = DateTime(date.year, date.month, date.day);
  }

  void _setActiveFilter(TimeFilter filter) {
    setState(() {
      final pickedDate = _lastPickedDate;
      _lastPickedDate = null;
      _activeFilter = filter;
      final anchor = _anchorDateForFilter(filter, pickedDate: pickedDate);
      _visibleCalendarMonth = DateTime(anchor.year, anchor.month, 1);
      _selectedDay = _clampSelectedDay(anchor, filter);
      _dayFilter = null;
    });
  }

  DateTime _anchorDateForFilter(TimeFilter filter, {DateTime? pickedDate}) {
    if (pickedDate != null && filter.contains(pickedDate)) {
      return DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
    }

    final currentSelected = _selectedDay;
    if (currentSelected != null && filter.contains(currentSelected)) {
      return DateTime(
        currentSelected.year,
        currentSelected.month,
        currentSelected.day,
      );
    }

    if (filter.mode == TimeFilterMode.year &&
        _visibleCalendarMonth.year == filter.startDate.year) {
      return DateTime(
        _visibleCalendarMonth.year,
        _visibleCalendarMonth.month,
        1,
      );
    }

    return DateTime(
      filter.startDate.year,
      filter.startDate.month,
      filter.startDate.day,
    );
  }

  DateTime _clampSelectedDay(DateTime date, TimeFilter filter) {
    switch (filter.mode) {
      case TimeFilterMode.day:
        return DateTime(
          filter.startDate.year,
          filter.startDate.month,
          filter.startDate.day,
        );
      case TimeFilterMode.month:
      case TimeFilterMode.year:
      case TimeFilterMode.customRange:
        final day = date.day.clamp(
          1,
          DateTime(date.year, date.month + 1, 0).day,
        );
        final clamped = DateTime(date.year, date.month, day);
        if (filter.contains(clamped)) return clamped;
        return DateTime(
          filter.startDate.year,
          filter.startDate.month,
          filter.startDate.day,
        );
    }
  }

  void _moveCalendarMonth(int delta) {
    switch (_activeFilter.mode) {
      case TimeFilterMode.day:
        final newDay = _activeFilter.startDate.add(Duration(days: delta));
        _setActiveFilter(TimeFilter.day(newDay));
      case TimeFilterMode.month:
        final base = DateTime(
          _activeFilter.startDate.year,
          _activeFilter.startDate.month + delta,
          1,
        );
        _setActiveFilter(TimeFilter.month(base.year, base.month));
      case TimeFilterMode.year:
        _setActiveFilter(TimeFilter.year(_activeFilter.startDate.year + delta));
      case TimeFilterMode.customRange:
        final shift = Duration(days: delta * 30);
        _setActiveFilter(
          TimeFilter.customRange(
            _activeFilter.startDate.add(shift),
            _activeFilter.endDate.add(shift),
          ),
        );
    }
  }

  Widget _buildCalendar({
    required List<Movement> periodFilteredMovements,
    required List<Movement> searchFilteredMovements,
    required bool hasQuery,
  }) {
    final year = _visibleCalendarMonth.year;
    final month = _visibleCalendarMonth.month;
    final displayedMovements = _displayedMovementsForActiveFilter(
      searchFilteredMovements,
    );

    return ListView(
      key: const Key('movements_layout_calendar'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        _buildMonthNavigator(keyName: 'calendar_month_navigator'),
        const SizedBox(height: StreamSpacing.md),
        Container(
          key: const Key('calendar_month_surface'),
          padding: const EdgeInsets.all(StreamSpacing.md),
          decoration: BoxDecoration(
            color: StreamColors.surface,
            borderRadius: BorderRadius.circular(StreamRadius.md),
            border: Border.all(color: StreamColors.divider),
          ),
          child: Column(
            children: [
              ExpenseHeatmap(
                key: const Key('calendar_large_month_heatmap'),
                allMovements: searchFilteredMovements,
                year: year,
                month: month,
                selectedDay: _selectedDay,
                onDaySelected: (day) => setState(() => _selectedDay = day),
                variant: ExpenseHeatmapVariant.calendar,
              ),
              const HeatmapLegend(),
            ],
          ),
        ),
        const SizedBox(height: StreamSpacing.md),
        _buildPeriodMovementsPanel(
          displayedMovements,
          periodFilteredMovements: periodFilteredMovements,
          hasQuery: hasQuery,
        ),
      ],
    );
  }

  Widget _buildAdvancedHeatmap({
    required List<Movement> periodFilteredMovements,
    required List<Movement> searchFilteredMovements,
    required bool hasQuery,
  }) {
    final year = _visibleCalendarMonth.year;
    final month = _visibleCalendarMonth.month;
    final displayedMovements = _displayedMovementsForActiveFilter(
      searchFilteredMovements,
    );

    final filteredDayMovements = _dayFilter != null
        ? displayedMovements.where((m) => m.type == _dayFilter).toList()
        : displayedMovements;

    return ListView(
      key: const Key('movements_layout_advanced_heatmap'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        _buildMonthNavigator(keyName: 'advanced_heatmap_month_navigator'),
        const SizedBox(height: StreamSpacing.md),
        Container(
          key: const Key('advanced_heatmap_surface'),
          padding: const EdgeInsets.all(StreamSpacing.md),
          decoration: BoxDecoration(
            color: StreamColors.surface,
            borderRadius: BorderRadius.circular(StreamRadius.md),
            border: Border.all(
              color: StreamColors.primary.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: StreamColors.primary),
                  const SizedBox(width: StreamSpacing.sm),
                  Text('Analisi heatmap', style: StreamTypography.h3),
                ],
              ),
              const SizedBox(height: StreamSpacing.md),
              KeyedSubtree(
                key: const Key('advanced_heatmap_grid'),
                child: ExpenseHeatmap(
                  key: const Key('advanced_large_heatmap'),
                  allMovements: searchFilteredMovements,
                  year: year,
                  month: month,
                  selectedDay: _selectedDay,
                  onDaySelected: (day) => setState(() => _selectedDay = day),
                  variant: ExpenseHeatmapVariant.advanced,
                ),
              ),
              const HeatmapLegend(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: StreamSpacing.md),
          child: _buildPeriodMovementsPanel(
            filteredDayMovements,
            periodFilteredMovements: periodFilteredMovements,
            hasQuery: hasQuery,
            includeTypeFilters: true,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigator({required String keyName}) {
    final monthLabel = TimeFilter.month(
      _visibleCalendarMonth.year,
      _visibleCalendarMonth.month,
    ).label;

    return Row(
      key: Key(keyName),
      children: [
        IconButton.filledTonal(
          key: Key('${keyName}_prev'),
          tooltip: 'Mese precedente',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _moveCalendarMonth(-1),
        ),
        const SizedBox(width: StreamSpacing.sm),
        Expanded(
          child: Container(
            key: const Key('movements_month_title'),
            padding: const EdgeInsets.symmetric(
              horizontal: StreamSpacing.md,
              vertical: StreamSpacing.md,
            ),
            decoration: BoxDecoration(
              color: StreamColors.surfaceElevated,
              borderRadius: BorderRadius.circular(StreamRadius.md),
            ),
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: StreamTypography.h3,
            ),
          ),
        ),
        const SizedBox(width: StreamSpacing.sm),
        IconButton.filledTonal(
          key: Key('${keyName}_next'),
          tooltip: 'Mese successivo',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _moveCalendarMonth(1),
        ),
      ],
    );
  }

  List<Movement> _displayedMovementsForActiveFilter(List<Movement> movements) {
    return movements;
  }

  Widget _buildPeriodMovementsPanel(
    List<Movement> displayedMovements, {
    required List<Movement> periodFilteredMovements,
    required bool hasQuery,
    bool includeTypeFilters = false,
  }) {
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
          includeTypeFilters
              ? KeyedSubtree(
                  key: const Key('advanced_heatmap_kpi_panel'),
                  child: _buildPeriodSummary(displayedMovements),
                )
              : _buildPeriodSummary(displayedMovements),
          if (includeTypeFilters) _buildDayFilterChips(),
          const Divider(height: 1, color: StreamColors.divider),
          displayedMovements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(StreamSpacing.xl),
                  child: Center(
                    child: Text(
                      hasQuery
                          ? 'Nessun risultato in questo periodo'
                          : periodFilteredMovements.isEmpty
                          ? 'Nessun movimento in questo periodo'
                          : 'Nessun movimento per questo filtro',
                      style: StreamTypography.body.copyWith(
                        color: StreamColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildDayMovementsList(displayedMovements),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary(List<Movement> movements) {
    final income = _incomeTotal(movements);
    final expense = _expenseTotal(movements);
    final balance = income - expense;
    final count = movements.length;

    return Padding(
      key: const Key('day_summary'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_activeFilter.label, style: StreamTypography.h3),
          const SizedBox(height: 8),
          Row(
            children: [
              _dayKpi(
                'Entrate',
                formatHeatmapAmount(income),
                StreamColors.income,
                'day_income_total',
              ),
              const SizedBox(width: 12),
              _dayKpi(
                'Uscite',
                formatHeatmapAmount(expense),
                StreamColors.expense,
                'day_expense_total',
              ),
              const SizedBox(width: 12),
              _dayKpi(
                'Saldo',
                '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)}€',
                balance >= 0 ? StreamColors.income : StreamColors.expense,
                'day_balance',
              ),
              const SizedBox(width: 12),
              _dayKpi(
                'Movimenti',
                '$count',
                StreamColors.textPrimary,
                'day_movement_count',
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _incomeTotal(List<Movement> movements) {
    return movements.fold<double>(
      0,
      (sum, movement) => movement.isIncome && !movement.isTransfer
          ? sum + movement.amount
          : sum,
    );
  }

  double _expenseTotal(List<Movement> movements) {
    return movements.fold<double>(
      0,
      (sum, movement) => movement.isExpense && !movement.isTransfer
          ? sum + movement.amount
          : sum,
    );
  }

  Widget _dayKpi(String label, String value, Color color, String keyName) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            key: Key(keyName),
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: StreamTypography.captionBold.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDayFilterChips() {
    return Padding(
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
    final selected = _dayFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _dayFilter = type),
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

  Widget _buildDayMovementsList(
    List<Movement> movements, {
    bool scrollable = false,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: movements.length,
      separatorBuilder: (_, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final m = movements[index];
        final cat = widget.db.categories
            .where((c) => c.id == m.categoryId)
            .firstOrNull;
        final acc = widget.db.accounts
            .where((a) => a.id == m.accountId)
            .firstOrNull;
        final destAcc = m.destinationAccountId == null
            ? null
            : widget.db.accounts
                  .where((a) => a.id == m.destinationAccountId)
                  .firstOrNull;
        return MovementCard(
          movement: m,
          category: cat,
          account: acc,
          destinationAccount: destAcc,
          onTap: () => _showPicker(context, prefill: m),
        );
      },
    );
  }

  void _showPicker(BuildContext context, {Movement? prefill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovementPicker(db: widget.db, prefill: prefill),
    );
  }

  Widget _buildEmptyAll() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: StreamColors.textMuted,
          ),
          const SizedBox(height: StreamSpacing.lg),
          const Text('Nessun movimento', style: StreamTypography.h2),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Tocca + per aggiungerne uno',
            style: StreamTypography.body.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPeriod() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 64, color: StreamColors.textMuted),
          const SizedBox(height: StreamSpacing.lg),
          const Text(
            'Nessun movimento in questo periodo',
            style: StreamTypography.h2,
          ),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Prova a cambiare periodo',
            style: StreamTypography.body.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: StreamColors.textMuted),
          const SizedBox(height: StreamSpacing.lg),
          const Text('Nessun risultato', style: StreamTypography.h2),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Prova con un termine diverso o cambia periodo',
            style: StreamTypography.body.copyWith(
              color: StreamColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
