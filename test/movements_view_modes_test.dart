import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
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

  Future<void> pumpMovements(WidgetTester tester, AppDatabase db) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(home: MovementsScreen(db: db)));
    await tester.pumpAndSettle();
  }

  void expectNoLegacyMovementLayouts() {
    expect(find.byKey(const Key('movements_layout_list')), findsNothing);
    expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);
  }

  testWidgets(
    'settings screen exposes only Configura heatmap for movements',
    (tester) async {
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
      expect(
        find.byKey(const Key('settings_heatmap_configure_tile')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('settings_heatmap_configure_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('heatmap_settings_screen')), findsOneWidget);
      expect(find.text('Configura heatmap'), findsOneWidget);
    },
  );

  testWidgets(
    'movements screen renders heatmap layout and no legacy list/calendar layouts',
    (tester) async {
      await pumpMovements(tester, seededDb());

      expectNoLegacyMovementLayouts();
      expect(find.byKey(const Key('movements_layout_heatmap')), findsOneWidget);
      expect(find.text('Vista movimenti predefinita'), findsNothing);
      expect(find.text('Modalità vista movimenti'), findsNothing);
      expect(find.text('Vista calendario predefinita'), findsNothing);
      expect(
        find.byKey(const Key('movements_open_calendar_default_settings')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'movements screen shows heatmap for all periods and opens configure screen',
    (tester) async {
      await pumpMovements(tester, seededDb());

      expectNoLegacyMovementLayouts();

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

      final configureButton =
          find
              .byKey(const Key('movements_card_configure_heatmap_button'))
              .evaluate()
              .isNotEmpty
          ? find.byKey(const Key('movements_card_configure_heatmap_button'))
          : find.byKey(const Key('movements_day_configure_heatmap_button'));

      await tester.ensureVisible(configureButton);
      await tester.pumpAndSettle();
      await tester.tap(configureButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('heatmap_settings_screen')), findsOneWidget);
      expect(find.byKey(const Key('heatmap_settings_section')), findsOneWidget);
      expect(find.byKey(const Key('heatmap_primary_metric')), findsOneWidget);
      expect(find.text('Metrica principale: Totale uscite'), findsOneWidget);
    },
  );
}
