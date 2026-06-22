import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/stream_kpi_style.dart';
import '../design/stream_theme_palette.dart';
import '../utils/heatmap_utils.dart';

enum AppCurrency { eur, usd, gbp, chf, jpy }

class PreferencesService {
  static const _showNotesKey = 'show_notes';
  static const _lastBackupDateKey = 'last_backup_date';
  static const _categoryLayoutKey = 'category_layout';
  static const _currencyKey = 'app_currency';
  static const _themeIdKey = 'theme_id';
  static const _kpiStyleKey = 'kpi_style';
  static const _chartStyleKey = 'chart_style';
  static const heatmapThresholdsKey = 'heatmap_thresholds';
  static const heatmapColorsKey = 'heatmap_colors';

  static const defaultCategoryLayout = 'cleanList';
  static const defaultCurrency = AppCurrency.eur;
  static const defaultThemeId = 'streamClassic';
  static const defaultKpiStyle = 'automatic';
  static const defaultChartStyle = 'automatic';
  static const defaultHeatmapSettings = HeatmapSettings.defaults;

  static final categoryLayoutNotifier = ValueNotifier<String>(
    defaultCategoryLayout,
  );
  static final heatmapSettingsNotifier = ValueNotifier<HeatmapSettings>(
    defaultHeatmapSettings,
  );
  static final currencyNotifier = ValueNotifier<AppCurrency>(defaultCurrency);
  static final themeIdNotifier = ValueNotifier<String>(defaultThemeId);
  static final kpiStyleNotifier = ValueNotifier<String>(defaultKpiStyle);
  static final chartStyleNotifier = ValueNotifier<String>(defaultChartStyle);

  static final showNotesNotifier = ValueNotifier<bool>(false);

