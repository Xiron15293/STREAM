import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/beneficiary_profile.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/services/ifinance_csv_import_service.dart';

Future<({AppDatabase db, SQLiteService sqlite})> _createDb() async {
  final tempDir = await Directory.systemTemp.createTemp('ifinance_csv_import_');
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

String _csv({
  String? header,
  List<String>? metadataLines,
  required List<String> dataRows,
}) {
  final buffer = StringBuffer();
  if (metadataLines != null) {
    for (final line in metadataLines) {
      buffer.writeln(line);
    }
  }
  buffer.writeln(header ?? 'Data;Importo;Causale;Beneficiario/Contribuente;IBAN;Bic/Swift bancario;Categoria;Commento;Etichette;Conto');
  for (final row in dataRows) {
    buffer.writeln(row);
  }
  return buffer.toString();
}

String _row({
  required String date,
  required String amount,
  String title = '',
  String payee = '',
  String iban = '',
  String bic = '',
  String category = '',
  String comment = '',
  String labels = '',
  String account = 'Conto Corrente',
}) {
  return '$date;$amount;$title;$payee;$iban;$bic;$category;$comment;$labels;$account';
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Parser', () {
    test('salta metadati iniziali e trova header', () async {
      final fixture = await _createDb();
      final csv = _csv(
        metadataLines: [
          'Esportazione iFinance',
          'Periodo: 01/01/22 - 31/12/26',
          '',
        ],
        dataRows: [
          _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Contante'),
        ],
      );
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.totalRows, 1);
      expect(preview.movements, hasLength(1));
      expect(preview.errors, isEmpty);
    });

    test('header non trovato produce errore', () async {
      final fixture = await _createDb();
      final csv = 'Nessun header qui\nriga 1\nriga 2';
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.errors, isNotEmpty);
      expect(preview.errors.first, contains('Intestazione'));
    });

    test('file vuoto produce errore', () async {
      final fixture = await _createDb();
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, '');
      expect(preview.errors, isNotEmpty);
    });

    test('parsa data dd/MM/yy', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Test'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements, hasLength(1));
      expect(preview.movements.first.date.year, 2026);
      expect(preview.movements.first.date.month, 6);
      expect(preview.movements.first.date.day, 15);
    });

    test('data non valida produce errore riga', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '99/99/99', amount: '-10,00', title: 'Test'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.errors, isNotEmpty);
    });

    test('importo con virgola decimale', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-15,50', title: 'Spesa'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements, hasLength(1));
      expect(preview.movements.first.rawAmount, -15.50);
      expect(preview.movements.first.amount, 15.50);
    });

    test('importo senza virgola', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-100', title: 'Spesa'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements.first.rawAmount, -100);
    });
  });

  group('Mapping', () {
    test('importo negativo -> expense', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-25,00', title: 'Spesa'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements, hasLength(1));
      expect(preview.movements.first.type, MovementType.expense);
      expect(preview.movements.first.amount, 25.00);
    });

    test('importo positivo -> income', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '1500,00', title: 'Stipendio'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements, hasLength(1));
      expect(preview.movements.first.type, MovementType.income);
      expect(preview.movements.first.amount, 1500.00);
    });

    test('payee importato', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-45,00', title: 'Cena', payee: 'Ristorante Rossi'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements.first.payee, 'Ristorante Rossi');
    });

    test('payee vuoto è null', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', payee: ''),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements.first.payee, isNull);
    });

    test('note include solo commento senza prefissi', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', comment: 'Spesa settimanale'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final note = preview.movements.first.note;
      expect(note, 'Spesa settimanale');
      expect(note, isNot(contains('Commento:')));
      expect(note, isNot(contains('Origine:')));
      expect(note, isNot(contains('iFinance')));
    });

    test('note include solo etichetta senza prefissi', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', labels: 'Fisso'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final note = preview.movements.first.note;
      expect(note, 'Fisso');
      expect(note, isNot(contains('Etichette importate:')));
      expect(note, isNot(contains('Origine:')));
      expect(note, isNot(contains('iFinance')));
    });

    test('note include commento + etichetta puliti', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '15/06/26', amount: '-10,00', title: 'Spesa',
          comment: 'Settimanale', labels: 'Fisso',
        ),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final note = preview.movements.first.note;
      expect(note, 'Settimanale\nFisso');
      expect(note, isNot(contains('Commento:')));
      expect(note, isNot(contains('Etichette importate:')));
      expect(note, isNot(contains('Origine:')));
      expect(note, isNot(contains('iFinance')));
    });

    test('note include etichette multiple tra virgolette', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', labels: '"Fisso;Supermercato"'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final note = preview.movements.first.note;
      expect(note, 'Fisso;Supermercato');
      expect(note, isNot(contains('Etichette importate:')));
    });

    test('commento == etichetta: note contiene una sola occorrenza', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '15/06/26', amount: '-10,00', title: 'Spesa',
          comment: 'Vacanza', labels: 'Vacanza',
        ),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final note = preview.movements.first.note;
      expect(note, 'Vacanza');
      expect(note.split('\n'), hasLength(1));
    });

    test('nessun commento / nessuna etichetta -> note vuota', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final note = preview.movements.first.note;
      expect(note, isEmpty);
    });

    test('solo etichetta "Vacanza" -> note == "Vacanza"', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', labels: 'Vacanza'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements.first.note, 'Vacanza');
    });
  });

  group('Categorie e sottocategorie', () {
    test('categoria semplice parsata', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'Spesa'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements.first.categoryParent, 'Spesa');
      expect(preview.movements.first.subcategoryName, '');
    });

    test('categoria con sottocategoria', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'Spesa:Alimentari'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements.first.categoryParent, 'Spesa');
      expect(preview.movements.first.subcategoryName, 'Alimentari');
    });

    test('categoria a 3 livelli: resto diventa sottocategoria', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Invisibili:Bar:Caffetteria'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements.first.categoryParent, 'Invisibili');
      expect(preview.movements.first.subcategoryName, 'Bar:Caffetteria');
    });

    test('auto-creazione categoria in preview', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'NuovaCategoria'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.categoriesToCreate, contains('NuovaCategoria'));
    });

    test('auto-creazione sottocategoria in preview', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'Nuova:NuovaSub'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.categoriesToCreate, contains('Nuova'));
      expect(preview.subcategoriesToCreate, hasLength(1));
      expect(preview.subcategoriesToCreate.first.category, 'Nuova');
      expect(preview.subcategoriesToCreate.first.subcategory, 'NuovaSub');
    });

    test('categoria esistente non viene ricreata', () async {
      final fixture = await _createDb();
      await fixture.db.addCategory('Esistente', MovementType.expense, 0xFFEF5350);
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'Esistente'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.categoriesToCreate, isEmpty);
    });

    test('sottocategoria esistente non viene ricreata', () async {
      final fixture = await _createDb();
      await fixture.db.addCategory('Cat', MovementType.expense, 0xFFEF5350);
      final cat = fixture.db.categories.firstWhere((c) => c.name == 'Cat');
      await fixture.db.createSubcategory(cat.id, 'SubEsistente');
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'Cat:SubEsistente'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.subcategoriesToCreate, isEmpty);
    });

    test('conto mancante produce errore riga', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', account: ''),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.errors, isNotEmpty);
    });
  });

  group('Transfer', () {
    test('pair semplice con direzione da/su', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '12/06/26',
          amount: '10,00',
          title: 'Trasferimento',
          payee: 'Trasferimento da Conto comunità',
          category: 'Trasferimenti',
          account: 'Contante',
        ),
        _row(
          date: '12/06/26',
          amount: '-10,00',
          title: 'Trasferimento',
          payee: 'Trasferimento su Contante',
          category: 'Trasferimenti',
          account: 'Conto comunità',
        ),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.transferCandidateRows, 2);
      expect(preview.transfers, hasLength(1));
      expect(preview.transfers.first.accountSource, 'Conto comunità');
      expect(preview.transfers.first.accountDestination, 'Contante');
      expect(preview.ambiguousTransfers, isEmpty);
      expect(preview.movements, isEmpty);
    });

    test('transfer accoppiato: stessa data, stesso importo, conti diversi, "Trasferimento"', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-500,00', title: 'Trasferimento', account: 'Conto A'),
        _row(date: '15/06/26', amount: '500,00', title: 'Trasferimento', account: 'Conto B'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.transfers, hasLength(1));
      expect(preview.transfers.first.amount, 500.00);
      expect(preview.transfers.first.accountSource, 'Conto A');
      expect(preview.transfers.first.accountDestination, 'Conto B');
      expect(preview.movements, isEmpty);
      expect(preview.ambiguousTransfers, isEmpty);
    });

    test('righe normali non bloccate da transfer accoppiato', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-5,00', title: 'Bar', category: 'Spesa', account: 'Contante'),
        _row(date: '15/06/26', amount: '-12,00', title: 'Spesa', category: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '1000,00', title: 'Stipendio', category: 'Stipendio', account: 'Conto A'),
        _row(
          date: '15/06/26',
          amount: '10,00',
          title: 'Trasferimento',
          payee: 'Trasferimento da Conto A',
          category: 'Trasferimenti',
          account: 'Contante',
        ),
        _row(
          date: '15/06/26',
          amount: '-10,00',
          title: 'Trasferimento',
          payee: 'Trasferimento su Contante',
          category: 'Trasferimenti',
          account: 'Conto A',
        ),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.movements, hasLength(3));
      expect(preview.transfers, hasLength(1));
      expect(preview.ambiguousTransfers, isEmpty);
      expect(preview.totalToImport, 4);
    });

    test('multi-match risolvibile da da/su', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '18/02/24',
          amount: '25,00',
          title: 'Risparmio',
          payee: 'Trasferimento da Soldi mamma e papà',
          category: 'Trasferimenti',
          account: 'Conto comunità',
        ),
        _row(
          date: '18/02/24',
          amount: '25,00',
          title: 'Trasferimento',
          payee: 'Trasferimento da Soldi mamma e papà',
          category: 'Trasferimenti',
          account: 'Soldi casa',
        ),
        _row(
          date: '18/02/24',
          amount: '-25,00',
          title: 'Trasferimento',
          payee: 'Trasferimento su Soldi casa',
          category: 'Trasferimenti',
          account: 'Soldi mamma e papà',
        ),
        _row(
          date: '18/02/24',
          amount: '-25,00',
          title: 'Risparmio',
          payee: 'Trasferimento su Conto comunità',
          category: 'Trasferimenti',
          account: 'Soldi mamma e papà',
        ),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.transfers, hasLength(2));
      expect(preview.ambiguousTransfers, isEmpty);
      expect(
        preview.transfers.any((t) =>
            t.accountSource == 'Soldi mamma e papà' &&
            t.accountDestination == 'Conto comunità'),
        isTrue,
      );
      expect(
        preview.transfers.any((t) =>
            t.accountSource == 'Soldi mamma e papà' &&
            t.accountDestination == 'Soldi casa'),
        isTrue,
      );
    });

    test('multi-match realmente ambiguo resta ambiguo solo per quel gruppo', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '18/02/24', amount: '25,00', title: 'Trasferimento', category: 'Trasferimenti', account: 'Conto A'),
        _row(date: '18/02/24', amount: '25,00', title: 'Trasferimento', category: 'Trasferimenti', account: 'Conto B'),
        _row(date: '18/02/24', amount: '-25,00', title: 'Trasferimento', category: 'Trasferimenti', account: 'Conto C'),
        _row(date: '18/02/24', amount: '-25,00', title: 'Trasferimento', category: 'Trasferimenti', account: 'Conto D'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.transfers, isEmpty);
      expect(preview.ambiguousTransferGroups, 1);
      expect(preview.ambiguousTransfers, hasLength(4));
    });

    test('settimanale con payee da/su viene accoppiato come transfer', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '08/06/26',
          amount: '15,00',
          title: 'Settimanale',
          payee: 'Trasferimento da Conto comunità',
          category: 'Settimanale',
          account: 'Contante',
        ),
        _row(
          date: '08/06/26',
          amount: '-15,00',
          title: 'Settimanale',
          payee: 'Trasferimento su Contante',
          category: 'Settimanale',
          account: 'Conto comunità',
        ),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.transfers, hasLength(1));
      expect(preview.ambiguousTransfers, isEmpty);
      expect(preview.movements, isEmpty);
    });

    test('transfer ambiguo: "Trasferimento" ma non accoppiabile', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-500,00', title: 'Trasferimento', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.ambiguousTransfers, hasLength(1));
      expect(preview.movements, isEmpty);
      expect(preview.transfers, isEmpty);
    });

    test('transfer non rilevato se conti uguali', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-500,00', title: 'Trasferimento', account: 'Conto A'),
        _row(date: '15/06/26', amount: '500,00', title: 'Trasferimento', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.transfers, isEmpty);
      expect(preview.ambiguousTransfers, hasLength(2));
    });

    test('transfer non rilevato se importi diversi', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-500,00', title: 'Trasferimento', account: 'Conto A'),
        _row(date: '15/06/26', amount: '600,00', title: 'Trasferimento', account: 'Conto B'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.transfers, isEmpty);
    });
  });

  group('Deduplica', () {
    test('stesso file: righe identiche importate entrambe', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.intraFileRepeats, 1);
      expect(preview.duplicatesSkipped, 0);
      expect(preview.movements, hasLength(2));
    });

    test('reimport stesso file dopo commit: duplicato DB ignorato', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
      ]);
      final preview1 = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final report1 = await IFinanceCsvImportService.commitImport(fixture.db, preview1);
      expect(report1.movementsImported, 1);

      final preview2 = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview2.duplicatesSkipped, 1);
      expect(preview2.movements, hasLength(0));
    });

    test('100 movimenti stessa categoria creano 1 sottocategoria in preview', () async {
      final fixture = await _createDb();
      final rows = List.generate(100, (i) => _row(
        date: '${((i % 28) + 1).toString().padLeft(2, '0')}/06/26',
        amount: '-${(i % 10) + 1},00',
        title: 'Movimento $i',
        category: 'NuovaCat:Alimentari',
        account: 'Conto A',
      ));
      final csv = _csv(dataRows: rows);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.subcategoriesToCreate, hasLength(1));
      expect(preview.categoriesToCreate, hasLength(1));
    });

    test('varianti spazi/case deduplicano categoria', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'A', category: 'NuovaCat:NuovaSub', account: 'Conto A'),
        _row(date: '16/06/26', amount: '-15,00', title: 'B', category: 'NuovaCat: NuovaSub', account: 'Conto A'),
        _row(date: '17/06/26', amount: '-20,00', title: 'C', category: ' nuovacat : nuovasub ', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.subcategoriesToCreate, hasLength(1));
      expect(preview.categoriesToCreate, hasLength(1));
    });

    test('commit non crea sottocategorie duplicate', () async {
      final fixture = await _createDb();
      final rows = List.generate(100, (i) => _row(
        date: '${((i % 28) + 1).toString().padLeft(2, '0')}/06/26',
        amount: '-${(i % 10) + 1},00',
        title: 'Movimento $i',
        category: 'NuovaCat:Alimentari',
        account: 'Conto A',
      ));
      final csv = _csv(dataRows: rows);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.subcategoriesCreated, 1);
      expect(report.categoriesCreated, 1);
    });

    test('deduplica categorie/sottocategorie separata dalla deduplica movimenti', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'NuovaCat:Alimentari', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'NuovaCat:Alimentari', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.intraFileRepeats, 1);
      expect(preview.duplicatesSkipped, 0);
      expect(preview.movements, hasLength(2));
      expect(preview.subcategoriesToCreate, hasLength(1));
      expect(preview.categoriesToCreate, hasLength(1));
    });

    test('stress 4000+ righe verifica sottocategorie uniche', () async {
      final fixture = await _createDb();
      final rows = <String>[];
      for (var i = 0; i < 4001; i++) {
        final catIdx = i % 15;
        rows.add(_row(
          date: '${((i % 28) + 1).toString().padLeft(2, '0')}/06/26',
          amount: '-${(i % 100) + 1},00',
          title: 'Movimento $i',
          category: 'Categoria$catIdx:SubCat$catIdx',
          account: 'Conto${i % 5}',
        ));
      }
      final csv = _csv(dataRows: rows);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.subcategoriesToCreate, hasLength(15));
      expect(preview.categoriesToCreate, hasLength(15));
    });

    test('duplicato non rilevato se cambia titolo', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-10,00', title: 'Cappuccino', category: 'Spesa', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.duplicatesSkipped, 0);
      expect(preview.movements, hasLength(2));
    });

    test('tre righe identiche generano intraFileRepeats 2', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-5,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-5,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-5,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.intraFileRepeats, 2);
      expect(preview.duplicatesSkipped, 0);
      expect(preview.movements, hasLength(3));
    });

    test('3 identici: primo import OK, reimport li salta tutti', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-5,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-5,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-5,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
      ]);

      // Primo import: tutti e 3 creati (intraFileRepeats = 2)
      final p1 = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(p1.movements, hasLength(3));
      expect(p1.duplicatesSkipped, 0);
      expect(p1.intraFileRepeats, 2);
      final r1 = await IFinanceCsvImportService.commitImport(fixture.db, p1);
      expect(r1.movementsImported, 3);

      // I 3 movimenti nel DB hanno fingerprint distinti (baseFp, baseFp#2, baseFp#3).
      // Al reimport, isDuplicate matcha ciascuno per esattezza o via backward‑compat.
      expect(fixture.db.movements.length, 3);

      // Reimport: tutti e 3 saltati
      final p2 = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(p2.duplicatesSkipped, 3, reason: 'Tutte e 3 le righe devono essere riconosciute come duplicati del DB');
      expect(p2.movements, hasLength(0));
      final r2 = await IFinanceCsvImportService.commitImport(fixture.db, p2);
      expect(r2.movementsImported, 0);
      expect(fixture.db.movements.length, 3);

      // Terzo import con stesso CSV → ancora 3 duplicati
      final p3 = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(p3.duplicatesSkipped, 3);
      expect(p3.movements, hasLength(0));
    });

    test('reimport stesso CSV con note pulite resta deduplicato', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'Spesa', comment: 'Settimanale', labels: 'Fisso', account: 'Conto A'),
      ]);
      final p1 = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(p1.movements, hasLength(1));
      expect(p1.duplicatesSkipped, 0);
      final r1 = await IFinanceCsvImportService.commitImport(fixture.db, p1);
      expect(r1.movementsImported, 1);

      // Verify note in DB
      final dbMovement = fixture.db.movements.first;
      expect(dbMovement.note, 'Settimanale\nFisso');
      expect(dbMovement.note, isNot(contains('Commento:')));
      expect(dbMovement.note, isNot(contains('Etichette importate:')));
      expect(dbMovement.note, isNot(contains('Origine:')));

      // Reimport stesso CSV → deduplicato
      final p2 = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(p2.duplicatesSkipped, 1);
      expect(p2.movements, hasLength(0));
    });
  });

  group('Conti', () {
    test('conti da metadati e movimenti', () async {
      final fixture = await _createDb();
      final csv = _csv(
        metadataLines: [
          'Esportazione iFinance',
          'Conti: Conto Corrente, Carta Risparmio, Conto Investimenti',
          '',
        ],
        dataRows: [
          _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Conto Corrente'),
          _row(date: '16/06/26', amount: '-20,00', title: 'Cena', category: 'Spesa', account: 'Conto Corrente'),
          _row(date: '17/06/26', amount: '100,00', title: 'Bonifico', category: 'Lavoro', account: 'Carta Risparmio'),
        ],
      );
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.accountsFromMetadata, hasLength(3));
      expect(preview.accountsFoundInCsv, 3);
      expect(preview.accountsUsedByMovements, 2);
      expect(preview.accountsToCreate, hasLength(2));
      expect(preview.accountsExistingInDb, 0);
      expect(preview.metadataOnlyAccounts, hasLength(1));
      expect(preview.metadataOnlyAccounts.first, 'Conto Investimenti');
    });

    test('conti con spazi normalizzati non duplicati', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', account: 'Revolut'),
        _row(date: '16/06/26', amount: '-20,00', title: 'Cena', account: 'Revolut '),
        _row(date: '17/06/26', amount: '100,00', title: 'Entrata', account: '  Revolut  '),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.accountsToCreate, hasLength(1));
      expect(preview.accountsToCreate.first, 'Revolut');
      expect(preview.accountsUsedByMovements, 1);
    });

    test('conto in transfer ambiguo appare in preview', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-500,00', title: 'Trasferimento', account: 'Conto A'),
        _row(date: '15/06/26', amount: '500,00', title: 'Trasferimento', account: 'Conto A'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.ambiguousTransfers, hasLength(2));
      expect(preview.accountsToCreate, contains('Conto A'));
      expect(preview.accountsUsedByMovements, 1);
    });

    test('commit crea tutti i conti dai movimenti importabili', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', account: 'NuovoConto'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.accountsToCreate, contains('NuovoConto'));
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.accountsCreated, 1);
      expect(fixture.db.accounts.any((a) => a.name == 'NuovoConto'), isTrue);
    });

    test('nessuna cartella/gruppo creata', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', account: 'Conto Corrente'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      // Nessuna cartella/gruppo nei nomi conto
      expect(preview.accountsToCreate.every((a) => !a.contains(':') && !a.contains('/')), isTrue);
    });
  });

  group('Preview e commit', () {
    test('preview non scrive nel DB', () async {
      final fixture = await _createDb();
      final initialCount = fixture.db.movements.length;
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
      ]);
      await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(fixture.db.movements.length, initialCount);
    });

    test('commit importa movimenti nel DB', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', category: 'Spesa', account: 'Conto A'),
        _row(date: '16/06/26', amount: '1500,00', title: 'Stipendio', category: 'Lavoro', account: 'Conto B'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.movementsImported, 2);
      expect(report.transfersImported, 0);
      expect(report.errors, isEmpty);
      expect(fixture.db.movements.length, 2);
      expect(fixture.db.movements.where((m) => m.type == MovementType.expense), hasLength(1));
      expect(fixture.db.movements.where((m) => m.type == MovementType.income), hasLength(1));
    });

    test('commit crea conti automaticamente', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Caffè', account: 'NuovoConto'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.accountsToCreate, contains('NuovoConto'));
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.accountsCreated, 1);
      expect(fixture.db.accounts.any((a) => a.name == 'NuovoConto'), isTrue);
    });

    test('commit crea categorie automaticamente', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'NuovaCat'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.categoriesToCreate, contains('NuovaCat'));
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.categoriesCreated, 1);
      expect(fixture.db.categories.any((c) => c.name == 'NuovaCat'), isTrue);
    });

    test('commit crea sottocategorie automaticamente', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', category: 'Nuova:NuovaSub'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.categoriesCreated, 1);
      expect(report.subcategoriesCreated, 1);
      final cat = fixture.db.categories.firstWhere((c) => c.name == 'Nuova');
      expect(fixture.db.subcategories.any((s) => s.categoryId == cat.id && s.name == 'NuovaSub'), isTrue);
    });

    test('commit transfer crea movimento trasferimento', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-500,00', title: 'Trasferimento', account: 'Conto A'),
        _row(date: '15/06/26', amount: '500,00', title: 'Trasferimento', account: 'Conto B'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.transfersImported, 1);
      expect(report.movementsImported, 0);
      expect(fixture.db.movements, hasLength(1));
      expect(fixture.db.movements.first.type, MovementType.transfer);
    });

    test('commit con payee', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-50,00', title: 'Cena', payee: 'Ristorante',
             category: 'Spesa:Ristoranti'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.movementsImported, 1);
      final movement = fixture.db.movements.first;
      expect(movement.payee, 'Ristorante');
      expect(movement.title, 'Cena');
    });

    test('import iFinance non crea profili beneficiario automaticamente', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '15/06/26',
          amount: '-50,00',
          title: 'Cena',
          payee: 'Ristorante',
          category: 'Spesa:Ristoranti',
        ),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      await IFinanceCsvImportService.commitImport(fixture.db, preview);

      expect(fixture.db.movements, hasLength(1));
      expect(fixture.db.beneficiaryProfiles, isEmpty);
    });

    test('reimport dopo profilo beneficiario non duplica movimenti', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '15/06/26',
          amount: '-50,00',
          title: 'Cena',
          payee: 'Ristorante Rossi',
          category: 'Spesa:Ristoranti',
        ),
      ]);

      final firstPreview = await IFinanceCsvImportService.previewCsv(
        fixture.db,
        csv,
      );
      final firstReport = await IFinanceCsvImportService.commitImport(
        fixture.db,
        firstPreview,
      );
      expect(firstReport.movementsImported, 1);

      await fixture.db.createManualBeneficiaryProfile(
        'Ristorante Rossi',
        iconKey: BeneficiaryProfile.defaultIconKey,
      );
      await fixture.db.updateBeneficiaryProfile(
        fixture.db.beneficiaryProfiles.first.copyWith(
          displayName: 'Ristorante Rossi Srl',
        ),
      );

      final secondPreview = await IFinanceCsvImportService.previewCsv(
        fixture.db,
        csv,
      );
      final secondReport = await IFinanceCsvImportService.commitImport(
        fixture.db,
        secondPreview,
      );

      expect(secondReport.movementsImported, 0);
      expect(secondReport.duplicatesSkipped, 1);
      expect(fixture.db.movements, hasLength(1));
      expect(fixture.db.movements.first.payee, 'Ristorante Rossi');
      expect(
        fixture.db.beneficiaryProfiles.first.displayName,
        'Ristorante Rossi Srl',
      );
    });

    test('reimport stesso CSV con transfer importa 0 nuovi movimenti', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(
          date: '12/06/26',
          amount: '10,00',
          title: 'Trasferimento',
          payee: 'Trasferimento da Conto comunità',
          category: 'Trasferimenti',
          account: 'Contante',
        ),
        _row(
          date: '12/06/26',
          amount: '-10,00',
          title: 'Trasferimento',
          payee: 'Trasferimento su Contante',
          category: 'Trasferimenti',
          account: 'Conto comunità',
        ),
      ]);

      final firstPreview = await IFinanceCsvImportService.previewCsv(
        fixture.db,
        csv,
      );
      final firstReport = await IFinanceCsvImportService.commitImport(
        fixture.db,
        firstPreview,
      );
      expect(firstReport.transfersImported, 1);
      expect(fixture.db.movements, hasLength(1));

      final secondPreview = await IFinanceCsvImportService.previewCsv(
        fixture.db,
        csv,
      );
      final secondReport = await IFinanceCsvImportService.commitImport(
        fixture.db,
        secondPreview,
      );
      expect(secondPreview.totalToImport, 0);
      expect(secondReport.movementsImported, 0);
      expect(secondReport.transfersImported, 0);
      expect(secondReport.duplicatesSkipped, 1);
      expect(fixture.db.movements, hasLength(1));
    });

    test('periodo min/max calcolato', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '01/01/26', amount: '-10,00', title: 'A'),
        _row(date: '31/12/26', amount: '-20,00', title: 'B'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.dateMin, DateTime(2026, 1, 1));
      expect(preview.dateMax, DateTime(2026, 12, 31));
    });
  });

  group('Stress test', () {
    test('4000+ righe', () async {
      final fixture = await _createDb();
      final rows = <String>[];
      for (var i = 0; i < 4000; i++) {
        final day = (i % 28) + 1;
        rows.add(_row(
          date: '${day.toString().padLeft(2, '0')}/06/26',
          amount: '-${(i + 1).toString()},50',
          title: 'Movimento $i',
          category: 'Categoria${i % 10}',
          account: 'Conto${i % 5}',
        ));
      }
      // Add one income
      rows.add(_row(
        date: '15/06/26', amount: '5000,00', title: 'Stipendio',
        category: 'Lavoro', account: 'Conto0',
      ));

      final csv = _csv(
        metadataLines: ['Metadato 1', 'Metadato 2', ''],
        dataRows: rows,
      );

      final stopwatch = Stopwatch()..start();
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.totalRows, 4001);
      expect(preview.movements, hasLength(4001));
      expect(preview.errors, isEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));

      stopwatch.reset();
      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.movementsImported, 4001);
      expect(fixture.db.movements.length, 4001);
      expect(fixture.db.accounts.length, 6); // 5 conti + default
      expect(stopwatch.elapsedMilliseconds, lessThan(30000));
    });
  });

  group('Import report', () {
    test('report mostra statistiche corrette', () async {
      final fixture = await _createDb();
      final csv = _csv(dataRows: [
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', account: 'Conto A'),
        _row(date: '15/06/26', amount: '-10,00', title: 'Spesa', account: 'Conto A'),
        _row(date: '16/06/26', amount: '100,00', title: 'Entrata', account: 'Conto B'),
      ]);
      final preview = await IFinanceCsvImportService.previewCsv(fixture.db, csv);
      expect(preview.intraFileRepeats, 1);
      expect(preview.duplicatesSkipped, 0);
      expect(preview.movements, hasLength(3));
      expect(preview.accountsToCreate, hasLength(2));
      expect(preview.errors, isEmpty);

      final report = await IFinanceCsvImportService.commitImport(fixture.db, preview);
      expect(report.movementsImported, 3);
      expect(report.duplicatesSkipped, 0);
      expect(report.accountsCreated, 2);
    });
  });
}
