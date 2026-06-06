import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/models/favorite_movement.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('In-memory mode', () {
    test('1. Default account created in in-memory mode', () {
      final db = AppDatabase();
      expect(db.accounts.length, 1);
      expect(db.accounts.first.name, 'Principale');
      expect(db.accounts.first.archived, false);
    });

    test('2. Add account in-memory mode', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addAccount(Account(
        id: 'acc_test',
        name: 'Contante',
        type: AccountType.cash,
        initialBalance: 100.0,
        createdAt: now,
      ));
      expect(db.accounts.length, 2);
      expect(db.accounts.any((a) => a.name == 'Contante'), true);
    });

    test('3. Archive account in-memory mode', () {
      final db = AppDatabase();
      db.archiveAccount('acc_default');
      final archived = db.accounts.firstWhere((a) => a.id == 'acc_default');
      expect(archived.archived, true);
    });

    test('4. Account balance with movements', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addMovement(Movement(
        id: 'inc1', title: 'Stipendio', amount: 2000,
        type: MovementType.income, date: now, categoryId: 'inc_1',
        accountId: 'acc_default', createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'exp1', title: 'Spesa', amount: 500,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        accountId: 'acc_default', createdAt: now,
      ));

      final acc = db.getAccount('acc_default');
      expect(db.getAccountBalance(acc), 1500.0);
    });

    test('5. Total accounts balance', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc2', name: 'Cash', type: AccountType.cash,
        initialBalance: 200.0, createdAt: now,
      ));

      db.addMovement(Movement(
        id: 'm1', title: 'Income', amount: 1000,
        type: MovementType.income, date: now, categoryId: 'inc_1',
        accountId: 'acc_default', createdAt: now,
      ));

      expect(db.totalAccountsBalance, 1200.0); // 0 + 200 + 1000
    });

    test('6. Update account details', () {
      final db = AppDatabase();
      db.updateAccount('acc_default', 'Banca Principale', AccountType.bank, 500);
      final acc = db.getAccount('acc_default');
      expect(acc.name, 'Banca Principale');
    });

    test('7. Account balance with no movements', () {
      final db = AppDatabase();
      final acc = db.getAccount('acc_default');
      expect(db.getAccountBalance(acc), 0.0);
    });
  });

  group('SQLite persistence', () {
    test('8. Default account persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      expect(db.accounts.length, 1);
      expect(db.accounts.first.name, 'Principale');

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.accounts.length, 1);
      expect(db2.accounts.first.name, 'Principale');

      await sqlite.close();
    });

    test('9. New account persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      db.addAccount(Account(
        id: 'acc_test_1',
        name: 'Contanti',
        type: AccountType.cash,
        initialBalance: 50.0,
        createdAt: DateTime.now(),
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.accounts.length, 2);
      expect(db2.accounts.any((a) => a.name == 'Contanti'), true);
      expect(db2.accounts.any((a) => a.name == 'Principale'), true);

      await sqlite.close();
    });

    test('10. Account archive persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      db.archiveAccount('acc_default');

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      final archived = db2.accounts.firstWhere((a) => a.id == 'acc_default');
      expect(archived.archived, true);

      await sqlite.close();
    });

    test('11. Account balance survives reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      db.addMovement(Movement(
        id: 'inc_bal', title: 'Stipendio', amount: 3000,
        type: MovementType.income, date: DateTime.now(),
        categoryId: 'inc_1', accountId: 'acc_default', createdAt: DateTime.now(),
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      final acc = db2.getAccount('acc_default');
      expect(db2.getAccountBalance(acc), 3000.0);

      await sqlite.close();
    });

    test('12. Account update persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      db.updateAccount('acc_default', 'Principale Banca', AccountType.bank, 1000);

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      final acc = db2.getAccount('acc_default');
      expect(acc.name, 'Principale Banca');
      expect(acc.initialBalance, 1000.0);

      await sqlite.close();
    });

    test('13. Multiple accounts with separate balances', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_cash', name: 'Contanti', type: AccountType.cash,
        initialBalance: 200.0, createdAt: now,
      ));

      db.addMovement(Movement(
        id: 'm_inc', title: 'Income', amount: 1000,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', accountId: 'acc_default', createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'm_exp', title: 'Spesa contanti', amount: 50,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', accountId: 'acc_cash', createdAt: now,
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.getAccountBalance(db2.getAccount('acc_default')), 1000.0);
      expect(db2.getAccountBalance(db2.getAccount('acc_cash')), 150.0);

      await sqlite.close();
    });

    test('14. Archived accounts excluded from total balance', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_old', name: 'Vecchio', type: AccountType.bank,
        initialBalance: 500.0, createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'm_old_inc', title: 'Old inc', amount: 1000,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', accountId: 'acc_old', createdAt: now,
      ));

      // Before archive
      expect(db.totalAccountsBalance, 1500.0);

      db.archiveAccount('acc_old');
      expect(db.totalAccountsBalance, 0.0); // Only 'acc_default' with no movements

      await Future.delayed(const Duration(milliseconds: 100));
      await sqlite.close();
    });
  });

  group('Edit Movement', () {
    test('15. Edit movement title', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_1', title: 'Vecchio', amount: 100,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      db.updateMovement(db.movements.first.copyWith(title: 'Nuovo', updatedAt: DateTime.now()));
      expect(db.movements.length, 1);
      expect(db.movements.first.title, 'Nuovo');
    });

    test('16. Edit movement amount', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_2', title: 'Test', amount: 50,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      db.updateMovement(db.movements.first.copyWith(amount: 99.99, updatedAt: DateTime.now()));
      expect(db.movements.first.amount, 99.99);
    });

    test('17. Edit movement category', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_3', title: 'Test', amount: 50,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      db.updateMovement(db.movements.first.copyWith(categoryId: 'exp_3', updatedAt: DateTime.now()));
      expect(db.movements.first.categoryId, 'exp_3');
    });

    test('18. Edit movement account', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addAccount(Account(
        id: 'acc_edit', name: 'Secondo', type: AccountType.cash,
        createdAt: now,
      ));
      db.addMovement(Movement(
        id: 'edit_4', title: 'Test', amount: 50,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        accountId: 'acc_default', createdAt: now,
      ));
      db.updateMovement(db.movements.first.copyWith(accountId: 'acc_edit', updatedAt: DateTime.now()));
      expect(db.movements.first.accountId, 'acc_edit');
    });

    test('19. Edit movement note', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_5', title: 'Test', amount: 50,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      expect(db.movements.first.note, isNull);
      db.updateMovement(db.movements.first.copyWith(note: 'Nota aggiunta', updatedAt: DateTime.now()));
      expect(db.movements.first.note, 'Nota aggiunta');
    });

    test('20. Edit movement type (expense -> income)', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_6', title: 'Test', amount: 50,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      db.updateMovement(db.movements.first.copyWith(
        type: MovementType.income, categoryId: 'inc_1', updatedAt: DateTime.now(),
      ));
      expect(db.movements.first.type, MovementType.income);
      expect(db.movements.first.categoryId, 'inc_1');
    });

    test('21. Edit movement date', () {
      final db = AppDatabase();
      final now = DateTime.now();
      final newDate = DateTime(2025, 1, 1);
      db.addMovement(Movement(
        id: 'edit_7', title: 'Test', amount: 50,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      db.updateMovement(db.movements.first.copyWith(date: newDate, updatedAt: DateTime.now()));
      expect(db.movements.first.date, newDate);
    });

    test('22. createdAt unchanged after edit', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_8', title: 'Originale', amount: 100,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      final originalCreatedAt = db.movements.first.createdAt;
      db.updateMovement(db.movements.first.copyWith(title: 'Modificato', updatedAt: DateTime.now()));
      expect(db.movements.first.createdAt, originalCreatedAt);
    });

    test('23. updatedAt updated after edit', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_9', title: 'Test', amount: 100,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));
      final later = now.add(const Duration(hours: 1));
      db.updateMovement(db.movements.first.copyWith(title: 'Modificato', updatedAt: later));
      expect(db.movements.first.updatedAt, later);
      expect(db.movements.first.createdAt, now);
    });

    test('24. Dashboard updates after edit', () {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(Movement(
        id: 'edit_10', title: 'Stipendio', amount: 2000,
        type: MovementType.income, date: now, categoryId: 'inc_1',
        createdAt: now,
      ));
      expect(db.totalIncome, 2000.0);
      expect(db.balance, 2000.0);

      // Edit: change from income to expense
      db.updateMovement(db.movements.first.copyWith(
        title: 'Bolletta',
        amount: 500,
        type: MovementType.expense,
        categoryId: 'exp_2',
        updatedAt: DateTime.now(),
      ));
      expect(db.totalIncome, 0.0);
      expect(db.totalExpenses, 500.0);
      expect(db.balance, -500.0);
    });
  });

  group('Edit Movement — SQLite persistence', () {
    test('25. Edit persists after reload', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final now = DateTime.now();

      db.addMovement(Movement(
        id: 'edit_persist', title: 'Originale', amount: 100,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));

      db.updateMovement(db.movements.first.copyWith(
        title: 'Modificato',
        amount: 200,
        categoryId: 'exp_3',
        note: 'Nota dopo modifica',
        updatedAt: DateTime.now(),
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 1);
      expect(db2.movements.first.title, 'Modificato');
      expect(db2.movements.first.amount, 200.0);
      expect(db2.movements.first.categoryId, 'exp_3');
      expect(db2.movements.first.note, 'Nota dopo modifica');
      // createdAt should be preserved
      expect(db2.movements.first.createdAt, now);

      await sqlite.close();
    });

    test('26. Update uses SQL UPDATE (not INSERT)', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final now = DateTime.now();

      db.addMovement(Movement(
        id: 'update_test', title: 'Prima', amount: 100,
        type: MovementType.expense, date: now, categoryId: 'exp_1',
        createdAt: now,
      ));

      db.updateMovement(db.movements.first.copyWith(
        title: 'Dopo', updatedAt: DateTime.now(),
      ));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 1); // Not 2 — UPDATE not INSERT
      expect(db2.movements.first.title, 'Dopo');

      await sqlite.close();
    });
  });

  group('AccountId in Rapidi / Preferiti', () {
    test('27. QuickMovement salva accountId', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_test_qm', name: 'Secondo', type: AccountType.cash,
        createdAt: now,
      ));

      db.addQuickMovement(const QuickMovement(
        id: 'qm_test', title: 'Test', amount: 10,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: 'acc_test_qm',
      ));

      expect(db.quickMovements.firstWhere((q) => q.id == 'qm_test').accountId, 'acc_test_qm');
    });

    test('28. FavoriteMovement salva accountId', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_test_fm', name: 'Secondo', type: AccountType.cash,
        createdAt: now,
      ));

      db.addFavoriteMovement(const FavoriteMovement(
        id: 'fm_test', title: 'Test', amount: 10,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: 'acc_test_fm',
      ));

      expect(db.favoriteMovements.first.accountId, 'acc_test_fm');
    });

    test('29. Rapido crea movimento sul conto corretto', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_rapido', name: 'Conto Rapido', type: AccountType.cash,
        createdAt: now,
      ));

      db.addQuickMovement(const QuickMovement(
        id: 'qm_rapido', title: 'Test Rapido', amount: 25,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: 'acc_rapido',
      ));

      final qm = db.quickMovements.firstWhere((q) => q.id == 'qm_rapido');
      db.createMovementFromTemplate(
        title: qm.title,
        amount: qm.amount,
        type: qm.type,
        categoryId: qm.categoryId,
        accountId: qm.accountId,
      );

      expect(db.movements.first.accountId, 'acc_rapido');
    });

    test('30. Preferito crea movimento sul conto corretto', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_pref', name: 'Conto Preferito', type: AccountType.cash,
        createdAt: now,
      ));

      db.addFavoriteMovement(const FavoriteMovement(
        id: 'fm_pref', title: 'Test Pref', amount: 50,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: 'acc_pref',
      ));

      db.createMovementFromTemplate(
        title: db.favoriteMovements.first.title,
        amount: db.favoriteMovements.first.amount,
        type: db.favoriteMovements.first.type,
        categoryId: db.favoriteMovements.first.categoryId,
        accountId: db.favoriteMovements.first.accountId,
      );

      expect(db.movements.first.accountId, 'acc_pref');
    });

    test('31. Salva movimento come preferito copia accountId', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_save_fav', name: 'Conto Salvato', type: AccountType.cash,
        createdAt: now,
      ));

      db.addMovement(Movement(
        id: 'm_save', title: 'Da salvare', amount: 100,
        type: MovementType.income, date: now, categoryId: 'inc_1',
        accountId: 'acc_save_fav', createdAt: now,
      ));

      db.saveMovementAsFavorite(db.movements.first);

      expect(db.favoriteMovements.length, 1);
      expect(db.favoriteMovements.first.accountId, 'acc_save_fav');
    });

    test('32. Saldo conto aggiornato dopo uso Rapido', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_bal_rap', name: 'Bilancio', type: AccountType.cash,
        initialBalance: 1000, createdAt: now,
      ));

      db.addQuickMovement(const QuickMovement(
        id: 'qm_bal', title: 'Spesa veloce', amount: 100,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: 'acc_bal_rap',
      ));

      final qm = db.quickMovements.firstWhere((q) => q.id == 'qm_bal');
      db.createMovementFromTemplate(
        title: qm.title,
        amount: qm.amount,
        type: qm.type,
        categoryId: qm.categoryId,
        accountId: qm.accountId,
      );

      final acc = db.getAccount('acc_bal_rap');
      expect(db.getAccountBalance(acc), 900.0);
    });

    test('33. Saldo conto aggiornato dopo uso Preferito', () {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_bal_pref', name: 'Bilancio', type: AccountType.cash,
        initialBalance: 500, createdAt: now,
      ));

      db.addFavoriteMovement(const FavoriteMovement(
        id: 'fm_bal', title: 'Entrata preferita', amount: 200,
        type: MovementType.income, categoryId: 'inc_1',
        accountId: 'acc_bal_pref',
      ));

      final fm = db.favoriteMovements.firstWhere((f) => f.id == 'fm_bal');
      db.createMovementFromTemplate(
        title: fm.title,
        amount: fm.amount,
        type: fm.type,
        categoryId: fm.categoryId,
        accountId: fm.accountId,
      );

      final acc = db.getAccount('acc_bal_pref');
      expect(db.getAccountBalance(acc), 700.0);
    });
  });

  group('AccountId Rapidi/Preferiti — SQLite persistence', () {
    test('34. Persistenza accountId su quick_movements dopo reload DB', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_pers_qm', name: 'Persistente', type: AccountType.cash,
        createdAt: now,
      ));

      db.addQuickMovement(QuickMovement(
        id: 'qm_pers', title: 'Test', amount: 10,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: 'acc_pers_qm',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.quickMovements.any((q) => q.id == 'qm_pers'), true);
      expect(
        db2.quickMovements.firstWhere((q) => q.id == 'qm_pers').accountId,
        'acc_pers_qm',
      );

      await sqlite.close();
    });

    test('35. Persistenza accountId su favorite_movements dopo reload DB', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final now = DateTime.now();

      db.addAccount(Account(
        id: 'acc_pers_fm', name: 'Persistente', type: AccountType.cash,
        createdAt: now,
      ));

      db.addFavoriteMovement(FavoriteMovement(
        id: 'fm_pers', title: 'Test', amount: 10,
        type: MovementType.expense, categoryId: 'exp_1',
        accountId: 'acc_pers_fm',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.favoriteMovements.any((f) => f.id == 'fm_pers'), true);
      expect(
        db2.favoriteMovements.firstWhere((f) => f.id == 'fm_pers').accountId,
        'acc_pers_fm',
      );

      await sqlite.close();
    });

    test('36. Migrazione record legacy senza account_id -> Principale', () async {
      // Test that fromMap fallback handles null account_id
      // This simulates legacy records created before v3 migration
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      db.addQuickMovement(const QuickMovement(
        id: 'qm_legacy', title: 'Legacy', amount: 10,
        type: MovementType.expense, categoryId: 'exp_1',
      ));

      db.addFavoriteMovement(const FavoriteMovement(
        id: 'fm_legacy', title: 'Legacy', amount: 10,
        type: MovementType.expense, categoryId: 'exp_1',
      ));

      // Reload and verify default accountId
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();

      expect(
        db2.quickMovements.firstWhere((q) => q.id == 'qm_legacy').accountId,
        defaultAccountId,
      );
      expect(
        db2.favoriteMovements.firstWhere((f) => f.id == 'fm_legacy').accountId,
        defaultAccountId,
      );

      await sqlite.close();
    });
  });
}
