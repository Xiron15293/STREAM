import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_theme_palette.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'show_notes': true,
      'last_backup_date': '2026-06-20 10:00',
      'category_layout': 'treemap',
      'movements_view_mode': 'listHeatmap',
      'app_currency': 'usd',
      'theme_id': 'forest',
      'kpi_style': 'dense',
      'chart_style': 'technical',
      'dashboard_net_worth_account_ids': ['cash'],
      'dashboard_net_worth_account_ids_profile_a': ['cash', 'intesa'],
      'dashboard_net_worth_account_ids_profile_b': ['house'],
      'hidden_chart_ids': ['movements_cashflow'],
    });
    PreferencesService.categoryLayoutNotifier.value = 'treemap';
    PreferencesService.movementsViewModeNotifier.value =
        MovementsViewMode.heatmap;
    PreferencesService.currencyNotifier.value = AppCurrency.usd;
    PreferencesService.themeIdNotifier.value = 'forest';
    PreferencesService.kpiStyleNotifier.value = 'dense';
    PreferencesService.chartStyleNotifier.value = 'technical';
    PreferencesService.hiddenChartIdsNotifier.value = {'movements_cashflow'};
    PreferencesService.netWorthAccountIdsNotifier.value = {'cash'};
  });

  test(
    'clearForReset resets SharedPreferences and runtime notifiers',
    () async {
      await PreferencesService.clearForReset();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(PreferencesService.categoryLayoutNotifier.value, 'cleanList');
      expect(
        PreferencesService.movementsViewModeNotifier.value,
        MovementsViewMode.heatmap,
      );
      expect(PreferencesService.currencyNotifier.value, AppCurrency.eur);
      expect(
        PreferencesService.themeIdNotifier.value,
        StreamThemeId.streamClassic.name,
      );
      expect(PreferencesService.kpiStyleNotifier.value, 'automatic');
      expect(PreferencesService.chartStyleNotifier.value, 'automatic');
      expect(PreferencesService.hiddenChartIdsNotifier.value, isEmpty);
      expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    },
  );
}
