import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/screens/accounts_screen.dart';

void main() {
  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.addAccount(
      Account(
        id: 'acc_theme',
        name: 'Conto tema',
        type: AccountType.bank,
        initialBalance: 1200,
        color: 0xFF22AA88,
        createdAt: DateTime(2026, 6, 20),
      ),
    );
    return db;
  }

  Future<void> pumpScreen(WidgetTester tester, StreamThemeId themeId) async {
    final db = await seededDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: AccountsScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('AccountsScreen renders in Midnight and High Contrast', (
    tester,
  ) async {
    await pumpScreen(tester, StreamThemeId.midnight);
    expect(find.text('Conto tema'), findsOneWidget);
    expect(
      find.byKey(const Key('account_period_summary')),
      findsAtLeastNWidgets(1),
    );
    expect(tester.takeException(), isNull);

    await pumpScreen(tester, StreamThemeId.highContrast);
    expect(find.text('Conto tema'), findsOneWidget);
    expect(
      find.byKey(const Key('account_current_balance')),
      findsAtLeastNWidgets(1),
    );
    expect(tester.takeException(), isNull);
  });
}
