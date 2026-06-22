import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/screens/dashboard_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
    PreferencesService.kpiStyleNotifier.value = 'minimal';
    PreferencesService.netWorthAccountIdsNotifier.value = null;
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
        initialBalance: 10,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'acc_b',
        name: 'Cash',
        type: AccountType.cash,
        initialBalance: 20,
        createdAt: createdAt,
      ),
    );
    return db;
  }

  Future<void> pumpDashboard(
    WidgetTester tester,
    AppDatabase db, {
    required String profileId,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
        ),
        home: DashboardScreen(db: db, activeProfileId: profileId),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder heroText(String text) => find.descendant(
        of: find.byKey(const Key('dashboard_hero_networth_card')),
        matching: find.text(text),
      );

  Future<void> toggleAllAccounts(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const Key('dashboard_net_worth_account_filter_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('dashboard_net_worth_all_accounts_option')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('dashboard_net_worth_account_filter_apply')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dashboard default is Tutti i conti', (tester) async {
    final db = await seededDb();
    await pumpDashboard(tester, db, profileId: 'profile_a');

    expect(heroText('Tutti i conti'), findsOneWidget);
    expect(heroText('+30.00 €'), findsOneWidget);
  });

  testWidgets('deselect all shows Nessun conto and patrimonio 0', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpDashboard(tester, db, profileId: 'profile_a');

    await toggleAllAccounts(tester);

    expect(heroText('Nessun conto'), findsOneWidget);
    expect(heroText('+0.00 €'), findsOneWidget);
    expect(heroText('Nessun conto selezionato'), findsOneWidget);
    expect(
      heroText('Il patrimonio resta a zero finché non selezioni almeno un conto.'),
      findsOneWidget,
    );
    expect(PreferencesService.netWorthAccountIdsNotifier.value, <String>{});
  });

  testWidgets('account sheet shows standard helper copy', (tester) async {
    final db = await seededDb();
    await pumpDashboard(tester, db, profileId: 'profile_a');

    await tester.tap(
      find.byKey(const Key('dashboard_net_worth_account_filter_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conti'), findsOneWidget);
    expect(
      find.text('Tocca per selezionare o deselezionare tutti.'),
      findsOneWidget,
    );
  });

  testWidgets('second toggle all restores Tutti i conti and full patrimonio', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpDashboard(tester, db, profileId: 'profile_a');

    await toggleAllAccounts(tester);
    await toggleAllAccounts(tester);

    expect(heroText('Tutti i conti'), findsOneWidget);
    expect(heroText('+30.00 €'), findsOneWidget);
    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
  });

  testWidgets('reset returns dashboard selection to Tutti i conti', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpDashboard(tester, db, profileId: 'profile_a');

    await toggleAllAccounts(tester);
    await PreferencesService.clearForReset(activeProfileId: 'profile_a');
    final prefs = await SharedPreferences.getInstance();

    expect(
      prefs.containsKey('dashboard_net_worth_account_ids_profile_a'),
      isFalse,
    );
    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
  });

  testWidgets('dashboard select all semantics stay profile-scoped', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpDashboard(tester, db, profileId: 'profile_a');
    await toggleAllAccounts(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('dashboard_net_worth_account_ids_profile_a'),
      <String>[],
    );
    expect(
      prefs.getStringList('dashboard_net_worth_account_ids_profile_b'),
      isNull,
    );
  });
}
