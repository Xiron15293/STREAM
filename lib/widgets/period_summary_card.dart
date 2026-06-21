import 'package:flutter/material.dart';

import '../models/movement.dart';
import '../design/stream_surface_tokens.dart';
import '../models/time_filter.dart';
import '../design/stream_theme_extension.dart';
import '../theme.dart';
import '../utils/heatmap_utils.dart';
import '../utils/movement_period_metrics.dart';
import 'stream_kpi_card.dart';

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
    final p = context.$palette;
    final surface = StreamSurfaceTokens.card(p, elevated: true);
    final balanceColor = metrics.netBalance > 0
        ? p.income
        : metrics.netBalance < 0
        ? p.expense
        : p.textPrimary;

    return Container(
      key: const Key('period_summary_card'),
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: surface.background,
        borderRadius: BorderRadius.circular(StreamRadius.lg),
        border: Border.all(color: surface.border, width: surface.borderWidth),
        boxShadow: surface.shadows,
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
                color: p.income,
                semanticType: StreamKpiSemanticType.income,
              ),
              _MetricChip(
                keyName: 'period_summary_expense',
                label: 'Uscite del $periodLabel',
                value: formatEuro(metrics.totalExpense),
                color: p.expense,
                semanticType: StreamKpiSemanticType.expense,
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
                semanticType: StreamKpiSemanticType.balance,
              ),
              _MetricChip(
                keyName: 'period_summary_count',
                label: 'Movimenti del $periodLabel',
                value: '${metrics.movementCount}',
                color: p.textPrimary,
                semanticType: StreamKpiSemanticType.count,
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
  final StreamKpiSemanticType semanticType;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.keyName,
    required this.semanticType,
  });

  @override
  Widget build(BuildContext context) {
    return StreamKpiCard(
      cardKey: Key(keyName),
      title: label,
      value: value,
      icon: Icons.circle,
      accentColor: color,
      semanticType: semanticType,
      density: StreamKpiDensity.compact,
      layout: StreamKpiLayout.stacked,
      width: 160,
      uppercaseTitle: false,
    );
  }
}
