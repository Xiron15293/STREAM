import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

/// Create V5 schema on an open database (all columns except date in movements).
Future<void> _createV5Schema(Database db) async {
  await db.execute('''
    CREATE TABLE movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      color INTEGER, icon_key TEXT NOT NULL DEFAULT 'tag',
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE quick_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE favorite_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE accounts (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      initial_balance REAL NOT NULL DEFAULT 0.0,
      icon_key TEXT NOT NULL DEFAULT 'wallet',
      color INTEGER NOT NULL DEFAULT ${StreamColorPalette.getDefault()},
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  // V5 DB would always have the default account (inserted by V1→V2 migration or V1 onCreate)
  final now = DateTime.now().toIso8601String();
  await db.insert('accounts', {
    'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
    'initial_balance': 0.0, 'archived': 0,
    'created_at': now, 'updated_at': now,
  });
}

/// Create V6 schema on an open database (date in movements, no destination_account_id).
Future<void> _createV6Schema(Database db) async {
  await db.execute('''
    CREATE TABLE movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      date TEXT NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      color INTEGER, icon_key TEXT NOT NULL DEFAULT 'tag',
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE quick_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE favorite_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE accounts (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      initial_balance REAL NOT NULL DEFAULT 0.0,
      icon_key TEXT NOT NULL DEFAULT 'wallet',
      color INTEGER NOT NULL DEFAULT ${StreamColorPalette.getDefault()},
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  final now = DateTime.now().toIso8601String();
  await db.insert('accounts', {
    'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
    'initial_balance': 0.0, 'archived': 0,
    'created_at': now, 'updated_at': now,
  });
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

/// Crea database V5 su file (pre-V6: senza colonna date in movements).
Future<String> _makeV5Db() async {
  final path = _tempDbPath('v5.db');
  var db = await openDatabase(path, version: 5, onCreate: (db, _) => _createV5Schema(db));
  await db.close();
  return path;
}

/// Crea database V6 su file (date presente, destination_account_id assente).
Future<String> _makeV6Db() async {
  final path = _tempDbPath('v6.db');
  var db = await openDatabase(path, version: 6, onCreate: (db, _) => _createV6Schema(db));
  await db.close();
  return path;
}

/// Create a schema with accounts but without initial_balance, used to validate V8 upgrade.
Future<void> _createV7NoInitialBalanceSchema(Database db) async {
  await db.execute('''
    CREATE TABLE movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      destination_account_id TEXT,
      date TEXT NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE categories (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      color INTEGER, icon_key TEXT NOT NULL DEFAULT 'tag',
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE quick_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE favorite_movements (
      id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
      type TEXT NOT NULL, category_id TEXT NOT NULL,
      account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
      note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE accounts (
      id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
      icon_key TEXT NOT NULL DEFAULT 'wallet',
      color INTEGER NOT NULL DEFAULT ${StreamColorPalette.getDefault()},
      archived INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL
    )
  ''');
  final now = DateTime.now().toIso8601String();
  await db.insert('accounts', {
    'id': defaultAccountId,
    'name': 'Principale',
    'type': 'bank',
    'archived': 0,
    'created_at': now,
    'updated_at': now,
  });
  await db.insert('accounts', {
    'id': 'acc_v7_seed',
    'name': 'Conto Legacy',
    'type': 'bank',
    'archived': 0,
    'created_at': now,
    'updated_at': now,
  });
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

  group('V5→V6 — migration date column robustezza', () {
    /// Verifica la colonna date via raw SQL dopo la migration.
    /// Non usa AppDatabase/loadMovements per evitare crash su created_at malformato.
    Future<String> verifyDateAfterMigration(String dbPath, String movementId) async {
      // Apri connessione raw per leggere, nessun upgrade callback
      final reader = await openDatabase(dbPath);
      final rows = await reader.rawQuery(
        'SELECT date FROM movements WHERE id = ?', [movementId],
      );
      await reader.close();
      expect(rows.length, 1);
      final date = rows.first['date'] as String?;
      expect(date, isNotNull);
      expect(date, isNotEmpty);
      return date!;
    }

    test('V5→V6: backfill da created_at ISO valido → date = substr(created_at, 1, 10)', () async {
      final path = await _makeV5Db();
      var db = await openDatabase(path, version: 5);
      const createdAt = '2026-06-15T10:30:00.000';
      await db.rawInsert('''
        INSERT INTO movements (id, title, amount, type, category_id, account_id, created_at, updated_at)
        VALUES ('m_v6_ok', 'Test V6', 50.0, 'expense', 'exp_1', '$defaultAccountId', '$createdAt', '$createdAt')
      ''');
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      await sqlite.close();

      final date = await verifyDateAfterMigration(path, 'm_v6_ok');
      expect(date, '2026-06-15');
    });

    test('V5→V6: created_at vuoto → fallback a oggi', () async {
      final path = await _makeV5Db();
      var db = await openDatabase(path, version: 5);
      const now = '2026-06-20T00:00:00.000';
      await db.rawInsert('''
        INSERT INTO movements (id, title, amount, type, category_id, account_id, created_at, updated_at)
        VALUES ('m_v6_empty', 'Empty CA', 10.0, 'expense', 'exp_1', '$defaultAccountId', '', '$now')
      ''');
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      await sqlite.close();

      final date = await verifyDateAfterMigration(path, 'm_v6_empty');
      // Fallback: today's date in yyyy-MM-dd format
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(date, today);
    });

    test('V5→V6: created_at malformato senza dash → backfill skip, fallback a oggi', () async {
      final path = await _makeV5Db();
      var db = await openDatabase(path, version: 5);
      const now = '2026-06-20T00:00:00.000';
      await db.rawInsert('''
        INSERT INTO movements (id, title, amount, type, category_id, account_id, created_at, updated_at)
        VALUES ('m_v6_bad', 'Bad CA', 5.0, 'expense', 'exp_1', '$defaultAccountId', 'not-a-date', '$now')
      ''');
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      await sqlite.close();

      final date = await verifyDateAfterMigration(path, 'm_v6_bad');
      // backfill: substr('not-a-date', 1, 10) = 'not-a-dat', substr(...,5,1)='a' != '-' → skip
      // fallback: date IS NULL → set to today
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(date, today);
    });

    test('V5→V6: created_at con solo dash pos errate → backfill skip, fallback a oggi', () async {
      final path = await _makeV5Db();
      var db = await openDatabase(path, version: 5);
      const now = '2026-06-20T00:00:00.000';
      // length >= 10, ma dash a posizione sbagliata
      await db.rawInsert('''
        INSERT INTO movements (id, title, amount, type, category_id, account_id, created_at, updated_at)
        VALUES ('m_v6_wdash', 'Wrong dash', 3.0, 'income', 'inc_1', '$defaultAccountId', '2026=06=15foo', '$now')
      ''');
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      await sqlite.close();

      final date = await verifyDateAfterMigration(path, 'm_v6_wdash');
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(date, today);
    });

    test('V5→V6: CREATE TABLE IF NOT EXISTS accounts non crasha', () async {
      // _makeV5Db crea V5 con tabella accounts già esistente
      final path = await _makeV5Db();
      var db = await openDatabase(path, version: 5);
      await db.close();

      // SQLiteService V2 blocca usa CREATE TABLE IF NOT EXISTS — non deve crashare
      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      await sqlite.close();

      // Verifica che accounts tabella esista ancora
      final reader = await openDatabase(path);
      final tables = await reader.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'",
      );
      await reader.close();
      expect(tables.length, 1);
    });

    test('V1→V6 upgrade completo: tutti i dati preservati, date non NULL', () async {
      final path = await _makeV1Db();
      var db = await openDatabase(path, version: 1);
      final now = DateTime(2026, 6, 1).toIso8601String();
      await db.insert('movements', {
        'id': 'v1_v6_1', 'title': 'Sopravvissuto', 'amount': 99.0,
        'type': 'expense', 'category_id': 'exp_1',
        'date': now, 'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'exp_1', 'name': 'Spesa', 'type': 'expense',
        'color': 0xFFEF5350, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.close();

      // Upgrade V1→V6
      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.movements.length, 1);
      expect(appDb.movements.first.title, 'Sopravvissuto');
      expect(appDb.accounts.length, greaterThanOrEqualTo(1));
      expect(appDb.accounts.any((a) => a.id == defaultAccountId), true);
      // date non deve essere NULL
      expect(appDb.movements.first.date, isNotNull);

      await sqlite.close();
    });
  });

  group('V6→V7 — destination account migration', () {
    test('V6 upgradea con destination_account_id senza perdere movimenti esistenti', () async {
      final path = await _makeV6Db();
      var db = await openDatabase(path, version: 6);
      final now = DateTime(2026, 6, 20).toIso8601String();
      await db.rawInsert('''
        INSERT INTO movements (id, title, amount, type, category_id, account_id, date, created_at, updated_at)
        VALUES ('v7_old_mov', 'Vecchio movimento', 42.0, 'expense', 'exp_1', '$defaultAccountId', '$now', '$now', '$now')
      ''');
      await db.rawInsert('''
        INSERT INTO categories (id, name, type, color, archived, created_at, updated_at)
        VALUES ('exp_1', 'Spesa', 'expense', 0xFFEF5350, 0, '$now', '$now')
      ''');
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.movements.length, 1);
      expect(appDb.movements.first.title, 'Vecchio movimento');
      expect(appDb.movements.first.destinationAccountId, isNull);

      await sqlite.close();
    });

    test('V6 upgradea e salva transfer con destination_account_id', () async {
      final path = await _makeV6Db();
      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      await appDb.addAccount(Account(
        id: 'acc_dest',
        name: 'Destinazione',
        type: AccountType.bank,
        createdAt: DateTime(2026, 6, 20),
      ));
      await appDb.addMovement(Movement(
        id: 'tr_v7',
        title: 'Trasferimento',
        amount: 30,
        type: MovementType.transfer,
        date: DateTime(2026, 6, 20),
        categoryId: '',
        accountId: defaultAccountId,
        destinationAccountId: 'acc_dest',
        createdAt: DateTime(2026, 6, 20),
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 1);
      expect(db2.movements.first.destinationAccountId, 'acc_dest');
      expect(db2.getAccountBalance(db2.getAccount(defaultAccountId)), -30.0);
      expect(db2.getAccountBalance(db2.getAccount('acc_dest')), 30.0);

      await sqlite.close();
    });

    test('V7 reopen idempotente non perde destination_account_id', () async {
      final path = await _makeV6Db();
      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      await appDb.addAccount(Account(
        id: 'acc_dest',
        name: 'Destinazione',
        type: AccountType.bank,
        createdAt: DateTime(2026, 6, 20),
      ));
      await appDb.addMovement(Movement(
        id: 'tr_v7_idem',
        title: 'Trasferimento',
        amount: 15,
        type: MovementType.transfer,
        date: DateTime(2026, 6, 20),
        categoryId: '',
        accountId: defaultAccountId,
        destinationAccountId: 'acc_dest',
        createdAt: DateTime(2026, 6, 20),
      ));

      final appDb2 = AppDatabase(sqlite: sqlite);
      await appDb2.initialize();
      expect(appDb2.movements.first.destinationAccountId, 'acc_dest');

      await sqlite.close();
    });
  });

  group('V7→V8 — initial_balance migration', () {
    test('Accounts senza initial_balance vengono letti con saldo iniziale a zero', () async {
      final path = _tempDbPath('v7_no_initial_balance.db');
      final db = await openDatabase(
        path,
        version: 7,
        onCreate: (db, _) => _createV7NoInitialBalanceSchema(db),
      );
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      final defaultAccount = appDb.accounts.firstWhere((a) => a.id == defaultAccountId);
      final legacyAccount = appDb.accounts.firstWhere((a) => a.id == 'acc_v7_seed');
      expect(defaultAccount.initialBalance, 0.0);
      expect(legacyAccount.initialBalance, 0.0);
      expect(appDb.getAccountBalance(legacyAccount), 0.0);

      await sqlite.close();
    });
  });

  group('C5 fix — date NULL/malformed non crasha loadMovements', () {
    test('V6 with NULL date after migration → loadMovements non crasha', () async {
      final path = _tempDbPath('c5_null_date.db');
      // Creiamo DB V6 simulando un backfill fallito
      var db = await openDatabase(path, version: 6, onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE movements (
            id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
            type TEXT NOT NULL, category_id TEXT NOT NULL,
            account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
            date TEXT, note TEXT,
            created_at TEXT NOT NULL, updated_at TEXT NOT NULL
          )
        ''');
        // Inserisci movimento con date NULL
        final now = DateTime.now().toIso8601String();
        await db.rawInsert('''
          INSERT INTO movements (id, title, amount, type, category_id, account_id, date, created_at, updated_at)
          VALUES ('c5_null', 'Null Date', 10.0, 'expense', 'exp_1', '$defaultAccountId', NULL, '$now', '$now')
        ''');
      });
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
          color INTEGER, icon_key TEXT NOT NULL DEFAULT 'tag',
          archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
          initial_balance REAL NOT NULL DEFAULT 0.0,
          icon_key TEXT NOT NULL DEFAULT 'wallet',
          color INTEGER NOT NULL DEFAULT ${StreamColorPalette.getDefault()},
          archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quick_movements (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
          type TEXT NOT NULL, category_id TEXT,
          account_id TEXT, note TEXT,
          created_at TEXT, updated_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_movements (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
          type TEXT NOT NULL, category_id TEXT,
          account_id TEXT, note TEXT,
          created_at TEXT, updated_at TEXT
        )
      ''');
      final now = DateTime.now().toIso8601String();
      await db.insert('accounts', {
        'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
        'initial_balance': 0.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'exp_1', 'name': 'Spesa', 'type': 'expense',
        'color': 0xFFEF5350, 'icon_key': 'shopping_cart',
        'archived': 0, 'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      // Non deve crashare
      expect(appDb.movements.length, 1);
      expect(appDb.movements.first.id, 'c5_null');
      // date deve essere fallback: created_at
      expect(appDb.movements.first.date, isNotNull);

      await sqlite.close();
    });

    test('V6 with NULL created_at → loadMovements non crasha (double fallback)', () async {
      final path = _tempDbPath('c5_null_ca.db');
      var db = await openDatabase(path, version: 6, onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE movements (
            id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
            type TEXT NOT NULL, category_id TEXT NOT NULL,
            account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
            date TEXT, note TEXT,
            created_at TEXT, updated_at TEXT
          )
        ''');
        // Inserisci movimento con date NULL e created_at NULL
        await db.rawInsert('''
          INSERT INTO movements (id, title, amount, type, category_id, account_id, date, created_at, updated_at)
          VALUES ('c5_null_ca', 'Null Both', 10.0, 'expense', 'exp_1', '$defaultAccountId', NULL, NULL, NULL)
        ''');
      });
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
          color INTEGER, icon_key TEXT NOT NULL DEFAULT 'tag',
          archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
          initial_balance REAL NOT NULL DEFAULT 0.0,
          icon_key TEXT NOT NULL DEFAULT 'wallet',
          color INTEGER NOT NULL DEFAULT ${StreamColorPalette.getDefault()},
          archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quick_movements (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
          type TEXT NOT NULL, category_id TEXT,
          account_id TEXT, note TEXT,
          created_at TEXT, updated_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_movements (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
          type TEXT NOT NULL, category_id TEXT,
          account_id TEXT, note TEXT,
          created_at TEXT, updated_at TEXT
        )
      ''');
      final now = DateTime.now().toIso8601String();
      await db.insert('accounts', {
        'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
        'initial_balance': 0.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'exp_1', 'name': 'Spesa', 'type': 'expense',
        'color': 0xFFEF5350, 'icon_key': 'shopping_cart',
        'archived': 0, 'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      // Non deve crashare anche con doppio NULL
      expect(appDb.movements.length, 1);
      // Fallback estremo: DateTime(2020, 1, 1)
      expect(appDb.movements.first.date, DateTime(2020, 1, 1));
      expect(appDb.movements.first.createdAt, DateTime(2020, 1, 1));

      await sqlite.close();
    });

    test('V6 with invalid date string → loadMovements non crasha', () async {
      final path = _tempDbPath('c5_bad_date.db');
      var db = await openDatabase(path, version: 6, onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE movements (
            id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
            type TEXT NOT NULL, category_id TEXT NOT NULL,
            account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
            date TEXT, note TEXT,
            created_at TEXT NOT NULL, updated_at TEXT NOT NULL
          )
        ''');
        final now = DateTime.now().toIso8601String();
        await db.rawInsert('''
          INSERT INTO movements (id, title, amount, type, category_id, account_id, date, created_at, updated_at)
          VALUES ('c5_bad', 'Bad Date', 10.0, 'expense', 'exp_1', '$defaultAccountId', 'not-a-date', '$now', '$now')
        ''');
      });
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
          color INTEGER, icon_key TEXT NOT NULL DEFAULT 'tag',
          archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id TEXT PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL,
          initial_balance REAL NOT NULL DEFAULT 0.0,
          icon_key TEXT NOT NULL DEFAULT 'wallet',
          color INTEGER NOT NULL DEFAULT ${StreamColorPalette.getDefault()},
          archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quick_movements (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
          type TEXT NOT NULL, category_id TEXT,
          account_id TEXT, note TEXT,
          created_at TEXT, updated_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_movements (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, amount REAL NOT NULL,
          type TEXT NOT NULL, category_id TEXT,
          account_id TEXT, note TEXT,
          created_at TEXT, updated_at TEXT
        )
      ''');
      final now = DateTime.now().toIso8601String();
      await db.insert('accounts', {
        'id': defaultAccountId, 'name': 'Principale', 'type': 'bank',
        'initial_balance': 0.0, 'archived': 0,
        'created_at': now, 'updated_at': now,
      });
      await db.insert('categories', {
        'id': 'exp_1', 'name': 'Spesa', 'type': 'expense',
        'color': 0xFFEF5350, 'icon_key': 'shopping_cart',
        'archived': 0, 'created_at': now, 'updated_at': now,
      });
      await db.close();

      final sqlite = SQLiteService();
      await sqlite.open(path: path);
      final appDb = AppDatabase(sqlite: sqlite);
      await appDb.initialize();

      expect(appDb.movements.length, 1);
      expect(appDb.movements.first.date, isNotNull);

      await sqlite.close();
    });
  });
}
