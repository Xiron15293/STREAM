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
    PreferencesService.kpiStyleNotifier.value = 'automatic';
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.addAccount(
      Account(
        id: 'hero_acc',
        name: 'Patrimonio Test',
        type: AccountType.savings,
        initialBalance: 4321,
        createdAt: DateTime(2026, 6, 20),
      ),
    );
    return db;
  }

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required StreamThemeId themeId,
    required String kpiStyle,
    Size size = const Size(390, 844),
  }) async {
    PreferencesService.kpiStyleNotifier.value = kpiStyle;
    final db = await seededDb();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: DashboardScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hero net worth value stays invariant across KPI styles', (
    tester,
  ) async {
    const expected = '+4321.00';

    await pumpDashboard(
      tester,
      themeId: StreamThemeId.streamClassic,
      kpiStyle: 'minimal',
    );
    expect(find.textContaining(expected), findsWidgets);

    await pumpDashboard(
      tester,
      themeId: StreamThemeId.streamClassic,
      kpiStyle: 'dense',
    );
    expect(find.textContaining(expected), findsWidgets);

    await pumpDashboard(
      tester,
      themeId: StreamThemeId.streamClassic,
      kpiStyle: 'solid',
    );
    expect(find.textContaining(expected), findsWidgets);
  });

  testWidgets('dense hero is clearly more compact than minimal', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      themeId: StreamThemeId.forest,
      kpiStyle: 'minimal',
    );
    final minimalSize = tester.getSize(
      find.byKey(const Key('dashboard_hero_networth_card')),
    );

    await pumpDashboard(
      tester,
      themeId: StreamThemeId.forest,
      kpiStyle: 'dense',
    );
    final denseSize = tester.getSize(
      find.byKey(const Key('dashboard_hero_networth_card')),
    );
    expect(denseSize.height, lessThan(minimalSize.height * 0.8));
    expect(
      find.byKey(const Key('dashboard_hero_kpi_style_dense')),
      findsOneWidget,
    );
  });

  testWidgets('hero changes decoration with solid and outline styles', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      themeId: StreamThemeId.aurora,
      kpiStyle: 'solid',
    );
    final solidHero = tester.widget<AnimatedContainer>(
      find.byKey(const Key('dashboard_hero_networth_card')),
    );
    final solidDecoration = solidHero.decoration as BoxDecoration;

    await pumpDashboard(
      tester,
      themeId: StreamThemeId.aurora,
      kpiStyle: 'outline',
    );
    final outlineHero = tester.widget<AnimatedContainer>(
      find.byKey(const Key('dashboard_hero_networth_card')),
    );
    final outlineDecoration = outlineHero.decoration as BoxDecoration;

    expect(solidDecoration.color, isNotNull);
    expect(outlineDecoration.border, isNotNull);
    expect(solidDecoration.color, isNot(outlineDecoration.color));
  });

  testWidgets('small viewport does not overflow with dense hero', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      themeId: StreamThemeId.highContrast,
      kpiStyle: 'dense',
      size: const Size(320, 480),
    );

    await tester.drag(find.byKey(const Key('dashboard_scroll_view')), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dashboard_hero_networth_card')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
