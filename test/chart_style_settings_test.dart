import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.themeIdNotifier.value = StreamThemeId.streamClassic.name;
    PreferencesService.kpiStyleNotifier.value = 'dense';
    PreferencesService.chartStyleNotifier.value = 'automatic';
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
        ),
        home: SettingsScreen(db: AppDatabase(), onManageProfiles: () {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revealChartStyle(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_chart_picker_tile')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Settings shows chart style section and options', (tester) async {
    await pumpSettings(tester);

    await revealChartStyle(tester);
    expect(find.byKey(const Key('settings_chart_style_section')), findsOneWidget);
    expect(find.text('Stile grafici'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_chart_picker_tile')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings_chart_style_option_automatic')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settings_chart_style_option_soft')), findsOneWidget);
    expect(
      find.byKey(const Key('settings_chart_style_option_technical')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings_chart_style_option_highContrast')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings_chart_style_option_editorial')),
      findsOneWidget,
    );
  });

  testWidgets('selecting chart style updates preference and survives rebuild', (
    tester,
  ) async {
    await pumpSettings(tester);

    await revealChartStyle(tester);
    await tester.tap(find.byKey(const Key('settings_chart_picker_tile')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('settings_chart_style_option_editorial')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_chart_style_option_editorial')));
    await tester.pumpAndSettle();

    expect(PreferencesService.chartStyleNotifier.value, 'editorial');
    expect(find.text('Editoriale'), findsWidgets);

    await pumpSettings(tester);
    expect(find.text('Editoriale'), findsWidgets);
  });
}
