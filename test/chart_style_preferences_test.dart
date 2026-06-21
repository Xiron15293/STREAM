import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.chartStyleNotifier.value =
        PreferencesService.defaultChartStyle;
  });

  test('default chart_style is automatic', () async {
    final style = await PreferencesService.loadChartStyleId();
    expect(style, 'automatic');
  });

  test('save/load chart_style persists and updates notifier', () async {
    await PreferencesService.saveChartStyleId('editorial');

    expect(PreferencesService.chartStyleNotifier.value, 'editorial');
    expect(await PreferencesService.loadChartStyleId(), 'editorial');
  });

  test('invalid chart_style falls back to automatic', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chart_style', 'broken');

    final style = await PreferencesService.loadChartStyleId();
    expect(style, 'automatic');
    expect(PreferencesService.chartStyleNotifier.value, 'automatic');
  });
}
