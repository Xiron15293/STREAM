import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' show join;
import 'dart:io';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart' show MovementType;
import 'package:stream_app/design/stream_icon_library.dart';

String _tempDbPath(String name) {
  final dir = Directory.systemTemp.createTempSync('stream_test_acc_');
  return join(dir.path, name);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ── Test di immediatezza in-memory (nessun SQLite) ──
  group('Account icon/color refresh — in-memory (no SQLite)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(sqlite: null);
    });

    test('1. modifica icona conto → lista conti aggiornata subito', () {
      final a = db.accounts.first;
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'bank');
      final updated = db.accounts.firstWhere((x) => x.id == a.id);
      expect(updated.iconKey, 'bank');
    });

    test('2. modifica colore conto → lista conti aggiornata subito', () {
      final a = db.accounts.first;
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, color: 0xFF42A5F5);
      final updated = db.accounts.firstWhere((x) => x.id == a.id);
      expect(updated.color, 0xFF42A5F5);
    });

    test('3. modifica nome conto → lista conti aggiornata subito', () {
      final a = db.accounts.first;
      db.updateAccount(a.id, 'Nuovo Nome', a.type, a.initialBalance);
      final updated = db.accounts.firstWhere((x) => x.id == a.id);
      expect(updated.name, 'Nuovo Nome');
    });

    test('4. movimento collegato mantiene accountId dopo modifica conto', () {
      final a = db.accounts.first;
      db.addMovement(Movement(
        id: 'm_acc_1', title: 'Test', amount: 10.0,
        type: MovementType.expense, date: DateTime(2026, 6, 1),
        categoryId: 'exp_1', accountId: a.id,
        createdAt: DateTime(2026, 6, 1),
      ));
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'bank', color: 0xFFFF7043);
      final m = db.movements.firstWhere((x) => x.id == 'm_acc_1');
      expect(m.accountId, a.id);
    });

    test('5. saldo conto invariato dopo modifica icona/colore', () {
      final a = db.accounts.first;
      final before = db.getAccountBalance(a);
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'bank', color: 0xFFFF7043);
      expect(db.getAccountBalance(a), before);
    });

    test('6. saldo totale dashboard invariato dopo modifica icona/colore', () {
      final before = db.totalAccountsBalance;
      final a = db.accounts.first;
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'bank', color: 0xFFFF7043);
      expect(db.totalAccountsBalance, before);
    });

    test('7. nessuna duplicazione conto dopo modifica icona/colore', () {
      final count = db.accounts.length;
      final a = db.accounts.first;
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'bank', color: 0xFF42A5F5);
      expect(db.accounts.length, count);
    });

    test('8. fallback icon se account iconKey non riconosciuta', () {
      final icon = StreamIconLibrary.getAccountIcon('nonexistent_key');
      expect(icon, StreamIconLibrary.fallbackIcon);
    });

    test('9. conto custom con iconKey custom appare correttamente', () {
      db.addAccount(Account(
        id: 'custom_test_id',
        name: 'Custom Test',
        type: AccountType.cash,
        iconKey: 'hand-coins',
        color: 0xFFAB47BC,
        createdAt: DateTime.now(),
      ));
      final c = db.accounts.firstWhere((a) => a.id == 'custom_test_id');
      expect(c.name, 'Custom Test');
      expect(c.iconKey, 'hand-coins');
      expect(c.color, 0xFFAB47BC);
      expect(c.type, AccountType.cash);
    });

    test('10. archiveAccount preserva iconKey e color', () {
      final a = db.accounts.first;
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'safe', color: 0xFF26A69A);
      db.archiveAccount(a.id);
      final archived = db.accounts.firstWhere((x) => x.id == a.id);
      expect(archived.archived, true);
      expect(archived.iconKey, 'safe');
      expect(archived.color, 0xFF26A69A);
    });

    test('11. nuovo conto usa il colore selezionato', () {
      db.addAccount(Account(
        id: 'new_color_test',
        name: 'Color Test',
        type: AccountType.bank,
        iconKey: 'wallet',
        color: 0xFFEC407A,
        createdAt: DateTime.now(),
      ));
      final c = db.accounts.firstWhere((a) => a.id == 'new_color_test');
      expect(c.color, 0xFFEC407A);
    });

    test('12. updateAccount senza color/iconKey mantiene valori esistenti', () {
      final a = db.accounts.first;
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'vault', color: 0xFF7E57C2);
      db.updateAccount(a.id, 'Solo Nome', a.type, a.initialBalance);
      final updated = db.accounts.firstWhere((x) => x.id == a.id);
      expect(updated.name, 'Solo Nome');
      expect(updated.iconKey, 'vault');
      expect(updated.color, 0xFF7E57C2);
    });

    test('13. modifica solo colore lascia nome/tipo/saldo/icona invariati', () {
      final a = db.accounts.first;
      final originalName = a.name;
      final originalType = a.type;
      final originalBalance = a.initialBalance;
      final originalIcon = a.iconKey;

      db.updateAccount(a.id, a.name, a.type, a.initialBalance, color: 0xFF5C6BC0);
      final updated = db.accounts.firstWhere((x) => x.id == a.id);

      expect(updated.color, 0xFF5C6BC0);
      expect(updated.name, originalName);
      expect(updated.type, originalType);
      expect(updated.initialBalance, originalBalance);
      expect(updated.iconKey, originalIcon);

      db.addMovement(Movement(
        id: 'm_single_color', title: 'Test', amount: 25.0,
        type: MovementType.expense, date: DateTime(2026, 6, 1),
        categoryId: 'exp_1', accountId: a.id,
        createdAt: DateTime(2026, 6, 1),
      ));
      expect(db.getAccountBalance(a), -25.0);
    });

    test('14. modifica solo icona lascia colore invariato', () {
      final a = db.accounts.first;
      final originalColor = a.color;
      db.updateAccount(a.id, a.name, a.type, a.initialBalance, iconKey: 'coins');
      final updated = db.accounts.firstWhere((x) => x.id == a.id);
      expect(updated.iconKey, 'coins');
      expect(updated.color, originalColor);
      expect(db.getAccountBalance(a), 0.0);
    });
  });

  // ── Test di persistenza SQLite ──
  group('Account icon/color persistenza SQLite', () {
    test('modifica icona/colore conto → reload SQLite mantiene dati', () async {
      final dbPath = _tempDbPath('acc_persist.db');
      var sqlite = SQLiteService();
      await sqlite.open(path: dbPath);
      var db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      final a = db.accounts.first;
      final updated = Account(
        id: a.id,
        name: 'Reload Test',
        type: AccountType.savings,
        initialBalance: 500.0,
        iconKey: 'piggy-bank',
        color: 0xFF66BB6A,
        archived: a.archived,
        createdAt: a.createdAt,
        updatedAt: DateTime.now(),
      );
      // Usa SQLiteService direttamente (awaitable)
      await sqlite.updateAccount(a.id, updated);
      await sqlite.close();

      var sqlite2 = SQLiteService();
      await sqlite2.open(path: dbPath);
      var db2 = AppDatabase(sqlite: sqlite2);
      await db2.initialize();

      final reloaded = db2.accounts.firstWhere((x) => x.id == a.id);
      expect(reloaded.name, 'Reload Test');
      expect(reloaded.iconKey, 'piggy-bank');
      expect(reloaded.color, 0xFF66BB6A);
      expect(reloaded.type, AccountType.savings);
      expect(reloaded.initialBalance, 500.0);

      await sqlite2.close();
    });
  });
}
