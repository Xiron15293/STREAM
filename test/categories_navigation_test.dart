import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/widgets/movement_card.dart';

Future<void> openArchiveCategories(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bottom_nav_archive')).hitTestable());
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('archive_section_categories')).hitTestable(),
  );
  await tester.pumpAndSettle();

  final segmentedButton = tester.widget<SegmentedButton<int>>(
    find.byType(SegmentedButton<int>),
  );
  expect(segmentedButton.selected, contains(2));
}

Future<void> switchCategoryFilter(
  WidgetTester tester,
  MovementType type,
) async {
  final key = type == MovementType.income
      ? 'categories_filter_income'
      : 'categories_filter_expense';
  await tester.tap(find.byKey(Key(key)).hitTestable());
  await tester.pumpAndSettle();
}

Future<void> scrollToCategory(WidgetTester tester, String categoryId) async {
  final target = find.byKey(
    Key('category_card_$categoryId'),
    skipOffstage: false,
  );
  final listView = find.byType(ListView).first;

  for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
    await tester.drag(listView, const Offset(0, -320));
    await tester.pumpAndSettle();
  }

  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> openCategorySheet(
  WidgetTester tester,
  String categoryId, {
  MovementType? filterType,
}) async {
  await openArchiveCategories(tester);
  if (filterType != null) {
    await switchCategoryFilter(tester, filterType);
  }
  await scrollToCategory(tester, categoryId);

  final card = find.byKey(Key('category_card_$categoryId'));
  await tester.tap(card.hitTestable());
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('category_movements_name')), findsOneWidget);
}

List<MovementCard> _movementCards(WidgetTester tester) {
  return tester
      .widgetList<MovementCard>(find.byType(MovementCard, skipOffstage: false))
      .toList();
}

List<String> _movementTitles(WidgetTester tester) {
  return _movementCards(tester).map((card) => card.movement.title).toList();
}

