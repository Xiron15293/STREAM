import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../design/stream_icon_library.dart';
import '../theme.dart';
import '../widgets/movement_picker.dart';

class CalendarScreen extends StatefulWidget {
  final AppDatabase db;

  const CalendarScreen({super.key, required this.db});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = now;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = _focusedMonth.month == 1
          ? DateTime(_focusedMonth.year - 1, 12, 1)
          : DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = _focusedMonth.month == 12
          ? DateTime(_focusedMonth.year + 1, 1, 1)
          : DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = now;
    });
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  String _monthLabel(int year, int month) {
    const names = [
      'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
      'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
    ];
    return '${names[month - 1]} $year';
  }

  void _showDayMovements(BuildContext context, DateTime day, List<Movement> movements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DayMovementsSheet(
        day: day,
        movements: movements,
        db: widget.db,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = _daysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon ... 7=Sun

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.db,
        builder: (context, _) {
          final allMovements = widget.db.movements;
          final selectedDayFilter = _selectedDay != null
              ? allMovements.where((m) =>
                  m.date.year == _selectedDay!.year &&
                  m.date.month == _selectedDay!.month &&
                  m.date.day == _selectedDay!.day)
              : <Movement>[];
          final selectedDayMovements = selectedDayFilter.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              _buildHeader(context),
              _buildWeekdayHeaders(),
              Expanded(
                child: Column(
                  children: [
                    _buildGrid(allMovements, today),
                    if (_selectedDay != null) ...[
                      const Divider(height: 1, color: StreamColors.divider),
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
              _monthLabel(_focusedMonth.year, _focusedMonth.month),
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
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = _daysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon

    final daysWithMovements = <int>{};
    for (final m in allMovements) {
      if (m.date.year == year && m.date.month == month) {
        daysWithMovements.add(m.date.day);
      }
    }

    final cells = <Widget>[];
    for (int i = 1; i < firstWeekday; i++) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: StreamSpacing.lg, vertical: StreamSpacing.sm),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        alignment: WrapAlignment.spaceAround,
        children: cells,
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

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.md, StreamSpacing.lg, 80),
        itemCount: movements.length,
        separatorBuilder: (_, __) => const SizedBox(height: StreamSpacing.xs),
        itemBuilder: (context, index) {
          final m = movements[index];
          final cat = widget.db.categories.where((c) => c.id == m.categoryId).firstOrNull;
          final acc = widget.db.accounts.where((a) => a.id == m.accountId).firstOrNull;
          return _CalendarMovementCard(
            movement: m,
            category: cat,
            account: acc,
            db: widget.db,
            onEdit: () => _showPicker(context, prefill: m),
          );
        },
      ),
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

class _DayMovementsSheet extends StatelessWidget {
  final DateTime day;
  final List<Movement> movements;
  final AppDatabase db;

  const _DayMovementsSheet({
    required this.day,
    required this.movements,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.md, StreamSpacing.lg, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${day.day} ${_monthName(day.month)} ${day.year}',
                  style: StreamTypography.h3,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: StreamColors.divider),
          if (movements.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Nessun movimento',
                  style: StreamTypography.body.copyWith(color: StreamColors.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(StreamSpacing.lg, StreamSpacing.md, StreamSpacing.lg, StreamSpacing.xxl),
                itemCount: movements.length,
                separatorBuilder: (_, __) => const SizedBox(height: StreamSpacing.xs),
                itemBuilder: (context, index) {
                  final m = movements[index];
                  final cat = db.categories.where((c) => c.id == m.categoryId).firstOrNull;
                  final acc = db.accounts.where((a) => a.id == m.accountId).firstOrNull;
                  return _CalendarMovementCard(
                    movement: m,
                    category: cat,
                    account: acc,
                    db: db,
                    onEdit: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => MovementPicker(db: db, prefill: m),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
      'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
    ];
    return names[month - 1];
  }
}

class _CalendarMovementCard extends StatelessWidget {
  final Movement movement;
  final Category? category;
  final Account? account;
  final AppDatabase db;
  final VoidCallback onEdit;

  const _CalendarMovementCard({
    required this.movement,
    required this.category,
    required this.account,
    required this.db,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = category != null
        ? StreamIconLibrary.getIcon(category!.iconKey)
        : Icons.help_outline;
    return Container(
      padding: const EdgeInsets.all(StreamSpacing.md),
      decoration: BoxDecoration(
        color: StreamColors.surface,
        borderRadius: BorderRadius.circular(StreamRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(category?.color ?? 0xFF636366),
              borderRadius: BorderRadius.circular(StreamRadius.sm),
            ),
            child: Icon(iconData, color: Colors.white, size: 16),
          ),
          const SizedBox(width: StreamSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.title, style: StreamTypography.bodyBold),
                const SizedBox(height: 2),
                Text(
                  category?.name ?? movement.categoryId,
                  style: StreamTypography.caption.copyWith(color: StreamColors.textSecondary),
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
