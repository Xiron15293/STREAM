import 'package:flutter/material.dart';

import '../models/movement.dart';
import '../design/stream_surface_tokens.dart';
import '../models/time_filter.dart';
import '../design/stream_theme_extension.dart';
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
              ),
              _MetricChip(
                keyName: 'period_summary_expense',
                label: 'Uscite del $periodLabel',
                value: formatEuro(metrics.totalExpense),
                color: p.expense,
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
                color: p.textPrimary,
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
    final p = context.$palette;
    final chipSurface = StreamSurfaceTokens.card(p, muted: true);
    final tint = color.withValues(
      alpha: p.brightness == Brightness.light ? 0.14 : 0.22,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Container(
        key: Key(keyName),
        padding: const EdgeInsets.symmetric(
          horizontal: StreamSpacing.sm,
          vertical: StreamSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: chipSurface.background,
          borderRadius: BorderRadius.circular(StreamRadius.md),
          border: Border.all(
            color: chipSurface.border,
            width: chipSurface.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tint,
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.65)),
              ),
            ),
            const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: StreamTypography.micro.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: StreamTypography.captionBold.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
