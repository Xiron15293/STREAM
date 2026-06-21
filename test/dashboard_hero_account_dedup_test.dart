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
        initialBalance: 0.25,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'intesa',
        name: 'X Me Intesa San Paolo',
        type: AccountType.bank,
        initialBalance: 810.04,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'house',
        name: 'Soldi casa',
        type: AccountType.savings,
        initialBalance: 0.0,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'vacation',
        name: 'Fondo vacanze molto lungo per test layout',
        type: AccountType.savings,
        initialBalance: 14738.15,
        createdAt: createdAt,
      ),
    );
    await db.addAccount(
      Account(
        id: 'buffer',
        name: 'Buffer',
        type: AccountType.other,
        initialBalance: 0.0,
        createdAt: createdAt,
      ),
    );
    return db;
  }

  Future<void> pumpDashboard(WidgetTester tester) async {
    final db = await seededDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
        ),
        home: DashboardScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder heroText(String text) => find.descendant(
    of: find.byKey(const Key('dashboard_hero_networth_card')),
    matching: find.text(text),
  );

  testWidgets('hero shows each visible account once and collapses extras', (
    tester,
  ) async {
    await pumpDashboard(tester);
    final valueText = tester.widget<Text>(
      find.byKey(const Key('dashboard_hero_networth_value')),
    );

    expect(heroText('Patrimonio netto'), findsOneWidget);
    expect(valueText.data, '+15548.44 €');
    expect(heroText('Contante'), findsOneWidget);
    expect(heroText('X Me Intesa San Paolo'), findsOneWidget);
    expect(heroText('Soldi casa'), findsOneWidget);
    expect(heroText('+2 altri'), findsOneWidget);
    expect(
      find.byKey(const Key('dashboard_hero_more_accounts')),
      findsOneWidget,
    );

    expect(heroText('Fondo vacanze molto lungo per test layout'), findsNothing);
    expect(heroText('Buffer'), findsNothing);
    expect(heroText('PATRIMONIO'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
