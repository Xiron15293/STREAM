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
    String? mode,
  }) async {
    SharedPreferences.setMockInitialValues(
      mode == null ? <String, Object>{} : {'movements_view_mode': mode},
    );
    await tester.pumpWidget(MaterialApp(home: MovementsScreen(db: db)));
    await tester.pumpAndSettle();
  }

  Future<void> expectHeatmapConfigureButtonVisible(WidgetTester tester) async {
    final cardButton = find.byKey(
      const Key('movements_card_configure_heatmap_button'),
    );
    final dayButton = find.byKey(
      const Key('movements_day_configure_heatmap_button'),
    );
    final screenScrollable = find.byKey(const Key('movements_layout_heatmap'));

    for (var attempt = 0;
        attempt < 5 &&
            cardButton.evaluate().isEmpty &&
            dayButton.evaluate().isEmpty &&
            screenScrollable.evaluate().isNotEmpty;
        attempt++) {
      await tester.drag(screenScrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
    }

    expect(cardButton.evaluate().isNotEmpty || dayButton.evaluate().isNotEmpty, isTrue);
  }

  void expectNoLegacyMovementLayouts() {
    expect(find.byKey(const Key('movements_layout_list')), findsNothing);
    expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);
  }

  test(
    'saving movement view preference persists heatmap as the only configurable mode',
    () async {
      await PreferencesService.saveMovementsViewMode(MovementsViewMode.list);

      final mode = await PreferencesService.loadMovementsViewMode();
      expect(mode, MovementsViewMode.heatmap);
      expect(PreferencesService.movementsViewModeNotifier.value, mode);
    },
  );

  test('legacy movement view values fallback safely to heatmap', () async {
    SharedPreferences.setMockInitialValues({
      'movements_view_mode': 'listHeatmap',
    });
    expect(
      await PreferencesService.loadMovementsViewMode(),
      MovementsViewMode.heatmap,
    );

    SharedPreferences.setMockInitialValues({
      'movements_view_mode': 'list',
    });
    expect(
      await PreferencesService.loadMovementsViewMode(),
      MovementsViewMode.heatmap,
    );

    SharedPreferences.setMockInitialValues({
      'movements_view_mode': 'calendar',
    });
    expect(
      await PreferencesService.loadMovementsViewMode(),
      MovementsViewMode.heatmap,
    );

    SharedPreferences.setMockInitialValues({
      'movements_view_mode': 'advancedHeatmap',
    });
    expect(
      await PreferencesService.loadMovementsViewMode(),
      MovementsViewMode.heatmap,
    );
  });

  testWidgets('settings screen exposes only Configura heatmap for movements', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(MaterialApp(home: SettingsScreen(db: seededDb())));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_heatmap_configure_tile')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Vista movimenti predefinita'), findsNothing);
    expect(find.text('Modalità vista movimenti'), findsNothing);
    expect(find.byKey(const Key('movements_view_mode_setting')), findsNothing);
    expect(find.byKey(const Key('settings_heatmap_configure_tile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_heatmap_configure_tile')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('heatmap_settings_screen')), findsOneWidget);
    expect(find.text('Configura heatmap'), findsOneWidget);
  });

  testWidgets(
    'legacy listHeatmap preference does not restore list or calendar UI and keeps movements in heatmap mode',
    (tester) async {
      await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

      expectNoLegacyMovementLayouts();
      expect(find.byKey(const Key('movements_layout_heatmap')), findsOneWidget);
      expect(find.text('Vista movimenti predefinita'), findsNothing);
      expect(find.text('Modalità vista movimenti'), findsNothing);
      expect(find.text('Vista calendario predefinita'), findsNothing);
      expect(
        find.byKey(const Key('movements_open_calendar_default_settings')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('movements_card_configure_heatmap_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'legacy listHeatmap preference does not make settings show old movement view controls',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'movements_view_mode': 'listHeatmap',
      });

      await tester.pumpWidget(MaterialApp(home: SettingsScreen(db: seededDb())));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_heatmap_configure_tile')),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Vista movimenti predefinita'), findsNothing);
      expect(find.text('Modalità vista movimenti'), findsNothing);
      expect(find.byKey(const Key('movements_view_mode_setting')), findsNothing);
      expect(find.byKey(const Key('settings_heatmap_configure_tile')), findsOneWidget);
    },
  );

  testWidgets(
    'movements heatmap shows Configura heatmap for all periods and opens the same screen',
    (tester) async {
      await pumpMovements(tester, seededDb(), mode: 'heatmap');

      expectNoLegacyMovementLayouts();
      await expectHeatmapConfigureButtonVisible(tester);

      await tester.tap(find.text('Giorno'));
      await tester.pumpAndSettle();
      expectNoLegacyMovementLayouts();

      await tester.tap(find.text('Sett.'));
      await tester.pumpAndSettle();
      expectNoLegacyMovementLayouts();

      await tester.tap(find.text('Mese'));
      await tester.pumpAndSettle();
      expectNoLegacyMovementLayouts();

      await tester.tap(find.text('Anno'));
      await tester.pumpAndSettle();
      expectNoLegacyMovementLayouts();

      await tester.tap(find.text('Intervallo'));
      await tester.pumpAndSettle();
      expect(find.text('Seleziona intervallo'), findsOneWidget);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expectNoLegacyMovementLayouts();

      final configureButton = find.byKey(
        const Key('movements_card_configure_heatmap_button'),
      ).evaluate().isNotEmpty
          ? find.byKey(const Key('movements_card_configure_heatmap_button'))
          : find.byKey(const Key('movements_day_configure_heatmap_button'));

      await tester.tap(configureButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('heatmap_settings_screen')), findsOneWidget);
      expect(find.byKey(const Key('heatmap_settings_section')), findsOneWidget);
      expect(find.byKey(const Key('heatmap_primary_metric')), findsOneWidget);
      expect(find.text('Metrica principale: Totale uscite'), findsOneWidget);
    },
  );
}
