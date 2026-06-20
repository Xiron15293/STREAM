import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/screens/categories_screen.dart';

void main() {
  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.addCategory('Casa', MovementType.expense, 0xFF4477AA);
    return db;
  }

  Future<void> pumpScreen(WidgetTester tester, StreamThemeId themeId) async {
    final db = await seededDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: CategoriesScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('CategoriesScreen renders with Forest and High Contrast', (
    tester,
  ) async {
    await pumpScreen(tester, StreamThemeId.forest);
    expect(find.text('Categorie'), findsWidgets);
    expect(find.byKey(const Key('categories_period_summary')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpScreen(tester, StreamThemeId.highContrast);
    expect(find.byKey(const Key('categories_filter_expense')), findsOneWidget);
    expect(find.byKey(const Key('categories_period_summary')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
