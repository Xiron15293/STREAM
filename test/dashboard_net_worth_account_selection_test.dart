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

  Future<AppDatabase> seededDb({bool withArchived = false}) async {
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
    await db.addAccount(
      Account(
        id: 'vacation',
        name: 'Vacanze',
        type: AccountType.savings,
        initialBalance: 40,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'buffer',
        name: 'Buffer',
        type: AccountType.other,
        initialBalance: 50,
        createdAt: createdAt,
      ),
    );

    if (withArchived) {
      await db.addAccount(
        Account(
          id: 'legacy',
          name: 'Legacy',
          type: AccountType.bank,
          initialBalance: 999,
          createdAt: createdAt,
        ),
      );
      await db.archiveAccount('legacy');
    }

    return db;
  }

  Future<void> pumpDashboard(
    WidgetTester tester,
    AppDatabase db, {
    String? profileId,
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

  testWidgets('default null selection keeps Tutti i conti', (tester) async {
    final db = await seededDb();
    await pumpDashboard(tester, db);

    expect(heroText('Tutti i conti'), findsOneWidget);
    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two selected accounts sum only those accounts', (tester) async {
    final db = await seededDb();
    await PreferencesService.saveDashboardNetWorthAccountIds({
      'cash',
      'intesa',
    });

    await pumpDashboard(tester, db);

    expect(heroText('2 conti selezionati'), findsOneWidget);
    expect(find.text('+30.00 €'), findsWidgets);
    expect(heroText('Contante'), findsOneWidget);
    expect(heroText('Intesa'), findsOneWidget);
    expect(heroText('Casa'), findsNothing);
    expect(PreferencesService.netWorthAccountIdsNotifier.value, {
      'cash',
      'intesa',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid and archived ids are sanitized away', (tester) async {
    final db = await seededDb(withArchived: true);
    await PreferencesService.saveDashboardNetWorthAccountIds({
      'cash',
      'intesa',
      'house',
      'vacation',
      'missing',
      'legacy',
    });

    await pumpDashboard(tester, db);

    expect(heroText('4 conti selezionati'), findsOneWidget);
    expect(heroText('+1 altri'), findsOneWidget);
    expect(heroText('Legacy'), findsNothing);
    expect(PreferencesService.netWorthAccountIdsNotifier.value, {
      'cash',
      'intesa',
      'house',
      'vacation',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('all invalid ids become Nessun conto', (tester) async {
    final db = await seededDb(withArchived: true);
    await PreferencesService.saveDashboardNetWorthAccountIds({
      'missing',
      'legacy',
    });

    await pumpDashboard(tester, db);

    expect(heroText('Nessun conto'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard_hero_networth_card')),
        matching: find.text('Nessun conto selezionato'),
      ),
      findsOneWidget,
    );
    expect(PreferencesService.netWorthAccountIdsNotifier.value, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
