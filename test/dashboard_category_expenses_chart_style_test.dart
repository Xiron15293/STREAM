import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/dashboard_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    final now = DateTime(2026, 6, 21);
    await db.addMovement(
      Movement(
        id: 'dash_exp_1',
        title: 'Spesa A',
        amount: 120,
        type: MovementType.expense,
        date: now,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: now,
      ),
    );
    await db.addMovement(
      Movement(
        id: 'dash_exp_2',
        title: 'Spesa B',
        amount: 30,
        type: MovementType.expense,
        date: now,
        categoryId: 'exp_2',
        accountId: defaultAccountId,
        createdAt: now,
      ),
    );
    return db;
  }

  Future<void> pumpDashboard(
    WidgetTester tester,
    StreamChartStyleId style, {
    bool withData = true,
  }) async {
    final db = withData ? await seededDb() : AppDatabase();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
          chartStyle: style,
        ),
        home: DashboardScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Spese per categoria reacts to chart style without changing data', (
    tester,
  ) async {
    await pumpDashboard(tester, StreamChartStyleId.automatic);
    expect(find.byKey(const Key('dashboard_category_expenses_chart')), findsOneWidget);
    expect(find.text('Spese per categoria'), findsOneWidget);
    expect(find.text('120.00 €'), findsOneWidget);

    final automaticDecoration = tester
        .widget<Container>(find.byKey(const Key('dashboard_category_expenses_chart')))
        .decoration! as BoxDecoration;

    await pumpDashboard(tester, StreamChartStyleId.editorial);
    final editorialDecoration = tester
        .widget<Container>(find.byKey(const Key('dashboard_category_expenses_chart')))
        .decoration! as BoxDecoration;

    expect(editorialDecoration.borderRadius, isNot(equals(automaticDecoration.borderRadius)));
    expect(find.text('120.00 €'), findsOneWidget);
  });

  testWidgets('empty state does not break with chart style applied', (tester) async {
    await pumpDashboard(tester, StreamChartStyleId.technical, withData: false);
    expect(find.text('Nessuna spesa nel periodo selezionato'), findsOneWidget);
  });
}
