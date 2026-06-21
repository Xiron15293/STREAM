import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/screens/archive_screen.dart';
import 'package:stream_app/theme.dart';

Widget buildApp() {
  final db = AppDatabase();
  return MaterialApp(
    theme: StreamTheme.build(
      StreamThemePalette.of(StreamThemeId.streamClassic),
    ),
    home: Scaffold(body: ArchiveScreen(db: db)),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
  });

  testWidgets('segmented button has 4 segments', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final segmentButton = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(segmentButton.segments.length, 4);
  });

  testWidgets('tab section keys exist', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byKey(const Key('archive_section_movements')), findsOneWidget);
    expect(find.byKey(const Key('archive_section_accounts')), findsOneWidget);
    expect(find.byKey(const Key('archive_section_categories')), findsOneWidget);
    expect(find.byKey(const Key('archive_section_beneficiaries')), findsOneWidget);
  });

  testWidgets('tab switch shows correct screen', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.byKey(const Key('archive_movements_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('archive_section_accounts')));
    await tester.pump();
    expect(find.byKey(const Key('archive_accounts_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('archive_section_categories')));
    await tester.pump();
    expect(find.byKey(const Key('archive_categories_screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('archive_section_beneficiaries')));
    await tester.pump();
    expect(find.byKey(const Key('archive_beneficiaries_screen')), findsOneWidget);
  });
}
