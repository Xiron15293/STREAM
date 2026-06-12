import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';
import '../theme.dart';
import '../widgets/movement_picker.dart';
import '../widgets/movement_card.dart';

class CalendarScreen extends StatefulWidget {
  final AppDatabase db;

  const CalendarScreen({super.key, required this.db});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late TimeFilter _filter;
  DateTime? _selectedDay;

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _filter = TimeFilter.month(now.year, now.month);
    _selectedDay = now;
  }

  void _prevMonth() {
    setState(() {
      _filter = _filter.previous();
      _ensureSelectedDayInMonth();
    });
  }

  void _nextMonth() {
    setState(() {
      _filter = _filter.next();
      _ensureSelectedDayInMonth();
    });
  }

  void _ensureSelectedDayInMonth() {
    final year = _filter.startDate.year;
    final month = _filter.startDate.month;
    if (_selectedDay == null ||
        _selectedDay!.year != year ||
        _selectedDay!.month != month) {
      final now = DateTime.now();
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (now.year == year && now.month == month) {
        final day = now.day.clamp(1, daysInMonth);
        _selectedDay = DateTime(year, month, day);
      } else {
        _selectedDay = DateTime(year, month, 1);
      }
    }
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _filter = TimeFilter.month(now.year, now.month);
      _selectedDay = now;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final allMovements = widget.db.movements;
          final selectedDayMovements = _selectedDay != null
              ? allMovements.filterByTime(TimeFilter.day(_selectedDay!))
              : <Movement>[];

          return Column(
            children: [
              _buildHeader(context),
              _buildWeekdayHeaders(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildGrid(allMovements, today),
                    if (_selectedDay != null) ...[
                      const Divider(height: 1, color: StreamColors.divider),
                      _buildDayHeader(selectedDayMovements),
                      _buildDayMovementsList(selectedDayMovements),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: () => _showPicker(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg, vertical: StreamSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prevMonth,
            color: StreamColors.textSecondary,
          ),
          GestureDetector(
            onTap: _goToToday,
            child: Text(
              _filter.label,
              style: StreamTypography.h2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            color: StreamColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _weekdays.map((d) {
          final isWeekend = d == 'Sab' || d == 'Dom';
          return SizedBox(
            width: 40,
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: StreamTypography.caption.copyWith(
                color: isWeekend ? StreamColors.textMuted : StreamColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(List<Movement> allMovements, DateTime today) {
    final year = _filter.startDate.year;
    final month = _filter.startDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon
    final leadingEmpty = firstWeekday - 1;

    final daysWithMovements = <int>{};
    for (final m in allMovements) {
      if (m.date.year == year && m.date.month == month) {
        daysWithMovements.add(m.date.day);
      }
    }

    final cells = <Widget>[];
    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox(width: 40, height: 44));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dayDate = DateTime(year, month, day);
      final isToday = dayDate == today;
      final isSelected = _selectedDay != null &&
          _selectedDay!.year == year &&
          _selectedDay!.month == month &&
          _selectedDay!.day == day;
      final hasMovement = daysWithMovements.contains(day);

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = dayDate),
          child: SizedBox(
            width: 40,
            height: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? StreamColors.primary
                        : isToday
                            ? StreamColors.primary.withValues(alpha: 0.15)
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: StreamTypography.body.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? StreamColors.primary
                                : StreamColors.textPrimary,
                        fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                if (hasMovement)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: StreamColors.primary,
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      );
    }

    final trailingEmpty = (7 - cells.length % 7) % 7;
    for (int i = 0; i < trailingEmpty; i++) {
      cells.add(const SizedBox(width: 40, height: 44));
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: cells.sublist(i, i + 7),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg, vertical: StreamSpacing.sm),
      child: Column(children: rows),
    );
  }

  Widget _buildDayHeader(List<Movement> movements) {
    final dateLabel = TimeFilter.day(_selectedDay!).label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.md, StreamSpacing.lg, StreamSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dateLabel, style: StreamTypography.bodyBold),
          if (movements.isNotEmpty)
            Text(
              '${movements.length} moviment${movements.length == 1 ? 'o' : 'i'}',
              style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildDayMovementsList(List<Movement> movements) {
    if (movements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(StreamSpacing.xl),
        child: Center(
          child: Text(
            'Nessun movimento in questo giorno',
            style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.md, StreamSpacing.lg, 80),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movements.length,
      separatorBuilder: (_, i) => const SizedBox(height: StreamSpacing.xs),
      itemBuilder: (context, index) {
        final m = movements[index];
        final cat = widget.db.categories.where((c) => c.id == m.categoryId).firstOrNull;
        final acc = widget.db.accounts.where((a) => a.id == m.accountId).firstOrNull;
        final destinationAcc = m.destinationAccountId == null
            ? null
            : widget.db.accounts.where((a) => a.id == m.destinationAccountId).firstOrNull;
        final subcat = m.subcategoryId == null
            ? null
            : widget.db.subcategories.where((s) => s.id == m.subcategoryId).firstOrNull;
        return MovementCard(
          movement: m,
          category: cat,
          subcategory: subcat,
          account: acc,
          destinationAccount: destinationAcc,
          onTap: () => _showPicker(context, prefill: m),
        );
      },
    );
  }

  void _showPicker(BuildContext context, {Movement? prefill}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovementPicker(db: widget.db, prefill: prefill),
    );
  }
}
