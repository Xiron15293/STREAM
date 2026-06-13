import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/duplicate_date_selector.dart';
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
              TimeFilterBar(activeFilter: _filter, onChanged: _onFilterChanged),
              const SizedBox(height: StreamSpacing.md),
              _BalanceHero(
                accountsBalance: accountsBalance,
                accounts: activeAccounts,
                db: widget.db,
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
          );
        },
      ),
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
    return Container(
      padding: const EdgeInsets.all(StreamSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            StreamColors.primary.withValues(alpha: 0.2),
            StreamColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(StreamRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PATRIMONIO',
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: StreamSpacing.xs),
          Text(
            '${accountsBalance >= 0 ? '+' : ''}${accountsBalance.toStringAsFixed(2)} €',
            style: StreamTypography.display.copyWith(
              color: accountsBalance >= 0
                  ? StreamColors.income
                  : StreamColors.expense,
            ),
          ),
          const SizedBox(height: StreamSpacing.sm),
          Text(
            'Situazione attuale, non filtrata dal periodo',
            style: StreamTypography.caption.copyWith(
              color: StreamColors.textSecondary,
            ),
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
      ),
    );
  }
}

class _AccountBalancePill extends StatelessWidget {
  final Account account;
  final double balance;

  const _AccountBalancePill({required this.account, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StreamSpacing.sm,
        vertical: StreamSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: StreamColors.surfaceElevated,
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
          Text(
            account.name,
            style: StreamTypography.caption.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(width: StreamSpacing.xs),
          Text(
            '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)} €',
            style: StreamTypography.captionBold.copyWith(
              color: balance >= 0 ? StreamColors.income : StreamColors.expense,
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
                    '${item.total.toStringAsFixed(2)} €',
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Entrate',
                value: '${income.toStringAsFixed(2)} €',
                color: StreamColors.income,
              ),
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: _KpiCard(
                label: 'Uscite',
                value: '${expenses.toStringAsFixed(2)} €',
                color: StreamColors.expense,
                subtitle: expenseComparison != null
                    ? _formatExpenseComparison(expenseComparison!)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: StreamSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Saldo',
                value:
                    '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)} €',
                color: balance >= 0
                    ? StreamColors.income
                    : StreamColors.expense,
              ),
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: _KpiCard(
                label: 'Movimenti',
                value: '$count',
                color: StreamColors.textPrimary,
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
    return '$sign${value.abs().toStringAsFixed(2)} € rispetto al periodo precedente';
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
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: StreamSpacing.md,
        horizontal: StreamSpacing.md,
      ),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: StreamSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: StreamTypography.captionBold.copyWith(color: color),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: StreamSpacing.xs),
            Text(
              subtitle!,
              style: StreamTypography.micro.copyWith(
                color: StreamColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(StreamSpacing.xxl),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: StreamColors.textMuted),
          const SizedBox(height: StreamSpacing.md),
          Text(
            message,
            style: StreamTypography.bodyBold.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: StreamSpacing.xs),
          Text(
            subtitle,
            style: StreamTypography.caption.copyWith(
              color: StreamColors.textMuted,
            ),
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
                            borderRadius: BorderRadius.circular(StreamRadius.sm),
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
                                '${currentMovements.length} movimenti · ${item.total.toStringAsFixed(2)} €',
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
                              builder: (_) => MovementPicker(
                                db: db,
                                prefill: m,
                              ),
                            ),
                            onDuplicate: (m) async {
                              final date = await showDuplicateDateSheet(context);
                              if (date != null) db.duplicateMovement(m, date: date);
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
