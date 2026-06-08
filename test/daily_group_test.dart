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
    }) {
      return Movement(
        id: id,
        title: 'Test',
        amount: amount,
        type: type,
        date: date,
        categoryId: 'cat1',
        createdAt: date,
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
    });
  });
}
