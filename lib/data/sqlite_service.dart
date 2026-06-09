import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'categories_data.dart';
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/quick_movement.dart';
import '../models/favorite_movement.dart';

class SQLiteService {
  Database? _db;

  Future<void> open({String? path}) async {
    _db = await openDatabase(
      path ?? join(await getDatabasesPath(), 'stream.db'),
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return _database.transaction(action);
  }

  Database get _database {
    if (_db == null) throw StateError('Database not opened');
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE movements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
        destination_account_id TEXT,
        date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color INTEGER,
        icon_key TEXT NOT NULL DEFAULT '${StreamIconLibrary.defaultCategoryIcon}',
        archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quick_movements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorite_movements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL DEFAULT '$defaultAccountId',
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0.0,
        icon_key TEXT NOT NULL DEFAULT '${StreamIconLibrary.defaultAccountIcon}',
        color INTEGER NOT NULL DEFAULT ${StreamColorPalette.getDefault()},
        archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await _insertDefaultAccount(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          initial_balance REAL NOT NULL DEFAULT 0.0,
          archived INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await _insertDefaultAccount(db);
      try {
        await db.execute(
            "ALTER TABLE movements ADD COLUMN account_id TEXT NOT NULL DEFAULT '$defaultAccountId'");
      } catch (e) {
        debugPrint('Migration V2 add account_id to movements error: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
            "ALTER TABLE quick_movements ADD COLUMN account_id TEXT NOT NULL DEFAULT '$defaultAccountId'");
      } catch (e) {
        debugPrint('Migration V3 add account_id to quick_movements error: $e');
      }
      try {
        await db.execute(
            "ALTER TABLE favorite_movements ADD COLUMN account_id TEXT NOT NULL DEFAULT '$defaultAccountId'");
      } catch (e) {
        debugPrint('Migration V3 add account_id to favorite_movements error: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
            "ALTER TABLE categories ADD COLUMN icon_key TEXT NOT NULL DEFAULT '${StreamIconLibrary.defaultCategoryIcon}'");
      } catch (e) {
        debugPrint('Migration V4 add icon_key to categories error: $e');
      }
      try {
        await db.execute(
            "ALTER TABLE accounts ADD COLUMN icon_key TEXT NOT NULL DEFAULT '${StreamIconLibrary.defaultAccountIcon}'");
      } catch (e) {
        debugPrint('Migration V4 add icon_key to accounts error: $e');
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
            "ALTER TABLE accounts ADD COLUMN color INTEGER");
        await db.update('accounts', {'color': StreamColorPalette.getDefault()}, where: 'color IS NULL');
      } catch (e) {
        debugPrint('Migration V5 add color to accounts error: $e');
      }
    }
    if (oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        table: 'movements',
        column: 'date',
        definition: 'TEXT',
        migrationLabel: 'Migration V6 add date to movements',
      );
      try {
        await db.rawUpdate('''
          UPDATE movements SET date = substr(created_at, 1, 10)
          WHERE date IS NULL
            AND created_at IS NOT NULL
            AND length(created_at) >= 10
            AND substr(created_at, 5, 1) = '-'
            AND substr(created_at, 8, 1) = '-'
        ''');
      } catch (e) {
        debugPrint('Migration V6 backfill from created_at error: $e');
      }
      try {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await db.rawUpdate(
          "UPDATE movements SET date = ? WHERE date IS NULL OR date = ''",
          [today],
        );
      } catch (e) {
        debugPrint('Migration V6 fallback date error: $e');
      }
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(
        db,
        table: 'movements',
        column: 'destination_account_id',
        definition: 'TEXT',
        migrationLabel: 'Migration V7 add destination_account_id to movements',
      );
    }
    if (oldVersion < 8) {
      await _addColumnIfMissing(
        db,
        table: 'accounts',
        column: 'initial_balance',
        definition: 'REAL NOT NULL DEFAULT 0.0',
        migrationLabel: 'Migration V8 add initial_balance to accounts',
      );
      try {
        await db.rawUpdate(
          'UPDATE accounts SET initial_balance = 0.0 WHERE initial_balance IS NULL',
        );
      } catch (e) {
        debugPrint('Migration V8 backfill initial_balance error: $e');
      }
    }
  }

  Future<void> _insertDefaultAccount(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('accounts', {
      'id': defaultAccountId,
      'name': 'Principale',
      'type': 'bank',
      'initial_balance': 0.0,
      'archived': 0,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  List<QuickMovement> _defaultQuickMovements() => [
        const QuickMovement(
          id: 'qm_1',
          title: 'Caffè',
          amount: 1.50,
          type: MovementType.expense,
          categoryId: 'exp_4',
          accountId: defaultAccountId,
        ),
        const QuickMovement(
          id: 'qm_2',
          title: 'Benzina',
          amount: 50.0,
          type: MovementType.expense,
          categoryId: 'exp_3',
          accountId: defaultAccountId,
        ),
        const QuickMovement(
          id: 'qm_3',
          title: 'Spesa',
          amount: 80.0,
          type: MovementType.expense,
          categoryId: 'exp_1',
          accountId: defaultAccountId,
        ),
        const QuickMovement(
          id: 'qm_4',
          title: 'Stipendio',
          amount: 2500.0,
          type: MovementType.income,
          categoryId: 'inc_1',
          accountId: defaultAccountId,
        ),
      ];

  Future<void> resetAllData() async {
    final db = _database;
    await db.transaction((txn) async {
      await txn.delete('movements');
      await txn.delete('categories');
      await txn.delete('quick_movements');
      await txn.delete('favorite_movements');
      await txn.delete('accounts');

      await _insertDefaultAccount(txn);

      for (final category in DefaultCategories.all) {
        await txn.insert(
          'categories',
          _categoryToMap(category),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final quickMovement in _defaultQuickMovements()) {
        await txn.insert(
          'quick_movements',
          _quickMovementToMap(quickMovement),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ── Movements ──

  Future<List<Map<String, dynamic>>> _getMovementsRows() async {
    final db = _database;
    return db.query('movements');
  }

  Future<List<Movement>> loadMovements() async {
    final rows = await _getMovementsRows();
    return rows.map(_movementFromMap).toList();
  }

  Future<void> insertMovement(Movement m) async {
    final db = _database;
    await db.insert('movements', _movementToMap(m),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMovement(String id) async {
    final db = _database;
    await db.delete('movements', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateMovement(Movement m) async {
    final db = _database;
    await db.update('movements', _movementToMap(m),
        where: 'id = ?', whereArgs: [m.id]);
  }

  String _toDateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _movementToMap(Movement m) => {
        'id': m.id,
        'title': m.title,
        'amount': m.amount,
        'type': m.type.name,
        'category_id': m.categoryId,
        'account_id': m.accountId,
        'destination_account_id': m.destinationAccountId,
        'date': _toDateOnly(m.date),
        'note': m.note,
        'created_at': m.createdAt.toIso8601String(),
        'updated_at': m.updatedAt.toIso8601String(),
      };

  static DateTime _parseDateSafe(dynamic value, {required DateTime fallback}) {
    if (value is! String || value.isEmpty) return fallback;
    final parsed = DateTime.tryParse(value);
    if (parsed != null && parsed.isAfter(DateTime(2000))) return parsed;
    return fallback;
  }

  Movement _movementFromMap(Map<String, dynamic> map) => Movement(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: MovementType.values.byName(map['type'] as String),
        categoryId: map['category_id'] as String,
        accountId: map['account_id'] as String? ?? defaultAccountId,
        destinationAccountId: map['destination_account_id'] as String?,
        date: _parseDateSafe(map['date'], fallback: _parseDateSafe(map['created_at'], fallback: DateTime(2020, 1, 1))),
        note: map['note'] as String?,
        createdAt: _parseDateSafe(map['created_at'], fallback: DateTime(2020, 1, 1)),
        updatedAt: _parseDateSafe(map['updated_at'], fallback: DateTime(2020, 1, 1)),
      );

  // ── Categories ──

  Future<int> getCategoriesCount() async {
    final db = _database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM categories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getMovementCountByCategory(String categoryId) async {
    final db = _database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM movements WHERE category_id = ?',
        [categoryId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Category>> loadCategories() async {
    final db = _database;
    final rows = await db.query('categories');
    return rows.map(_categoryFromMap).toList();
  }

  Future<void> insertCategory(Category c) async {
    final db = _database;
    await db.insert('categories', _categoryToMap(c),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(Category c) async {
    final db = _database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'categories',
      {
        'name': c.name,
        'type': c.type.name,
        'color': c.color,
        'icon_key': c.iconKey,
        'archived': c.archived ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = _database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _categoryToMap(Category c) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': c.id,
      'name': c.name,
      'type': c.type.name,
      'color': c.color,
      'icon_key': c.iconKey,
      'archived': c.archived ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
  }

  Category _categoryFromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        type: MovementType.values.byName(map['type'] as String),
        color: map['color'] as int,
        iconKey: map['icon_key'] as String? ?? StreamIconLibrary.defaultCategoryIcon,
        archived: (map['archived'] as int) == 1,
      );

  // ── Quick Movements ──

  Future<List<QuickMovement>> loadQuickMovements() async {
    final db = _database;
    final rows = await db.query('quick_movements');
    return rows.map(_quickMovementFromMap).toList();
  }

  Future<void> insertQuickMovement(QuickMovement qm) async {
    final db = _database;
    await db.insert('quick_movements', _quickMovementToMap(qm),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateQuickMovement(String id, QuickMovement qm) async {
    final db = _database;
    await db.update('quick_movements', _quickMovementToMap(qm),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteQuickMovement(String id) async {
    final db = _database;
    await db.delete('quick_movements', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _quickMovementToMap(QuickMovement qm) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': qm.id,
      'title': qm.title,
      'amount': qm.amount,
      'type': qm.type.name,
      'category_id': qm.categoryId,
      'account_id': qm.accountId,
      'note': qm.note,
      'created_at': now,
      'updated_at': now,
    };
  }

  QuickMovement _quickMovementFromMap(Map<String, dynamic> map) =>
      QuickMovement(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: MovementType.values.byName(map['type'] as String),
        categoryId: map['category_id'] as String,
        accountId: map['account_id'] as String? ?? defaultAccountId,
        note: map['note'] as String?,
      );

  // ── Favorite Movements ──

  Future<List<FavoriteMovement>> loadFavoriteMovements() async {
    final db = _database;
    final rows = await db.query('favorite_movements');
    return rows.map(_favoriteMovementFromMap).toList();
  }

  Future<void> insertFavoriteMovement(FavoriteMovement fm) async {
    final db = _database;
    await db.insert('favorite_movements', _favoriteMovementToMap(fm),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFavoriteMovement(String id) async {
    final db = _database;
    await db.delete('favorite_movements', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _favoriteMovementToMap(FavoriteMovement fm) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': fm.id,
      'title': fm.title,
      'amount': fm.amount,
      'type': fm.type.name,
      'category_id': fm.categoryId,
      'account_id': fm.accountId,
      'note': fm.note,
      'created_at': now,
      'updated_at': now,
    };
  }

  FavoriteMovement _favoriteMovementFromMap(Map<String, dynamic> map) =>
      FavoriteMovement(
        id: map['id'] as String,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        type: MovementType.values.byName(map['type'] as String),
        categoryId: map['category_id'] as String,
        accountId: map['account_id'] as String? ?? defaultAccountId,
        note: map['note'] as String?,
      );

  // ── Accounts ──

  Future<int> getAccountsCount() async {
    final db = _database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM accounts');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Account>> loadAccounts() async {
    final db = _database;
    final rows = await db.query('accounts');
    return rows.map(_accountFromMap).toList();
  }

  Future<void> insertAccount(Account a) async {
    final db = _database;
    await db.insert('accounts', _accountToMap(a),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAccount(String id, Account a) async {
    final db = _database;
    await db.update('accounts', _accountToMap(a),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archiveAccount(String id) async {
    final db = _database;
    final now = DateTime.now().toIso8601String();
    await db.update('accounts',
        {'archived': 1, 'updated_at': now},
        where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _accountToMap(Account a) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': a.id,
      'name': a.name,
      'type': a.type.name,
      'initial_balance': a.initialBalance,
      'icon_key': a.iconKey,
      'color': a.color,
      'archived': a.archived ? 1 : 0,
      'created_at': a.createdAt.toIso8601String(),
      'updated_at': now,
    };
  }

  Account _accountFromMap(Map<String, dynamic> map) => Account(
        id: map['id'] as String,
        name: map['name'] as String,
        type: AccountType.values.byName(map['type'] as String),
        initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
        iconKey: map['icon_key'] as String? ?? StreamIconLibrary.defaultAccountIcon,
        color: map['color'] as int? ?? StreamColorPalette.getDefault(),
        archived: (map['archived'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  // ── Delete all (for reset/test) ──

  Future<void> deleteAll() async {
    final db = _database;
    await db.delete('movements');
    await db.delete('categories');
    await db.delete('quick_movements');
    await db.delete('favorite_movements');
    await db.delete('accounts');
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
    required String migrationLabel,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (exists) return;
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    } catch (e) {
      debugPrint('$migrationLabel error: $e');
    }
  }
}
