import 'package:flutter/material.dart';

import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/subcategory.dart';
import '../theme.dart';
import '../util/beneficiary_helpers.dart';
import '../utils/currency_formatter.dart';
import 'beneficiary_picker_sheet.dart';
import 'calculator_amount_pad.dart';
import 'movement_calculator_pad.dart';
import 'movement_text_suggestions.dart';

enum _FlowStep { category, subcategory, account, transferAccounts, details }

class AddMovementFlow extends StatefulWidget {
  final AppDatabase db;
  final Movement? prefill;
  final String? categoryPreFill;
  final String? accountPreFill;
  final MovementType? initialType;
  final VoidCallback onSaved;

  const AddMovementFlow({
    super.key,
    required this.db,
    this.prefill,
    this.categoryPreFill,
    this.accountPreFill,
    this.initialType,
    required this.onSaved,
  });

  @override
  State<AddMovementFlow> createState() => _AddMovementFlowState();
}

class _AddMovementFlowState extends State<AddMovementFlow> {
  final _titleCtrl = TextEditingController();
  final _counterpartyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _counterpartyFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  final _detailsScrollCtrl = ScrollController();
  final _evaluator = const AmountExpressionEvaluator();

  MovementType _type = MovementType.expense;
  _FlowStep _step = _FlowStep.category;
  String _search = '';
  String? _categoryId;
  String? _subcategoryId;
  String? _accountId;
  String? _destinationAccountId;
  DateTime _date = DateTime.now();
  String? _selectionError;
  bool _showStickyAmount = false;
  bool get _isEditing => widget.prefill != null;

  void _handleAmountChanged() {
    if (mounted) setState(() {});
  }

