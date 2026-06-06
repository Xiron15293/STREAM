import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _showNotesKey = 'show_notes';

  static Future<bool> loadShowNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showNotesKey) ?? false;
  }

  static Future<void> saveShowNotes(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showNotesKey, value);
  }
}
