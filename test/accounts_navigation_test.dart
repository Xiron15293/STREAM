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
import 'package:stream_app/screens/accounts_screen.dart';
import 'package:stream_app/screens/categories_screen.dart';
import 'package:stream_app/widgets/movement_card.dart';

DateTime _monthDay(DateTime base, int day) => DateTime(base.year, base.month, day);

DateTime _sameYearOtherMonth(DateTime base) {
  final month = base.month == 12 ? 11 : 12;
  return DateTime(base.year, month, 15);
}

Future<void> openArchiveAccounts(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bottom_nav_archive')).hitTestable());
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('archive_section_accounts')).hitTestable());
  await tester.pumpAndSettle();

  final segmentedButton = tester.widget<SegmentedButton<int>>(
    find.byType(SegmentedButton<int>),
  );
  expect(segmentedButton.selected, contains(1));
}

Future<void> scrollToAccount(WidgetTester tester, String accountId) async {
  final target = find.byKey(Key('account_card_$accountId'), skipOffstage: false);
  final scrollable = find
      .descendant(
        of: find.byType(AccountsScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  try {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: scrollable,
    );
  } catch (_) {
    for (var i = 0; i < 8 && !tester.any(target); i++) {
      await tester.drag(scrollable, const Offset(0, -320));
      await tester.pumpAndSettle();
    }
  }

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
}

Future<void> scrollToCategory(WidgetTester tester, String categoryId) async {
  final target = find.byKey(Key('category_card_$categoryId'), skipOffstage: false);
  final scrollable = find
      .descendant(
        of: find.byType(CategoriesScreen),
        matching: find.byType(Scrollable),
      )
      .first;

  try {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: scrollable,
    );
  } catch (_) {
    for (var i = 0; i < 8 && !tester.any(target); i++) {
      await tester.drag(scrollable, const Offset(0, -320));
      await tester.pumpAndSettle();
    }
  }

  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target, findsOneWidget);
}

Future<void> openAccountSheet(WidgetTester tester, String accountId) async {
  await openArchiveAccounts(tester);
  await scrollToAccount(tester, accountId);

  final card = find.byKey(Key('account_card_$accountId'));
  await tester.tap(card.hitTestable());
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('account_movements_name')), findsOneWidget);
}

