import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

const Map<String, String> _defaultCategoryKeyByLabel = {
  'Spesa': 'exp_1',
  'Casa': 'exp_2',
  'Auto': 'exp_3',
  'Svago': 'exp_4',
  'Salute': 'exp_5',
  'Altro': 'exp_6',
  'Stipendio': 'inc_1',
  'Rimborso': 'inc_2',
  'Vendita': 'inc_3',
};

/// Enters an amount value by tapping the calculator pad keys.
///
/// 1. Taps the amount [label] field to open the calculator pad.
/// 2. Taps each character of [amount] on the pad.
/// 3. Taps "Fatto" to confirm and close the pad.
///
/// Characters `,` and `.` both map to the `.` key on the pad.
Future<void> enterAmountWithCalculator(
  WidgetTester tester,
  String amount, {
  String label = 'Importo (€)',
}) async {
  final movementPadDigit = find.byKey(const Key('movement_pad_0'));
  if (movementPadDigit.evaluate().isNotEmpty) {
    for (var i = 0; i < amount.length; i++) {
      final char = amount[i];
      final key = switch (char) {
        '.' || ',' => ',',
        _ => char,
      };
      await tapVisible(tester, find.byKey(Key('movement_pad_$key')));
    }
    return;
  }

  await tester.tap(find.widgetWithText(TextField, label).last);
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calculator_done')), findsOneWidget);

  for (var i = 0; i < amount.length; i++) {
    final char = amount[i];
    final key = char == ',' ? '.' : char;
    await tester.tap(find.byKey(Key('calculator_key_$key')));
    await tester.pump();
  }

  await tester.tap(find.byKey(const Key('calculator_done')));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calculator_done')), findsNothing);
}

/// Opens the calculator pad, enters a sequence of keys without confirming.
/// Used for testing invalid expressions that Fatto won't accept.
Future<void> openPadAndType(
  WidgetTester tester,
  String expression, {
  String label = 'Importo (€)',
}) async {
  final movementPadDigit = find.byKey(const Key('movement_pad_0'));
  if (movementPadDigit.evaluate().isNotEmpty) {
    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];
      final key = switch (char) {
        '.' || ',' => ',',
        _ => char,
      };
      await tapVisible(tester, find.byKey(Key('movement_pad_$key')));
    }
    return;
  }

  await tester.tap(find.widgetWithText(TextField, label).last);
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('calculator_done')), findsOneWidget);

  for (var i = 0; i < expression.length; i++) {
    final char = expression[i];
    final key = char == ',' ? '.' : char;
    await tester.tap(find.byKey(Key('calculator_key_$key')));
    await tester.pump();
  }
}

/// Closes the calculator pad by clearing and tapping Fatto.
/// Used when an invalid expression prevents normal dismissal.
Future<void> closeCalculatorPad(WidgetTester tester) async {
  if (find.byKey(const Key('movement_pad_backspace')).evaluate().isNotEmpty) {
    return;
  }
  await tester.tap(find.byKey(const Key('calculator_clear')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('calculator_done')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('calculator_done')), findsNothing);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> prepareManualMovementDetails(
  WidgetTester tester, {
  String type = 'Spesa',
  String? categoryLabel,
  String? accountLabel,
}) async {
  if (find.byKey(const Key('movement_title_field')).evaluate().isNotEmpty ||
      find.widgetWithText(TextField, 'Titolo').evaluate().isNotEmpty) {
    return;
  }

  final normalizedType = type == 'Uscita' ? 'Spesa' : type;
  if (normalizedType != 'Spesa') {
    await tapVisible(tester, find.text(normalizedType).last);
  }

  if (find.byKey(const Key('add_movement_category_step')).evaluate().isNotEmpty) {
    final fallbackCategory = switch (normalizedType) {
      'Entrata' => 'Stipendio',
      'Trasferimento' => null,
      _ => 'Spesa',
    };
    final chosenCategory = categoryLabel ?? fallbackCategory;
    if (chosenCategory != null) {
      final categoryKey = _defaultCategoryKeyByLabel[chosenCategory];
      final categoryFinder = categoryKey != null
          ? find.byKey(Key('category_option_$categoryKey'))
          : find.text(chosenCategory).last;
      await tapVisible(tester, categoryFinder);
    }
  }

  if (find.byKey(const Key('add_movement_account_step')).evaluate().isNotEmpty) {
    final targetAccount = accountLabel ?? 'Principale';
    await tapVisible(tester, find.text(targetAccount).last);
  }
}

Future<void> enterMovementTitle(
  WidgetTester tester,
  String title,
) async {
  final finder = find.byKey(const Key('movement_title_field')).evaluate().isNotEmpty
      ? find.byKey(const Key('movement_title_field'))
      : find.widgetWithText(TextField, 'Titolo');
  await tester.enterText(finder, title);
  await tester.pumpAndSettle();
}

Future<void> enterMovementNote(
  WidgetTester tester,
  String note,
) async {
  final keyFinder = find.byKey(const Key('movement_note_field'));
  if (keyFinder.evaluate().isNotEmpty) {
    await tester.enterText(keyFinder, note);
  } else {
    final legacy = find.widgetWithText(TextField, 'Nota (opzionale)');
    await tester.enterText(legacy, note);
  }
  await tester.pumpAndSettle();
}

Future<void> submitMovement(WidgetTester tester, {String label = 'Salva'}) async {
  final keyed = find.byKey(const Key('movement_submit_button'));
  if (keyed.evaluate().isNotEmpty) {
    await tapVisible(tester, keyed);
    return;
  }
  await tapVisible(tester, find.widgetWithText(FilledButton, label));
}
