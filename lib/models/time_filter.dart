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
    return TimeFilter._(
      mode: TimeFilterMode.day,
      startDate: start,
      endDate: start,
      label: '${d.day} ${_monthNames[d.month - 1]} ${d.year}',
    );
  }

  factory TimeFilter.month(int year, int month) {
    final start = DateTime.utc(year, month, 1);
    final end = month < 12
        ? DateTime.utc(year, month + 1, 1).subtract(const Duration(days: 1))
        : DateTime.utc(year + 1, 1, 1).subtract(const Duration(days: 1));
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
      endDate: DateTime.utc(year, 12, 31),
      label: '$year',
    );
  }

  factory TimeFilter.customRange(DateTime start, DateTime end) {
    final startNormalized = _normalize(start);
    final endNormalized = _normalize(end);
    final startUtc = DateTime.utc(
      startNormalized.year,
      startNormalized.month,
      startNormalized.day,
    );
    final endUtc = endNormalized.isBefore(startNormalized)
        ? startUtc
        : DateTime.utc(
            endNormalized.year,
            endNormalized.month,
            endNormalized.day,
          );

    String shortFmt(DateTime d) =>
        '${d.day} ${_shortMonthNames[d.month - 1]}';
    return TimeFilter._(
      mode: TimeFilterMode.customRange,
      startDate: startUtc,
      endDate: endUtc,
      label: '${shortFmt(startUtc)} → ${shortFmt(endUtc)}',
    );
  }

  bool contains(DateTime date) {
    final d = _normalize(date);
    final cmp = DateTime(d.year, d.month, d.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !cmp.isBefore(s) && !cmp.isAfter(e);
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

  static const _shortMonthNames = [
    'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
    'lug', 'ago', 'set', 'ott', 'nov', 'dic',
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
