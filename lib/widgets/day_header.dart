import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/daily_group.dart';
import '../theme.dart';

class DayHeader extends StatelessWidget {
  final DailyMovementGroup group;
  final MovementType? filterType;

  const DayHeader({super.key, required this.group, this.filterType});

  static const _weekdays = ['LUNEDÌ', 'MARTEDÌ', 'MERCOLEDÌ', 'GIOVEDÌ', 'VENERDÌ', 'SABATO', 'DOMENICA'];

  String get _weekdayLabel => _weekdays[group.date.weekday - 1];
  String get _dayNumber => group.date.day.toString().padLeft(2, '0');

  Color _balanceColor() {
    if (group.balance > 0) return StreamColors.income;
    if (group.balance < 0) return StreamColors.expense;
    return StreamColors.textSecondary;
  }

  String _format(double value) {
    return '${value.toStringAsFixed(2)} €';
  }

  String _balancePrefix() {
    if (group.balance > 0) return '+';
    return '';
  }

  Widget _buildSummaryRow() {
    if (filterType == MovementType.expense) {
      return Row(
        children: [
          Text('Uscite: ', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
          Text(_format(group.totalExpenses), style: StreamTypography.captionBold.copyWith(color: StreamColors.expense)),
        ],
      );
    }
    if (filterType == MovementType.income) {
      return Row(
        children: [
          Text('Entrate: ', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
          Text(_format(group.totalIncome), style: StreamTypography.captionBold.copyWith(color: StreamColors.income)),
        ],
      );
    }
    return Row(
      children: [
        Text('Entrate: ', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
        Text(_format(group.totalIncome), style: StreamTypography.captionBold.copyWith(color: StreamColors.income)),
        const SizedBox(width: StreamSpacing.md),
        Text('Uscite: ', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
        Text(_format(group.totalExpenses), style: StreamTypography.captionBold.copyWith(color: StreamColors.expense)),
        const SizedBox(width: StreamSpacing.md),
        Text('Saldo: ', style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary)),
        Text('${_balancePrefix()}${_format(group.balance)}',
          style: StreamTypography.captionBold.copyWith(color: _balanceColor())),
      ],
    );
  }

  String? _dayLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(group.date.year, group.date.month, group.date.day);
    if (date == today) return 'OGGI';
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == yesterday) return 'IERI';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final label = _dayLabel();
    return Padding(
      padding: const EdgeInsets.only(top: StreamSpacing.md, bottom: StreamSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_dayNumber, style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: StreamColors.textPrimary,
                height: 1.0,
              )),
              const SizedBox(width: StreamSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(_weekdayLabel, style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: StreamColors.textSecondary,
                  letterSpacing: 1.5,
                )),
              ),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: StreamColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(label, style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: StreamColors.primary,
                      letterSpacing: 1,
                    )),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${group.movements.length} ${group.movements.length == 1 ? 'movimento' : 'movimenti'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: StreamColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _buildSummaryRow(),
          ),
          const SizedBox(height: StreamSpacing.sm),
          Divider(color: StreamColors.divider, height: 1),
        ],
      ),
    );
  }
}
