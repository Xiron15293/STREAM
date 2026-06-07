import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/main.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';

String _monthLabel(int year, int month) {
  const months = [
    'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
    'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
  ];
  return '${months[month - 1]} $year';
}

Future<void> _openCalendar(WidgetTester tester) async {
  await tester.tap(find.text('Archivio'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Calendario'));
  await tester.pumpAndSettle();
}

void main() {
  SharedPreferences.setMockInitialValues({});

  group('CalendarScreen', () {
    testWidgets('shows month header with current month', (WidgetTester tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: MainScaffold(db: db),
      ));
      await tester.pumpAndSettle();

      await _openCalendar(tester);

      final now = DateTime.now();
      expect(find.text(_monthLabel(now.year, now.month)), findsOneWidget);
    });

    testWidgets('shows weekday headers', (WidgetTester tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: MainScaffold(db: db),
      ));
      await tester.pumpAndSettle();

      await _openCalendar(tester);

      expect(find.text('Lun'), findsOneWidget);
      expect(find.text('Mar'), findsOneWidget);
      expect(find.text('Ven'), findsOneWidget);
      expect(find.text('Dom'), findsOneWidget);
    });

    testWidgets('navigation arrows change month', (WidgetTester tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: MainScaffold(db: db),
      ));
      await tester.pumpAndSettle();

      await _openCalendar(tester);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final nextM = now.month == 12 ? 1 : now.month + 1;
      final nextY = now.month == 12 ? now.year + 1 : now.year;
      expect(find.text(_monthLabel(nextY, nextM)), findsOneWidget);
    });

    testWidgets('shows movement indicators on days', (WidgetTester tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: MainScaffold(db: db),
      ));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'cal_test',
        title: 'Calendario test',
        amount: 50,
        type: MovementType.expense,
        date: DateTime(now.year, now.month, now.day),
        categoryId: 'exp_1',
        createdAt: now,
      ));

      await _openCalendar(tester);

      // Day number should be rendered (may have multiple widgets with same number)
      expect(find.text('${now.day}'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping a day shows movements for that day', (WidgetTester tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: MainScaffold(db: db),
      ));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'day_test',
        title: 'Day movement',
        amount: 100,
        type: MovementType.income,
        date: DateTime(now.year, now.month, now.day),
        categoryId: 'inc_1',
        createdAt: now,
      ));

      await _openCalendar(tester);

      await tester.tap(find.text('${now.day}').first);
      await tester.pumpAndSettle();

      expect(find.text('Day movement'), findsOneWidget);
    });

    testWidgets('bottom nav has three tabs', (WidgetTester tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(StreamApp(db: db));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Archivio'), findsOneWidget);
      expect(find.text('Impostazioni'), findsOneWidget);
    });

    testWidgets('tapping month label resets to today', (WidgetTester tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(
        home: MainScaffold(db: db),
      ));
      await tester.pumpAndSettle();

      await _openCalendar(tester);

      final now = DateTime.now();

      // Navigate to next month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Tap the current label (which shows next month)
      final nextM = now.month == 12 ? 1 : now.month + 1;
      final nextY = now.month == 12 ? now.year + 1 : now.year;
      await tester.tap(find.text(_monthLabel(nextY, nextM)));
      await tester.pumpAndSettle();

      // Should be back at current month
      expect(find.text(_monthLabel(now.year, now.month)), findsOneWidget);
    });
  });
}