void _expectMovementTitles(WidgetTester tester, List<String> titles) {
  final movementTitles = _movementTitles(tester);
  for (final title in titles) {
    expect(movementTitles, contains(title));
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({'show_notes': true});
  });

  testWidgets(
    'Tocca categoria attiva apre movimenti categoria e filtra per tipo',
    (WidgetTester tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final secondDay = DateTime(now.year, now.month, 2);
      final otherMonth = now.month == 12 ? 11 : now.month + 1;
      final otherMonthDay3 = DateTime(now.year, otherMonth, 3);

      await db.addCategory('Spese QA', MovementType.expense, 0xFF4285F4);
      await db.addCategory('Entrate QA', MovementType.income, 0xFF66BB6A);
      final incomeCategory = db.categories.firstWhere(
        (c) => c.name == 'Entrate QA',
      );

      await db.addMovement(
        Movement(
          id: 'exp_1',
          title: 'Entrata uno',
          amount: 10,
          type: MovementType.income,
          date: firstDay,
          categoryId: incomeCategory.id,
          accountId: defaultAccountId,
          note: 'nota entrata uno',
          createdAt: firstDay,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'exp_2',
          title: 'Entrata due',
          amount: 20,
          type: MovementType.income,
          date: secondDay,
          categoryId: incomeCategory.id,
          accountId: defaultAccountId,
          note: 'nota entrata due',
          createdAt: secondDay,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'exp_3',
          title: 'Entrata anno',
          amount: 30,
          type: MovementType.income,
          date: otherMonthDay3,
          categoryId: incomeCategory.id,
          accountId: defaultAccountId,
          note: 'nota entrata anno',
          createdAt: otherMonthDay3,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'inc_1',
          title: 'Spesa esclusa',
          amount: 50,
          type: MovementType.expense,
          date: firstDay,
          categoryId: incomeCategory.id,
          accountId: defaultAccountId,
          note: 'non deve apparire',
          createdAt: firstDay,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'tr_1',
          title: 'Trasferimento escluso',
          amount: 15,
          type: MovementType.transfer,
          date: secondDay,
          categoryId: '',
          accountId: defaultAccountId,
          destinationAccountId: 'acc_other',
          createdAt: secondDay,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await openCategorySheet(
        tester,
        incomeCategory.id,
        filterType: MovementType.income,
      );

      expect(
        find.byKey(const Key('category_interactive_sheet')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('category_sheet_header')), findsOneWidget);
      expect(
        find.byKey(const Key('category_sheet_period_summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('category_sheet_add_movement_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('category_sheet_edit_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('category_sheet_archive_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('category_sheet_movements_list')),
        findsOneWidget,
      );
      expect(find.text('Movimenti categoria'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('category_movements_name')))
            .data,
        'Entrate QA',
      );
      expect(find.text('Totale entrate'), findsOneWidget);
      _expectMovementTitles(tester, ['Entrata uno', 'Entrata due']);
      expect(
        find.descendant(
          of: find.byKey(const Key('category_movements_count')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      final sheetFilter = find.byKey(
        const Key('category_movements_time_filter'),
      );

      await tester.tap(
        find.descendant(of: sheetFilter, matching: find.text('Giorno')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('category_movements_count')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      _expectMovementTitles(tester, ['Entrata uno']);

      await tester.tap(
        find.descendant(of: sheetFilter, matching: find.text('Anno')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('category_movements_count')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      _expectMovementTitles(tester, [
        'Entrata uno',
        'Entrata due',
        'Entrata anno',
      ]);

      await tester.tap(
        find.byKey(const Key('category_movements_close_button')),
      );
      await tester.pumpAndSettle();

      await openCategorySheet(
        tester,
        incomeCategory.id,
        filterType: MovementType.income,
      );
      expect(find.text('Totale entrate'), findsOneWidget);
    },
  );

  testWidgets('Interactive category sheet apre Movimento precompilato', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase();
    await db.addCategory('Entrate Azione', MovementType.income, 0xFF66BB6A);
    final category = db.categories.firstWhere(
      (c) => c.name == 'Entrate Azione',
    );

    await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    await openCategorySheet(
      tester,
      category.id,
      filterType: MovementType.income,
    );

    await tester.tap(
      find.byKey(const Key('category_sheet_add_movement_action')).hitTestable(),
    );
    await tester.pumpAndSettle();

    final typeControls = tester.widgetList<SegmentedButton<MovementType>>(
      find.byType(SegmentedButton<MovementType>),
    );
    expect(typeControls.last.selected, contains(MovementType.income));
  });

  testWidgets(
    'Categoria archiviata resta cliccabile e mostra movimenti storici',
    (WidgetTester tester) async {
      final db = AppDatabase();
      final day = DateTime(2026, 6, 4);

      await db.addCategory(
        'Categoria Archiviata QA',
        MovementType.income,
        0xFF8E24AA,
      );
      final category = db.categories.firstWhere(
        (c) => c.name == 'Categoria Archiviata QA',
      );
      await db.addMovement(
        Movement(
          id: 'arch_inc_1',
          title: 'Storico entrata',
          amount: 120,
          type: MovementType.income,
          date: day,
          categoryId: category.id,
          accountId: defaultAccountId,
          createdAt: day,
        ),
      );
      await db.archiveCategory(category.id);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await openArchiveCategories(tester);
      await switchCategoryFilter(tester, MovementType.income);
      final archivedSection = find.byKey(
        const Key('categories_archived_section'),
        skipOffstage: false,
      );
      final listView = find.byType(ListView).first;
      for (var i = 0; i < 12 && archivedSection.evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -320));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(archivedSection);
      await tester.pumpAndSettle();
      expect(archivedSection, findsOneWidget);

      await openCategorySheet(
        tester,
        category.id,
        filterType: MovementType.income,
      );

      expect(find.text('Movimenti categoria'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('category_movements_name')))
            .data,
        'Categoria Archiviata QA',
      );
      expect(find.text('Totale entrate'), findsOneWidget);
      _expectMovementTitles(tester, ['Storico entrata']);
      expect(
        find.descendant(
          of: find.byKey(const Key('category_movements_count')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Categoria senza movimenti mostra empty state', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase();
    await db.addCategory(
      'Categoria Vuota QA',
      MovementType.expense,
      0xFFEF5350,
    );
    final category = db.categories.firstWhere(
      (c) => c.name == 'Categoria Vuota QA',
    );

    await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    await openCategorySheet(tester, category.id);

    expect(find.text('Nessun movimento in questo periodo'), findsOneWidget);
  });

  test('Filtro intervallo su categoria usa TimeFilter.customRange', () async {
    final db = AppDatabase();
    await db.addCategory(
      'Categoria Intervallo QA',
      MovementType.expense,
      0xFF03A9F4,
    );
    final storedCategory = db.categories.firstWhere(
      (c) => c.name == 'Categoria Intervallo QA',
    );
    await db.addMovement(
      Movement(
        id: 'rng_1',
        title: 'Mov 1',
        amount: 5,
        type: MovementType.expense,
        date: DateTime(2026, 6, 10),
        categoryId: storedCategory.id,
        accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 10),
      ),
    );
    await db.addMovement(
      Movement(
        id: 'rng_2',
        title: 'Mov 2',
        amount: 7,
        type: MovementType.expense,
        date: DateTime(2026, 6, 15),
        categoryId: storedCategory.id,
        accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 15),
      ),
    );
    await db.addMovement(
      Movement(
        id: 'rng_3',
        title: 'Mov 3',
        amount: 9,
        type: MovementType.expense,
        date: DateTime(2026, 6, 20),
        categoryId: storedCategory.id,
        accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 20),
      ),
    );

    final filtered = db.movements
        .where(
          (m) =>
              m.categoryId == storedCategory.id &&
              m.type == storedCategory.type,
        )
        .toList()
        .filterByTime(
          TimeFilter.customRange(DateTime(2026, 6, 12), DateTime(2026, 6, 18)),
        );

    expect(filtered.map((m) => m.id).toList(), ['rng_2']);
  });
}
