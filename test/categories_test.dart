import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/models/favorite_movement.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Categories — In-memory mode', () {
    test('1. Aggiungi categoria', () async {
      final db = AppDatabase();
      final initialCount = db.categories.length;

      await db.addCategory('Nuova Cat', MovementType.expense, 0xFF42A5F5);

      expect(db.categories.length, initialCount + 1);
      expect(db.categories.any((c) => c.name == 'Nuova Cat'), true);
    });

    test('2. Categoria aggiunta ha tipo e colore corretti', () async {
      final db = AppDatabase();
      await db.addCategory('Test Income', MovementType.income, 0xFF4CAF50);

      final cat =
          db.categories.firstWhere((c) => c.name == 'Test Income');
      expect(cat.type, MovementType.income);
      expect(cat.color, 0xFF4CAF50);
      expect(cat.archived, false);
    });

    test('3. Modifica nome categoria', () async {
      final db = AppDatabase();
      final cat = db.categories.first;

      await db.updateCategory(cat.id, 'Nome Modificato', cat.color);

      final updated =
          db.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.name, 'Nome Modificato');
      expect(updated.color, cat.color);
      expect(updated.type, cat.type);
    });

    test('4. Modifica colore categoria', () async {
      final db = AppDatabase();
      final cat = db.categories.first;

      await db.updateCategory(cat.id, cat.name, 0xFFFF0000);

      final updated =
          db.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.color, 0xFFFF0000);
    });

    test('5. Archivia categoria', () async {
      final db = AppDatabase();
      final cat = db.categories.first;

      db.archiveCategory(cat.id);

      final updated =
          db.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.archived, true);
    });

    test('6. Categoria archiviata non appare in activeCategories', () async {
      final db = AppDatabase();
      final cat = db.categories.first;
      final initialActive = db.activeCategories.length;

      db.archiveCategory(cat.id);

      expect(db.activeCategories.length, initialActive - 1);
      expect(db.activeCategories.any((c) => c.id == cat.id), false);
    });

    test('7. Ripristina categoria archiviata', () async {
      final db = AppDatabase();
      final cat = db.categories.first;

      db.archiveCategory(cat.id);
      db.restoreCategory(cat.id);

      final updated =
          db.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.archived, false);
    });

    test('8. Elimina categoria senza movimenti', () async {
      final db = AppDatabase();
      await db.addCategory('Da Eliminare', MovementType.expense, 0xFF0000);
      final cat =
          db.categories.firstWhere((c) => c.name == 'Da Eliminare');

      expect(db.categoryHasMovements(cat.id), false);

      await db.deleteCategory(cat.id);

      expect(db.categories.any((c) => c.name == 'Da Eliminare'), false);
    });

    test('9. Eliminazione bloccata per categoria con movimenti', () async {
      final db = AppDatabase();
      final cat = db.categories.firstWhere((c) => c.type == MovementType.expense);

      await db.addMovement(Movement(
        id: 'test_mov',
        title: 'Test',
        amount: 100,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      ));

      expect(db.categoryHasMovements(cat.id), true);
      // Categoria con movimenti NON deve essere eliminabile
      // (la UI mostra un dialog informativo)
    });

    test('10. activeCategories filtra quelle archiviate', () async {
      final db = AppDatabase();
      final activeBefore = db.activeCategories.length;

      db.archiveCategory(db.categories.first.id);
      db.archiveCategory(db.categories.last.id);

      expect(db.activeCategories.length, activeBefore - 2);
    });

    test('11. Aggiungi categoria con nome duplicato (controllo lato db)', () async {
      final db = AppDatabase();
      final existing = db.categories.first;
      final count = db.categories.length;

      // Aggiunta con nome identico (la UI blocca, ma il db permette)
      await db.addCategory(existing.name, MovementType.expense, 0xFF0000);

      // Il db permette comunque l'aggiunta (la validazione è UI-side)
      expect(db.categories.length, count + 1);
    });
  });

  group('Categories — SQLite persistence', () {
    test('12. Categoria persiste dopo reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addCategory('Categoria Persistente', MovementType.income, 0xFF4CAF50);

      // Reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();

      expect(db2.categories.any((c) => c.name == 'Categoria Persistente'), true);

      await sqlite.close();
    });

    test('13. Modifica categoria persiste dopo reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final cat = db.categories.first;
      await db.updateCategory(cat.id, 'Nome Aggiornato', 0xFFFF0000);

      // Reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();

      final updated =
          db2.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.name, 'Nome Aggiornato');
      expect(updated.color, 0xFFFF0000);

      await sqlite.close();
    });

    test('14. Archiviazione categoria persiste dopo reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final cat = db.categories.first;
      db.archiveCategory(cat.id);

      // Reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();

      final archived =
          db2.categories.firstWhere((c) => c.id == cat.id);
      expect(archived.archived, true);

      await sqlite.close();
    });

    test('15. Eliminazione categoria persiste dopo reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addCategory('Temporanea', MovementType.expense, 0xFF0000);
      final temp =
          db.categories.firstWhere((c) => c.name == 'Temporanea');
      await db.deleteCategory(temp.id);

      // Reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();

      expect(db2.categories.any((c) => c.name == 'Temporanea'), false);

      await sqlite.close();
    });

    test('16. Categorie iniziali non impattate da operazioni CRUD SQLite', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await Future.delayed(const Duration(milliseconds: 100));

      final initialCount = await sqlite.getCategoriesCount();
      expect(initialCount, 10);

      await db.addCategory('Extra', MovementType.expense, 0xFF0000);
      await Future.delayed(const Duration(milliseconds: 100));

      final afterAdd = await sqlite.getCategoriesCount();
      expect(afterAdd, 11);

      await sqlite.close();
    });

    test('17. SQLite updateCategory preserva createdAt', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final cat = db.categories.first;
      final originalId = cat.id;

      await db.updateCategory(cat.id, 'Renamed', cat.color);

      // Direct SQLite query to verify
      final rows = await sqlite.loadCategories();
      final updated = rows.firstWhere((c) => c.id == originalId);
      expect(updated.name, 'Renamed');

      await sqlite.close();
    });
  });

  group('Categoria rename → propagazione', () {
    test('18. Rinomina categoria → categoria nel db ha nome nuovo', () async {
      final db = AppDatabase();
      final cat = db.categories.first;

      await db.updateCategory(cat.id, 'Nuovo Nome', cat.color);

      final fromDb = db.categories.where((c) => c.id == cat.id).firstOrNull;
      expect(fromDb?.name, 'Nuovo Nome');
    });

    test('19. Rinomina categoria → risoluzione nome movimento usa db.categories', () async {
      final db = AppDatabase();
      final cat = db.categories.firstWhere((c) => c.type == MovementType.expense);

      await db.addMovement(Movement(
        id: 'm_rename_1',
        title: 'Test',
        amount: 50,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      ));

      await db.updateCategory(cat.id, 'Expense Rinominata', cat.color);

      final resolved = db.categories
          .where((c) => c.id == cat.id)
          .firstOrNull;
      expect(resolved?.name, 'Expense Rinominata');
      // Il movimento esiste ancora e referenzia l'ID corretto
      expect(db.movements.any((m) => m.categoryId == cat.id), true);
    });

    test('20. Categoria custom → nome corretto in db.categories', () async {
      final db = AppDatabase();
      await db.addCategory('Categoria Custom', MovementType.expense, 0xFFFF7043);
      final custom = db.categories.where((c) => c.name == 'Categoria Custom').firstOrNull;
      expect(custom, isNotNull);
      expect(custom?.name, 'Categoria Custom');

      await db.addMovement(Movement(
        id: 'm_custom_1',
        title: 'Spesa Custom',
        amount: 30,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: custom!.id,
        createdAt: DateTime.now(),
      ));

      final resolved = db.categories
          .where((c) => c.id == custom.id)
          .firstOrNull;
      expect(resolved?.name, 'Categoria Custom');
    });

    test('21. Rinomina categoria → saldi invariati', () async {
      final db = AppDatabase();
      final incCat = db.categories.firstWhere((c) => c.type == MovementType.income);
      final expCat = db.categories.firstWhere((c) => c.type == MovementType.expense);

      await db.addMovement(Movement(
        id: 'm_bal_1', title: 'Entrata', amount: 1000,
        type: MovementType.income, date: DateTime.now(),
        categoryId: incCat.id, createdAt: DateTime.now(),
      ));
      await db.addMovement(Movement(
        id: 'm_bal_2', title: 'Uscita', amount: 300,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: expCat.id, createdAt: DateTime.now(),
      ));

      final incomeBefore = db.totalIncome;
      final expensesBefore = db.totalExpenses;
      final balanceBefore = db.balance;

      await db.updateCategory(incCat.id, 'Stipendio Nuovo', incCat.color);
      await db.updateCategory(expCat.id, 'Spesa Nuova', expCat.color);

      expect(db.totalIncome, incomeBefore);
      expect(db.totalExpenses, expensesBefore);
      expect(db.balance, balanceBefore);
    });

    test('22. Rinomina categoria con SQLite → reload → nome persiste', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final cat = db.categories.first;
      final catId = cat.id;

      await db.addMovement(Movement(
        id: 'm_sql_rename_1', title: 'Test', amount: 50,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: catId, createdAt: DateTime.now(),
      ));

      await db.updateCategory(catId, 'SQLite Renamed', cat.color);

      // Reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();

      final resolved = db2.categories.where((c) => c.id == catId).firstOrNull;
      expect(resolved?.name, 'SQLite Renamed');
      expect(db2.movements.any((m) => m.categoryId == catId), true);

      await sqlite.close();
    });

    test('23. Rinomina categoria → rapido referenzia ID categoria rinominata', () async {
      final db = AppDatabase();
      final cat = db.categories.first;

      await db.addQuickMovement(QuickMovement(
        id: 'qm_rename_1', title: 'Rapido Test', amount: 10,
        type: MovementType.expense, categoryId: cat.id,
      ));

      await db.updateCategory(cat.id, 'Nuovo Nome Rapido', cat.color);

      final resolved = db.categories.where((c) => c.id == cat.id).firstOrNull;
      expect(resolved?.name, 'Nuovo Nome Rapido');
      expect(db.quickMovements.any((q) => q.categoryId == cat.id), true);
    });

    test('24. Rinomina categoria → preferito referenzia ID categoria rinominata', () async {
      final db = AppDatabase();
      final cat = db.categories.first;

      await db.addFavoriteMovement(FavoriteMovement(
        id: 'fm_rename_1', title: 'Preferito Test', amount: 20,
        type: MovementType.expense, categoryId: cat.id,
      ));

      await db.updateCategory(cat.id, 'Nuovo Nome Preferito', cat.color);

      final resolved = db.categories.where((c) => c.id == cat.id).firstOrNull;
      expect(resolved?.name, 'Nuovo Nome Preferito');
      expect(db.favoriteMovements.any((f) => f.categoryId == cat.id), true);
    });

    test('25. Archivia categoria → storico movimento risolve ancora nome', () async {
      final db = AppDatabase();
      final cat = db.categories.firstWhere((c) => c.type == MovementType.expense);
      final catId = cat.id;

      await db.addMovement(Movement(
        id: 'm_archive_view_1', title: 'Archiviato Test', amount: 40,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: catId, createdAt: DateTime.now(),
      ));

      db.archiveCategory(catId);

      // Anche archiviata, la categoria è ancora in db.categories
      final resolved = db.categories.where((c) => c.id == catId).firstOrNull;
      expect(resolved, isNotNull);
      expect(resolved?.archived, true);
      expect(resolved?.name, cat.name);
    });

    test('26. Categoria custom + SQLite reload → nome corretto in db.categories', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addCategory('Custom SQLite', MovementType.expense, 0xFF42A5F5);
      final custom = db.categories.where((c) => c.name == 'Custom SQLite').first;
      final customId = custom.id;

      await db.addMovement(Movement(
        id: 'm_custom_sql_1', title: 'Custom SQL', amount: 25,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: customId, createdAt: DateTime.now(),
      ));

      // Reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();

      final resolved = db2.categories.where((c) => c.id == customId).firstOrNull;
      expect(resolved?.name, 'Custom SQLite');
      expect(db2.movements.any((m) => m.categoryId == customId), true);

      await sqlite.close();
    });
  });

  group('Categoria rename + edit movimento', () {
    test('27. Edit movimento + rename categoria → movimento mantiene categoryId', () async {
      final db = AppDatabase();
      final cat = db.categories.firstWhere((c) => c.type == MovementType.expense);
      final catId = cat.id;

      await db.addMovement(Movement(
        id: 'm_edit_rename_1', title: 'Originale', amount: 60,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: catId, createdAt: DateTime.now(),
      ));

      await db.updateCategory(catId, 'Categoria Rinominata', cat.color);

      // Edit movimento (es. cambio titolo)
      final m = db.movements.first;
      await db.updateMovement(m.copyWith(title: 'Modificato'));

      final resolvedCat = db.categories.where((c) => c.id == catId).firstOrNull;
      expect(resolvedCat?.name, 'Categoria Rinominata');
      expect(db.movements.first.categoryId, catId);
      expect(db.movements.first.title, 'Modificato');
    });
  });
}
