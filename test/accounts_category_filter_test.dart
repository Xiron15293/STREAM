import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/accounts_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.accountsCategoryFilterIdsNotifier.value = null;
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
        initialBalance: 100,
        createdAt: now,
      ),
    );
    await db.addAccount(
      Account(
        id: 'acc_b',
        name: 'Cash',
        type: AccountType.cash,
        initialBalance: 10,
        createdAt: now,
      ),
    );

    final day = DateTime(now.year, now.month, 12, 9);
    await db.addMovement(
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
    await db.addMovement(
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
    await db.addMovement(
      Movement(
        id: 'm_transfer_ab',
        title: 'Transfer A-B',
        amount: 30,
        type: MovementType.transfer,
        date: day,
        categoryId: '',
        accountId: 'acc_a',
        destinationAccountId: 'acc_b',
        createdAt: day.add(const Duration(minutes: 2)),
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
        home: AccountsScreen(db: db, activeProfileId: profileId),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder withinCard(String accountId, Finder inner) => find.descendant(
    of: find.byKey(Key('account_card_$accountId')),
    matching: inner,
  );

  testWidgets('default label is all categories', (tester) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    expect(find.text('Tutte le categorie'), findsOneWidget);
  });

  testWidgets('category filter changes period stats but not real balance', (
    tester,
  ) async {
    final db = await seededDb();
    await PreferencesService.saveAccountsCategoryFilterIds({
      'exp_1',
    }, profileId: 'profile_a');
    await pumpScreen(tester, db, profileId: 'profile_a');

    final balanceBefore = tester.widget<Text>(
      withinCard('acc_a', find.byKey(const Key('account_current_balance'))),
    );

    expect(withinCard('acc_a', find.text('1')), findsWidgets);

    final balanceAfter = tester.widget<Text>(
      withinCard('acc_a', find.byKey(const Key('account_current_balance'))),
    );
    expect(balanceAfter.data, balanceBefore.data);

    await tester.tap(find.byKey(const Key('account_card_acc_a')));
    await tester.pumpAndSettle();
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsNothing);
    expect(find.text('Transfer A-B'), findsNothing);
  });

  testWidgets('category sheet groups expense and income sections', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    await tester.tap(find.byKey(const Key('accounts_category_filter_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('accounts_category_filter_expense_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('accounts_category_filter_income_section')),
      findsOneWidget,
    );
    expect(find.text('Categorie'), findsOneWidget);
    expect(
      find.text('Puoi combinare categorie di uscita e di entrata.'),
      findsOneWidget,
    );
    expect(find.text('Il saldo reale del conto non cambia.'), findsOneWidget);
  });
}
