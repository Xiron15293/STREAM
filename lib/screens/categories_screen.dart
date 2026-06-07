import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/category.dart';
import '../theme.dart';
import '../widgets/icon_picker.dart';

class CategoriesScreen extends StatefulWidget {
  final AppDatabase db;

  const CategoriesScreen({super.key, required this.db});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  void _showAddDialog() {
    _showCategoryForm(context, db: widget.db);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorie')),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final all = widget.db.categories;
          final income = all.where((c) => c.type == MovementType.income && !c.archived).toList();
          final expense = all.where((c) => c.type == MovementType.expense && !c.archived).toList();
          final archived = all.where((c) => c.archived).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.lg, 80),
            children: [
              _SectionHeader(title: 'Entrate', count: income.length),
              const SizedBox(height: StreamSpacing.md),
              ...income.map((c) => _CategoryTile(
                    category: c,
                    db: widget.db,
                    onEdit: () => _showCategoryForm(context, db: widget.db, existing: c),
                    onChanged: () => setState(() {}),
                  )),
              const SizedBox(height: StreamSpacing.section),
              _SectionHeader(title: 'Uscite', count: expense.length),
              const SizedBox(height: StreamSpacing.md),
              ...expense.map((c) => _CategoryTile(
                    category: c,
                    db: widget.db,
                    onEdit: () => _showCategoryForm(context, db: widget.db, existing: c),
                    onChanged: () => setState(() {}),
                  )),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: StreamSpacing.section),
                const _SectionHeader(title: 'Archiviate', count: null),
                const SizedBox(height: StreamSpacing.md),
                ...archived.map((c) => _CategoryTile(
                      category: c,
                      db: widget.db,
                      onEdit: () => _showCategoryForm(context, db: widget.db, existing: c),
                      onChanged: () => setState(() {}),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryForm(BuildContext context,
      {required AppDatabase db, Category? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryFormDialog(
        db: db,
        existing: existing,
        onChanged: () => setState(() {}),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: StreamTypography.h3.copyWith(color: StreamColors.textSecondary)),
        if (count != null) ...[
          const SizedBox(width: StreamSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: StreamColors.surfaceElevated,
              borderRadius: BorderRadius.circular(StreamRadius.full),
            ),
            child: Text('$count', style: StreamTypography.micro.copyWith(color: StreamColors.textSecondary)),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final AppDatabase db;
  final VoidCallback onEdit;
  final VoidCallback onChanged;

  const _CategoryTile({
    required this.category,
    required this.db,
    required this.onEdit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = StreamIconLibrary.getIcon(category.iconKey);
    return Container(
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(category.color),
              borderRadius: BorderRadius.circular(StreamRadius.md),
            ),
            child: Icon(iconData, color: Colors.white, size: 20),
          ),
          const SizedBox(width: StreamSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: category.archived
                      ? StreamTypography.bodyBold.copyWith(decoration: TextDecoration.lineThrough, color: StreamColors.textSecondary)
                      : StreamTypography.bodyBold,
                ),
                if (category.archived)
                  Text('Archiviata', style: StreamTypography.micro.copyWith(color: StreamColors.textMuted)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.type == MovementType.income
                      ? StreamColors.income.withValues(alpha: 0.15)
                      : StreamColors.expense.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(StreamRadius.sm),
                ),
                child: Text(
                  category.type == MovementType.income ? 'Entrata' : 'Uscita',
                  style: StreamTypography.micro.copyWith(
                    color: category.type == MovementType.income ? StreamColors.income : StreamColors.expense,
                  ),
                ),
              ),
              const SizedBox(width: StreamSpacing.xs),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'archive':
                      db.archiveCategory(category.id);
                      onChanged();
                    case 'restore':
                      db.restoreCategory(category.id);
                      onChanged();
                    case 'delete':
                      _tryDelete(context);
                  }
                },
                icon: Icon(Icons.more_horiz, size: 18, color: StreamColors.textMuted),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                  if (!category.archived)
                    const PopupMenuItem(value: 'archive', child: Text('Archivia')),
                  if (category.archived)
                    const PopupMenuItem(value: 'restore', child: Text('Ripristina')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Elimina', style: TextStyle(color: StreamColors.expense)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _tryDelete(BuildContext context) {
    if (db.categoryHasMovements(category.id)) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Impossibile eliminare'),
          content: Text(
              'La categoria "${category.name}" contiene movimenti.\n\n'
              'Archiviala o riassegna i movimenti prima di eliminarla.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare categoria?'),
          content: Text(
              'La categoria "${category.name}" sarà eliminata definitivamente.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            TextButton(
              onPressed: () {
                db.deleteCategory(category.id);
                onChanged();
                Navigator.pop(ctx);
              },
              style: TextButton.styleFrom(foregroundColor: StreamColors.expense),
              child: const Text('Elimina'),
            ),
          ],
        ),
      );
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final AppDatabase db;
  final Category? existing;
  final VoidCallback onChanged;

  const _CategoryFormDialog({
    required this.db,
    this.existing,
    required this.onChanged,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _nameCtrl;
  MovementType _type = MovementType.expense;
  int _color = 0xFF42A5F5;
  String _iconKey = StreamIconLibrary.defaultCategoryIcon;
  bool _typeLocked = false;
  String? _typeLockMessage;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    if (e != null) {
      _type = e.type;
      _color = e.color;
      _iconKey = e.iconKey;
      if (widget.db.categoryHasMovements(e.id)) {
        _typeLocked = true;
        _typeLockMessage =
            'Tipo non modificabile: la categoria contiene movimenti.';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isDuplicateName {
    final name = _nameCtrl.text.trim().toLowerCase();
    if (name.isEmpty) return false;
    return widget.db.categories.any((c) =>
        c.name.toLowerCase() == name &&
        c.id != (widget.existing?.id ?? ''));
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome')),
      );
      return;
    }
    if (_isDuplicateName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esiste già una categoria con questo nome')),
      );
      return;
    }

    if (widget.existing != null) {
      widget.db.updateCategory(
        widget.existing!.id,
        name,
        _color,
        type: _typeLocked ? null : _type,
        iconKey: _iconKey,
      );
    } else {
      widget.db.addCategory(name, _type, _color, iconKey: _iconKey);
    }

    widget.onChanged();
    Navigator.pop(context);
  }

  Future<void> _pickIcon() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => IconPickerDialog(
        currentIconKey: _iconKey,
        isAccount: false,
      ),
    );
    if (result != null) {
      setState(() => _iconKey = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewIcon = StreamIconLibrary.getIcon(_iconKey);
    return AlertDialog(
      title: Text(widget.existing != null ? 'Modifica categoria' : 'Nuova categoria'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
            ),
            if (widget.existing == null) ...[
              const SizedBox(height: StreamSpacing.lg),
              SegmentedButton<MovementType>(
                segments: const [
                  ButtonSegment(value: MovementType.expense, label: Text('Uscita')),
                  ButtonSegment(value: MovementType.income, label: Text('Entrata')),
                ],
                selected: {_type},
                onSelectionChanged: (set) =>
                    setState(() => _type = set.first),
              ),
            ],
            if (_typeLocked) ...[
              const SizedBox(height: StreamSpacing.sm),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: StreamColors.warning),
                  const SizedBox(width: StreamSpacing.sm),
                  Text(_typeLockMessage!,
                      style: TextStyle(fontSize: 12, color: StreamColors.warning)),
                ],
              ),
            ],
            const SizedBox(height: StreamSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Icona', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
                GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: StreamColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(StreamRadius.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(previewIcon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(StreamIconLibrary.getLabel(_iconKey),
                            style: StreamTypography.caption),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: StreamColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: StreamSpacing.lg),
            Text('Colore', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
            const SizedBox(height: StreamSpacing.md),
            ColorPicker(
              currentColor: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla')),
        FilledButton(
          onPressed: _save,
          child: Text(widget.existing != null ? 'Salva' : 'Crea'),
        ),
      ],
    );
  }
}
