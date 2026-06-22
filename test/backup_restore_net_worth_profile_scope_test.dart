import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/backup_data.dart';
import 'package:stream_app/services/backup_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.netWorthAccountIdsNotifier.value = null;
  });

  BackupData backupWithSelection(
    List<Account> accounts,
    List<String>? selectedIds,
  ) {
    return BackupData(
      version: BackupService.currentVersion,
      createdAt: '2026-06-21T00:00:00.000',
      accounts: accounts,
      categories: const [],
      movements: const [],
      settings: BackupSettings(
        showNotes: false,
        netWorthAccountIds: selectedIds,
      ),
    );
  }

  Account account(String id) => Account(
    id: id,
    name: id,
    type: AccountType.bank,
    createdAt: DateTime(2026, 6, 21),
  );

  test('backup export reads current profile selection only', () async {
    await PreferencesService.saveDashboardNetWorthAccountIds({
      'acc_a',
    }, profileId: 'profile_a');
    await PreferencesService.saveDashboardNetWorthAccountIds({
      'acc_b1',
      'acc_b2',
    }, profileId: 'profile_b');

    final json = await BackupService.exportToJson(
      AppDatabase(),
      activeProfileId: 'profile_b',
    );
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    final settings = parsed['settings'] as Map<String, dynamic>;

    expect(settings['netWorthAccountIds'], ['acc_b1', 'acc_b2']);
  });

  test('restore writes selection only into current profile key', () async {
    SharedPreferences.setMockInitialValues({
      'dashboard_net_worth_account_ids_profile_a': ['acc_a'],
    });

    final backup = backupWithSelection([account('acc_b')], ['acc_b']);

    await BackupService.restore(
      AppDatabase(),
      backup,
      activeProfileId: 'profile_b',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('dashboard_net_worth_account_ids_profile_a'), [
      'acc_a',
    ]);
    expect(prefs.getStringList('dashboard_net_worth_account_ids_profile_b'), [
      'acc_b',
    ]);
    expect(PreferencesService.netWorthAccountIdsNotifier.value, {'acc_b'});
  });

  test('restore does not create legacy global key', () async {
    final backup = backupWithSelection([account('cash')], ['cash']);

    await BackupService.restore(
      AppDatabase(),
      backup,
      activeProfileId: 'profile_b',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('dashboard_net_worth_account_ids'), isFalse);
  });

  test(
    'restore with invalid ids falls back to tutti i conti for current profile',
    () async {
      SharedPreferences.setMockInitialValues({
        'dashboard_net_worth_account_ids_profile_b': ['stale_id'],
      });

      final backup = backupWithSelection(
        [account('valid_acc')],
        ['missing_acc'],
      );

      await BackupService.restore(
        AppDatabase(),
        backup,
        activeProfileId: 'profile_b',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey('dashboard_net_worth_account_ids_profile_b'),
        isFalse,
      );
      expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    },
  );

  test('restore preserves empty none-state for current profile', () async {
    SharedPreferences.setMockInitialValues({
      'dashboard_net_worth_account_ids_profile_a': ['acc_a'],
    });

    final backup = backupWithSelection([account('acc_b')], <String>[]);

    await BackupService.restore(
      AppDatabase(),
      backup,
      activeProfileId: 'profile_b',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('dashboard_net_worth_account_ids_profile_a'), [
      'acc_a',
    ]);
    expect(
      prefs.getStringList('dashboard_net_worth_account_ids_profile_b'),
      <String>[],
    );
    expect(PreferencesService.netWorthAccountIdsNotifier.value, <String>{});
  });

  test(
    'restore with null activeProfileId uses safe fallback and creates no bleed',
    () async {
      SharedPreferences.setMockInitialValues({
        'dashboard_net_worth_account_ids_profile_a': ['acc_a'],
      });

      final backup = backupWithSelection([account('acc_b')], ['acc_b']);

      await BackupService.restore(AppDatabase(), backup);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('dashboard_net_worth_account_ids_profile_a'), [
        'acc_a',
      ]);
      expect(
        prefs.containsKey('dashboard_net_worth_account_ids_profile_b'),
        isFalse,
      );
      expect(prefs.containsKey('dashboard_net_worth_account_ids'), isFalse);
      expect(PreferencesService.netWorthAccountIdsNotifier.value, isNull);
    },
  );
}
