import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../theme.dart';

class MovementForm extends StatefulWidget {
  final AppDatabase db;
  final Movement? prefill;

  const MovementForm({super.key, required this.db, this.prefill});

  @override
  State<MovementForm> createState() => _MovementFormState();
}

class _MovementFormState extends State<MovementForm> {
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
    if (title.isEmpty || amountText.isEmpty || _selectedCategoryId == null) return;

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

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
      final movement = Movement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        type: _type,
        date: _date,
        categoryId: _selectedCategoryId!,
        accountId: _selectedAccountId,
        note: note,
        createdAt: DateTime.now(),
      );
      widget.db.addMovement(movement);
    }
    Navigator.of(context).pop();
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
                widget.prefill != null ? 'Modifica movimento' : 'Nuovo movimento',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.lg),
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
            items: _availableCategories.map((c) => DropdownMenuItem(
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
            )).toList(),
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
      ),
    );
  }
}
