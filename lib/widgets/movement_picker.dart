import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/quick_movement.dart';
import '../models/favorite_movement.dart';
import '../theme.dart';

enum AddMode { manuale, rapidi, preferiti }

class MovementPicker extends StatefulWidget {
  final AppDatabase db;
  final Movement? prefill;
  final String? categoryPreFill;

  const MovementPicker({super.key, required this.db, this.prefill, this.categoryPreFill});

  @override
  State<MovementPicker> createState() => _MovementPickerState();
}

class _MovementPickerState extends State<MovementPicker> {
  AddMode _mode = AddMode.manuale;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      _mode = AddMode.manuale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: StreamSpacing.lg,
        right: StreamSpacing.lg,
        top: StreamSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + StreamSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _mode == AddMode.manuale
                    ? (widget.prefill != null ? 'Modifica movimento' : 'Nuovo movimento')
                    : _mode == AddMode.rapidi
                        ? 'Movimenti rapidi'
                        : 'Preferiti',
                style: StreamTypography.h3,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.md),
          SegmentedButton<AddMode>(
            segments: const [
              ButtonSegment(value: AddMode.manuale, label: Text('Manuale')),
              ButtonSegment(value: AddMode.rapidi, label: Text('Rapidi')),
              ButtonSegment(value: AddMode.preferiti, label: Text('Preferiti')),
            ],
            selected: {_mode},
            onSelectionChanged: (set) =>
                setState(() => _mode = set.first),
          ),
          const SizedBox(height: StreamSpacing.lg),
          Flexible(
            child: SingleChildScrollView(
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_mode) {
      case AddMode.manuale:
        return _ManualForm(
          db: widget.db,
          prefill: widget.prefill,
          categoryPreFill: widget.categoryPreFill,
          onSaved: () => Navigator.of(context).pop(),
        );
      case AddMode.rapidi:
        return _QuickPanel(
          db: widget.db,
          onUsed: () => Navigator.of(context).pop(),
        );
      case AddMode.preferiti:
        return _FavoritesPanel(
          db: widget.db,
          onUsed: () => Navigator.of(context).pop(),
        );
    }
  }
}

// ============================================================
// Manuale Tab
// ============================================================

class _ManualForm extends StatefulWidget {
  final AppDatabase db;
  final Movement? prefill;
  final String? categoryPreFill;
  final VoidCallback onSaved;

  const _ManualForm({
    required this.db,
    this.prefill,
    this.categoryPreFill,
    required this.onSaved,
  });

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  MovementType _type = MovementType.expense;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _amountCtrl =
        TextEditingController(text: p != null ? p.amount.toString() : '');
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    _date = p?.date ?? DateTime.now();
    if (p != null) {
      _type = p.type;
      _selectedCategoryId = p.categoryId;
      _selectedAccountId = p.accountId;
    } else if (widget.categoryPreFill != null) {
      final cat = widget.db.categories.where((c) => c.id == widget.categoryPreFill).firstOrNull;
      if (cat != null) {
        _type = cat.type;
        _selectedCategoryId = cat.id;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<Category> get _availableCategories =>
      widget.db.categories.where((c) => c.type == _type && !c.archived).toList();

  void _submit() {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (title.isEmpty || amountText.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi obbligatori')),
      );
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido')),
      );
      return;
    }

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (widget.prefill != null) {
      final updated = widget.prefill!.copyWith(
        title: title,
        amount: amount,
        type: _type,
        date: _date,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId,
        note: note,
        updatedAt: DateTime.now(),
      );
      widget.db.updateMovement(updated);
    } else {
      widget.db.createMovementFromTemplate(
        title: title,
        amount: amount,
        type: _type,
        date: _date,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId,
        note: note,
      );
    }
    widget.onSaved();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day,
            _date.hour, _date.minute);
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategoryId == null && _availableCategories.isNotEmpty) {
      _selectedCategoryId = _availableCategories.first.id;
    }
    if (_selectedAccountId == null) {
      final active = widget.db.accounts.where((a) => !a.archived).toList();
      if (active.isNotEmpty) {
        _selectedAccountId = active.first.id;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<MovementType>(
          segments: const [
            ButtonSegment(value: MovementType.expense, label: Text('Uscita')),
            ButtonSegment(value: MovementType.income, label: Text('Entrata')),
          ],
          selected: {_type},
          onSelectionChanged: (set) {
            setState(() {
              _type = set.first;
              _selectedCategoryId = null;
            });
          },
        ),
        const SizedBox(height: StreamSpacing.md),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Titolo'),
        ),
        const SizedBox(height: StreamSpacing.md),
        TextField(
          controller: _amountCtrl,
          decoration: const InputDecoration(labelText: 'Importo (€)'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: StreamSpacing.md),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Data',
              suffixIcon: Icon(Icons.calendar_today, size: 20),
            ),
            child: Text(_formatDate(_date)),
          ),
        ),
        const SizedBox(height: StreamSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: StreamColors.surfaceElevated,
          ),
          items: _availableCategories
              .map((c) => DropdownMenuItem(
                    value: c.id,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(c.color),
                        borderRadius: BorderRadius.circular(StreamRadius.sm),
                      ),
                      child: Icon(StreamIconLibrary.getIcon(c.iconKey), color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ],
                ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
        const SizedBox(height: StreamSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedAccountId,
          decoration: const InputDecoration(
            labelText: 'Conto',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: StreamColors.surfaceElevated,
          ),
          items: widget.db.accounts
              .where((a) => !a.archived)
                .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(StreamIconLibrary.getAccountIcon(a.iconKey), size: 18, color: Color(a.color)),
                          const SizedBox(width: 8),
                          Text(a.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccountId = v),
          ),
          const SizedBox(height: StreamSpacing.md),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Nota (opzionale)'),
            maxLines: 2,
          ),
          const SizedBox(height: StreamSpacing.lg),
          FilledButton(
            onPressed: _submit,
            child: Text(widget.prefill != null ? 'Aggiorna' : 'Salva'),
          ),
      ],
    );
  }
}

