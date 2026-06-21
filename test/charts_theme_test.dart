import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_extension.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/charts_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    final now = DateTime(2026, 6, 20);
    await db.addMovement(
      Movement(
        id: 'chart_mov_1',
        title: 'Grafico test',
        amount: 75,
        type: MovementType.expense,
        date: now,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: now,
      ),
    );
    return db;
  }

  Future<void> pumpCharts(
    WidgetTester tester,
    StreamThemeId themeId, {
    bool withData = true,
  }) async {
    final db = withData ? await seededDb() : AppDatabase();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: ChartsScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ChartsScreen follows app theme background in Forest', (
    tester,
  ) async {
    await pumpCharts(tester, StreamThemeId.forest);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(
      scaffold.backgroundColor,
      StreamThemePalette.of(StreamThemeId.forest).canvas,
    );
  });

  testWidgets('chart card uses themed surface and divider in Minimal Sand', (
    tester,
  ) async {
    final palette = StreamThemePalette.of(StreamThemeId.minimalSand);
    final chartPalette = StreamTheme.build(
      palette,
      chartStyle: StreamChartStyleId.automatic,
    ).extension<StreamThemeExtension>()!.chartPalette;
    await pumpCharts(tester, StreamThemeId.minimalSand);

    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Entrate / Uscite nel tempo'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, chartPalette.cardBackground);
    expect((decoration.border! as Border).top.color, chartPalette.cardBorderColor);
  });

  testWidgets('chart empty state stays readable in High Contrast', (
    tester,
  ) async {
    final palette = StreamThemePalette.of(StreamThemeId.highContrast);
    await pumpCharts(tester, StreamThemeId.highContrast, withData: false);

    final message = tester.widget<Text>(
      find.text('Nessun movimento nel periodo selezionato'),
    );
    expect(message.style?.color, palette.textSecondary);
  });
}
