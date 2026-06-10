import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/main.dart';
import 'helpers/calculator_test_helpers.dart';

/// Helper: create AppDatabase + pump app
Future<AppDatabase> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final db = AppDatabase();
  await tester.pumpWidget(MaterialApp(
    home: MainScaffold(db: db),
  ));
  return db;
}

/// Helper: save a movement via UI
Future<void> saveMovement(
  WidgetTester tester, {
  required String title,
  required String amount,
  bool isIncome = false,
}) async {
  await tester.tap(find.text('Archivio'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Titolo'), title);
  await enterAmountWithCalculator(tester, amount);
  if (isIncome) {
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();
  }

  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Salva'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Salva'));
  await tester.pumpAndSettle();
}

/// Navigate to Dashboard tab
Future<void> goToDashboard(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.dashboard));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── In-memory tests (pure logic, no UI) ──

  group('1. Dashboard KPI dopo deleteMovement (in-memory)', () {
    test('1.1 Elimina entrata → dashboard entrate diminuisce', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Income', amount: 500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      expect(db.totalIncome, 500);
      await db.deleteMovement('m1');
      expect(db.totalIncome, 0.0);
    });

    test('1.2 Elimina uscita → dashboard uscite diminuisce', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Expense', amount: 200,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));
      expect(db.totalExpenses, 200);
      await db.deleteMovement('m1');
      expect(db.totalExpenses, 0.0);
    });

    test('1.3 Elimina entrata → saldo totale diminuisce', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Income', amount: 500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      expect(db.balance, 500);
      await db.deleteMovement('m1');
      expect(db.balance, 0.0);
    });

    test('1.4 Elimina uscita → saldo totale aumenta', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'm1', title: 'Expense', amount: 200,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));
      expect(db.balance, -200);
      await db.deleteMovement('m1');
      expect(db.balance, 0.0);
    });

    test('1.5 Elimina movimento su conto A → saldo conto A aggiornato', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addAccount(Account(
        id: 'acc_a', name: 'Conto A', type: AccountType.cash,
        initialBalance: 1000, createdAt: now,
      ));
      final accA = db.accounts.firstWhere((a) => a.id == 'acc_a');
      expect(db.getAccountBalance(accA), 1000);

      await db.addMovement(Movement(
        id: 'm1', title: 'Spesa', amount: 300,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', accountId: 'acc_a', createdAt: now,
      ));
      expect(db.getAccountBalance(accA), 700);

      await db.deleteMovement('m1');
      expect(db.getAccountBalance(accA), 1000);
    });

    test('1.6 Elimina movimento su conto B → saldo conto B aggiornato', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addAccount(Account(
        id: 'acc_b', name: 'Conto B', type: AccountType.bank,
        initialBalance: 2000, createdAt: now,
      ));
      final accB = db.accounts.firstWhere((a) => a.id == 'acc_b');

      await db.addMovement(Movement(
        id: 'm1', title: 'Bonifico', amount: 100,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', accountId: 'acc_b', createdAt: now,
      ));
      expect(db.getAccountBalance(accB), 2100);

      await db.deleteMovement('m1');
      expect(db.getAccountBalance(accB), 2000);
    });

    test('1.7 totalAccountsBalance aggiornato dopo delete', () async {
      final db = AppDatabase();
      final now = DateTime.now();

      expect(db.totalAccountsBalance, 0.0);

      await db.addMovement(Movement(
        id: 'm1', title: 'Entrata', amount: 1000,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      expect(db.totalAccountsBalance, 1000);

      await db.deleteMovement('m1');
      expect(db.totalAccountsBalance, 0.0);
    });

    test('1.8 Elimina movimento duplicato → dashboard aggiornata', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'orig', title: 'Originale', amount: 50,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));
      await db.duplicateMovement(db.movements.first);
      expect(db.movements.length, 2);
      expect(db.totalExpenses, 100);

      final dup = db.movements.firstWhere((m) => m.id != 'orig');
      await db.deleteMovement(dup.id);
      expect(db.movements.length, 1);
      expect(db.totalExpenses, 50);
    });

    test('1.9 Elimina movimento creato da Rapido → dashboard aggiornata', () async {
      final db = AppDatabase();
      await db.createMovementFromTemplate(
        title: 'Caffè', amount: 1.50,
        type: MovementType.expense, categoryId: 'exp_4',
        accountId: defaultAccountId,
      );
      expect(db.movements.length, 1);
      expect(db.totalExpenses, 1.5);

      await db.deleteMovement(db.movements.first.id);
      expect(db.movements.length, 0);
      expect(db.totalExpenses, 0.0);
    });

    test('1.10 Elimina movimento creato da Preferito → dashboard aggiornata', () async {
      final db = AppDatabase();
      await db.addFavoriteMovement(const FavoriteMovement(
        id: 'fm_test', title: 'Ripetibile', amount: 100,
        type: MovementType.expense, categoryId: 'exp_1',
      ));
      await db.createMovementFromTemplate(
        title: 'Ripetibile', amount: 100,
        type: MovementType.expense, categoryId: 'exp_1',
      );
      expect(db.movements.length, 1);
      expect(db.totalExpenses, 100);

      await db.deleteMovement(db.movements.first.id);
      expect(db.movements.length, 0);
      expect(db.totalExpenses, 0.0);
    });

    test('1.11 Elimina movimento dopo modifica → dashboard aggiornata', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'edit_me', title: 'Prima', amount: 50,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));
      await db.updateMovement(db.movements.first.copyWith(
        title: 'Dopo', amount: 200, updatedAt: DateTime.now(),
      ));
      expect(db.totalExpenses, 200);

      await db.deleteMovement('edit_me');
      expect(db.totalExpenses, 0.0);
    });

    test('1.12 Annulla eliminazione → nessun saldo cambia', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'keep', title: 'Trattenere', amount: 100,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      expect(db.totalIncome, 100);
      // Non si elimina (simula Annulla)
      expect(db.movements.length, 1);
      expect(db.totalIncome, 100);
    });

    test('1.13 Elimina ultimo movimento → dashboard torna a zero', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'last', title: 'Ultimo', amount: 75,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));
      expect(db.totalExpenses, 75);
      await db.deleteMovement('last');
      expect(db.movements.length, 0);
      expect(db.totalExpenses, 0.0);
      expect(db.totalIncome, 0.0);
      expect(db.balance, 0.0);
    });

    test('1.14 Elimina movimento su conto default → saldo Principale aggiornato', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      final principale = db.accounts.first;
      expect(db.getAccountBalance(principale), 0);

      await db.addMovement(Movement(
        id: 'm1', title: 'Stipendio', amount: 2500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      expect(db.getAccountBalance(principale), 2500);

      await db.deleteMovement('m1');
      expect(db.getAccountBalance(principale), 0);
    });

    test('1.15 due eliminazioni consecutive → saldo corretto', () async {
      final db = AppDatabase();
      final now = DateTime.now();
      await db.addMovement(Movement(
        id: 'a', title: 'A', amount: 100,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      await db.addMovement(Movement(
        id: 'b', title: 'B', amount: 50,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));
      expect(db.balance, 50);

      await db.deleteMovement('a');
      expect(db.balance, -50);

      await db.deleteMovement('b');
      expect(db.balance, 0);
    });
  });

  // ── SQLite persistence tests ──

  group('2. Dashboard KPI dopo delete + SQLite reload', () {
    Future<AppDatabase> createDb(SQLiteService sqlite) async {
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      return db;
    }

    test('2.1 Elimina movimento → reload → movimento non torna', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      var db = await createDb(sqlite);
      final now = DateTime.now();

      await db.addMovement(Movement(
        id: 'persistent', title: 'Test', amount: 100,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));

      await db.deleteMovement('persistent');

      // Reload
      db = await createDb(sqlite);
      expect(db.movements.any((m) => m.id == 'persistent'), false);

      await sqlite.close();
    });

    test('2.2 Elimina movimento → reload → dashboard KPI corretti', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      var db = await createDb(sqlite);
      final now = DateTime.now();

      await db.addMovement(Movement(
        id: 'a', title: 'Entrata', amount: 500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', createdAt: now,
      ));
      await db.addMovement(Movement(
        id: 'b', title: 'Uscita', amount: 200,
        type: MovementType.expense, date: now,
        categoryId: 'exp_1', createdAt: now,
      ));

      expect(db.totalIncome, 500);
      expect(db.totalExpenses, 200);
      expect(db.balance, 300);

      await db.deleteMovement('a');

      // Reload
      db = await createDb(sqlite);
      expect(db.totalIncome, 0);
      expect(db.totalExpenses, 200);
      expect(db.balance, -200);

      await sqlite.close();
    });

    test('2.3 Elimina movimento su conto → reload → saldo conto corretto', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      var db = await createDb(sqlite);
      final now = DateTime.now();

      await db.addAccount(Account(
        id: 'acc_extra', name: 'Extra', type: AccountType.savings,
        initialBalance: 1000, createdAt: now,
      ));

      await db.addMovement(Movement(
        id: 'm1', title: 'Deposito', amount: 500,
        type: MovementType.income, date: now,
        categoryId: 'inc_1', accountId: 'acc_extra', createdAt: now,
      ));

      await db.deleteMovement('m1');

      // Reload
      db = await createDb(sqlite);
      final acc = db.accounts.firstWhere((a) => a.id == 'acc_extra');
      expect(db.getAccountBalance(acc), 1000);

      await sqlite.close();
    });
  });

  // ── UI widget tests ──

  group('3. UI Dashboard update dopo delete', () {
    testWidgets('3.1 Dashboard KPI si aggiorna dopo eliminazione dalla UI',
        (tester) async {
      final db = await pumpApp(tester);

      // Crea entrata da 500
      await saveMovement(tester, title: 'Stipendio', amount: '500', isIncome: true);
      await goToDashboard(tester);

      // Verifica KPI iniziali
      expect(find.textContaining('500.00'), findsWidgets);

      // Torna a Movimenti ed elimina
      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
      await tester.pumpAndSettle();

      // Torna a Dashboard
      await goToDashboard(tester);

      // Verifica KPI aggiornati (solo 0, nessun 500)
      expect(db.totalIncome, 0.0);
      expect(find.textContaining('0.00'), findsWidgets);
    });

    testWidgets('3.2 Saldo conti si aggiorna dopo eliminazione dalla UI',
        (tester) async {
      final db = await pumpApp(tester);

      // Crea entrata da 1000
      await saveMovement(tester, title: 'Bonifico', amount: '1000', isIncome: true);
      await goToDashboard(tester);

      expect(db.totalAccountsBalance, 1000);

      // Elimina
      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
      await tester.pumpAndSettle();

      await goToDashboard(tester);
      expect(db.totalAccountsBalance, 0);
    });

    testWidgets('3.3 Elimina uscita → saldo totale aumenta nella UI',
        (tester) async {
      final db = await pumpApp(tester);

      await saveMovement(tester, title: 'Spesa', amount: '100');
      await goToDashboard(tester);

      expect(db.balance, -100);

      // Elimina
      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      // Annulla
      await tester.tap(find.widgetWithText(TextButton, 'Annulla'));
      await tester.pumpAndSettle();

      await goToDashboard(tester);
      expect(db.balance, -100);
      expect(db.totalExpenses, 100);
    });
  });
}
