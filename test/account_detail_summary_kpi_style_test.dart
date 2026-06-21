import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/screens/accounts_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.addAccount(
      Account(
        id: 'acc_detail_kpi',
        name: 'Conto KPI',
        type: AccountType.bank,
        initialBalance: 250,
        createdAt: DateTime(2026, 6, 21),
      ),
    );
    return db;
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    required String kpiStyle,
    StreamThemeId themeId = StreamThemeId.midnight,
  }) async {
    PreferencesService.kpiStyleNotifier.value = kpiStyle;
    final db = await seededDb();
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: AccountsScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account_card_acc_detail_kpi')));
    await tester.pumpAndSettle();
  }

  testWidgets('account detail summary stays readable in dense style', (
    tester,
  ) async {
    await pumpSheet(tester, kpiStyle: 'dense');

    expect(find.byKey(const Key('account_detail_sheet')), findsOneWidget);
    expect(find.byKey(const Key('account_detail_summary_grid')), findsOneWidget);
    expect(find.byKey(const Key('account_sheet_income')), findsOneWidget);
    expect(find.byKey(const Key('account_sheet_transfer_net')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account detail summary toggle expands in split style', (
    tester,
  ) async {
    await pumpSheet(tester, kpiStyle: 'split');

    expect(find.byKey(const Key('account_detail_compact_summary')), findsOneWidget);
    expect(find.byKey(const Key('account_detail_summary_grid')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('account_detail_summary_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account_detail_summary_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account_detail_summary_grid')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('account_detail_summary_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account_detail_summary_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account_detail_summary_grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
