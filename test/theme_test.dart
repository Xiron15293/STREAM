import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_chart_palette.dart';
import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_extension.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/theme.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreamThemeId', () {
    test('fromString returns correct enum', () {
      expect(StreamThemeId.fromString('forest'), StreamThemeId.forest);
      expect(StreamThemeId.fromString('midnight'), StreamThemeId.midnight);
    });

    test('fromString with invalid value returns default', () {
      expect(StreamThemeId.fromString('invalid'), StreamThemeId.streamClassic);
    });

    test('all themes have labels', () {
      for (final theme in StreamThemeId.values) {
        expect(theme.label, isNotEmpty);
      }
    });
  });

  group('StreamThemePalette', () {
    test('of returns correct palette', () {
      expect(StreamThemePalette.of(StreamThemeId.streamClassic).primary, const Color(0xFF4B7BFF));
      expect(StreamThemePalette.of(StreamThemeId.forest).primary, const Color(0xFF22C55E));
      expect(StreamThemePalette.of(StreamThemeId.midnight).primary, const Color(0xFF60A5FA));
      expect(StreamThemePalette.of(StreamThemeId.minimalSand).brightness, Brightness.light);
      expect(StreamThemePalette.of(StreamThemeId.highContrast).brightness, Brightness.dark);
    });
  });

  group('StreamTheme.build', () {
    test('build with classic returns valid ThemeData', () {
      final theme = StreamTheme.build(StreamThemePalette.of(StreamThemeId.streamClassic));
      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.dark);
    });

    test('build with minimalSand returns light theme', () {
      final theme = StreamTheme.build(StreamThemePalette.of(StreamThemeId.minimalSand));
      expect(theme.brightness, Brightness.light);
    });

    test('build includes StreamThemeExtension', () {
      final theme = StreamTheme.build(StreamThemePalette.of(StreamThemeId.streamClassic));
      final ext = theme.extension<StreamThemeExtension>();
      expect(ext, isNotNull);
      expect(ext!.palette.primary, const Color(0xFF4B7BFF));
    });

    test('build with forest has correct chart palette', () {
      final theme = StreamTheme.build(StreamThemePalette.of(StreamThemeId.forest));
      final ext = theme.extension<StreamThemeExtension>()!;
      expect(ext.chartPalette.donutColors, isNotEmpty);
      expect(ext.chartPalette.categoryColors, isNotEmpty);
    });
  });

  group('PreferencesService theme', () {
    test('default theme is streamClassic', () async {
      final id = await PreferencesService.loadThemeId();
      expect(id, 'streamClassic');
    });

    test('save and load Forest', () async {
      await PreferencesService.saveThemeId('forest');
      final id = await PreferencesService.loadThemeId();
      expect(id, 'forest');
    });

    test('save and load Midnight', () async {
      await PreferencesService.saveThemeId('midnight');
      final id = await PreferencesService.loadThemeId();
      expect(id, 'midnight');
    });

    test('invalid theme falls back to classic', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_id', 'invalid_theme');
      final id = await PreferencesService.loadThemeId();
      expect(id, 'streamClassic');
    });

    test('default KPI style is automatic', () async {
      final style = await PreferencesService.loadKpiStyleId();
      expect(style, 'automatic');
    });

    test('save and load KPI style', () async {
      await PreferencesService.saveKpiStyleId('dense');
      final style = await PreferencesService.loadKpiStyleId();
      expect(style, 'dense');
    });

    test('default chart style is automatic', () async {
      final style = await PreferencesService.loadChartStyleId();
      expect(style, 'automatic');
    });

    test('save and load chart style', () async {
      await PreferencesService.saveChartStyleId('technical');
      final style = await PreferencesService.loadChartStyleId();
      expect(style, 'technical');
    });
  });

  group('StreamKpiStyleId', () {
    test('fromString returns correct enum', () {
      expect(StreamKpiStyleId.fromString('minimal'), StreamKpiStyleId.minimal);
      expect(StreamKpiStyleId.fromString('glass'), StreamKpiStyleId.glass);
      expect(StreamKpiStyleId.fromString('dense'), StreamKpiStyleId.dense);
      expect(StreamKpiStyleId.fromString('outline'), StreamKpiStyleId.outline);
      expect(StreamKpiStyleId.fromString('solid'), StreamKpiStyleId.solid);
      expect(StreamKpiStyleId.fromString('split'), StreamKpiStyleId.split);
    });

    test('fromString with invalid value returns automatic', () {
      expect(StreamKpiStyleId.fromString('invalid'), StreamKpiStyleId.automatic);
    });

    test('kpi_style invalid falls back to automatic', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kpi_style', 'invalid_style');
      final style = await PreferencesService.loadKpiStyleId();
      expect(style, 'automatic');
    });

    test('all styles have labels', () {
      for (final s in StreamKpiStyleId.values) {
        expect(s.label, isNotEmpty);
      }
    });
  });

  group('StreamChartStyleId', () {
    test('fromString returns correct enum', () {
      expect(StreamChartStyleId.fromString('soft'), StreamChartStyleId.soft);
      expect(StreamChartStyleId.fromString('editorial'), StreamChartStyleId.editorial);
    });

    test('fromString with invalid value returns automatic', () {
      expect(StreamChartStyleId.fromString('invalid'), StreamChartStyleId.automatic);
    });
  });

  group('Chart style effects', () {
    late StreamThemePalette classic;

    setUp(() {
      classic = StreamThemePalette.of(StreamThemeId.streamClassic);
    });

    test('automatic uses base palette unchanged', () {
      final base = StreamChartPalette.forTheme(classic);
      final applied = base.applyStyle(StreamChartStyleId.automatic, classic);
      expect(applied.gridColor, base.gridColor);
      expect(applied.axisTextColor, base.axisTextColor);
    });

    test('soft palette differs from automatic', () {
      final base = StreamChartPalette.forTheme(classic);
      final applied = base.applyStyle(StreamChartStyleId.soft, classic);
      expect(applied.gridColor.alpha, lessThan(base.gridColor.alpha));
    });

    test('technical has brighter axis text', () {
      final base = StreamChartPalette.forTheme(classic);
      final applied = base.applyStyle(StreamChartStyleId.technical, classic);
      expect(applied.axisTextColor, classic.textPrimary);
      expect(applied.gridColor.alpha, greaterThan(base.gridColor.alpha));
    });

    test('highContrast uses very different donut colors', () {
      final base = StreamChartPalette.forTheme(classic);
      final applied = base.applyStyle(StreamChartStyleId.highContrast, classic);
      expect(applied.donutColors.first, const Color(0xFFFFFF00));
      expect(applied.axisTextColor, Colors.white);
    });

    test('editorial has muted grid', () {
      final base = StreamChartPalette.forTheme(classic);
      final applied = base.applyStyle(StreamChartStyleId.editorial, classic);
      expect(applied.gridColor.alpha, lessThan(base.gridColor.alpha));
    });

    test('chart style applied through StreamTheme.build', () {
      final theme = StreamTheme.build(classic, chartStyle: StreamChartStyleId.technical);
      final ext = theme.extension<StreamThemeExtension>()!;
      expect(ext.chartPalette.axisTextColor, classic.textPrimary);
    });

    test('automatic chart style is default in build', () {
      final theme = StreamTheme.build(classic);
      final ext = theme.extension<StreamThemeExtension>()!;
      final auto = StreamChartPalette.forTheme(classic);
      expect(ext.chartPalette.gridColor, auto.gridColor);
    });
  });

  group('chart style persistence', () {
    test('chartStyleId invalid falls back to automatic', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chart_style', 'invalid_style');
      final style = await PreferencesService.loadChartStyleId();
      expect(style, 'automatic');
    });
  });
}
