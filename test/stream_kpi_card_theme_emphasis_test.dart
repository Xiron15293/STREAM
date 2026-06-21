import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/stream_kpi_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
    PreferencesService.kpiStyleNotifier.value = 'automatic';
  });

  Widget wrapKpi(StreamKpiCard card, [StreamThemeId themeId = StreamThemeId.streamClassic]) {
    return MaterialApp(
      theme: StreamTheme.build(StreamThemePalette.of(themeId)),
      home: Scaffold(body: card),
    );
  }

  group('StreamKpiCard emphasis', () {
    testWidgets('hero emphasis renders with key', (tester) async {
      await tester.pumpWidget(wrapKpi(
        StreamKpiCard(
          cardKey: const Key('test_hero_kpi'),
          title: 'Test Hero',
          value: '100.00 €',
          emphasis: StreamKpiEmphasis.hero,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test_hero_kpi')), findsOneWidget);
      // uppercaseTitle defaults to true, so title is uppercased
      expect(find.text('TEST HERO'), findsOneWidget);
      expect(find.text('100.00 €'), findsOneWidget);
    });

    testWidgets('normal emphasis renders by default', (tester) async {
      await tester.pumpWidget(wrapKpi(
        StreamKpiCard(
          cardKey: const Key('test_normal_kpi'),
          title: 'Normal',
          value: '50.00 €',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test_normal_kpi')), findsOneWidget);
    });

    testWidgets('all KPI styles render without crash', (tester) async {
      for (final style in StreamKpiStyleId.values) {
        PreferencesService.kpiStyleNotifier.value = style.name;
        await tester.pumpWidget(wrapKpi(
          StreamKpiCard(
            title: 'Style ${style.name}',
            value: '100.00 €',
            emphasis: StreamKpiEmphasis.hero,
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('High Contrast hero card', () {
    testWidgets('High Contrast hero renders without crash', (tester) async {
      await tester.pumpWidget(wrapKpi(
        StreamKpiCard(
          cardKey: const Key('hc_hero_kpi'),
          title: 'HC Hero',
          value: '500.00 €',
          emphasis: StreamKpiEmphasis.hero,
        ),
        StreamThemeId.highContrast,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hc_hero_kpi')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('High Contrast normal card still renders', (tester) async {
      await tester.pumpWidget(wrapKpi(
        StreamKpiCard(
          cardKey: const Key('hc_normal_kpi'),
          title: 'HC Normal',
          value: '100.00 €',
        ),
        StreamThemeId.highContrast,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hc_normal_kpi')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
