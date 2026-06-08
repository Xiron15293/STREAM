import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../models/daily_group.dart';
import '../theme.dart';
import '../widgets/movement_picker.dart';
import '../widgets/time_filter_bar.dart';
import '../widgets/movement_card.dart';
import '../widgets/day_header.dart';

class MovementsScreen extends StatefulWidget {
  final AppDatabase db;

  const MovementsScreen({super.key, required this.db});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  bool _showNotes = false;
  late TimeFilter _activeFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _activeFilter = TimeFilter.month(now.year, now.month);
    _loadShowNotes();
  }

  Future<void> _loadShowNotes() async {
    final showNotes = await PreferencesService.loadShowNotes();
    if (mounted) setState(() => _showNotes = showNotes);
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
          padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.xxl),
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
                subtitle: const Text('Visualizza la nota sotto ogni movimento nella lista'),
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
          final filtered = allMovements.filterByTime(_activeFilter);

          return Column(
            children: [
              TimeFilterBar(
                activeFilter: _activeFilter,
                onChanged: (f) => setState(() => _activeFilter = f),
              ),
              const SizedBox(height: StreamSpacing.sm),
              Expanded(
                child: allMovements.isEmpty
                    ? _buildEmptyAll()
                    : filtered.isEmpty
                        ? _buildEmptyPeriod()
                        : _buildMovementsList(filtered),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'movements_fab',
        onPressed: () => _showPicker(context),
        child: const Icon(Icons.add),
      ),
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
          Icon(Icons.receipt_long_outlined, size: 64, color: StreamColors.textMuted),
          const SizedBox(height: StreamSpacing.lg),
          const Text('Nessun movimento', style: StreamTypography.h2),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Tocca + per aggiungerne uno',
            style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
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
          const Text('Nessun movimento in questo periodo', style: StreamTypography.h2),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Prova a cambiare periodo',
            style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList(List<Movement> movements) {
    final groups = groupMovementsByDay(movements);
    final totalItems = groups.fold<int>(0, (sum, g) => sum + 1 + g.movements.length);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, 0, StreamSpacing.lg, 80),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        int cursor = 0;
        for (final group in groups) {
          final groupTotal = 1 + group.movements.length;
          if (index < cursor + groupTotal) {
            final localIdx = index - cursor;
            if (localIdx == 0) {
              return DayHeader(group: group);
            }
            final m = group.movements[localIdx - 1];
            final cat = widget.db.categories.where((c) => c.id == m.categoryId).firstOrNull;
            final acc = widget.db.accounts.where((a) => a.id == m.accountId).firstOrNull;
            return MovementCard(
              movement: m,
              category: cat,
              account: acc,
              showNotes: _showNotes,
              showDate: false,
              onEdit: () => _showPicker(context, prefill: m),
              onDuplicate: () {
                widget.db.duplicateMovement(m);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Movimento duplicato')),
                );
              },
              onSaveAsFavorite: () {
                widget.db.saveMovementAsFavorite(m);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salvato nei preferiti')),
                );
              },
              onDelete: () {
                widget.db.deleteMovement(m.id);
              },
            );
          }
          cursor += groupTotal;
        }
        return null;
      },
    );
  }
}
