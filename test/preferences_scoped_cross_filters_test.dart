import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.categoriesAccountFilterIdsNotifier.value = null;
    PreferencesService.accountsCategoryFilterIdsNotifier.value = null;
    PreferencesService.beneficiariesAccountFilterIdsNotifier.value = null;
    PreferencesService.beneficiariesCategoryFilterIdsNotifier.value = null;
  });

  test('cross filters are profile scoped', () async {
    await PreferencesService.saveCategoriesAccountFilterIds({
      'acc_a',
    }, profileId: 'profile_a');
    await PreferencesService.saveAccountsCategoryFilterIds({
      'exp_1',
    }, profileId: 'profile_b');
    await PreferencesService.saveBeneficiariesAccountFilterIds({
      'acc_b',
    }, profileId: 'profile_a');
    await PreferencesService.saveBeneficiariesCategoryFilterIds({
      'inc_1',
    }, profileId: 'profile_b');

    expect(
      await PreferencesService.loadCategoriesAccountFilterIds(
        profileId: 'profile_a',
      ),
      {'acc_a'},
    );
    expect(
      await PreferencesService.loadAccountsCategoryFilterIds(
        profileId: 'profile_b',
      ),
      {'exp_1'},
    );
    expect(
      await PreferencesService.loadBeneficiariesAccountFilterIds(
        profileId: 'profile_a',
      ),
      {'acc_b'},
    );
    expect(
      await PreferencesService.loadBeneficiariesCategoryFilterIds(
        profileId: 'profile_b',
      ),
      {'inc_1'},
    );
  });

  test('reset current profile does not clear other cross filters', () async {
    SharedPreferences.setMockInitialValues({
      'categories_filter_account_ids_profile_a': ['acc_a'],
      'categories_filter_account_ids_profile_b': ['acc_b'],
      'accounts_filter_category_ids_profile_a': ['exp_1'],
      'beneficiaries_filter_account_ids_profile_a': ['acc_a'],
      'beneficiaries_filter_category_ids_profile_b': ['inc_1'],
    });

    await PreferencesService.clearForReset(activeProfileId: 'profile_b');
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getStringList('categories_filter_account_ids_profile_a'), [
      'acc_a',
    ]);
    expect(prefs.getStringList('accounts_filter_category_ids_profile_a'), [
      'exp_1',
    ]);
    expect(prefs.getStringList('beneficiaries_filter_account_ids_profile_a'), [
      'acc_a',
    ]);
    expect(
      prefs.containsKey('categories_filter_account_ids_profile_b'),
      isFalse,
    );
    expect(
      prefs.containsKey('beneficiaries_filter_category_ids_profile_b'),
      isFalse,
    );
  });

  test(
    'sanitize keeps null and empty but invalid subset falls back to null',
    () {
      expect(
        PreferencesService.normalizeScopedFilterIds(null, const ['acc_a']),
        isNull,
      );
      expect(
        PreferencesService.normalizeScopedFilterIds(<String>{}, const [
          'acc_a',
        ]),
        <String>{},
      );
      expect(
        PreferencesService.normalizeScopedFilterIds(
          {'ghost_a', 'ghost_b'},
          const ['acc_a'],
        ),
        isNull,
      );
      expect(
        PreferencesService.normalizeScopedFilterIds(
          {'acc_a', 'ghost_b'},
          const ['acc_a', 'acc_b'],
        ),
        {'acc_a'},
      );
    },
  );
}