List<MovementCard> _movementCards(WidgetTester tester) {
  return tester.widgetList<MovementCard>(
    find.byType(MovementCard, skipOffstage: false),
  ).toList();
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
    'Archivio mostra conti e categorie archiviati separati',
    (WidgetTester tester) async {
      final db = AppDatabase();

      await db.addAccount(
        Account(
          id: 'acc_active',
          name: 'Conto Attivo',
          type: AccountType.bank,
          createdAt: DateTime(2026, 6, 1),
        ),
      );
      await db.addAccount(
        Account(
          id: 'acc_archived',
          name: 'Conto Archiviato',
          type: AccountType.bank,
          createdAt: DateTime(2026, 6, 1),
        ),
      );
      await db.archiveAccount('acc_archived');

      await db.addCategory('Categoria Attiva', MovementType.expense, 0xFF123456);
      await db.addCategory('Categoria Archiviata', MovementType.expense, 0xFF654321);
      final activeCategoryId = db.categories.firstWhere((c) => c.name == 'Categoria Attiva').id;
      final archivedCategoryId = db.categories.firstWhere((c) => c.name == 'Categoria Archiviata').id;
      await db.archiveCategory(archivedCategoryId);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')).hitTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('archive_section_accounts')).hitTestable());
      await tester.pumpAndSettle();
      expect(
        tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected,
        contains(1),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('accounts_archived_section')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(AccountsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accounts_archived_section')), findsOneWidget);

      await scrollToAccount(tester, 'acc_active');
      expect(find.byKey(const Key('account_card_acc_active')), findsOneWidget);
      expect(find.text('Conto Attivo'), findsOneWidget);

      await scrollToAccount(tester, 'acc_archived');
      expect(find.byKey(const Key('account_card_acc_archived')), findsOneWidget);
      expect(find.text('Conto Archiviato'), findsOneWidget);

      await tester.tap(find.byKey(const Key('archive_section_categories')).hitTestable());
      await tester.pumpAndSettle();
      expect(
        tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>)).selected,
        contains(2),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('categories_archived_section')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CategoriesScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('categories_archived_section')), findsOneWidget);

      await scrollToCategory(tester, activeCategoryId);
      expect(find.byKey(Key('category_card_$activeCategoryId')), findsOneWidget);
      expect(find.text('Categoria Attiva'), findsOneWidget);

      await scrollToCategory(tester, archivedCategoryId);
      expect(find.byKey(Key('category_card_$archivedCategoryId')), findsOneWidget);
      expect(find.text('Categoria Archiviata'), findsOneWidget);
    },
  );

  testWidgets(
    'Tocca conto apre movimenti del conto e mostra riepilogo filtrato',
    (WidgetTester tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      final currentMonthDay1 = _monthDay(now, 1);
      final currentMonthDay2 = _monthDay(now, 2);
      final currentMonthDay3 = _monthDay(now, 3);
      final otherMonthSameYear = _sameYearOtherMonth(now);

      await db.addAccount(
        Account(
          id: 'acc_main',
          name: 'Conto Principale QA',
          type: AccountType.bank,
          initialBalance: 100,
          createdAt: DateTime(2026, 6, 1),
        ),
      );
      await db.addAccount(
        Account(
          id: 'acc_dest',
          name: 'Conto Destinazione QA',
          type: AccountType.bank,
          createdAt: DateTime(2026, 6, 1),
        ),
      );
      await db.addMovement(
        Movement(
          id: 'm_income',
          title: 'Entrata mese',
          amount: 50,
          type: MovementType.income,
          date: currentMonthDay1,
          categoryId: 'inc_1',
          accountId: 'acc_main',
          createdAt: currentMonthDay1,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'm_expense',
          title: 'Uscita mese',
          amount: 20,
          type: MovementType.expense,
          date: currentMonthDay2,
          categoryId: 'exp_1',
          accountId: 'acc_main',
          createdAt: currentMonthDay2,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'm_transfer',
          title: 'Trasferimento mese',
          amount: 10,
          type: MovementType.transfer,
          date: currentMonthDay3,
          categoryId: '',
          accountId: 'acc_main',
          destinationAccountId: 'acc_dest',
          createdAt: currentMonthDay3,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'm_other_month',
          title: 'Fuori periodo',
          amount: 30,
          type: MovementType.income,
          date: otherMonthSameYear,
          categoryId: 'inc_1',
          accountId: 'acc_main',
          createdAt: otherMonthSameYear,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await openAccountSheet(tester, 'acc_main');

      expect(find.text('Movimenti del conto'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('account_movements_name'))).data, 'Conto Principale QA');

      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_initial_balance')),
          matching: find.text('+100.00 €'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_income')),
          matching: find.text('+50.00 €'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_expenses')),
          matching: find.text('+20.00 €'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_transfers')),
          matching: find.text('-10.00 €'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_current_balance')),
          matching: find.text('+150.00 €'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_count')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      _expectMovementTitles(tester, ['Entrata mese', 'Uscita mese', 'Trasferimento mese']);

      await tester.tap(find.text('Giorno'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_count')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      _expectMovementTitles(tester, ['Entrata mese']);

      await tester.tap(find.text('Mese'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_count')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Anno'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_count')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Conto senza movimenti mostra empty state',
    (WidgetTester tester) async {
      final db = AppDatabase();
      await db.addAccount(
        Account(
          id: 'acc_empty',
          name: 'Conto Vuoto QA',
          type: AccountType.bank,
          createdAt: DateTime(2026, 6, 1),
        ),
      );

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await openAccountSheet(tester, 'acc_empty');

      expect(find.text('Nessun movimento in questo periodo'), findsOneWidget);
    },
  );

  testWidgets(
    'Conto archiviato resta cliccabile e mostra lo storico movimenti',
    (WidgetTester tester) async {
      final db = AppDatabase();
      final day = DateTime(2026, 6, 6);
      await db.addAccount(
        Account(
          id: 'acc_archived_click',
          name: 'Conto Archiviato Click',
          type: AccountType.bank,
          createdAt: DateTime(2026, 6, 1),
        ),
      );
      await db.addMovement(
        Movement(
          id: 'arch_m_1',
          title: 'Movimento storico',
          amount: 18,
          type: MovementType.expense,
          date: day,
          categoryId: 'exp_1',
          accountId: 'acc_archived_click',
          createdAt: day,
        ),
      );
      await db.archiveAccount('acc_archived_click');

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await openAccountSheet(tester, 'acc_archived_click');

      expect(find.text('Movimenti del conto'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('account_movements_name'))).data, 'Conto Archiviato Click');
      _expectMovementTitles(tester, ['Movimento storico']);
      expect(
        find.descendant(
          of: find.byKey(const Key('account_movements_count')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    },
  );

  test(
    'Filtro custom range su movimenti del conto usa TimeFilter.customRange',
    () async {
      final db = AppDatabase();
      final now = DateTime(2026, 6, 1);

      await db.addAccount(
        Account(
          id: 'acc_filter',
          name: 'Conto Filtro QA',
          type: AccountType.bank,
          createdAt: now,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'f1',
          title: 'Movimento 1',
          amount: 10,
          type: MovementType.income,
          date: DateTime(2026, 6, 1),
          categoryId: 'inc_1',
          accountId: 'acc_filter',
          createdAt: now,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'f2',
          title: 'Movimento 2',
          amount: 20,
          type: MovementType.expense,
          date: DateTime(2026, 6, 2),
          categoryId: 'exp_1',
          accountId: 'acc_filter',
          createdAt: now,
        ),
      );
      await db.addMovement(
        Movement(
          id: 'f3',
          title: 'Movimento 3',
          amount: 30,
          type: MovementType.transfer,
          date: DateTime(2026, 6, 3),
          categoryId: '',
          accountId: 'acc_filter',
          destinationAccountId: 'acc_default',
          createdAt: now,
        ),
      );

      final filtered = db.movements
          .where(
            (m) =>
                m.accountId == 'acc_filter' ||
                m.destinationAccountId == 'acc_filter',
          )
          .toList()
          .filterByTime(
            TimeFilter.customRange(
              DateTime(2026, 6, 2),
              DateTime(2026, 6, 3),
            ),
          );

      expect(filtered.length, 2);
      expect(filtered.map((m) => m.id).toList(), ['f3', 'f2']);
    },
  );

  group('Initial Balance / Current Balance', () {
    testWidgets('Dialog mostra saldo attuale non editabile',
      (WidgetTester tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addAccount(Account(
        id: 'acc_bal_ui',
        name: 'Bilancio UI',
        type: AccountType.bank,
        initialBalance: 100.0,
        createdAt: now,
      ));

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await openArchiveAccounts(tester);
      await scrollToAccount(tester, 'acc_bal_ui');

      // Open edit dialog
      final card = find.byKey(const Key('account_card_acc_bal_ui'));
      final popup = find.descendant(
        of: card,
        matching: find.byIcon(Icons.more_horiz),
      );
      await tester.tap(popup);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifica'));
      await tester.pumpAndSettle();

      // Saldo iniziale editable (TextField inside CalculatorAmountField)
      expect(find.byKey(const Key('account_initial_balance_field')), findsOneWidget);

      // Saldo attuale NON editabile (sezione read-only con solo Text, nessun TextField)
      expect(find.byKey(const Key('account_current_balance_section')), findsOneWidget);
      expect(find.byKey(const Key('account_current_balance_value')), findsOneWidget);
      expect(find.byKey(const Key('account_balance_info_text')), findsOneWidget);
      expect(find.text('+100.00 €'), findsAtLeastNWidgets(1));

      // current_balance_value is a Text, not a TextField (read-only)
      expect(find.byKey(const Key('account_current_balance_value')), findsOneWidget);

      // Save and close
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();

      // Card still shows after save
      expect(find.byKey(const Key('account_card_acc_bal_ui')), findsOneWidget);
    });
  });
}
