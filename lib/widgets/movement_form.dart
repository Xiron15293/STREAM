import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../theme.dart';
import '../util/beneficiary_helpers.dart';
import 'beneficiary_picker_sheet.dart';
import 'calculator_amount_pad.dart';
import 'category_subcategory_selector.dart';

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
      text: p != null ? p.amount.toString() : '',
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
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return;
    }

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (isTransfer) {
      final origin = _selectedAccountId;
      final destination = _selectedDestinationAccountId;
      if (origin == null || destination == null || origin == destination) {
        return;
      }

      if (widget.prefill != null) {
        await widget.db.updateMovement(
          widget.prefill!.copyWith(
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
          ),
        );
      } else {
        await widget.db.createMovementFromTemplate(
          title: title,
          amount: amount,
          type: _type,
          date: _date,
          categoryId: '',
          accountId: origin,
          destinationAccountId: destination,
          note: note,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final payee = widget.db.cleanBeneficiaryName(_payeeCtrl.text);
    final payeeDecision = await askToSaveBeneficiary(context, widget.db, payee);
    if (!mounted || payeeDecision == SaveBeneficiaryDecision.cancel) {
      return;
    }

    if (widget.prefill != null) {
      await widget.db.updateMovement(
        widget.prefill!.copyWith(
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
        ),
      );
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
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
                    widget.prefill != null
                        ? 'Modifica movimento'
                        : 'Nuovo movimento',
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
                    labelText: _type == MovementType.income
                        ? 'Pagatore / Fonte'
                        : 'Beneficiario / Esercente',
                    suffixIcon: IconButton(
                      key: const Key('movement_beneficiary_picker_button'),
                      onPressed: _pickBeneficiary,
                      icon: const Icon(Icons.people_outline),
                      tooltip: 'Apri beneficiari',
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: StreamSpacing.md),
              ],
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
                decoration: const InputDecoration(
                  labelText: 'Nota (opzionale)',
                ),
                textInputAction: TextInputAction.done,
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
      },
    );
  }
}
