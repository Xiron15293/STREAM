import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/widgets/calculator_amount_pad.dart';
import 'package:stream_app/widgets/movement_picker.dart';

void main() {
  group('AmountExpressionEvaluator', () {
    const evaluator = AmountExpressionEvaluator();

    double value(String expression, {bool allowNegative = false}) {
      final result = evaluator.evaluate(
        expression,
        allowNegative: allowNegative,
      );
      expect(result.error, isNull);
      return result.value!;
    }

    test('somma', () {
      expect(value('10 + 5'), 15);
    });

    test('sottrazione', () {
      expect(value('10 - 3'), 7);
    });

    test('moltiplicazione', () {
      expect(value('10 * 2'), 20);
    });

    test('divisione', () {
      expect(value('10 / 4'), 2.5);
    });

    test('divisione con due punti', () {
      expect(value('10 : 4'), 2.5);
    });

    test('decimali', () {
      expect(value('12.50 + 2.50'), 15);
    });

    test('virgola decimale', () {
      expect(value('12,50 + 2,50'), 15);
    });

    test('divisione per zero', () {
      final result = evaluator.evaluate('10 / 0');
      expect(result.isValid, isFalse);
      expect(result.error, 'Divisione per zero');
    });

    test('espressione incompleta', () {
      final result = evaluator.evaluate('10 +');
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
    });

    test('input vuoto', () {
      expect(value(''), 0);
    });

    test('precedenza operatori', () {
      expect(value('2 + 3 * 4'), 14);
    });
  });

  group('CalculatorAmountPad', () {
    testWidgets('tap numeri aggiorna campo', (tester) async {
      final controller = TextEditingController();
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_key_1')));
      await tester.tap(find.byKey(const Key('calculator_key_2')));
      await tester.pumpAndSettle();

      expect(controller.text, '12');
      expect(
        find.descendant(
          of: find.byKey(const Key('calculator_amount_display')),
          matching: find.text('12'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tap operatore aggiorna espressione', (tester) async {
      final controller = TextEditingController();
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_key_1')));
      await tester.tap(find.byKey(const Key('calculator_key_+')));
      await tester.pumpAndSettle();

      expect(controller.text, '1+');
    });

    testWidgets('tap = calcola ma non chiude il pad', (tester) async {
      final controller = TextEditingController(text: '10+5');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.pumpAndSettle();

      expect(controller.text, '15');
      expect(
        find.byKey(const Key('calculator_amount_display')),
        findsOneWidget,
      );
    });

    testWidgets('dopo = si puo continuare operazione', (tester) async {
      final controller = TextEditingController(text: '10+5');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.tap(find.byKey(const Key('calculator_key_+')));
      await tester.tap(find.byKey(const Key('calculator_key_2')));
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.pumpAndSettle();

      expect(controller.text, '17');
    });

    testWidgets('tap Fatto dopo = chiude e conferma valore', (tester) async {
      final controller = TextEditingController(text: '10/4');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.tap(find.byKey(const Key('calculator_done')));
      await tester.pumpAndSettle();

      expect(controller.text, '2.50');
      expect(find.byKey(const Key('calculator_amount_display')), findsNothing);
    });

    testWidgets('tap Fatto calcola e chiude', (tester) async {
      final controller = TextEditingController(text: '2+3*4');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_done')));
      await tester.pumpAndSettle();

      expect(controller.text, '14');
      expect(find.byKey(const Key('calculator_amount_display')), findsNothing);
    });

    testWidgets('divisione zero non crasha', (tester) async {
      final controller = TextEditingController(text: '10/0');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculator_amount_error')), findsOneWidget);
      expect(
        find.byKey(const Key('calculator_amount_display')),
        findsOneWidget,
      );
    });

    testWidgets('backspace funziona', (tester) async {
      final controller = TextEditingController(text: '123');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_backspace')));
      await tester.pumpAndSettle();

      expect(controller.text, '12');
    });

    testWidgets('clear funziona', (tester) async {
      final controller = TextEditingController(text: '123');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_clear')));
      await tester.pumpAndSettle();

      expect(controller.text, '');
    });

    testWidgets('= su espressione incompleta non crasha', (tester) async {
      final controller = TextEditingController(text: '10+');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.pumpAndSettle();

      expect(controller.text, '10+');
      expect(find.byKey(const Key('calculator_amount_error')), findsOneWidget);
    });

    testWidgets('= su input vuoto non crasha', (tester) async {
      final controller = TextEditingController();
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.pumpAndSettle();

      expect(controller.text, '0');
      expect(
        find.byKey(const Key('calculator_amount_display')),
        findsOneWidget,
      );
    });
  });

  group('CalculatorAmountField — keyboard prevention', () {
    testWidgets('campo readOnly non apre tastiera nativa', (tester) async {
      final controller = TextEditingController();
      await _pumpAmountField(tester, controller);

      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Importo (€)'),
      );
      expect(field.readOnly, isTrue);
      expect(field.showCursor, isFalse);
      expect(field.keyboardType, TextInputType.none);
    });

    testWidgets('tap apre il calculator pad custom', (tester) async {
      final controller = TextEditingController();
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      expect(find.byKey(const Key('calculator_key_1')), findsOneWidget);
      expect(find.byKey(const Key('calculator_key_+')), findsOneWidget);
      expect(find.byKey(const Key('calculator_done')), findsOneWidget);
    });

    testWidgets('Fatto chiude pad e mantiene valore nel controller', (
      tester,
    ) async {
      final controller = TextEditingController(text: '10+5');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.tap(find.byKey(const Key('calculator_done')));
      await tester.pumpAndSettle();

      expect(controller.text, '15');
      expect(find.byKey(const Key('calculator_amount_display')), findsNothing);
    });

    testWidgets('= calcola senza chiudere il pad', (tester) async {
      final controller = TextEditingController(text: '10+5');
      await _pumpAmountField(tester, controller);

      await _openPad(tester);
      await tester.tap(find.byKey(const Key('calculator_equals')));
      await tester.pumpAndSettle();

      expect(controller.text, '15');
      expect(
        find.byKey(const Key('calculator_amount_display')),
        findsOneWidget,
      );
    });
  });

  group('integrazione campi importo', () {
    testWidgets('aggiunta spesa con importo da calculator pad', (tester) async {
      final db = AppDatabase();
      await _pumpMainScaffold(tester, db);

      await _openMovementPicker(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Titolo'),
        'Spesa pad',
      );
      await _enterAmountWithPad(tester, ['1', '0', '+', '5']);
      await _saveMovement(tester);

      expect(db.movements.single.title, 'Spesa pad');
      expect(db.movements.single.amount, 15);
      expect(db.movements.single.type, MovementType.expense);
    });

    testWidgets('aggiunta entrata con importo da calculator pad', (
      tester,
    ) async {
      final db = AppDatabase();
      await _pumpMainScaffold(tester, db);

      await _openMovementPicker(tester);
      await tester.tap(find.text('Entrata'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titolo'),
        'Entrata pad',
      );
      await _enterAmountWithPad(tester, ['2', '0', '*', '2']);
      await _saveMovement(tester);

      expect(db.movements.single.title, 'Entrata pad');
      expect(db.movements.single.amount, 40);
      expect(db.movements.single.type, MovementType.income);
    });

    testWidgets('modifica movimento con importo da calculator pad', (
      tester,
    ) async {
      final db = AppDatabase();
      final movement = Movement(
        id: 'm1',
        title: 'Da modificare',
        amount: 10,
        type: MovementType.expense,
        date: DateTime(2026, 6, 10),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 10),
      );
      await db.addMovement(movement);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => MovementPicker(db: db, prefill: movement),
                ),
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();
      await _replaceAmountWithPad(tester, ['1', '0', '+', '7']);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Aggiorna'));
      await tester.tap(find.widgetWithText(FilledButton, 'Aggiorna'));
      await tester.pumpAndSettle();

      expect(db.movements.single.amount, 17);
    });

    testWidgets('saldo iniziale conto con calculator pad', (tester) async {
      final db = AppDatabase();
      await _pumpMainScaffold(tester, db);

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_accounts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Nome'),
        'Conto pad',
      );
      await _enterAmountWithPad(tester, [
        '1',
        '0',
        '0',
        '+',
        '5',
        '0',
      ], label: 'Saldo iniziale');
      await tester.tap(find.widgetWithText(FilledButton, 'Crea'));
      await tester.pumpAndSettle();

      final account = db.accounts.firstWhere((a) => a.name == 'Conto pad');
      expect(account.initialBalance, 150);
    });
  });
}

