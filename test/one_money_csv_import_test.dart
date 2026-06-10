import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/services/one_money_csv_import_service.dart';

const String _realOneMoneyCsvPath =
    '/tmp/codex-remote-attachments/019ea8a9-a716-7c40-98a6-23b5efd642da/2DACBC81-D89B-4651-943C-5AD1BD5957A6/2-1Money_09_06_26.csv';

Future<({AppDatabase db, SQLiteService sqlite})> _createDb() async {
  final tempDir = await Directory.systemTemp.createTemp('one_money_csv_import_');
  final dbPath = p.join(tempDir.path, 'stream_test.db');
  final sqlite = SQLiteService();
  await sqlite.open(path: dbPath);
  final db = AppDatabase(sqlite: sqlite);
  await db.initialize();
  addTearDown(() async {
    await sqlite.close();
    await tempDir.delete(recursive: true);
  });
  return (db: db, sqlite: sqlite);
}

String _csv(List<List<String>> rows) {
  final buffer = StringBuffer();
  buffer.writeln(
    'DATA;TIPOLOGIA;DAL CONTO;AL CONTO / ALLA CATEGORIA;IMPORTO;VALUTA;IMPORTO 2;VALUTA 2;TAG;NOTE',
  );
  for (final row in rows) {
    buffer.writeln(row.join(';'));
  }
  return buffer.toString();
}

