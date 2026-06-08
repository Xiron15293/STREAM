import 'package:flutter/material.dart';
import '../models/daily_group.dart';
import '../theme.dart';

class DayHeader extends StatelessWidget {
  final DailyMovementGroup group;

  const DayHeader({super.key, required this.group});

  static const _weekdays = ['LUNEDÌ', 'MARTEDÌ', 'MERCOLEDÌ', 'GIOVEDÌ', 'VENERDÌ', 'SABATO', 'DOMENICA'];
  static const _months = [
    'GENNAIO', 'FEBBRAIO', 'MARZO', 'APRILE', 'MAGGIO', 'GIUGNO',
    'LUGLIO', 'AGOSTO', 'SETTEMBRE', 'OTTOBRE', 'NOVEMBRE', 'DICEMBRE'
  ];

  String get _weekdayLabel => _weekdays[group.date.weekday - 1];
  String get _monthLabel => _months[group.date.month - 1];
  String get _dayNumber => group.date.day.toString().padLeft(2, '0');
  String get _yearMonth => '$_monthLabel ${group.date.year}';

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

  @override
  Widget build(BuildContext context) {
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
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(_yearMonth, style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: StreamColors.textMuted,
                )),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          Row(
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
          ),
          const SizedBox(height: StreamSpacing.sm),
          Divider(color: StreamColors.divider, height: 1),
        ],
      ),
    );
  }
}
