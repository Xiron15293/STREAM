import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

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
  await tester.tap(find.byKey(const Key('calculator_clear')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('calculator_done')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('calculator_done')), findsNothing);
}