// ============================================================
// Rapidi Tab
// ============================================================

class _QuickPanel extends StatelessWidget {
  final AppDatabase db;
  final VoidCallback onUsed;

  const _QuickPanel({required this.db, required this.onUsed});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final items = db.quickMovements;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Movimenti rapidi', style: StreamTypography.h3),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Nuovo rapido',
                  onPressed: () => _showQuickForm(context, db: db),
                ),
              ],
            ),
            if (items.isEmpty)
              _EmptyPanel(message: 'Nessun movimento rapido')
            else
                  ...items.map((qm) {
                    final qmCat = db.categories.where((c) => c.id == qm.categoryId).firstOrNull;
                    return Container(
                    margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
                    padding: const EdgeInsets.all(StreamSpacing.md),
                    decoration: BoxDecoration(
                      color: StreamColors.surface,
                      borderRadius: BorderRadius.circular(StreamRadius.md),
                    ),
                    child: Row(
                      children: [
                        _CategoryIcon(
                          color: qmCat?.color ?? 0xFF636366,
                          iconKey: qmCat?.iconKey ?? StreamIconLibrary.defaultCategoryIcon,
                          size: 36,
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(qm.title, style: StreamTypography.bodyBold),
                              const SizedBox(height: 2),
                              Text(
                                '${qmCat?.name ?? ''} • ${qm.type == MovementType.expense ? '-' : '+'}${qm.amount.toStringAsFixed(2)} €',
                                style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: 18, color: StreamColors.textMuted),
                              onPressed: () => _showQuickForm(context, db: db, existing: qm),
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow, size: 22, color: StreamColors.primary),
                              tooltip: 'Usa',
                              onPressed: () {
                                db.createMovementFromTemplate(
                                  title: qm.title,
                                  amount: qm.amount,
                                  type: qm.type,
                                  categoryId: qm.categoryId,
                                  accountId: qm.accountId,
                                  note: qm.note,
                                );
                                onUsed();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    );
                  }),
          ],
        );
      },
    );
  }

  void _showQuickForm(BuildContext context,
      {required AppDatabase db, QuickMovement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _QuickFormDialog(db: db, existing: existing),
    );
  }
}

class _QuickFormDialog extends StatefulWidget {
  final AppDatabase db;
  final QuickMovement? existing;

  const _QuickFormDialog({required this.db, this.existing});

  @override
  State<_QuickFormDialog> createState() => _QuickFormDialogState();
}

