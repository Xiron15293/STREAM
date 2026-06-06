import 'movement.dart';

enum TimeFilterMode { day, month, year, customRange }

class TimeFilter {
  final TimeFilterMode mode;
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  TimeFilter._({
    required this.mode,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  factory TimeFilter.day(DateTime date) {
    final d = _normalize(date);
    final start = DateTime.utc(d.year, d.month, d.day);
    final end = DateTime.utc(d.year, d.month, d.day + 1);
    return TimeFilter._(
      mode: TimeFilterMode.day,
      startDate: start,
      endDate: end,
      label: '${d.day} ${_monthNames[d.month - 1]} ${d.year}',
    );
  }

  factory TimeFilter.month(int year, int month) {
    final start = DateTime.utc(year, month, 1);
    final end = month < 12
        ? DateTime.utc(year, month + 1, 1)
        : DateTime.utc(year + 1, 1, 1);
    return TimeFilter._(
      mode: TimeFilterMode.month,
      startDate: start,
      endDate: end,
      label: '${_monthNames[month - 1]} $year',
    );
  }

  factory TimeFilter.year(int year) {
    return TimeFilter._(
      mode: TimeFilterMode.year,
      startDate: DateTime.utc(year, 1, 1),
      endDate: DateTime.utc(year + 1, 1, 1),
      label: '$year',
    );
  }

  factory TimeFilter.customRange(DateTime start, DateTime end) {
    final s = _normalize(start);
    final e = _normalize(end);
    final startUtc = DateTime.utc(s.year, s.month, s.day);
    final endUtc = e.isAfter(startUtc)
        ? DateTime.utc(e.year, e.month, e.day)
        : DateTime.utc(s.year, s.month, s.day + 1);

    String fmt(DateTime d) =>
        '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
    return TimeFilter._(
      mode: TimeFilterMode.customRange,
      startDate: startUtc,
      endDate: endUtc,
      label: '${fmt(startUtc)} - ${fmt(endUtc)}',
    );
  }

  bool contains(DateTime date) {
    final d = _normalize(date);
    final cmp = DateTime.utc(d.year, d.month, d.day);
    return !cmp.isBefore(startDate) && cmp.isBefore(endDate);
  }

  TimeFilter next() {
    switch (mode) {
      case TimeFilterMode.day:
        final next = DateTime.utc(
          startDate.year,
          startDate.month,
          startDate.day + 1,
        );
        return TimeFilter.day(next);
      case TimeFilterMode.month:
        final nextMonth = startDate.month < 12
            ? DateTime.utc(startDate.year, startDate.month + 1, 1)
            : DateTime.utc(startDate.year + 1, 1, 1);
        return TimeFilter.month(nextMonth.year, nextMonth.month);
      case TimeFilterMode.year:
        return TimeFilter.year(startDate.year + 1);
      case TimeFilterMode.customRange:
        return this;
    }
  }

  TimeFilter previous() {
    switch (mode) {
      case TimeFilterMode.day:
        final prev = DateTime.utc(
          startDate.year,
          startDate.month,
          startDate.day - 1,
        );
        return TimeFilter.day(prev);
      case TimeFilterMode.month:
        final prevMonth = startDate.month > 1
            ? DateTime.utc(startDate.year, startDate.month - 1, 1)
            : DateTime.utc(startDate.year - 1, 12, 1);
        return TimeFilter.month(prevMonth.year, prevMonth.month);
      case TimeFilterMode.year:
        return TimeFilter.year(startDate.year - 1);
      case TimeFilterMode.customRange:
        return this;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TimeFilter &&
      other.mode == mode &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(mode, startDate, endDate);

  static DateTime _normalize(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static const _monthNames = [
    'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
    'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
  ];
}

extension MovementFilter on List<Movement> {
  List<Movement> filterByTime(TimeFilter filter) {
    final filtered = where((m) => filter.contains(m.date)).toList();
    filtered.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }
}
