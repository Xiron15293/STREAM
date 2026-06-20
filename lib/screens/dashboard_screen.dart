import 'package:flutter/material.dart';
import '../data/database.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../design/stream_kpi_style.dart';
import '../design/stream_theme_extension.dart';
import '../design/stream_theme_palette.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/duplicate_date_selector.dart';
import '../utils/currency_formatter.dart';
import '../widgets/movement_picker.dart';
import '../widgets/time_filter_bar.dart';
import '../widgets/grouped_movements_list.dart';

class DashboardScreen extends StatefulWidget {
  final AppDatabase db;

  const DashboardScreen({super.key, required this.db});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late TimeFilter _filter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
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
              final accountsBalance = widget.db.totalAccountsBalance;
              final activeAccounts = widget.db.accounts
                  .where((a) => !a.archived)
                  .toList();
              final categoryExpenses = _buildCategoryExpenses(
                filteredMovements,
                widget.db.categories,
              );
              final expenseComparison = previousFilter != null
                  ? filteredExpenses - previousExpenses
                  : null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  StreamSpacing.lg,
                  StreamSpacing.xxl,
                ),
                children: [
                  TimeFilterBar(
                    activeFilter: _filter,
                    onChanged: _onFilterChanged,
                  ),
                  const SizedBox(height: StreamSpacing.md),
                  _BalanceHero(
                    accountsBalance: accountsBalance,
                    accounts: activeAccounts,
                    db: widget.db,
                  ),
                  const SizedBox(height: StreamSpacing.lg),
                  ValueListenableBuilder<String>(
                    valueListenable: PreferencesService.kpiStyleNotifier,
                    builder: (context, kpiStyle, _) => _KpiGrid(
                      income: filteredIncome,
                      expenses: filteredExpenses,
                      balance: filteredBalance,
                      count: filteredCount,
                      expenseComparison: expenseComparison,
                    ),
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
  final AppDatabase db;

  const _BalanceHero({
    required this.accountsBalance,
    required this.accounts,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final kpiStyle = StreamKpiStyleId.fromString(
      PreferencesService.kpiStyleNotifier.value,
    );
    final valueColor = accountsBalance >= 0 ? p.income : p.expense;
    final isDense = kpiStyle == StreamKpiStyleId.dense;

    Decoration decoration;
    EdgeInsets padding;
    TextStyle valueStyle;
    Widget content;

    switch (kpiStyle) {
      case StreamKpiStyleId.dense:
        padding = const EdgeInsets.symmetric(
          horizontal: StreamSpacing.lg,
          vertical: StreamSpacing.md,
        );
        valueStyle = StreamTypography.h1.copyWith(color: valueColor, height: 1);
        decoration = BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(StreamRadius.lg),
          border: Border.all(color: p.divider),
        );
        content = Row(
          key: const Key('dashboard_hero_kpi_style_dense'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _HeroHeading(accountsBalance: accountsBalance)),
            const SizedBox(width: StreamSpacing.md),
            Flexible(
              child: Text(
                formatMovementCurrency(accountsBalance, showPositiveSign: true),
                key: const Key('dashboard_hero_networth_value'),
                textAlign: TextAlign.right,
                style: valueStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case StreamKpiStyleId.glass:
        padding = const EdgeInsets.all(StreamSpacing.xl);
        valueStyle = StreamTypography.display.copyWith(color: valueColor);
        decoration = BoxDecoration(
          color: p.surfaceElevated.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(StreamRadius.xl),
          border: Border.all(color: p.divider.withValues(alpha: 0.55)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.primary.withValues(alpha: 0.18),
              p.surface.withValues(alpha: 0.9),
            ],
          ),
        );
        content = _HeroStacked(
          accounts: accounts,
          db: db,
          valueStyle: valueStyle,
          accountsBalance: accountsBalance,
        );
      case StreamKpiStyleId.outline:
        padding = const EdgeInsets.all(StreamSpacing.xl);
        valueStyle = StreamTypography.display.copyWith(color: valueColor);
        decoration = BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(StreamRadius.xl),
          border: Border.all(
            color: p.primary.withValues(alpha: 0.55),
            width: 1.4,
          ),
        );
        content = _HeroStacked(
          accounts: accounts,
          db: db,
          valueStyle: valueStyle,
          accountsBalance: accountsBalance,
        );
      case StreamKpiStyleId.solid:
        padding = const EdgeInsets.all(StreamSpacing.xl);
        valueStyle = StreamTypography.display.copyWith(color: p.textPrimary);
        decoration = BoxDecoration(
          color: p.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(StreamRadius.xl),
        );
        content = KeyedSubtree(
          key: const Key('dashboard_hero_kpi_style_solid'),
          child: _HeroStacked(
            accounts: accounts,
            db: db,
            valueStyle: valueStyle,
            accountsBalance: accountsBalance,
            forcePrimaryForeground: true,
          ),
        );
      case StreamKpiStyleId.split:
        padding = const EdgeInsets.all(StreamSpacing.xl);
        valueStyle = StreamTypography.amountLarge.copyWith(color: valueColor);
        decoration = BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(StreamRadius.xl),
          border: Border.all(color: p.divider),
        );
        content = _HeroSplit(
          accounts: accounts,
          db: db,
          valueStyle: valueStyle,
          accountsBalance: accountsBalance,
        );
      case StreamKpiStyleId.automatic:
      case StreamKpiStyleId.minimal:
        padding = const EdgeInsets.all(StreamSpacing.xl);
        valueStyle = StreamTypography.amountLarge.copyWith(color: valueColor);
        decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.primary.withValues(alpha: 0.18), p.surface],
          ),
          borderRadius: BorderRadius.circular(StreamRadius.xl),
          border: Border.all(color: p.divider),
        );
        content = _HeroStacked(
          accounts: accounts,
          db: db,
          valueStyle: valueStyle,
          accountsBalance: accountsBalance,
        );
    }

    return AnimatedContainer(
      key: const Key('dashboard_hero_networth_card'),
      duration: const Duration(milliseconds: 220),
      padding: padding,
      decoration: decoration,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: isDense ? p.textPrimary : null),
        child: content,
      ),
    );
  }
}

