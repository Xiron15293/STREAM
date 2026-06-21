import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/charts_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    final now = DateTime(2026, 6, 21);
    await db.addMovement(
      Movement(
        id: 'style_m1',
        title: 'Grafico stile',
        amount: 90,
        type: MovementType.expense,
        date: now,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: now,
      ),
    );
    await db.addMovement(
      Movement(
        id: 'style_m2',
        title: 'Grafico stile 2',
        amount: 40,
        type: MovementType.income,
        date: now,
        categoryId: 'inc_1',
        accountId: defaultAccountId,
        createdAt: now,
      ),
    );
    return db;
  }

  Future<void> pumpCharts(
    WidgetTester tester,
    StreamChartStyleId style,
  ) async {
    final db = await seededDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
          chartStyle: style,
        ),
        home: ChartsScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  BoxDecoration cardDecoration(WidgetTester tester, Key key) {
    return tester.widget<Container>(find.byKey(key)).decoration! as BoxDecoration;
  }

  testWidgets('default, technical and editorial styles keep charts present', (
    tester,
  ) async {
    await pumpCharts(tester, StreamChartStyleId.automatic);
    expect(find.byKey(const Key('charts_screen_root')), findsOneWidget);
    expect(find.byKey(const Key('chart_card_movements_cashflow')), findsOneWidget);
    expect(find.text('Entrate / Uscite nel tempo'), findsOneWidget);

    final automaticDecoration = cardDecoration(
      tester,
      const Key('chart_card_movements_cashflow'),
    );

    await pumpCharts(tester, StreamChartStyleId.technical);
    final technicalDecoration = cardDecoration(
      tester,
      const Key('chart_card_movements_cashflow'),
    );

    await pumpCharts(tester, StreamChartStyleId.editorial);
    final editorialDecoration = cardDecoration(
      tester,
      const Key('chart_card_movements_cashflow'),
    );

    expect(
      (technicalDecoration.border! as Border).top.width,
      greaterThan((automaticDecoration.border! as Border).top.width),
    );
    expect(
      editorialDecoration.borderRadius,
      isNot(equals(automaticDecoration.borderRadius)),
    );
  });
}
