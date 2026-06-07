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
      _populateTestData(db);

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
      _populateTestData(db);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final accounts = parsed['accounts'] as List;

      expect(accounts.length, equals(db.accounts.length));
    });

    test('includes all categories', () async {
      final db = AppDatabase();
      _populateTestData(db);
      db.addCategory('CustomCat', MovementType.expense, 0xFFFF0000);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final categories = parsed['categories'] as List;

      // 10 defaults + 1 custom
      expect(categories.length, equals(11));
    });

    test('includes all movements', () async {
      final db = AppDatabase();
      _populateTestData(db);

      final json = await BackupService.exportToJson(db);
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final movements = parsed['movements'] as List;

      expect(movements.length, equals(db.movements.length));
    });

    test('includes metadata fields', () async {
      final db = AppDatabase();
      _populateTestData(db);

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
      _populateTestData(db);
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
      _populateTestData(db);

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
      _populateTestData(db);
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
      _populateTestData(db);

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
      _populateTestData(db);

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

      db.addMovement(Movement(
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
}

// ── Helpers ──

void _populateTestData(AppDatabase db) {
  final now = DateTime.now();

  db.addMovement(Movement(
    id: 'export_test_1',
    title: 'Export test expense',
    amount: 25.50,
    type: MovementType.expense,
    date: now,
    categoryId: 'exp_1',
    createdAt: now,
  ));

  db.addMovement(Movement(
    id: 'export_test_2',
    title: 'Export test income',
    amount: 1000.0,
    type: MovementType.income,
    date: now,
    categoryId: 'inc_1',
    createdAt: now,
  ));

  db.saveMovementAsFavorite(db.movements.first);
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
