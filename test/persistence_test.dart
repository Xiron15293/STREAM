import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/models/favorite_movement.dart';

/// Create an AppDatabase backed by an in-memory SQLite database.
Future<AppDatabase> createPersistentDb() async {
  final sqlite = SQLiteService();
  await sqlite.open(path: inMemoryDatabasePath);
  final db = AppDatabase(sqlite: sqlite);
  await db.initialize();
  return db;
}

/// Simulate a "reload" by creating a new AppDatabase with fresh SQLite service.
Future<AppDatabase> reloadDb(SQLiteService sqlite) async {
  final db = AppDatabase(sqlite: sqlite);
  await db.initialize();
  return db;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── 1. Movimento persistente dopo reload ──

  test('1. Movimento persistente dopo reload database', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addMovement(Movement(
      id: 'persist_1',
      title: 'Persistente',
      amount: 100.0,
      type: MovementType.income,
      date: DateTime(2026, 6, 1),
      categoryId: 'inc_1',
      createdAt: DateTime(2026, 6, 1, 10, 0),
    ));

    final db2 = await reloadDb(sqlite);
    expect(db2.movements.length, 1);
    expect(db2.movements.first.title, 'Persistente');
    expect(db2.movements.first.amount, 100.0);
    expect(db2.totalIncome, 100.0);

    await sqlite.close();
  });

  // ── 2. Categoria persistente dopo reload ──

  test('2. Categoria persistente dopo reload database', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    // Categories should have been seeded on init
    expect(db.categories.length, 10);

    final db2 = await reloadDb(sqlite);
    expect(db2.categories.length, 10);
    expect(db2.categories.any((c) => c.name == 'Stipendio'), true);
    expect(db2.categories.any((c) => c.name == 'Spesa'), true);

    await sqlite.close();
  });

  // ── 3. Rapido persistente dopo reload ──

  test('3. Rapido persistente dopo reload database', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addQuickMovement(QuickMovement(
      id: 'qm_persist',
      title: 'Palestra',
      amount: 49.99,
      type: MovementType.expense,
      categoryId: 'exp_4',
    ));

    final db2 = await reloadDb(sqlite);
    expect(db2.quickMovements.length, 5); // 4 defaults + 1 new
    expect(db2.quickMovements.any((q) => q.title == 'Palestra'), true);

    await sqlite.close();
  });

  // ── 4. Preferito persistente dopo reload ──

  test('4. Preferito persistente dopo reload database', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addFavoriteMovement(FavoriteMovement(
      id: 'fav_persist',
      title: 'Netflix',
      amount: 15.99,
      type: MovementType.expense,
      categoryId: 'exp_4',
    ));

    final db2 = await reloadDb(sqlite);
    expect(db2.favoriteMovements.length, 1);
    expect(db2.favoriteMovements.first.title, 'Netflix');

    await sqlite.close();
  });

  // ── 5. Duplicazione movimento salvata in SQLite ──

  test('5. Duplicazione movimento salvata in SQLite', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addMovement(Movement(
      id: 'orig',
      title: 'Caffè',
      amount: 1.50,
      type: MovementType.expense,
      date: DateTime(2026, 6, 1),
      categoryId: 'exp_4',
      note: 'Mattina',
      createdAt: DateTime(2026, 6, 1, 8, 0),
    ));

    await db.duplicateMovement(db.movements.first);

    final db2 = await reloadDb(sqlite);
    expect(db2.movements.length, 2);
    expect(db2.movements.last.title, 'Caffè');
    expect(db2.movements.last.amount, 1.50);
    expect(db2.movements.last.note, 'Mattina');

    await sqlite.close();
  });

  // ── 6. Note preservate ──

  test('6. Note preservate dopo reload', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addMovement(Movement(
      id: 'note_test',
      title: 'Test nota',
      amount: 25.0,
      type: MovementType.expense,
      date: DateTime.now(),
      categoryId: 'exp_1',
      note: 'Nota importante di test',
      createdAt: DateTime.now(),
    ));

    final db2 = await reloadDb(sqlite);
    expect(db2.movements.length, 1);
    expect(db2.movements.first.note, 'Nota importante di test');

    // Movement with null note
    await db2.addMovement(Movement(
      id: 'no_note',
      title: 'Senza nota',
      amount: 10.0,
      type: MovementType.expense,
      date: DateTime.now(),
      categoryId: 'exp_1',
      createdAt: DateTime.now(),
    ));

    final db3 = await reloadDb(sqlite);
    expect(db3.movements.length, 2);
    expect(db3.movements.firstWhere((m) => m.id == 'no_note').note, isNull);

    await sqlite.close();
  });

  // ── 7. Suggeriti funzionano dopo reload ──

  test('7. Suggeriti funzionano dopo reload', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    // Add 5 identical movements to trigger suggestion
    for (int i = 0; i < 5; i++) {
      await db.addMovement(Movement(
        id: 'sug_$i',
        title: 'Caffè',
        amount: 1.50,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'exp_4',
        createdAt: DateTime.now(),
      ));
    }

    final db2 = await reloadDb(sqlite);
    final suggestions = db2.getSuggestions();
    expect(suggestions.length, 1);
    expect(suggestions.first.title, 'Caffè');
    expect(suggestions.first.categoryId, 'exp_4');

    await sqlite.close();
  });

  // ── 8. Categorie iniziali non duplicate a ogni avvio ──

  test('8. Categorie iniziali non duplicate a ogni avvio', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    // First init seeds 10 categories
    expect(db.categories.length, 10);

    // Simulate second init (reload)
    final db2 = await reloadDb(sqlite);
    expect(db2.categories.length, 10); // Should still be 10, not 20

    // Simulate third init
    final db3 = await reloadDb(sqlite);
    expect(db3.categories.length, 10); // Still 10

    await sqlite.close();
  });

  // ── 9. Eliminazione movimento persistente ──

  test('9. Eliminazione movimento persistente', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addMovement(Movement(
      id: 'to_delete',
      title: 'Da eliminare',
      amount: 50.0,
      type: MovementType.expense,
      date: DateTime.now(),
      categoryId: 'exp_1',
      createdAt: DateTime.now(),
    ));
    expect(db.movements.length, 1);

    await db.deleteMovement('to_delete');

    final db2 = await reloadDb(sqlite);
    expect(db2.movements.length, 0);

    await sqlite.close();
  });

  // ── 10. Salva movimento come preferito → persiste ──

  test('10. Salva movimento come preferito persiste', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addMovement(Movement(
      id: 'src',
      title: 'Palestra',
      amount: 50.0,
      type: MovementType.expense,
      date: DateTime.now(),
      categoryId: 'exp_4',
      createdAt: DateTime.now(),
    ));

    await db.saveMovementAsFavorite(db.movements.first);

    final db2 = await reloadDb(sqlite);
    expect(db2.favoriteMovements.length, 1);
    expect(db2.favoriteMovements.first.title, 'Palestra');

    await sqlite.close();
  });

  // ── 11. Crea movimento da template persiste ──

  test('11. Crea movimento da template persiste', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.createMovementFromTemplate(
      title: 'Template test',
      amount: 99.99,
      type: MovementType.income,
      categoryId: 'inc_1',
      note: 'Da template',
    );

    final db2 = await reloadDb(sqlite);
    expect(db2.movements.length, 1);
    expect(db2.movements.first.title, 'Template test');
    expect(db2.movements.first.amount, 99.99);
    expect(db2.movements.first.note, 'Da template');

    await sqlite.close();
  });

  // ── 12. Quick movement update persiste ──

  test('12. Quick movement update persiste', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    final updated = QuickMovement(
      id: 'qm_1',
      title: 'Caffè doppio',
      amount: 2.00,
      type: MovementType.expense,
      categoryId: 'exp_4',
    );
    await db.updateQuickMovement('qm_1', updated);

    final db2 = await reloadDb(sqlite);
    final qm = db2.quickMovements.firstWhere((q) => q.id == 'qm_1');
    expect(qm.title, 'Caffè doppio');
    expect(qm.amount, 2.00);

    await sqlite.close();
  });

  // ── 13. Quick movement delete persiste ──

  test('13. Quick movement delete persiste', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.deleteQuickMovement('qm_1');

    final db2 = await reloadDb(sqlite);
    expect(db2.quickMovements.length, 3);

    await sqlite.close();
  });

  // ── 14. Favorite movement delete persiste ──

  test('14. Favorite movement delete persiste', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addFavoriteMovement(FavoriteMovement(
      id: 'fav_del',
      title: 'Da cancellare',
      amount: 10.0,
      type: MovementType.expense,
      categoryId: 'exp_1',
    ));
    expect(db.favoriteMovements.length, 1);

    await db.deleteFavoriteMovement('fav_del');

    final db2 = await reloadDb(sqlite);
    expect(db2.favoriteMovements.length, 0);

    await sqlite.close();
  });

  // ── 15. Aggregati corretti dopo reload ──

  test('15. Aggregati dashboard corretti dopo reload', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    await db.addMovement(Movement(
      id: 'i1', title: 'Stipendio', amount: 2000.0,
      type: MovementType.income, date: DateTime.now(),
      categoryId: 'inc_1', createdAt: DateTime.now(),
    ));
    await db.addMovement(Movement(
      id: 'e1', title: 'Affitto', amount: 800.0,
      type: MovementType.expense, date: DateTime.now(),
      categoryId: 'exp_2', createdAt: DateTime.now(),
    ));

    final db2 = await reloadDb(sqlite);
    expect(db2.totalIncome, 2000.0);
    expect(db2.totalExpenses, 800.0);
    expect(db2.balance, 1200.0);
    expect(db2.lastMovements.length, 2);

    await sqlite.close();
  });

  // ── 16. Movimenti rapidi default persistono all\'avvio ──

  test('16. Movimenti rapidi default presenti dopo init', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();

    expect(db.quickMovements.length, 4);
    expect(db.quickMovements.any((q) => q.title == 'Caffè'), true);
    expect(db.quickMovements.any((q) => q.title == 'Stipendio'), true);

    await sqlite.close();
  });

  // ── 17. Nessuna categoria duplicata dopo init multiplo ──

  test('17. Init multiplo non duplica categorie', () async {
    final sqlite = SQLiteService();
    await sqlite.open(path: inMemoryDatabasePath);

    // Init 3 volte
    for (int i = 0; i < 3; i++) {
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      expect(db.categories.length, 10,
          reason: 'init #$i should have exactly 10 categories');
    }

    // Verifica finale: solo 10 categorie
    final finalCount = await sqlite.getCategoriesCount();
    expect(finalCount, 10);

    await sqlite.close();
  });
}
