import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/categories_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.categoriesAccountFilterIdsNotifier.value = null;
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.archiveAccount(defaultAccountId);
    final now = DateTime.now();
    await db.addAccount(
      Account(
        id: 'acc_a',
        name: 'Intesa',
        type: AccountType.bank,
        createdAt: now,
      ),
    );
    await db.addAccount(
      Account(
        id: 'acc_b',
        name: 'Cash',
        type: AccountType.cash,
        createdAt: now,
      ),
    );

    final day = DateTime(now.year, now.month, 10, 9);
    await db.addMovement(
      Movement(
        id: 'm_food_a',
        title: 'Spesa Intesa',
        amount: 20,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: 'acc_a',
        createdAt: day,
      ),
    );
    await db.addMovement(
      Movement(
        id: 'm_transport_b',
        title: 'Benzina Cash',
        amount: 40,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_3',
        accountId: 'acc_b',
        createdAt: day.add(const Duration(minutes: 1)),
      ),
    );
    return db;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    AppDatabase db, {
    required String profileId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
        ),
        home: CategoriesScreen(db: db, activeProfileId: profileId),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectAccounts(
    WidgetTester tester,
    AppDatabase db,
    List<String> accountIds,
  ) async {
    await tester.tap(find.byKey(const Key('categories_account_filter_button')));
    await tester.pumpAndSettle();

    final activeAccounts = db.accounts
        .where((account) => !account.archived)
        .map((account) => account.id)
        .toList();
    final allOption = find.byKey(
      const Key('categories_account_filter_all_option'),
    );
    final allIsSelected = find
        .descendant(of: allOption, matching: find.byIcon(Icons.check_box))
        .evaluate()
        .isNotEmpty;

    if (accountIds.isEmpty) {
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
      for (final accountId in activeAccounts) {
        if (accountIds.contains(accountId)) continue;
        await tester.tap(
          find.byKey(Key('categories_account_filter_option_$accountId')),
        );
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.byKey(const Key('categories_account_filter_apply')));
    await tester.pumpAndSettle();
  }

  testWidgets('default shows all accounts and all expense categories', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    expect(find.text('Tutti i conti'), findsOneWidget);
    expect(find.byKey(const Key('category_card_exp_1')), findsOneWidget);
    expect(find.byKey(const Key('category_card_exp_3')), findsOneWidget);
  });

  testWidgets('account filter narrows visible categories', (tester) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    await selectAccounts(tester, db, ['acc_a']);

    expect(find.byKey(const Key('category_card_exp_1')), findsOneWidget);
    expect(find.byKey(const Key('category_card_exp_3')), findsNothing);
    expect(find.text('Intesa'), findsOneWidget);
  });

  testWidgets('deselect all shows empty categories state', (tester) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    await selectAccounts(tester, db, const []);

    expect(find.text('Nessun conto'), findsOneWidget);
    expect(find.text('Nessuna categoria'), findsOneWidget);
  });

  testWidgets('account sheet shows standard title and helper copy', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    await tester.tap(find.byKey(const Key('categories_account_filter_button')));
    await tester.pumpAndSettle();

    expect(find.text('Conti'), findsOneWidget);
    expect(
      find.text('Tocca per selezionare o deselezionare tutti.'),
      findsOneWidget,
    );
    expect(
      find.text('Filtri i movimenti usati per calcolare le categorie.'),
      findsOneWidget,
    );
  });
}
