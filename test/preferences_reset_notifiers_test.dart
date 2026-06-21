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
    PreferencesService.currencyNotifier.value = AppCurrency.usd;
    PreferencesService.themeIdNotifier.value = 'forest';
    PreferencesService.kpiStyleNotifier.value = 'dense';
    PreferencesService.chartStyleNotifier.value = 'technical';
    PreferencesService.hiddenChartIdsNotifier.value = {'movements_cashflow'};
    PreferencesService.netWorthAccountIdsNotifier.value = {'cash'};
    PreferencesService.showNotesNotifier.value = true;
  });

  test(
    'clearForReset resets SharedPreferences base keys and runtime notifiers',
    () async {
      await PreferencesService.clearForReset();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('show_notes'), isFalse);
      expect(prefs.containsKey('last_backup_date'), isFalse);
      expect(prefs.containsKey('category_layout'), isFalse);
      expect(prefs.containsKey('app_currency'), isFalse);
      expect(prefs.containsKey('theme_id'), isFalse);
      expect(prefs.containsKey('kpi_style'), isFalse);
      expect(prefs.containsKey('chart_style'), isFalse);
      expect(prefs.containsKey('dashboard_net_worth_account_ids'), isFalse);
      expect(prefs.containsKey('hidden_chart_ids'), isFalse);

      // Profile-scoped keys must NOT be removed when no activeProfileId
      expect(
        prefs.containsKey('dashboard_net_worth_account_ids_profile_a'),
        isTrue,
      );
      expect(
        prefs.containsKey('dashboard_net_worth_account_ids_profile_b'),
        isTrue,
      );

      expect(PreferencesService.showNotesNotifier.value, false);
      expect(PreferencesService.categoryLayoutNotifier.value, 'cleanList');
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

  test(
    'clearForReset with activeProfileId only removes that profile scoped key',
    () async {
      await PreferencesService.clearForReset(
        activeProfileId: 'profile_b',
      );

      final prefs = await SharedPreferences.getInstance();

      // profile_a scoped key must survive
      expect(
        prefs.containsKey('dashboard_net_worth_account_ids_profile_a'),
        isTrue,
      );
      // profile_b scoped key must be removed
      expect(
        prefs.containsKey('dashboard_net_worth_account_ids_profile_b'),
        isFalse,
      );

      expect(PreferencesService.showNotesNotifier.value, false);
      expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    },
  );
}
