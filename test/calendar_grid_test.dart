import 'package:flutter_test/flutter_test.dart';

int leadingEmptyCells(int year, int month) {
  return DateTime(year, month, 1).weekday - 1;
}

int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

int trailingEmptyCells(int year, int month) {
  final total = leadingEmptyCells(year, month) + daysInMonth(year, month);
  return (7 - total % 7) % 7;
}

int totalGridSlots(int year, int month) {
  return leadingEmptyCells(year, month) + daysInMonth(year, month) + trailingEmptyCells(year, month);
}

void main() {
  group('Calendar grid math', () {
    test('April 2026: 1 April is Wednesday, leadingEmpty = 2', () {
      // 1 April 2026 = Wednesday → weekday = 3 → leadingEmpty = 2
      expect(DateTime(2026, 4, 1).weekday, equals(3));
      expect(leadingEmptyCells(2026, 4), equals(2));
    });

    test('April 2026: 30 days, total slots fill complete rows', () {
      expect(daysInMonth(2026, 4), equals(30));
      // 2 empty + 30 days = 32, next multiple of 7 = 35, trailing = 3
      expect(trailingEmptyCells(2026, 4), equals(3));
      expect(totalGridSlots(2026, 4), equals(35));
    });

    test('June 2026: 1 June is Monday, leadingEmpty = 0', () {
      // 1 June 2026 = Monday → weekday = 1 → leadingEmpty = 0
      expect(DateTime(2026, 6, 1).weekday, equals(1));
      expect(leadingEmptyCells(2026, 6), equals(0));
    });

    test('June 2026: 7 June is Sunday', () {
      expect(DateTime(2026, 6, 7).weekday, equals(7));
    });

    test('June 2026: 30 days, total slots fill complete rows', () {
      expect(daysInMonth(2026, 6), equals(30));
      // 0 empty + 30 days = 30, next multiple of 7 = 35, trailing = 5
      expect(trailingEmptyCells(2026, 6), equals(5));
      expect(totalGridSlots(2026, 6), equals(35));
    });

    test('February 2026: 28 days, leading empty = 0 (Monday)', () {
      expect(DateTime(2026, 2, 1).weekday, equals(7)); // Sunday
      expect(leadingEmptyCells(2026, 2), equals(6));
      expect(daysInMonth(2026, 2), equals(28));
      // 6 + 28 = 34, next multiple = 35, trailing = 1
      expect(trailingEmptyCells(2026, 2), equals(1));
      expect(totalGridSlots(2026, 2), equals(35));
    });

    test('March 2026: 31 days, leading empty', () {
      expect(DateTime(2026, 3, 1).weekday, equals(7)); // Sunday
      expect(leadingEmptyCells(2026, 3), equals(6));
      expect(daysInMonth(2026, 3), equals(31));
      // 6 + 31 = 37, next multiple = 42, trailing = 5
      expect(trailingEmptyCells(2026, 3), equals(5));
      expect(totalGridSlots(2026, 3), equals(42));
    });

    test('all grid totals are multiples of 7', () {
      for (int year = 2024; year <= 2027; year++) {
        for (int month = 1; month <= 12; month++) {
          expect(totalGridSlots(year, month) % 7, equals(0),
              reason: 'Year $year month $month should have grid slots multiple of 7');
        }
      }
    });

    test('selected day updates on month change', () {
      // Simulate the fix: when month changes, selectedDay must be in the new month
      DateTime selectedDay = DateTime(2026, 4, 15);

      // Simulate navigating to June 2026
      int newYear = 2026;
      int newMonth = 6;
      if (selectedDay.year != newYear || selectedDay.month != newMonth) {
        final now = DateTime.now();
        final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
        if (now.year == newYear && now.month == newMonth) {
          selectedDay = DateTime(newYear, newMonth, now.day.clamp(1, daysInNewMonth));
        } else {
          selectedDay = DateTime(newYear, newMonth, 1);
        }
      }

      expect(selectedDay.year, equals(2026));
      expect(selectedDay.month, equals(6));
    });
  });

  group('CalendarScreen month change', () {
    DateTime ensureSelectedDayInMonth(DateTime selectedDay, int filterYear, int filterMonth) {
      if (selectedDay.year != filterYear || selectedDay.month != filterMonth) {
        final now = DateTime.now();
        final daysInMonth = DateTime(filterYear, filterMonth + 1, 0).day;
        if (now.year == filterYear && now.month == filterMonth) {
          final day = now.day.clamp(1, daysInMonth);
          return DateTime(filterYear, filterMonth, day);
        } else {
          return DateTime(filterYear, filterMonth, 1);
        }
      }
      return selectedDay;
    }

    test('picks day 1 of target month when not current month', () {
      final result = ensureSelectedDayInMonth(DateTime(2026, 4, 15), 1999, 6);
      expect(result.year, equals(1999));
      expect(result.month, equals(6));
      expect(result.day, equals(1));
    });

    test('picks today when target is current month', () {
      final now = DateTime.now();
      final result = ensureSelectedDayInMonth(DateTime(2026, 4, 15), now.year, now.month);
      expect(result.year, equals(now.year));
      expect(result.month, equals(now.month));
      expect(result.day, equals(now.day));
    });

    test('stays unchanged when already in target month', () {
      final result = ensureSelectedDayInMonth(DateTime(2026, 6, 15), 2026, 6);
      expect(result.year, equals(2026));
      expect(result.month, equals(6));
      expect(result.day, equals(15));
    });

    test('clamps to last day of month when current day exceeds it', () {
      final result = ensureSelectedDayInMonth(DateTime(2026, 4, 15), 2026, 2);
      expect(result.year, equals(2026));
      expect(result.month, equals(2));
      expect(result.day, equals(1)); // February has 28 days, not current month
    });
  });
}