class _QuickFormDialogState extends State<_QuickFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  MovementType _type = MovementType.expense;
  String? _selectedCategoryId;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
        text: e != null ? e.amount.toString() : '');
    if (e != null) {
      _type = e.type;
      _selectedCategoryId = e.categoryId;
      _selectedAccountId = e.accountId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  List<Category> get _availableCategories =>
      widget.db.categories.where((c) => c.type == _type && !c.archived).toList();

  void _save() {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (title.isEmpty || amountText.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi')),
      );
      return;
    }
    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importo non valido')),
      );
      return;
    }

    final qm = QuickMovement(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId ?? defaultAccountId,
    );

    if (widget.existing != null) {
      widget.db.updateQuickMovement(widget.existing!.id, qm);
    } else {
      widget.db.addQuickMovement(qm);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategoryId == null && _availableCategories.isNotEmpty) {
      _selectedCategoryId = _availableCategories.first.id;
    }
    if (_selectedAccountId == null) {
      final active = widget.db.accounts.where((a) => !a.archived).toList();
      if (active.isNotEmpty) {
        _selectedAccountId = active.first.id;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: StreamSpacing.lg,
        right: StreamSpacing.lg,
        top: StreamSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + StreamSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existing != null ? 'Modifica rapido' : 'Nuovo movimento rapido',
                style: StreamTypography.h3,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.md),
          SegmentedButton<MovementType>(
            segments: const [
              ButtonSegment(value: MovementType.expense, label: Text('Uscita')),
              ButtonSegment(value: MovementType.income, label: Text('Entrata')),
            ],
            selected: {_type},
            onSelectionChanged: (set) {
              setState(() {
                _type = set.first;
                _selectedCategoryId = null;
              });
            },
          ),
          const SizedBox(height: StreamSpacing.md),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titolo'),
          ),
          const SizedBox(height: StreamSpacing.md),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(labelText: 'Importo (€)'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: StreamSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: StreamColors.surfaceElevated,
            ),
            items: _availableCategories
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(c.color),
                              borderRadius: BorderRadius.circular(StreamRadius.sm),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: StreamSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedAccountId,
            decoration: const InputDecoration(
              labelText: 'Conto',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: StreamColors.surfaceElevated,
            ),
            items: widget.db.accounts
                .where((a) => !a.archived)
                .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(StreamIconLibrary.getAccountIcon(a.iconKey), size: 18, color: Color(a.color)),
                          const SizedBox(width: 8),
                          Text(a.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccountId = v),
          ),
          const SizedBox(height: StreamSpacing.lg),
          FilledButton(
            onPressed: _save,
            child: Text(widget.existing != null ? 'Aggiorna' : 'Crea'),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: StreamSpacing.sm),
            OutlinedButton(
              onPressed: () {
                widget.db.deleteQuickMovement(widget.existing!.id);
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(foregroundColor: StreamColors.expense),
              child: const Text('Elimina'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Preferiti + Suggeriti Tab
// ============================================================

class _FavoritesPanel extends StatelessWidget {
  final AppDatabase db;
  final VoidCallback onUsed;

  const _FavoritesPanel({required this.db, required this.onUsed});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final favorites = db.favoriteMovements;
        final suggestions = db.getSuggestions();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preferiti', style: StreamTypography.h3),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Nuovo'),
                  onPressed: () => _showFavoriteForm(context, db: db),
                ),
              ],
            ),
            if (favorites.isEmpty && suggestions.isEmpty)
              const _EmptyPanel(message: 'Nessun preferito'),
            if (favorites.isNotEmpty)
              ...favorites.map((fm) => _FavoriteTile(
                    fm: fm,
                    isSuggestion: false,
                    db: db,
                    onUsed: onUsed,
                  )),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: StreamSpacing.md),
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: StreamColors.textMuted),
                  const SizedBox(width: StreamSpacing.sm),
                  const Text('Suggeriti', style: StreamTypography.h3),
                ],
              ),
              const SizedBox(height: StreamSpacing.sm),
              ...suggestions.map((fm) => _FavoriteTile(
                    fm: fm,
                    isSuggestion: true,
                    db: db,
                    onUsed: onUsed,
                  )),
            ],
          ],
        );
      },
    );
  }

  void _showFavoriteForm(BuildContext context,
      {required AppDatabase db, FavoriteMovement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FavoriteFormDialog(db: db, existing: existing),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final FavoriteMovement fm;
  final bool isSuggestion;
  final AppDatabase db;
  final VoidCallback onUsed;

  const _FavoriteTile({
    required this.fm,
    required this.isSuggestion,
    required this.db,
    required this.onUsed,
  });

  @override
  Widget build(BuildContext context) {
    final favCat = db.categories.where((c) => c.id == fm.categoryId).firstOrNull;
    final catColor = favCat?.color ?? 0xFF636366;
    return Container(
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Row(
        children: [
          _CategoryIcon(
            color: catColor,
            iconKey: favCat?.iconKey ?? StreamIconLibrary.defaultCategoryIcon,
            size: 36,
          ),
          const SizedBox(width: StreamSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fm.title, style: StreamTypography.bodyBold),
                const SizedBox(height: 2),
                Text(
                  '${db.categories.where((c) => c.id == fm.categoryId).firstOrNull?.name ?? ''} • ${fm.type == MovementType.expense ? '-' : '+'}${fm.amount.toStringAsFixed(2)} €',
                  style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSuggestion) ...[
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: StreamColors.textMuted),
                  onPressed: () => _showFavoriteForm(context, db: db, existing: fm),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: StreamColors.expense),
                  onPressed: () => db.deleteFavoriteMovement(fm.id),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 22, color: StreamColors.primary),
                tooltip: 'Usa',
                onPressed: () {
                  db.createMovementFromTemplate(
                    title: fm.title,
                    amount: fm.amount,
                    type: fm.type,
                    categoryId: fm.categoryId,
                    accountId: fm.accountId,
                    note: fm.note,
                  );
                  onUsed();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFavoriteForm(BuildContext context,
      {required AppDatabase db, required FavoriteMovement existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FavoriteFormDialog(db: db, existing: existing),
    );
  }
}

class _FavoriteFormDialog extends StatefulWidget {
  final AppDatabase db;
  final FavoriteMovement? existing;

  const _FavoriteFormDialog({required this.db, this.existing});

  @override
  State<_FavoriteFormDialog> createState() => _FavoriteFormDialogState();
}

class _FavoriteFormDialogState extends State<_FavoriteFormDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  MovementType _type = MovementType.expense;
  String? _selectedCategoryId;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl =
        TextEditingController(text: e != null ? e.amount.toString() : '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      _type = e.type;
      _selectedCategoryId = e.categoryId;
      _selectedAccountId = e.accountId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<Category> get _availableCategories =>
      widget.db.categories.where((c) => c.type == _type && !c.archived).toList();

  void _save() {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (title.isEmpty || amountText.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi')),
      );
      return;
    }
    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importo non valido')),
      );
      return;
    }

    if (widget.existing != null) {
      widget.db.deleteFavoriteMovement(widget.existing!.id);
    }

    widget.db.addFavoriteMovement(FavoriteMovement(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId ?? defaultAccountId,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategoryId == null && _availableCategories.isNotEmpty) {
      _selectedCategoryId = _availableCategories.first.id;
    }
    if (_selectedAccountId == null) {
      final active = widget.db.accounts.where((a) => !a.archived).toList();
      if (active.isNotEmpty) {
        _selectedAccountId = active.first.id;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: StreamSpacing.lg,
        right: StreamSpacing.lg,
        top: StreamSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + StreamSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existing != null ? 'Modifica preferito' : 'Nuovo preferito',
                style: StreamTypography.h3,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.md),
          SegmentedButton<MovementType>(
            segments: const [
              ButtonSegment(value: MovementType.expense, label: Text('Uscita')),
              ButtonSegment(value: MovementType.income, label: Text('Entrata')),
            ],
            selected: {_type},
            onSelectionChanged: (set) {
              setState(() {
                _type = set.first;
                _selectedCategoryId = null;
              });
            },
          ),
          const SizedBox(height: StreamSpacing.md),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titolo'),
          ),
          const SizedBox(height: StreamSpacing.md),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(labelText: 'Importo (€)'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: StreamSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: StreamColors.surfaceElevated,
            ),
            items: _availableCategories
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(c.color),
                              borderRadius: BorderRadius.circular(StreamRadius.sm),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: StreamSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _selectedAccountId,
            decoration: const InputDecoration(
              labelText: 'Conto',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(StreamRadius.md)),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: StreamColors.surfaceElevated,
            ),
            items: widget.db.accounts
                .where((a) => !a.archived)
                .map((a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(StreamIconLibrary.getAccountIcon(a.iconKey), size: 18, color: Color(a.color)),
                          const SizedBox(width: 8),
                          Text(a.name),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccountId = v),
          ),
          const SizedBox(height: StreamSpacing.md),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Nota (opzionale)'),
            maxLines: 2,
          ),
          const SizedBox(height: StreamSpacing.lg),
          FilledButton(
            onPressed: _save,
            child: Text(widget.existing != null ? 'Aggiorna' : 'Crea'),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: StreamSpacing.sm),
            OutlinedButton(
              onPressed: () {
                widget.db.deleteFavoriteMovement(widget.existing!.id);
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(foregroundColor: StreamColors.expense),
              child: const Text('Elimina'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Shared Widgets
// ============================================================

class _CategoryIcon extends StatelessWidget {
  final int color;
  final String iconKey;
  final double size;

  const _CategoryIcon({required this.color, required this.iconKey, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(StreamRadius.sm),
      ),
      child: Icon(StreamIconLibrary.getIcon(iconKey), color: Colors.white, size: size * 0.45),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StreamSpacing.xxl),
      child: Center(
        child: Text(message, style: StreamTypography.body.copyWith(color: StreamColors.textSecondary)),
      ),
    );
  }
}
