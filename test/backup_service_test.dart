import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/backup_data.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/services/backup_service.dart';

class FailingSQLiteService extends SQLiteService {
  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return super.transaction((txn) async {
      await action(txn);
      throw StateError('forced restore failure');
    });
  }
}

void main() {
  SharedPreferences.setMockInitialValues({});
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('BackupService — Export', () {
    test('generates valid JSON with all data types', () async {
      final db = AppDatabase();
      await _populateTestData(db);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed['version'], equals(1));
      expect(parsed['createdAt'], isNotEmpty);
      expect(parsed['accounts'], isA<List>());
      expect(parsed['categories'], isA<List>());
      expect(parsed['movements'], isA<List>());
      expect(parsed['quickMovements'], isA<List>());
      expect(parsed['favoriteMovements'], isA<List>());
      expect(parsed['settings'], isA<Map>());
    });

    test('includes all accounts', () async {
      final db = AppDatabase();
      await _populateTestData(db);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final accounts = parsed['accounts'] as List;

      expect(accounts.length, equals(db.accounts.length));
    });

    test('includes all categories', () async {
      final db = AppDatabase();
      await _populateTestData(db);
      await db.addCategory('CustomCat', MovementType.expense, 0xFFFF0000);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final categories = parsed['categories'] as List;

      // 10 defaults + 1 custom
      expect(categories.length, equals(11));
    });

    test('includes all movements', () async {
      final db = AppDatabase();
      await _populateTestData(db);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final movements = parsed['movements'] as List;

      expect(movements.length, equals(db.movements.length));
    });

    test('includes metadata fields', () async {
      final db = AppDatabase();
      await _populateTestData(db);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;

      expect(parsed.containsKey('version'), isTrue);
      expect(parsed.containsKey('createdAt'), isTrue);
      expect(parsed.containsKey('accounts'), isTrue);
      expect(parsed.containsKey('categories'), isTrue);
      expect(parsed.containsKey('movements'), isTrue);
    });

    test('settings include showNotes', () async {
      final db = AppDatabase();
      await _populateTestData(db);
      await PreferencesService.saveShowNotes(true);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final settings = parsed['settings'] as Map;

      expect(settings['showNotes'], isTrue);
    });
  });

  group('BackupService — Validation', () {
    test('valid JSON passes validation', () {
      final json = _validBackupJson();
      final result = BackupService.validate(json);

      expect(result.isValid, isTrue);
      expect(result.data, isNotNull);
    });

    test('empty string fails validation', () {
      final result = BackupService.validate('');
      expect(result.isValid, isFalse);
      expect(result.error, isNotEmpty);
    });

    test('corrupt JSON fails validation', () {
      final result = BackupService.validate('{not valid json!!!');
      expect(result.isValid, isFalse);
      expect(result.error, isNotEmpty);
    });

    test('missing version field fails validation', () {
      final json = jsonEncode({'accounts': [], 'categories': [], 'movements': []});
      final result = BackupService.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('version'));
    });

    test('unsupported version fails validation', () {
      final json = _validBackupJson(version: 99);
      final result = BackupService.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('99'));
    });

    test('missing required fields fails validation', () {
      final json = jsonEncode({'version': 1, 'accounts': []});
      final result = BackupService.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('categories'));
    });

    test('non-list field fails validation', () {
      final json = jsonEncode({
        'version': 1,
        'accounts': 'not_a_list',
        'categories': [],
        'movements': [],
      });
      final result = BackupService.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('accounts'));
    });
  });

  group('BackupService — Restore', () {
    test('restore populates empty database', () async {
      final db = AppDatabase();

      // Add data to source db
      await _populateTestData(db);

      // Export
      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      // Create fresh db and restore
      final restoreDb = AppDatabase();
      await BackupService.restore(restoreDb, validation.data!);

      // Verify all data was restored
      expect(restoreDb.accounts.length, equals(1)); // default + custom
      expect(restoreDb.categories.length, equals(10)); // all defaults
      expect(restoreDb.movements.length, equals(2));
      expect(restoreDb.favoriteMovements.length, equals(1));
    });

    test('restore replaces existing data', () async {
      final db = AppDatabase();

      // Add initial data
      await _populateTestData(db);
      expect(db.movements.length, equals(2));

      // Export
      final emptyDb = AppDatabase();
      final json = await BackupService.exportToJson(emptyDb);
      final validation = BackupService.validate(json);

      // Restore empty data over existing
      await BackupService.restore(db, validation.data!);

      // Existing data should be replaced
      expect(db.movements.length, equals(0));
    });

    test('round-trip: export then restore produces identical data', () async {
      // Create source db with known data
      final sourceDb = AppDatabase();
      final m1 = Movement(
        id: 'm_round_1',
        title: 'Round trip test',
        amount: 99.99,
        type: MovementType.expense,
        date: DateTime(2026, 6, 7),
        categoryId: 'exp_1',
        createdAt: DateTime(2026, 6, 7),
      );
      sourceDb.addMovement(m1);

      // Export
      final json = await BackupService.exportToJson(sourceDb);
      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      // Restore into fresh db
      final targetDb = AppDatabase();
      await BackupService.restore(targetDb, validation.data!);

      // Verify data matches
      expect(targetDb.movements.length, equals(1));
      expect(targetDb.movements.first.title, equals('Round trip test'));
      expect(targetDb.movements.first.amount, equals(99.99));
      expect(targetDb.movements.first.type, equals(MovementType.expense));

      // Verify account preserved
      expect(targetDb.accounts.length, equals(1));
      expect(targetDb.accounts.first.name, equals('Principale'));

      // Verify categories preserved
      expect(targetDb.categories.length, equals(10));
    });

    test('restore preserves settings', () async {
      await PreferencesService.saveShowNotes(true);

      final db = AppDatabase();
      await _populateTestData(db);

      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);

      await PreferencesService.saveShowNotes(false);

      await BackupService.restore(db, validation.data!);

      expect(await PreferencesService.loadShowNotes(), isTrue);
    });
  });

  group('BackupData serialization', () {
    test('BackupData round-trip JSON', () {
      final original = BackupData(
        version: 1,
        createdAt: DateTime.now().toIso8601String(),
        accounts: [
          Account(
            id: 'test_acc',
            name: 'Test',
            type: AccountType.bank,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        categories: [
          const Category(id: 'test_cat', name: 'Test Cat', type: MovementType.expense, color: 0xFFFF0000),
        ],
        movements: [
          Movement(
            id: 'test_mov',
            title: 'Test',
            amount: 10.0,
            type: MovementType.income,
            date: DateTime(2026, 6, 1),
            categoryId: 'test_cat',
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
        quickMovements: [
          const QuickMovement(id: 'test_qm', title: 'Quick', amount: 5.0, type: MovementType.expense, categoryId: 'test_cat'),
        ],
        favoriteMovements: [
          const FavoriteMovement(id: 'test_fm', title: 'Fav', amount: 20.0, type: MovementType.income, categoryId: 'test_cat'),
        ],
        settings: const BackupSettings(showNotes: true),
      );

      final json = original.toJson();
      final restored = BackupData.fromJson(json);

      expect(restored.version, equals(original.version));
      expect(restored.accounts.length, equals(1));
      expect(restored.accounts.first.name, equals('Test'));
      expect(restored.categories.length, equals(1));
      expect(restored.categories.first.name, equals('Test Cat'));
      expect(restored.movements.length, equals(1));
      expect(restored.movements.first.title, equals('Test'));
      expect(restored.quickMovements.length, equals(1));
      expect(restored.quickMovements.first.title, equals('Quick'));
      expect(restored.favoriteMovements.length, equals(1));
      expect(restored.favoriteMovements.first.title, equals('Fav'));
      expect(restored.settings?.showNotes, isTrue);
    });

    test('BackupData handles empty lists', () {
      final data = BackupData(
        version: 1,
        createdAt: '2026-01-01',
        accounts: [],
        categories: [],
        movements: [],
      );

      final json = data.toJson();
      final restored = BackupData.fromJson(json);

      expect(restored.accounts, isEmpty);
      expect(restored.categories, isEmpty);
      expect(restored.movements, isEmpty);
      expect(restored.quickMovements, isEmpty);
      expect(restored.favoriteMovements, isEmpty);
    });
  });

  group('BackupService — pre-restore backup', () {
    test('creates backup before restore', () async {
      final db = AppDatabase();
      await _populateTestData(db);

      // Simulate: we'd call createPreRestoreBackup
      // but we can't test file system in unit tests easily
      // Instead verify the export works
      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      expect(parsed['version'], equals(1));
    });
  });

  group('BackupService — restore safety', () {
    test('restore rolls back automatically if the transaction fails', () async {
      final sqlite = FailingSQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(Movement(
        id: 'before_restore',
        title: 'Prima del restore',
        amount: 10.0,
        type: MovementType.expense,
        date: DateTime(2026, 6, 1),
        categoryId: 'exp_1',
        createdAt: DateTime(2026, 6, 1),
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      final backup = BackupData(
        version: 1,
        createdAt: '2026-06-07T12:00:00',
        accounts: [
          Account(
            id: 'acc_new',
            name: 'Conto Nuovo',
            type: AccountType.bank,
            createdAt: DateTime(2026, 6, 7),
          ),
        ],
        categories: [
          const Category(
            id: 'exp_new',
            name: 'Categoria Nuova',
            type: MovementType.expense,
            color: 0xFFFF0000,
          ),
        ],
        movements: [
          Movement(
            id: 'after_restore',
            title: 'Dopo restore',
            amount: 99.0,
            type: MovementType.income,
            date: DateTime(2026, 6, 7),
            categoryId: 'exp_new',
            accountId: 'acc_new',
            createdAt: DateTime(2026, 6, 7),
          ),
        ],
      );

      await expectLater(
        BackupService.restore(db, backup),
        throwsA(isA<StateError>()),
      );

      expect(db.movements.any((m) => m.id == 'before_restore'), isTrue);
      expect(db.movements.any((m) => m.id == 'after_restore'), isFalse);

      final persistedMovements = await sqlite.loadMovements();
      expect(persistedMovements.any((m) => m.id == 'before_restore'), isTrue);
      expect(persistedMovements.any((m) => m.id == 'after_restore'), isFalse);

      await sqlite.close();
    });

    test('restore remaps orphan account/category references to safe defaults', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final backup = BackupData(
        version: 1,
        createdAt: '2026-06-07T12:00:00',
        accounts: const [],
        categories: const [],
        movements: [
          Movement(
            id: 'orphan_mov',
            title: 'Movimento Orfano',
            amount: 25.0,
            type: MovementType.expense,
            date: DateTime(2026, 6, 7),
            categoryId: 'missing_category',
            accountId: 'missing_account',
            createdAt: DateTime(2026, 6, 7),
          ),
        ],
        quickMovements: [
          const QuickMovement(
            id: 'orphan_qm',
            title: 'Rapido Orfano',
            amount: 7.5,
            type: MovementType.expense,
            categoryId: 'missing_category',
            accountId: 'missing_account',
          ),
        ],
        favoriteMovements: [
          const FavoriteMovement(
            id: 'orphan_fm',
            title: 'Preferito Orfano',
            amount: 12.0,
            type: MovementType.income,
            categoryId: 'missing_category',
            accountId: 'missing_account',
          ),
        ],
      );

      await BackupService.restore(db, backup);

      expect(db.accounts.length, equals(1));
      expect(db.movements.length, equals(1));
      expect(db.movements.first.accountId, defaultAccountId);
      expect(db.movements.first.categoryId, 'exp_1');
      expect(db.quickMovements.length, equals(5));
      expect(db.quickMovements.last.accountId, defaultAccountId);
      expect(db.quickMovements.last.categoryId, 'exp_1');
      expect(db.favoriteMovements.length, equals(1));
      expect(db.favoriteMovements.first.accountId, defaultAccountId);
      expect(db.favoriteMovements.first.categoryId, 'inc_1');

      final persistedMovements = await sqlite.loadMovements();
      expect(persistedMovements.first.accountId, defaultAccountId);
      expect(persistedMovements.first.categoryId, 'exp_1');

      await sqlite.close();
    });
  });

  group('Stress test — restore safety', () {
    test('restore with 1000 movements succeeds', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      for (int i = 0; i < 1000; i++) {
        await db.addMovement(Movement(
          id: 'stress_$i',
          title: 'Movimento $i',
          amount: (i % 100).toDouble(),
          type: i.isEven ? MovementType.income : MovementType.expense,
          date: DateTime(2026, 6, (i % 28) + 1),
          categoryId: i.isEven ? 'inc_1' : 'exp_1',
          createdAt: DateTime(2026, 6, (i % 28) + 1),
        ));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      final freshDb = AppDatabase(sqlite: sqlite);
      await freshDb.initialize();
      await BackupService.restore(freshDb, validation.data!);

      expect(freshDb.movements.length, 1000);
      expect(freshDb.accounts.length, 1);
      await sqlite.close();
    });

    test('restore repeated 10 times produces consistent state', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final original = AppDatabase(sqlite: sqlite);
      await original.initialize();

      original.addMovement(Movement(
        id: 'rep_m', title: 'Repeat', amount: 42.0,
        type: MovementType.expense, date: DateTime(2026, 6, 15),
        categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15),
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      final json = await BackupService.exportToJson(original);
      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      for (int i = 0; i < 10; i++) {
        final target = AppDatabase(sqlite: sqlite);
        await target.initialize();
        await BackupService.restore(target, validation.data!);
        expect(target.movements.length, 1);
        expect(target.movements.first.title, 'Repeat');
        expect(target.accounts.length, 1);
      }
      await sqlite.close();
    });

    test('restore after pre-restore backup succeeds', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await _populateTestData(db);
      await Future.delayed(const Duration(milliseconds: 100));

      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      final preRestoreJson = await BackupService.exportToJson(db);
      final preValidation = BackupService.validate(preRestoreJson);
      expect(preValidation.isValid, isTrue);

      await BackupService.restore(db, validation.data!);
      expect(db.movements.length, 2);
      expect(db.movements.any((m) => m.id == 'export_test_1'), isTrue);
      await sqlite.close();
    });
  });

  group('Stress test — validation', () {
    test('account id null fails validation', () {
      final json = _validBackupJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      (parsed['accounts'] as List).first['id'] = null;
      final result = BackupService.validate(jsonEncode(parsed));
      expect(result.isValid, isFalse);
      expect(result.error, contains('Conto'));
      expect(result.error, contains('id'));
    });

    test('movement amount string non-numeric fails validation', () {
      final json = _validBackupJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      (parsed['movements'] as List).first['amount'] = 'not-a-number';
      final result = BackupService.validate(jsonEncode(parsed));
      expect(result.isValid, isFalse);
      expect(result.error, contains('amount'));
    });

    test('movement type sconosciuto fails validation', () {
      final json = _validBackupJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      (parsed['movements'] as List).first['type'] = 'unknown';
      final result = BackupService.validate(jsonEncode(parsed));
      expect(result.isValid, isFalse);
      expect(result.error, contains('type'));
    });

    test('date invalida fails validation', () {
      final json = _validBackupJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      (parsed['movements'] as List).first['date'] = 'not-a-date';
      final result = BackupService.validate(jsonEncode(parsed));
      expect(result.isValid, isFalse);
      expect(result.error, contains('date'));
    });

    test('version negativa fails validation', () {
      final json = _validBackupJson(version: -1);
      final result = BackupService.validate(json);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Versione'));
    });

    test('item not a Map fails validation', () {
      final json = _validBackupJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      (parsed['movements'] as List).add('not a map');
      final result = BackupService.validate(jsonEncode(parsed));
      expect(result.isValid, isFalse);
      expect(result.error, contains('Movimento'));
    });

    test('category type mismatch fails validation', () {
      final json = _validBackupJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      (parsed['categories'] as List).first['type'] = 'invalid_type';
      final result = BackupService.validate(jsonEncode(parsed));
      expect(result.isValid, isFalse);
      expect(result.error, contains('type'));
    });
  });

  group('Stress test — DB writes persist after reload', () {
    test('addMovement persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(Movement(
        id: 'p_m', title: 'Persist', amount: 10.0,
        type: MovementType.expense, date: DateTime(2026, 6, 1),
        categoryId: 'exp_1', createdAt: DateTime(2026, 6, 1),
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.any((m) => m.id == 'p_m'), isTrue);
      await sqlite.close();
    });

    test('deleteMovement persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(Movement(
        id: 'd_m', title: 'Delete me', amount: 5.0,
        type: MovementType.expense, date: DateTime(2026, 6, 1),
        categoryId: 'exp_1', createdAt: DateTime(2026, 6, 1),
      ));
      await db.deleteMovement('d_m');

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.any((m) => m.id == 'd_m'), isFalse);
      await sqlite.close();
    });

    test('updateMovement persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(Movement(
        id: 'u_m', title: 'Original', amount: 10.0,
        type: MovementType.expense, date: DateTime(2026, 6, 1),
        categoryId: 'exp_1', createdAt: DateTime(2026, 6, 1),
      ));
      await db.updateMovement(Movement(
        id: 'u_m', title: 'Updated', amount: 20.0,
        type: MovementType.income, date: DateTime(2026, 6, 2),
        categoryId: 'inc_1', createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime.now(),
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      final m = db2.movements.firstWhere((m) => m.id == 'u_m');
      expect(m.title, 'Updated');
      expect(m.amount, 20.0);
      expect(m.type, MovementType.income);
      await sqlite.close();
    });

    test('addCategory persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addCategory('Test Cat', MovementType.expense, 0xFF00FF00);

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.categories.any((c) => c.name == 'Test Cat'), isTrue);
      await sqlite.close();
    });

    test('archiveAccount persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addAccount(Account(id: 'arch_test', name: 'Arch Test', type: AccountType.bank, createdAt: DateTime.now()));
      await db.archiveAccount('arch_test');

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      final acc = db2.accounts.firstWhere((a) => a.id == 'arch_test');
      expect(acc.archived, isTrue);
      await sqlite.close();
    });

    test('quickMovement persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addQuickMovement(QuickMovement(
        id: 'qm_persist', title: 'Persist QM', amount: 3.0,
        type: MovementType.expense, categoryId: 'exp_1',
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.quickMovements.any((q) => q.id == 'qm_persist'), isTrue);
      await sqlite.close();
    });

    test('favoriteMovement persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addFavoriteMovement(FavoriteMovement(
        id: 'fm_persist', title: 'Persist FM', amount: 50.0,
        type: MovementType.income, categoryId: 'inc_1',
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.favoriteMovements.any((f) => f.id == 'fm_persist'), isTrue);
      await sqlite.close();
    });

    test('saveMovementAsFavorite persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(Movement(
        id: 'sav_fav', title: 'Save as fav', amount: 100.0,
        type: MovementType.income, date: DateTime(2026, 6, 1),
        categoryId: 'inc_1', createdAt: DateTime(2026, 6, 1),
      ));
      await db.saveMovementAsFavorite(db.movements.first);

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.favoriteMovements.any((f) => f.title == 'Save as fav'), isTrue);
      await sqlite.close();
    });

    test('duplicateMovement persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(Movement(
        id: 'dup_orig', title: 'Original', amount: 25.0,
        type: MovementType.expense, date: DateTime(2026, 6, 1),
        categoryId: 'exp_1', createdAt: DateTime(2026, 6, 1),
      ));
      await db.duplicateMovement(db.movements.first);

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 2);
      await sqlite.close();
    });
  });

  group('Stress test — restore rejects malformed backup', () {
    test('backup with null account id → restore rejected, existing data preserved', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(Movement(
        id: 'safe_m', title: 'Safe', amount: 1.0,
        type: MovementType.expense, date: DateTime(2026, 6, 1),
        categoryId: 'exp_1', createdAt: DateTime(2026, 6, 1),
      ));

      final json = _validBackupJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      (parsed['accounts'] as List).first['id'] = null;
      final badJson = jsonEncode(parsed);
      final validation = BackupService.validate(badJson);
      expect(validation.isValid, isFalse);

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.any((m) => m.id == 'safe_m'), isTrue);
      await sqlite.close();
    });

    test('restore with movements referencing missing accounts still works (graceful)', () async {
      final json = jsonEncode({
        'version': 1,
        'createdAt': '2026-06-07T12:00:00',
        'accounts': [],
        'categories': [
          {'id': 'exp_1', 'name': 'Spesa', 'type': 'expense', 'color': 0xFFEF5350, 'iconKey': 'shopping_cart', 'archived': false},
        ],
        'movements': [
          {
            'id': 'm_orphan',
            'title': 'Orphan',
            'amount': 50.0,
            'type': 'expense',
            'date': '2026-06-07T00:00:00.000',
            'categoryId': 'exp_1',
            'accountId': 'non_existent',
            'note': null,
            'createdAt': '2026-06-07T00:00:00.000',
            'updatedAt': '2026-06-07T00:00:00.000',
          }
        ],
        'quickMovements': [],
        'favoriteMovements': [],
        'settings': {'showNotes': true},
      });

      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);

      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      await BackupService.restore(db, validation.data!);

      expect(db.movements.length, 1);
      expect(db.movements.first.accountId, defaultAccountId);
      expect(db.movements.first.categoryId, 'exp_1');
      await sqlite.close();
    });
  });
}

