import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../design/stream_kpi_style.dart';
import '../design/stream_theme_extension.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/duplicate_date_selector.dart';
import '../utils/currency_formatter.dart';
import '../utils/filter_ux_copy.dart';
import '../widgets/movement_picker.dart';
import '../widgets/grouped_movements_list.dart';
import '../widgets/stream_kpi_card.dart';
import '../widgets/time_filter_bar.dart';

class DashboardScreen extends StatefulWidget {
  final AppDatabase db;
  final String? activeProfileId;
  final DateTime Function()? timeFilterNowProvider;

  const DashboardScreen({
    super.key,
    required this.db,
    this.activeProfileId,
    this.timeFilterNowProvider,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TimeFilter _filter;
  Set<String>? _selectedAccountIds;
  bool _selectionSyncInProgress = false;

  @override
  void initState() {
    super.initState();
    final now = _now();
    _filter = TimeFilter.month(now.year, now.month);
    _loadAccountSelection();
  }

  DateTime _now() => widget.timeFilterNowProvider?.call() ?? DateTime.now();

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProfileId != widget.activeProfileId) {
      setState(() => _selectedAccountIds = null);
      _loadAccountSelection();
    }
  }

  Future<void> _loadAccountSelection() async {
    final ids = await PreferencesService.loadDashboardNetWorthAccountIds(
      profileId: widget.activeProfileId,
    );
    if (mounted) {
      setState(() => _selectedAccountIds = ids);
    }
  }

  List<Account> _getFilteredAccounts(List<Account> activeAccounts) {
    if (_selectedAccountIds == null) {
      return activeAccounts;
    }
    if (_selectedAccountIds!.isEmpty) return [];
    return activeAccounts
        .where((a) => _selectedAccountIds!.contains(a.id))
        .toList();
  }

  Future<void> _syncAccountSelection(List<Account> activeAccounts) async {
    if (_selectionSyncInProgress) return;
    final current = _selectedAccountIds;
    if (current == null) return;

    final validIds = activeAccounts.map((account) => account.id).toSet();
    final sanitized = current.intersection(validIds);
    final shouldClear = sanitized.length == activeAccounts.length;
    final nextSelection = shouldClear ? null : sanitized;

    if (setEquals(current, nextSelection)) return;

    _selectionSyncInProgress = true;
    try {
      if (nextSelection == null) {
        await PreferencesService.clearDashboardNetWorthAccountSelection(
          profileId: widget.activeProfileId,
        );
      } else {
        await PreferencesService.saveDashboardNetWorthAccountIds(
          nextSelection,
          profileId: widget.activeProfileId,
        );
      }
      if (mounted) {
        setState(() => _selectedAccountIds = nextSelection);
      }
    } finally {
      _selectionSyncInProgress = false;
    }
  }

  void _onFilterChanged(TimeFilter filter) {
    setState(() {
      _filter = filter;
    });
  }

