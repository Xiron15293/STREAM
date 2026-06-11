import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MovementsViewMode { listHeatmap, calendar, advancedHeatmap }

class PreferencesService {
  static const _showNotesKey = 'show_notes';
  static const _lastBackupDateKey = 'last_backup_date';
  static const _categoryLayoutKey = 'category_layout';
  static const _movementsViewModeKey = 'movements_view_mode';

  static const defaultCategoryLayout = 'cleanList';
  static const defaultMovementsViewMode = MovementsViewMode.listHeatmap;

  static final categoryLayoutNotifier = ValueNotifier<String>(
    defaultCategoryLayout,
  );
  static final movementsViewModeNotifier = ValueNotifier<MovementsViewMode>(
    defaultMovementsViewMode,
  );

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
    if (value == null) return defaultMovementsViewMode;
    return MovementsViewMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => defaultMovementsViewMode,
    );
  }

  static Future<void> saveMovementsViewMode(MovementsViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_movementsViewModeKey, mode.name);
    movementsViewModeNotifier.value = mode;
  }

  static Future<void> clearForReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_showNotesKey);
    await prefs.remove(_lastBackupDateKey);
    await prefs.remove(_categoryLayoutKey);
    await prefs.remove(_movementsViewModeKey);
  }
}
