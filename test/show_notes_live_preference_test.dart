import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.showNotesNotifier.value = false;
  });

  test('saveShowNotes updates notifier', () async {
    expect(PreferencesService.showNotesNotifier.value, false);

    await PreferencesService.saveShowNotes(true);
    expect(PreferencesService.showNotesNotifier.value, true);

    await PreferencesService.saveShowNotes(false);
    expect(PreferencesService.showNotesNotifier.value, false);
  });

  test('loadShowNotes updates notifier', () async {
    SharedPreferences.setMockInitialValues({'show_notes': true});

    await PreferencesService.loadShowNotes();
    expect(PreferencesService.showNotesNotifier.value, true);
  });

  test('clearForReset resets showNotes notifier to false', () async {
    PreferencesService.showNotesNotifier.value = true;

    await PreferencesService.clearForReset();
    expect(PreferencesService.showNotesNotifier.value, false);
  });
}