  void _showCategoryDetail(
    BuildContext context,
    _CategoryExpense item,
    List<Movement> allFilteredMovements,
  ) {
    final categoryMovements = allFilteredMovements
        .where((m) => m.categoryId == item.categoryId)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryDetailSheet(
        item: item,
        movements: categoryMovements,
        db: widget.db,
        filter: _filter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppCurrency>(
      valueListenable: PreferencesService.currencyNotifier,
      builder: (context, _, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('STREAM')),
          body: ListenableBuilder(
            listenable: widget.db,
            builder: (context, _) {
              final allMovements = widget.db.movements;
              final filteredMovements = allMovements.filterByTime(_filter);
              final previousFilter = _filter.mode == TimeFilterMode.customRange
                  ? null
                  : _filter.previous();
              final previousMovements = previousFilter != null
                  ? allMovements.filterByTime(previousFilter)
                  : <Movement>[];

              final filteredIncome = sumIncome(filteredMovements);
              final filteredExpenses = sumExpenses(filteredMovements);
              final previousExpenses = sumExpenses(previousMovements);
              final filteredBalance = netIncomeExpense(filteredMovements);
              final filteredCount = filteredMovements.length;
              final activeAccounts = widget.db.accounts
                  .where((a) => !a.archived)
                  .toList();
              unawaited(_syncAccountSelection(activeAccounts));
              final selectedAccounts = _getFilteredAccounts(activeAccounts);
              final accountsBalance = selectedAccounts.fold<double>(
                0.0,
                (sum, a) => sum + widget.db.getAccountBalance(a),
              );
              final categoryExpenses = _buildCategoryExpenses(
                filteredMovements,
                widget.db.categories,
              );
              final expenseComparison = previousFilter != null
                  ? filteredExpenses - previousExpenses
                  : null;

              return SingleChildScrollView(
                key: const Key('dashboard_scroll_view'),
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  StreamSpacing.xxl,
                ),
                child: Column(
                  children: [
                    TimeFilterBar(
                      activeFilter: _filter,
                      onChanged: _onFilterChanged,
                      nowProvider: widget.timeFilterNowProvider,
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    _BalanceHero(
                      accountsBalance: accountsBalance,
                      accounts: selectedAccounts,
                      allAccounts: activeAccounts,
                      selectedAccountIds: _selectedAccountIds,
                      activeProfileId: widget.activeProfileId,
                      db: widget.db,
                      onAccountSelectionChanged: (ids) {
                        setState(() => _selectedAccountIds = ids);
                      },
                    ),
                    const SizedBox(height: StreamSpacing.lg),
                    _KpiGrid(
                      income: filteredIncome,
                      expenses: filteredExpenses,
                      balance: filteredBalance,
                      count: filteredCount,
                      expenseComparison: expenseComparison,
                    ),
                    const SizedBox(height: StreamSpacing.section),
                    _CategoryExpensesSection(
                      items: categoryExpenses,
                      totalExpenses: filteredExpenses,
                      db: widget.db,
                      onCategoryTap: (item) =>
                          _showCategoryDetail(context, item, filteredMovements),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final double accountsBalance;
  final List<Account> accounts;
  final List<Account> allAccounts;
  final Set<String>? selectedAccountIds;
  final String? activeProfileId;
  final AppDatabase db;
  final ValueChanged<Set<String>?> onAccountSelectionChanged;

  const _BalanceHero({
    required this.accountsBalance,
    required this.accounts,
    required this.allAccounts,
    required this.selectedAccountIds,
    required this.activeProfileId,
    required this.db,
    required this.onAccountSelectionChanged,
  });

  String _selectionLabel() {
    final validSelectedCount = accounts.length;
    final activeCount = allAccounts.length;

    if (selectedAccountIds == null || validSelectedCount == activeCount) {
      return 'Tutti i conti';
    }
    if (selectedAccountIds!.isEmpty) return 'Nessun conto';
    if (validSelectedCount == 1) {
      final name = accounts.first.name;
      return name.length <= 20 ? name : '1 conto selezionato';
    }
    return '$validSelectedCount conti selezionati';
  }

  void _showAccountFilterSheet(BuildContext context) {
    final p = context.$palette;
    final activeAccounts = allAccounts;
    Set<String> workingIds = Set.from(
      selectedAccountIds ?? activeAccounts.map((a) => a.id),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Conti', style: StreamTypography.h3),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: StreamSpacing.xs),
                    Text(
                      FilterUxCopy.accountToggleHint,
                      style: StreamTypography.caption.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.md),
                    InkWell(
                      key: const Key('dashboard_net_worth_all_accounts_option'),
                      onTap: () {
                        setSheetState(() {
                          if (workingIds.length == activeAccounts.length) {
                            workingIds = <String>{};
                          } else {
                            workingIds = activeAccounts
                                .map((a) => a.id)
                                .toSet();
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              workingIds.length == activeAccounts.length
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: p.primary,
                              size: 22,
                            ),
                            const SizedBox(width: StreamSpacing.md),
                            Text(
                              'Tutti i conti',
                              style: StreamTypography.bodyBold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: activeAccounts.map((account) {
                            final isSelected = workingIds.contains(account.id);
                            return InkWell(
                              key: Key(
                                'dashboard_net_worth_account_option_${account.id}',
                              ),
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    workingIds.remove(account.id);
                                  } else {
                                    workingIds.add(account.id);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                                    Icon(
                                      StreamIconLibrary.getAccountIcon(
                                        account.iconKey,
                                      ),
                                      size: 18,
                                      color: Color(account.color),
                                    ),
                                    const SizedBox(width: StreamSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        account.name,
                                        style: StreamTypography.bodyBold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      formatMovementCurrency(
                                        db.getAccountBalance(account),
                                        showPositiveSign: true,
                                      ),
                                      style: StreamTypography.captionBold
                                          .copyWith(color: p.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: StreamSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key(
                              'dashboard_net_worth_account_filter_cancel',
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annulla'),
                          ),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: FilledButton(
                            key: const Key(
                              'dashboard_net_worth_account_filter_apply',
                            ),
                            onPressed: () {
                              final finalIds =
                                  workingIds.length == activeAccounts.length
                                  ? null
                                  : workingIds;
                              onAccountSelectionChanged(finalIds);
                              unawaited(
                                PreferencesService.saveDashboardNetWorthAccountIds(
                                  finalIds,
                                  profileId: activeProfileId,
                                ),
                              );
                              Navigator.of(context).pop();
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
    final p = context.$palette;
    final kpiStyle = StreamKpiStyleId.fromString(
      PreferencesService.kpiStyleNotifier.value,
    );
    final effectiveStyle = resolveEffectiveKpiStyle(p, kpiStyle);
    final valueColor = accountsBalance >= 0 ? p.income : p.expense;
    final isDense = effectiveStyle == StreamKpiStyleId.dense;

    final chrome = resolveKpiChrome(
      p,
      valueColor,
      kpiStyle,
      StreamKpiDensity.regular,
      StreamKpiEmphasis.hero,
    );

    Widget content;
    if (isDense) {
      content = Row(
        key: const Key('dashboard_hero_kpi_style_dense'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(child: _HeroHeading()),
          const SizedBox(width: StreamSpacing.md),
          Flexible(
            child: Text(
              formatMovementCurrency(accountsBalance, showPositiveSign: true),
              key: const Key('dashboard_hero_networth_value'),
              textAlign: TextAlign.right,
              style: chrome.valueStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else if (effectiveStyle == StreamKpiStyleId.split) {
      content = _HeroSplit(
        accounts: accounts,
        db: db,
        valueStyle: chrome.valueStyle,
        accountsBalance: accountsBalance,
      );
    } else {
      content = _HeroStacked(
        accounts: accounts,
        db: db,
        valueStyle: chrome.valueStyle,
        accountsBalance: accountsBalance,
        forcePrimaryForeground: chrome.backgroundColor.computeLuminance() < 0.3,
      );
    }

    return AnimatedContainer(
      key: const Key('dashboard_hero_networth_card'),
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: chrome.padding,
      decoration: BoxDecoration(
        color: chrome.backgroundColor,
        gradient: chrome.gradient,
        borderRadius: BorderRadius.circular(chrome.radius),
        border: chrome.border,
        boxShadow: chrome.shadows.isEmpty ? null : chrome.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Patrimonio netto', style: chrome.titleStyle),
              ),
              GestureDetector(
                key: const Key('dashboard_net_worth_account_filter_button'),
                onTap: () => _showAccountFilterSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StreamSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(StreamRadius.full),
                    border: Border.all(color: p.divider.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 12, color: p.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _selectionLabel(),
                          style: StreamTypography.micro.copyWith(
                            color: p.textSecondary,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: chrome.valueSpacing),
          content,
        ],
      ),
    );
  }
}

class _HeroHeading extends StatelessWidget {
  const _HeroHeading();

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Text(
      'Situazione attuale, non filtrata dal periodo',
      style: StreamTypography.caption.copyWith(color: p.textMuted),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _HeroStacked extends StatelessWidget {
  final List<Account> accounts;
  final AppDatabase db;
  final TextStyle valueStyle;
  final double accountsBalance;
  final bool forcePrimaryForeground;

  const _HeroStacked({
    required this.accounts,
    required this.db,
    required this.valueStyle,
    required this.accountsBalance,
    this.forcePrimaryForeground = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final subtitleColor = forcePrimaryForeground
        ? p.textPrimary.withValues(alpha: 0.78)
        : p.textSecondary;

    const maxPills = 3;
    final activeAccounts = accounts.where((a) => !a.archived).toList();
    final visible = activeAccounts.take(maxPills).toList();
    final extraCount = activeAccounts.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatMovementCurrency(accountsBalance, showPositiveSign: true),
          key: const Key('dashboard_hero_networth_value'),
          style: valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: StreamSpacing.sm),
        Text(
          'Situazione attuale, non filtrata dal periodo',
          style: StreamTypography.caption.copyWith(color: subtitleColor),
        ),
        if (activeAccounts.isEmpty && accounts.isEmpty) ...[
          const SizedBox(height: StreamSpacing.sm),
          Text(
            FilterUxCopy.noAccountSelectedTitle,
            style: StreamTypography.captionBold.copyWith(color: subtitleColor),
          ),
          const SizedBox(height: StreamSpacing.xs),
          Text(
            'Il patrimonio resta a zero finché non selezioni almeno un conto.',
            style: StreamTypography.micro.copyWith(color: subtitleColor),
          ),
        ],
        if (visible.isNotEmpty) ...[
          const SizedBox(height: StreamSpacing.md),
          Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.sm,
            children: [
              ...visible.map(
                (account) => _AccountBalancePill(
                  account: account,
                  balance: db.getAccountBalance(account),
                  emphasis: forcePrimaryForeground,
                ),
              ),
              if (extraCount > 0)
                Container(
                  key: const Key('dashboard_hero_more_accounts'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: forcePrimaryForeground
                        ? p.textPrimary.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$extraCount altri',
                    style: TextStyle(
                      fontSize: 11,
                      color: forcePrimaryForeground
                          ? p.textPrimary
                          : p.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeroSplit extends StatelessWidget {
  final List<Account> accounts;
  final AppDatabase db;
  final TextStyle valueStyle;
  final double accountsBalance;

  const _HeroSplit({
    required this.accounts,
    required this.db,
    required this.valueStyle,
    required this.accountsBalance,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    const maxPills = 3;
    final activeAccounts = accounts.where((a) => !a.archived).toList();
    final visible = activeAccounts.take(maxPills).toList();
    final extraCount = activeAccounts.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _HeroHeading()),
            const SizedBox(width: StreamSpacing.md),
            Icon(Icons.account_balance_wallet_outlined, color: p.primary),
          ],
        ),
        const SizedBox(height: StreamSpacing.md),
        Text(
          formatMovementCurrency(accountsBalance, showPositiveSign: true),
          key: const Key('dashboard_hero_networth_value'),
          style: valueStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (activeAccounts.isEmpty && accounts.isEmpty) ...[
          const SizedBox(height: StreamSpacing.sm),
          Text(
            FilterUxCopy.noAccountSelectedTitle,
            style: StreamTypography.captionBold.copyWith(
              color: p.textSecondary,
            ),
          ),
          const SizedBox(height: StreamSpacing.xs),
          Text(
            'Il patrimonio resta a zero finché non selezioni almeno un conto.',
            style: StreamTypography.micro.copyWith(color: p.textSecondary),
          ),
        ],
        if (visible.isNotEmpty) ...[
          const SizedBox(height: StreamSpacing.md),
          Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.sm,
            children: [
              ...visible.map(
                (account) => _AccountBalancePill(
                  account: account,
                  balance: db.getAccountBalance(account),
                ),
              ),
              if (extraCount > 0)
                Container(
                  key: const Key('dashboard_hero_more_accounts'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$extraCount altri',
                    style: TextStyle(fontSize: 11, color: p.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AccountBalancePill extends StatelessWidget {
  final Account account;
  final double balance;
  final bool emphasis;

  const _AccountBalancePill({
    required this.account,
    required this.balance,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final width = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width * 0.82),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StreamSpacing.sm,
          vertical: StreamSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: emphasis
              ? p.textPrimary.withValues(alpha: 0.12)
              : p.surfaceElevated,
          borderRadius: BorderRadius.circular(StreamRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              StreamIconLibrary.getAccountIcon(account.iconKey),
              size: 14,
              color: Color(account.color),
            ),
            const SizedBox(width: StreamSpacing.xs),
            Flexible(
              child: Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StreamTypography.caption.copyWith(
                  color: emphasis ? p.textPrimary : p.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: StreamSpacing.xs),
            Text(
              formatMovementCurrency(balance, showPositiveSign: true),
              style: StreamTypography.captionBold.copyWith(
                color: balance >= 0 ? p.income : p.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<_CategoryExpense> _buildCategoryExpenses(
  List<Movement> movements,
  List<Category> categories,
) {
  final totalsByCategory = <String, double>{};
  for (final movement in movements) {
    if (!movement.isExpense) continue;
    totalsByCategory.update(
      movement.categoryId,
      (value) => value + movement.amount,
      ifAbsent: () => movement.amount,
    );
  }

  final items = totalsByCategory.entries.where((entry) => entry.value > 0).map((
    entry,
  ) {
    final category = categories.where((c) => c.id == entry.key).firstOrNull;
    return _CategoryExpense(
      categoryId: entry.key,
      category: category,
      total: entry.value,
    );
  }).toList()..sort((a, b) => b.total.compareTo(a.total));

  return items;
}

class _CategoryExpense {
  final String categoryId;
  final Category? category;
  final double total;

  const _CategoryExpense({
    required this.categoryId,
    required this.category,
    required this.total,
  });
}

class _CategoryExpensesSection extends StatelessWidget {
  final List<_CategoryExpense> items;
  final double totalExpenses;
  final AppDatabase db;
  final void Function(_CategoryExpense)? onCategoryTap;

  const _CategoryExpensesSection({
    required this.items,
    required this.totalExpenses,
    required this.db,
    this.onCategoryTap,
  });

  void _quickAdd(BuildContext context, _CategoryExpense item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovementPicker(db: db, categoryPreFill: item.categoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final cp = context.$chart;
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'Nessuna spesa nel periodo selezionato',
        subtitle: 'Le categorie appariranno quando registri uscite nel periodo',
      );
    }

    final visibleItems = items.take(5).toList();
    final hiddenCount = items.length - visibleItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spese per categoria', style: StreamTypography.h3),
        const SizedBox(height: StreamSpacing.md),
        Container(
          key: const Key('dashboard_category_expenses_chart'),
          decoration: BoxDecoration(
            color: cp.cardBackground,
            borderRadius: BorderRadius.circular(cp.cardRadius),
            border: Border.all(
              color: cp.cardBorderColor,
              width: cp.cardBorderWidth,
            ),
            boxShadow: cp.cardShadows,
          ),
          child: Padding(
            padding: const EdgeInsets.all(StreamSpacing.md),
            child: Column(
              children: [
                ...visibleItems.asMap().entries.map((entry) {
                  return _CategoryExpenseRow(
                    item: entry.value,
                    totalExpenses: totalExpenses,
                    isTopCategory: entry.key == 0,
                    onQuickAdd: () => _quickAdd(context, entry.value),
                    onTap: onCategoryTap != null
                        ? () => onCategoryTap!(entry.value)
                        : null,
                  );
                }),
                if (hiddenCount > 0) ...[
                  Divider(height: StreamSpacing.lg, color: p.divider),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mostra tutte: altre $hiddenCount categorie in Archivio',
                      style: StreamTypography.caption.copyWith(
                        color: p.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryExpenseRow extends StatelessWidget {
  final _CategoryExpense item;
  final double totalExpenses;
  final bool isTopCategory;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onTap;

  const _CategoryExpenseRow({
    required this.item,
    required this.totalExpenses,
    required this.isTopCategory,
    this.onQuickAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final cp = context.$chart;
    final category = item.category;
    final categoryColor = category != null
        ? Color(category.color)
        : Color(StreamColorPalette.defaultColor);
    final iconData = category != null
        ? StreamIconLibrary.getIcon(category.iconKey)
        : StreamIconLibrary.fallbackIcon;
    final percentage = totalExpenses > 0
        ? (item.total / totalExpenses) * 100
        : null;
    final progress = totalExpenses > 0 ? (item.total / totalExpenses) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
      padding: const EdgeInsets.only(
        left: StreamSpacing.sm,
        top: StreamSpacing.sm,
        bottom: StreamSpacing.sm,
        right: StreamSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isTopCategory
            ? categoryColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: isTopCategory
            ? Border.all(color: categoryColor.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(StreamRadius.sm),
                    ),
                    child: Icon(iconData, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: StreamSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.name ?? item.categoryId,
                          style: StreamTypography.bodyBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (percentage != null)
                          Text(
                            '${percentage.round()}% del totale spese',
                            style: StreamTypography.caption.copyWith(
                              color: p.textSecondary,
                            ),
                          ),
                        if (percentage != null) ...[
                          const SizedBox(height: StreamSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              cp.horizontalBarRadius,
                            ),
                            child: SizedBox(
                              height: cp.horizontalBarHeight / 4,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ColoredBox(
                                      color: cp.horizontalTrackColor,
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: progress.clamp(0.0, 1.0),
                                    alignment: Alignment.centerLeft,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: categoryColor,
                                        borderRadius: BorderRadius.circular(
                                          cp.horizontalBarRadius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: StreamSpacing.sm),
                  Text(
                    formatMovementCurrency(item.total),
                    style: StreamTypography.amount.copyWith(color: p.expense),
                  ),
                ],
              ),
            ),
          ),
          if (onQuickAdd != null) ...[
            const SizedBox(width: StreamSpacing.xs),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onQuickAdd,
                tooltip: 'Aggiungi movimento in questa categoria',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;
  final int count;
  final double? expenseComparison;

  const _KpiGrid({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.count,
    required this.expenseComparison,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final styleId = StreamKpiStyleId.fromString(
      PreferencesService.kpiStyleNotifier.value,
    );
    final isDense = styleId == StreamKpiStyleId.dense;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamKpiCard(
                title: 'Entrate',
                value: formatMovementCurrency(income),
                semanticType: StreamKpiSemanticType.income,
              ),
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: StreamKpiCard(
                title: 'Uscite',
                value: formatMovementCurrency(expenses),
                semanticType: StreamKpiSemanticType.expense,
                subtitle: expenseComparison != null
                    ? _formatExpenseComparison(expenseComparison!)
                    : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isDense ? StreamSpacing.xs : StreamSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamKpiCard(
                title: 'Saldo',
                value: formatMovementCurrency(balance, showPositiveSign: true),
                semanticType: StreamKpiSemanticType.balance,
                accentColor: balance >= 0 ? p.income : p.expense,
              ),
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: StreamKpiCard(
                title: 'Movimenti',
                value: '$count',
                semanticType: StreamKpiSemanticType.count,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatExpenseComparison(double value) {
    if (value == 0) return 'In linea col periodo precedente';
    final sign = value > 0 ? '+' : '-';
    return '$sign${formatMovementCurrency(value.abs())} rispetto al periodo precedente';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Container(
      padding: const EdgeInsets.all(StreamSpacing.xxl),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: p.textMuted),
          const SizedBox(height: StreamSpacing.md),
          Text(
            message,
            style: StreamTypography.bodyBold.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: StreamSpacing.xs),
          Text(
            subtitle,
            style: StreamTypography.caption.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CategoryDetailSheet extends StatelessWidget {
  final _CategoryExpense item;
  final List<Movement> movements;
  final AppDatabase db;
  final TimeFilter filter;

  const _CategoryDetailSheet({
    required this.item,
    required this.movements,
    required this.db,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final category = item.category;
    final color = category != null
        ? Color(category.color)
        : Color(StreamColorPalette.defaultColor);
    final iconData = category != null
        ? StreamIconLibrary.getIcon(category.iconKey)
        : StreamIconLibrary.fallbackIcon;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: StreamColors.canvas,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(StreamRadius.xl),
            ),
          ),
          child: ListenableBuilder(
            listenable: db,
            builder: (context, _) {
              final currentMovements = db.movements
                  .where((m) => m.categoryId == item.categoryId)
                  .toList();
              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: StreamSpacing.sm),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: StreamColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(StreamSpacing.lg),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(
                              StreamRadius.sm,
                            ),
                          ),
                          child: Icon(iconData, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: StreamSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category?.name ?? item.categoryId,
                                style: StreamTypography.h3,
                              ),
                              const SizedBox(height: StreamSpacing.xs),
                              Text(
                                '${currentMovements.length} movimenti · ${formatMovementCurrency(item.total)}',
                                style: StreamTypography.caption.copyWith(
                                  color: StreamColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => MovementPicker(
                                db: db,
                                categoryPreFill: item.categoryId,
                              ),
                            );
                          },
                          tooltip: 'Aggiungi movimento in questa categoria',
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: StreamColors.divider),
                  Expanded(
                    child: currentMovements.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(StreamSpacing.xl),
                              child: Text(
                                'Nessun movimento in questa categoria nel periodo',
                                style: StreamTypography.body.copyWith(
                                  color: StreamColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : GroupedMovementsList(
                            movements: currentMovements,
                            db: db,
                            showNotes: false,
                            scrollController: scrollController,
                            onEdit: (m) => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) =>
                                  MovementPicker(db: db, prefill: m),
                            ),
                            onDuplicate: (m) async {
                              final date = await showDuplicateDateSheet(
                                context,
                              );
                              if (date != null) {
                                db.duplicateMovement(m, date: date);
                              }
                            },
                            onSaveAsFavorite: (m) =>
                                db.saveMovementAsFavorite(m),
                            onAddQuick: (m) => db.saveMovementAsQuick(m),
                            onDelete: (m) => db.deleteMovement(m.id),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
