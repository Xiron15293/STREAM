import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/widgets/time_filter_bar.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('TimeFilterBar widget', () {
    testWidgets('shows Giorno/Mese/Anno/Intervallo segments and label',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: TimeFilterBar(
            activeFilter: TimeFilter.month(2026, 6),
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.text('Giorno'), findsOneWidget);
      expect(find.text('Mese'), findsOneWidget);
      expect(find.text('Anno'), findsOneWidget);
      expect(find.text('Intervallo'), findsOneWidget);
      expect(find.text('giugno 2026'), findsOneWidget);
    });

    testWidgets('previous/next change label for month mode',
        (WidgetTester tester) async {
      TimeFilter current = TimeFilter.month(2026, 6);
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) => TimeFilterBar(
              activeFilter: current,
              onChanged: (f) => setState(() => current = f),
            ),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(current.label, 'luglio 2026');

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(current.label, 'giugno 2026');
    });

    testWidgets('previous/next work for day mode',
        (WidgetTester tester) async {
      TimeFilter current = TimeFilter.day(DateTime(2026, 6, 15));
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) => TimeFilterBar(
              activeFilter: current,
              onChanged: (f) => setState(() => current = f),
            ),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(current.label, '16 giugno 2026');

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(current.label, '15 giugno 2026');
    });

    testWidgets('previous/next work for year mode',
        (WidgetTester tester) async {
      TimeFilter current = TimeFilter.year(2026);
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) => TimeFilterBar(
              activeFilter: current,
              onChanged: (f) => setState(() => current = f),
            ),
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(current.label, '2027');

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(current.label, '2026');
    });

    testWidgets('switching modes changes filter mode',
        (WidgetTester tester) async {
      TimeFilter current = TimeFilter.month(2026, 6);
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) => TimeFilterBar(
              activeFilter: current,
              onChanged: (f) => setState(() => current = f),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Giorno'));
      await tester.pumpAndSettle();
      expect(current.mode, TimeFilterMode.day);

      await tester.tap(find.text('Anno'));
      await tester.pumpAndSettle();
      expect(current.mode, TimeFilterMode.year);

      await tester.tap(find.text('Mese'));
      await tester.pumpAndSettle();
      expect(current.mode, TimeFilterMode.month);
    });

    testWidgets('customRange mode previous/next return self',
        (WidgetTester tester) async {
      TimeFilter current = TimeFilter.customRange(
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 30),
      );
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: StatefulBuilder(
            builder: (context, setState) => TimeFilterBar(
              activeFilter: current,
              onChanged: (f) => setState(() => current = f),
            ),
          ),
        ),
      ));

      final before = current;
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(current, before);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(current, before);
    });
  });

  group('MovementsScreen filtered by time', () {
    testWidgets('shows only movements in selected month',
        (WidgetTester tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;

      db.addMovement(Movement(
        id: 'current',
        title: 'Mese corrente',
        amount: 100,
        type: MovementType.expense,
        date: DateTime(now.year, now.month, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(now.year, now.month, 15),
      ));
      db.addMovement(Movement(
        id: 'prev',
        title: 'Mese prima',
        amount: 200,
        type: MovementType.expense,
        date: DateTime(prevYear, prevMonth, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(prevYear, prevMonth, 15),
      ));
      db.addMovement(Movement(
        id: 'next',
        title: 'Mese dopo',
        amount: 300,
        type: MovementType.expense,
        date: DateTime(nextYear, nextMonth, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(nextYear, nextMonth, 15),
      ));

      await tester.pumpWidget(StreamApp(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      expect(find.text('Mese corrente'), findsOneWidget);
      expect(find.text('Mese prima'), findsNothing);
      expect(find.text('Mese dopo'), findsNothing);
    });

    testWidgets('navigating prev/next updates movement list',
        (WidgetTester tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      final prevMonth = now.month == 1 ? 12 : now.month - 1;
      final prevYear = now.month == 1 ? now.year - 1 : now.year;
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;

      db.addMovement(Movement(
        id: 'cur',
        title: 'Corrente',
        amount: 100,
        type: MovementType.expense,
        date: DateTime(now.year, now.month, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(now.year, now.month, 15),
      ));
      db.addMovement(Movement(
        id: 'prev',
        title: 'Precedente',
        amount: 200,
        type: MovementType.expense,
        date: DateTime(prevYear, prevMonth, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(prevYear, prevMonth, 15),
      ));
      db.addMovement(Movement(
        id: 'nxt',
        title: 'Successivo',
        amount: 300,
        type: MovementType.expense,
        date: DateTime(nextYear, nextMonth, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(nextYear, nextMonth, 15),
      ));

      await tester.pumpWidget(StreamApp(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      expect(find.text('Corrente'), findsOneWidget);
      expect(find.text('Precedente'), findsNothing);
      expect(find.text('Successivo'), findsNothing);

      // Navigate to previous month
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('Precedente'), findsOneWidget);
      expect(find.text('Corrente'), findsNothing);
      expect(find.text('Successivo'), findsNothing);

      // Navigate to next month (which is now the current month)
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Also navigate one more to get to the "next" month
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Successivo'), findsOneWidget);
      expect(find.text('Precedente'), findsNothing);
      expect(find.text('Corrente'), findsNothing);
    });

    testWidgets('shows period empty state when movements exist but not in period',
        (WidgetTester tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;

      db.addMovement(Movement(
        id: 'outside',
        title: 'Fuori periodo',
        amount: 100,
        type: MovementType.expense,
        date: DateTime(nextYear, nextMonth, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(nextYear, nextMonth, 15),
      ));

      await tester.pumpWidget(StreamApp(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      expect(find.text('Nessun movimento in questo periodo'), findsOneWidget);
      expect(find.text('Fuori periodo'), findsNothing);
    });

    testWidgets('shows original empty state when no movements at all',
        (WidgetTester tester) async {
      final db = AppDatabase();

      await tester.pumpWidget(StreamApp(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      expect(find.text('Nessun movimento'), findsOneWidget);
    });

    testWidgets('works with MaterialApp (no StreamTheme)',
        (WidgetTester tester) async {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addMovement(Movement(
        id: 'test1',
        title: 'Movimento 0',
        amount: 100,
        type: MovementType.expense,
        date: DateTime(now.year, now.month, 15),
        categoryId: 'exp_1',
        createdAt: DateTime(now.year, now.month, 15),
      ));

      await tester.pumpWidget(MaterialApp(
        home: MainScaffold(db: db),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      expect(
        find.text('Movimento 0'),
        findsOneWidget,
        reason: 'Movement should be visible with MaterialApp',
      );
    });

  });
}
