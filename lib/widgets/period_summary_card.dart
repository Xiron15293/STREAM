import 'package:flutter/material.dart';

import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';
import '../utils/movement_period_metrics.dart';

class PeriodSummaryCard extends StatelessWidget {
  final TimeFilter timeFilter;
  final List<Movement> movements;

  const PeriodSummaryCard({
    super.key,
    required this.timeFilter,
    required this.movements,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = MovementPeriodMetrics.fromMovements(movements);
    final periodLabel = timeFilterPeriodLabel(timeFilter.mode);
    final balanceColor = metrics.netBalance > 0
        ? StreamColors.income
        : metrics.netBalance < 0
        ? StreamColors.expense
        : StreamColors.textPrimary;

    return Container(
      key: const Key('period_summary_card'),
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
        border: Border.all(color: StreamColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatTimeFilterTitle(timeFilter),
            key: const Key('period_summary_title'),
            style: StreamTypography.h3,
          ),
          const SizedBox(height: StreamSpacing.md),
          Wrap(
            spacing: StreamSpacing.md,
            runSpacing: StreamSpacing.sm,
            children: [
              _MetricChip(
                keyName: 'period_summary_income',
                label: 'Entrate del $periodLabel',
                value: formatEuro(metrics.totalIncome),
                color: StreamColors.income,
              ),
              _MetricChip(
                keyName: 'period_summary_expense',
                label: 'Uscite del $periodLabel',
                value: formatEuro(metrics.totalExpense),
                color: StreamColors.expense,
              ),
              _MetricChip(
                keyName: 'period_summary_balance',
                label: 'Saldo del $periodLabel',
                value:
                    '${metrics.netBalance > 0
                        ? '+'
                        : metrics.netBalance < 0
                        ? '-'
                        : ''}${formatEuro(metrics.netBalance.abs())}',
                color: balanceColor,
              ),
              _MetricChip(
                keyName: 'period_summary_count',
                label: 'Movimenti del $periodLabel',
                value: '${metrics.movementCount}',
                color: StreamColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String keyName;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.keyName,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Column(
        key: Key(keyName),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StreamTypography.micro.copyWith(
              color: StreamColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: StreamTypography.captionBold.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
