import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/beneficiary_profile.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/beneficiaries_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.beneficiariesAccountFilterIdsNotifier.value = null;
    PreferencesService.beneficiariesCategoryFilterIdsNotifier.value = null;
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
    await db.addBeneficiaryProfile(
      BeneficiaryProfile(
        id: 'bp_amazon',
        key: 'amazon',
        displayName: 'Amazon Prime',
        createdAt: now,
      ),
    );

    final day = DateTime(now.year, now.month, 14, 9);
    await db.addMovement(
      Movement(
        id: 'm_amazon_a',
        title: 'Amazon Intesa',
        amount: 20,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: 'acc_a',
        payee: 'amazon',
        createdAt: day,
      ),
    );
    await db.addMovement(
      Movement(
        id: 'm_amazon_b',
        title: 'Amazon Cash',
        amount: 10,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_3',
        accountId: 'acc_b',
        payee: 'amazon',
        createdAt: day.add(const Duration(minutes: 1)),
      ),
    );
    await db.addMovement(
      Movement(
        id: 'm_salary_a',
        title: 'Salary',
        amount: 100,
        type: MovementType.income,
        date: day,
        categoryId: 'inc_1',
        accountId: 'acc_a',
        payee: 'Employer',
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
        home: BeneficiariesScreen(db: db, activeProfileId: profileId),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('default shows full beneficiary list', (tester) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    expect(find.text('Amazon Prime'), findsOneWidget);
    expect(find.text('Employer'), findsOneWidget);
  });

  testWidgets('account and category filters use AND on beneficiaries', (
    tester,
  ) async {
    final db = await seededDb();
    await PreferencesService.saveBeneficiariesAccountFilterIds({
      'acc_a',
    }, profileId: 'profile_a');
    await PreferencesService.saveBeneficiariesCategoryFilterIds({
      'exp_1',
    }, profileId: 'profile_a');
    await pumpScreen(tester, db, profileId: 'profile_a');

    expect(find.text('Amazon Prime'), findsOneWidget);
    expect(find.text('Employer'), findsNothing);

    await tester.tap(find.byKey(const Key('beneficiary_card_amazon')));
    await tester.pumpAndSettle();
    final sheet = find.byKey(const Key('beneficiary_detail_sheet'));
    expect(
      find.descendant(of: sheet, matching: find.text('Amazon Intesa')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Amazon Cash')),
      findsNothing,
    );
  });

  testWidgets('empty account selection clears beneficiary list', (
    tester,
  ) async {
    final db = await seededDb();
    await PreferencesService.saveBeneficiariesAccountFilterIds(
      <String>{},
      profileId: 'profile_a',
    );
    await pumpScreen(tester, db, profileId: 'profile_a');

    expect(find.text('Nessun conto'), findsOneWidget);
    expect(find.text('Nessun beneficiario disponibile'), findsOneWidget);
  });

  testWidgets('category sheet shows expense and income sections', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpScreen(tester, db, profileId: 'profile_a');

    await tester.tap(
      find.byKey(const Key('beneficiaries_category_filter_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('beneficiaries_category_filter_expense_section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('beneficiaries_category_filter_income_section')),
      findsOneWidget,
    );
  });
}
