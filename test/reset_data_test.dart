import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/categories_data.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/screens/archive_screen.dart';
import 'package:stream_app/screens/dashboard_screen.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/services/backup_service.dart';
import 'package:stream_app/widgets/movement_card.dart';

ThemeData _testTheme() => ThemeData(useMaterial3: true).copyWith(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
);

class TriggerFailingSQLiteService extends SQLiteService {
  Future<void> installAbortTrigger() async {
    await transaction((txn) async {
      await txn.execute('''
        CREATE TRIGGER IF NOT EXISTS abort_reset_categories
        BEFORE INSERT ON categories
        BEGIN
          SELECT RAISE(ABORT, 'forced reset failure');
        END;
      ''');
    });
  }
}

Future<void> _pumpMainAppWithResetBackupStub(
  WidgetTester tester,
  AppDatabase db,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: _testTheme(),
      home: _TestMainScaffold(db: db),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestMainScaffold extends StatefulWidget {
  final AppDatabase db;

  const _TestMainScaffold({required this.db});

  @override
  State<_TestMainScaffold> createState() => _TestMainScaffoldState();
}

class _TestMainScaffoldState extends State<_TestMainScaffold> {
  int _currentIndex = 0;
  late final AppDatabase _db = widget.db;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(db: _db),
      ArchiveScreen(db: _db),
      SettingsScreen(
        db: _db,
        createPreResetBackup: (_) async => 'test://noop-backup',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          BottomNavigationBarItem(
            icon: KeyedSubtree(
              key: const Key('bottom_nav_dashboard'),
              child: const Icon(Icons.dashboard),
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: KeyedSubtree(
              key: const Key('bottom_nav_archive'),
              child: const Icon(Icons.folder),
            ),
            label: 'Archivio',
          ),
          BottomNavigationBarItem(
            icon: KeyedSubtree(
              key: const Key('bottom_nav_settings'),
              child: const Icon(Icons.settings),
            ),
            label: 'Impostazioni',
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'show_notes': true,
      'last_backup_date': '2026-06-07 10:00',
    });
  });

  Future<void> seedUserData(AppDatabase db) async {
    await db.addAccount(
      Account(
        id: 'acc_custom',
        name: 'Conto Test',
        type: AccountType.bank,
        createdAt: DateTime(2026, 6, 7),
      ),
    );
    await db.addCategory('Categoria Test', MovementType.expense, 0xFF123456);
    await db.addQuickMovement(
      const QuickMovement(
        id: 'qm_custom',
        title: 'Rapido Custom',
        amount: 12.5,
        type: MovementType.expense,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
      ),
    );
    await db.addFavoriteMovement(
      const FavoriteMovement(
        id: 'fm_custom',
        title: 'Preferito Custom',
        amount: 22.0,
        type: MovementType.income,
        categoryId: 'inc_1',
        accountId: defaultAccountId,
      ),
    );
    await db.addMovement(
      Movement(
        id: 'mov_custom',
        title: 'Vecchio movimento',
        amount: 45.0,
        type: MovementType.expense,
        date: DateTime(2026, 6, 7),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: DateTime(2026, 6, 7),
      ),
    );
  }

  Future<void> openSettingsOrResetArea(WidgetTester tester) async {
    final settingsNav = find
        .byKey(const Key('bottom_nav_settings'))
        .hitTestable();
    if (settingsNav.evaluate().isNotEmpty) {
      await tester.tap(settingsNav);
      await tester.pumpAndSettle();
    }

    final settingsScreen = find.byType(SettingsScreen);
    expect(settingsScreen, findsOneWidget);
    final scrollable = find.descendant(
      of: settingsScreen,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsWidgets);

    final resetTile = find.byKey(const Key('settings_reset_data_tile'));
    final fallbackResetTile = find.byKey(const Key('reset_data_tile'));
    try {
      await tester.scrollUntilVisible(
        resetTile,
        250.0,
        scrollable: scrollable.first,
      );
    } catch (_) {
      await tester.scrollUntilVisible(
        fallbackResetTile,
        250.0,
        scrollable: scrollable.first,
      );
    }
    await tester.pumpAndSettle();

    final hittableResetTile = resetTile.hitTestable().evaluate().isNotEmpty
        ? resetTile.hitTestable()
        : fallbackResetTile.hitTestable();
    expect(hittableResetTile, findsOneWidget);
    await tester.tap(hittableResetTile);
    await tester.pumpAndSettle();
    expect(find.text('Reset dati app?'), findsOneWidget);
  }

  Future<void> startResetFlow(WidgetTester tester) async {
    final confirmField = find.byKey(const Key('reset_data_confirm_field'));
    expect(confirmField, findsOneWidget);
    await tester.ensureVisible(confirmField);
    await tester.enterText(confirmField, 'RESET');
    await tester.pumpAndSettle();
    final confirmButton = find
        .byKey(const Key('reset_data_confirm_button'))
        .hitTestable();
    expect(confirmButton, findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('reset_data_confirm_button'))).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(confirmButton);
    await tester.runAsync(() async {
      await tester.tap(confirmButton);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(deadline) &&
        find.text('Reset dati app?').evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Reset dati app?'), findsNothing);
  }

  Future<bool> confirmResetFlow(
    WidgetTester tester, {
    bool continueIfBackupFails = true,
  }) async {
    await startResetFlow(tester);

    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));

      final backupFailed = find.text('Backup pre-reset fallito');
      if (backupFailed.evaluate().isNotEmpty) {
        if (continueIfBackupFails) {
          final continueButton =
              find.widgetWithText(FilledButton, 'Continua').hitTestable();
          expect(continueButton, findsOneWidget);
          await tester.ensureVisible(continueButton);
          await tester.runAsync(() async {
            await tester.tap(continueButton);
            await Future<void>.delayed(Duration.zero);
          });
        } else {
          final cancelButton =
              find.widgetWithText(TextButton, 'Annulla').hitTestable();
          expect(cancelButton, findsOneWidget);
          await tester.ensureVisible(cancelButton);
          await tester.runAsync(() async {
            await tester.tap(cancelButton);
            await Future<void>.delayed(Duration.zero);
          });
        }
        await tester.pumpAndSettle();
        return true;
      }

      if (find.text('Dati app resettati').evaluate().isNotEmpty) {
        await tester.pumpAndSettle();
        return false;
      }
    }
    return false;
  }

  Future<void> waitForResetCompleted(WidgetTester tester, AppDatabase db) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {});
      await db.reloadFromDb();

      final movementsEmpty = db.movements.isEmpty;
      final hasDefaultAccount = db.accounts.any(
        (a) => a.id == defaultAccountId,
      );
      final hasOnlyDefaultAccount = db.accounts.length == 1;
      final hasDefaultCategories = db.categories.length == DefaultCategories.all.length;
      final hasDefaultQuickMovements = db.quickMovements.length == 4;
      final favoritesEmpty = db.favoriteMovements.isEmpty;
      final resetCompleted =
          movementsEmpty &&
          hasDefaultAccount &&
          hasOnlyDefaultAccount &&
          hasDefaultCategories &&
          hasDefaultQuickMovements &&
          favoritesEmpty;

      if (resetCompleted) {
        await db.reloadFromDb();
        await tester.pumpAndSettle();
        return;
      }
    }

    final movements = db.movements.map((m) => '${m.id}:${m.title}').toList();
    final favorites = db.favoriteMovements
        .map((m) => '${m.id}:${m.title}')
        .toList();
    final quick = db.quickMovements.map((m) => '${m.id}:${m.title}').toList();
    final movementsLength = db.movements.length;
    final favoritesLength = db.favoriteMovements.length;
    final quickLength = db.quickMovements.length;
    final accountsLength = db.accounts.length;
    final categoriesLength = db.categories.length;
    final failedConditions = <String>[
      if (db.movements.isNotEmpty) 'movementsEmpty',
      if (!db.accounts.any((a) => a.id == defaultAccountId))
        'hasDefaultAccount',
      if (db.accounts.length != 1) 'hasOnlyDefaultAccount',
      if (db.categories.length != 10) 'hasDefaultCategories',
      if (db.quickMovements.length != 4) 'hasDefaultQuickMovements',
      if (db.favoriteMovements.isNotEmpty) 'favoritesEmpty',
    ];
    fail(
      'Reset non completato entro timeout. '
      'movements.length=$movementsLength; '
      'favoriteMovements.length=$favoritesLength; '
      'quickMovements.length=$quickLength; '
      'accounts.length=$accountsLength; '
      'categories.length=$categoriesLength; '
      'Movimenti residui: $movements; '
      'Preferiti residui: $favorites; '
      'Rapidi presenti: $quick; '
      'condizioni fallite: $failedConditions',
    );
  }

  Future<void> assertDefaultsRestored(WidgetTester tester, AppDatabase db) async {
    expect(db.movements, isEmpty);
    expect(db.accounts.length, 1);
    expect(db.accounts.single.id, defaultAccountId);
    expect(db.categories.length, DefaultCategories.all.length);
    expect(db.quickMovements.length, 4);
    expect(db.favoriteMovements, isEmpty);
    expect(db.totalIncome, closeTo(0.0, 0.001));
    expect(db.totalExpenses, closeTo(0.0, 0.001));
    expect(db.balance, closeTo(0.0, 0.001));
    expect(db.totalAccountsBalance, closeTo(0.0, 0.001));
    expect(await PreferencesService.loadShowNotes(), isFalse);
    expect(await PreferencesService.loadLastBackupDate(), isNull);
    await tester.pumpAndSettle();
  }

  testWidgets('Reset richiede conferma e Annulla non cancella nulla', (
    WidgetTester tester,
  ) async {
    final db = AppDatabase();
    await seedUserData(db);

    await tester.pumpWidget(MaterialApp(theme: _testTheme(), home: MainScaffold(db: db)));
    await tester.pumpAndSettle();

    await openSettingsOrResetArea(tester);

    expect(find.text('Reset dati app?'), findsOneWidget);
    expect(find.byKey(const Key('reset_data_confirm_button')), findsOneWidget);

    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('reset_data_confirm_button')),
    );
    expect(confirmButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('reset_data_confirm_field')),
      'RESET',
    );
    await tester.pumpAndSettle();

    final confirmButtonEnabled = tester.widget<FilledButton>(
      find.byKey(const Key('reset_data_confirm_button')),
    );
    expect(confirmButtonEnabled.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('reset_data_cancel_button')));
    await tester.pumpAndSettle();

    expect(db.movements.length, 1);
    expect(db.accounts.length, 2);
    expect(db.categories.length, 11);
    expect(db.quickMovements.length, 5);
    expect(db.favoriteMovements.length, 1);
  });

  // TODO: Reset widget flow fragile; reset validated manually on Pixel;
  // rerun as integration test or service-level test.
    testWidgets(
      'Reset confermato ripristina i default e pulisce Archivio',
      (WidgetTester tester) async {
      final db = AppDatabase();
      await seedUserData(db);

      await _pumpMainAppWithResetBackupStub(tester, db);

      await openSettingsOrResetArea(tester);
      await confirmResetFlow(tester);
      await waitForResetCompleted(tester, db);
      await assertDefaultsRestored(tester, db);

      await tester.tap(find.byKey(const Key('bottom_nav_dashboard')));
      await tester.pumpAndSettle();
      expect(find.text('+0.00 €'), findsAtLeastNWidgets(1));

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      expect(find.text('Nessun movimento'), findsOneWidget);
      expect(find.byType(MovementCard), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Vecchio movimento');
      await tester.pumpAndSettle();
      expect(find.byType(MovementCard), findsNothing);
      expect(find.text('Nessun movimento'), findsOneWidget);
    },
  );

  test(
    'Backup pre-reset viene creato e non viene cancellato dal reset',
    () async {
      final db = AppDatabase();
      await seedUserData(db);

      final path = await BackupService.createPreResetBackup(db);
      final file = File(path);
      expect(await file.exists(), isTrue);

      await db.resetAllData();

      expect(await file.exists(), isTrue);

      await file.delete();
    },
  );

  testWidgets(
    'Se il backup pre-reset fallisce compare l\'avviso prima di continuare',
    (WidgetTester tester) async {
      final db = AppDatabase();
      await seedUserData(db);

      await tester.pumpWidget(
      MaterialApp(
        theme: _testTheme(),
        home: SettingsScreen(
          db: db,
          createPreResetBackup: (_) async {
            throw StateError('forced backup failure');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openSettingsOrResetArea(tester);
      final sawBackupFailure = await confirmResetFlow(
        tester,
        continueIfBackupFails: false,
      );

      expect(sawBackupFailure, isTrue);
      expect(db.movements.length, 1);
    },
  );

  testWidgets(
    'Se il backup pre-reset fallisce il reset continua solo dopo conferma',
    (WidgetTester tester) async {
      final db = AppDatabase();
      await seedUserData(db);

      await tester.pumpWidget(
      MaterialApp(
        theme: _testTheme(),
        home: SettingsScreen(
          db: db,
          createPreResetBackup: (_) async {
            throw StateError('forced backup failure');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openSettingsOrResetArea(tester);
      final sawBackupFailure = await confirmResetFlow(tester);
      expect(sawBackupFailure, isTrue);
      await waitForResetCompleted(tester, db);

      expect(db.movements, isEmpty);
      expect(db.accounts.length, 1);
      expect(db.categories.length, DefaultCategories.all.length);
    },
  );

  test(
    'Reset atomico: un errore SQLite nella transazione non lascia stato parziale',
    () async {
      final sqlite = TriggerFailingSQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();

      await db.addMovement(
        Movement(
          id: 'mov_before_reset',
          title: 'Prima del reset',
          amount: 10.0,
          type: MovementType.expense,
          date: DateTime(2026, 6, 7),
          categoryId: 'exp_1',
          createdAt: DateTime(2026, 6, 7),
        ),
      );

      await sqlite.installAbortTrigger();

      await expectLater(db.resetAllData(), throwsException);

      expect(db.movements.any((m) => m.id == 'mov_before_reset'), isTrue);
      expect(db.categories.isNotEmpty, isTrue);
      expect(db.accounts.isNotEmpty, isTrue);

      await db.reloadFromDb();
      expect(db.movements.any((m) => m.id == 'mov_before_reset'), isTrue);
      expect(db.categories.isNotEmpty, isTrue);
      expect(db.accounts.isNotEmpty, isTrue);

      final persistedMovements = await sqlite.loadMovements();
      expect(persistedMovements.any((m) => m.id == 'mov_before_reset'), isTrue);

      await sqlite.close();
    },
  );
}
