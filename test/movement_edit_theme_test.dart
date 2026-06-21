import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/movement_picker.dart';

Future<(AppDatabase, Movement)> _seedEditDb() async {
  final db = AppDatabase();
  await db.addAccount(
    Account(
      id: 'edit_cash',
      name: 'Cash',
      type: AccountType.cash,
      createdAt: DateTime(2026, 6, 20),
      color: 0xFF607D8B,
    ),
  );
  await db.addCategory('Cibo', MovementType.expense, 0xFFE57373);
  final categoryId = db.categories.firstWhere((c) => c.name == 'Cibo').id;
  final movement = Movement(
    id: 'edit_mov',
    title: 'Pranzo',
    amount: 12.5,
    type: MovementType.expense,
    categoryId: categoryId,
    accountId: 'edit_cash',
    date: DateTime(2026, 6, 20),
    createdAt: DateTime(2026, 6, 20),
  );
  return (db, movement);
}

void main() {
  testWidgets('MovementPicker edit flow renders in High Contrast', (
    tester,
  ) async {
    final seeded = await _seedEditDb();
    final db = seeded.$1;
    final movement = seeded.$2;

    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.highContrast),
        ),
        home: Scaffold(
          body: MovementPicker(db: db, prefill: movement),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modifica movimento'), findsOneWidget);
    expect(find.byKey(const Key('movement_amount_display')), findsOneWidget);
    expect(find.byKey(const Key('movement_submit_top_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
