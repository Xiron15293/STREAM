import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/category.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../widgets/time_filter_bar.dart';
import '../widgets/movement_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STREAM')),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final allMovements = widget.db.movements;
          final filteredMovements = allMovements.filterByTime(_filter);

          double filteredIncome = 0;
          double filteredExpenses = 0;
          for (final m in filteredMovements) {
            if (m.type == MovementType.income) {
              filteredIncome += m.amount;
            } else {
              filteredExpenses += m.amount;
            }
          }
          final filteredBalance = filteredIncome - filteredExpenses;
          final filteredCount = filteredMovements.length;
          final accountsBalance = widget.db.totalAccountsBalance;
          final lastFiltered = filteredMovements.take(5).toList();
          final hasAnyMovements = allMovements.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.xxl),
            children: [
              TimeFilterBar(activeFilter: _filter, onChanged: _onFilterChanged),
              const SizedBox(height: StreamSpacing.md),
              _BalanceHero(
                accountsBalance: accountsBalance,
                income: filteredIncome,
                expenses: filteredExpenses,
              ),
              const SizedBox(height: StreamSpacing.lg),
              _KpiGrid(
                income: filteredIncome,
                expenses: filteredExpenses,
                balance: filteredBalance,
                count: filteredCount,
              ),
              const SizedBox(height: StreamSpacing.section),
              if (lastFiltered.isNotEmpty) ...[
                Text('Ultime transazioni', style: StreamTypography.h3),
                const SizedBox(height: StreamSpacing.md),
                ...lastFiltered.map((m) {
                  final cat = widget.db.categories.where((c) => c.id == m.categoryId).firstOrNull;
                  final acc = widget.db.accounts.where((a) => a.id == m.accountId).firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
                    child: MovementCard(
                      movement: m,
                      category: cat,
                      account: acc,
                    ),
                  );
                }),
              ] else if (hasAnyMovements) ...[
                _EmptyState(
                  icon: Icons.search_off,
                  message: 'Nessun movimento nel periodo selezionato',
                  subtitle: 'Prova a cambiare periodo o filtro',
                ),
              ] else ...[
                Text('Ultime transazioni', style: StreamTypography.h3),
                const SizedBox(height: StreamSpacing.md),
                _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'Nessun movimento',
                  subtitle: 'Tocca + per aggiungerne uno',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final double accountsBalance;
  final double income;
  final double expenses;

  const _BalanceHero({required this.accountsBalance, required this.income, required this.expenses});

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
          Text('PATRIMONIO', style: StreamTypography.micro.copyWith(color: StreamColors.textSecondary)),
          const SizedBox(height: StreamSpacing.xs),
          Text(
            '${accountsBalance >= 0 ? '+' : ''}${accountsBalance.toStringAsFixed(2)} €',
            style: StreamTypography.display.copyWith(
              color: accountsBalance >= 0 ? StreamColors.income : StreamColors.expense,
            ),
          ),
          const SizedBox(height: StreamSpacing.sm),
          Row(
            children: [
              _LabeledValue(label: 'Entrate', value: '${income.toStringAsFixed(2)} €', color: StreamColors.income),
              const SizedBox(width: StreamSpacing.xxl),
              _LabeledValue(label: 'Uscite', value: '${expenses.toStringAsFixed(2)} €', color: StreamColors.expense),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LabeledValue({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: StreamTypography.micro.copyWith(color: StreamColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: StreamTypography.captionBold.copyWith(color: color)),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;
  final int count;

  const _KpiGrid({required this.income, required this.expenses, required this.balance, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _KpiCard(label: 'Entrate', value: '${income.toStringAsFixed(2)} €', color: StreamColors.income)),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(child: _KpiCard(label: 'Uscite', value: '${expenses.toStringAsFixed(2)} €', color: StreamColors.expense)),
          ],
        ),
        const SizedBox(height: StreamSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Saldo',
                value: '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)} €',
                color: balance >= 0 ? StreamColors.income : StreamColors.expense,
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
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: StreamSpacing.md, horizontal: StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: StreamTypography.micro.copyWith(color: StreamColors.textSecondary)),
          const SizedBox(height: StreamSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: StreamTypography.captionBold.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({required this.icon, required this.message, required this.subtitle});

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
          Text(message, style: StreamTypography.bodyBold.copyWith(color: StreamColors.textSecondary)),
          const SizedBox(height: StreamSpacing.xs),
          Text(subtitle, style: StreamTypography.caption.copyWith(color: StreamColors.textMuted)),
        ],
      ),
    );
  }
}
