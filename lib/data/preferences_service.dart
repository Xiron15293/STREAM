import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/heatmap_utils.dart';

enum MovementsViewMode { list, calendar, heatmap }
enum AppCurrency { eur, usd, gbp, chf, jpy }

class PreferencesService {
  static const _showNotesKey = 'show_notes';
  static const _lastBackupDateKey = 'last_backup_date';
  static const _categoryLayoutKey = 'category_layout';
  static const _movementsViewModeKey = 'movements_view_mode';
  static const _currencyKey = 'app_currency';
  static const heatmapThresholdsKey = 'heatmap_thresholds';
  static const heatmapColorsKey = 'heatmap_colors';

  static const defaultCategoryLayout = 'cleanList';
  static const defaultMovementsViewMode = MovementsViewMode.heatmap;
  static const defaultCurrency = AppCurrency.eur;
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

  static Future<void> clearForReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_showNotesKey);
    await prefs.remove(_lastBackupDateKey);
    await prefs.remove(_categoryLayoutKey);
    await prefs.remove(_movementsViewModeKey);
    await prefs.remove(_currencyKey);
  }
}
