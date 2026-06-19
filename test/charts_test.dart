import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/screens/charts_screen.dart';
import 'package:stream_app/utils/analytics_metrics.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('Analytics Metrics — pure functions', () {
    final now = DateTime(2026, 6, 15);
    final filter = TimeFilter.month(2026, 6);

    group('buildMovementCashflowSeries', () {
      test('returns empty list for empty movements', () {
        final result = buildMovementCashflowSeries([], filter);
        expect(result, isEmpty);
      });

      test('correctly splits income and expense', () {
        final movements = [
          Movement(id: '1', title: 'Inc', amount: 100, type: MovementType.income, date: now, categoryId: 'inc_1', createdAt: now),
          Movement(id: '2', title: 'Exp', amount: 50, type: MovementType.expense, date: now, categoryId: 'exp_1', createdAt: now),
        ];
        final result = buildMovementCashflowSeries(movements, filter);
        expect(result.length, 2);
        expect(result[0].label, 'Entrate');
        final incomePoint = result[0].points.firstWhere((p) => p.value > 0);
        expect(incomePoint.value, 100);
        expect(result[1].label, 'Uscite');
        final expensePoint = result[1].points.firstWhere((p) => p.value > 0);
        expect(expensePoint.value, 50);
      });
    });

    group('buildMovementCountByDay', () {
      test('counts movements per day', () {
        final movements = [
          Movement(id: '1', title: 'M1', amount: 10, type: MovementType.expense, date: now, categoryId: 'exp_1', createdAt: now),
          Movement(id: '2', title: 'M2', amount: 20, type: MovementType.expense, date: now, categoryId: 'exp_1', createdAt: now),
          Movement(id: '3', title: 'M3', amount: 30, type: MovementType.income, date: DateTime(2026, 6, 16), categoryId: 'inc_1', createdAt: now),
        ];
        final result = buildMovementCountByDay(movements, filter);
        expect(result.length, 1);
        expect(result[0].label, 'Movimenti');
        final day15 = result[0].points.where((p) => p.label == '15/6').firstOrNull;
        final day16 = result[0].points.where((p) => p.label == '16/6').firstOrNull;
        expect(day15?.value, 2);
        expect(day16?.value, 1);
      });
    });

    group('buildMovementTypeBreakdown', () {
      test('excludes zero-value types', () {
        final movements = [
          Movement(id: '1', title: 'Inc', amount: 100, type: MovementType.income, date: now, categoryId: 'inc_1', createdAt: now),
        ];
        final result = buildMovementTypeBreakdown(movements, filter);
        expect(result.length, 1);
        expect(result[0].label, 'Entrate');
      });

      test('includes all types with data', () {
        final movements = [
          Movement(id: '1', title: 'Inc', amount: 100, type: MovementType.income, date: now, categoryId: 'inc_1', createdAt: now),
          Movement(id: '2', title: 'Exp', amount: 50, type: MovementType.expense, date: now, categoryId: 'exp_1', createdAt: now),
          Movement(id: '3', title: 'Trf', amount: 30, type: MovementType.transfer, date: now, categoryId: '', createdAt: now),
        ];
        final result = buildMovementTypeBreakdown(movements, filter);
        expect(result.length, 3);
      });
    });

    group('buildTopSpendingDays', () {
      test('excludes transfers', () {
        final movements = [
          Movement(id: '1', title: 'Exp', amount: 50, type: MovementType.expense, date: now, categoryId: 'exp_1', createdAt: now),
          Movement(id: '2', title: 'Trf', amount: 100, type: MovementType.transfer, date: now, categoryId: '', createdAt: now),
        ];
        final result = buildTopSpendingDays(movements, filter);
        expect(result.length, 1);
        expect(result[0].points.first.value, 50);
      });
    });

    group('buildCategoryTopSeries', () {
      test('excludes transfers', () {
        final cat = Category(id: 'exp_1', name: 'Test Cat', type: MovementType.expense, color: 0xFF0000);
        final movements = [
          Movement(id: '1', title: 'Exp', amount: 50, type: MovementType.expense, date: now, categoryId: 'exp_1', createdAt: now),
          Movement(id: '2', title: 'Trf', amount: 100, type: MovementType.transfer, date: now, categoryId: '', createdAt: now),
        ];
        final result = buildCategoryTopSeries(movements, [cat], filter, null);
        expect(result.length, 1);
        expect(result[0].points.first.value, 50);
      });
    });

    group('buildCategoryComposition', () {
      test('groups overflow into Altro', () {
        final cats = List.generate(10, (i) => Category(
          id: 'cat_$i', name: 'Cat $i', type: MovementType.expense, color: 0xFF0000 + i,
        ));
        final movements = List.generate(10, (i) => Movement(
          id: 'm$i', title: 'M$i', amount: (i + 1) * 10.0, type: MovementType.expense,
          date: now, categoryId: 'cat_$i', createdAt: now,
        ));
        final result = buildCategoryComposition(movements, cats, filter, null);
        expect(result.any((s) => s.label == 'Altro'), true);
      });
    });

    group('buildAccountBalanceSeries', () {
      test('excludes archived accounts', () {
        final db = AppDatabase();
        final accounts = [
          Account(id: 'a1', name: 'Active', type: AccountType.bank, archived: false, createdAt: now),
          Account(id: 'a2', name: 'Archived', type: AccountType.bank, archived: true, createdAt: now),
        ];
        final result = buildAccountBalanceSeries(accounts, db);
        expect(result.every((p) => p.label != 'Archived'), true);
      });
    });

    group('buildBeneficiaryTopSeries', () {
      test('ignores empty payee', () {
        final movements = [
          Movement(id: '1', title: 'M1', amount: 50, type: MovementType.expense, date: now, categoryId: 'exp_1', payee: '  ', createdAt: now),
          Movement(id: '2', title: 'M2', amount: 100, type: MovementType.expense, date: now, categoryId: 'exp_1', payee: null, createdAt: now),
        ];
        final result = buildBeneficiaryTopSeries(movements, filter);
        expect(result, isEmpty);
      });

      test('aggregates by payee', () {
        final movements = [
          Movement(id: '1', title: 'M1', amount: 50, type: MovementType.expense, date: now, categoryId: 'exp_1', payee: 'Pippo', createdAt: now),
          Movement(id: '2', title: 'M2', amount: 30, type: MovementType.expense, date: now, categoryId: 'exp_1', payee: 'Pippo', createdAt: now),
        ];
        final result = buildBeneficiaryTopSeries(movements, filter);
        expect(result.length, 1);
        expect(result[0].points.first.value, 80);
      });
    });

    group('buildBeneficiaryFrequencySeries', () {
      test('counts occurrences', () {
        final movements = [
          Movement(id: '1', title: 'M1', amount: 50, type: MovementType.expense, date: now, categoryId: 'exp_1', payee: 'Pluto', createdAt: now),
          Movement(id: '2', title: 'M2', amount: 30, type: MovementType.expense, date: now, categoryId: 'exp_1', payee: 'Pluto', createdAt: now),
        ];
        final result = buildBeneficiaryFrequencySeries(movements, filter);
        expect(result.length, 1);
        expect(result[0].points.first.value, 2);
      });
    });
  });

  group('ChartsScreen integration', () {
    testWidgets('ChartsScreen renders with empty db shows empty state', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChartsScreen(db: db))));
      await tester.pumpAndSettle();
      expect(find.text('Nessun movimento nel periodo selezionato'), findsOneWidget);
    });

    testWidgets('ChartsScreen shows sections segmented control', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Test', amount: 10, type: MovementType.expense,
        date: now, categoryId: 'exp_1', createdAt: now,
      ));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChartsScreen(db: db))));
      await tester.pumpAndSettle();
      expect(find.text('Movimenti'), findsOneWidget);
      expect(find.text('Categorie'), findsOneWidget);
      expect(find.text('Conti'), findsOneWidget);
      expect(find.text('Beneficiari'), findsOneWidget);
    });

    testWidgets('Categorie section shows type filter', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Test', amount: 10, type: MovementType.expense,
        date: now, categoryId: 'exp_1', createdAt: now,
      ));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChartsScreen(db: db))));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categorie'));
      await tester.pumpAndSettle();
      expect(find.text('Uscite'), findsOneWidget);
      expect(find.text('Entrate'), findsOneWidget);
    });

    testWidgets('TimeFilter updates charts', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Test', amount: 10, type: MovementType.expense,
        date: now, categoryId: 'exp_1', createdAt: now,
      ));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChartsScreen(db: db))));
      await tester.pumpAndSettle();
      expect(find.text('Entrate / Uscite nel tempo'), findsOneWidget);
    });

    testWidgets('Conti section shows chart headers', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addAccount(Account(id: 'acc2', name: 'Secondo', type: AccountType.cash, createdAt: now));
      await db.addMovement(Movement(
        id: 'm1', title: 'Test', amount: 10, type: MovementType.expense,
        date: now, categoryId: 'exp_1', accountId: 'acc2', createdAt: now,
      ));
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ChartsScreen(db: db))));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Conti'));
      await tester.pumpAndSettle();
      expect(find.text('Saldo per conto'), findsWidgets);
      expect(find.text('Flussi per conto'), findsWidgets);
      expect(find.byType(ChartsScreen), findsOneWidget);
    });
  });

  group('Bottom navigation integration', () {
    testWidgets('Grafici tab appears in bottom nav', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bottom_nav_charts')), findsOneWidget);
    });

    testWidgets('Tap on Grafici opens ChartsScreen', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Test', amount: 10, type: MovementType.expense,
        date: now, categoryId: 'exp_1', createdAt: now,
      ));
      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_charts')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(ChartsScreen), findsOneWidget);
      expect(find.text('Grafici'), findsAtLeastNWidgets(1));
    });

    testWidgets('Dashboard and Archivio still work after adding Grafici', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_dashboard')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsWidgets);

      await tester.tap(find.byKey(const Key('bottom_nav_archive')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Archivio'), findsWidgets);

      await tester.tap(find.byKey(const Key('bottom_nav_charts')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Grafici'), findsAtLeastNWidgets(1));

      await tester.tap(find.byKey(const Key('bottom_nav_settings')).hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Impostazioni'), findsWidgets);
    });
  });
}
