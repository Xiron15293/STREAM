import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/stream_kpi_style.dart';
import '../design/stream_theme_palette.dart';
import '../utils/heatmap_utils.dart';

enum MovementsViewMode { list, calendar, heatmap }
enum AppCurrency { eur, usd, gbp, chf, jpy }

class PreferencesService {
  static const _showNotesKey = 'show_notes';
  static const _lastBackupDateKey = 'last_backup_date';
  static const _categoryLayoutKey = 'category_layout';
  static const _movementsViewModeKey = 'movements_view_mode';
  static const _currencyKey = 'app_currency';
  static const _themeIdKey = 'theme_id';
  static const _kpiStyleKey = 'kpi_style';
  static const _chartStyleKey = 'chart_style';
  static const heatmapThresholdsKey = 'heatmap_thresholds';
  static const heatmapColorsKey = 'heatmap_colors';

  static const defaultCategoryLayout = 'cleanList';
  static const defaultMovementsViewMode = MovementsViewMode.heatmap;
  static const defaultCurrency = AppCurrency.eur;
  static const defaultThemeId = 'streamClassic';
  static const defaultKpiStyle = 'automatic';
  static const defaultChartStyle = 'automatic';
  static const defaultHeatmapSettings = HeatmapSettings.defaults;

  static final categoryLayoutNotifier = ValueNotifier<String>(
    defaultCategoryLayout,
  );
  static final movementsViewModeNotifier = ValueNotifier<MovementsViewMode>(
    defaultMovementsViewMode,
  );
  static final heatmapSettingsNotifier = ValueNotifier<HeatmapSettings>(
    defaultHeatmapSettings,
  );
  static final currencyNotifier = ValueNotifier<AppCurrency>(defaultCurrency);
  static final themeIdNotifier = ValueNotifier<String>(defaultThemeId);
  static final kpiStyleNotifier = ValueNotifier<String>(defaultKpiStyle);
  static final chartStyleNotifier = ValueNotifier<String>(defaultChartStyle);

