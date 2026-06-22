import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/screens/categories_screen.dart';
import 'package:stream_app/widgets/categories_treemap.dart';

ThemeData _testTheme() => ThemeData(useMaterial3: true).copyWith(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'category_layout': 'treemap'});
    PreferencesService.categoryLayoutNotifier.value = 'treemap';
  });

  testWidgets('treemap layout is visible and renders category blocks', (
    tester,
  ) async {
    final db = AppDatabase();
    final now = DateTime.now();
    final food = await _addCategory(db, 'Treemap Food', 0xFFE53935);

    await _addMovement(db, 'food_1', food, 42, now);
    await _pumpCategories(tester, db);

    expect(find.byKey(const Key('categories_layout_treemap')), findsOneWidget);
    expect(find.byKey(const Key('categories_treemap')), findsOneWidget);
    expect(find.byKey(const Key('categories_treemap_tile')), findsWidgets);
    expect(_treemapLabels(tester), contains('Treemap Food'));
    expect(_treemapAmounts(tester), contains('42€'));
    expect(find.byKey(const Key('categories_treemap_count')), findsWidgets);
  });

  testWidgets('treemap groups amounts by category and excludes transfers', (
    tester,
  ) async {
    final db = AppDatabase();
    final now = DateTime.now();
    final food = await _addCategory(db, 'Grouped Food', 0xFFE53935);
    final home = await _addCategory(db, 'Grouped Home', 0xFF1E88E5);

    await _addMovement(db, 'food_1', food, 20, now);
    await _addMovement(db, 'food_2', food, 30, now);
    await _addMovement(db, 'home_1', home, 15, now);
    await db.addMovement(
      Movement(
        id: 'transfer_ignored',
        title: 'Transfer ignored',
        amount: 999,
        type: MovementType.transfer,
        date: now,
        categoryId: food.id,
        accountId: defaultAccountId,
        destinationAccountId: 'another_account',
        createdAt: now,
      ),
    );

    await _pumpCategories(tester, db);

    expect(
      _treemapLabels(tester),
      containsAll(['Grouped Food', 'Grouped Home']),
    );
    expect(_treemapAmounts(tester), contains('50€'));
    expect(_treemapAmounts(tester), isNot(contains('999€')));
  });

  testWidgets('treemap respects day, month and year filters', (tester) async {
    final db = AppDatabase();
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day, 10);
    final sameMonth = DateTime(now.year, now.month, 2, 10);
    final sameYear = DateTime(now.year, now.month == 1 ? 2 : 1, 3, 10);
    final category = await _addCategory(db, 'Period Filtered', 0xFFE53935);

    await _addMovement(db, 'day', category, 10, currentDay);
    await _addMovement(db, 'month', category, 20, sameMonth);
    await _addMovement(db, 'year', category, 30, sameYear);

    await _pumpCategories(tester, db);
    expect(_treemapAmounts(tester), contains('30€'));

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(_treemapAmounts(tester), contains('10€'));

    await tester.tap(find.text('Anno'));
    await tester.pumpAndSettle();
    expect(_treemapAmounts(tester), contains('60€'));
  });

  testWidgets('treemap can render a custom interval movement set', (
    tester,
  ) async {
    final db = AppDatabase();
    final start = DateTime(2026, 2, 4, 10);
    final end = DateTime(2026, 2, 8, 10);
    final outside = DateTime(2026, 2, 12, 10);
    final food = await _addCategory(db, 'Interval Food', 0xFFE53935);
    final travel = await _addCategory(db, 'Interval Travel', 0xFF43A047);
    final filter = TimeFilter.customRange(start, end);

    await _addMovement(db, 'interval_food', food, 25, start);
    await _addMovement(db, 'interval_travel', travel, 35, end);
    await _addMovement(db, 'interval_outside', food, 90, outside);

    await _pumpTreemapWidget(
      tester,
      categories: [food, travel],
      movements: db.movements.filterByTime(filter),
    );

    expect(
      _treemapLabels(tester),
      containsAll(['Interval Food', 'Interval Travel']),
    );
    expect(_treemapAmounts(tester), containsAll(['25€', '35€']));
    expect(_treemapAmounts(tester), isNot(contains('90€')));
  });

  testWidgets('treemap sort supports total desc and name asc', (tester) async {
    final db = AppDatabase();
    final now = DateTime.now();
    final zebra = await _addCategory(db, 'Zebra Sort', 0xFFE53935);
    final alpha = await _addCategory(db, 'Alpha Sort', 0xFF43A047);

    await _addMovement(db, 'zebra', zebra, 80, now);
    await _addMovement(db, 'alpha', alpha, 10, now);

    await _pumpCategories(tester, db);
    expect(_treemapLabels(tester).first, 'Zebra Sort');

    await tester.tap(find.byKey(const Key('categories_treemap_sort_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('categories_treemap_sort_name_asc')));
    await tester.pumpAndSettle();

    expect(_treemapLabels(tester).first, 'Alpha Sort');
  });

  testWidgets('treemap sort supports count desc and total asc', (tester) async {
    final db = AppDatabase();
    final now = DateTime.now();
    final many = await _addCategory(db, 'Many Count', 0xFFE53935);
    final one = await _addCategory(db, 'One Count', 0xFF43A047);

    await _addMovement(db, 'many_1', many, 5, now);
    await _addMovement(db, 'many_2', many, 5, now);
    await _addMovement(db, 'one_1', one, 40, now);

    await _pumpCategories(tester, db);
    await tester.tap(find.byKey(const Key('categories_treemap_sort_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('categories_treemap_sort_count_desc')),
    );
    await tester.pumpAndSettle();
    expect(_treemapLabels(tester).first, 'Many Count');

    await tester.tap(find.byKey(const Key('categories_treemap_sort_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('categories_treemap_sort_total_asc')),
    );
    await tester.pumpAndSettle();
    expect(_treemapLabels(tester).first, 'Many Count');
  });

  testWidgets('treemap tile tap opens category interactive sheet', (
    tester,
  ) async {
    final db = AppDatabase();
    final now = DateTime.now();
    final food = await _addCategory(db, 'Tap Treemap', 0xFFE53935);
    await _addMovement(db, 'tap_1', food, 40, now);

    await _pumpCategories(tester, db);
    await tester.tap(find.text('Tap Treemap'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('category_interactive_sheet')), findsOneWidget);
    expect(find.byKey(const Key('category_movements_name')), findsOneWidget);
  });

  testWidgets('treemap empty state appears when period has no data', (
    tester,
  ) async {
    final db = AppDatabase();
    await _addCategory(db, 'Empty Period', 0xFFE53935);

    await _pumpCategories(tester, db);

    expect(find.byKey(const Key('categories_treemap_empty')), findsOneWidget);
    expect(find.text('Nessun dato'), findsOneWidget);
    expect(
      find.text('Modifica i filtri o il periodo per vedere altri risultati.'),
      findsOneWidget,
    );
  });

  testWidgets('treemap uses category color and excludes archived categories', (
    tester,
  ) async {
    final db = AppDatabase();
    final now = DateTime.now();
    final visible = await _addCategory(db, 'Visible Color', 0xFFE53935);
    final archived = await _addCategory(db, 'Archived Color', 0xFF43A047);

    await db.archiveCategory(archived.id);
    await _addMovement(db, 'visible', visible, 20, now);
    await _addMovement(db, 'archived', archived, 40, now);

    await _pumpCategories(tester, db);

    expect(_treemapLabels(tester), contains('Visible Color'));
    expect(_treemapLabels(tester), isNot(contains('Archived Color')));
    final material = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Visible Color'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, const Color(0xFFE53935));
  });

  testWidgets('treemap has no overflow with many categories at 800x600', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final db = AppDatabase();
    final now = DateTime.now();
    for (var i = 0; i < 28; i++) {
      final category = await _addCategory(
        db,
        'Many Category $i',
        0xFF1565C0 + i,
      );
      await _addMovement(db, 'many_$i', category, (i + 1).toDouble(), now);
    }

    await _pumpCategories(tester, db);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('categories_treemap_tile')), findsWidgets);
  });
}

Future<Category> _addCategory(AppDatabase db, String name, int color) async {
  await db.addCategory(name, MovementType.expense, color);
  return db.categories.firstWhere((category) => category.name == name);
}

Future<void> _addMovement(
  AppDatabase db,
  String id,
  Category category,
  double amount,
  DateTime date,
) {
  return db.addMovement(
    Movement(
      id: id,
      title: id,
      amount: amount,
      type: category.type,
      date: date,
      categoryId: category.id,
      accountId: defaultAccountId,
      createdAt: date,
    ),
  );
}

Future<void> _pumpCategories(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(body: CategoriesScreen(db: db)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTreemapWidget(
  WidgetTester tester, {
  required List<Category> categories,
  required List<Movement> movements,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 420,
          height: 620,
          child: CategoriesTreemap(
            categories: categories,
            movements: movements,
            onCategoryTap: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _treemapLabels(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.byKey(const Key('categories_treemap_label'), skipOffstage: false),
      )
      .map((text) => text.data ?? '')
      .where((text) => text.isNotEmpty)
      .toList();
}

List<String> _treemapAmounts(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.byKey(const Key('categories_treemap_amount'), skipOffstage: false),
      )
      .map((text) => text.data ?? '')
      .where((text) => text.isNotEmpty)
      .toList();
}