  static Future<bool> loadShowNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_showNotesKey) ?? false;
    showNotesNotifier.value = value;
    return value;
  }

  static Future<void> saveShowNotes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNotesKey, value);
    showNotesNotifier.value = value;
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
  static const _netWorthAccountIdsKeyPrefix =
      'dashboard_net_worth_account_ids_';
  static const _movementsAccountFilterIdsKeyPrefix =
      'movements_filter_account_ids_';
  static const _movementsCategoryFilterIdsKeyPrefix =
      'movements_filter_category_ids_';
  static const _chartsAccountFilterIdsKeyPrefix = 'charts_filter_account_ids_';
  static const _chartsCategoryFilterIdsKeyPrefix =
      'charts_filter_category_ids_';
  static const _categoriesAccountFilterIdsKeyPrefix =
      'categories_filter_account_ids_';
  static const _accountsCategoryFilterIdsKeyPrefix =
      'accounts_filter_category_ids_';
  static const _beneficiariesAccountFilterIdsKeyPrefix =
      'beneficiaries_filter_account_ids_';
  static const _beneficiariesCategoryFilterIdsKeyPrefix =
      'beneficiaries_filter_category_ids_';
  static const _hiddenChartIdsKey = 'hidden_chart_ids';

  static final netWorthAccountIdsNotifier = ValueNotifier<Set<String>?>(null);
  static final movementsAccountFilterIdsNotifier = ValueNotifier<Set<String>?>(
    null,
  );
  static final movementsCategoryFilterIdsNotifier = ValueNotifier<Set<String>?>(
    null,
  );
  static final chartsAccountFilterIdsNotifier = ValueNotifier<Set<String>?>(
    null,
  );
  static final chartsCategoryFilterIdsNotifier = ValueNotifier<Set<String>?>(
    null,
  );
  static final categoriesAccountFilterIdsNotifier = ValueNotifier<Set<String>?>(
    null,
  );
  static final accountsCategoryFilterIdsNotifier = ValueNotifier<Set<String>?>(
    null,
  );
  static final beneficiariesAccountFilterIdsNotifier =
      ValueNotifier<Set<String>?>(null);
  static final beneficiariesCategoryFilterIdsNotifier =
      ValueNotifier<Set<String>?>(null);
  static final hiddenChartIdsNotifier = ValueNotifier<Set<String>>({});

  static String _dashboardNetWorthAccountIdsKey({String? profileId}) {
    if (profileId == null || profileId.trim().isEmpty) {
      return _netWorthAccountIdsKey;
    }
    return '$_netWorthAccountIdsKeyPrefix${profileId.trim()}';
  }

  static String _movementsAccountFilterIdsKey({required String profileId}) {
    return '$_movementsAccountFilterIdsKeyPrefix${profileId.trim()}';
  }

  static String _movementsCategoryFilterIdsKey({required String profileId}) {
    return '$_movementsCategoryFilterIdsKeyPrefix${profileId.trim()}';
  }

  static String _chartsAccountFilterIdsKey({required String profileId}) {
    return '$_chartsAccountFilterIdsKeyPrefix${profileId.trim()}';
  }

  static String _chartsCategoryFilterIdsKey({required String profileId}) {
    return '$_chartsCategoryFilterIdsKeyPrefix${profileId.trim()}';
  }

  static String _categoriesAccountFilterIdsKey({required String profileId}) {
    return '$_categoriesAccountFilterIdsKeyPrefix${profileId.trim()}';
  }

  static String _accountsCategoryFilterIdsKey({required String profileId}) {
    return '$_accountsCategoryFilterIdsKeyPrefix${profileId.trim()}';
  }

  static String _beneficiariesAccountFilterIdsKey({required String profileId}) {
    return '$_beneficiariesAccountFilterIdsKeyPrefix${profileId.trim()}';
  }

  static String _beneficiariesCategoryFilterIdsKey({
    required String profileId,
  }) {
    return '$_beneficiariesCategoryFilterIdsKeyPrefix${profileId.trim()}';
  }

  static Set<String>? normalizeScopedFilterIds(
    Set<String>? ids,
    Iterable<String> validIds,
  ) {
    if (ids == null) return null;
    if (ids.isEmpty) return <String>{};

    final validIdSet = validIds.toSet();
    final sanitized = ids.intersection(validIdSet);
    if (sanitized.isEmpty) {
      return null;
    }
    if (sanitized.length == validIdSet.length) {
      return null;
    }
    return sanitized;
  }

  static Future<Set<String>?> loadDashboardNetWorthAccountIds({
    String? profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _dashboardNetWorthAccountIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    netWorthAccountIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveDashboardNetWorthAccountIds(
    Set<String>? ids, {
    String? profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _dashboardNetWorthAccountIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      netWorthAccountIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    netWorthAccountIdsNotifier.value = ids;
  }

  static Future<void> clearDashboardNetWorthAccountSelection({
    String? profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dashboardNetWorthAccountIdsKey(profileId: profileId));
    netWorthAccountIdsNotifier.value = null;
  }

  static Future<Set<String>?> loadMovementsAccountFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _movementsAccountFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    movementsAccountFilterIdsNotifier.value = result;
    return movementsAccountFilterIdsNotifier.value;
  }

  static Future<void> saveMovementsAccountFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _movementsAccountFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      movementsAccountFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    movementsAccountFilterIdsNotifier.value = ids;
  }

  static Future<Set<String>?> loadMovementsCategoryFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _movementsCategoryFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    movementsCategoryFilterIdsNotifier.value = result;
    return movementsCategoryFilterIdsNotifier.value;
  }

  static Future<void> saveMovementsCategoryFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _movementsCategoryFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      movementsCategoryFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    movementsCategoryFilterIdsNotifier.value = ids;
  }

  static Future<Set<String>?> loadChartsAccountFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _chartsAccountFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    chartsAccountFilterIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveChartsAccountFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _chartsAccountFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      chartsAccountFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    chartsAccountFilterIdsNotifier.value = ids;
  }

  static Future<Set<String>?> loadChartsCategoryFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _chartsCategoryFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    chartsCategoryFilterIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveChartsCategoryFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _chartsCategoryFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      chartsCategoryFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    chartsCategoryFilterIdsNotifier.value = ids;
  }

  static Future<Set<String>?> loadCategoriesAccountFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _categoriesAccountFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    categoriesAccountFilterIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveCategoriesAccountFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _categoriesAccountFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      categoriesAccountFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    categoriesAccountFilterIdsNotifier.value = ids;
  }

  static Future<Set<String>?> loadAccountsCategoryFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _accountsCategoryFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    accountsCategoryFilterIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveAccountsCategoryFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _accountsCategoryFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      accountsCategoryFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    accountsCategoryFilterIdsNotifier.value = ids;
  }

  static Future<Set<String>?> loadBeneficiariesAccountFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _beneficiariesAccountFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    beneficiariesAccountFilterIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveBeneficiariesAccountFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _beneficiariesAccountFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      beneficiariesAccountFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    beneficiariesAccountFilterIdsNotifier.value = ids;
  }

  static Future<Set<String>?> loadBeneficiariesCategoryFilterIds({
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(
      _beneficiariesCategoryFilterIdsKey(profileId: profileId),
    );
    final result = list?.toSet();
    beneficiariesCategoryFilterIdsNotifier.value = result;
    return result;
  }

  static Future<void> saveBeneficiariesCategoryFilterIds(
    Set<String>? ids, {
    required String profileId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _beneficiariesCategoryFilterIdsKey(profileId: profileId);
    if (ids == null) {
      await prefs.remove(key);
      beneficiariesCategoryFilterIdsNotifier.value = null;
      return;
    }
    await prefs.setStringList(key, ids.toList());
    beneficiariesCategoryFilterIdsNotifier.value = ids;
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

  static Future<void> clearForReset({String? activeProfileId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_showNotesKey);
    await prefs.remove(_lastBackupDateKey);
    await prefs.remove(_categoryLayoutKey);
    await prefs.remove(_currencyKey);
    await prefs.remove(_themeIdKey);
    await prefs.remove(_kpiStyleKey);
    await prefs.remove(_chartStyleKey);
    await prefs.remove(_netWorthAccountIdsKey);
    await prefs.remove(_hiddenChartIdsKey);

    // Only remove the scoped key for the active profile, not all profiles
    if (activeProfileId != null && activeProfileId.trim().isNotEmpty) {
      await prefs.remove(
        _dashboardNetWorthAccountIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _movementsAccountFilterIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _movementsCategoryFilterIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _chartsAccountFilterIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _chartsCategoryFilterIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _categoriesAccountFilterIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _accountsCategoryFilterIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _beneficiariesAccountFilterIdsKey(profileId: activeProfileId),
      );
      await prefs.remove(
        _beneficiariesCategoryFilterIdsKey(profileId: activeProfileId),
      );
    }

    showNotesNotifier.value = false;
    categoryLayoutNotifier.value = defaultCategoryLayout;
    currencyNotifier.value = defaultCurrency;
    themeIdNotifier.value = defaultThemeId;
    kpiStyleNotifier.value = defaultKpiStyle;
    chartStyleNotifier.value = defaultChartStyle;
    hiddenChartIdsNotifier.value = {};
    netWorthAccountIdsNotifier.value = null;
    movementsAccountFilterIdsNotifier.value = null;
    movementsCategoryFilterIdsNotifier.value = null;
    chartsAccountFilterIdsNotifier.value = null;
    chartsCategoryFilterIdsNotifier.value = null;
    categoriesAccountFilterIdsNotifier.value = null;
    accountsCategoryFilterIdsNotifier.value = null;
    beneficiariesAccountFilterIdsNotifier.value = null;
    beneficiariesCategoryFilterIdsNotifier.value = null;
  }
}
