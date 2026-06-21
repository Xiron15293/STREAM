import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/movement_picker.dart';

Future<AppDatabase> _seedDb() async {
  final db = AppDatabase();
  await db.addAccount(
    Account(
      id: 'flow_cash',
      name: 'Cash',
      type: AccountType.cash,
      createdAt: DateTime(2026, 6, 20),
      color: 0xFF009688,
    ),
  );
  await db.addCategory('Cibo', MovementType.expense, 0xFFE57373);
  await db.addCategory('Stipendio', MovementType.income, 0xFF66BB6A);
  return db;
}

void main() {
  testWidgets(
    'MovementPicker manual flow renders category and account steps in Midnight',
    (tester) async {
      final db = await _seedDb();
      await tester.pumpWidget(
        MaterialApp(
          theme: StreamTheme.build(
            StreamThemePalette.of(StreamThemeId.midnight),
          ),
          home: Scaffold(body: MovementPicker(db: db)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nuovo movimento'), findsOneWidget);
      expect(
        find.byKey(const Key('add_movement_category_step')),
        findsOneWidget,
      );
      expect(find.byType(MovementPicker), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