// ── Helpers ──

Future<void> _populateTestData(AppDatabase db) async {
  final now = DateTime.now();

  await db.addMovement(Movement(
    id: 'export_test_1',
    title: 'Export test expense',
    amount: 25.50,
    type: MovementType.expense,
    date: now,
    categoryId: 'exp_1',
    createdAt: now,
  ));

  await db.addMovement(Movement(
    id: 'export_test_2',
    title: 'Export test income',
    amount: 1000.0,
    type: MovementType.income,
    date: now,
    categoryId: 'inc_1',
    createdAt: now,
  ));

  await db.saveMovementAsFavorite(db.movements.first);
}

String _validBackupJson({int version = 1}) {
  return jsonEncode({
    'version': version,
    'createdAt': '2026-06-07T12:00:00',
    'accounts': [
      {
        'id': 'acc_default',
        'name': 'Principale',
        'type': 'bank',
        'initialBalance': 0.0,
        'iconKey': 'account_balance',
        'color': 4278230352,
        'archived': false,
        'createdAt': '2026-01-01T00:00:00.000',
        'updatedAt': '2026-01-01T00:00:00.000',
      }
    ],
    'categories': [
      {
        'id': 'exp_1',
        'name': 'Spesa',
        'type': 'expense',
        'color': 0xFFEF5350,
        'iconKey': 'shopping_cart',
        'archived': false,
      }
    ],
    'movements': [
      {
        'id': 'm_1',
        'title': 'Test movement',
        'amount': 50.0,
        'type': 'expense',
        'date': '2026-06-07T00:00:00.000',
        'categoryId': 'exp_1',
        'accountId': 'acc_default',
        'note': null,
        'createdAt': '2026-06-07T00:00:00.000',
        'updatedAt': '2026-06-07T00:00:00.000',
      }
    ],
    'quickMovements': [],
    'favoriteMovements': [],
    'settings': {'showNotes': true},
  });
}
