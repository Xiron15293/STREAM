import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/screens/movements_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.showNotesNotifier.value = false;
    PreferencesService.movementsAccountFilterIdsNotifier.value = null;
    PreferencesService.movementsCategoryFilterIdsNotifier.value = null;
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.archiveAccount(defaultAccountId);
    final createdAt = DateTime.now();
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
    await db.addAccount(
      Account(
        id: 'acc_c',
        name: 'Carta',
        type: AccountType.card,
        createdAt: createdAt,
      ),
    );

    final day = DateTime(createdAt.year, createdAt.month, 12, 9);
    db.addMovement(
      Movement(
        id: 'm_a_food',
        title: 'Spesa Intesa',
        amount: 20,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: 'acc_a',
        createdAt: day,
      ),
    );
    db.addMovement(
      Movement(
        id: 'm_a_income',
        title: 'Entrata Intesa',
        amount: 50,
        type: MovementType.income,
        date: day,
        categoryId: 'inc_1',
        accountId: 'acc_a',
        createdAt: day.add(const Duration(minutes: 1)),
      ),
    );
    db.addMovement(
      Movement(
        id: 'm_c_food',
        title: 'Spesa Carta',
        amount: 15,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: 'acc_c',
        createdAt: day.add(const Duration(minutes: 2)),
      ),
    );
    db.addMovement(
      Movement(
        id: 'm_transfer_ab',
        title: 'Transfer A-B',
        amount: 30,
        type: MovementType.transfer,
        date: day,
        categoryId: '',
        accountId: 'acc_a',
        destinationAccountId: 'acc_b',
        createdAt: day.add(const Duration(minutes: 3)),
      ),
    );

    return db;
  }

  Future<void> pumpMovements(
    WidgetTester tester,
    AppDatabase db, {
    required String profileId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
        ),
        home: MovementsScreen(db: db, activeProfileId: profileId),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectAccounts(
    WidgetTester tester,
    AppDatabase db,
    List<String> accountIds,
  ) async {
    await tester.tap(find.byKey(const Key('movements_account_filter_button')));
    await tester.pumpAndSettle();

    final activeAccounts = db.accounts
        .where((account) => !account.archived)
        .map((account) => account.id)
        .toList();

    if (accountIds.isEmpty) {
      await tester.tap(
        find.byKey(const Key('movements_account_filter_all_option')),
      );
      await tester.pumpAndSettle();
    } else {
      await tester.tap(
        find.byKey(const Key('movements_account_filter_all_option')),
      );
      await tester.pumpAndSettle();
      for (final accountId in activeAccounts) {
        if (accountIds.contains(accountId)) continue;
        await tester.tap(
          find.byKey(Key('movements_account_filter_option_$accountId')),
        );
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.byKey(const Key('movements_account_filter_apply')));
    await tester.pumpAndSettle();
  }

  Future<void> selectCategories(
    WidgetTester tester,
    AppDatabase db,
    List<String> categoryIds,
  ) async {
    await tester.tap(find.byKey(const Key('movements_category_filter_button')));
    await tester.pumpAndSettle();

    final activeCategories = db.categories
        .where((category) => !category.archived)
        .toList();

    if (categoryIds.isEmpty) {
      await tester.tap(
        find.byKey(const Key('movements_category_filter_all_option')),
      );
      await tester.pumpAndSettle();
    } else {
      await tester.tap(
        find.byKey(const Key('movements_category_filter_all_option')),
      );
      await tester.pumpAndSettle();
      // Deselect expense categories (visible at top)
      for (final category in activeCategories) {
        if (categoryIds.contains(category.id)) continue;
        if (category.type == MovementType.expense) {
          await tester.tap(
            find.byKey(Key('movements_category_filter_option_${category.id}')),
          );
          await tester.pumpAndSettle();
        }
      }
      // Scroll to show income categories
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.last, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      // Deselect income categories
      for (final category in activeCategories) {
        if (categoryIds.contains(category.id)) continue;
        if (category.type == MovementType.income) {
          await tester.tap(
            find.byKey(Key('movements_category_filter_option_${category.id}')),
          );
          await tester.pumpAndSettle();
        }
      }
    }

    await tester.tap(find.byKey(const Key('movements_category_filter_apply')));
    await tester.pumpAndSettle();
  }

  Finder chipLabel(Key chipKey, String text) => find.descendant(
        of: find.byKey(chipKey),
        matching: find.text(text),
      );

  testWidgets('default shows all movements', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsOneWidget);
    expect(find.text('Spesa Carta'), findsOneWidget);
    expect(find.text('Transfer A-B'), findsOneWidget);
  });

  testWidgets('account filter filters normal movements', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectAccounts(tester, db, ['acc_c']);

    expect(find.text('Spesa Carta'), findsOneWidget);
    expect(find.text('Spesa Intesa'), findsNothing);
    expect(find.text('Entrata Intesa'), findsNothing);
    expect(find.text('Transfer A-B'), findsNothing);
  });

  testWidgets('account filter includes transfers by source or destination', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectAccounts(tester, db, ['acc_a']);
    expect(find.text('Transfer A-B'), findsOneWidget);

    await selectAccounts(tester, db, ['acc_b']);
    expect(find.text('Transfer A-B'), findsOneWidget);

    await selectAccounts(tester, db, ['acc_c']);
    expect(find.text('Transfer A-B'), findsNothing);
  });

  testWidgets('category filter filters normal movements', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectCategories(tester, db, ['inc_1']);

    expect(find.text('Entrata Intesa'), findsOneWidget);
    expect(find.text('Spesa Intesa'), findsNothing);
    expect(find.text('Spesa Carta'), findsNothing);
  });

  testWidgets('category filter excludes uncategorized transfers', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectCategories(tester, db, ['exp_1']);

    expect(find.text('Transfer A-B'), findsNothing);
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Spesa Carta'), findsOneWidget);
  });

  testWidgets('account + category filter uses AND', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectAccounts(tester, db, ['acc_a']);
    await selectCategories(tester, db, ['exp_1']);

    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsNothing);
    expect(find.text('Spesa Carta'), findsNothing);
    expect(find.text('Transfer A-B'), findsNothing);
  });

  testWidgets('filter labels update', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    expect(find.text('Tutti i conti'), findsOneWidget);
    expect(find.text('Tutte le categorie'), findsOneWidget);

    await selectAccounts(tester, db, ['acc_a', 'acc_b']);
    await selectCategories(tester, db, ['exp_1', 'inc_1']);

    expect(
      chipLabel(
        const Key('movements_account_filter_button'),
        '2 conti selezionati',
      ),
      findsOneWidget,
    );
    expect(
      chipLabel(
        const Key('movements_category_filter_button'),
        '2 categorie selezionate',
      ),
      findsOneWidget,
    );
  });

  testWidgets('filters are profile-scoped', (tester) async {
    final db = await seededDb();
    await PreferencesService.saveMovementsAccountFilterIds(
      {'acc_a'},
      profileId: 'profile_a',
    );
    await PreferencesService.saveMovementsAccountFilterIds(
      {'acc_b'},
      profileId: 'profile_b',
    );

    await pumpMovements(tester, db, profileId: 'profile_a');
    expect(
      chipLabel(const Key('movements_account_filter_button'), 'Intesa'),
      findsOneWidget,
    );

    await pumpMovements(tester, db, profileId: 'profile_b');
    expect(
      chipLabel(const Key('movements_account_filter_button'), 'Cash'),
      findsOneWidget,
    );
    expect(
      chipLabel(const Key('movements_account_filter_button'), 'Intesa'),
      findsNothing,
    );
  });

  testWidgets('invalid IDs sanitized', (tester) async {
    SharedPreferences.setMockInitialValues({
      'movements_filter_account_ids_profile_a': ['acc_a', 'ghost_acc'],
      'movements_filter_category_ids_profile_a': ['exp_1', 'ghost_cat'],
    });
    final db = await seededDb();

    await pumpMovements(tester, db, profileId: 'profile_a');

    expect(
      chipLabel(const Key('movements_account_filter_button'), 'Intesa'),
      findsOneWidget,
    );
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('movements_filter_account_ids_profile_a'),
      ['acc_a'],
    );
    expect(
      prefs.getStringList('movements_filter_category_ids_profile_a'),
      ['exp_1'],
    );
  });

  testWidgets(
    'category filter sheet groups categories by Uscite and Entrate',
    (tester) async {
      final db = await seededDb();
      await pumpMovements(tester, db, profileId: 'profile_a');

      await tester.tap(
        find.byKey(const Key('movements_category_filter_button')),
      );
      await tester.pumpAndSettle();

      final sheet = find.byKey(
        const Key('movements_category_filter_sheet'),
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Uscite'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Entrate'),
        ),
        findsOneWidget,
      );

      expect(find.byKey(const Key('movements_category_filter_option_exp_1')),
          findsOneWidget);
      expect(find.byKey(const Key('movements_category_filter_option_exp_6')),
          findsOneWidget);
      expect(find.byKey(const Key('movements_category_filter_option_inc_1')),
          findsOneWidget);
      expect(find.byKey(const Key('movements_category_filter_option_inc_4')),
          findsOneWidget);
    },
  );

  testWidgets('can select mixed income and expense categories',
      (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectCategories(tester, db, ['exp_1', 'inc_1']);

    expect(
      chipLabel(
        const Key('movements_category_filter_button'),
        '2 categorie selezionate',
      ),
      findsOneWidget,
    );
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsOneWidget);
    expect(find.text('Spesa Carta'), findsOneWidget);
  });

  testWidgets('all option still resets category filter', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectCategories(tester, db, ['exp_1', 'inc_1']);
    expect(
      chipLabel(
        const Key('movements_category_filter_button'),
        '2 categorie selezionate',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('movements_category_filter_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movements_category_filter_all_option')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movements_category_filter_apply')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tutte le categorie'), findsOneWidget);
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsOneWidget);
    expect(find.text('Transfer A-B'), findsOneWidget);
  });

  testWidgets('transfer behavior unchanged with category filter',
      (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await selectCategories(tester, db, ['exp_1']);

    expect(find.text('Transfer A-B'), findsNothing);
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Spesa Carta'), findsOneWidget);
  });
}
