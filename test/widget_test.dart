import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/main.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('App shows bottom navigation', (WidgetTester tester) async {
    final db = AppDatabase();
    await tester.pumpWidget(StreamApp(db: db));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Archivio'), findsOneWidget);
    expect(find.text('Impostazioni'), findsOneWidget);
  });

  test('AppDatabase saves and retrieves movements', () {
    final db = AppDatabase();
    expect(db.movements.length, 0);

    db.addMovement(
      Movement(
        id: 'test_1',
        title: 'Test',
        amount: 100.0,
        type: MovementType.income,
        date: DateTime(2026, 6, 1),
        categoryId: 'inc_1',
        createdAt: DateTime(2026, 6, 1, 10, 0),
      ),
    );

    expect(db.movements.length, 1);
    expect(db.movements.first.title, 'Test');
    expect(db.totalIncome, 100.0);
    expect(db.totalExpenses, 0.0);
    expect(db.balance, 100.0);
  });

  test('AppDatabase computes totals correctly', () {
    final db = AppDatabase();
    db.addMovement(
      Movement(
        id: 'a',
        title: 'Inc',
        amount: 200.0,
        type: MovementType.income,
        date: DateTime.now(),
        categoryId: 'inc_1',
        createdAt: DateTime.now(),
      ),
    );
    db.addMovement(
      Movement(
        id: 'b',
        title: 'Exp',
        amount: 50.0,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'exp_1',
        createdAt: DateTime.now(),
      ),
    );

    expect(db.totalIncome, 200.0);
    expect(db.totalExpenses, 50.0);
    expect(db.balance, 150.0);
    expect(db.lastMovements.length, 2);
  });

  test('Parse amount with comma decimal separator', () {
    expect(double.tryParse('10'), 10.0);
    expect(double.tryParse('10.50'), 10.50);
    expect(double.tryParse('10,50'), null);
    expect(double.tryParse('10,50'.replaceAll(',', '.')), 10.50);
  });

  testWidgets('MovementForm saves movement with dot and appears in list', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase();
    await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archivio'));
    await tester.pumpAndSettle();
    expect(find.text('Nessun movimento'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Titolo'),
      'Test salvataggio',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Importo (€)'),
      '150',
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();

    expect(find.text('Test salvataggio'), findsOneWidget);
    expect(db.movements.length, 1);
    expect(db.movements.first.amount, 150.0);
  });

  testWidgets('MovementForm saves movement with comma decimal', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase();
    await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archivio'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Titolo'),
      'Spesa con virgola',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Importo (€)'),
      '10,50',
    );

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();

    expect(find.text('Spesa con virgola'), findsOneWidget);
    expect(db.movements.length, 1);
    expect(db.movements.first.amount, 10.50);
  });

  testWidgets('Dashboard updates after saving movement', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase();
    await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    expect(find.text('0.00 €'), findsWidgets);

    // Save a movement via form on Archivio tab → Movimenti section
    await tester.tap(find.text('Archivio'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Titolo'),
      'Stipendio',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Importo (€)'),
      '2000',
    );

    // Switch to income type
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
    await tester.pumpAndSettle();

    // Go back to dashboard
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    // Dashboard should show updated values
    expect(find.text('+2000.00 €'), findsAtLeastNWidgets(1));
    expect(find.text('Stipendio'), findsNothing);
    expect(find.text('ENTRATE'), findsAtLeastNWidgets(1));
    expect(find.text('2000.00 €'), findsAtLeastNWidgets(1));
  });

  testWidgets('Backup & Restore is reachable from settings', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase();
    await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Impostazioni'));
    await tester.pumpAndSettle();

    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Preferenze'), findsOneWidget);
    expect(find.text('Info app'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Backup & Restore'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Esporta backup'), findsOneWidget);
    expect(find.text('Importa backup'), findsOneWidget);
  });
}
