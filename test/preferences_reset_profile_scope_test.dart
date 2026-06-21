import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'dashboard_net_worth_account_ids_profile_a': ['acc_a1', 'acc_a2'],
      'dashboard_net_worth_account_ids_profile_b': ['acc_b1'],
      'movements_filter_account_ids_profile_a': ['acc_a1'],
      'movements_filter_account_ids_profile_b': ['acc_b1'],
      'movements_filter_category_ids_profile_a': ['cat_a1'],
      'movements_filter_category_ids_profile_b': ['cat_b1'],
      'charts_filter_account_ids_profile_a': ['acc_a1'],
      'charts_filter_account_ids_profile_b': ['acc_b1'],
      'charts_filter_category_ids_profile_a': ['cat_a1'],
      'charts_filter_category_ids_profile_b': ['cat_b1'],
    });
    PreferencesService.netWorthAccountIdsNotifier.value = {'acc_b1'};
    PreferencesService.movementsAccountFilterIdsNotifier.value = {'acc_b1'};
    PreferencesService.movementsCategoryFilterIdsNotifier.value = {'cat_b1'};
    PreferencesService.chartsAccountFilterIdsNotifier.value = {'acc_b1'};
    PreferencesService.chartsCategoryFilterIdsNotifier.value = {'cat_b1'};
  });

  test('reset profile B does not clear profile A selection', () async {
    await PreferencesService.clearForReset(activeProfileId: 'profile_b');

    final prefs = await SharedPreferences.getInstance();

    // Profile A keeps its selection
    expect(
      prefs.getStringList('dashboard_net_worth_account_ids_profile_a'),
      ['acc_a1', 'acc_a2'],
    );
    expect(
      prefs.getStringList('movements_filter_account_ids_profile_a'),
      ['acc_a1'],
    );
    expect(
      prefs.getStringList('movements_filter_category_ids_profile_a'),
      ['cat_a1'],
    );
    expect(
      prefs.getStringList('charts_filter_account_ids_profile_a'),
      ['acc_a1'],
    );
    expect(
      prefs.getStringList('charts_filter_category_ids_profile_a'),
      ['cat_a1'],
    );

    // Profile B scoped key is removed
    expect(
      prefs.containsKey('dashboard_net_worth_account_ids_profile_b'),
      isFalse,
    );
    expect(prefs.containsKey('movements_filter_account_ids_profile_b'), isFalse);
    expect(
      prefs.containsKey('movements_filter_category_ids_profile_b'),
      isFalse,
    );
    expect(prefs.containsKey('charts_filter_account_ids_profile_b'), isFalse);
    expect(
      prefs.containsKey('charts_filter_category_ids_profile_b'),
      isFalse,
    );

    // Notifier resets to null
    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    expect(PreferencesService.movementsAccountFilterIdsNotifier.value, isNull);
    expect(PreferencesService.movementsCategoryFilterIdsNotifier.value, isNull);
    expect(PreferencesService.chartsAccountFilterIdsNotifier.value, isNull);
    expect(PreferencesService.chartsCategoryFilterIdsNotifier.value, isNull);
  });

  test('reset profile A does not clear profile B selection', () async {
    await PreferencesService.clearForReset(activeProfileId: 'profile_a');

    final prefs = await SharedPreferences.getInstance();

    // Profile B keeps its selection
    expect(
      prefs.getStringList('dashboard_net_worth_account_ids_profile_b'),
      ['acc_b1'],
    );
    expect(
      prefs.getStringList('movements_filter_account_ids_profile_b'),
      ['acc_b1'],
    );
    expect(
      prefs.getStringList('movements_filter_category_ids_profile_b'),
      ['cat_b1'],
    );
    expect(
      prefs.getStringList('charts_filter_account_ids_profile_b'),
      ['acc_b1'],
    );
    expect(
      prefs.getStringList('charts_filter_category_ids_profile_b'),
      ['cat_b1'],
    );

    // Profile A scoped key is removed
    expect(
      prefs.containsKey('dashboard_net_worth_account_ids_profile_a'),
      isFalse,
    );
    expect(prefs.containsKey('movements_filter_account_ids_profile_a'), isFalse);
    expect(
      prefs.containsKey('movements_filter_category_ids_profile_a'),
      isFalse,
    );
    expect(prefs.containsKey('charts_filter_account_ids_profile_a'), isFalse);
    expect(
      prefs.containsKey('charts_filter_category_ids_profile_a'),
      isFalse,
    );

    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    expect(PreferencesService.movementsAccountFilterIdsNotifier.value, isNull);
    expect(PreferencesService.movementsCategoryFilterIdsNotifier.value, isNull);
    expect(PreferencesService.chartsAccountFilterIdsNotifier.value, isNull);
    expect(PreferencesService.chartsCategoryFilterIdsNotifier.value, isNull);
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
    expect(prefs.containsKey('movements_filter_account_ids_profile_a'), isTrue);
    expect(prefs.containsKey('movements_filter_account_ids_profile_b'), isTrue);
    expect(prefs.containsKey('charts_filter_account_ids_profile_a'), isTrue);
    expect(prefs.containsKey('charts_filter_account_ids_profile_b'), isTrue);
    expect(
      prefs.containsKey('movements_filter_category_ids_profile_a'),
      isTrue,
    );
    expect(
      prefs.containsKey('movements_filter_category_ids_profile_b'),
      isTrue,
    );
    expect(
      prefs.containsKey('charts_filter_category_ids_profile_a'),
      isTrue,
    );
    expect(
      prefs.containsKey('charts_filter_category_ids_profile_b'),
      isTrue,
    );

    expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    expect(PreferencesService.movementsAccountFilterIdsNotifier.value, isNull);
    expect(PreferencesService.movementsCategoryFilterIdsNotifier.value, isNull);
    expect(PreferencesService.chartsAccountFilterIdsNotifier.value, isNull);
    expect(PreferencesService.chartsCategoryFilterIdsNotifier.value, isNull);
  });
}
