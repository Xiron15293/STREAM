import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/services/ifinance_csv_import_service.dart';
import 'package:stream_app/services/profile_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('stream_profiles_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<ProfileService> createService() async {
    final service = ProfileService(testBasePath: tempDir.path);
    await service.initialize();
    return service;
  }

  Future<AppDatabase> openDbFor(ProfileService service, String profileId) async {
    final profile = service.profiles.firstWhere((p) => p.id == profileId);
    final sqlite = SQLiteService();
    await sqlite.open(path: await service.getDatabasePath(profile));
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();
    addTearDown(() => sqlite.close());
    return db;
  }

  String csv({
    required List<String> dataRows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Data;Importo;Causale;Beneficiario/Contribuente;IBAN;Bic/Swift bancario;Categoria;Commento;Etichette;Conto',
    );
    for (final row in dataRows) {
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  String row({
    required String date,
    required String amount,
    String title = '',
    String payee = '',
    String category = '',
    String comment = '',
    String labels = '',
    String account = 'Conto Corrente',
  }) {
    return '$date;$amount;$title;$payee;;;$category;$comment;$labels;$account';
  }

  test('create profile uses unique dbFileName and persists activeProfileId', () async {
    final service = await createService();
    final created = await service.createProfile('Profilo B');

    expect(created.dbFileName, startsWith('stream_profile_'));
    expect(created.dbFileName, endsWith('.db'));
    expect(created.dbFileName, isNot('stream.db'));

    await service.switchProfile(created.id);
    final reloaded = ProfileService(testBasePath: tempDir.path);
    await reloaded.initialize();

    expect(reloaded.activeProfileId, created.id);
    expect(reloaded.activeProfile?.name, 'Profilo B');
  });

  test('rename and delete keep registry valid', () async {
    final service = await createService();
    final created = await service.createProfile('Tmp');

    await service.renameProfile(created.id, 'Rinominato');
    expect(
      service.profiles.firstWhere((p) => p.id == created.id).name,
      'Rinominato',
    );

    await service.switchProfile(created.id);
    await service.deleteProfile(created.id);

    expect(service.activeProfileId, 'main');
    expect(service.profiles.any((p) => p.id == created.id), isFalse);
  });

  test('corrupted registry with duplicate stream.db is healed', () async {
    final registryFile = File(p.join(tempDir.path, 'profiles.json'));
    await registryFile.writeAsString(
      jsonEncode({
        'activeProfileId': 'profile_b',
        'profiles': [
          {
            'id': 'main',
            'name': 'Principale',
            'dbFileName': 'stream.db',
            'createdAt': DateTime(2026, 1, 1).toIso8601String(),
            'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
          },
          {
            'id': 'profile_b',
            'name': 'B',
            'dbFileName': 'stream.db',
            'createdAt': DateTime(2026, 1, 2).toIso8601String(),
            'updatedAt': DateTime(2026, 1, 2).toIso8601String(),
          },
        ],
      }),
    );

    final service = await createService();
    final main = service.profiles.firstWhere((p) => p.id == 'main');
    final b = service.profiles.firstWhere((p) => p.id == 'profile_b');

    expect(main.dbFileName, 'stream.db');
    expect(b.dbFileName, 'stream_profile_profile_b.db');
    expect(service.activeProfileId, 'profile_b');
  });

  test('db isolation: profile A and B see only their own movements', () async {
    final service = await createService();
    final b = await service.createProfile('Profilo B');

    final dbA = await openDbFor(service, 'main');
    await dbA.addMovement(
      Movement(
        id: 'a1',
        title: 'Movimento A',
        amount: 10,
        type: MovementType.expense,
        date: DateTime(2026, 6, 15),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 15),
      ),
    );

    final dbB = await openDbFor(service, b.id);
    expect(dbB.movements, isEmpty);
    await dbB.addMovement(
      Movement(
        id: 'b1',
        title: 'Movimento B',
        amount: 20,
        type: MovementType.expense,
        date: DateTime(2026, 6, 15),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 15),
      ),
    );

    final reloadA = await openDbFor(service, 'main');
    final reloadB = await openDbFor(service, b.id);
    expect(reloadA.movements.map((m) => m.title), ['Movimento A']);
    expect(reloadB.movements.map((m) => m.title), ['Movimento B']);
  });

  test('reset on profile B does not touch profile A', () async {
    final service = await createService();
    final b = await service.createProfile('Profilo B');

    final dbA = await openDbFor(service, 'main');
    await dbA.createMovementFromTemplate(
      title: 'A',
      amount: 10,
      type: MovementType.expense,
      categoryId: 'exp_1',
    );

    final dbB = await openDbFor(service, b.id);
    await dbB.createMovementFromTemplate(
      title: 'B',
      amount: 20,
      type: MovementType.expense,
      categoryId: 'exp_1',
    );

    await dbB.resetAllData();

    final reloadA = await openDbFor(service, 'main');
    final reloadB = await openDbFor(service, b.id);
    expect(reloadA.movements, isNotEmpty);
    expect(reloadB.movements, isEmpty);
  });

  test('beneficiaries are isolated by profile', () async {
    final service = await createService();
    final b = await service.createProfile('Profilo B');

    final dbA = await openDbFor(service, 'main');
    await dbA.createManualBeneficiaryProfile('Mario Rossi');

    final dbB = await openDbFor(service, b.id);
    expect(dbB.beneficiaryProfiles, isEmpty);
    await dbB.createManualBeneficiaryProfile('Luigi Verdi');

    final reloadA = await openDbFor(service, 'main');
    final reloadB = await openDbFor(service, b.id);
    expect(
      reloadA.beneficiaryProfiles.map((p) => p.displayName),
      ['Mario Rossi'],
    );
    expect(
      reloadB.beneficiaryProfiles.map((p) => p.displayName),
      ['Luigi Verdi'],
    );
  });

  test('iFinance import on profile B leaves profile A empty', () async {
    final service = await createService();
    final b = await service.createProfile('Profilo B');

    final dbB = await openDbFor(service, b.id);

    final preview = await IFinanceCsvImportService.previewCsv(
      dbB,
      csv(dataRows: [
        row(
          date: '15/06/26',
          amount: '-12,50',
          title: 'Spesa',
          payee: 'Bar Roma',
          category: 'Spesa',
          account: 'Contante',
        ),
      ]),
    );
    expect(preview.totalToImport, 1);
    await IFinanceCsvImportService.commitImport(dbB, preview);

    final reloadA = await openDbFor(service, 'main');
    final reloadB = await openDbFor(service, b.id);
    expect(reloadA.movements, isEmpty);
    expect(reloadB.movements, hasLength(1));
    expect(reloadB.movements.first.payee, 'Bar Roma');
  });
}
