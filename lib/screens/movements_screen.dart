import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../widgets/movement_picker.dart';
import '../widgets/time_filter_bar.dart';

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
                  _toggleShowNotes(value);
                  setSheetState(() {});
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, 0, StreamSpacing.lg, 80),
      itemCount: movements.length,
      separatorBuilder: (context, index) => const SizedBox(height: StreamSpacing.xs),
      itemBuilder: (context, index) {
        final m = movements[index];
        final cat = widget.db.categories.where((c) => c.id == m.categoryId).firstOrNull;
        final acc = widget.db.accounts.where((a) => a.id == m.accountId).firstOrNull;
        return _MovementCard(
          movement: m,
          category: cat,
          account: acc,
          showNotes: _showNotes,
          db: widget.db,
          onEdit: () => _showPicker(context, prefill: m),
        );
      },
    );
  }
}

class _MovementCard extends StatelessWidget {
  final Movement movement;
  final Category? category;
  final Account? account;
  final bool showNotes;
  final AppDatabase db;
  final VoidCallback onEdit;

  const _MovementCard({
    required this.movement,
    required this.category,
    required this.account,
    required this.showNotes,
    required this.db,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = category != null
        ? StreamIconLibrary.getIcon(category!.iconKey)
        : Icons.help_outline;
    return Container(
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(category?.color ?? 0xFF636366),
                  borderRadius: BorderRadius.circular(StreamRadius.sm),
                ),
                child: Icon(iconData, color: Colors.white, size: 16),
              ),
              const SizedBox(width: StreamSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movement.title, style: StreamTypography.bodyBold),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (account != null) ...[
                          Icon(StreamIconLibrary.getAccountIcon(account!.iconKey), size: 12, color: Color(account!.color)),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            [category?.name ?? movement.categoryId, if (account != null) account!.name, _formatDate(movement.date)].join(' • '),
                            style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: StreamSpacing.sm),
              Text(
                '${movement.type == MovementType.expense ? '-' : '+'}${movement.amount.toStringAsFixed(2)} €',
                style: StreamTypography.amount.copyWith(
                  color: movement.type == MovementType.expense ? StreamColors.expense : StreamColors.income,
                ),
              ),
              const SizedBox(width: StreamSpacing.xs),
              _PopupMenu(movement: movement, db: db, onEdit: onEdit),
            ],
          ),
          if (showNotes && movement.note != null && movement.note!.isNotEmpty) ...[
            const SizedBox(height: StreamSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(StreamSpacing.sm),
              decoration: BoxDecoration(
                color: StreamColors.surfaceElevated,
                borderRadius: BorderRadius.circular(StreamRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded, size: 14, color: StreamColors.textMuted),
                  const SizedBox(width: StreamSpacing.sm),
                  Expanded(
                    child: Text(
                      movement.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _PopupMenu extends StatelessWidget {
  final Movement movement;
  final AppDatabase db;
  final VoidCallback onEdit;

  const _PopupMenu({required this.movement, required this.db, required this.onEdit});

  void _confirmDelete(BuildContext context, Movement m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare movimento?'),
        content: const Text('Questa operazione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              db.deleteMovement(m.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, size: 20, color: StreamColors.textMuted),
      onSelected: (value) {
        switch (value) {
          case 'modifica':
            onEdit();
          case 'duplica':
            db.duplicateMovement(movement);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Movimento duplicato')),
            );
          case 'preferito':
            db.saveMovementAsFavorite(movement);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salvato nei preferiti')),
            );
          case 'elimina':
            _confirmDelete(context, movement);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'modifica',
          child: ListTile(
            leading: Icon(Icons.edit, size: 20),
            title: Text('Modifica'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'duplica',
          child: ListTile(
            leading: Icon(Icons.copy, size: 20),
            title: Text('Duplica'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'preferito',
          child: ListTile(
            leading: Icon(Icons.favorite_border, size: 20),
            title: Text('Salva preferito'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'elimina',
          child: ListTile(
            leading: Icon(Icons.delete_outline, size: 20, color: StreamColors.expense),
            title: Text('Elimina', style: TextStyle(color: StreamColors.expense)),
            dense: true,
          ),
        ),
      ],
    );
  }
}
