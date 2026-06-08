import 'package:flutter_test/flutter_test.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/daily_group.dart';

void main() {
  group('DailyMovementGroup', () {
    DateTime d(int year, int month, int day) =>
        DateTime(year, month, day, 12, 0, 0);

    Movement makeMov({
      required double amount,
      required MovementType type,
      required DateTime date,
      String id = 'm1',
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final c = createdAt ?? date;
      return Movement(
        id: id,
        title: 'Test',
        amount: amount,
        type: type,
        date: date,
        categoryId: 'cat1',
        createdAt: c,
        updatedAt: updatedAt ?? c,
      );
    }

    group('groupMovementsByDay', () {
      test('1. Empty list returns empty groups', () {
        expect(groupMovementsByDay([]), isEmpty);
      });

      test('2. Single day returns one group with one header', () {
        final now = DateTime.now();
        final movements = [makeMov(amount: 100, type: MovementType.income, date: now)];
        final groups = groupMovementsByDay(movements);
        expect(groups.length, 1);
        expect(groups[0].movements.length, 1);
      });

      test('3. Multiple days returns multiple groups', () {
        final d1 = d(2026, 6, 7);
        final d2 = d(2026, 6, 6);
        final movements = [
          makeMov(amount: 50, type: MovementType.expense, date: d1, id: 'm1'),
          makeMov(amount: 30, type: MovementType.expense, date: d2, id: 'm2'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups.length, 2);
      });

      test('4. Groups ordered recent → oldest', () {
        final d1 = d(2026, 6, 5);
        final d2 = d(2026, 6, 3);
        final d3 = d(2026, 6, 1);
        final movements = [
          makeMov(amount: 10, type: MovementType.income, date: d2, id: 'm2'),
          makeMov(amount: 20, type: MovementType.income, date: d1, id: 'm1'),
          makeMov(amount: 30, type: MovementType.income, date: d3, id: 'm3'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].date.day, 5);
        expect(groups[1].date.day, 3);
        expect(groups[2].date.day, 1);
      });

      test('5. Movements inside group ordered recent → oldest', () {
        final earlier = d(2026, 6, 7).subtract(const Duration(hours: 2));
        final later = d(2026, 6, 7).add(const Duration(hours: 2));
        final movements = [
          makeMov(amount: 10, type: MovementType.income, date: earlier, id: 'm1'),
          makeMov(amount: 20, type: MovementType.income, date: later, id: 'm2'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].movements[0].id, 'm2');
        expect(groups[0].movements[1].id, 'm1');
      });

      test('6. totalIncome correct', () {
        final date = d(2026, 6, 7);
        final movements = [
          makeMov(amount: 100, type: MovementType.income, date: date, id: 'm1'),
          makeMov(amount: 50, type: MovementType.expense, date: date, id: 'm2'),
          makeMov(amount: 25, type: MovementType.income, date: date, id: 'm3'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].totalIncome, 125);
      });

      test('7. totalExpenses correct', () {
        final date = d(2026, 6, 7);
        final movements = [
          makeMov(amount: 100, type: MovementType.income, date: date, id: 'm1'),
          makeMov(amount: 50, type: MovementType.expense, date: date, id: 'm2'),
          makeMov(amount: 25, type: MovementType.expense, date: date, id: 'm3'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].totalExpenses, 75);
      });

      test('8. balance = income - expenses', () {
        final date = d(2026, 6, 7);
        final movements = [
          makeMov(amount: 100, type: MovementType.income, date: date, id: 'm1'),
          makeMov(amount: 40, type: MovementType.expense, date: date, id: 'm2'),
          makeMov(amount: 10, type: MovementType.expense, date: date, id: 'm3'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].balance, 50);
      });

      test('9. Day with only income', () {
        final date = d(2026, 6, 7);
        final movements = [
          makeMov(amount: 200, type: MovementType.income, date: date, id: 'm1'),
          makeMov(amount: 50, type: MovementType.income, date: date, id: 'm2'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].totalIncome, 250);
        expect(groups[0].totalExpenses, 0);
        expect(groups[0].balance, 250);
      });

      test('10. Day with only expenses', () {
        final date = d(2026, 6, 7);
        final movements = [
          makeMov(amount: 30, type: MovementType.expense, date: date, id: 'm1'),
          makeMov(amount: 20, type: MovementType.expense, date: date, id: 'm2'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].totalIncome, 0);
        expect(groups[0].totalExpenses, 50);
        expect(groups[0].balance, -50);
      });

      test('11. Day with both income and expenses', () {
        final date = d(2026, 6, 7);
        final movements = [
          makeMov(amount: 100, type: MovementType.income, date: date, id: 'm1'),
          makeMov(amount: 60, type: MovementType.expense, date: date, id: 'm2'),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].totalIncome, 100);
        expect(groups[0].totalExpenses, 60);
        expect(groups[0].balance, 40);
      });

      test('12. Type does NOT influence order — only createdAt desc', () {
        final base = d(2026, 6, 7);
        // createdAt: t1=08:00 expense, t2=09:00 income, t3=10:00 expense
        final t1 = base.add(const Duration(hours: 8));
        final t2 = base.add(const Duration(hours: 9));
        final t3 = base.add(const Duration(hours: 10));
        final movements = [
          makeMov(amount: 45, type: MovementType.expense, date: base, id: 'spesa', createdAt: t1),
          makeMov(amount: 1300, type: MovementType.income, date: base, id: 'stipendio', createdAt: t2),
          makeMov(amount: 30, type: MovementType.expense, date: base, id: 'benzina', createdAt: t3),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].movements.length, 3);
        // Most recent createdAt first
        expect(groups[0].movements[0].id, 'benzina');
        expect(groups[0].movements[1].id, 'stipendio');
        expect(groups[0].movements[2].id, 'spesa');
        // Types are mixed: expense, income, expense
        expect(groups[0].movements[0].type, MovementType.expense);
        expect(groups[0].movements[1].type, MovementType.income);
        expect(groups[0].movements[2].type, MovementType.expense);
      });

      test('13. Same createdAt falls back to id order (stable)', () {
        final base = d(2026, 6, 7);
        final sameTime = base.add(const Duration(hours: 12));
        final movements = [
          makeMov(amount: 10, type: MovementType.expense, date: base, id: 'b_expense', createdAt: sameTime),
          makeMov(amount: 20, type: MovementType.income, date: base, id: 'a_income', createdAt: sameTime),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].movements.length, 2);
        // Same createdAt: sorted by id ascending
        expect(groups[0].movements[0].id, 'a_income');
        expect(groups[0].movements[1].id, 'b_expense');
      });

      test('14. Ordered by updatedAt desc, not createdAt', () {
        final base = d(2026, 6, 7);
        // A: created 08:00, updated 09:50
        // B: created 09:20, never updated (updatedAt = createdAt)
        // C: created 08:40, updated 10:30
        final t8 = base.add(const Duration(hours: 8));
        final t840 = base.add(const Duration(hours: 8, minutes: 40));
        final t920 = base.add(const Duration(hours: 9, minutes: 20));
        final t950 = base.add(const Duration(hours: 9, minutes: 50));
        final t1030 = base.add(const Duration(hours: 10, minutes: 30));
        final movements = [
          makeMov(amount: 10, type: MovementType.expense, date: base, id: 'A', createdAt: t8, updatedAt: t950),
          makeMov(amount: 20, type: MovementType.income, date: base, id: 'B', createdAt: t920),
          makeMov(amount: 30, type: MovementType.expense, date: base, id: 'C', createdAt: t840, updatedAt: t1030),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].movements.length, 3);
        // updatedAt desc: C (10:30) → A (09:50) → B (09:20 = createdAt)
        expect(groups[0].movements[0].id, 'C');
        expect(groups[0].movements[1].id, 'A');
        expect(groups[0].movements[2].id, 'B');
      });

      test('15. updatedAt with same timestamp falls back to createdAt, then id', () {
        final base = d(2026, 6, 7);
        final sameTime = base.add(const Duration(hours: 12));
        // X: updatedAt same as Y, but createdAt earlier → Y comes first
        // Z: same updatedAt and createdAt as Y, but id 'z' > 'y' → Y before Z
        final movements = [
          makeMov(amount: 10, type: MovementType.expense, date: base, id: 'x', createdAt: base, updatedAt: sameTime),
          makeMov(amount: 20, type: MovementType.income, date: base, id: 'y', createdAt: sameTime, updatedAt: sameTime),
          makeMov(amount: 30, type: MovementType.expense, date: base, id: 'z', createdAt: sameTime, updatedAt: sameTime),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].movements.length, 3);
        // same updatedAt → createdAt desc: y,z (sameTime) → x (base)
        // y and z have same updatedAt and createdAt → id asc: y before z
        expect(groups[0].movements[0].id, 'y');
        expect(groups[0].movements[1].id, 'z');
        expect(groups[0].movements[2].id, 'x');
      });

      test('16. Type does NOT influence order — only updatedAt desc', () {
        final base = d(2026, 6, 7);
        final t1 = base.add(const Duration(hours: 8));
        final t2 = base.add(const Duration(hours: 9));
        final t3 = base.add(const Duration(hours: 10));
        final movements = [
          makeMov(amount: 45, type: MovementType.expense, date: base, id: 'spesa', createdAt: t1),
          makeMov(amount: 1300, type: MovementType.income, date: base, id: 'stipendio', createdAt: t2),
          makeMov(amount: 30, type: MovementType.expense, date: base, id: 'benzina', createdAt: t3),
        ];
        final groups = groupMovementsByDay(movements);
        expect(groups[0].movements.length, 3);
        // No updatedAt set → fallback createdAt desc
        expect(groups[0].movements[0].id, 'benzina');  // 10:00
        expect(groups[0].movements[1].id, 'stipendio'); // 09:00
        expect(groups[0].movements[2].id, 'spesa');     // 08:00
        // Types are mixed
        expect(groups[0].movements[0].type, MovementType.expense);
        expect(groups[0].movements[1].type, MovementType.income);
        expect(groups[0].movements[2].type, MovementType.expense);
      });
    });
  });
}
