import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_surface_tokens.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_icon_library.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/duplicate_date_selector.dart';
import '../widgets/grouped_movements_list.dart';
import '../widgets/icon_picker.dart';
import '../widgets/calculator_amount_pad.dart';
import '../widgets/movement_picker.dart';
import '../widgets/stream_kpi_card.dart';
import '../widgets/time_filter_bar.dart';
import '../utils/currency_formatter.dart';

class AccountsScreen extends StatefulWidget {
  final AppDatabase db;
  final String? activeProfileId;

  const AccountsScreen({super.key, required this.db, this.activeProfileId});

  static const _typeLabels = {
    AccountType.cash: 'Contante',
    AccountType.bank: 'Banca',
    AccountType.card: 'Carta',
    AccountType.savings: 'Risparmio',
    AccountType.other: 'Altro',
  };

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late TimeFilter _filter;
  Set<String>? _selectedCategoryFilterIds;
  bool _filtersSyncInProgress = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
    _loadScopedFilters();
  }

  @override
  void didUpdateWidget(covariant AccountsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfileId != widget.activeProfileId) {
      _loadScopedFilters();
    }
  }

  Future<void> _loadScopedFilters() async {
    final profileId = widget.activeProfileId?.trim();
    if (profileId == null || profileId.isEmpty) {
      if (mounted) {
        setState(() => _selectedCategoryFilterIds = null);
      }
      PreferencesService.accountsCategoryFilterIdsNotifier.value = null;
      return;
    }

    final categoryIds = await PreferencesService.loadAccountsCategoryFilterIds(
      profileId: profileId,
    );
    await _applySanitizedFilters(
      profileId: profileId,
      categoryIds: categoryIds,
    );
  }

  Future<void> _applySanitizedFilters({
    required String profileId,
    Set<String>? categoryIds,
  }) async {
    if (_filtersSyncInProgress) return;
    _filtersSyncInProgress = true;

    final activeCategoryIds = widget.db.categories
        .where((category) => !category.archived)
        .map((category) => category.id);
    final normalizedCategoryIds = PreferencesService.normalizeScopedFilterIds(
      categoryIds,
      activeCategoryIds,
    );

    try {
      if (!_sameIdSet(categoryIds, normalizedCategoryIds)) {
        await PreferencesService.saveAccountsCategoryFilterIds(
          normalizedCategoryIds,
          profileId: profileId,
        );
      }

      if (mounted) {
        setState(() => _selectedCategoryFilterIds = normalizedCategoryIds);
      }
    } finally {
      _filtersSyncInProgress = false;
    }
  }

  bool _sameIdSet(Set<String>? a, Set<String>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.isEmpty || b.isEmpty) return a.isEmpty && b.isEmpty;
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  List<Movement> _applyCategoryScopedFilters(List<Movement> movements) {
    if (_selectedCategoryFilterIds == null) {
      return movements;
    }

    return movements.where((movement) {
      if (movement.isTransfer) {
        return movement.categoryId.isNotEmpty &&
            _selectedCategoryFilterIds!.contains(movement.categoryId);
      }
      return _selectedCategoryFilterIds!.contains(movement.categoryId);
    }).toList();
  }

  String _categoryFilterLabel() {
    final activeCategories = widget.db.categories
        .where((category) => !category.archived)
        .toList();
    final selected = _selectedCategoryFilterIds == null
        ? <String>[]
        : activeCategories
              .where(
                (category) => _selectedCategoryFilterIds!.contains(category.id),
              )
              .map((category) => category.id)
              .toList();
    if (_selectedCategoryFilterIds == null ||
        selected.length == activeCategories.length) {
      return 'Tutte le categorie';
    }
    if (_selectedCategoryFilterIds!.isEmpty) return 'Nessuna categoria';
    if (selected.length == 1) {
      final name = activeCategories
          .firstWhere((category) => category.id == selected.first)
          .name;
      return name.length <= 20 ? name : '1 categoria selezionata';
    }
    return '${selected.length} categorie selezionate';
  }

  List<Category> _expenseCategories(List<Category> categories) =>
      categories.where((c) => c.type == MovementType.expense).toList();

  List<Category> _incomeCategories(List<Category> categories) =>
      categories.where((c) => c.type == MovementType.income).toList();

  Future<void> _showCategoryFilterSheet(BuildContext context) async {
    final profileId = widget.activeProfileId?.trim();
    if (profileId == null || profileId.isEmpty) return;
    final p = context.$palette;
    final activeCategories = widget.db.categories
        .where((category) => !category.archived)
        .toList();
    final expenseCategories = _expenseCategories(activeCategories);
    final incomeCategories = _incomeCategories(activeCategories);
    Set<String> workingIds = Set.from(
      _selectedCategoryFilterIds ??
          activeCategories.map((category) => category.id),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget buildCategoryOption(Category category) {
              final isSelected = workingIds.contains(category.id);
              return InkWell(
                key: Key('accounts_category_filter_option_${category.id}'),
                onTap: () {
                  setSheetState(() {
                    if (isSelected) {
                      workingIds.remove(category.id);
                    } else {
                      workingIds.add(category.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: p.primary,
                        size: 22,
                      ),
                      const SizedBox(width: StreamSpacing.md),
                      Expanded(
                        child: Text(
                          category.name,
                          style: StreamTypography.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: StreamSpacing.lg,
                  right: StreamSpacing.lg,
                  top: StreamSpacing.lg,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      StreamSpacing.lg,
                ),
                child: Column(
                  key: const Key('accounts_category_filter_sheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Categorie', style: StreamTypography.h3),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key('accounts_category_filter_all_option'),
                      onTap: () {
                        setSheetState(() {
                          if (workingIds.length == activeCategories.length) {
                            workingIds = <String>{};
                          } else {
                            workingIds = activeCategories
                                .map((category) => category.id)
                                .toSet();
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              workingIds.length == activeCategories.length
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: p.primary,
                              size: 22,
                            ),
                            const SizedBox(width: StreamSpacing.md),
                            Text(
                              'Tutte le categorie',
                              style: StreamTypography.bodyBold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.55,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (expenseCategories.isNotEmpty) ...[
                              const Padding(
                                key: Key(
                                  'accounts_category_filter_expense_section',
                                ),
                                padding: EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  'Uscite',
                                  style: StreamTypography.h3,
                                ),
                              ),
                              ...expenseCategories.map(buildCategoryOption),
                            ],
                            if (incomeCategories.isNotEmpty) ...[
                              const Padding(
                                key: Key(
                                  'accounts_category_filter_income_section',
                                ),
                                padding: EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(
                                  'Entrate',
                                  style: StreamTypography.h3,
                                ),
                              ),
                              ...incomeCategories.map(buildCategoryOption),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('accounts_category_filter_cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key('accounts_category_filter_apply'),
                            onPressed: () async {
                              final finalIds =
                                  workingIds.length == activeCategories.length
                                  ? null
                                  : workingIds;
                              await PreferencesService.saveAccountsCategoryFilterIds(
                                finalIds,
                                profileId: profileId,
                              );
                              await _applySanitizedFilters(
                                profileId: profileId,
                                categoryIds: finalIds,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Applica'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppCurrency>(
      valueListenable: PreferencesService.currencyNotifier,
      builder: (context, _, child) {
        final p = context.$palette;
        return Scaffold(
          backgroundColor: p.canvas,
          appBar: AppBar(title: const Text('Conti')),
          body: ListenableBuilder(
            listenable: widget.db,
            builder: (context, _) {
              final profileId = widget.activeProfileId?.trim();
              final hasProfileScope = profileId != null && profileId.isNotEmpty;
              if (!_filtersSyncInProgress && hasProfileScope) {
                final activeCategoryIds = widget.db.categories
                    .where((category) => !category.archived)
                    .map((category) => category.id)
                    .toSet();
                final categoryNeedsSanitize =
                    _selectedCategoryFilterIds != null &&
                    !_selectedCategoryFilterIds!.every(
                      activeCategoryIds.contains,
                    );
                if (categoryNeedsSanitize) {
                  Future.microtask(
                    () => _applySanitizedFilters(
                      profileId: profileId,
                      categoryIds: _selectedCategoryFilterIds,
                    ),
                  );
                }
              }

              final db = widget.db;
              final active = db.accounts.where((a) => !a.archived).toList();
              final archived = db.accounts.where((a) => a.archived).toList();
              final periodMovements = _applyCategoryScopedFilters(
                db.movements.filterByTime(_filter),
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  80,
                ),
                children: [
                  KeyedSubtree(
                    key: const Key('accounts_time_filter'),
                    child: TimeFilterBar(
                      activeFilter: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                  ),
                  const SizedBox(height: StreamSpacing.md),
                  if (hasProfileScope)
                    Padding(
                      key: const Key('accounts_filters_section'),
                      padding: const EdgeInsets.only(bottom: StreamSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtri',
                            style: StreamTypography.bodyBold.copyWith(
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: StreamSpacing.sm),
                          ActionChip(
                            key: const Key('accounts_category_filter_button'),
                            avatar: const Icon(Icons.category, size: 18),
                            label: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(
                                _categoryFilterLabel(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onPressed: () => _showCategoryFilterSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ...active.map(
                    (a) => _AccountCard(
                      key: Key('account_card_${a.id}'),
                      db: db,
                      account: a,
                      periodMovements: periodMovements,
                      allMovements: db.movements,
                      filter: _filter,
                      onTap: () => _showAccountMovements(
                        context,
                        db,
                        a,
                        selectedCategoryIds: _selectedCategoryFilterIds,
                      ),
                      onEdit: () => _showAddEditDialog(context, db, account: a),
                      onArchive: () => db.archiveAccount(a.id),
                      onRestore: () => db.restoreAccount(a.id),
                    ),
                  ),
                  if (archived.isNotEmpty) ...[
                    const SizedBox(height: StreamSpacing.section),
                    const KeyedSubtree(
                      key: Key('accounts_archived_section'),
                      child: _SectionHeader(title: 'Archiviati'),
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    ...archived.map(
                      (a) => _AccountCard(
                        key: Key('account_card_${a.id}'),
                        db: db,
                        account: a,
                        periodMovements: periodMovements,
                        allMovements: db.movements,
                        filter: _filter,
                        onTap: () => _showAccountMovements(
                          context,
                          db,
                          a,
                          selectedCategoryIds: _selectedCategoryFilterIds,
                        ),
                        onEdit: () =>
                            _showAddEditDialog(context, db, account: a),
                        onRestore: () => db.restoreAccount(a.id),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'accounts_fab',
            onPressed: () => _showAddEditDialog(context, widget.db),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAccountMovements(
    BuildContext context,
    AppDatabase db,
    Account account, {
    Set<String>? selectedCategoryIds,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AccountMovementsSheet(
        db: db,
        account: account,
        initialFilter: _filter,
        onEdit: () => _showAddEditDialog(context, db, account: account),
        selectedCategoryIds: selectedCategoryIds,
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    AppDatabase db, {
    Account? account,
  }) {
    final p = context.$palette;
    final nameController = TextEditingController(text: account?.name ?? '');
    final balanceController = TextEditingController(
      text: account?.initialBalance.toString() ?? '0',
    );
    AccountType selectedType = account?.type ?? AccountType.bank;
    int selectedColor = account?.color ?? StreamColorPalette.getDefault();
    String selectedIconKey =
        account?.iconKey ?? StreamIconLibrary.defaultAccountIcon;
    final currentMovementsDelta = account == null
        ? 0.0
        : db.getAccountBalance(account) - account.initialBalance;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(account == null ? 'Nuovo Conto' : 'Modifica Conto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: StreamSpacing.lg),
                DropdownButtonFormField<AccountType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(StreamRadius.md),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: p.surfaceElevated,
                  ),
                  items: AccountType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(_typeIcon(t), size: 20),
                              const SizedBox(width: 8),
                              Text(AccountsScreen._typeLabels[t]!),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: StreamSpacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bilancio',
                    style: StreamTypography.caption.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: StreamSpacing.sm),
                CalculatorAmountField(
                  fieldKey: const Key('account_initial_balance_field'),
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Saldo iniziale',
                  ),
                  allowNegative: true,
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: StreamSpacing.lg),
                Container(
                  key: const Key('account_current_balance_section'),
                  padding: const EdgeInsets.all(StreamSpacing.md),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(StreamRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo attuale',
                        style: StreamTypography.caption.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: StreamSpacing.xs),
                      Builder(
                        builder: (_) {
                          final parsedInitialBalance =
                              double.tryParse(
                                balanceController.text.replaceAll(',', '.'),
                              ) ??
                              0.0;
                          final currentBalance =
                              parsedInitialBalance + currentMovementsDelta;
                          return Text(
                            formatMovementCurrency(
                              currentBalance,
                              showPositiveSign: true,
                            ),
                            key: const Key('account_current_balance_value'),
                            style: StreamTypography.amount.copyWith(
                              color: currentBalance >= 0 ? p.income : p.expense,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: StreamSpacing.sm),
                      Text(
                        'Il saldo attuale viene calcolato automaticamente dai movimenti e dal saldo iniziale.',
                        key: const Key('account_balance_info_text'),
                        style: StreamTypography.caption.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StreamSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Icona',
                      style: StreamTypography.caption.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await showDialog<String>(
                          context: ctx,
                          builder: (_) => IconPickerDialog(
                            currentIconKey: selectedIconKey,
                            isAccount: true,
                          ),
                        );
                        if (result != null) {
                          setDialogState(() => selectedIconKey = result);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: p.surfaceElevated,
                          borderRadius: BorderRadius.circular(StreamRadius.md),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              StreamIconLibrary.getAccountIcon(selectedIconKey),
                              size: 20,
                              color: StreamSurfaceTokens.onAccent(
                                Color(selectedColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              StreamIconLibrary.getAccountLabel(
                                selectedIconKey,
                              ),
                              style: StreamTypography.caption,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: p.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.lg),
                Text(
                  'Colore',
                  style: StreamTypography.caption.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                const SizedBox(height: StreamSpacing.md),
                ColorPicker(
                  currentColor: selectedColor,
                  onChanged: (c) => setDialogState(() => selectedColor = c),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final balance =
                    double.tryParse(
                      balanceController.text.replaceAll(',', '.'),
                    ) ??
                    0;
                if (account == null) {
                  db.addAccount(
                    Account(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      type: selectedType,
                      initialBalance: balance,
                      iconKey: selectedIconKey,
                      color: selectedColor,
                      createdAt: DateTime.now(),
                    ),
                  );
                } else {
                  db.updateAccount(
                    account.id,
                    name,
                    selectedType,
                    balance,
                    iconKey: selectedIconKey,
                    color: selectedColor,
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(account == null ? 'Crea' : 'Salva'),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(AccountType t) {
    switch (t) {
      case AccountType.cash:
        return Icons.money;
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.card:
        return Icons.credit_card;
      case AccountType.savings:
        return Icons.savings;
      case AccountType.other:
        return Icons.account_balance_wallet;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Text(
      title,
      style: StreamTypography.h3.copyWith(color: p.textSecondary),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final AppDatabase db;
  final Account account;
  final List<Movement> periodMovements;
  final List<Movement> allMovements;
  final TimeFilter filter;

  const _AccountCard({
    super.key,
    required this.onTap,
    this.onEdit,
    this.onArchive,
    this.onRestore,
    required this.db,
    required this.account,
    required this.periodMovements,
    required this.allMovements,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final surface = StreamSurfaceTokens.card(p, muted: account.archived);
    final accountPeriodMovements = periodMovements
        .where(
          (m) =>
              m.accountId == account.id || m.destinationAccountId == account.id,
        )
        .toList();
    final periodIncome = sumIncome(
      accountPeriodMovements.where(
        (m) => m.isIncome && m.accountId == account.id,
      ),
    );
    final periodExpenses = sumExpenses(
      accountPeriodMovements.where(
        (m) => m.isExpense && m.accountId == account.id,
      ),
    );
    final periodTransfersNet = periodTransferNetForAccount(
      account.id,
      accountPeriodMovements,
    );
    final periodStartBalance = balanceForAccountBefore(
      account.id,
      allMovements,
      filter.startDate,
      initialBalance: account.initialBalance,
    );
    final periodEndBalance = balanceForAccountUntil(
      account.id,
      allMovements,
      filter.endDate,
      initialBalance: account.initialBalance,
    );
    final iconData = StreamIconLibrary.getAccountIcon(account.iconKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StreamRadius.md),
          child: Container(
            padding: const EdgeInsets.all(StreamSpacing.lg),
            decoration: BoxDecoration(
              color: surface.background,
              borderRadius: BorderRadius.circular(StreamRadius.md),
              border: Border.all(
                color: surface.border,
                width: surface.borderWidth,
              ),
              boxShadow: surface.shadows,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: account.archived
                            ? Color(account.color).withValues(alpha: 0.3)
                            : Color(account.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(StreamRadius.md),
                      ),
                      child: Icon(
                        iconData,
                        color: account.archived
                            ? p.textMuted
                            : StreamSurfaceTokens.onAccent(
                                Color(account.color).withValues(alpha: 0.92),
                              ),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: account.archived
                                ? StreamTypography.bodyBold.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: p.textSecondary,
                                  )
                                : StreamTypography.bodyBold,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AccountsScreen._typeLabels[account.type] ?? '',
                            style: StreamTypography.caption.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 104),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatMoney(periodEndBalance),
                            key: const Key('account_current_balance'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StreamTypography.amount.copyWith(
                              color: periodEndBalance >= 0
                                  ? p.income
                                  : p.expense,
                            ),
                          ),
                          Text(
                            _balanceLabel(filter),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StreamTypography.micro.copyWith(
                              color: p.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                onEdit?.call();
                              } else if (v == 'archive') {
                                onArchive?.call();
                              } else if (v == 'restore') {
                                onRestore?.call();
                              }
                            },
                            icon: Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: p.textMuted,
                            ),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifica'),
                              ),
                              if (!account.archived)
                                const PopupMenuItem(
                                  value: 'archive',
                                  child: Text('Archivia'),
                                ),
                              if (account.archived)
                                const PopupMenuItem(
                                  value: 'restore',
                                  child: Text('Ripristina'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: StreamSpacing.md),
                _AccountPeriodSummary(
                  income: periodIncome,
                  expenses: periodExpenses,
                  transfersNet: periodTransfersNet,
                  startBalance: periodStartBalance,
                  endBalance: periodEndBalance,
                  movementCount: accountPeriodMovements.length,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return formatMovementCurrency(value, showPositiveSign: true);
  }

  String _balanceLabel(TimeFilter filter) {
    return 'Saldo al ${_formatDate(filter.endDate)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _AccountPeriodSummary extends StatelessWidget {
  final double income;
  final double expenses;
  final double transfersNet;
  final double startBalance;
  final double endBalance;
  final int movementCount;

  const _AccountPeriodSummary({
    required this.income,
    required this.expenses,
    required this.transfersNet,
    required this.startBalance,
    required this.endBalance,
    required this.movementCount,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Wrap(
      key: const Key('accounts_hero_kpi'),
      spacing: StreamSpacing.sm,
      runSpacing: StreamSpacing.sm,
      children: [
        _PeriodMetric(
          key: const Key('account_period_income'),
          label: 'Entrate',
          value: _formatMoney(income),
          semanticType: StreamKpiSemanticType.income,
          accentColor: p.income,
        ),
        _PeriodMetric(
          key: const Key('account_period_expense'),
          label: 'Uscite',
          value: _formatMoney(expenses),
          semanticType: StreamKpiSemanticType.expense,
          accentColor: p.expense,
        ),
        _PeriodMetric(
          key: const Key('account_period_transfer_net'),
          label: 'Trasf.',
          value: _formatMoney(transfersNet),
          semanticType: StreamKpiSemanticType.neutral,
          accentColor: transfersNet >= 0 ? p.income : p.expense,
        ),
        _PeriodMetric(
          key: const Key('account_period_movement_count'),
          label: 'Movimenti',
          value: '$movementCount',
          semanticType: StreamKpiSemanticType.count,
          accentColor: p.textPrimary,
        ),
        _PeriodMetric(
          key: const Key('account_period_start_balance'),
          label: 'Saldo ini.',
          value: _formatMoney(startBalance),
          semanticType: StreamKpiSemanticType.balance,
          accentColor: startBalance >= 0 ? p.income : p.expense,
        ),
        _PeriodMetric(
          key: const Key('account_period_end_balance'),
          label: 'Saldo fine',
          value: _formatMoney(endBalance),
          semanticType: StreamKpiSemanticType.balance,
          accentColor: endBalance >= 0 ? p.income : p.expense,
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    return formatMovementCurrency(value, showPositiveSign: true);
  }
}

class _PeriodMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final StreamKpiSemanticType semanticType;

  const _PeriodMetric({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.semanticType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamKpiCard(
      title: label,
      value: value,
      semanticType: semanticType,
      accentColor: accentColor,
      density: StreamKpiDensity.tight,
      layout: StreamKpiLayout.stacked,
      width: 96,
      uppercaseTitle: false,
    );
  }
}

class _AccountMovementsSheet extends StatefulWidget {
  final AppDatabase db;
  final Account account;
  final TimeFilter? initialFilter;
  final VoidCallback onEdit;
  final Set<String>? selectedCategoryIds;

  const _AccountMovementsSheet({
    required this.db,
    required this.account,
    required this.onEdit,
    this.initialFilter,
    this.selectedCategoryIds,
  });

  @override
  State<_AccountMovementsSheet> createState() => _AccountMovementsSheetState();
}

class _AccountMovementsSheetState extends State<_AccountMovementsSheet> {
  late TimeFilter _filter;
  bool? _detailsExpandedOverride;

  Account get _account {
    return widget.db.accounts.firstWhere(
      (a) => a.id == widget.account.id,
      orElse: () => widget.account,
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = widget.initialFilter ?? TimeFilter.month(now.year, now.month);
  }

  List<Movement> get _accountMovements {
    final account = _account;
    return widget.db.movements
        .where(
          (m) =>
              m.accountId == account.id || m.destinationAccountId == account.id,
        )
        .where((movement) {
          if (widget.selectedCategoryIds == null) {
            return true;
          }
          if (movement.isTransfer) {
            return movement.categoryId.isNotEmpty &&
                widget.selectedCategoryIds!.contains(movement.categoryId);
          }
          return widget.selectedCategoryIds!.contains(movement.categoryId);
        })
        .toList()
        .filterByTime(_filter);
  }

  double get _filteredIncome => sumIncome(
    _accountMovements.where((m) => m.isIncome && m.accountId == _account.id),
  );

  double get _filteredExpenses => sumExpenses(
    _accountMovements.where((m) => m.isExpense && m.accountId == _account.id),
  );

  double get _filteredTransfersNet =>
      periodTransferNetForAccount(_account.id, _accountMovements);

  void _showAddMovement({MovementType initialType = MovementType.expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MovementPicker(
        db: widget.db,
        accountPreFill: _account.id,
        initialType: initialType,
      ),
    );
  }

  Future<void> _archiveAccount() async {
    if (_account.archived) return;
    await widget.db.archiveAccount(_account.id);
    if (mounted) setState(() {});
  }

  Future<void> _restoreAccount() async {
    if (!_account.archived) return;
    await widget.db.restoreAccount(_account.id);
    if (mounted) setState(() {});
  }

  void _toggleDetails() {
    final shouldExpand = _detailsExpandedOverride ?? _accountMovements.isEmpty;
    setState(() => _detailsExpandedOverride = !shouldExpand);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return ListenableBuilder(
      listenable: widget.db,
      builder: (context, _) {
        final account = _account;
        final movements = _accountMovements;
        final periodStartBalance = balanceForAccountBefore(
          account.id,
          widget.db.movements,
          _filter.startDate,
          initialBalance: account.initialBalance,
        );
        final periodEndBalance = balanceForAccountUntil(
          account.id,
          widget.db.movements,
          _filter.endDate,
          initialBalance: account.initialBalance,
        );
        final hasMovements = movements.isNotEmpty;
        final detailsExpanded = _detailsExpandedOverride ?? !hasMovements;

        return FractionallySizedBox(
          heightFactor: 1.0,
          child: KeyedSubtree(
            key: const Key('account_detail_sheet'),
            child: Padding(
              key: const Key('account_interactive_sheet'),
              padding: const EdgeInsets.fromLTRB(
                StreamSpacing.lg,
                StreamSpacing.lg,
                StreamSpacing.lg,
                StreamSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          KeyedSubtree(
                            key: const Key('account_sheet_header'),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Color(
                                      account.color,
                                    ).withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    StreamIconLibrary.getAccountIcon(
                                      account.iconKey,
                                    ),
                                    color: StreamSurfaceTokens.onAccent(
                                      Color(
                                        account.color,
                                      ).withValues(alpha: 0.92),
                                    ),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: StreamSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Movimenti del conto',
                                        style: StreamTypography.captionBold
                                            .copyWith(color: p.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        account.name,
                                        key: const Key(
                                          'account_movements_name',
                                        ),
                                        style: StreamTypography.h2,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        account.archived
                                            ? 'Archiviato'
                                            : 'Attivo',
                                        style: StreamTypography.caption
                                            .copyWith(color: p.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: const Key(
                                    'account_movements_close_button',
                                  ),
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: StreamSpacing.md),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final buttonWidth =
                                  (constraints.maxWidth - StreamSpacing.sm) / 2;
                              return KeyedSubtree(
                                key: const Key('account_detail_actions'),
                                child: Wrap(
                                  spacing: StreamSpacing.sm,
                                  runSpacing: StreamSpacing.sm,
                                  children: [
                                    SizedBox(
                                      width: buttonWidth,
                                      child: _SheetActionButton(
                                        key: const Key(
                                          'account_sheet_add_movement_action',
                                        ),
                                        icon: Icons.add,
                                        label: 'Movimento',
                                        prominence: _ActionProminence.primary,
                                        onPressed: () => _showAddMovement(),
                                      ),
                                    ),
                                    SizedBox(
                                      width: buttonWidth,
                                      child: _SheetActionButton(
                                        key: const Key(
                                          'account_sheet_transfer_action',
                                        ),
                                        icon: Icons.compare_arrows,
                                        label: 'Trasferisci',
                                        prominence: _ActionProminence.secondary,
                                        onPressed: () => _showAddMovement(
                                          initialType: MovementType.transfer,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: buttonWidth,
                                      child: _SheetActionButton(
                                        key: const Key(
                                          'account_sheet_edit_action',
                                        ),
                                        icon: Icons.edit,
                                        label: 'Modifica',
                                        prominence: _ActionProminence.tertiary,
                                        onPressed: widget.onEdit,
                                      ),
                                    ),
                                    SizedBox(
                                      width: buttonWidth,
                                      child: !account.archived
                                          ? _SheetActionButton(
                                              key: const Key(
                                                'account_sheet_archive_action',
                                              ),
                                              icon: Icons.archive_outlined,
                                              label: 'Archivia',
                                              prominence:
                                                  _ActionProminence.tertiary,
                                              onPressed: _archiveAccount,
                                            )
                                          : _SheetActionButton(
                                              key: const Key(
                                                'account_sheet_restore_action',
                                              ),
                                              icon: Icons.unarchive_outlined,
                                              label: 'Ripristina',
                                              prominence:
                                                  _ActionProminence.tertiary,
                                              onPressed: _restoreAccount,
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: StreamSpacing.md),
                          KeyedSubtree(
                            key: const Key('account_detail_period_filter'),
                            child: KeyedSubtree(
                              key: const Key('account_movements_time_filter'),
                              child: TimeFilterBar(
                                activeFilter: _filter,
                                onChanged: (value) =>
                                    setState(() => _filter = value),
                              ),
                            ),
                          ),
                          const SizedBox(height: StreamSpacing.sm),
                          KeyedSubtree(
                            key: const Key('account_detail_compact_summary'),
                            child: _CompactAccountSummary(
                              income: _filteredIncome,
                              expenses: _filteredExpenses,
                              balance:
                                  _filteredIncome -
                                  _filteredExpenses +
                                  _filteredTransfersNet,
                            ),
                          ),
                          const SizedBox(height: StreamSpacing.xs),
                          KeyedSubtree(
                            key: const Key('account_sheet_period_summary'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  key: const Key(
                                    'account_detail_summary_toggle',
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    StreamRadius.md,
                                  ),
                                  onTap: _toggleDetails,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: StreamSpacing.xs,
                                      vertical: StreamSpacing.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          detailsExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 18,
                                          color: p.textSecondary,
                                        ),
                                        const SizedBox(width: StreamSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            'Riepilogo dettagliato',
                                            style: StreamTypography.captionBold
                                                .copyWith(
                                                  color: p.textSecondary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  alignment: Alignment.topCenter,
                                  child: detailsExpanded
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            top: StreamSpacing.xs,
                                          ),
                                          child: Wrap(
                                            key: const Key(
                                              'account_detail_summary_grid',
                                            ),
                                            spacing: StreamSpacing.sm,
                                            runSpacing: StreamSpacing.sm,
                                            children: [
                                              KeyedSubtree(
                                                key: const Key(
                                                  'account_movements_current_balance',
                                                ),
                                                child: _StatChip(
                                                  label: _balanceLabel(_filter),
                                                  value: _formatMoney(
                                                    periodEndBalance,
                                                  ),
                                                  key: const Key(
                                                    'account_sheet_balance_as_of',
                                                  ),
                                                ),
                                              ),
                                              _StatChip(
                                                label: 'Saldo iniziale',
                                                value: _formatMoney(
                                                  account.initialBalance,
                                                ),
                                                key: const Key(
                                                  'account_movements_initial_balance',
                                                ),
                                              ),
                                              KeyedSubtree(
                                                key: const Key(
                                                  'account_movements_income',
                                                ),
                                                child: _StatChip(
                                                  label: 'Entrate periodo',
                                                  value: _formatMoney(
                                                    _filteredIncome,
                                                  ),
                                                  key: const Key(
                                                    'account_sheet_income',
                                                  ),
                                                ),
                                              ),
                                              KeyedSubtree(
                                                key: const Key(
                                                  'account_movements_expenses',
                                                ),
                                                child: _StatChip(
                                                  label: 'Uscite periodo',
                                                  value: _formatMoney(
                                                    _filteredExpenses,
                                                  ),
                                                  key: const Key(
                                                    'account_sheet_expense',
                                                  ),
                                                ),
                                              ),
                                              KeyedSubtree(
                                                key: const Key(
                                                  'account_movements_transfers',
                                                ),
                                                child: _StatChip(
                                                  label: 'Trasferimenti netti',
                                                  value: _formatMoney(
                                                    _filteredTransfersNet,
                                                  ),
                                                  key: const Key(
                                                    'account_sheet_transfer_net',
                                                  ),
                                                ),
                                              ),
                                              _StatChip(
                                                label: 'Saldo inizio periodo',
                                                value: _formatMoney(
                                                  periodStartBalance,
                                                ),
                                                key: const Key(
                                                  'account_movements_start_balance',
                                                ),
                                              ),
                                              KeyedSubtree(
                                                key: const Key(
                                                  'account_movements_count',
                                                ),
                                                child: _StatChip(
                                                  label: 'Movimenti',
                                                  value: '${movements.length}',
                                                  key: const Key(
                                                    'account_sheet_movement_count',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: StreamSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    key: const Key('account_detail_movements_list'),
                    child: hasMovements
                        ? KeyedSubtree(
                            key: const Key('account_sheet_movements_list'),
                            child: GroupedMovementsList(
                              movements: movements,
                              db: widget.db,
                              showNotes: true,
                              onEdit: (m) => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    MovementPicker(db: widget.db, prefill: m),
                              ),
                              onDuplicate: (m) async {
                                final date = await showDuplicateDateSheet(
                                  context,
                                );
                                if (date != null) {
                                  widget.db.duplicateMovement(m, date: date);
                                }
                              },
                              onSaveAsFavorite: (m) =>
                                  widget.db.saveMovementAsFavorite(m),
                              onAddQuick: (m) =>
                                  widget.db.saveMovementAsQuick(m),
                              onDelete: (m) => widget.db.deleteMovement(m.id),
                            ),
                          )
                        : KeyedSubtree(
                            key: const Key('account_sheet_movements_list'),
                            child: _AccountMovementsEmptyState(
                              onAddMovement: () => _showAddMovement(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMoney(double value) {
    return formatMovementCurrency(value, showPositiveSign: true);
  }

  String _balanceLabel(TimeFilter filter) {
    return 'Saldo al ${_formatDate(filter.endDate)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

enum _ActionProminence { primary, secondary, tertiary }

class _SheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final _ActionProminence prominence;

  const _SheetActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominence = _ActionProminence.primary,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(StreamRadius.md),
    );

    switch (prominence) {
      case _ActionProminence.primary:
        return FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: shape,
          ),
        );
      case _ActionProminence.secondary:
        return FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: shape,
          ),
        );
      case _ActionProminence.tertiary:
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: shape,
            foregroundColor: p.textPrimary,
            side: BorderSide(color: p.divider),
          ),
        );
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return StreamKpiCard(
      title: label,
      value: value,
      semanticType: StreamKpiSemanticType.neutral,
      density: StreamKpiDensity.compact,
      layout: StreamKpiLayout.stacked,
      width: 160,
      uppercaseTitle: false,
    );
  }
}

class _CompactAccountSummary extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;

  const _CompactAccountSummary({
    required this.income,
    required this.expenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final surface = StreamSurfaceTokens.card(p, muted: true);
    final balanceColor = balance >= 0 ? p.income : p.expense;

    return Container(
      key: const Key('account_detail_hero_kpi'),
      decoration: BoxDecoration(
        color: surface.background,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: Border.all(color: surface.border, width: surface.borderWidth),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: StreamSpacing.md,
        vertical: StreamSpacing.sm,
      ),
      child: Wrap(
        spacing: StreamSpacing.md,
        runSpacing: StreamSpacing.xs,
        children: [
          _CompactSummaryItem(
            label: 'Entrate',
            value: formatMovementCurrency(income),
            color: p.income,
          ),
          _CompactSummaryItem(
            label: 'Uscite',
            value: formatMovementCurrency(expenses),
            color: p.expense,
          ),
          _CompactSummaryItem(
            label: 'Saldo',
            value: formatMovementCurrency(balance, showPositiveSign: true),
            color: balanceColor,
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompactSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return RichText(
      text: TextSpan(
        style: StreamTypography.caption.copyWith(color: p.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: StreamTypography.captionBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _AccountMovementsEmptyState extends StatelessWidget {
  final VoidCallback onAddMovement;

  const _AccountMovementsEmptyState({required this.onAddMovement});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: p.textMuted),
            const SizedBox(height: StreamSpacing.md),
            Text(
              'Nessun movimento in questo periodo',
              style: StreamTypography.bodyBold.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StreamSpacing.xs),
            Text(
              'Puoi cambiare periodo oppure aggiungere subito un nuovo movimento.',
              style: StreamTypography.caption.copyWith(color: p.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: StreamSpacing.md),
            FilledButton.icon(
              onPressed: onAddMovement,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi movimento'),
            ),
          ],
        ),
      ),
    );
  }
}