class _HeroHeading extends StatelessWidget {
  final double accountsBalance;

  const _HeroHeading({required this.accountsBalance});

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PATRIMONIO',
          style: StreamTypography.micro.copyWith(
            color: p.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: StreamSpacing.xs),
        Text(
          'Situazione attuale, non filtrata dal periodo',
          style: StreamTypography.caption.copyWith(color: p.textMuted),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
    final titleColor = forcePrimaryForeground ? p.textPrimary : p.textSecondary;
    final subtitleColor = forcePrimaryForeground
        ? p.textPrimary.withValues(alpha: 0.78)
        : p.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PATRIMONIO',
          style: StreamTypography.micro.copyWith(
            color: titleColor,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: StreamSpacing.sm),
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
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: StreamSpacing.md),
          Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.sm,
            children: accounts.take(3).map((account) {
              return _AccountBalancePill(
                account: account,
                balance: db.getAccountBalance(account),
                emphasis: forcePrimaryForeground,
              );
            }).toList(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _HeroHeading(accountsBalance: accountsBalance)),
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
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: StreamSpacing.md),
          Wrap(
            spacing: StreamSpacing.sm,
            runSpacing: StreamSpacing.sm,
            children: accounts.take(3).map((account) {
              return _AccountBalancePill(
                account: account,
                balance: db.getAccountBalance(account),
              );
            }).toList(),
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
    return Container(
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
      child: Wrap(
        spacing: StreamSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            StreamIconLibrary.getAccountIcon(account.iconKey),
            size: 14,
            color: Color(account.color),
          ),
          Text(
            account.name,
            style: StreamTypography.caption.copyWith(
              color: emphasis ? p.textPrimary : p.textSecondary,
            ),
          ),
          Text(
            formatMovementCurrency(balance, showPositiveSign: true),
            style: StreamTypography.captionBold.copyWith(
              color: balance >= 0 ? p.income : p.expense,
            ),
          ),
        ],
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
        Card(
          color: StreamColors.surface,
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
                  const Divider(height: StreamSpacing.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mostra tutte: altre $hiddenCount categorie in Archivio',
                      style: StreamTypography.caption.copyWith(
                        color: StreamColors.primary,
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
                              color: StreamColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: StreamSpacing.sm),
                  Text(
                    formatMovementCurrency(item.total),
                    style: StreamTypography.amount.copyWith(
                      color: StreamColors.expense,
                    ),
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
              child: _KpiCard(
                label: 'Entrate',
                value: formatMovementCurrency(income),
                color: p.income,
              ),
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: _KpiCard(
                label: 'Uscite',
                value: formatMovementCurrency(expenses),
                color: p.expense,
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
              child: _KpiCard(
                label: 'Saldo',
                value: formatMovementCurrency(balance, showPositiveSign: true),
                color: balance >= 0 ? p.income : p.expense,
              ),
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: _KpiCard(
                label: 'Movimenti',
                value: '$count',
                color: p.textPrimary,
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

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    final kpiStyle = PreferencesService.kpiStyleNotifier.value;
    final styleId = StreamKpiStyleId.fromString(kpiStyle);

    Color bgColor;
    BoxBorder? border;
    double pad;
    double labelSize;
    double valueSize;

    switch (styleId) {
      case StreamKpiStyleId.dense:
        pad = 8;
        labelSize = 8.5;
        valueSize = 12;
        bgColor = p.surfaceElevated;
        border = Border.all(color: p.divider);
      case StreamKpiStyleId.outline:
        pad = 12;
        labelSize = 11;
        valueSize = 15;
        bgColor = p.surface;
        border = Border.all(color: p.primary.withValues(alpha: 0.4));
      case StreamKpiStyleId.solid:
        pad = 12;
        labelSize = 11;
        valueSize = 15;
        bgColor = color.withValues(alpha: 0.15);
        border = null;
      case StreamKpiStyleId.split:
        pad = 12;
        labelSize = 11;
        valueSize = 15;
        bgColor = p.surface;
        border = null;
      case StreamKpiStyleId.glass:
        pad = 12;
        labelSize = 11;
        valueSize = 15;
        bgColor = p.surfaceElevated.withValues(alpha: 0.7);
        border = Border.all(color: p.divider.withValues(alpha: 0.5));
      default: // automatic, minimal
        pad = 16;
        labelSize = 11;
        valueSize = 20;
        bgColor = p.surface;
        border = Border.all(color: p.divider);
    }

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: border,
      ),
      child: styleId == StreamKpiStyleId.split
          ? _buildSplit(p)
          : styleId == StreamKpiStyleId.dense
          ? _buildDense(p, labelSize, valueSize)
          : _buildCompact(
              p,
              labelSize,
              valueSize,
              airy:
                  styleId == StreamKpiStyleId.minimal ||
                  styleId == StreamKpiStyleId.automatic,
            ),
    );
  }

  Widget _buildCompact(
    StreamThemePalette p,
    double labelSize,
    double valueSize, {
    bool airy = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: StreamTypography.micro.copyWith(
            fontSize: labelSize,
            color: p.textSecondary,
          ),
        ),
        SizedBox(height: airy ? StreamSpacing.sm : StreamSpacing.xs),
        Text(
          value,
          style: StreamTypography.captionBold.copyWith(
            fontSize: valueSize,
            color: color,
            height: airy ? 1.05 : 1.15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(top: airy ? 8 : 4),
            child: Text(
              subtitle!,
              style: StreamTypography.micro.copyWith(
                fontSize: labelSize - 1,
                color: p.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildDense(StreamThemePalette p, double labelSize, double valueSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: StreamTypography.micro.copyWith(
                  fontSize: labelSize,
                  color: p.textSecondary,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: StreamTypography.captionBold.copyWith(
                  fontSize: valueSize,
                  color: color,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: StreamTypography.micro.copyWith(
                fontSize: labelSize - 1,
                color: p.textMuted,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildSplit(StreamThemePalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: StreamTypography.micro.copyWith(color: p.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: StreamTypography.captionBold.copyWith(
                  color: color,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: StreamTypography.micro.copyWith(color: p.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
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
