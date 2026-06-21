import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/charts_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.hiddenChartIdsNotifier.value = {};
    PreferencesService.chartStyleNotifier.value = 'automatic';
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    final now = DateTime(2026, 6, 21);
    await db.addMovement(
      Movement(
        id: 'vis_chart_1',
        title: 'Grafico visibile',
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

  Future<void> pumpCharts(WidgetTester tester) async {
    final db = await seededDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
          chartStyle: StreamChartStyleId.fromString(
            PreferencesService.chartStyleNotifier.value,
          ),
        ),
        home: ChartsScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hidden_chart_ids and chart_style persist together', (tester) async {
    await PreferencesService.saveChartStyleId('technical');
    await PreferencesService.saveHiddenChartIds({'movements_cashflow'});

    expect(PreferencesService.chartStyleNotifier.value, 'technical');
    expect(PreferencesService.isChartVisible('movements_cashflow'), false);

    await pumpCharts(tester);

    expect(find.byKey(const Key('chart_card_movements_cashflow')), findsNothing);
    expect(find.byKey(const Key('chart_card_movements_daily_count')), findsOneWidget);
    expect(await PreferencesService.loadChartStyleId(), 'technical');
    expect(await PreferencesService.loadHiddenChartIds(), contains('movements_cashflow'));
  });
}
