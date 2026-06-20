import 'package:flutter/material.dart';
import '../design/stream_theme_extension.dart';
import '../models/category.dart';
import '../models/daily_group.dart';
import '../theme.dart';
import '../utils/currency_formatter.dart';

class DayHeader extends StatelessWidget {
  final DailyMovementGroup group;
  final MovementType? filterType;

  const DayHeader({super.key, required this.group, this.filterType});

  static const _weekdays = [
    'LUNEDÌ',
    'MARTEDÌ',
    'MERCOLEDÌ',
    'GIOVEDÌ',
    'VENERDÌ',
    'SABATO',
    'DOMENICA',
  ];
  static const _monthNames = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];

  String get _weekdayLabel => _weekdays[group.date.weekday - 1];
  String get _dayNumber => group.date.day.toString().padLeft(2, '0');

  Color _balanceColor(BuildContext context) {
    final p = context.$palette;
    if (group.balance > 0) return p.income;
    if (group.balance < 0) return p.expense;
    return p.textSecondary;
  }

  String _format(double value) {
    return formatMovementCurrency(value);
  }

  String _balancePrefix() {
    if (group.balance > 0) return '+';
    return '';
  }

  Widget _buildSummaryRowWithPalette(BuildContext context) {
    final p = context.$palette;
    if (filterType == MovementType.expense) {
      return Row(
        children: [
          Text(
            'Uscite: ',
            style: StreamTypography.caption.copyWith(color: p.textSecondary),
          ),
          Text(
            _format(group.totalExpenses),
            style: StreamTypography.captionBold.copyWith(color: p.expense),
          ),
        ],
      );
    }
    if (filterType == MovementType.income) {
      return Row(
        children: [
          Text(
            'Entrate: ',
            style: StreamTypography.caption.copyWith(color: p.textSecondary),
          ),
          Text(
            _format(group.totalIncome),
            style: StreamTypography.captionBold.copyWith(color: p.income),
          ),
        ],
      );
    }
    return Row(
      children: [
        Text(
          'Entrate: ',
          style: StreamTypography.caption.copyWith(color: p.textSecondary),
        ),
        Text(
          _format(group.totalIncome),
          style: StreamTypography.captionBold.copyWith(color: p.income),
        ),
        const SizedBox(width: StreamSpacing.md),
        Text(
          'Uscite: ',
          style: StreamTypography.caption.copyWith(color: p.textSecondary),
        ),
        Text(
          _format(group.totalExpenses),
          style: StreamTypography.captionBold.copyWith(color: p.expense),
        ),
        const SizedBox(width: StreamSpacing.md),
        Text(
          'Saldo: ',
          style: StreamTypography.caption.copyWith(color: p.textSecondary),
        ),
        Text(
          '${_balancePrefix()}${_format(group.balance)}',
          style: StreamTypography.captionBold.copyWith(
            color: _balanceColor(context),
          ),
        ),
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
    final p = context.$palette;
    final label = _dayLabel();
    return Padding(
      padding: const EdgeInsets.only(
        top: StreamSpacing.md,
        bottom: StreamSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _dayNumber,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: StreamSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weekdayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${_monthNames[group.date.month - 1]} ${group.date.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: p.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: p.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${group.movements.length} ${group.movements.length == 1 ? 'movimento' : 'movimenti'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: StreamSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _buildSummaryRowWithPalette(context),
          ),
          const SizedBox(height: StreamSpacing.sm),
          Divider(color: p.divider, height: 1),
        ],
      ),
    );
  }
}
