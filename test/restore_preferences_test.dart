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

  group('Restore preferences', () {
    test('restore new backup applies all preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveShowNotes(true);
      await PreferencesService.saveChartStyleId('technical');
      await PreferencesService.saveKpiStyleId('dense');
      await PreferencesService.saveHiddenChartIds({'chart_x'});
      await PreferencesService.saveCategoryLayout('treemap');

      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);

      // Reset prefs to defaults
      SharedPreferences.setMockInitialValues({});

      await BackupService.restore(db, validation.data!);

      expect(await PreferencesService.loadShowNotes(), isTrue);
      expect(await PreferencesService.loadChartStyleId(), 'technical');
      expect(await PreferencesService.loadKpiStyleId(), 'dense');
      expect(await PreferencesService.loadHiddenChartIds(), {'chart_x'});
      expect(await PreferencesService.loadCategoryLayout(), 'treemap');
      await sqlite.close();
    });

    test('restore old backup without new fields does not crash', () async {
      SharedPreferences.setMockInitialValues({});
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final oldJson = jsonEncode({
        'version': 2,
        'createdAt': '2026-06-01T00:00:00',
        'accounts': [],
        'categories': [],
        'movements': [],
        'quickMovements': [],
        'favoriteMovements': [],
        'settings': {'showNotes': true},
      });

      final validation = BackupService.validate(oldJson);
      expect(validation.isValid, isTrue);

      await BackupService.restore(db, validation.data!);

      expect(await PreferencesService.loadShowNotes(), isTrue);
      // Missing fields should not crash, defaults used
      expect(await PreferencesService.loadChartStyleId(), 'automatic');
      expect(await PreferencesService.loadKpiStyleId(), 'automatic');
      expect(await PreferencesService.loadHiddenChartIds(), isEmpty);
      expect(await PreferencesService.loadCategoryLayout(), 'cleanList');
      await sqlite.close();
    });

    test('restore updates live notifiers', () async {
      SharedPreferences.setMockInitialValues({});
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveShowNotes(true);
      await PreferencesService.saveChartStyleId('editorial');

      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);

      // Reset notifiers
      PreferencesService.showNotesNotifier.value = false;
      PreferencesService.chartStyleNotifier.value = 'automatic';

      await BackupService.restore(db, validation.data!);

      expect(PreferencesService.showNotesNotifier.value, true);
      expect(PreferencesService.chartStyleNotifier.value, 'editorial');
      await sqlite.close();
    });

    test('restore sanitizes invalid netWorthAccountIds', () async {
      SharedPreferences.setMockInitialValues({});
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      // Add a valid account via DB directly
      final acc = Account(
        id: 'valid_acc',
        name: 'Valid',
        type: AccountType.bank,
        createdAt: DateTime.now(),
      );
      await db.addAccount(acc);

      final json = jsonEncode({
        'version': 2,
        'createdAt': '2026-06-01T00:00:00',
        'accounts': [
          {
            'id': 'valid_acc',
            'name': 'Valid',
            'type': 'bank',
            'initialBalance': 0.0,
            'iconKey': 'account_balance',
            'color': 4278230352,
            'archived': false,
            'createdAt': '2026-01-01T00:00:00.000',
            'updatedAt': '2026-01-01T00:00:00.000',
          }
        ],
        'categories': [],
        'movements': [],
        'quickMovements': [],
        'favoriteMovements': [],
        'settings': {
          'showNotes': false,
          'netWorthAccountIds': ['valid_acc', 'invalid_acc', 'also_invalid'],
        },
      });

      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      await BackupService.restore(
        db,
        validation.data!,
        activeProfileId: 'profile_b',
      );

      final restoredIds =
          await PreferencesService.loadDashboardNetWorthAccountIds(
            profileId: 'profile_b',
          );
      // Only valid_acc should survive
      expect(restoredIds, {'valid_acc'});
      await sqlite.close();
    });

    test('restore falls back to Tutti i conti when all ids invalid', () async {
      SharedPreferences.setMockInitialValues({});
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final json = jsonEncode({
        'version': 2,
        'createdAt': '2026-06-01T00:00:00',
        'accounts': [],
        'categories': [],
        'movements': [],
        'quickMovements': [],
        'favoriteMovements': [],
        'settings': {
          'showNotes': false,
          'netWorthAccountIds': ['nonexistent_1', 'nonexistent_2'],
        },
      });

      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      await BackupService.restore(
        db,
        validation.data!,
        activeProfileId: 'profile_b',
      );

      final restoredIds =
          await PreferencesService.loadDashboardNetWorthAccountIds(
            profileId: 'profile_b',
          );
      expect(restoredIds, isNull);
      expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
      await sqlite.close();
    });
  });
}
