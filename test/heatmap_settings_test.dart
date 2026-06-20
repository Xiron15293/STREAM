import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/heatmap_settings_screen.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/utils/heatmap_utils.dart';
import 'package:stream_app/widgets/categories_treemap.dart';
import 'package:stream_app/widgets/expense_heatmap.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.heatmapSettingsNotifier.value =
        PreferencesService.defaultHeatmapSettings;
  });

  tearDown(() async {
    await PreferencesService.restoreDefaultHeatmapSettings();
    PreferencesService.heatmapSettingsNotifier.value =
        PreferencesService.defaultHeatmapSettings;
  });

  test('default heatmap settings and labels are stable', () async {
    final settings = await PreferencesService.loadHeatmapSettings();

    expect(settings.thresholds, [1, 5, 20, 50, 150, 500]);
    expect(settings.colors, HeatmapSettings.defaultColors);
    expect(settings.bands.map((band) => band.label), [
      '< 1€',
      '1–5€',
      '5–20€',
      '20–50€',
      '50–150€',
      '150–500€',
      '> 500€',
    ]);
  });

  test('corrupted SharedPreferences fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.heatmapThresholdsKey: ['5', '5', '-1'],
      PreferencesService.heatmapColorsKey: ['123'],
    });

    final settings = await PreferencesService.loadHeatmapSettings();

    expect(settings.thresholds, HeatmapSettings.defaultThresholds);
    expect(settings.colors, HeatmapSettings.defaultColors);
  });

  test('invalid heatmap settings are not saved', () async {
    final invalid = HeatmapSettings(
      thresholds: const [1, 1, 20, 50, 150, 500],
      colors: HeatmapSettings.defaultColors,
    );

    final saved = await PreferencesService.saveHeatmapSettings(invalid);

    expect(saved, isFalse);
    expect(
      PreferencesService.heatmapSettingsNotifier.value.thresholds,
      HeatmapSettings.defaultThresholds,
    );
  });

  testWidgets('settings UI exposes heatmap controls and restore', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(db: AppDatabase())),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('settings_heatmap_configure_tile'), skipOffstage: false),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('settings_heatmap_configure_tile')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('settings_heatmap_configure_tile')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('heatmap_settings_screen')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_settings_section')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_settings_preview')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_thresholds_editor')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_threshold_field_0')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_threshold_field_1')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_threshold_field_2')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_threshold_field_3')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_threshold_field_4')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_threshold_field_5')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_color_editor')), findsOneWidget);
    expect(find.byKey(const Key('heatmap_color_item')), findsNWidgets(7));
    expect(
      find.byKey(const Key('heatmap_restore_defaults_button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('threshold edit changes banding and restore resets defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HeatmapSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('heatmap_threshold_field_0')),
      '2',
    );
    await tester.pumpAndSettle();

    var settings = await PreferencesService.loadHeatmapSettings();
    expect(settings.thresholds.first, 2);
    expect(heatmapBandIndex(1.5, settings: settings), 0);

    final restoreButton = find.byKey(
      const Key('heatmap_restore_defaults_button'),
    );
    await tester.ensureVisible(restoreButton);
    await tester.pumpAndSettle();
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();
    settings = await PreferencesService.loadHeatmapSettings();

    expect(settings.thresholds, HeatmapSettings.defaultThresholds);
    expect(settings.colors, HeatmapSettings.defaultColors);
  });

  testWidgets('non growing and negative thresholds are rejected', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HeatmapSettingsScreen()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('heatmap_threshold_field_1')),
      '1',
    );
    await tester.pumpAndSettle();

    expect(
      PreferencesService.heatmapSettingsNotifier.value.thresholds,
      HeatmapSettings.defaultThresholds,
    );
    expect(
      find.text('Le soglie devono essere positive e crescenti.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('heatmap_threshold_field_0')),
      '-1',
    );
    await tester.pumpAndSettle();

    expect(
      PreferencesService.heatmapSettingsNotifier.value.thresholds,
      HeatmapSettings.defaultThresholds,
    );
  });

  testWidgets('color edit updates heatmap cell color', (tester) async {
    final settings = HeatmapSettings.defaults.copyWith(
      colors: [0xFF123456, ...HeatmapSettings.defaultColors.skip(1)],
    );
    await PreferencesService.saveHeatmapSettings(settings);

    final date = DateTime(2026, 6, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseHeatmap(
            allMovements: [
              Movement(
                id: 'heatmap_color',
                title: 'Heatmap color',
                amount: 0.5,
                type: MovementType.expense,
                date: date,
                categoryId: 'exp_1',
                accountId: defaultAccountId,
                createdAt: date,
              ),
            ],
            year: 2026,
            month: 6,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_heatmapCellColor(tester, 1), const Color(0xFF123456));
  });

  testWidgets(
    'category treemap keeps category.color after heatmap color change',
    (tester) async {
      await PreferencesService.saveHeatmapSettings(
        HeatmapSettings.defaults.copyWith(
          colors: [0xFF123456, ...HeatmapSettings.defaultColors.skip(1)],
        ),
      );
      const category = Category(
        id: 'cat_color',
        name: 'Categoria colore',
        type: MovementType.expense,
        color: 0xFFE53935,
      );
      final date = DateTime(2026, 6, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 560,
              child: CategoriesTreemap(
                categories: const [category],
                movements: [
                  Movement(
                    id: 'cat_mov',
                    title: 'Categoria movimento',
                    amount: 20,
                    type: MovementType.expense,
                    date: date,
                    categoryId: category.id,
                    accountId: defaultAccountId,
                    createdAt: date,
                  ),
                ],
                onCategoryTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.text('Categoria colore'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, const Color(0xFFE53935));
    },
  );
}

Color? _heatmapCellColor(WidgetTester tester, int day) {
  final widget = tester.widget(find.byKey(Key('heatmap_day_cell_$day')).first);
  final decoration = switch (widget) {
    Container(:final decoration) => decoration,
    AnimatedContainer(:final decoration) => decoration,
    _ => null,
  };
  if (decoration is BoxDecoration) return decoration.color;
  return null;
}
