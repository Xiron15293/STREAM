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
  });

  test('backup includes new cross filters for current profile', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await PreferencesService.saveCategoriesAccountFilterIds({
      'acc_1',
    }, profileId: 'profile_test');
    await PreferencesService.saveAccountsCategoryFilterIds(
      <String>{},
      profileId: 'profile_test',
    );
    await PreferencesService.saveBeneficiariesAccountFilterIds({
      'acc_2',
    }, profileId: 'profile_test');
    await PreferencesService.saveBeneficiariesCategoryFilterIds({
      'exp_1',
    }, profileId: 'profile_test');

    final json = await BackupService.exportToJson(
      db,
      profileId: 'profile_test',
    );
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    final settings = parsed['settings'] as Map<String, dynamic>;

    expect(settings['categoriesFilterAccountIds'], ['acc_1']);
    expect(settings['accountsFilterCategoryIds'], <String>[]);
    expect(settings['beneficiariesFilterAccountIds'], ['acc_2']);
    expect(settings['beneficiariesFilterCategoryIds'], ['exp_1']);
    await sqlite.close();
  });

  test('restore sanitizes and scopes new cross filters', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();
    await db.addAccount(
      Account(
        id: 'acc_valid',
        name: 'Valid',
        type: AccountType.bank,
        createdAt: DateTime.now(),
      ),
    );

    final validation = BackupService.validate(
      jsonEncode({
        'version': 2,
        'createdAt': '2026-06-22T00:00:00',
        'accounts': [
          {
            'id': 'acc_valid',
            'name': 'Valid',
            'type': 'bank',
            'initialBalance': 0.0,
            'iconKey': 'account_balance',
            'color': 4278190335,
            'archived': false,
            'createdAt': '2026-06-22T00:00:00.000',
            'updatedAt': '2026-06-22T00:00:00.000',
          },
        ],
        'categories': [
          {
            'id': 'exp_1',
            'name': 'Spesa',
            'type': 'expense',
            'color': 4278190335,
            'iconKey': 'shopping_cart',
            'archived': false,
          },
        ],
        'movements': [],
        'quickMovements': [],
        'favoriteMovements': [],
        'settings': {
          'showNotes': false,
          'categoriesFilterAccountIds': ['ghost_acc'],
          'accountsFilterCategoryIds': ['exp_1', 'ghost_cat'],
          'beneficiariesFilterAccountIds': <String>[],
          'beneficiariesFilterCategoryIds': ['ghost_cat'],
        },
      }),
    );

    await BackupService.restore(
      db,
      validation.data!,
      activeProfileId: 'profile_b',
    );

    expect(
      await PreferencesService.loadCategoriesAccountFilterIds(
        profileId: 'profile_b',
      ),
      isNull,
    );
    expect(
      await PreferencesService.loadAccountsCategoryFilterIds(
        profileId: 'profile_b',
      ),
      {'exp_1'},
    );
    expect(
      await PreferencesService.loadBeneficiariesAccountFilterIds(
        profileId: 'profile_b',
      ),
      <String>{},
    );
    expect(
      await PreferencesService.loadBeneficiariesCategoryFilterIds(
        profileId: 'profile_b',
      ),
      isNull,
    );
    await sqlite.close();
  });
}
