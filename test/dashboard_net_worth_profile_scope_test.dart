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
    PreferencesService.netWorthAccountIdsNotifier.value = null;
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.archiveAccount(defaultAccountId);
    final createdAt = DateTime(2026, 6, 20);
    await db.addAccount(
      Account(
        id: 'cash',
        name: 'Contante',
        type: AccountType.cash,
        initialBalance: 10,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'intesa',
        name: 'Intesa',
        type: AccountType.bank,
        initialBalance: 20,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'house',
        name: 'Casa',
        type: AccountType.savings,
        initialBalance: 30,
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

  testWidgets('dashboard selection stays scoped to each profile', (
    tester,
  ) async {
    final db = await seededDb();
    await PreferencesService.saveDashboardNetWorthAccountIds({
      'cash',
      'intesa',
    }, profileId: 'profile_a');
    await PreferencesService.saveDashboardNetWorthAccountIds({
      'house',
    }, profileId: 'profile_b');

    await pumpDashboard(tester, db, profileId: 'profile_a');
    expect(find.text('2 conti selezionati'), findsOneWidget);
    expect(find.text('+30.00 €'), findsWidgets);

    await pumpDashboard(tester, db, profileId: 'profile_b');
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard_net_worth_account_filter_button')),
        matching: find.text('Casa'),
      ),
      findsOneWidget,
    );
    expect(find.text('+30.00 €'), findsWidgets);

    await pumpDashboard(tester, db, profileId: 'profile_c');
    expect(find.text('Tutti i conti'), findsOneWidget);
    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    expect(tester.takeException(), isNull);
  });
}
