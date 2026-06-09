import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/main.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';


const String _defaultAccountId = 'acc_default';

Movement _makeMovement(int i) {
  return Movement(
    id: 'stress_m_$i',
    title: 'Movimento $i',
    amount: (i % 100) + 0.50,
    type: i.isEven ? MovementType.income : MovementType.expense,
    date: DateTime(2026, 6, (i % 28) + 1),
    categoryId: i.isEven ? 'inc_1' : 'exp_1',
    accountId: i.isEven ? _defaultAccountId : 'conto_b',
    createdAt: DateTime(2026, 6, (i % 28) + 1, i ~/ 60, i % 60),
  );
}

Movement _makeAccountMovement(int i, String accountId) {
  return Movement(
    id: 'bal_${accountId}_$i',
    title: 'Mov $i su $accountId',
    amount: 100.0,
    type: MovementType.income,
    date: DateTime(2026, 6, (i % 28) + 1),
    categoryId: 'inc_1',
    accountId: accountId,
    createdAt: DateTime(2026, 6, (i % 28) + 1),
  );
}

/// Helper: pump full app for widget tests
Future<AppDatabase> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final db = AppDatabase();
  await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
  return db;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ──────────────────────────────────────────────
  // 1000 MOVIMENTI — IN-MEMORY
  // ──────────────────────────────────────────────
  group('1000 movimenti (in-memory) — crash, duplicati, perdita dati', () {
    test('Crea 1000 movimenti senza crash ne duplicati', () {
      final db = AppDatabase();
      for (int i = 0; i < 1000; i++) {
        db.addMovement(_makeMovement(i));
      }

      expect(db.movements.length, 1000, reason: 'Perdita dati: mancano movimenti');

      // ids univoci
      final ids = db.movements.map((m) => m.id).toSet();
      expect(ids.length, 1000, reason: 'Duplicati: ids non univoci');

      expect(db.totalIncome, greaterThan(0));
      expect(db.totalExpenses, greaterThan(0));
    });

    test('Modifica 500 movimenti senza errori', () {
      final db = AppDatabase();
      for (int i = 0; i < 1000; i++) {
        db.addMovement(_makeMovement(i));
      }

      // ids prima
      final idsBefore = db.movements.map((m) => m.id).toSet();

      for (int i = 0; i < 500; i++) {
        final m = db.movements[i];
        db.updateMovement(m.copyWith(
          title: 'Modificato $i',
          amount: (i + 1) * 2.0,
          note: 'Nota modifica $i',
        ));
      }

      expect(db.movements.length, 1000, reason: 'Perdita dati dopo modifiche');
      expect(db.movements.where((m) => m.title.startsWith('Modificato')).length,
          500, reason: 'Modifiche non applicate');

      // ids invariati
      final idsAfter = db.movements.map((m) => m.id).toSet();
      expect(idsAfter, idsBefore, reason: 'Duplicati: ids cambiati dopo modifica');

      expect(() => db.updateMovement(Movement(
        id: 'inesistente',
        title: 'Fake',
        amount: 1,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'exp_1',
        createdAt: DateTime.now(),
      )), returnsNormally, reason: 'Assertion/crash su update ID inesistente');
    });

    test('Cancella 500 movimenti senza errori', () {
      final db = AppDatabase();
      for (int i = 0; i < 1000; i++) {
        db.addMovement(_makeMovement(i));
      }

      for (int i = 0; i < 500; i++) {
        db.deleteMovement('stress_m_$i');
      }

      expect(db.movements.length, 500, reason: 'Perdita/duplicati: lunghezza errata dopo delete');
      expect(db.movements.every((m) => int.parse(m.id.split('_').last) >= 500),
          isTrue, reason: 'Cancellati ID errati');

      // verify no crash on delete di ID già rimosso
      expect(() => db.deleteMovement('stress_m_0'),
          returnsNormally, reason: 'Crash su delete ID già rimosso');
    });

    test('Verifica calcoli finali dopo stress', () {
      final db = AppDatabase();
      for (int i = 0; i < 1000; i++) {
        db.addMovement(_makeMovement(i));
      }
      for (int i = 0; i < 500; i++) {
        db.updateMovement(db.movements[i].copyWith(
          amount: (i % 100) + 0.50,
          title: 'Movimento ${db.movements[i].id}',
        ));
      }
      for (int i = 0; i < 500; i++) {
        db.deleteMovement('stress_m_$i');
      }

      // solo i movimenti 500-999 sopravvivono
      expect(db.movements.length, 500);

      double expectedIncome = 0;
      double expectedExpenses = 0;
      for (int i = 500; i < 1000; i++) {
        final amt = (i % 100) + 0.50;
        if (i.isEven) {
          expectedIncome += amt;
        } else {
          expectedExpenses += amt;
        }
      }

      expect(db.totalIncome, expectedIncome);
      expect(db.totalExpenses, expectedExpenses);
      expect(db.balance, expectedIncome - expectedExpenses);
    });
  });

  // ──────────────────────────────────────────────
  // 1000 MOVIMENTI — SQLITE
  // ──────────────────────────────────────────────
  group('1000 movimenti (SQLite) — crash, duplicati, persistenza', () {
    test('Crea 1000 movimenti con persistenza senza crash', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      for (int i = 0; i < 1000; i++) {
        await db.addMovement(_makeMovement(i));
      }

      expect(db.movements.length, 1000);

      // reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 1000,
          reason: 'Perdita dati dopo reload SQLite');
      expect(db2.movements.map((m) => m.id).toSet().length, 1000,
          reason: 'Duplicati dopo reload SQLite');

      await sqlite.close();
    });

    test('Modifica 500 movimenti persistente', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      for (int i = 0; i < 1000; i++) {
        await db.addMovement(_makeMovement(i));
      }

      for (int i = 0; i < 500; i++) {
        await db.updateMovement(db.movements[i].copyWith(
          title: 'SQLite Mod $i',
          amount: (i + 1) * 3.0,
        ));
      }

      // reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 1000);
      expect(
          db2.movements.where((m) => m.title.startsWith('SQLite Mod')).length,
          500, reason: 'Modifiche non persistite');

      await sqlite.close();
    });

    test('Cancella 500 movimenti persistente', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      for (int i = 0; i < 1000; i++) {
        await db.addMovement(_makeMovement(i));
      }

      for (int i = 0; i < 500; i++) {
        await db.deleteMovement('stress_m_$i');
      }

      // reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 500,
          reason: 'Perdita/duplicati dopo delete persistente');
      expect(db2.movements.every((m) => int.parse(m.id.split('_').last) >= 500),
          isTrue, reason: 'Cancellati ID errati (persistente)');

      await sqlite.close();
    });

    test('Verifica integrità finale dopo ciclo completo SQLite', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      for (int i = 0; i < 1000; i++) {
        await db.addMovement(_makeMovement(i));
      }
      for (int i = 0; i < 500; i++) {
        await db.updateMovement(db.movements[i].copyWith(
          amount: (i % 100) + 0.50,
          title: 'Movimento ${db.movements[i].id}',
        ));
      }
      for (int i = 0; i < 500; i++) {
        await db.deleteMovement('stress_m_$i');
      }

      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.movements.length, 500);

      double expectedIncome = 0;
      double expectedExpenses = 0;
      for (int i = 500; i < 1000; i++) {
        final amt = (i % 100) + 0.50;
        if (i.isEven) {
          expectedIncome += amt;
        } else {
          expectedExpenses += amt;
        }
      }

      expect(db2.totalIncome, expectedIncome);
      expect(db2.totalExpenses, expectedExpenses);
      expect(db2.balance, expectedIncome - expectedExpenses);

      await sqlite.close();
    });
  });

  // ──────────────────────────────────────────────
  // DECINE DI CONTI + ARCHIVIAZIONE
  // ──────────────────────────────────────────────
  group('Decine di conti — archivia/riattiva, saldi, perdita dati', () {
    test('Crea 30 conti senza crash o duplicati', () {
      final db = AppDatabase();
      expect(db.accounts.length, 1); // default account

      for (int i = 0; i < 30; i++) {
        db.addAccount(Account(
          id: 'conto_$i',
          name: 'Conto $i',
          type: [AccountType.cash, AccountType.bank, AccountType.card,
                  AccountType.savings, AccountType.other][i % 5],
          createdAt: DateTime.now().subtract(Duration(days: i)),
        ));
      }

      expect(db.accounts.length, 31,
          reason: 'Perdita dati: mancano conti');
      final ids = db.accounts.map((a) => a.id).toSet();
      expect(ids.length, 31,
          reason: 'Duplicati: ids conto non univoci');
    });

    test('Archivia conti — restoreAccount non disponibile (mancante API)', () {
      // NOTA: restoreAccount NON esiste in AppDatabase.
      // Solo archiveAccount() è implementata.
      // Per riattivare servirebbe un restoreAccount() che set archived:false
      // oppure updateAccount() dovrebbe supportare il flag archived.
      final db = AppDatabase();
      for (int i = 0; i < 30; i++) {
        db.addAccount(Account(
          id: 'conto_$i',
          name: 'Conto $i',
          type: AccountType.bank,
          createdAt: DateTime.now().subtract(Duration(days: i)),
        ));
      }

      // archivia 15 conti
      for (int i = 0; i < 15; i++) {
        db.archiveAccount('conto_$i');
      }

      expect(db.accounts.where((a) => a.archived).length, 15,
          reason: 'Archiviazione non applicata');
      expect(db.accounts.where((a) => !a.archived).length, 16, // 15 + default
          reason: 'Perdita conti non archiviati');

      // verifica crash su archive ID inesistente
      expect(() => db.archiveAccount('conto_999'),
          returnsNormally, reason: 'Crash su archive ID inesistente');
    });

    test('Verifica totalAccountsBalance dopo archiviazione', () {
      final db = AppDatabase();

      // conto default + 5 nuovi
      for (int i = 0; i < 5; i++) {
        db.addAccount(Account(
          id: 'conto_$i',
          name: 'Conto $i',
          type: AccountType.bank,
          initialBalance: 1000.0 * (i + 1),
          createdAt: DateTime.now(),
        ));
      }

      // aggiungi movimenti a ciascun conto
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 10; j++) {
          db.addMovement(_makeAccountMovement(j, 'conto_$i'));
        }
      }

      final beforeArchive = db.totalAccountsBalance;
      expect(beforeArchive, greaterThan(0),
          reason: 'totalAccountsBalance dovrebbe essere positivo');

      // archivia conto_0
      db.archiveAccount('conto_0');
      final afterArchive = db.totalAccountsBalance;

      // conto_0 (1000 initial + 10*100) = 2000 non dovrebbe più contribuire
      expect(afterArchive, lessThan(beforeArchive),
          reason: 'Archiviazione non rimossa da totalAccountsBalance');

      // verifica crash su archive ID inesistente
      expect(() => db.archiveAccount('conto_999'),
          returnsNormally, reason: 'Crash su archive ID inesistente');
    });

    test('Crea 30 conti con SQLite senza crash', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      // oltre al default, aggiungi 30 conti
      for (int i = 0; i < 30; i++) {
        await db.addAccount(Account(
          id: 'p_conto_$i',
          name: 'Persistente $i',
          type: AccountType.bank,
          initialBalance: 500.0,
          createdAt: DateTime.now().subtract(Duration(days: i)),
        ));
      }

      expect(db.accounts.length, 31);

      // reload
      final db2 = AppDatabase(sqlite: sqlite);
      await db2.initialize();
      expect(db2.accounts.length, 31,
          reason: 'Perdita conti dopo reload SQLite');
      expect(db2.accounts.map((a) => a.id).toSet().length, 31,
          reason: 'Duplicati conti dopo reload SQLite');

      await sqlite.close();
    });
  });

  // ──────────────────────────────────────────────
  // NAVIGAZIONE RAPIDA — WIDGET TEST
  // ──────────────────────────────────────────────
  group('Navigazione rapida — freeze/crash apertura/chiusura schermate', () {
    testWidgets('Switch rapido tra sezioni Archivio senza freeze', (tester) async {
      final db = await _pumpApp(tester);
      for (int i = 0; i < 20; i++) {
        db.addMovement(_makeMovement(i));
      }

      // Vai su Archivio
      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // switch rapido tra le 4 sezioni interne
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Conti'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Categorie'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Calendario'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Movimenti'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      expect(db.movements.length, 20,
          reason: 'Movimenti persi dopo navigazione rapida');
    });

    testWidgets('Switch rapido bottom nav senza freeze', (tester) async {
      final db = await _pumpApp(tester);
      for (int i = 0; i < 10; i++) {
        db.addMovement(_makeMovement(i));
      }

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Archivio'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Impostazioni'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      expect(db.movements.length, 10,
          reason: 'Movimenti persi dopo switch bottom nav');
    });

    testWidgets('Apri e chiudi form movimento rapido senza crash', (tester) async {
      final db = await _pumpApp(tester);
      for (int i = 0; i < 5; i++) {
        db.addMovement(_makeMovement(i));
      }

      // Vai su Archivio → Movimenti
      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      // Apri form movimento, chiudi senza salvare, ripeti
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // chiudi con back (close button nel form)
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      expect(db.movements.length, 5,
          reason: 'Movimenti creati involontariamente durante apertura/chiusura form');
    });

    testWidgets('Navigazione combinata: bottom nav + sezioni + form', (tester) async {
      final db = await _pumpApp(tester);
      for (int i = 0; i < 5; i++) {
        db.addMovement(_makeMovement(i));
      }

      // Archivio → Categorie
      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categorie'));
      await tester.pumpAndSettle();

      // Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Archivio → Conti
      await tester.tap(find.text('Archivio'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Conti'));
      await tester.pumpAndSettle();

      // Archivio → Calendario
      await tester.tap(find.text('Calendario'));
      await tester.pumpAndSettle();

      // Torna a Movimenti
      await tester.tap(find.text('Movimenti'));
      await tester.pumpAndSettle();

      // Apri form e chiudi
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(db.movements.length, 5,
          reason: 'Movimenti creati involontariamente');
      expect(db.categories.length, greaterThanOrEqualTo(7),
          reason: 'Categorie perse');
    });
  });
}
