import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/screens/dashboard_screen.dart';

void main() {
  group('1. Dashboard filtered KPI (in-memory logic)', () {
    late AppDatabase db;
    late DateTime now;

    setUp(() {
      db = AppDatabase();
      now = DateTime.now();
    });

    test('1.1 Default filter = mese corrente', () {
      final filter = TimeFilter.month(now.year, now.month);
      expect(filter.mode, TimeFilterMode.month);
      expect(filter.startDate.year, now.year);
      expect(filter.startDate.month, now.month);
    });

    test('1.2 Entrate filtrate per mese corrente', () {
      db.addMovement(Movement(
        id: 'm1', title: 'Income', amount: 500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(Movement(
        id: 'm2', title: 'Old Income', amount: 300,
        type: MovementType.income, date: prev,
        categoryId: 'inc_1', createdAt: prev,
      ));

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);
      double income = 0;
      for (final m in filtered) {
        if (m.type == MovementType.income) income += m.amount;
      }

      expect(filtered.length, 1);
      expect(income, 500);
      expect(db.totalIncome, 800);
    });

    test('1.3 Spese filtrate per mese corrente', () {
      db.addMovement(Movement(
        id: 'm1', title: 'Expense', amount: 200,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(Movement(
        id: 'm2', title: 'Old Expense', amount: 100,
        type: MovementType.expense, date: prev,
        categoryId: 'exp_1', createdAt: prev,
      ));

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);
      double expenses = 0;
      for (final m in filtered) {
        if (m.type == MovementType.expense) expenses += m.amount;
      }

      expect(filtered.length, 1);
      expect(expenses, 200);
      expect(db.totalExpenses, 300);
    });

    test('1.4 Saldo filtrato per mese corrente', () {
      db.addMovement(Movement(
        id: 'm1', title: 'Income', amount: 500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'm2', title: 'Expense', amount: 200,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);
      double income = 0, expenses = 0;
      for (final m in filtered) {
        if (m.type == MovementType.income) {
          income += m.amount;
        } else {
          expenses += m.amount;
        }
      }

      expect(income - expenses, 300);
      expect(db.balance, 300);
    });

    test('1.5 Cambio giorno: KPI filtrati correttamente', () {
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      db.addMovement(Movement(
        id: 'm1', title: 'Today', amount: 100,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'm2', title: 'Yesterday', amount: 50,
        type: MovementType.income, date: yesterday,
        categoryId: 'inc_1', createdAt: yesterday,
      ));

      final todayFilter = TimeFilter.day(now);
      expect(db.movements.filterByTime(todayFilter).length, 1);
      expect(db.movements.filterByTime(todayFilter).first.id, 'm1');

      final yesterdayFilter = TimeFilter.day(yesterday);
      expect(db.movements.filterByTime(yesterdayFilter).length, 1);
      expect(db.movements.filterByTime(yesterdayFilter).first.id, 'm2');
    });

    test('1.6 Cambio anno: KPI filtrati per anno', () {
      db.addMovement(Movement(
        id: 'm1', title: 'This Year', amount: 1000,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'm2', title: 'Last Year', amount: 500,
        type: MovementType.income, date: DateTime(now.year - 1, 6, 15),
        categoryId: 'inc_1', createdAt: DateTime(now.year - 1, 6, 15),
      ));

      expect(db.movements.filterByTime(TimeFilter.year(now.year)).length, 1);
      expect(db.movements.filterByTime(TimeFilter.year(now.year - 1)).length, 1);
    });

    test('1.7 Periodo custom: range di 7 giorni', () {
      final day1 = DateTime(now.year, now.month, 10);
      final day3 = DateTime(now.year, now.month, 12);
      final day7 = DateTime(now.year, now.month, 16);

      db.addMovement(Movement(
        id: 'm1', title: 'Day1', amount: 10,
        type: MovementType.expense, date: day1,
        categoryId: 'exp_1', createdAt: day1,
      ));
      db.addMovement(Movement(
        id: 'm2', title: 'Day3', amount: 20,
        type: MovementType.expense, date: day3,
        categoryId: 'exp_1', createdAt: day3,
      ));
      db.addMovement(Movement(
        id: 'm3', title: 'Day7', amount: 30,
        type: MovementType.expense, date: day7,
        categoryId: 'exp_1', createdAt: day7,
      ));

      final range = TimeFilter.customRange(
        day1, DateTime(now.year, now.month, 13),
      );
      final filtered = db.movements.filterByTime(range);
      expect(filtered.length, 2);
      expect(filtered.any((m) => m.id == 'm1'), true);
      expect(filtered.any((m) => m.id == 'm2'), true);
      expect(filtered.any((m) => m.id == 'm3'), false);
    });

    test('1.8 Patrimonio NON filtrato dal periodo', () {
      db.addAccount(Account(
        id: 'acc_test', name: 'Test', type: AccountType.bank,
        initialBalance: 5000, createdAt: now,
      ));

      db.addMovement(Movement(
        id: 'm1', title: 'Income', amount: 1000,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', accountId: 'acc_test', createdAt: now,
      ));

      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(Movement(
        id: 'm2', title: 'Old', amount: 500,
        type: MovementType.income, date: prev,
        categoryId: 'inc_1', accountId: 'acc_test', createdAt: prev,
      ));

      expect(db.totalAccountsBalance, 6500);

      final filter = TimeFilter.month(now.year, now.month);
      expect(db.movements.filterByTime(filter).length, 1);
      expect(db.totalAccountsBalance, 6500);
    });

    test('1.9 Stato vuoto: movimenti in altro periodo', () {
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(Movement(
        id: 'm1', title: 'Old', amount: 100,
        type: MovementType.income, date: prev,
        categoryId: 'inc_1', createdAt: prev,
      ));

      final nextMonth = now.month < 12 ? now.month + 1 : 1;
      final nextYear = now.month < 12 ? now.year : now.year + 1;
      final filter = TimeFilter.month(nextYear, nextMonth);

      expect(db.movements.filterByTime(filter).isEmpty, true);
      expect(db.movements.isNotEmpty, true);
    });

    test('1.10 Movimenti count filtrato', () {
      for (int i = 0; i < 5; i++) {
        db.addMovement(Movement(
          id: 'm$i', title: 'Mov $i', amount: 10.0,
          type: MovementType.expense, date: now,
          categoryId: 'exp_1', createdAt: now,
        ));
      }
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(Movement(
        id: 'm_old', title: 'Old', amount: 100,
        type: MovementType.income, date: prev,
        categoryId: 'inc_1', createdAt: prev,
      ));

      final filter = TimeFilter.month(now.year, now.month);
      expect(db.movements.filterByTime(filter).length, 5);
    });
  });

  group('2. Dashboard UI widget tests', () {
    testWidgets('2.1 TimeFilterBar and KPIs render correctly', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: DashboardScreen(db: db),
      ));

      expect(find.text('Giorno'), findsOneWidget);
      expect(find.text('Mese'), findsOneWidget);
      expect(find.text('Anno'), findsOneWidget);
      expect(find.text('Periodo'), findsOneWidget);

      final now = DateTime.now();
      final expectedLabel = TimeFilter.month(now.year, now.month).label;
      expect(find.text(expectedLabel), findsOneWidget);

      expect(find.text('PATRIMONIO'), findsOneWidget);
    });

    testWidgets('2.2 Filtered values shown in UI', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addMovement(Movement(
        id: 'm1', title: 'Stipendio', amount: 2500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'm2', title: 'Affitto', amount: 800,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));

      await tester.pumpWidget(MaterialApp(
        home: DashboardScreen(db: db),
      ));

      expect(find.textContaining('2500.00'), findsWidgets);
      expect(find.textContaining('800.00'), findsWidgets);
      expect(find.textContaining('1700.00'), findsWidgets);
    });

    testWidgets('2.3 Empty state when no movements', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: DashboardScreen(db: db),
      ));

      expect(find.text('Nessun movimento'), findsOneWidget);
      expect(find.text('Tocca + per aggiungerne uno'), findsOneWidget);
      expect(find.text('PATRIMONIO'), findsOneWidget);
      expect(find.text('Giorno'), findsOneWidget);
    });
  });
}
