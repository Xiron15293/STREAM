import 'package:flutter/material.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../theme.dart';

class DashboardScreen extends StatelessWidget {
  final AppDatabase db;

  const DashboardScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STREAM')),
      body: ListenableBuilder(
        listenable: db,
        builder: (context, _) {
          final income = db.totalIncome;
          final expenses = db.totalExpenses;
          final balance = db.balance;
          final accountsBalance = db.totalAccountsBalance;
          final last = db.lastMovements;
          return ListView(
            padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.lg, StreamSpacing.xxl),
            children: [
              _BalanceHero(accountsBalance: accountsBalance, income: income, expenses: expenses),
              const SizedBox(height: StreamSpacing.lg),
              _KpiGrid(income: income, expenses: expenses, balance: balance),
              const SizedBox(height: StreamSpacing.section),
              const Text('Ultime transazioni', style: StreamTypography.h3),
              const SizedBox(height: StreamSpacing.md),
              if (last.isEmpty)
                _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'Nessun movimento',
                  subtitle: 'Tocca + per aggiungerne uno',
                )
              else
                ...last.map((m) => _MovementTile(movement: m, db: db)),
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

  const _KpiGrid({required this.income, required this.expenses, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _KpiCard(label: 'Entrate', value: '${income.toStringAsFixed(2)} €', color: StreamColors.income)),
        const SizedBox(width: StreamSpacing.sm),
        Expanded(child: _KpiCard(label: 'Uscite', value: '${expenses.toStringAsFixed(2)} €', color: StreamColors.expense)),
        const SizedBox(width: StreamSpacing.sm),
        Expanded(
          child: _KpiCard(
            label: 'Saldo',
            value: '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)} €',
            color: balance >= 0 ? StreamColors.income : StreamColors.expense,
          ),
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

class _MovementTile extends StatelessWidget {
  final Movement movement;
  final AppDatabase db;

  const _MovementTile({required this.movement, required this.db});

  @override
  Widget build(BuildContext context) {
    final cat = db.categories.where((c) => c.id == movement.categoryId).firstOrNull;
    final acc = db.accounts.where((a) => a.id == movement.accountId).firstOrNull;
    final iconData = cat != null ? StreamIconLibrary.getIcon(cat.iconKey) : Icons.help_outline;
    return Container(
      margin: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(cat?.color ?? 0xFF636366),
              borderRadius: BorderRadius.circular(StreamRadius.md),
            ),
            child: Icon(iconData, color: Colors.white, size: 18),
          ),
          const SizedBox(width: StreamSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.title, style: StreamTypography.bodyBold),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (acc != null) ...[
                      Icon(StreamIconLibrary.getAccountIcon(acc.iconKey), size: 12, color: Color(acc.color)),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        [cat?.name ?? movement.categoryId, if (acc != null) acc.name].join(' • '),
                        style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${movement.type == MovementType.expense ? '-' : '+'}${movement.amount.toStringAsFixed(2)} €',
            style: StreamTypography.amount.copyWith(
              color: movement.type == MovementType.expense ? StreamColors.expense : StreamColors.income,
            ),
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
