import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' show openDatabase;
import 'package:path/path.dart' show join;
import 'dart:io';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/design/stream_icon_library.dart';

/// Create a temporary file path for a database.
String _tempDbPath(String name) {
  final dir = Directory.systemTemp.createTempSync('stream_test_');
  return join(dir.path, name);
}

/// Create V1 schema on an open database (initial Hermes: no accounts, no account_id).
Future<void> _createV1Schema(Database db) async {
  await db.execute('''
    CREATE TABLE movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      date TEXT NOT NULL, note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      color INTEGER, archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE quick_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL, note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE favorite_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL, note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
}

/// Create V2 schema on an open database (V1 + accounts + account_id in movements).
Future<void> _createV2Schema(Database db) async {
  await _createV1Schema(db);
  await db.execute('''
    CREATE TABLE accounts (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      initial_balance REAL NOT NULL DEFAULT 0.0, archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute(
    "ALTER TABLE movements ADD COLUMN account_id TEXT NOT NULL DEFAULT '$defaultAccountId'");
}

/// Create V3 schema on an open database (V2 + account_id in quick/favorite).
Future<void> _createV3Schema(Database db) async {
  await _createV2Schema(db);
  await db.execute(
    "ALTER TABLE quick_movements ADD COLUMN account_id TEXT NOT NULL DEFAULT '$defaultAccountId'");
  await db.execute(
    "ALTER TABLE favorite_movements ADD COLUMN account_id TEXT NOT NULL DEFAULT '$defaultAccountId'");
}

/// Crea database V1 su file, popola, chiude, restituisce il path.
Future<String> _makeV1Db() async {
  final path = _tempDbPath('v1.db');
  var db = await openDatabase(path, version: 1, onCreate: (db, _) => _createV1Schema(db));
  await db.close();
  return path;
}

/// Crea database V2 su file.
Future<String> _makeV2Db() async {
  final path = _tempDbPath('v2.db');
  var db = await openDatabase(path, version: 2, onCreate: (db, _) => _createV2Schema(db));
  await db.close();
  return path;
}

/// Crea database V3 su file.
Future<String> _makeV3Db() async {
  final path = _tempDbPath('v3.db');
  var db = await openDatabase(path, version: 3, onCreate: (db, _) => _createV3Schema(db));
  await db.close();
  return path;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('V1→V4 — movimenti e categorie preservati', () {
    test('V1 movimento sopravvive con accountId default', () async {
      final path = await _makeV1Db();
      var db = await openDatabase(path, version: 1);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('movements', {
        'id': 'mig_v1_1', 'title': 'Movimento V1', 'amount': 100.0,
        'type': 'income', 'category_id': 'inc_1',
        'date': now, 'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'inc_1', 'name': 'Stipendio', 'type': 'income',
        'color': 0xFF4CAF50, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.movements.length, 1);
      expect(appDb.movements.first.title, 'Movimento V1');
      expect(appDb.movements.first.amount, 100.0);
      expect(appDb.movements.first.accountId, defaultAccountId);

      await sqlite.close();
    });

    test('V1 categoria sopravvive con iconKey default', () async {
      final path = await _makeV1Db();
      var db = await openDatabase(path, version: 1);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('categories', {
        'id': 'cat_mig', 'name': 'Categoria V1', 'type': 'expense',
        'color': 0xFFEF5350, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      final cat = appDb.categories.firstWhere((c) => c.id == 'cat_mig');
      expect(cat.name, 'Categoria V1');
      expect(cat.iconKey, StreamIconLibrary.defaultCategoryIcon);
      expect(cat.color, 0xFFEF5350);

      await sqlite.close();
    });
  });

  group('V2→V4 — account_id preservato', () {
    test('V2 movimento con account_id personalizzato sopravvive', () async {
      final path = await _makeV2Db();
      var db = await openDatabase(path, version: 2);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('accounts', {
        'id': 'acc_test', 'name': 'Conto Test', 'type': 'bank',
        'initial_balance': 500.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('movements', {
        'id': 'mig_v2_1', 'title': 'Movimento V2', 'amount': 50.0,
        'type': 'expense', 'category_id': 'exp_1',
        'account_id': 'acc_test', 'date': now,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'exp_1', 'name': 'Spesa', 'type': 'expense',
        'color': 0xFFEF5350, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.movements.length, 1);
      expect(appDb.movements.first.accountId, 'acc_test');
      expect(appDb.accounts.any((a) => a.id == 'acc_test'), true);

      await sqlite.close();
    });
  });

  group('V3→V4 — quick/favorite accountId', () {
    test('V3 quick_movement mantiene accountId dopo upgrade V4', () async {
      final path = await _makeV3Db();
      var db = await openDatabase(path, version: 3);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('accounts', {
        'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
        'initial_balance': 0.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('quick_movements', {
        'id': 'qm_mig', 'title': 'Caffè V3', 'amount': 1.5,
        'type': 'expense', 'category_id': 'exp_4',
        'account_id': defaultAccountId,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'exp_4', 'name': 'Svago', 'type': 'expense',
        'color': 0xFFFF7043, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.quickMovements.any((q) => q.id == 'qm_mig'), true);
      expect(appDb.quickMovements.firstWhere((q) => q.id == 'qm_mig').accountId, defaultAccountId);

      await sqlite.close();
    });

    test('V3 favorite_movement mantiene accountId dopo upgrade V4', () async {
      final path = await _makeV3Db();
      var db = await openDatabase(path, version: 3);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('accounts', {
        'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
        'initial_balance': 0.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('favorite_movements', {
        'id': 'fv_mig', 'title': 'Preferito V3', 'amount': 200.0,
        'type': 'income', 'category_id': 'inc_1',
        'account_id': defaultAccountId,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'inc_1', 'name': 'Stipendio', 'type': 'income',
        'color': 0xFF4CAF50, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.favoriteMovements.any((f) => f.id == 'fv_mig'), true);
      expect(appDb.favoriteMovements.firstWhere((f) => f.id == 'fv_mig').accountId, defaultAccountId);

      await sqlite.close();
    });
  });

  group('V3→V4 — iconKey/color preservati', () {
    test('Categoria rinominata mantiene iconKey e color', () async {
      final path = await _makeV3Db();
      var db = await openDatabase(path, version: 3);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('categories', {
        'id': 'cat_renamed', 'name': 'Categoria Rinominata', 'type': 'expense',
        'color': 0xFFAB47BC, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      final cat = appDb.categories.firstWhere((c) => c.id == 'cat_renamed');
      expect(cat.name, 'Categoria Rinominata');
      expect(cat.color, 0xFFAB47BC);
      expect(cat.iconKey, StreamIconLibrary.defaultCategoryIcon);

      await sqlite.close();
    });

    test('Conto V3 mantiene saldo e tipo dopo upgrade V4', () async {
      final path = await _makeV3Db();
      var db = await openDatabase(path, version: 3);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('accounts', {
        'id': 'acc_v3_test', 'name': 'Conto V3', 'type': 'card',
        'initial_balance': 1000.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      final acc = appDb.accounts.firstWhere((a) => a.id == 'acc_v3_test');
      expect(acc.name, 'Conto V3');
      expect(acc.type, AccountType.card);
      expect(acc.initialBalance, 1000.0);
      expect(acc.iconKey, StreamIconLibrary.defaultAccountIcon);

      await sqlite.close();
    });
  });

  group('Update app simulato — dati tutti preservati', () {
    test('Movimenti, categorie, conti, rapidi, preferiti tutti ok dopo reopen', () async {
      final path = _tempDbPath('full_v4.db');
      var sqlite = SQLiteService();
      await sqlite.open(path: path);
      var appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      // Usa SQLiteService direttamente (awaitable) invece di AppDatabase (unawaited)
      await sqlite.insertMovement(Movement(
        id: 'full_test_1', title: 'Test Completo', amount: 75.0,
        type: MovementType.expense, date: DateTime(2026, 6, 5),
        categoryId: 'exp_1', accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 5),
      ));

      await sqlite.insertCategory(Category(
        id: 'cat_custom', name: 'Custom', type: MovementType.expense,
        color: 0xFF42A5F5, iconKey: 'star',
      ));

      await sqlite.insertQuickMovement(QuickMovement(
        id: 'qm_full', title: 'Quick Custom', amount: 10.0,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: defaultAccountId,
      ));

      final now = DateTime.now();
      await sqlite.insertFavoriteMovement(FavoriteMovement(
        id: 'fv_full', title: 'Fav Custom', amount: 500.0,
        type: MovementType.income, categoryId: 'inc_1',
        accountId: defaultAccountId,
      ));

      await sqlite.close();

      // Riapri — simula update app
      var sqlite2 = SQLiteService();
      await sqlite2.open(path: path);
      var appDb2 = AppDatabase(sqlite: sqlite2);
      await appDb2.initialize();

      expect(appDb2.movements.length, 1);
      expect(appDb2.movements.first.title, 'Test Completo');
      expect(appDb2.categories.any((c) => c.id == 'cat_custom'), true);
      expect(appDb2.categories.firstWhere((c) => c.id == 'cat_custom').iconKey, 'star');
      expect(appDb2.quickMovements.any((q) => q.id == 'qm_full'), true);
      expect(appDb2.favoriteMovements.any((f) => f.id == 'fv_full'), true);

      await sqlite2.close();
    });
  });

  group('V3→V4 — nessun DROP TABLE', () {
    test('Tutte le tabelle V3 con tutti i dati dopo upgrade V4', () async {
      final path = await _makeV3Db();
      var db = await openDatabase(path, version: 3);
      final now = DateTime(2026, 6, 1).toIso8601String();

      await db.insert('accounts', {
        'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
        'initial_balance': 0.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('movements', {
        'id': 'm1', 'title': 'M1', 'amount': 10.0, 'type': 'expense',
        'category_id': 'exp_1', 'account_id': defaultAccountId,
        'date': now, 'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'exp_1', 'name': 'Spesa', 'type': 'expense',
        'color': 0xFFEF5350, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('quick_movements', {
        'id': 'qm1', 'title': 'QM1', 'amount': 5.0, 'type': 'expense',
        'category_id': 'exp_1', 'account_id': defaultAccountId,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('favorite_movements', {
        'id': 'fm1', 'title': 'FM1', 'amount': 100.0, 'type': 'income',
        'category_id': 'inc_1', 'account_id': defaultAccountId,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.movements.length, 1);
      expect(appDb.categories.length, 1);
      expect(appDb.quickMovements.length, 1);
      expect(appDb.favoriteMovements.length, 1);
      expect(appDb.accounts.length, 1);

      await sqlite.close();
    });
  });
}