List<String> _row({
  required String date,
  required String type,
  required String sourceAccount,
  required String target,
  required String amount,
  String note = '',
}) {
  return [
    date,
    type,
    sourceAccount,
    target,
    amount,
    'EUR',
    '',
    '',
    '',
    note,
  ];
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('importa spesa, crea conto e categoria, importa nota e data', () async {
    final fixture = await _createDb();
    final db = fixture.db;

    final csv = _csv([
      _row(
        date: '30/05/26',
        type: 'Spesa',
        sourceAccount: 'Conto Corrente',
        target: 'Supermercato',
        amount: '12,50',
        note: 'Cena al market',
      ),
    ]);

    final report = await OneMoneyCsvImportService.importCsv(db, csv);

    expect(report.movementsRead, 1);
    expect(report.importedMovements, 1);
    expect(report.duplicateMovements, 0);
    expect(report.accountsCreated, 1);
    expect(report.categoriesCreated, 1);
    expect(report.errorCount, 0);

    expect(db.movements, hasLength(1));
    final movement = db.movements.single;
    expect(movement.type, MovementType.expense);
    expect(movement.amount, closeTo(12.5, 0.0001));
    expect(movement.date, DateTime(2026, 5, 30));
    expect(movement.note, 'Cena al market');
    expect(movement.title, 'Cena al market');

    expect(db.accounts.any((a) => a.name == 'Conto Corrente'), isTrue);
    expect(db.categories.any((c) => c.name == 'Supermercato' && c.type == MovementType.expense), isTrue);
    expect(db.accounts.every((a) => a.initialBalance == 0.0), isTrue);

  });

  test('importa entrata e usa la categoria come titolo quando la nota e vuota', () async {
    final fixture = await _createDb();
    final db = fixture.db;

    final csv = _csv([
      _row(
        date: '01/06/26',
        type: 'Entrata',
        sourceAccount: 'Conto Stipendio',
        target: 'Stipendio',
        amount: '2500.50',
      ),
    ]);

    final report = await OneMoneyCsvImportService.importCsv(db, csv);

    expect(report.movementsRead, 1);
    expect(report.importedMovements, 1);
    expect(report.accountsCreated, 1);
    expect(report.categoriesCreated, 0);
    expect(report.errorCount, 0);

    final movement = db.movements.single;
    expect(movement.type, MovementType.income);
    expect(movement.amount, closeTo(2500.5, 0.0001));
    expect(movement.date, DateTime(2026, 6, 1));
    expect(movement.note, isEmpty);
    expect(movement.title, 'Stipendio');

  });

  test('importa trasferimento e crea automaticamente il conto destinazione', () async {
    final fixture = await _createDb();
    final db = fixture.db;

    final csv = _csv([
      _row(
        date: '02/06/26',
        type: 'Trasferimento',
        sourceAccount: 'Conto A',
        target: 'Conto B',
        amount: '100.00',
        note: 'Ricarica',
      ),
    ]);

    final report = await OneMoneyCsvImportService.importCsv(db, csv);

    expect(report.movementsRead, 1);
    expect(report.importedMovements, 1);
    expect(report.accountsCreated, 2);
    expect(report.categoriesCreated, 0);
    expect(report.errorCount, 0);

    final movement = db.movements.where((m) => m.type == MovementType.transfer).single;
    expect(movement.type, MovementType.transfer);
    expect(movement.amount, closeTo(100.0, 0.0001));
    expect(movement.date, DateTime(2026, 6, 2));
    expect(movement.note, 'Ricarica');
    expect(movement.title, 'Ricarica');
    expect(movement.categoryId, isEmpty);
    expect(movement.destinationAccountId, isNotNull);
    expect(db.accounts.firstWhere((a) => a.id == movement.accountId).name, 'Conto A');
    expect(db.accounts.firstWhere((a) => a.id == movement.destinationAccountId).name, 'Conto B');
    expect(db.accounts.any((a) => a.name == 'Conto A'), isTrue);
    expect(db.accounts.any((a) => a.name == 'Conto B'), isTrue);
    expect(db.accounts.every((a) => a.initialBalance == 0.0), isTrue);
  });

  test('ignora la sezione finale conti e fondi dopo il blocco movimenti', () async {
    final fixture = await _createDb();
    final db = fixture.db;

    final csv = '${_csv([
      _row(
        date: '30/05/26',
        type: 'Spesa',
        sourceAccount: 'Conto Corrente',
        target: 'Supermercato',
        amount: '12,50',
        note: 'Cena al market',
      ),
      _row(
        date: '01/06/26',
        type: 'Entrata',
        sourceAccount: 'Conto Stipendio',
        target: 'Stipendio',
        amount: '2500.50',
      ),
    ])}NOME;;;;;;;\nRevolut;;;;;;;\nContanti;;;;;;;\nBuffer;;;;;;;\n';

    final report = await OneMoneyCsvImportService.importCsv(db, csv);

    expect(report.movementsRead, 2);
    expect(report.importedMovements, 2);
    expect(report.errorCount, 0);
    expect(report.errors, isEmpty);
    expect(db.movements, hasLength(2));
    expect(db.accounts.any((a) => a.name == 'Revolut'), isFalse);
    expect(db.accounts.any((a) => a.name == 'Contanti'), isFalse);
    expect(db.accounts.any((a) => a.name == 'Buffer'), isFalse);
    expect(db.categories.any((c) => c.name == 'Revolut'), isFalse);
    expect(db.categories.any((c) => c.name == 'Contanti'), isFalse);
    expect(db.categories.any((c) => c.name == 'Buffer'), isFalse);
    expect(db.accounts.every((a) => a.initialBalance == 0.0), isTrue);
  });

  test('ignora duplicati presenti nello stesso file', () async {
    final fixture = await _createDb();
    final db = fixture.db;

    final csv = _csv([
      _row(
        date: '03/06/26',
        type: 'Spesa',
        sourceAccount: 'Conto Diario',
        target: 'Casa',
        amount: '18,90',
        note: 'Pane e latte',
      ),
      _row(
        date: '03/06/26',
        type: 'Spesa',
        sourceAccount: 'Conto Diario',
        target: 'Casa',
        amount: '18,90',
        note: 'Pane e latte',
      ),
    ]);

    final report = await OneMoneyCsvImportService.importCsv(db, csv);

    expect(report.movementsRead, 2);
    expect(report.importedMovements, 1);
    expect(report.duplicateMovements, 1);
    expect(report.duplicateDbMovements, 0);
    expect(report.duplicateWithinFileMovements, 1);
    expect(report.duplicateWithinFileImportedMovements, 0);
    expect(db.movements, hasLength(1));
  });

  test('importa duplicati interni quando dedupeWithinFile e false e li protegge al reimport', () async {
    final fixture = await _createDb();
    final db = fixture.db;

    final csv = _csv([
      _row(
        date: '03/06/26',
        type: 'Spesa',
        sourceAccount: 'Conto Diario',
        target: 'Casa',
        amount: '18,90',
        note: 'Pane e latte',
      ),
      _row(
        date: '03/06/26',
        type: 'Spesa',
        sourceAccount: 'Conto Diario',
        target: 'Casa',
        amount: '18,90',
        note: 'Pane e latte',
      ),
    ]);

    final firstReport = await OneMoneyCsvImportService.importCsv(
      db,
      csv,
      dedupeWithinFile: false,
    );

    expect(firstReport.movementsRead, 2);
    expect(firstReport.importedMovements, 2);
    expect(firstReport.duplicateMovements, 0);
    expect(firstReport.duplicateDbMovements, 0);
    expect(firstReport.duplicateWithinFileMovements, 1);
    expect(firstReport.duplicateWithinFileImportedMovements, 1);
    expect(db.movements, hasLength(2));

    final secondReport = await OneMoneyCsvImportService.importCsv(
      db,
      csv,
      dedupeWithinFile: false,
    );

    expect(secondReport.movementsRead, 2);
    expect(secondReport.importedMovements, 0);
    expect(secondReport.duplicateMovements, 2);
    expect(secondReport.duplicateDbMovements, 2);
    expect(secondReport.duplicateWithinFileMovements, 0);
    expect(secondReport.duplicateWithinFileImportedMovements, 0);
    expect(db.movements, hasLength(2));
  });

  test('importa 1000 movimenti e reimportare lo stesso file non duplica', () async {
    final fixture = await _createDb();
    final db = fixture.db;

    final rows = List.generate(1000, (index) {
      final day = (index % 28) + 1;
      return _row(
        date: '${day.toString().padLeft(2, '0')}/06/26',
        type: index.isEven ? 'Spesa' : 'Entrata',
        sourceAccount: index.isEven ? 'Conto Casa' : 'Conto Lavoro',
        target: index.isEven ? 'Spesa Variabile' : 'Stipendio',
        amount: '10.00',
        note: 'Nota $index',
      );
    });
    final csv = _csv(rows);

    final firstReport = await OneMoneyCsvImportService.importCsv(db, csv);
    expect(firstReport.movementsRead, 1000);
    expect(firstReport.importedMovements, 1000);
    expect(firstReport.duplicateMovements, 0);
    expect(db.movements, hasLength(1000));

    final secondReport = await OneMoneyCsvImportService.importCsv(db, csv);
    expect(secondReport.movementsRead, 1000);
    expect(secondReport.importedMovements, 0);
    expect(secondReport.duplicateMovements, 1000);
    expect(db.movements, hasLength(1000));
  });

  test(
    'importa il CSV reale 1Money con dedupeWithinFile false e conserva i duplicati interni',
    () async {
      final fixture = await _createDb();
      final db = fixture.db;

      final csv = await File(_realOneMoneyCsvPath).readAsString();
      final report = await OneMoneyCsvImportService.importCsv(
        db,
        csv,
        dedupeWithinFile: false,
      );

      expect(report.movementsRead, 6417);
      expect(report.importedMovements, 6417);
      expect(report.duplicateMovements, 0);
      expect(report.duplicateDbMovements, 0);
      expect(report.duplicateWithinFileMovements, 49);
      expect(report.duplicateWithinFileImportedMovements, 49);
      expect(db.movements, hasLength(6417));
      expect(db.accounts.every((a) => a.initialBalance == 0.0), isTrue);

      final secondReport = await OneMoneyCsvImportService.importCsv(
        db,
        csv,
        dedupeWithinFile: false,
      );

      expect(secondReport.movementsRead, 6417);
      expect(secondReport.importedMovements, 0);
      expect(secondReport.duplicateMovements, 6417);
      expect(secondReport.duplicateDbMovements, 6417);
      expect(secondReport.duplicateWithinFileMovements, 0);
      expect(secondReport.duplicateWithinFileImportedMovements, 0);
      expect(db.movements, hasLength(6417));
    },
    skip: !File(_realOneMoneyCsvPath).existsSync(),
  );
}
