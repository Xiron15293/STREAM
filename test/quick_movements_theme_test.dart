import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/movement_picker.dart';

Future<AppDatabase> _seedQuickDb() async {
  final db = AppDatabase();
  await db.addAccount(
    Account(
      id: 'quick_cash',
      name: 'Cash',
      type: AccountType.cash,
      createdAt: DateTime(2026, 6, 20),
    ),
  );
  await db.addCategory('Cibo', MovementType.expense, 0xFFE57373);
  final categoryId = db.categories.firstWhere((c) => c.name == 'Cibo').id;
  await db.addQuickMovement(
    QuickMovement(
      id: 'quick_1',
      title: 'Colazione',
      amount: 4.5,
      type: MovementType.expense,
      categoryId: categoryId,
      accountId: 'quick_cash',
    ),
  );
  return db;
}

void main() {
  testWidgets('Quick movements panel renders in Forest and opens form', (
    tester,
  ) async {
    final db = await _seedQuickDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(StreamThemeId.forest)),
        home: Scaffold(body: MovementPicker(db: db)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rapidi'));
    await tester.pumpAndSettle();

    expect(find.text('Movimenti rapidi'), findsAtLeastNWidgets(1));
    expect(find.text('Colazione'), findsOneWidget);

    await tester.tap(find.byTooltip('Nuovo rapido'));
    await tester.pumpAndSettle();
    expect(find.text('Nuovo movimento rapido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
