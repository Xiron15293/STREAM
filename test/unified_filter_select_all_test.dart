import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/charts_screen.dart';
import 'package:stream_app/screens/movements_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.movementsAccountFilterIdsNotifier.value = null;
    PreferencesService.movementsCategoryFilterIdsNotifier.value = null;
    PreferencesService.chartsAccountFilterIdsNotifier.value = null;
    PreferencesService.chartsCategoryFilterIdsNotifier.value = null;
    PreferencesService.hiddenChartIdsNotifier.value = {};
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.archiveAccount(defaultAccountId);
    final createdAt = DateTime(2026, 6, 21);
    await db.addAccount(
      Account(
        id: 'acc_a',
        name: 'Intesa',
        type: AccountType.bank,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'acc_b',
        name: 'Cash',
        type: AccountType.cash,
        createdAt: createdAt,
      ),
    );
    db.addMovement(
      Movement(
        id: 'm1',
        title: 'Spesa Intesa',
        amount: 10,
        type: MovementType.expense,
        date: createdAt,
        categoryId: 'exp_1',
        accountId: 'acc_a',
        createdAt: createdAt,
      ),
    );
    return db;
  }

  Future<void> pumpMovements(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
        ),
        home: MovementsScreen(db: db, activeProfileId: 'profile_a'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpCharts(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
        ),
        home: ChartsScreen(db: db, activeProfileId: 'profile_a'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('movements account all option toggles all and none', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db);

    await tester.tap(find.byKey(const Key('movements_account_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_account_filter_all_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_account_filter_apply')));
    await tester.pumpAndSettle();

    expect(find.text('Nessun conto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('movements_account_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_account_filter_all_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_account_filter_apply')));
    await tester.pumpAndSettle();

    expect(find.text('Tutti i conti'), findsOneWidget);
  });

  testWidgets('movements category cancel does not save but apply does', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db);

    await tester.tap(find.byKey(const Key('movements_category_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movements_category_filter_all_option')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_category_filter_cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Tutte le categorie'), findsOneWidget);

    await tester.tap(find.byKey(const Key('movements_category_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movements_category_filter_all_option')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_category_filter_apply')));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna categoria'), findsOneWidget);
  });

  testWidgets('charts filters use same apply/cancel semantics', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);

    await tester.tap(find.byKey(const Key('charts_account_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('charts_account_filter_all_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('charts_account_filter_cancel')));
    await tester.pumpAndSettle();

    expect(find.text('Tutti i conti'), findsOneWidget);

    await tester.tap(find.byKey(const Key('charts_account_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('charts_account_filter_all_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('charts_account_filter_apply')));
    await tester.pumpAndSettle();

    expect(find.text('Nessun conto'), findsOneWidget);

    await tester.tap(find.byKey(const Key('charts_category_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('charts_category_filter_all_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('charts_category_filter_apply')));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna categoria'), findsOneWidget);
  });
}
