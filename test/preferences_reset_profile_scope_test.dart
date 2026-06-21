import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'dashboard_net_worth_account_ids_profile_a': ['acc_a1', 'acc_a2'],
      'dashboard_net_worth_account_ids_profile_b': ['acc_b1'],
    });
    PreferencesService.netWorthAccountIdsNotifier.value = {'acc_b1'};
  });

  test('reset profile B does not clear profile A selection', () async {
    await PreferencesService.clearForReset(activeProfileId: 'profile_b');

    final prefs = await SharedPreferences.getInstance();

    // Profile A keeps its selection
    expect(
      prefs.getStringList('dashboard_net_worth_account_ids_profile_a'),
      ['acc_a1', 'acc_a2'],
    );

    // Profile B scoped key is removed
    expect(
      prefs.containsKey('dashboard_net_worth_account_ids_profile_b'),
      isFalse,
    );

    // Notifier resets to null
    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
  });

  test('reset profile A does not clear profile B selection', () async {
    await PreferencesService.clearForReset(activeProfileId: 'profile_a');

    final prefs = await SharedPreferences.getInstance();

    // Profile B keeps its selection
    expect(
      prefs.getStringList('dashboard_net_worth_account_ids_profile_b'),
      ['acc_b1'],
    );

    // Profile A scoped key is removed
    expect(
      prefs.containsKey('dashboard_net_worth_account_ids_profile_a'),
      isFalse,
    );

    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
  });

  test('reset without profileId does not touch scoped keys', () async {
    await PreferencesService.clearForReset();

    final prefs = await SharedPreferences.getInstance();

    // Both profile-scoped keys survive
    expect(
      prefs.containsKey('dashboard_net_worth_account_ids_profile_a'),
      isTrue,
    );
    expect(
      prefs.containsKey('dashboard_net_worth_account_ids_profile_b'),
      isTrue,
    );

    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
  });
}