  void _handleDetailsScroll() {
    final shouldShow =
        _detailsScrollCtrl.hasClients && _detailsScrollCtrl.offset > 120;
    if (!mounted || shouldShow == _showStickyAmount) return;
    setState(() => _showStickyAmount = shouldShow);
  }

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _type = p.type;
      _titleCtrl.text = p.title;
      _counterpartyCtrl.text = p.payee ?? '';
      _noteCtrl.text = p.note ?? '';
      _amountCtrl.text = formatAmountExpressionValue(p.amount);
      _categoryId = p.categoryId.isEmpty ? null : p.categoryId;
      _subcategoryId = p.subcategoryId;
      _accountId = p.accountId;
      _destinationAccountId = p.destinationAccountId;
      _date = p.date;
    } else {
      _type = widget.initialType ?? MovementType.expense;
      _categoryId = widget.categoryPreFill;
      _accountId = widget.accountPreFill;
    }
    _syncInitialState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim().toLowerCase());
    });
    _amountCtrl.addListener(_handleAmountChanged);
    _detailsScrollCtrl.addListener(_handleDetailsScroll);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_handleAmountChanged);
    _detailsScrollCtrl.removeListener(_handleDetailsScroll);
    _titleCtrl.dispose();
    _counterpartyCtrl.dispose();
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    _titleFocusNode.dispose();
    _counterpartyFocusNode.dispose();
    _noteFocusNode.dispose();
    _detailsScrollCtrl.dispose();
    super.dispose();
  }

  void _syncInitialState() {
    final category = _selectedCategory;
    if (category != null) {
      _type = category.type;
    }
    _accountId ??= _activeAccounts.isNotEmpty ? _activeAccounts.first.id : null;
    if (_type == MovementType.transfer) {
      _destinationAccountId ??= _activeAccounts.length > 1
          ? _activeAccounts[1].id
          : _accountId;
      _step = _FlowStep.transferAccounts;
      return;
    }
    if (_categoryId != null) {
      final hasSubs = _subcategoriesFor(_categoryId!).isNotEmpty;
      if (_type == MovementType.income) {
        _step = _accountId == null ? _FlowStep.account : _FlowStep.details;
      } else if (hasSubs && _subcategoryId == null) {
        _step = _FlowStep.subcategory;
      } else if (_accountId != null) {
        _step = _FlowStep.details;
      }
    }
  }

  List<Account> get _activeAccounts =>
      widget.db.accounts.where((a) => !a.archived).toList();

  List<Category> get _categories =>
      widget.db.categories.where((c) => c.type == _type && !c.archived).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Category? get _selectedCategory =>
      widget.db.categories.where((c) => c.id == _categoryId).firstOrNull;

  Subcategory? get _selectedSubcategory =>
      widget.db.subcategories.where((s) => s.id == _subcategoryId).firstOrNull;

  Account? get _selectedAccount =>
      widget.db.accounts.where((a) => a.id == _accountId).firstOrNull;

  Account? get _selectedDestinationAccount => widget.db.accounts
      .where((a) => a.id == _destinationAccountId)
      .firstOrNull;

  List<Subcategory> _subcategoriesFor(String categoryId) {
    final items =
        widget.db.subcategories
            .where((s) => s.categoryId == categoryId && !s.archived)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  void _changeType(MovementType type) {
    if (_type == type) return;
    setState(() {
      _type = type;
      _categoryId = null;
      _subcategoryId = null;
      _searchCtrl.clear();
      _selectionError = null;
      if (_type == MovementType.transfer) {
        _accountId ??= _activeAccounts.isNotEmpty
            ? _activeAccounts.first.id
            : null;
        _destinationAccountId ??= _activeAccounts.length > 1
            ? _activeAccounts[1].id
            : _accountId;
        _step = _FlowStep.transferAccounts;
      } else {
        _destinationAccountId = null;
        _step = _FlowStep.category;
      }
    });
  }

  void _selectCategory(Category category) {
    final hasSubs = _subcategoriesFor(category.id).isNotEmpty;
    setState(() {
      _categoryId = category.id;
      _subcategoryId = null;
      _selectionError = null;
      if (_type == MovementType.income) {
        _step = _FlowStep.account;
      } else {
        _step = hasSubs ? _FlowStep.subcategory : _FlowStep.details;
      }
    });
  }

  void _selectSubcategory(String? subcategoryId) {
    setState(() {
      _subcategoryId = subcategoryId;
      _selectionError = null;
      _step = _FlowStep.details;
    });
  }

  void _selectAccount(String accountId) {
    setState(() {
      _accountId = accountId;
      _selectionError = null;
      _step = _FlowStep.details;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickBeneficiary() async {
    final selected = await showBeneficiaryPickerSheet(
      context,
      widget.db,
      initialQuery: _counterpartyCtrl.text,
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() {
      _counterpartyCtrl.text = selected;
    });
  }

  String _amountDisplayText() {
    return formatAmountInputDisplay(_amountCtrl.text);
  }

  String _currentCurrencySymbol() {
    return currencySymbolForCurrentPreference();
  }

  String _formatCurrency(double value) {
    return formatMovementCurrency(value);
  }

  String _formatDateLabel() {
    final monthNames = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_date.year, _date.month, _date.day);
    final dateText =
        '${_date.day} ${monthNames[_date.month - 1]} ${_date.year}';
    return selected == today ? 'Oggi, $dateText' : dateText;
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

  String _titleLabel() {
    final prefix = _isEditing ? 'Modifica' : 'Nuova';
    switch (_type) {
      case MovementType.income:
        return '$prefix entrata';
      case MovementType.expense:
        return '$prefix spesa';
      case MovementType.transfer:
        return '$prefix trasferimento';
    }
  }

  String _submitTooltip() {
    return _type == MovementType.transfer
        ? 'Conferma trasferimento'
        : 'Salva movimento';
  }

  List<Category> _frequentCategories() {
    final usage = <String, int>{};
    for (final movement in widget.db.movements.where((m) => m.type == _type)) {
      usage.update(
        movement.categoryId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final ids = _categories.map((c) => c.id).toSet();
    final sorted = usage.entries.where((e) => ids.contains(e.key)).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final frequent = sorted
        .map((entry) => _categories.firstWhere((c) => c.id == entry.key))
        .take(4)
        .toList();
    if (frequent.isNotEmpty) return frequent;
    final preferredNames = _type == MovementType.expense
        ? {'Casa', 'Spesa', 'Fumo', 'Auto'}
        : {'Stipendio', 'Pensione', 'Regalo', 'Rimborso'};
    final matching = _categories
        .where((c) => preferredNames.contains(c.name))
        .take(4)
        .toList();
    return matching.isNotEmpty ? matching : _categories.take(4).toList();
  }

  List<Account> _frequentAccounts() {
    final usage = <String, int>{};
    for (final movement in widget.db.movements) {
      usage.update(movement.accountId, (value) => value + 1, ifAbsent: () => 1);
      if (movement.destinationAccountId != null) {
        usage.update(
          movement.destinationAccountId!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final activeIds = _activeAccounts.map((a) => a.id).toSet();
    final sorted =
        usage.entries.where((e) => activeIds.contains(e.key)).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final frequent = sorted
        .map((entry) => _activeAccounts.firstWhere((a) => a.id == entry.key))
        .take(4)
        .toList();
    return frequent.isNotEmpty ? frequent : _activeAccounts.take(4).toList();
  }

  double _categoryTotal(String categoryId) {
    return widget.db.movements
        .where((m) => m.categoryId == categoryId && m.type == _type)
        .fold<double>(0, (sum, m) => sum + m.amount);
  }

  Future<void> _submit() async {
    final trimmedTitle = _titleCtrl.text.trim();
    final amountResult = _evaluator.evaluate(
      _amountCtrl.text.trim(),
      allowNegative: false,
    );
    if (!amountResult.isValid ||
        amountResult.value == null ||
        amountResult.value! <= 0) {
      setState(
        () => _selectionError = 'Inserisci un importo valido maggiore di zero',
      );
      return;
    }
    final normalizedAmount = double.parse(
      amountResult.value!.toStringAsFixed(2),
    );

    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_type == MovementType.transfer) {
      if (_accountId == null ||
          _destinationAccountId == null ||
          _accountId == _destinationAccountId) {
        setState(() {
          _selectionError = 'Origine e destinazione non possono coincidere';
        });
        return;
      }
      if (_isEditing) {
        await widget.db.updateMovement(
          widget.prefill!.copyWith(
            title: trimmedTitle.isEmpty ? widget.prefill!.title : trimmedTitle,
            amount: normalizedAmount,
            type: MovementType.transfer,
            date: _date,
            categoryId: '',
            subcategoryId: null,
            accountId: _accountId!,
            destinationAccountId: _destinationAccountId,
            note: note,
            payee: null,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await widget.db.createMovementFromTemplate(
          title: trimmedTitle,
          amount: normalizedAmount,
          type: MovementType.transfer,
          date: _date,
          categoryId: '',
          accountId: _accountId,
          destinationAccountId: _destinationAccountId,
          note: note,
        );
      }
      if (!mounted) return;
      widget.onSaved();
      return;
    }

    if (trimmedTitle.isEmpty || _categoryId == null || _accountId == null) {
      setState(
        () => _selectionError = 'Completa selezioni e campi obbligatori',
      );
      return;
    }

    final payee = widget.db.cleanBeneficiaryName(_counterpartyCtrl.text);
    final payeeDecision = await askToSaveBeneficiary(context, widget.db, payee);
    if (!mounted || payeeDecision == SaveBeneficiaryDecision.cancel) {
      return;
    }

    if (_isEditing) {
      await widget.db.updateMovement(
        widget.prefill!.copyWith(
          title: trimmedTitle,
          amount: normalizedAmount,
          type: _type,
          date: _date,
          categoryId: _categoryId!,
          subcategoryId: _subcategoryId,
          accountId: _accountId!,
          note: note,
          payee: payee.isEmpty ? null : payee,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await widget.db.createMovementFromTemplate(
        title: trimmedTitle,
        amount: normalizedAmount,
        type: _type,
        date: _date,
        categoryId: _categoryId!,
        subcategoryId: _subcategoryId,
        accountId: _accountId,
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                  value: MovementType.income,
                  label: Text('Entrata'),
                ),
                ButtonSegment(
                  value: MovementType.expense,
                  label: Text('Spesa'),
                ),
                ButtonSegment(
                  value: MovementType.transfer,
                  label: Text('Trasferimento'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => _changeType(set.first),
            ),
            const SizedBox(height: StreamSpacing.md),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (_step) {
                _FlowStep.category => _buildCategoryStep(),
                _FlowStep.subcategory => _buildSubcategoryStep(),
                _FlowStep.account => _buildAccountStep(),
                _FlowStep.transferAccounts => _buildTransferAccountsStep(),
                _FlowStep.details => _buildDetailsStep(),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryStep() {
    final frequent = _frequentCategories();
    final filtered = _categories
        .where((c) => _search.isEmpty || c.name.toLowerCase().contains(_search))
        .toList();
    return SingleChildScrollView(
      key: const Key('add_movement_category_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _type == MovementType.income
                ? 'Scegli categoria entrata'
                : 'Scegli categoria spesa',
            style: StreamTypography.h3,
          ),
          const SizedBox(height: StreamSpacing.md),
          TextField(
            key: const Key('add_movement_category_search'),
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Cerca categoria...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: StreamSpacing.lg),
          if (frequent.isNotEmpty) ...[
            Text('Più usate', style: StreamTypography.h3),
            const SizedBox(height: StreamSpacing.sm),
            Wrap(
              spacing: StreamSpacing.sm,
              runSpacing: StreamSpacing.sm,
              children: frequent.map(_buildFrequentCategoryChip).toList(),
            ),
            const SizedBox(height: StreamSpacing.lg),
          ],
          Text('Tutte le categorie', style: StreamTypography.h3),
          const SizedBox(height: StreamSpacing.sm),
          ...filtered.map(_buildCategoryTile),
        ],
      ),
    );
  }

  Widget _buildSubcategoryStep() {
    final p = context.$palette;
    final category = _selectedCategory;
    final subcategories = category == null
        ? const <Subcategory>[]
        : _subcategoriesFor(category.id);
    return SingleChildScrollView(
      key: const Key('add_movement_subcategory_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _step = _FlowStep.category),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              Expanded(
                child: Text(
                  category == null
                      ? 'Scegli sottocategoria'
                      : 'Sottocategorie ${category.name}',
                  style: StreamTypography.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          OutlinedButton(
            key: const Key('skip_subcategory_button'),
            onPressed: () => _selectSubcategory(null),
            child: const Text('Continua senza sottocategoria'),
          ),
          const SizedBox(height: StreamSpacing.md),
          ...subcategories.map((sub) {
            return Material(
              color: Colors.transparent,
              child: ListTile(
                key: Key('subcategory_option_${sub.id}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(StreamRadius.md),
                ),
                tileColor: p.surfaceElevated,
                leading: _IconBubble(
                  color: sub.color ?? category?.color ?? p.primary.toARGB32(),
                  iconKey:
                      sub.iconKey ??
                      category?.iconKey ??
                      StreamIconLibrary.defaultCategoryIcon,
                ),
                title: Text(sub.name),
                onTap: () => _selectSubcategory(sub.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccountStep() {
    final frequent = _frequentAccounts();
    return SingleChildScrollView(
      key: const Key('add_movement_account_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _step = _FlowStep.category),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              Expanded(
                child: Text(
                  _type == MovementType.income
                      ? 'Scegli conto di destinazione'
                      : 'Scegli conto di origine',
                  style: StreamTypography.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.md),
          Text('Conti frequenti', style: StreamTypography.h3),
          const SizedBox(height: StreamSpacing.sm),
          Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.sm,
            children: frequent.map((account) {
              return _SelectionChip(
                widgetKey: Key('income_account_chip_${account.id}'),
                label: account.name,
                icon: StreamIconLibrary.getAccountIcon(account.iconKey),
                color: Color(account.color),
                selected: _accountId == account.id,
                onTap: () => _selectAccount(account.id),
              );
            }).toList(),
          ),
          const SizedBox(height: StreamSpacing.lg),
          Text('Tutti i conti', style: StreamTypography.h3),
          const SizedBox(height: StreamSpacing.sm),
          ..._activeAccounts.map(
            (account) => _buildAccountTile(
              account,
              onTap: () => _selectAccount(account.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferAccountsStep() {
    final p = context.$palette;
    final invalid =
        _accountId != null &&
        _destinationAccountId != null &&
        _accountId == _destinationAccountId;
    return SingleChildScrollView(
      key: const Key('add_movement_transfer_step'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Trasferisci denaro', style: StreamTypography.h3),
          const SizedBox(height: StreamSpacing.md),
          if (_selectedAccount != null ||
              _selectedDestinationAccount != null) ...[
            Container(
              key: const Key('transfer_selection_summary'),
              padding: const EdgeInsets.all(StreamSpacing.md),
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                borderRadius: BorderRadius.circular(StreamRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TransferSelectionSummary(
                      label: 'Origine',
                      account: _selectedAccount,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: StreamSpacing.sm),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: p.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: _TransferSelectionSummary(
                      label: 'Destinazione',
                      account: _selectedDestinationAccount,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StreamSpacing.lg),
          ],
          Text('Conto origine', style: StreamTypography.h3),
          Text(
            'Scegli da dove inviare',
            style: StreamTypography.caption.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: StreamSpacing.sm),
          Container(
            key: const Key('transfer_origin_list'),
            padding: const EdgeInsets.all(StreamSpacing.sm),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(StreamRadius.lg),
            ),
            child: Column(
              children: _activeAccounts
                  .map(
                    (account) => _buildTransferAccountTile(
                      account,
                      scope: 'origin',
                      selected: _accountId == account.id,
                      onTap: () => setState(() {
                        _accountId = account.id;
                        _selectionError = null;
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: StreamSpacing.lg),
          Text('Conto destinazione', style: StreamTypography.h3),
          Text(
            'Scegli dove inviare',
            style: StreamTypography.caption.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: StreamSpacing.sm),
          Container(
            key: const Key('transfer_destination_list'),
            padding: const EdgeInsets.all(StreamSpacing.sm),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(StreamRadius.lg),
            ),
            child: Column(
              children: _activeAccounts
                  .map(
                    (account) => _buildTransferAccountTile(
                      account,
                      scope: 'destination',
                      selected: _destinationAccountId == account.id,
                      onTap: () => setState(() {
                        _destinationAccountId = account.id;
                        _selectionError = null;
                      }),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (invalid) ...[
            const SizedBox(height: StreamSpacing.md),
            Text(
              'Origine e destinazione non possono coincidere',
              key: const Key('transfer_same_account_error'),
              style: StreamTypography.caption.copyWith(color: p.expense),
            ),
          ],
          const SizedBox(height: StreamSpacing.lg),
          FilledButton(
            key: const Key('transfer_continue_button'),
            onPressed:
                invalid || _accountId == null || _destinationAccountId == null
                ? null
                : () => setState(() {
                    _selectionError = null;
                    _step = _FlowStep.details;
                  }),
            child: const Text('Continua'),
          ),
          const SizedBox(height: StreamSpacing.sm),
          OutlinedButton(
            key: const Key('transfer_cancel_button'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancella'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    final p = context.$palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.85;
        return SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDetailsHeader(),
              const SizedBox(height: StreamSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _showStickyAmount
                    ? Container(
                        key: const Key('movement_amount_sticky'),
                        margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: StreamSpacing.md,
                          vertical: StreamSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: p.surfaceElevated,
                          borderRadius: BorderRadius.circular(StreamRadius.md),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 16,
                              offset: Offset(0, 6),
                              color: Color(0x22000000),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Importo', style: StreamTypography.caption),
                            Text(
                              '${_amountDisplayText()} ${_currentCurrencySymbol()}',
                              style: StreamTypography.bodyBold.copyWith(
                                color: p.primary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: const Key('add_movement_details_step'),
                  controller: _detailsScrollCtrl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: StreamSpacing.md),
                      _buildTopSelectors(),
                      const SizedBox(height: StreamSpacing.lg),
                      Text(
                        _amountDisplayText(),
                        key: const Key('movement_amount_display'),
                        textAlign: TextAlign.center,
                        style: StreamTypography.amountLarge.copyWith(
                          color: p.primary,
                        ),
                      ),
                      const SizedBox(height: StreamSpacing.lg),
                      TextField(
                        key: const Key('movement_title_field'),
                        controller: _titleCtrl,
                        focusNode: _titleFocusNode,
                        decoration: const InputDecoration(labelText: 'Titolo'),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                      MovementTextSuggestions(
                        db: widget.db,
                        controller: _titleCtrl,
                        focusNode: _titleFocusNode,
                        field: MovementTextSuggestionField.title,
                        type: _type,
                        categoryId: _categoryId,
                        beneficiary: _counterpartyCtrl.text,
                      ),
                      const SizedBox(height: StreamSpacing.md),
                      TextField(
                        key: const Key('movement_counterparty_field'),
                        controller: _counterpartyCtrl,
                        focusNode: _counterpartyFocusNode,
                        decoration: InputDecoration(
                          labelText: _counterpartyLabel(),
                          suffixIcon: IconButton(
                            key: const Key(
                              'movement_beneficiary_picker_button',
                            ),
                            onPressed: _pickBeneficiary,
                            icon: const Icon(Icons.people_outline),
                            tooltip: 'Apri beneficiari',
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                      MovementBeneficiarySuggestions(
                        db: widget.db,
                        controller: _counterpartyCtrl,
                        focusNode: _counterpartyFocusNode,
                        limit: 5,
                      ),
                      const SizedBox(height: StreamSpacing.md),
                      TextField(
                        key: const Key('movement_note_field'),
                        controller: _noteCtrl,
                        focusNode: _noteFocusNode,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Note'),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                      MovementTextSuggestions(
                        db: widget.db,
                        controller: _noteCtrl,
                        focusNode: _noteFocusNode,
                        field: MovementTextSuggestionField.note,
                        type: _type,
                        categoryId: _categoryId,
                        beneficiary: _counterpartyCtrl.text,
                        limit: 4,
                      ),
                      const SizedBox(height: StreamSpacing.md),
                      InkWell(
                        key: const Key('movement_date_field'),
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                          ),
                          child: Text(_formatDateLabel()),
                        ),
                      ),
                      const SizedBox(height: StreamSpacing.md),
                      MovementCalculatorPad(
                        controller: _amountCtrl,
                        onDateTap: _pickDate,
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        _formatDateLabel(),
                        textAlign: TextAlign.center,
                        style: StreamTypography.bodyBold.copyWith(
                          color: p.primary,
                        ),
                      ),
                      if (_selectionError != null) ...[
                        const SizedBox(height: StreamSpacing.md),
                        Text(
                          _selectionError!,
                          style: StreamTypography.caption.copyWith(
                            color: p.expense,
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailsHeader() {
    return Row(
      key: const Key('movement_details_header'),
      children: [
        IconButton(
          key: const Key('movement_back_button'),
          onPressed: () => setState(() {
            _selectionError = null;
            _step = switch (_type) {
              MovementType.transfer => _FlowStep.transferAccounts,
              MovementType.income => _FlowStep.account,
              MovementType.expense =>
                _selectedCategory != null &&
                        _subcategoriesFor(_selectedCategory!.id).isNotEmpty
                    ? _FlowStep.subcategory
                    : _FlowStep.category,
            };
            _showStickyAmount = false;
          }),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          tooltip: 'Indietro',
        ),
        Expanded(
          child: Text(
            _titleLabel(),
            style: StreamTypography.h3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Tooltip(
          message: 'Chiudi',
          child: IconButton(
            key: const Key('movement_close_top_button'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ),
        Tooltip(
          message: _submitTooltip(),
          child: IconButton.filled(
            key: const Key('movement_submit_top_button'),
            onPressed: _submit,
            icon: Icon(
              _type == MovementType.transfer
                  ? Icons.compare_arrows_rounded
                  : Icons.check_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSelectors() {
    final p = context.$palette;
    if (_type == MovementType.transfer) {
      return Row(
        children: [
          Expanded(
            child: _SelectorPill(
              label: 'Origine',
              value: _selectedAccount?.name ?? 'Seleziona',
              icon: _selectedAccount == null
                  ? Icons.account_balance_wallet_outlined
                  : StreamIconLibrary.getAccountIcon(_selectedAccount!.iconKey),
              color: _selectedAccount == null
                  ? p.primary
                  : Color(_selectedAccount!.color),
              onTap: () => setState(() => _step = _FlowStep.transferAccounts),
            ),
          ),
          IconButton(
            key: const Key('transfer_swap_button'),
            onPressed: () => setState(() {
              final previous = _accountId;
              _accountId = _destinationAccountId;
              _destinationAccountId = previous;
            }),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          Expanded(
            child: _SelectorPill(
              label: 'Destinazione',
              value: _selectedDestinationAccount?.name ?? 'Seleziona',
              icon: _selectedDestinationAccount == null
                  ? Icons.account_balance_wallet_outlined
                  : StreamIconLibrary.getAccountIcon(
                      _selectedDestinationAccount!.iconKey,
                    ),
              color: _selectedDestinationAccount == null
                  ? p.primary
                  : Color(_selectedDestinationAccount!.color),
              onTap: () => setState(() => _step = _FlowStep.transferAccounts),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: StreamSpacing.sm,
      runSpacing: StreamSpacing.sm,
      children: [
        _SelectorPill(
          label: _type == MovementType.income ? 'A conto' : 'Da conto',
          value: _selectedAccount?.name ?? 'Seleziona',
          icon: _selectedAccount == null
              ? Icons.account_balance_wallet_outlined
              : StreamIconLibrary.getAccountIcon(_selectedAccount!.iconKey),
          color: _selectedAccount == null
              ? p.primary
              : Color(_selectedAccount!.color),
          onTap: () => setState(() => _step = _FlowStep.account),
        ),
        _SelectorPill(
          label: 'Categoria',
          value: _selectedCategory?.name ?? 'Seleziona',
          icon: _selectedCategory == null
              ? Icons.sell_outlined
              : StreamIconLibrary.getIcon(_selectedCategory!.iconKey),
          color: _selectedCategory == null
              ? p.primary
              : Color(_selectedCategory!.color),
          onTap: () => setState(() => _step = _FlowStep.category),
        ),
        if (_selectedCategory != null &&
            _subcategoriesFor(_selectedCategory!.id).isNotEmpty)
          _SelectorPill(
            label: 'Sottocategoria',
            value: _selectedSubcategory?.name ?? 'Opzionale',
            icon: _selectedSubcategory?.iconKey != null
                ? StreamIconLibrary.getIcon(_selectedSubcategory!.iconKey!)
                : Icons.label_outline,
            color: _selectedSubcategory?.color != null
                ? Color(_selectedSubcategory!.color!)
                : p.surfaceElevated,
            onTap: () => setState(() => _step = _FlowStep.subcategory),
          ),
      ],
    );
  }

  Widget _buildFrequentCategoryChip(Category category) {
    return _SelectionChip(
      widgetKey: Key('frequent_category_${category.id}'),
      label: category.name,
      subtitle: _categoryTotal(category.id) > 0
          ? _formatCurrency(_categoryTotal(category.id))
          : null,
      icon: StreamIconLibrary.getIcon(category.iconKey),
      color: Color(category.color),
      selected: _categoryId == category.id,
      onTap: () => _selectCategory(category),
    );
  }

  Widget _buildCategoryTile(Category category) {
    final p = context.$palette;
    final total = _categoryTotal(category.id);
    final hasSubs = _subcategoriesFor(category.id).isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Material(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        child: InkWell(
          key: Key('category_option_${category.id}'),
          borderRadius: BorderRadius.circular(StreamRadius.md),
          onTap: () => _selectCategory(category),
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.md),
            child: Row(
              children: [
                _IconBubble(color: category.color, iconKey: category.iconKey),
                const SizedBox(width: StreamSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: StreamTypography.bodyBold),
                      if (total > 0)
                        Text(
                          _formatCurrency(total),
                          style: StreamTypography.caption.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasSubs)
                  Icon(Icons.chevron_right_rounded, color: p.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(Account account, {required VoidCallback onTap}) {
    final p = context.$palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Material(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        child: InkWell(
          key: Key('account_option_${account.id}'),
          borderRadius: BorderRadius.circular(StreamRadius.md),
          onTap: onTap,
          child: ListTile(
            leading: _IconBubble(
              color: account.color,
              iconKey: account.iconKey,
            ),
            title: Text(account.name),
            trailing: Icon(Icons.chevron_right_rounded, color: p.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferAccountTile(
    Account account, {
    required String scope,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final p = context.$palette;
    final balance = widget.db.getAccountBalance(account);
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Material(
        color: selected ? p.primary.withValues(alpha: 0.08) : p.surfaceElevated,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        child: InkWell(
          key: Key('transfer_${scope}_option_${account.id}'),
          borderRadius: BorderRadius.circular(StreamRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(StreamSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(StreamRadius.md),
              border: Border.all(
                color: selected ? p.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _IconBubble(color: account.color, iconKey: account.iconKey),
                const SizedBox(width: StreamSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: StreamTypography.bodyBold),
                      Text(
                        _formatCurrency(balance),
                        style: StreamTypography.caption.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? p.primary : p.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferSelectionSummary extends StatelessWidget {
  final String label;
  final Account? account;

  const _TransferSelectionSummary({required this.label, required this.account});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final selectedAccount = account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: StreamTypography.caption.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: StreamSpacing.xs),
        Row(
          children: [
            _IconBubble(
              color: selectedAccount?.color ?? p.primary.toARGB32(),
              iconKey:
                  selectedAccount?.iconKey ??
                  StreamIconLibrary.defaultAccountIcon,
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: Text(
                selectedAccount?.name ?? 'Seleziona conto',
                style: StreamTypography.bodyBold,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectorPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SelectorPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StreamRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StreamSpacing.md,
          vertical: StreamSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(StreamRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBubble(color: color.toARGB32(), iconData: icon, size: 18),
            const SizedBox(width: StreamSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: StreamTypography.micro.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  Text(value, style: StreamTypography.bodyBold),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final Key widgetKey;
  final String label;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.widgetKey,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Material(
      key: widgetKey,
      color: selected ? color.withValues(alpha: 0.22) : p.surfaceElevated,
      borderRadius: BorderRadius.circular(StreamRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(StreamRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StreamSpacing.md,
            vertical: StreamSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBubble(color: color.toARGB32(), iconData: icon, size: 18),
              const SizedBox(width: StreamSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: StreamTypography.bodyBold),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: StreamTypography.caption.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final int color;
  final String? iconKey;
  final IconData? iconData;
  final double size;

  const _IconBubble({
    required this.color,
    this.iconKey,
    this.iconData,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final icon =
        iconData ??
        StreamIconLibrary.getIcon(
          iconKey ?? StreamIconLibrary.defaultCategoryIcon,
        );
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Icon(
        icon,
        color: StreamSurfaceTokens.onAccent(Color(color)),
        size: size,
      ),
    );
  }
}
