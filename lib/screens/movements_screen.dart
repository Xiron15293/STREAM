import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/movement_search.dart';
import '../widgets/movement_picker.dart';
import '../widgets/time_filter_bar.dart';
import '../widgets/grouped_movements_list.dart';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
          final filtered = searchMovements(
            movements: allMovements,
            query: _searchQuery,
            filter: _activeFilter,
            categories: widget.db.categories,
            accounts: widget.db.accounts,
          );
          final hasQuery = _searchQuery.trim().isNotEmpty;
          final body = allMovements.isEmpty
              ? _buildEmptyAll()
              : filtered.isEmpty
              ? hasQuery
                    ? _buildEmptySearch()
                    : _buildEmptyPeriod()
              : _buildMovementsList(filtered);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  StreamSpacing.sm,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textInputAction: TextInputAction.search,
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
                onChanged: (f) => setState(() => _activeFilter = f),
              ),
              const SizedBox(height: StreamSpacing.sm),
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

  Widget _buildMovementsList(List<Movement> movements) {
    return GroupedMovementsList(
      movements: movements,
      db: widget.db,
      showNotes: _showNotes || _searchQuery.trim().isNotEmpty,
      onEdit: (m) => _showPicker(context, prefill: m),
      onDuplicate: (m) {
        widget.db.duplicateMovement(m);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movimento duplicato')));
      },
      onSaveAsFavorite: (m) {
        widget.db.saveMovementAsFavorite(m);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Salvato nei preferiti')));
      },
      onDelete: (m) {
        widget.db.deleteMovement(m.id);
      },
    );
  }
}
