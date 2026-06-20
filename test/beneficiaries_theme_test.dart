import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/beneficiary_profile.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/screens/beneficiaries_screen.dart';

void main() {
  Future<AppDatabase> seededDb({required bool withData}) async {
    final db = AppDatabase();
    if (withData) {
      await db.addBeneficiaryProfile(
        BeneficiaryProfile(
          id: 'bp_market',
          key: 'market',
          displayName: 'Market',
          iconKey: BeneficiaryProfile.defaultIconKey,
          color: 0xFFAA6633,
          createdAt: DateTime(2026, 6, 20),
        ),
      );
    }
    return db;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    StreamThemeId themeId, {
    required bool withData,
  }) async {
    final db = await seededDb(withData: withData);
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: Scaffold(body: BeneficiariesScreen(db: db)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'BeneficiariesScreen renders entry and empty state across themes',
    (tester) async {
      await pumpScreen(tester, StreamThemeId.minimalSand, withData: true);
      expect(find.text('Market'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpScreen(tester, StreamThemeId.midnight, withData: false);
      expect(find.text('Nessun beneficiario disponibile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
