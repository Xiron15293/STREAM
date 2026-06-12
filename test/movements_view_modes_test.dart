import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/movements_screen.dart';
import 'package:stream_app/screens/settings_screen.dart';

void main() {
  late DateTime today;

  setUp(() {
    today = DateTime.now();
    SharedPreferences.setMockInitialValues({});
    PreferencesService.movementsViewModeNotifier.value =
        PreferencesService.defaultMovementsViewMode;
  });

  AppDatabase seededDb() {
    final db = AppDatabase();
    final day = DateTime(today.year, today.month, today.day, 9);
    db.addMovement(
      Movement(
        id: 'income_today',
        title: 'Entrata oggi',
        amount: 50,
        type: MovementType.income,
        date: day,
        categoryId: 'inc_1',
        accountId: defaultAccountId,
        createdAt: day,
      ),
    );
    db.addMovement(
      Movement(
        id: 'expense_today',
        title: 'Uscita oggi',
        amount: 20,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: day,
      ),
    );
    return db;
  }

  Future<void> pumpMovements(
    WidgetTester tester,
    AppDatabase db, {
    required String mode,
  }) async {
    SharedPreferences.setMockInitialValues({'movements_view_mode': mode});
    await tester.pumpWidget(MaterialApp(home: MovementsScreen(db: db)));
    await tester.pumpAndSettle();
  }

  test('save and load movement view preference uses new enum values', () async {
    await PreferencesService.saveMovementsViewMode(MovementsViewMode.heatmap);

    final mode = await PreferencesService.loadMovementsViewMode();
    expect(mode, MovementsViewMode.heatmap);
    expect(PreferencesService.movementsViewModeNotifier.value, mode);
  });

  test(
    'load movement view preference keeps legacy values compatible',
    () async {
      SharedPreferences.setMockInitialValues({
        'movements_view_mode': 'listHeatmap',
      });
      expect(
        await PreferencesService.loadMovementsViewMode(),
        MovementsViewMode.list,
      );

      SharedPreferences.setMockInitialValues({
        'movements_view_mode': 'advancedHeatmap',
      });
      expect(
        await PreferencesService.loadMovementsViewMode(),
        MovementsViewMode.heatmap,
      );
    },
  );

  testWidgets('settings screen changes default movement view', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(home: SettingsScreen(db: seededDb())));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Vista movimenti predefinita'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final tile = find.widgetWithText(ListTile, 'Vista movimenti predefinita');
    expect(tile, findsOneWidget);

    await tester.tap(tile, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_view_mode_heatmap')));
    await tester.pumpAndSettle();

    expect(
      await PreferencesService.loadMovementsViewMode(),
      MovementsViewMode.heatmap,
    );
  });

  testWidgets(
    'movements screen in list mode hides inline selector and shows only list layout',
    (tester) async {
      await pumpMovements(tester, seededDb(), mode: 'list');

      expect(
        find.byKey(const Key('movements_mode_inline_selector')),
        findsNothing,
      );
      expect(find.byKey(const Key('movements_layout_list')), findsOneWidget);
      expect(
        find.byKey(const Key('movements_open_calendar_default_settings')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);
      expect(find.byKey(const Key('movements_layout_heatmap')), findsNothing);
    },
  );

  testWidgets('list mode CTA points user to default calendar settings', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'list');

    expect(
      find.byKey(const Key('movements_open_calendar_default_settings')),
      findsOneWidget,
    );
    expect(find.text('Vista calendario predefinita'), findsOneWidget);
  });

  testWidgets('movements screen in calendar mode shows only calendar layout', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'calendar');

    expect(find.byKey(const Key('movements_layout_list')), findsNothing);
    expect(find.byKey(const Key('movements_layout_calendar')), findsOneWidget);
    expect(find.byKey(const Key('movements_layout_heatmap')), findsNothing);
    expect(
      find.byKey(const Key('period_heatmap_month_surface')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('day_filter_transfer')), findsNothing);
  });

  testWidgets('movements screen in heatmap mode shows only heatmap layout', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'heatmap');

    expect(find.byKey(const Key('movements_layout_list')), findsNothing);
    expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);
    expect(find.byKey(const Key('movements_layout_heatmap')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('movements_layout_heatmap')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('advanced_heatmap_kpi_panel')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_transfer')), findsOneWidget);
  });

  testWidgets('year filter shows premium annual heatmap with 12 months', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'calendar');

    await tester.tap(find.text('Anno'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('annual_heatmap')), findsOneWidget);
    expect(find.text('Andamento annuale'), findsOneWidget);
    expect(find.text('Heatmap annuale compatta dei 12 mesi'), findsNothing);
    for (int month = 1; month <= 12; month++) {
      expect(find.byKey(Key('annual_heatmap_month_label_$month')), findsOneWidget);
    }
  });
}
