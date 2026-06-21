import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/movement_picker.dart';

Future<AppDatabase> _seedFavoriteDb() async {
  final db = AppDatabase();
  await db.addAccount(
    Account(
      id: 'fav_cash',
      name: 'Cash',
      type: AccountType.cash,
      createdAt: DateTime(2026, 6, 20),
    ),
  );
  await db.addCategory('Cibo', MovementType.expense, 0xFFE57373);
  final categoryId = db.categories.firstWhere((c) => c.name == 'Cibo').id;
  await db.addFavoriteMovement(
    FavoriteMovement(
      id: 'fav_1',
      title: 'Cena abituale',
      amount: 18,
      type: MovementType.expense,
      categoryId: categoryId,
      accountId: 'fav_cash',
    ),
  );
  return db;
}

void main() {
  testWidgets('Favorite movements panel renders in Aurora and opens form', (
    tester,
  ) async {
    final db = await _seedFavoriteDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(StreamThemeId.aurora)),
        home: Scaffold(body: MovementPicker(db: db)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preferiti'));
    await tester.pumpAndSettle();

    expect(find.text('Preferiti'), findsAtLeastNWidgets(1));
    expect(find.text('Cena abituale'), findsOneWidget);

    await tester.tap(find.text('Nuovo'));
    await tester.pumpAndSettle();
    expect(find.text('Nuovo preferito'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
