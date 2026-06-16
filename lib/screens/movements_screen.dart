import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/duplicate_date_selector.dart';
import '../utils/movement_search.dart';
import 'heatmap_settings_screen.dart';
import '../widgets/movement_picker.dart';
import '../widgets/movement_view_renderer.dart';
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
  DateTime? _selectedPeriodDay;
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
          } else {
            if (searchFilteredMovements.isEmpty) {
              body = hasQuery ? _buildEmptySearch() : _buildEmptyPeriod();
            } else {
              body = MovementViewRenderer(
                viewMode: viewMode,
                timeFilter: _activeFilter,
                movements: searchFilteredMovements,
                periodMovements: periodFilteredMovements,
                db: widget.db,
                showNotes: _showNotes || _searchQuery.trim().isNotEmpty,
                hasQuery: hasQuery,
                selectedDay: _selectedDay,
                selectedPeriodDay: _selectedPeriodDay,
                onDaySelected: _onHeatmapDayTap,
                onClearSelectedDay: _clearSelectedPeriodDay,
                dayFilter: _dayFilter,
                onDayFilterChanged: (MovementType? type) =>
                    setState(() => _dayFilter = type),
                onEdit: (movement) => _showPicker(context, prefill: movement),
                onDuplicate: (movement) async {
                  final date = await showDuplicateDateSheet(context);
                  if (date != null) {
                    widget.db.duplicateMovement(movement, date: date);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Movimento duplicato')),
                      );
                    }
                  }
                },
                onSaveAsFavorite: (movement) {
                  widget.db.saveMovementAsFavorite(movement);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Salvato nei preferiti')),
                  );
                },
                onAddQuick: (movement) {
                  widget.db.saveMovementAsQuick(movement);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Salvato nei rapidi')),
                  );
                },
                onDelete: (movement) {
                  widget.db.deleteMovement(movement.id);
                },
              );
            }
          }

          return Column(
            children: [
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
              if (_activeFilter.mode == TimeFilterMode.day)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    StreamSpacing.lg,
                    0,
                    StreamSpacing.lg,
                    StreamSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('movements_day_configure_heatmap_button'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HeatmapSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Configura heatmap'),
                    ),
                  ),
                ),
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

  void _rememberPickedDate(DateTime date) {
    _lastPickedDate = DateTime(date.year, date.month, date.day);
  }

  void _onHeatmapDayTap(DateTime day) {
    setState(() {
      switch (_activeFilter.mode) {
        case TimeFilterMode.day:
          _selectedDay = day;
          _activeFilter = TimeFilter.day(day);
          _visibleCalendarMonth = DateTime(day.year, day.month, 1);
        case TimeFilterMode.week:
        case TimeFilterMode.month:
        case TimeFilterMode.year:
        case TimeFilterMode.customRange:
          _selectedPeriodDay = day;
      }
    });
  }

  void _clearSelectedPeriodDay() {
    setState(() => _selectedPeriodDay = null);
  }

  void _setActiveFilter(TimeFilter filter) {
    setState(() {
      _selectedPeriodDay = null;
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
      case TimeFilterMode.week:
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