Future<void> _pumpAmountField(
  WidgetTester tester,
  TextEditingController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CalculatorAmountField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Importo (€)'),
        ),
      ),
    ),
  );
}

Future<void> _openPad(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextField, 'Importo (€)'));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('calculator_amount_display')), findsOneWidget);
}

Future<void> _pumpMainScaffold(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
  await tester.pumpAndSettle();
}

Future<void> _openMovementPicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bottom_nav_archive')));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> _enterAmountWithPad(
  WidgetTester tester,
  List<String> keys, {
  String label = 'Importo (€)',
}) async {
  await tester.tap(find.widgetWithText(TextField, label).last);
  await tester.pumpAndSettle();
  for (final key in keys) {
    await tester.tap(find.byKey(Key('calculator_key_$key')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('calculator_done')));
  await tester.pumpAndSettle();
}

Future<void> _replaceAmountWithPad(
  WidgetTester tester,
  List<String> keys,
) async {
  await tester.tap(find.widgetWithText(TextField, 'Importo (€)').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('calculator_clear')));
  await tester.pump();
  for (final key in keys) {
    await tester.tap(find.byKey(Key('calculator_key_$key')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('calculator_done')));
  await tester.pumpAndSettle();
}

Future<void> _saveMovement(WidgetTester tester) async {
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salva'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
  await tester.pumpAndSettle();
}
