import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/screens/backup_screen.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
  });

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: StreamTheme.dark,
      home: child,
    );
  }

  testWidgets('voce Profilo non appare senza callback reale', (tester) async {
    await tester.pumpWidget(
      wrap(SettingsScreen(db: AppDatabase())),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_profile_section')), findsNothing);
    expect(find.byKey(const Key('settings_active_profile_tile')), findsNothing);
    expect(find.text('Profilo'), findsNothing);
  });

  testWidgets('iFinance import resta accessibile anche senza Profili', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(SettingsScreen(db: AppDatabase())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Backup & Restore'));
    await tester.pumpAndSettle();

    expect(find.byType(BackupScreen), findsOneWidget);
    expect(find.text('Importa CSV iFinance'), findsOneWidget);
    expect(find.byKey(const Key('backup_ifinance_import_button')), findsOneWidget);
  });

  testWidgets('voce Valuta appare e aggiorna la preferenza', (tester) async {
    await tester.pumpWidget(
      wrap(SettingsScreen(db: AppDatabase())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_currency_tile')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_currency_tile')), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings_currency_tile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('currency_option_usd')));
    await tester.pumpAndSettle();

    expect(PreferencesService.currencyNotifier.value, AppCurrency.usd);
  });

  testWidgets('voce Profilo appare e reagisce al tap con callback', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      wrap(
        SettingsScreen(
          db: AppDatabase(),
          onManageProfiles: () {
            tapped = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_active_profile_tile')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings_profile_section')), findsOneWidget);
    expect(find.byKey(const Key('settings_active_profile_tile')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_active_profile_tile')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
