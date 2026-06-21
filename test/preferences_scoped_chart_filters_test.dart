import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/services/backup_service.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.chartsAccountFilterIdsNotifier.value = null;
    PreferencesService.chartsCategoryFilterIdsNotifier.value = null;
  });

  test('charts filters are profile-scoped', () async {
    await PreferencesService.saveChartsAccountFilterIds(
      {'acc_a'},
      profileId: 'profile_a',
    );
    await PreferencesService.saveChartsAccountFilterIds(
      {'acc_b'},
      profileId: 'profile_b',
    );

    expect(
      await PreferencesService.loadChartsAccountFilterIds(profileId: 'profile_a'),
      {'acc_a'},
    );
    expect(
      await PreferencesService.loadChartsAccountFilterIds(profileId: 'profile_b'),
      {'acc_b'},
    );
  });

  test('reset current profile does not clear other charts filters', () async {
    SharedPreferences.setMockInitialValues({
      'charts_filter_account_ids_profile_a': ['acc_a'],
      'charts_filter_account_ids_profile_b': <String>[],
      'charts_filter_category_ids_profile_a': ['exp_1'],
      'charts_filter_category_ids_profile_b': ['inc_1'],
    });

    await PreferencesService.clearForReset(activeProfileId: 'profile_b');
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getStringList('charts_filter_account_ids_profile_a'), ['acc_a']);
    expect(
      prefs.getStringList('charts_filter_category_ids_profile_a'),
      ['exp_1'],
    );
    expect(prefs.containsKey('charts_filter_account_ids_profile_b'), isFalse);
    expect(prefs.containsKey('charts_filter_category_ids_profile_b'), isFalse);
  });

  test('backup and restore preserve charts filters for current profile',
      () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await PreferencesService.saveChartsAccountFilterIds(
      <String>{},
      profileId: 'profile_b',
    );
    await PreferencesService.saveChartsCategoryFilterIds(
      {'exp_1'},
      profileId: 'profile_b',
    );

    final json = await BackupService.exportToJson(db, activeProfileId: 'profile_b');
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    final settings = parsed['settings'] as Map<String, dynamic>;
    expect(settings['chartsAccountFilterIds'], <String>[]);
    expect(settings['chartsCategoryFilterIds'], ['exp_1']);

    final restoreDb = AppDatabase();
    await restoreDb.addAccount(
      Account(
        id: 'acc_b',
        name: 'Cash',
        type: AccountType.cash,
        createdAt: DateTime.now(),
      ),
    );

    final validation = BackupService.validate(
      jsonEncode({
        'version': 2,
        'createdAt': '2026-06-21T00:00:00',
        'accounts': [
          {
            'id': 'acc_b',
            'name': 'Cash',
            'type': 'cash',
            'initialBalance': 0.0,
            'iconKey': 'wallet',
            'color': 4278190335,
            'archived': false,
            'createdAt': '2026-06-21T00:00:00.000',
            'updatedAt': '2026-06-21T00:00:00.000',
          }
        ],
        'categories': [
          {
            'id': 'exp_1',
            'name': 'Spesa',
            'type': 'expense',
            'color': 4278190335,
            'iconKey': 'shopping_cart',
            'archived': false,
          }
        ],
        'movements': [],
        'quickMovements': [],
        'favoriteMovements': [],
        'settings': settings,
      }),
    );

    await BackupService.restore(
      restoreDb,
      validation.data!,
      activeProfileId: 'profile_b',
    );

    expect(
      await PreferencesService.loadChartsAccountFilterIds(profileId: 'profile_b'),
      <String>{},
    );
    expect(
      await PreferencesService.loadChartsCategoryFilterIds(
        profileId: 'profile_b',
      ),
      {'exp_1'},
    );
    await sqlite.close();
  });
}
