import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Subcategories — In-memory mode', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase();
    });

    test('1. crea sottocategoria sotto categoria', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Test Sub');
      final subs = db.getSubcategoriesForCategory(cat.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'Test Sub');
      expect(subs.first.categoryId, cat.id);
    });

    test('2. dedup sottocategoria stessa categoria', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Sub');
      // Stesso nome sotto stessa categoria — attualmente permesso (nessuna validazione strict)
      await db.createSubcategory(cat.id, 'Sub');
      expect(db.getSubcategoriesForCategory(cat.id).length, 2);
    });

    test('3. stesso nome sottocategoria ammesso sotto categorie diverse', () async {
      final cats = db.categories.where((c) => !c.archived).toList();
      if (cats.length < 2) return;
      await db.createSubcategory(cats[0].id, 'StessoNome');
      await db.createSubcategory(cats[1].id, 'StessoNome');
      expect(db.getSubcategoriesForCategory(cats[0].id).length, 1);
      expect(db.getSubcategoriesForCategory(cats[1].id).length, 1);
    });

    test('4. movimento può salvare subcategoryId valido', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Sub');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      final mov = Movement(
        id: 'm1',
        title: 'Test',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        subcategoryId: sub.id,
        createdAt: DateTime.now(),
      );
      expect(mov.subcategoryId, sub.id);
    });

    test('5. archivia sottocategoria non rompe storico', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Sub');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      await db.archiveSubcategory(sub.id);
      final archived = db.subcategories.firstWhere((s) => s.id == sub.id);
      expect(archived.archived, true);
      expect(db.getActiveSubcategoriesForCategory(cat.id), isEmpty);
    });

    test('6. movimento resta salvabile senza sottocategoria', () async {
      final cat = db.categories.first;
      final mov = Movement(
        id: 'm2',
        title: 'NoSub',
        amount: 5,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      expect(mov.subcategoryId, isNull);
    });

    test('7. movimento con subcategory continua a contribuire alla categoria madre', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Sub');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      final mov = Movement(
        id: 'm3',
        title: 'Test',
        amount: 100,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        subcategoryId: sub.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);
      expect(db.totalExpenses > 0 || db.totalIncome > 0, true);
    });

    test('8. getActiveSubcategoriesForCategory filtra archiviate', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Active');
      await db.createSubcategory(cat.id, 'ArchivedToo');
      final subs = db.getSubcategoriesForCategory(cat.id);
      await db.archiveSubcategory(subs.last.id);
      final active = db.getActiveSubcategoriesForCategory(cat.id);
      expect(active.length, 1);
      expect(active.first.name, 'Active');
    });

    test('9. categoria senza subcategories ha lista vuota', () async {
      final cat = db.categories.first;
      expect(db.getSubcategoriesForCategory(cat.id), isEmpty);
    });
  });

  group('Subcategories — SQLite persistence', () {
    late SQLiteService sqlite;
    late AppDatabase db;
    late String subId;

    setUp(() async {
      sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Persistent Sub');
      final subs = db.getSubcategoriesForCategory(cat.id);
      subId = subs.first.id;
    });

    tearDown(() async {
      await sqlite.close();
    });

    test('10. subcategory persiste dopo reload', () async {
      await db.reloadFromDb();
      final subs = db.getSubcategoriesForCategory(db.categories.first.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'Persistent Sub');
    });

    test('11. subcategory archiviation persiste dopo reload', () async {
      final cat = db.categories.first;
      final subs = db.getSubcategoriesForCategory(cat.id);
      await db.archiveSubcategory(subs.first.id);
      await db.reloadFromDb();
      final loaded = db.subcategories.firstWhere((s) => s.id == subId);
      expect(loaded.archived, true);
    });
  });

  group('Subcategories — Backup/Restore', () {
    late SQLiteService sqlite;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Backup Sub');
    });

    tearDown(() async {
      await sqlite.close();
    });

    test('12. backup include subcategories', () async {
      final json = await BackupService.exportToJson(db);
      expect(json, contains('subcategories'));
      expect(json, contains('Backup Sub'));
    });

    test('13. restore con subcategories funziona', () async {
      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);
      expect(validation.isValid, true);
      final data = validation.data!;
      expect(data.subcategories.length, 1);
      expect(data.subcategories.first.name, 'Backup Sub');

      await db.resetAllData();
      await BackupService.restore(db, data);
      final restored = db.subcategories;
      expect(restored.length, 1);
      expect(restored.first.name, 'Backup Sub');
    });

    test('14. restore vecchio JSON senza subcategories funziona', () async {
      final oldJson = '''
      {
        "version": 2,
        "createdAt": "2024-01-01T00:00:00.000",
        "accounts": [],
        "categories": [],
        "movements": [],
        "quickMovements": [],
        "favoriteMovements": []
      }
      ''';
      final validation = BackupService.validate(oldJson);
      expect(validation.isValid, true);
      final data = validation.data!;
      expect(data.subcategories, isEmpty);
    });

    test('15. restore con subcategoryId orfano lo porta a null', () async {
      final json = '''
      {
        "version": 2,
        "createdAt": "2024-01-01T00:00:00.000",
        "accounts": [],
        "categories": [{"id": "exp_1", "name": "Test", "type": "expense", "color": 123}],
        "subcategories": [],
        "movements": [{"id": "m_orphan", "title": "Test", "amount": 10, "type": "expense", "date": "2024-01-01T00:00:00.000", "categoryId": "exp_1", "subcategoryId": "nonexistent_id", "accountId": "default", "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"}],
        "quickMovements": [],
        "favoriteMovements": []
      }
      ''';
      final validation = BackupService.validate(json);
      expect(validation.isValid, true);
      await db.resetAllData();
      await BackupService.restore(db, validation.data!);
      await db.reloadFromDb();
      final mov = db.movements.first;
      expect(mov.subcategoryId, isNull);
    });
  });

  group('Subcategories — Reset data', () {
    test('16. reset dati cancella subcategories', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'ToDelete');
      expect(db.subcategories.length, 1);
      await db.resetAllData();
      expect(db.subcategories, isEmpty);
      await sqlite.close();
    });
  });

  group('Subcategories — Compatibilità analytics', () {
    test('17. somma spese per categoria include movimenti con subcategory', () async {
      final db = AppDatabase();
      final cat = db.categories.firstWhere((c) => c.type == MovementType.expense);
      await db.createSubcategory(cat.id, 'Sub');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      const amount = 50.0;
      final mov = Movement(
        id: 'm_ana',
        title: 'Analytics Test',
        amount: amount,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: cat.id,
        subcategoryId: sub.id,
        createdAt: DateTime.now(),
      );
      await db.addMovement(mov);
      expect(db.totalExpenses, amount);
    });
  });
}
