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
    PreferencesService.chartStyleNotifier.value = 'technical';
    PreferencesService.chartsAccountFilterIdsNotifier.value = null;
    PreferencesService.chartsCategoryFilterIdsNotifier.value = null;
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.archiveAccount(defaultAccountId);
    final day = DateTime(2026, 6, 21, 10);
    await db.addAccount(
      Account(
        id: 'acc_a',
        name: 'Intesa',
        type: AccountType.bank,
        initialBalance: 100,
        createdAt: day,
      ),
    );
    await db.addAccount(
      Account(
        id: 'acc_b',
        name: 'Cash',
        type: AccountType.cash,
        initialBalance: 50,
        createdAt: day,
      ),
    );

    db.addMovement(
      Movement(
        id: 'm_exp_a',
        title: 'Spesa Intesa',
        amount: 20,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: 'acc_a',
        payee: 'Coop',
        createdAt: day,
      ),
    );
    db.addMovement(
      Movement(
        id: 'm_inc_a',
        title: 'Entrata Intesa',
        amount: 70,
        type: MovementType.income,
        date: day,
        categoryId: 'inc_1',
        accountId: 'acc_a',
        payee: 'Azienda',
        createdAt: day.add(const Duration(minutes: 1)),
      ),
    );
    db.addMovement(
      Movement(
        id: 'm_exp_b_food',
        title: 'Spesa Cash',
        amount: 15,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: 'acc_b',
        payee: 'Bar',
        createdAt: day.add(const Duration(minutes: 2)),
      ),
    );
    db.addMovement(
      Movement(
        id: 'm_exp_b_auto',
        title: 'Auto Cash',
        amount: 35,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_3',
        accountId: 'acc_b',
        payee: 'Benzina',
        createdAt: day.add(const Duration(minutes: 3)),
      ),
    );
    db.addMovement(
      Movement(
        id: 'm_transfer',
        title: 'Transfer',
        amount: 25,
        type: MovementType.transfer,
        date: day,
        categoryId: '',
        accountId: 'acc_a',
        destinationAccountId: 'acc_b',
        createdAt: day.add(const Duration(minutes: 4)),
      ),
    );
    return db;
  }

  Future<void> pumpCharts(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
          chartStyle: StreamChartStyleId.fromString(
            PreferencesService.chartStyleNotifier.value,
          ),
        ),
        home: ChartsScreen(db: db, activeProfileId: 'profile_a'),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSection(WidgetTester tester, String label) async {
    final finder = find.text(label).first;
    await tester.ensureVisible(finder);
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  Future<void> selectChartAccounts(
    WidgetTester tester,
    List<String> ids,
  ) async {
    await tester.tap(find.byKey(const Key('charts_account_filter_button')));
    await tester.pumpAndSettle();
    final allOption = find.byKey(const Key('charts_account_filter_all_option'));
    final allIsSelected = find.descendant(
      of: allOption,
      matching: find.byIcon(Icons.check_box),
    ).evaluate().isNotEmpty;

    if (ids.isEmpty) {
      await tester.tap(allOption);
      await tester.pumpAndSettle();
      if (!allIsSelected) {
        await tester.tap(allOption);
        await tester.pumpAndSettle();
      }
    } else {
      if (!allIsSelected) {
        await tester.tap(allOption);
        await tester.pumpAndSettle();
      }
      for (final accountId in ['acc_a', 'acc_b']) {
        if (ids.contains(accountId)) continue;
        await tester.tap(find.byKey(Key('charts_account_filter_option_$accountId')));
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.byKey(const Key('charts_account_filter_apply')));
    await tester.pumpAndSettle();
  }

  Future<void> selectChartCategories(
    WidgetTester tester,
    List<String> ids,
  ) async {
    await tester.tap(find.byKey(const Key('charts_category_filter_button')));
    await tester.pumpAndSettle();
    final allOption = find.byKey(const Key('charts_category_filter_all_option'));
    final allIsSelected = find.descendant(
      of: allOption,
      matching: find.byIcon(Icons.check_box),
    ).evaluate().isNotEmpty;

    if (ids.isEmpty) {
      await tester.tap(allOption);
      await tester.pumpAndSettle();
      if (!allIsSelected) {
        await tester.tap(allOption);
        await tester.pumpAndSettle();
      }
    } else {
      if (!allIsSelected) {
        await tester.tap(allOption);
        await tester.pumpAndSettle();
      }
      for (final categoryId in ['exp_1', 'exp_3', 'inc_1']) {
        if (ids.contains(categoryId)) continue;
        var finder = find.byKey(Key('charts_category_filter_option_$categoryId'));
        if (finder.evaluate().isEmpty) {
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(scrollables.last, const Offset(0, -300));
            await tester.pumpAndSettle();
            finder = find.byKey(Key('charts_category_filter_option_$categoryId'));
          }
        }
        if (finder.evaluate().isEmpty) continue;
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.byKey(const Key('charts_category_filter_apply')));
    await tester.pumpAndSettle();
  }

  testWidgets('charts default filters are all', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);

    expect(find.text('Tutti i conti'), findsOneWidget);
    expect(find.text('Tutte le categorie'), findsOneWidget);
  });

  testWidgets('charts contextual filters visibility matches section', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpCharts(tester, db);

    expect(find.byKey(const Key('charts_account_filter_button')), findsOneWidget);
    expect(find.byKey(const Key('charts_category_filter_button')), findsOneWidget);

    await openSection(tester, 'Categorie');
    expect(find.byKey(const Key('charts_account_filter_button')), findsOneWidget);
    expect(find.byKey(const Key('charts_category_filter_button')), findsNothing);

    await openSection(tester, 'Conti');
    expect(find.byKey(const Key('charts_account_filter_button')), findsNothing);
    expect(find.byKey(const Key('charts_category_filter_button')), findsOneWidget);

    await openSection(tester, 'Beneficiari');
    expect(find.byKey(const Key('charts_account_filter_button')), findsOneWidget);
    expect(find.byKey(const Key('charts_category_filter_button')), findsOneWidget);
  });

  testWidgets('account filter changes categories charts data', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);
    await selectChartAccounts(tester, ['acc_a']);
    await openSection(tester, 'Categorie');

    expect(find.text('Spesa'), findsWidgets);
    expect(find.text('Auto'), findsNothing);
  });

  testWidgets('category filter changes beneficiaries charts data', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);
    await selectChartCategories(tester, ['exp_1']);
    await openSection(tester, 'Beneficiari');

    expect(find.text('Coop'), findsWidgets);
    expect(find.text('Bar'), findsWidgets);
    expect(find.text('Benzina'), findsNothing);
  });

  testWidgets('account plus category filter uses AND', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);
    await selectChartAccounts(tester, ['acc_b']);
    await selectChartCategories(tester, ['inc_1']);
    await openSection(tester, 'Movimenti');

    expect(find.text('Nessun movimento nel periodo selezionato'), findsOneWidget);
  });

  testWidgets('hidden account filter does not affect accounts charts', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpCharts(tester, db);
    await selectChartAccounts(tester, ['acc_a']);

    await openSection(tester, 'Conti');

    expect(find.byKey(const Key('charts_account_filter_button')), findsNothing);
    expect(find.text('Intesa'), findsWidgets);
    expect(find.text('Cash'), findsWidgets);
  });

  testWidgets('hidden category filter does not affect categories charts', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpCharts(tester, db);
    await selectChartCategories(tester, ['exp_1']);

    await openSection(tester, 'Categorie');

    expect(find.byKey(const Key('charts_category_filter_button')), findsNothing);
    expect(find.text('Spesa'), findsWidgets);
    expect(find.text('Auto'), findsWidgets);
  });

  testWidgets('deselect all accounts shows charts empty state', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);

    await selectChartAccounts(tester, []);

    expect(find.text('Nessun conto selezionato'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deselect all categories shows charts empty state', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);

    await selectChartCategories(tester, []);

    expect(find.text('Nessuna categoria selezionata'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden charts and chart style remain unchanged', (tester) async {
    final db = await seededDb();
    await PreferencesService.saveHiddenChartIds({'movements_cashflow'});
    await pumpCharts(tester, db);

    await selectChartAccounts(tester, ['acc_a']);
    await selectChartCategories(tester, ['exp_1']);

    expect(find.byKey(const Key('chart_card_movements_cashflow')), findsNothing);
    expect(PreferencesService.hiddenChartIdsNotifier.value, {'movements_cashflow'});
    expect(PreferencesService.chartStyleNotifier.value, 'technical');
    expect(tester.takeException(), isNull);
  });

  testWidgets('small viewport charts sections do not overflow', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final db = await seededDb();
    await pumpCharts(tester, db);

    await openSection(tester, 'Movimenti');
    expect(tester.takeException(), isNull);

    await openSection(tester, 'Categorie');
    expect(tester.takeException(), isNull);

    await openSection(tester, 'Conti');
    expect(tester.takeException(), isNull);
  });
}
