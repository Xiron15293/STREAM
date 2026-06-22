import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/services/backup_service.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Backup includes preferences', () {
    test('backup includes showNotes', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveShowNotes(true);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['showNotes'], isTrue);
      await sqlite.close();
    });

    test('backup includes chartStyle', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveChartStyleId('technical');

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['chartStyle'], 'technical');
      await sqlite.close();
    });

    test('backup includes kpiStyle', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveKpiStyleId('dense');

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['kpiStyle'], 'dense');
      await sqlite.close();
    });

    test('backup includes hiddenChartIds', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveHiddenChartIds({'chart_a', 'chart_b'});

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['hiddenChartIds'], ['chart_a', 'chart_b']);
      await sqlite.close();
    });

    test('backup includes netWorthAccountIds per profile', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveDashboardNetWorthAccountIds({
        'acc_1',
        'acc_2',
      }, profileId: 'profile_test');

      final json = await BackupService.exportToJson(
        db,
        profileId: 'profile_test',
      );
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['netWorthAccountIds'], ['acc_1', 'acc_2']);
      await sqlite.close();
    });

    test('backup preserves empty netWorthAccountIds none-state', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveDashboardNetWorthAccountIds(
        <String>{},
        profileId: 'profile_test',
      );

      final json = await BackupService.exportToJson(
        db,
        profileId: 'profile_test',
      );
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['netWorthAccountIds'], <String>[]);
      await sqlite.close();
    });

    test('backup includes movements filters per profile', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveMovementsAccountFilterIds(
        <String>{},
        profileId: 'profile_test',
      );
      await PreferencesService.saveMovementsCategoryFilterIds({
        'exp_1',
        'inc_1',
      }, profileId: 'profile_test');

      final json = await BackupService.exportToJson(
        db,
        profileId: 'profile_test',
      );
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['movementsAccountFilterIds'], <String>[]);
      expect(settings['movementsCategoryFilterIds'], ['exp_1', 'inc_1']);
      await sqlite.close();
    });

    test(
      'backup includes charts filters per profile including empty none-state',
      () async {
        final sqlite = SQLiteService();
        await sqlite.open(path: inMemoryDatabasePath);
        final db = AppDatabase(sqlite: sqlite);
        await db.initialize();
        await PreferencesService.saveChartsAccountFilterIds(
          <String>{},
          profileId: 'profile_test',
        );
        await PreferencesService.saveChartsCategoryFilterIds({
          'exp_1',
          'inc_1',
        }, profileId: 'profile_test');

        final json = await BackupService.exportToJson(
          db,
          profileId: 'profile_test',
        );
        final parsed = jsonDecode(json) as Map<String, dynamic>;
        final settings = parsed['settings'] as Map;

        expect(settings['chartsAccountFilterIds'], <String>[]);
        expect(settings['chartsCategoryFilterIds'], ['exp_1', 'inc_1']);
        await sqlite.close();
      },
    );

    test('backup includes categoryLayout', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await PreferencesService.saveCategoryLayout('treemap');

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['categoryLayout'], 'treemap');
      await sqlite.close();
    });

    test('backup does not export default values to keep JSON lean', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map?;

      // With all defaults, settings should only contain showNotes
      expect(settings!['chartStyle'], isNull);
      expect(settings['kpiStyle'], isNull);
      expect(settings['hiddenChartIds'], isNull);
      expect(settings['netWorthAccountIds'], isNull);
      expect(settings['movementsAccountFilterIds'], isNull);
      expect(settings['movementsCategoryFilterIds'], isNull);
      expect(settings['chartsAccountFilterIds'], isNull);
      expect(settings['chartsCategoryFilterIds'], isNull);
      expect(settings['categoryLayout'], isNull);
      await sqlite.close();
    });
  });
}
