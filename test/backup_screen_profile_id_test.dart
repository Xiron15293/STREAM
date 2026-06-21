import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/models/backup_data.dart';
import 'package:stream_app/screens/backup_screen.dart';

void main() {
  testWidgets('export and pre-restore backup pass activeProfileId', (
    tester,
  ) async {
    final capturedProfileIds = <String?>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BackupScreen(
          db: AppDatabase(),
          activeProfileId: 'profile_b',
          exportBackupJson: (db, {activeProfileId}) async {
            capturedProfileIds.add(activeProfileId);
            return '{"version":2,"createdAt":"2026-06-21T00:00:00.000","accounts":[],"categories":[],"movements":[],"settings":{"showNotes":false}}';
          },
        ),
      ),
    );
    await tester.pump();

    final dynamic state = tester.state(find.byType(BackupScreen));
    await state.exportJsonForTesting();
    await state.preRestoreJsonForTesting();

    expect(capturedProfileIds, ['profile_b', 'profile_b']);
  });

  testWidgets('restore callback receives activeProfileId', (tester) async {
    final capturedProfileIds = <String?>[];
    final backup = BackupData(
      version: 2,
      createdAt: '2026-06-21T00:00:00.000',
      accounts: const [],
      categories: const [],
      movements: const [],
      settings: const BackupSettings(showNotes: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BackupScreen(
          db: AppDatabase(),
          activeProfileId: 'profile_b',
          restoreBackupData: (db, data, {activeProfileId}) async {
            capturedProfileIds.add(activeProfileId);
          },
        ),
      ),
    );
    await tester.pump();

    final dynamic state = tester.state(find.byType(BackupScreen));
    await state.restoreBackupForTesting(backup);

    expect(capturedProfileIds, ['profile_b']);
  });
}