  static Future<bool> loadShowNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showNotesKey) ?? false;
  }

  static Future<void> saveShowNotes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNotesKey, value);
  }

  static Future<String?> loadLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupDateKey);
  }

  static Future<void> saveLastBackupDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupDateKey, date);
  }

  static Future<String> loadCategoryLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_categoryLayoutKey) ?? defaultCategoryLayout;
  }

  static Future<void> saveCategoryLayout(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_categoryLayoutKey, value);
    categoryLayoutNotifier.value = value;
  }

  static Future<MovementsViewMode> loadMovementsViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_movementsViewModeKey);
    final mode = switch (value) {
      'heatmap' || 'advancedHeatmap' => MovementsViewMode.heatmap,
      'calendar' || 'list' || 'listHeatmap' => MovementsViewMode.heatmap,
      _ => defaultMovementsViewMode,
    };
    movementsViewModeNotifier.value = mode;
    return mode;
  }

  static Future<void> saveMovementsViewMode(MovementsViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_movementsViewModeKey, MovementsViewMode.heatmap.name);
    movementsViewModeNotifier.value = MovementsViewMode.heatmap;
  }

  static Future<AppCurrency> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_currencyKey);
    final currency = switch (value) {
      'usd' => AppCurrency.usd,
      'gbp' => AppCurrency.gbp,
      'chf' => AppCurrency.chf,
      'jpy' => AppCurrency.jpy,
      _ => defaultCurrency,
    };
    currencyNotifier.value = currency;
    return currency;
  }

  static Future<void> saveCurrency(AppCurrency currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency.name);
    currencyNotifier.value = currency;
  }

  static Future<HeatmapSettings> loadHeatmapSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final thresholdStrings = prefs.getStringList(heatmapThresholdsKey);
    final colorStrings = prefs.getStringList(heatmapColorsKey);
    final thresholds = thresholdStrings
        ?.map(double.tryParse)
        .whereType<double>()
        .toList();
    final colors = colorStrings?.map(int.tryParse).whereType<int>().toList();

    final settings = HeatmapSettings(
      thresholds: thresholds ?? HeatmapSettings.defaultThresholds,
      colors: colors ?? HeatmapSettings.defaultColors,
    );

    if (!settings.isValid) {
      heatmapSettingsNotifier.value = defaultHeatmapSettings;
      return defaultHeatmapSettings;
    }

    heatmapSettingsNotifier.value = settings;
    return settings;
  }

  static Future<bool> saveHeatmapSettings(HeatmapSettings settings) async {
    if (!settings.isValid) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      heatmapThresholdsKey,
      settings.thresholds.map((value) => value.toString()).toList(),
    );
    await prefs.setStringList(
      heatmapColorsKey,
      settings.colors.map((value) => value.toString()).toList(),
    );
    heatmapSettingsNotifier.value = settings;
    return true;
  }

  static Future<void> restoreDefaultHeatmapSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(heatmapThresholdsKey);
    await prefs.remove(heatmapColorsKey);
    heatmapSettingsNotifier.value = defaultHeatmapSettings;
  }

  static Future<String> loadThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeIdKey) ?? defaultThemeId;
    final valid = StreamThemeId.values.any((e) => e.name == value);
    final result = valid ? value : defaultThemeId;
    themeIdNotifier.value = result;
    return result;
  }

  static Future<void> saveThemeId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, value);
    themeIdNotifier.value = value;
  }

  static Future<String> loadKpiStyleId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kpiStyleKey) ?? defaultKpiStyle;
    final valid = StreamKpiStyleId.values.any((e) => e.name == value);
    final result = valid ? value : defaultKpiStyle;
    kpiStyleNotifier.value = result;
    return result;
  }

  static Future<void> saveKpiStyleId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kpiStyleKey, value);
    kpiStyleNotifier.value = value;
  }

  static Future<String> loadChartStyleId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_chartStyleKey) ?? defaultChartStyle;
    final valid = StreamChartStyleId.values.any((e) => e.name == value);
    final result = valid ? value : defaultChartStyle;
    chartStyleNotifier.value = result;
    return result;
  }

  static Future<void> saveChartStyleId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chartStyleKey, value);
    chartStyleNotifier.value = value;
  }

  static const _netWorthAccountIdsKey = 'dashboard_net_worth_account_ids';
  static const _hiddenChartIdsKey = 'hidden_chart_ids';

  static final netWorthAccountIdsNotifier = ValueNotifier<Set<String>?>(null);
  static final hiddenChartIdsNotifier = ValueNotifier<Set<String>>({});

  static Future<Set<String>?> loadDashboardNetWorthAccountIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_netWorthAccountIdsKey);
    final result = list?.toSet();
    netWorthAccountIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveDashboardNetWorthAccountIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_netWorthAccountIdsKey, ids.toList());
    netWorthAccountIdsNotifier.value = ids;
  }

  static Future<void> clearDashboardNetWorthAccountSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_netWorthAccountIdsKey);
    netWorthAccountIdsNotifier.value = null;
  }

  static Future<Set<String>> loadHiddenChartIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_hiddenChartIdsKey);
    final result = list?.toSet() ?? <String>{};
    hiddenChartIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveHiddenChartIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenChartIdsKey, ids.toList());
    hiddenChartIdsNotifier.value = ids;
  }

  static Future<void> setChartVisible(String chartId, bool visible) async {
    final hidden = Set<String>.from(hiddenChartIdsNotifier.value);
    if (visible) {
      hidden.remove(chartId);
    } else {
      hidden.add(chartId);
    }
    await saveHiddenChartIds(hidden);
  }

  static bool isChartVisible(String chartId) {
    return !hiddenChartIdsNotifier.value.contains(chartId);
  }

  static Future<void> resetChartVisibility() async {
    await saveHiddenChartIds({});
  }

  static Future<void> restoreDefaultChartVisibility() async {
    await resetChartVisibility();
  }

  static Future<void> clearForReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_showNotesKey);
    await prefs.remove(_lastBackupDateKey);
    await prefs.remove(_categoryLayoutKey);
    await prefs.remove(_movementsViewModeKey);
    await prefs.remove(_currencyKey);
    await prefs.remove(_themeIdKey);
    await prefs.remove(_kpiStyleKey);
    await prefs.remove(_chartStyleKey);
    await prefs.remove(_netWorthAccountIdsKey);
    await prefs.remove(_hiddenChartIdsKey);
  }
}
