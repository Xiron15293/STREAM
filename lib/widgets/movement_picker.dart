// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../design/stream_date_picker.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/quick_movement.dart';
import '../models/favorite_movement.dart';
import '../theme.dart';
import '../util/beneficiary_helpers.dart';
import '../utils/currency_formatter.dart';
import 'beneficiary_picker_sheet.dart';
import 'add_movement_flow.dart';
import 'calculator_amount_pad.dart';
import 'category_subcategory_selector.dart';
import 'movement_text_suggestions.dart';

enum AddMode { manuale, rapidi, preferiti }

enum _TemplateDateChoice { today, yesterday, tomorrow, custom }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

Future<DateTime?> _pickTemplateDate(BuildContext context) async {
  final choice = await showModalBottomSheet<_TemplateDateChoice>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      Widget tile({
        required IconData icon,
        required String title,
        required String subtitle,
        required _TemplateDateChoice value,
        required Key key,
      }) {
        return ListTile(
          key: key,
          leading: Icon(icon, color: StreamColors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          onTap: () => Navigator.of(sheetContext).pop(value),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StreamSpacing.lg,
            StreamSpacing.md,
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
                  const Text('Scegli data', style: StreamTypography.h3),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: StreamSpacing.sm),
              tile(
                icon: Icons.today,
                title: 'Oggi',
                subtitle: 'Data odierna',
                value: _TemplateDateChoice.today,
                key: const Key('quick_date_today'),
              ),
              tile(
                icon: Icons.history,
                title: 'Ieri',
                subtitle: 'Data di ieri',
                value: _TemplateDateChoice.yesterday,
                key: const Key('quick_date_yesterday'),
              ),
              tile(
                icon: Icons.update,
                title: 'Domani',
                subtitle: 'Data di domani',
                value: _TemplateDateChoice.tomorrow,
                key: const Key('quick_date_tomorrow'),
              ),
              tile(
                icon: Icons.calendar_month,
                title: 'Scegli data',
                subtitle: 'Apri il selettore completo',
                value: _TemplateDateChoice.custom,
                key: const Key('quick_date_custom'),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (choice == null) return null;

  final today = _dateOnly(DateTime.now());
  switch (choice) {
    case _TemplateDateChoice.today:
      return today;
    case _TemplateDateChoice.yesterday:
      return today.subtract(const Duration(days: 1));
    case _TemplateDateChoice.tomorrow:
      return today.add(const Duration(days: 1));
    case _TemplateDateChoice.custom:
      final picked = await StreamDatePicker.show(
        // The choice sheet has already been dismissed before opening the picker.
        // ignore: use_build_context_synchronously
        context: context,
        initialDate: today,
      );
      return picked == null ? null : _dateOnly(picked);
  }
}

Future<void> _useTemplateMovement({
  required BuildContext context,
  required AppDatabase db,
  required VoidCallback onUsed,
  required String title,
  required double amount,
  required MovementType type,
  required String categoryId,
  String? subcategoryId,
  required String accountId,
  String? note,
}) async {
  final date = await _pickTemplateDate(context);
  if (date == null) return;

  await db.createMovementFromTemplate(
    title: title,
    amount: amount,
    type: type,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    accountId: accountId,
    note: note,
    date: date,
  );
  if (!context.mounted) return;
  onUsed();
}

class MovementPicker extends StatefulWidget {
  final AppDatabase db;
  final Movement? prefill;
  final String? categoryPreFill;
  final String? accountPreFill;
  final MovementType? initialType;

  const MovementPicker({
    super.key,
    required this.db,
    this.prefill,
    this.categoryPreFill,
    this.accountPreFill,
    this.initialType,
  });

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
    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
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
                Expanded(
                  child: Text(
                    _mode == AddMode.manuale
                        ? (widget.prefill != null
                              ? 'Modifica movimento'
                              : 'Nuovo movimento')
                        : _mode == AddMode.rapidi
                        ? 'Movimenti rapidi'
                        : 'Preferiti',
                    style: StreamTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                ButtonSegment(
                  value: AddMode.preferiti,
                  label: Text('Preferiti'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (set) => setState(() => _mode = set.first),
            ),
            const SizedBox(height: StreamSpacing.lg),
            Flexible(child: SingleChildScrollView(child: _buildContent())),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_mode) {
      case AddMode.manuale:
        return AddMovementFlow(
          db: widget.db,
          prefill: widget.prefill,
          categoryPreFill: widget.categoryPreFill,
          accountPreFill: widget.accountPreFill,
          initialType: widget.initialType,
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
  final String? accountPreFill;
  final MovementType? initialType;
  final VoidCallback onSaved;

  const _ManualForm({
    required this.db,
    this.prefill,
    this.categoryPreFill,
    this.accountPreFill,
    this.initialType,
    required this.onSaved,
  });

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _payeeCtrl;
  MovementType _type = MovementType.expense;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedAccountId;
  String? _selectedDestinationAccountId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _amountCtrl = TextEditingController(
      text: p != null ? formatAmountExpressionValue(p.amount) : '',
    );
    _noteCtrl = TextEditingController(text: p?.note ?? '');
    _payeeCtrl = TextEditingController(text: p?.payee ?? '');
    _date = p?.date ?? DateTime.now();
    if (p != null) {
      _type = p.type;
      _selectedCategoryId = p.categoryId;
      _selectedSubcategoryId = p.subcategoryId;
      _selectedAccountId = p.accountId;
      _selectedDestinationAccountId = p.destinationAccountId;
    } else {
      _type = widget.initialType ?? _type;
      final cat = widget.db.categories
          .where((c) => c.id == widget.categoryPreFill)
          .firstOrNull;
      if (cat != null) {
        _type = cat.type;
        _selectedCategoryId = cat.id;
      }
      if (widget.accountPreFill != null) {
        _selectedAccountId = widget.accountPreFill;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _payeeCtrl.dispose();
    super.dispose();
  }

  List<Category> get _availableCategories => _type == MovementType.transfer
      ? const <Category>[]
      : widget.db.categories
            .where((c) => c.type == _type && !c.archived)
            .toList();

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final isTransfer = _type == MovementType.transfer;
    if (amountText.isEmpty ||
        (!isTransfer && (title.isEmpty || _selectedCategoryId == null))) {
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

    if (isTransfer) {
      final origin = _selectedAccountId;
      final destination = _selectedDestinationAccountId;
      if (origin == null || destination == null || origin == destination) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona due conti diversi')),
        );
        return;
      }

      if (widget.prefill != null) {
        final updated = widget.prefill!.copyWith(
          title: title.isEmpty ? widget.prefill!.title : title,
          amount: amount,
          type: _type,
          date: _date,
          categoryId: '',
          subcategoryId: null,
          accountId: origin,
          destinationAccountId: destination,
          note: note,
          updatedAt: DateTime.now(),
        );
        await widget.db.updateMovement(updated);
      } else {
        await widget.db.createMovementFromTemplate(
          title: title,
          amount: amount,
          type: _type,
          date: _date,
          categoryId: '',
          subcategoryId: null,
          accountId: origin,
          destinationAccountId: destination,
          note: note,
        );
      }
      widget.onSaved();
      return;
    }

    final payee = widget.db.cleanBeneficiaryName(_payeeCtrl.text);
    final payeeDecision = await askToSaveBeneficiary(context, widget.db, payee);
    if (!mounted || payeeDecision == SaveBeneficiaryDecision.cancel) {
      return;
    }

    if (widget.prefill != null) {
      final updated = widget.prefill!.copyWith(
        title: title,
        amount: amount,
        type: _type,
        date: _date,
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId,
        accountId: _selectedAccountId,
        note: note,
        payee: payee.isEmpty ? null : payee,
        updatedAt: DateTime.now(),
      );
      await widget.db.updateMovement(updated);
    } else {
      await widget.db.createMovementFromTemplate(
        title: title,
        amount: amount,
        type: _type,
        date: _date,
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId,
        accountId: _selectedAccountId,
        note: note,
        payee: payee.isEmpty ? null : payee,
      );
    }
    if (payeeDecision == SaveBeneficiaryDecision.saveBeneficiary &&
        payee.isNotEmpty) {
      await widget.db.createManualBeneficiaryProfile(payee);
    }
    if (!mounted) return;
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
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  String _counterpartyLabel() {
    switch (_type) {
      case MovementType.income:
        return 'Pagatore / Fonte';
      case MovementType.expense:
        return 'Beneficiario / Esercente';
      case MovementType.transfer:
        return 'Causale';
    }
  }

  Future<void> _pickBeneficiary() async {
    final selected = await showBeneficiaryPickerSheet(
      context,
      widget.db,
      initialQuery: _payeeCtrl.text,
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() {
      _payeeCtrl.text = selected;
    });
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        final accountLabel = _type == MovementType.transfer
            ? 'Conto origine'
            : 'Conto';
        if (_type != MovementType.transfer &&
            _selectedCategoryId == null &&
            _availableCategories.isNotEmpty) {
          _selectedCategoryId = _availableCategories.first.id;
        }
        if (_selectedAccountId == null) {
          final active = widget.db.accounts.where((a) => !a.archived).toList();
          if (active.isNotEmpty) {
            _selectedAccountId = active.first.id;
          }
        }
        if (_type == MovementType.transfer &&
            _selectedDestinationAccountId == null) {
          final active = widget.db.accounts.where((a) => !a.archived).toList();
          if (active.isNotEmpty) {
            _selectedDestinationAccountId = active.length > 1
                ? active[1].id
                : active.first.id;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                  value: MovementType.expense,
                  label: Text('Uscita'),
                ),
                ButtonSegment(
                  value: MovementType.income,
                  label: Text('Entrata'),
                ),
                ButtonSegment(
                  value: MovementType.transfer,
                  label: Text('Trasferimento'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() {
                  _type = set.first;
                  _selectedCategoryId = null;
                  _selectedSubcategoryId = null;
                  if (_type != MovementType.transfer) {
                    _selectedDestinationAccountId = null;
                  }
                });
              },
            ),
            const SizedBox(height: StreamSpacing.md),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titolo'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            const SizedBox(height: StreamSpacing.md),
            CalculatorAmountField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Importo (€)'),
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
            if (_type != MovementType.transfer) ...[
              CategorySubcategorySelector(
                categories: widget.db.categories,
                subcategories: widget.db.subcategories,
                type: _type,
                selectedCategoryId: _selectedCategoryId,
                selectedSubcategoryId: _selectedSubcategoryId,
                onChanged: (categoryId, subcategoryId) => setState(() {
                  _selectedCategoryId = categoryId;
                  _selectedSubcategoryId = subcategoryId;
                }),
              ),
              const SizedBox(height: StreamSpacing.md),
              TextField(
                key: const Key('movement_counterparty_field'),
                controller: _payeeCtrl,
                decoration: InputDecoration(
                  labelText: _counterpartyLabel(),
                  suffixIcon: IconButton(
                    key: const Key('movement_beneficiary_picker_button'),
                    onPressed: _pickBeneficiary,
                    icon: const Icon(Icons.people_outline),
                    tooltip: 'Apri beneficiari',
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              MovementBeneficiarySuggestions(
                db: widget.db,
                controller: _payeeCtrl,
                limit: 5,
              ),
            ],
            const SizedBox(height: StreamSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              decoration: InputDecoration(
                labelText: accountLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(StreamRadius.md),
                  ),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: StreamColors.surfaceElevated,
              ),
              items: widget.db.accounts
                  .where((a) => !a.archived)
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(
                            StreamIconLibrary.getAccountIcon(a.iconKey),
                            size: 18,
                            color: Color(a.color),
                          ),
                          const SizedBox(width: 8),
                          Text(a.name),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
            if (_type == MovementType.transfer) ...[
              const SizedBox(height: StreamSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedDestinationAccountId,
                decoration: const InputDecoration(
                  labelText: 'Conto destinazione',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(StreamRadius.md),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: StreamColors.surfaceElevated,
                ),
                items: widget.db.accounts
                    .where((a) => !a.archived)
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Row(
                          children: [
                            Icon(
                              StreamIconLibrary.getAccountIcon(a.iconKey),
                              size: 18,
                              color: Color(a.color),
                            ),
                            const SizedBox(width: 8),
                            Text(a.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedDestinationAccountId = v),
              ),
            ],
            const SizedBox(height: StreamSpacing.md),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opzionale)'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              maxLines: 2,
            ),
            const SizedBox(height: StreamSpacing.lg),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.prefill != null ? 'Aggiorna' : 'Salva'),
            ),
          ],
        );
      },
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
                final resolved = resolveCategorySubcategorySelection(
                  categories: db.categories,
                  subcategories: db.subcategories,
                  type: qm.type,
                  categoryId: qm.categoryId,
                  subcategoryId: qm.subcategoryId,
                  activeOnly: false,
                );
                final qmCat = resolved?.category;
                return Padding(
                  padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
                  child: Material(
                    color: StreamColors.surface,
                    borderRadius: BorderRadius.circular(StreamRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(StreamRadius.md),
                      onTap: () => _useTemplateMovement(
                        context: context,
                        db: db,
                        onUsed: onUsed,
                        title: qm.title,
                        amount: qm.amount,
                        type: qm.type,
                        categoryId: qm.categoryId,
                        subcategoryId: qm.subcategoryId,
                        accountId: qm.accountId,
                        note: qm.note,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(StreamSpacing.md),
                        child: Row(
                          children: [
                            _CategoryIcon(
                              color:
                                  resolved?.color ?? qmCat?.color ?? 0xFF636366,
                              iconKey:
                                  resolved?.iconKey ??
                                  qmCat?.iconKey ??
                                  StreamIconLibrary.defaultCategoryIcon,
                              size: 36,
                            ),
                            const SizedBox(width: StreamSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    qm.title,
                                    style: StreamTypography.bodyBold,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${resolved?.label ?? qmCat?.name ?? ''} • ${formatMovementCurrency(qm.type == MovementType.expense ? -qm.amount : qm.amount, showPositiveSign: true)}',
                                    style: StreamTypography.caption.copyWith(
                                      color: StreamColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: StreamColors.textMuted,
                                  ),
                                  onPressed: () => _showQuickForm(
                                    context,
                                    db: db,
                                    existing: qm,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    size: 22,
                                    color: StreamColors.primary,
                                  ),
                                  tooltip: 'Usa',
                                  onPressed: () => _useTemplateMovement(
                                    context: context,
                                    db: db,
                                    onUsed: onUsed,
                                    title: qm.title,
                                    amount: qm.amount,
                                    type: qm.type,
                                    categoryId: qm.categoryId,
                                    subcategoryId: qm.subcategoryId,
                                    accountId: qm.accountId,
                                    note: qm.note,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showQuickForm(
    BuildContext context, {
    required AppDatabase db,
    QuickMovement? existing,
  }) {
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
  late final TextEditingController _noteCtrl;
  MovementType _type = MovementType.expense;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toString() : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      _type = e.type;
      _selectedCategoryId = e.categoryId;
      _selectedSubcategoryId = e.subcategoryId;
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

  List<Category> get _availableCategories => widget.db.categories
      .where((c) => c.type == _type && !c.archived)
      .toList();

  void _save() {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (title.isEmpty || amountText.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compila tutti i campi')));
      return;
    }
    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Importo non valido')));
      return;
    }

    final note = _noteCtrl.text.trim();
    final qm = QuickMovement(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      type: _type,
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId,
      accountId: _selectedAccountId ?? defaultAccountId,
      note: note.isNotEmpty ? note : null,
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
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
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
                    widget.existing != null
                        ? 'Modifica rapido'
                        : 'Nuovo movimento rapido',
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
                  ButtonSegment(
                    value: MovementType.expense,
                    label: Text('Uscita'),
                  ),
                  ButtonSegment(
                    value: MovementType.income,
                    label: Text('Entrata'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() {
                    _type = set.first;
                    _selectedCategoryId = null;
                    _selectedSubcategoryId = null;
                  });
                },
              ),
              const SizedBox(height: StreamSpacing.md),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titolo'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: StreamSpacing.md),
              CalculatorAmountField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Importo (€)'),
              ),
              const SizedBox(height: StreamSpacing.md),
              CategorySubcategorySelector(
                categories: widget.db.categories,
                subcategories: widget.db.subcategories,
                type: _type,
                selectedCategoryId: _selectedCategoryId,
                selectedSubcategoryId: _selectedSubcategoryId,
                onChanged: (categoryId, subcategoryId) => setState(() {
                  _selectedCategoryId = categoryId;
                  _selectedSubcategoryId = subcategoryId;
                }),
              ),
              const SizedBox(height: StreamSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Conto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(StreamRadius.md),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: StreamColors.surfaceElevated,
                ),
                items: widget.db.accounts
                    .where((a) => !a.archived)
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Row(
                          children: [
                            Icon(
                              StreamIconLibrary.getAccountIcon(a.iconKey),
                              size: 18,
                              color: Color(a.color),
                            ),
                            const SizedBox(width: 8),
                            Text(a.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: StreamSpacing.md),
              TextField(
                key: const Key('quick_movement_note_input'),
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nota (opzionale)',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                    widget.db.deleteQuickMovement(widget.existing!.id);
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StreamColors.expense,
                  ),
                  child: const Text('Elimina'),
                ),
              ],
            ],
          ),
        );
      },
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
              ...favorites.map(
                (fm) => _FavoriteTile(
                  fm: fm,
                  isSuggestion: false,
                  db: db,
                  onUsed: onUsed,
                ),
              ),
            if (suggestions.isNotEmpty)
              _SuggestedSection(
                suggestions: suggestions,
                db: db,
                onUsed: onUsed,
              ),
          ],
        );
      },
    );
  }

  void _showFavoriteForm(
    BuildContext context, {
    required AppDatabase db,
    FavoriteMovement? existing,
  }) {
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
    super.key,
    required this.fm,
    required this.isSuggestion,
    required this.db,
    required this.onUsed,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = resolveCategorySubcategorySelection(
      categories: db.categories,
      subcategories: db.subcategories,
      type: fm.type,
      categoryId: fm.categoryId,
      subcategoryId: fm.subcategoryId,
      activeOnly: false,
    );
    final favCat = resolved?.category;
    final catColor = resolved?.color ?? favCat?.color ?? 0xFF636366;
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Material(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(StreamRadius.md),
          onTap: () => _useTemplateMovement(
            context: context,
            db: db,
            onUsed: onUsed,
            title: fm.title,
            amount: fm.amount,
            type: fm.type,
            categoryId: fm.categoryId,
            subcategoryId: fm.subcategoryId,
            accountId: fm.accountId,
            note: fm.note,
          ),
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.md),
            child: Row(
              children: [
                _CategoryIcon(
                  color: catColor,
                  iconKey:
                      resolved?.iconKey ??
                      favCat?.iconKey ??
                      StreamIconLibrary.defaultCategoryIcon,
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
                        '${resolved?.label ?? favCat?.name ?? ''} • ${formatMovementCurrency(fm.type == MovementType.expense ? -fm.amount : fm.amount, showPositiveSign: true)}',
                        style: StreamTypography.caption.copyWith(
                          color: StreamColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSuggestion) ...[
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: 18,
                          color: StreamColors.textMuted,
                        ),
                        onPressed: () =>
                            _showFavoriteForm(context, db: db, existing: fm),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: StreamColors.expense,
                        ),
                        onPressed: () => db.deleteFavoriteMovement(fm.id),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(
                        Icons.play_arrow,
                        size: 22,
                        color: StreamColors.primary,
                      ),
                      tooltip: 'Usa',
                      onPressed: () => _useTemplateMovement(
                        context: context,
                        db: db,
                        onUsed: onUsed,
                        title: fm.title,
                        amount: fm.amount,
                        type: fm.type,
                        categoryId: fm.categoryId,
                        subcategoryId: fm.subcategoryId,
                        accountId: fm.accountId,
                        note: fm.note,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFavoriteForm(
    BuildContext context, {
    required AppDatabase db,
    required FavoriteMovement existing,
  }) {
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
  String? _selectedSubcategoryId;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toString() : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      _type = e.type;
      _selectedCategoryId = e.categoryId;
      _selectedSubcategoryId = e.subcategoryId;
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

  List<Category> get _availableCategories => widget.db.categories
      .where((c) => c.type == _type && !c.archived)
      .toList();

  void _save() {
    final title = _titleCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    if (title.isEmpty || amountText.isEmpty || _selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compila tutti i campi')));
      return;
    }
    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Importo non valido')));
      return;
    }

    if (widget.existing != null) {
      widget.db.deleteFavoriteMovement(widget.existing!.id);
    }

    widget.db.addFavoriteMovement(
      FavoriteMovement(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        amount: amount,
        type: _type,
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId,
        accountId: _selectedAccountId ?? defaultAccountId,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
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
                    widget.existing != null
                        ? 'Modifica preferito'
                        : 'Nuovo preferito',
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
                  ButtonSegment(
                    value: MovementType.expense,
                    label: Text('Uscita'),
                  ),
                  ButtonSegment(
                    value: MovementType.income,
                    label: Text('Entrata'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() {
                    _type = set.first;
                    _selectedCategoryId = null;
                    _selectedSubcategoryId = null;
                  });
                },
              ),
              const SizedBox(height: StreamSpacing.md),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titolo'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: StreamSpacing.md),
              CalculatorAmountField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Importo (€)'),
              ),
              const SizedBox(height: StreamSpacing.md),
              CategorySubcategorySelector(
                categories: widget.db.categories,
                subcategories: widget.db.subcategories,
                type: _type,
                selectedCategoryId: _selectedCategoryId,
                selectedSubcategoryId: _selectedSubcategoryId,
                onChanged: (categoryId, subcategoryId) => setState(() {
                  _selectedCategoryId = categoryId;
                  _selectedSubcategoryId = subcategoryId;
                }),
              ),
              const SizedBox(height: StreamSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Conto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(StreamRadius.md),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: StreamColors.surfaceElevated,
                ),
                items: widget.db.accounts
                    .where((a) => !a.archived)
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Row(
                          children: [
                            Icon(
                              StreamIconLibrary.getAccountIcon(a.iconKey),
                              size: 18,
                              color: Color(a.color),
                            ),
                            const SizedBox(width: 8),
                            Text(a.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: StreamSpacing.md),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nota (opzionale)',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StreamColors.expense,
                  ),
                  child: const Text('Elimina'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// Suggeriti — sezione espandibile, ricercabile, per categoria
// ============================================================

class _SuggestedSection extends StatefulWidget {
  final List<FavoriteMovement> suggestions;
  final AppDatabase db;
  final VoidCallback onUsed;

  const _SuggestedSection({
    required this.suggestions,
    required this.db,
    required this.onUsed,
  });

  @override
  State<_SuggestedSection> createState() => _SuggestedSectionState();
}

class _SuggestedSectionState extends State<_SuggestedSection> {
  bool _expanded = true;
  String _searchQuery = '';
  final Set<String> _expandedCategories = {};
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FavoriteMovement> get _filtered {
    if (_searchQuery.isEmpty) return widget.suggestions;
    final q = _searchQuery.toLowerCase();
    return widget.suggestions.where((fm) {
      final cat = widget.db.categories
          .where((c) => c.id == fm.categoryId)
          .firstOrNull;
      final catName = cat?.name ?? '';
      String? subcatName;
      if (fm.subcategoryId != null) {
        subcatName = widget.db.subcategories
            .where((s) => s.id == fm.subcategoryId)
            .firstOrNull
            ?.name;
      }
      return fm.title.toLowerCase().contains(q) ||
          catName.toLowerCase().contains(q) ||
          (subcatName?.toLowerCase().contains(q) ?? false) ||
          (fm.note?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Map<String, List<FavoriteMovement>> get _grouped {
    final map = <String, List<FavoriteMovement>>{};
    for (final fm in _filtered) {
      final cat = widget.db.categories
          .where((c) => c.id == fm.categoryId)
          .firstOrNull;
      final catName = cat?.name ?? 'Senza categoria';
      map.putIfAbsent(catName, () => []).add(fm);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    return KeyedSubtree(
      key: const Key('suggested_section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: StreamSpacing.md),
          InkWell(
            key: const Key('suggested_section_header'),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: StreamColors.textMuted,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: StreamColors.textMuted,
                ),
                const SizedBox(width: StreamSpacing.sm),
                Text(
                  'Suggeriti (${widget.suggestions.length})',
                  style: StreamTypography.h3,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: StreamSpacing.sm),
            TextField(
              key: const Key('suggested_search_field'),
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cerca…',
                prefixIcon: Icon(Icons.search, size: 18),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: StreamSpacing.sm),
            if (grouped.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  key: Key('suggested_empty_state'),
                  child: Text('Nessun suggerito trovato.'),
                ),
              )
            else
              ...grouped.entries.map((entry) {
                final categoryName = entry.key;
                final items = entry.value;
                final isCatExpanded =
                    _searchQuery.isNotEmpty ||
                    _expandedCategories.contains(categoryName);
                return KeyedSubtree(
                  key: Key('suggested_category_group_$categoryName'),
                  child: Column(
                    children: [
                      InkWell(
                        key: const Key('suggested_category_header'),
                        onTap: _searchQuery.isEmpty
                            ? () {
                                setState(() {
                                  if (_expandedCategories.contains(
                                    categoryName,
                                  )) {
                                    _expandedCategories.remove(categoryName);
                                  } else {
                                    _expandedCategories.add(categoryName);
                                  }
                                });
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isCatExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 18,
                                color: StreamColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$categoryName (${items.length})',
                                  style: StreamTypography.captionBold.copyWith(
                                    color: StreamColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isCatExpanded)
                        ...items.map(
                          (fm) => _FavoriteTile(
                            key: Key('suggested_item_${fm.id}'),
                            fm: fm,
                            isSuggestion: true,
                            db: widget.db,
                            onUsed: widget.onUsed,
                          ),
                        ),
                    ],
                  ),
                );
              }),
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

  const _CategoryIcon({
    required this.color,
    required this.iconKey,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(StreamRadius.sm),
      ),
      child: Icon(
        StreamIconLibrary.getIcon(iconKey),
        color: Colors.white,
        size: size * 0.45,
      ),
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
        child: Text(
          message,
          style: StreamTypography.body.copyWith(
            color: StreamColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
