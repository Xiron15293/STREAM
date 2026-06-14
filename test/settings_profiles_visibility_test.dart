import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
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
