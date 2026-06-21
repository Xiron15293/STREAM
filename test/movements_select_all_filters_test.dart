import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
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

    final day = DateTime(2026, 6, 12, 9);
    db.addMovement(
      Movement(
        id: 'm1',
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
        id: 'm2',
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
        id: 'm3',
        title: 'Spesa Cash',
        amount: 15,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_6',
        accountId: 'acc_b',
        createdAt: day.add(const Duration(minutes: 2)),
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

  Future<void> applyNoAccounts(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('movements_account_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_account_filter_all_option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_account_filter_apply')));
    await tester.pumpAndSettle();
  }

  Future<void> applyNoCategories(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('movements_category_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('movements_category_filter_all_option')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('movements_category_filter_apply')));
    await tester.pumpAndSettle();
  }

  Future<void> restoreAllAccounts(WidgetTester tester) async {
    await applyNoAccounts(tester);
  }

  Future<void> restoreAllCategories(WidgetTester tester) async {
    await applyNoCategories(tester);
  }

  testWidgets('movements account deselect all shows empty list', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await applyNoAccounts(tester);

    expect(find.text('Nessun conto'), findsOneWidget);
    expect(find.text('Spesa Intesa'), findsNothing);
    expect(find.text('Entrata Intesa'), findsNothing);
    expect(find.text('Spesa Cash'), findsNothing);
  });

  testWidgets('movements category deselect all shows empty list', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await applyNoCategories(tester);

    expect(find.text('Nessuna categoria'), findsOneWidget);
    expect(find.text('Spesa Intesa'), findsNothing);
    expect(find.text('Entrata Intesa'), findsNothing);
    expect(find.text('Spesa Cash'), findsNothing);
  });

  testWidgets('select all restores full list for accounts and categories', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await applyNoAccounts(tester);
    await restoreAllAccounts(tester);
    expect(find.text('Tutti i conti'), findsOneWidget);
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsOneWidget);
    expect(find.text('Spesa Cash'), findsOneWidget);

    await applyNoCategories(tester);
    await restoreAllCategories(tester);
    expect(find.text('Tutte le categorie'), findsOneWidget);
    expect(find.text('Spesa Intesa'), findsOneWidget);
    expect(find.text('Entrata Intesa'), findsOneWidget);
    expect(find.text('Spesa Cash'), findsOneWidget);
  });

  testWidgets('Uscite and Entrate sections remain visible in category sheet', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db, profileId: 'profile_a');

    await tester.tap(find.byKey(const Key('movements_category_filter_button')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('movements_category_filter_sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('Uscite')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Entrate')),
      findsOneWidget,
    );
  });
}
