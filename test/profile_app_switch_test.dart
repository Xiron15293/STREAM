import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/services/profile_service.dart';
import 'package:stream_app/theme.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('stream_profile_app_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<AppDatabase> openProfileDb(ProfileService service, String profileId) async {
    final profile = service.profiles.firstWhere((p) => p.id == profileId);
    final sqlite = SQLiteService();
    await sqlite.open(path: await service.getDatabasePath(profile));
    final db = AppDatabase(sqlite: sqlite);
    await db.initialize();
    addTearDown(() => sqlite.close());
    return db;
  }

  Widget wrapMainScaffold({
    required AppDatabase db,
    required String profileId,
  }) {
    return MaterialApp(
      theme: StreamTheme.dark,
      home: MainScaffold(
        key: ValueKey('main_scaffold_$profileId'),
        db: db,
        activeProfileId: profileId,
        onManageProfiles: () {},
      ),
    );
  }

  testWidgets('switch profile key rebuild prevents stale db reuse', (tester) async {
    late AppDatabase dbA;
    late AppDatabase dbB;
    late String profileBId;

    await tester.runAsync(() async {
      final service = ProfileService(testBasePath: tempDir.path);
      await service.initialize();
      final profileB = await service.createProfile('Profilo B');
      profileBId = profileB.id;

      dbA = await openProfileDb(service, 'main');
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

      dbB = await openProfileDb(service, profileBId);
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
    });

    await tester.pumpWidget(
      wrapMainScaffold(db: dbA, profileId: 'main'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('main_scaffold_main')), findsOneWidget);
    await tester.tap(find.byKey(const Key('bottom_nav_archive')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Movimento A'), findsOneWidget);
    expect(find.text('Movimento B'), findsNothing);

    await tester.pumpWidget(
      wrapMainScaffold(db: dbB, profileId: profileBId),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('main_scaffold_$profileBId')), findsOneWidget);
    await tester.tap(find.byKey(const Key('bottom_nav_archive')).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Movimento B'), findsOneWidget);
    expect(find.text('Movimento A'), findsNothing);
  });
}
