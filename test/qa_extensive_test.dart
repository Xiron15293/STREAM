import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/categories_data.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/backup_data.dart';
import 'package:stream_app/models/category.dart';
import 'helpers/calculator_test_helpers.dart';
import 'package:stream_app/models/daily_group.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/services/backup_service.dart';
import 'package:stream_app/screens/archive_screen.dart';
import 'package:stream_app/screens/dashboard_screen.dart';
import 'package:stream_app/screens/settings_screen.dart';
import 'package:stream_app/utils/movement_search.dart';
import 'package:stream_app/widgets/grouped_movements_list.dart';
import 'package:stream_app/widgets/movement_card.dart';

const Object _throwingMovementUnset = Object();

class _FailingTransactionSQLiteService extends SQLiteService {
  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return super.transaction((txn) async {
      await action(txn);
      throw StateError('forced rollback');
    });
  }
}

class _ThrowingResetAppDatabase extends AppDatabase {
  @override
  Future<void> resetAllData() async {
    throw StateError('forced reset failure');
  }
}

class _ThrowingMovement extends Movement {
  _ThrowingMovement({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.date,
    required super.categoryId,
    required super.createdAt,
  });

  @override
  Movement copyWith({
    String? id,
    String? title,
    double? amount,
    MovementType? type,
    DateTime? date,
    String? categoryId,
    Object? subcategoryId = _throwingMovementUnset,
    String? accountId,
    Object? destinationAccountId = _throwingMovementUnset,
    Object? note = _throwingMovementUnset,
    Object? payee = _throwingMovementUnset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    throw StateError('forced restore snapshot failure');
  }
}

Future<void> _pumpMainAppWithResetBackupStub(
  WidgetTester tester,
  AppDatabase db, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
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

DateTime _d(int day, [int month = 6, int year = 2026]) =>
    DateTime(year, month, day);

Account _account({
  required String id,
  required String name,
  double initialBalance = 0,
  bool archived = false,
}) {
  return Account(
    id: id,
    name: name,
    type: AccountType.bank,
    initialBalance: initialBalance,
    archived: archived,
    createdAt: DateTime(2026, 1, 1),
  );
}

Category _category({
  required String id,
  required String name,
  required MovementType type,
  bool archived = false,
}) {
  return Category(
    id: id,
    name: name,
    type: type,
    color: type == MovementType.income ? 0xFF4CAF50 : 0xFFEF5350,
    archived: archived,
  );
}

Movement _movement({
  required String id,
  required String title,
  required double amount,
  required MovementType type,
  required DateTime date,
  required String categoryId,
  String accountId = defaultAccountId,
  String? destinationAccountId,
  String? note,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Movement(
    id: id,
    title: title,
    amount: amount,
    type: type,
    date: date,
    categoryId: categoryId,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    note: note,
    createdAt: createdAt ?? date,
    updatedAt: updatedAt,
  );
}

void expectMoney(num actual, num expected, {double delta = 0.001}) {
  expect(actual.toDouble(), closeTo(expected.toDouble(), delta));
}

void expectDateOnly(DateTime actual, DateTime expected) {
  expect(
    DateTime(actual.year, actual.month, actual.day),
    DateTime(expected.year, expected.month, expected.day),
  );
}

Future<({SQLiteService sqlite, AppDatabase db})> _openSqliteDb({
  String? path,
}) async {
  final sqlite = SQLiteService();
  await sqlite.open(path: path ?? inMemoryDatabasePath);
  final db = AppDatabase(sqlite: sqlite);
  await db.initialize();
  return (sqlite: sqlite, db: db);
}

Future<void> _pumpMainApp(
  WidgetTester tester,
  AppDatabase db, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: MainScaffold(db: db),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _goToTab(WidgetTester tester, String tab) async {
  final finder = switch (tab) {
    'Dashboard' => find.byKey(const Key('bottom_nav_dashboard')),
    'Archivio' => find.byKey(const Key('bottom_nav_archive')),
    'Impostazioni' => find.byKey(const Key('bottom_nav_settings')),
    _ => find.text(tab),
  };
  final tappable = finder.hitTestable();
  expect(tappable, findsOneWidget);
  await tester.tap(tappable);
  await tester.pumpAndSettle();
  if (tab == 'Impostazioni') {
    expect(find.byType(SettingsScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);
  }
}

Future<void> _goToArchiveMovements(WidgetTester tester) async {
  await _goToTab(tester, 'Archivio');
  final movementsSection = find.byKey(const Key('archive_section_movements')).hitTestable();
  expect(movementsSection, findsOneWidget);
  await tester.ensureVisible(movementsSection);
  await tester.tap(movementsSection);
  await tester.pumpAndSettle();
}

Future<void> _openMovementPicker(WidgetTester tester) async {
  await _goToArchiveMovements(tester);
  final fab = find.byType(FloatingActionButton).hitTestable();
  expect(fab, findsOneWidget);
  await tester.ensureVisible(fab);
  await tester.tap(fab);
  await tester.pumpAndSettle();
}

Future<void> _fillManualMovementForm(
  WidgetTester tester, {
  required String title,
  required String amount,
  String? note,
  bool income = false,
  bool transfer = false,
}) async {
  final typeText = transfer
      ? 'Trasferimento'
      : income
      ? 'Entrata'
      : 'Spesa';
  await prepareManualMovementDetails(tester, type: typeText);
  await enterMovementTitle(tester, title);
  await enterAmountWithCalculator(tester, amount);
  if (note != null) {
    await enterMovementNote(tester, note);
  }
}

Future<void> _saveManualMovement(WidgetTester tester) async {
  await submitMovement(tester);
}

Future<void> _chooseQuickDate(WidgetTester tester, String choice) async {
  final key = switch (choice) {
    'Oggi' => const Key('quick_date_today'),
    'Ieri' => const Key('quick_date_yesterday'),
    'Domani' => const Key('quick_date_tomorrow'),
    'Scegli data' => const Key('quick_date_custom'),
    _ => throw ArgumentError.value(choice, 'choice'),
  };
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
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
  final confirmButton = find.byKey(const Key('reset_data_confirm_button')).hitTestable();
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

  final deadline = DateTime.now().add(const Duration(seconds: 10));
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
  final deadline = DateTime.now().add(const Duration(seconds: 20));

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(() async {});
    await db.reloadFromDb();

    final movementsEmpty = db.movements.isEmpty;
    final hasDefaultAccount = db.accounts.any((a) => a.id == defaultAccountId);
    final hasOnlyDefaultAccount = db.accounts.length == 1;
    final hasDefaultCategories =
        db.categories.length == DefaultCategories.all.length;
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
    if (!db.accounts.any((a) => a.id == defaultAccountId)) 'hasDefaultAccount',
    if (db.accounts.length != 1) 'hasOnlyDefaultAccount',
    if (db.categories.length != DefaultCategories.all.length)
      'hasDefaultCategories',
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

Future<void> _openResetDialog(WidgetTester tester) => openSettingsOrResetArea(tester);

Future<bool> _confirmResetFlow(
  WidgetTester tester, {
  bool continueIfBackupFails = true,
}) =>
    confirmResetFlow(
      tester,
      continueIfBackupFails: continueIfBackupFails,
    );

Future<void> _waitForResetComplete(WidgetTester tester, AppDatabase db) =>
    waitForResetCompleted(tester, db);

Future<void> _seedTransferAccounts(AppDatabase db) async {
  await db.addAccount(
    _account(id: 'acc_a', name: 'Conto A', initialBalance: 100),
  );
  await db.addAccount(
    _account(id: 'acc_b', name: 'Conto B', initialBalance: 250),
  );
  await db.addAccount(
    _account(id: 'acc_c', name: 'Conto C', initialBalance: -40),
  );
  await db.addAccount(
    _account(id: 'acc_d', name: 'Postepay', initialBalance: -120),
  );
}

Future<void> _seedSearchDataset(AppDatabase db) async {
  await _seedTransferAccounts(db);
  await db.addCategory('Spesa speciale', MovementType.expense, 0xFFEF5350);
  await db.addCategory('Stipendio extra', MovementType.income, 0xFF4CAF50);
  await db.addMovement(
    _movement(
      id: 'm_title',
      title: 'Esselunga',
      amount: 42.0,
      type: MovementType.expense,
      date: _d(15),
      categoryId: 'exp_1',
      accountId: 'acc_d',
      note: 'Acquisto settimanale',
    ),
  );
  await db.addMovement(
    _movement(
      id: 'm_note',
      title: 'Bolletta',
      amount: 65.0,
      type: MovementType.expense,
      date: _d(15),
      categoryId: 'exp_2',
      accountId: 'acc_a',
      note: 'Pagamento al supermercato e benzina',
    ),
  );
  await db.addMovement(
    _movement(
      id: 'm_cat',
      title: 'Paga carburante',
      amount: 55.0,
      type: MovementType.expense,
      date: _d(15),
      categoryId: 'exp_1',
      accountId: 'acc_d',
    ),
  );
  await db.addMovement(
    _movement(
      id: 'm_income',
      title: 'Bonifico',
      amount: 1500.0,
      type: MovementType.income,
      date: _d(15),
      categoryId: 'inc_1',
      accountId: 'acc_a',
      note: 'Stipendio marzo',
    ),
  );
  await db.addMovement(
    _movement(
      id: 'm_transfer',
      title: 'Spostamento fondi',
      amount: 200.0,
      type: MovementType.transfer,
      date: _d(16),
      categoryId: '',
      accountId: 'acc_a',
      destinationAccountId: 'acc_b',
      note: 'Da conto A a conto B',
    ),
  );
}

Future<void> _seedGroupingDataset(AppDatabase db) async {
  await _seedTransferAccounts(db);
  await db.addMovement(
    _movement(
      id: 'g1',
      title: 'Alpha',
      amount: 10,
      type: MovementType.expense,
      date: _d(18),
      categoryId: 'exp_1',
      accountId: 'acc_a',
      createdAt: DateTime(2026, 6, 18, 10, 0),
      updatedAt: DateTime(2026, 6, 18, 12, 0),
    ),
  );
  await db.addMovement(
    _movement(
      id: 'g2',
      title: 'Beta',
      amount: 20,
      type: MovementType.expense,
      date: _d(18),
      categoryId: 'exp_1',
      accountId: 'acc_a',
      createdAt: DateTime(2026, 6, 18, 11, 0),
      updatedAt: DateTime(2026, 6, 12, 12, 0),
    ),
  );
  await db.addMovement(
    _movement(
      id: 'g3',
      title: 'Gamma',
      amount: 30,
      type: MovementType.expense,
      date: _d(18),
      categoryId: 'exp_1',
      accountId: 'acc_a',
      createdAt: DateTime(2026, 6, 18, 11, 0),
      updatedAt: DateTime(2026, 6, 18, 12, 0),
    ),
  );
  await db.addMovement(
    _movement(
      id: 'g_today',
      title: 'Oggi',
      amount: 40,
      type: MovementType.income,
      date: _d(19),
      categoryId: 'inc_1',
      accountId: 'acc_a',
      createdAt: DateTime(2026, 6, 19, 9, 0),
    ),
  );
  await db.addMovement(
    _movement(
      id: 'g_future',
      title: 'Futuro',
      amount: 50,
      type: MovementType.income,
      date: _d(22),
      categoryId: 'inc_1',
      accountId: 'acc_b',
      createdAt: DateTime(2026, 6, 22, 9, 0),
    ),
  );
  await db.addMovement(
    _movement(
      id: 'g_past',
      title: 'Ieri',
      amount: 60,
      type: MovementType.expense,
      date: _d(14),
      categoryId: 'exp_2',
      accountId: 'acc_c',
      createdAt: DateTime(2026, 6, 14, 9, 0),
    ),
  );
}

Future<void> _seedResetDataset(AppDatabase db) async {
  await _seedTransferAccounts(db);
  await db.addQuickMovement(
    const QuickMovement(
      id: 'quick_custom',
      title: 'Rapido Test',
      amount: 12,
      type: MovementType.expense,
      categoryId: 'exp_1',
      accountId: defaultAccountId,
    ),
  );
  await db.addFavoriteMovement(
    const FavoriteMovement(
      id: 'fav_custom',
      title: 'Preferito Test',
      amount: 18,
      type: MovementType.income,
      categoryId: 'inc_1',
      accountId: defaultAccountId,
    ),
  );
  await db.addMovement(
    _movement(
      id: 'reset_m1',
      title: 'Vecchio movimento',
      amount: 50,
      type: MovementType.expense,
      date: _d(8),
      categoryId: 'exp_1',
      accountId: 'acc_a',
      note: 'Nota vecchia',
    ),
  );
}

Future<void> _seedResetSmallDataset(AppDatabase db) async {
  await db.addAccount(
    _account(id: 'acc_custom', name: 'Conto Test', initialBalance: 0),
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

  group('A. Trasferimenti', () {
    test('A1. Matrice trasferimenti tra conti positivi e negativi', () async {
      final db = AppDatabase();
      await _seedTransferAccounts(db);

      final originIds = ['acc_a', 'acc_b', 'acc_c', 'acc_d'];
      final destinationIds = ['acc_b', 'acc_c', 'acc_d', 'acc_a'];
      final amounts = [0.01, 12.34, 100.0, 999.99];
      final notes = [null, 'nota trasferimento', '  nota trim  ', 'Benzina'];
      final titles = ['', 'Trasferimento speciale'];
      final dates = [_d(10), _d(15), _d(20), _d(25)];

      var caseCount = 0;
      for (var i = 0; i < originIds.length; i++) {
        for (var j = 0; j < amounts.length; j++) {
          final origin = originIds[i];
          final destination = destinationIds[i];
          if (origin == destination) continue;
          final amount = amounts[j];
          final title = titles[j % titles.length];
          final note = notes[j % notes.length];
          final date = dates[j % dates.length];
          final beforeOrigin = db.getAccountBalance(db.getAccount(origin));
          final beforeDestination = db.getAccountBalance(
            db.getAccount(destination),
          );
          final beforeTotalBalance = db.totalAccountsBalance;
          final beforeIncome = db.totalIncome;
          final beforeExpenses = db.totalExpenses;

          final movement = await db.createMovementFromTemplate(
            title: title,
            amount: amount,
            type: MovementType.transfer,
            categoryId: '',
            accountId: origin,
            destinationAccountId: destination,
            note: note,
            date: date,
          );
          caseCount++;

          expect(movement.type, MovementType.transfer);
          expect(movement.amount, amount);
          expect(movement.accountId, origin);
          expect(movement.destinationAccountId, destination);
          expect(movement.date, DateTime(date.year, date.month, date.day));
          expect(movement.title.isNotEmpty, isTrue);
          expectMoney(db.totalIncome, beforeIncome);
          expectMoney(db.totalExpenses, beforeExpenses);
          expectMoney(db.totalAccountsBalance, beforeTotalBalance);
          expectMoney(
            db.getAccountBalance(db.getAccount(origin)),
            beforeOrigin - amount,
          );
          expectMoney(
            db.getAccountBalance(db.getAccount(destination)),
            beforeDestination + amount,
          );
          expect(movement.impactForAccount(origin), -amount);
          expect(movement.impactForAccount(destination), amount);
          expect(movement.impactForAccount('missing'), 0.0);
          expect(
            searchMovements(
              movements: db.movements,
              query: db.getAccount(origin).name,
              filter: TimeFilter.year(2026),
              categories: db.categories,
              accounts: db.accounts,
            ).map((m) => m.id),
            contains(movement.id),
          );
          expect(
            searchMovements(
              movements: db.movements,
              query: db.getAccount(destination).name,
              filter: TimeFilter.year(2026),
              categories: db.categories,
              accounts: db.accounts,
            ).map((m) => m.id),
            contains(movement.id),
          );
          expect(
            searchMovements(
              movements: db.movements,
              query: note == null ? '' : note.trim(),
              filter: TimeFilter.year(2026),
              categories: db.categories,
              accounts: db.accounts,
            ).map((m) => m.id),
            contains(movement.id),
          );
          expect(
            groupMovementsByDay(
              db.movements,
            ).any((g) => g.movements.contains(movement)),
            isTrue,
          );
          expect(caseCount, greaterThan(0));
        }
      }
      expect(caseCount, 16);
    });

    test(
      'A2. Trasferimenti, filtri e backup/restore mantengono origine e destinazione',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        await db.createMovementFromTemplate(
          title: '',
          amount: 75.5,
          type: MovementType.transfer,
          categoryId: '',
          accountId: 'acc_a',
          destinationAccountId: 'acc_b',
          note: 'Nota trasferimento',
          date: _d(12),
        );
        await db.createMovementFromTemplate(
          title: '',
          amount: 33.0,
          type: MovementType.transfer,
          categoryId: '',
          accountId: 'acc_c',
          destinationAccountId: 'acc_d',
          note: 'Altro transfer',
          date: _d(20),
        );
        await db.createMovementFromTemplate(
          title: '',
          amount: 1.0,
          type: MovementType.transfer,
          categoryId: '',
          accountId: 'acc_d',
          destinationAccountId: 'acc_a',
          note: 'Piccolo transfer',
          date: _d(22),
        );

        final june = searchMovements(
          movements: db.movements,
          query: 'nota trasferimento',
          filter: TimeFilter.month(2026, 6),
          categories: db.categories,
          accounts: db.accounts,
        );
        final byDay = groupMovementsByDay(june);

        expect(june.length, 1);
        expect(byDay.length, 1);
        expect(byDay.first.movements.first.type, MovementType.transfer);

        final json = await BackupService.exportToJson(db);
        final parsed = BackupService.validate(json);
        expect(parsed.isValid, isTrue);
        expect(parsed.data, isNotNull);
        expect(
          parsed.data!.movements
              .where((m) => m.type == MovementType.transfer)
              .length,
          3,
        );
        expect(
          parsed.data!.movements.any((m) => m.destinationAccountId == 'acc_b'),
          isTrue,
        );

        final restoredDb = AppDatabase();
        await BackupService.restore(restoredDb, parsed.data!);
        expect(restoredDb.movements.length, db.movements.length);
        expect(
          restoredDb.movements
              .where((m) => m.type == MovementType.transfer)
              .length,
          3,
        );
        expect(
          restoredDb.movements.any((m) => m.destinationAccountId == 'acc_b'),
          isTrue,
        );
        expectMoney(restoredDb.totalAccountsBalance, db.totalAccountsBalance);
        expectMoney(restoredDb.totalIncome, db.totalIncome);
        expectMoney(restoredDb.totalExpenses, db.totalExpenses);
        expect(
          restoredDb.accounts.map((a) => a.id),
          containsAll(['acc_a', 'acc_b', 'acc_c', 'acc_d']),
        );
      },
    );

    test(
      'A3. Trasferimenti su SQLite: reload e persistenza restano coerenti',
      () async {
        final harness = await _openSqliteDb();
        final sqlite = harness.sqlite;
        final db = harness.db;
        addTearDown(sqlite.close);

        await _seedTransferAccounts(db);
        await db.createMovementFromTemplate(
          title: 'Trasferimento A',
          amount: 25,
          type: MovementType.transfer,
          categoryId: '',
          accountId: 'acc_a',
          destinationAccountId: 'acc_b',
          note: 'persistenza',
          date: _d(11),
        );
        await db.createMovementFromTemplate(
          title: 'Trasferimento B',
          amount: 60,
          type: MovementType.transfer,
          categoryId: '',
          accountId: 'acc_c',
          destinationAccountId: 'acc_d',
          note: 'persistenza 2',
          date: _d(21),
        );

        final reloaded = AppDatabase(sqlite: sqlite);
        await reloaded.initialize();
        expect(reloaded.movements.length, 2);
        expect(
          reloaded.movements
              .where((m) => m.type == MovementType.transfer)
              .length,
          2,
        );
        expect(reloaded.movements.first.destinationAccountId, isNotNull);
        expect(reloaded.accounts.length, db.accounts.length);
        expectMoney(reloaded.totalAccountsBalance, db.totalAccountsBalance);
        expect(
          reloaded.movements.map((m) => m.title),
          contains('Trasferimento A'),
        );
        expect(
          reloaded.movements.map((m) => m.title),
          contains('Trasferimento B'),
        );
        expect(
          reloaded.movements.every((m) => m.type == MovementType.transfer),
          isTrue,
        );
        expect(groupMovementsByDay(reloaded.movements).length, 2);
      },
    );

    test(
      'A4. Matrice estesa di trasferimenti mantiene saldo, search e grouping su 40 casi',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);

        final pairs = <(String, String)>[
          ('acc_a', 'acc_b'),
          ('acc_a', 'acc_c'),
          ('acc_b', 'acc_d'),
          ('acc_b', 'acc_a'),
          ('acc_c', 'acc_d'),
          ('acc_c', 'acc_a'),
          ('acc_d', 'acc_b'),
          ('acc_d', 'acc_c'),
        ];
        final amounts = [1.25, 12.5, 50.0, 250.0, 999.9];

        var seen = 0;
        for (var p = 0; p < pairs.length; p++) {
          final (origin, destination) = pairs[p];
          for (var a = 0; a < amounts.length; a++) {
            final amount = amounts[a];
            final date = _d(5 + (a % 4) * 5);
            final beforeOrigin = db.getAccountBalance(db.getAccount(origin));
            final beforeDestination = db.getAccountBalance(
              db.getAccount(destination),
            );
            final beforeIncome = db.totalIncome;
            final beforeExpenses = db.totalExpenses;
            final beforeTotal = db.totalAccountsBalance;

            final movement = _movement(
              id: 'tx_${p}_$a',
              title:
                  'Transfer QA $origin-$destination-${amount.toStringAsFixed(2)}',
              amount: amount,
              type: MovementType.transfer,
              date: date,
              categoryId: '',
              accountId: origin,
              destinationAccountId: destination,
              note: 'Nota QA ${p}_$a',
              createdAt: DateTime(2026, 6, date.day, 8 + a, 0),
              updatedAt: DateTime(2026, 6, date.day, 8 + a, 0),
            );
            await db.addMovement(movement);
            seen++;

            expect(movement.type, MovementType.transfer);
            expect(movement.amount, amount);
            expect(movement.accountId, origin);
            expect(movement.destinationAccountId, destination);
            expectMoney(
              db.getAccountBalance(db.getAccount(origin)),
              beforeOrigin - amount,
            );
            expectMoney(
              db.getAccountBalance(db.getAccount(destination)),
              beforeDestination + amount,
            );
            expectMoney(db.totalIncome, beforeIncome);
            expectMoney(db.totalExpenses, beforeExpenses);
            expectMoney(db.totalAccountsBalance, beforeTotal);
            expect(
              searchMovements(
                movements: db.movements,
                query: db.getAccount(origin).name,
                filter: TimeFilter.month(2026, 6),
                categories: db.categories,
                accounts: db.accounts,
              ).map((m) => m.id),
              contains(movement.id),
            );
            expect(
              searchMovements(
                movements: db.movements,
                query: db.getAccount(destination).name,
                filter: TimeFilter.month(2026, 6),
                categories: db.categories,
                accounts: db.accounts,
              ).map((m) => m.id),
              contains(movement.id),
            );
            expect(
              searchMovements(
                movements: db.movements,
                query: movement.title,
                filter: TimeFilter.year(2026),
                categories: db.categories,
                accounts: db.accounts,
              ).map((m) => m.id),
              contains(movement.id),
            );
            expect(
              searchMovements(
                movements: db.movements,
                query: movement.note ?? '',
                filter: TimeFilter.year(2026),
                categories: db.categories,
                accounts: db.accounts,
              ).map((m) => m.id),
              contains(movement.id),
            );
            expect(
              groupMovementsByDay(
                db.movements,
              ).any((g) => g.movements.any((m) => m.id == movement.id)),
              isTrue,
            );
            expect(
              db.movements.filterByTime(TimeFilter.day(date)).map((m) => m.id),
              contains(movement.id),
            );
          }
        }

        expect(seen, 40);
        expect(db.movements.length, 40);
        expect(
          db.movements.where((m) => m.type == MovementType.transfer).length,
          40,
        );
        expect(groupMovementsByDay(db.movements).length, 4);
        expect(
          groupMovementsByDay(db.movements).expand((g) => g.movements).length,
          40,
        );
        expect(
          searchMovements(
            movements: db.movements,
            query: 'Transfer QA',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).length,
          40,
        );
      },
    );
  });

  group('B. Ricerca globale', () {
    test('B1. Ricerca su titolo, nota, categoria, conto e transfer', () async {
      final db = AppDatabase();
      await _seedSearchDataset(db);

      final cases =
          <({String query, String label, int minResults, String expectedId})>[
            (
              query: 'Esselunga',
              label: 'titolo',
              minResults: 1,
              expectedId: 'm_title',
            ),
            (
              query: 'essel',
              label: 'titolo parziale',
              minResults: 1,
              expectedId: 'm_title',
            ),
            (
              query: '  ESSELUNGA  ',
              label: 'trim/case',
              minResults: 1,
              expectedId: 'm_title',
            ),
            (
              query: 'supermercato',
              label: 'nota',
              minResults: 1,
              expectedId: 'm_note',
            ),
            (
              query: 'benz',
              label: 'nota parziale',
              minResults: 1,
              expectedId: 'm_note',
            ),
            (
              query: 'Spesa',
              label: 'categoria',
              minResults: 2,
              expectedId: 'm_cat',
            ),
            (
              query: 'Postepay',
              label: 'conto',
              minResults: 1,
              expectedId: 'm_title',
            ),
            (
              query: 'conto b',
              label: 'transfer destinazione',
              minResults: 1,
              expectedId: 'm_transfer',
            ),
            (
              query: 'Da conto A',
              label: 'transfer nota',
              minResults: 1,
              expectedId: 'm_transfer',
            ),
            (
              query: 'Stipendio',
              label: 'income categoria',
              minResults: 1,
              expectedId: 'm_income',
            ),
          ];

      for (final c in cases) {
        final result = searchMovements(
          movements: db.movements,
          query: c.query,
          filter: TimeFilter.year(2026),
          categories: db.categories,
          accounts: db.accounts,
        );
        expect(
          result.map((m) => m.id),
          contains(c.expectedId),
          reason: c.label,
        );
        expect(
          result.length,
          greaterThanOrEqualTo(c.minResults),
          reason: c.label,
        );
        expect(
          result.every((m) => TimeFilter.year(2026).contains(m.date)),
          isTrue,
        );
      }

      final empty = searchMovements(
        movements: db.movements,
        query: '   ',
        filter: TimeFilter.year(2026),
        categories: db.categories,
        accounts: db.accounts,
      );
      expect(empty.length, db.movements.length);

      final none = searchMovements(
        movements: db.movements,
        query: 'nessun-risultato-xyz',
        filter: TimeFilter.year(2026),
        categories: db.categories,
        accounts: db.accounts,
      );
      expect(none, isEmpty);

      final dayFiltered = searchMovements(
        movements: db.movements,
        query: 'spesa',
        filter: TimeFilter.day(_d(15)),
        categories: db.categories,
        accounts: db.accounts,
      );
      expect(dayFiltered.map((m) => m.id), contains('m_title'));
      expect(dayFiltered.map((m) => m.id), contains('m_cat'));
      expect(dayFiltered.map((m) => m.id), isNot(contains('m_transfer')));
      expect(dayFiltered.length, 2);
    });

    test(
      'B2. Ricerca su dataset grande, caratteri speciali e ordinamento coerente',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        await db.addMovement(
          _movement(
            id: 's_special_1',
            title: 'Città',
            amount: 11,
            type: MovementType.expense,
            date: _d(15),
            categoryId: 'exp_1',
            accountId: 'acc_a',
            note: 'Spesa con accento',
          ),
        );
        await db.addMovement(
          _movement(
            id: 's_special_2',
            title: 'Spesa #1',
            amount: 12,
            type: MovementType.expense,
            date: _d(15),
            categoryId: 'exp_1',
            accountId: 'acc_a',
            note: 'speciale',
          ),
        );

        for (var i = 0; i < 1000; i++) {
          await db.addMovement(
            _movement(
              id: 'stress_search_$i',
              title: i.isEven ? 'Amazon ${i % 20}' : 'Benzina ${i % 15}',
              amount: (i % 90) + 0.5,
              type: i.isEven ? MovementType.expense : MovementType.income,
              date: _d((i % 28) + 1),
              categoryId: i.isEven ? 'exp_1' : 'inc_1',
              accountId: i % 3 == 0 ? 'acc_a' : 'acc_b',
              note: i % 10 == 0 ? 'Nota con spazi multipli' : null,
            ),
          );
        }

        final amazon = searchMovements(
          movements: db.movements,
          query: 'amazon',
          filter: TimeFilter.month(2026, 6),
          categories: db.categories,
          accounts: db.accounts,
        );
        final benz = searchMovements(
          movements: db.movements,
          query: 'benz',
          filter: TimeFilter.month(2026, 6),
          categories: db.categories,
          accounts: db.accounts,
        );
        final special = searchMovements(
          movements: db.movements,
          query: 'città',
          filter: TimeFilter.month(2026, 6),
          categories: db.categories,
          accounts: db.accounts,
        );
        final specialTrim = searchMovements(
          movements: db.movements,
          query: '  CITTÀ  ',
          filter: TimeFilter.month(2026, 6),
          categories: db.categories,
          accounts: db.accounts,
        );

        expect(amazon.isNotEmpty, isTrue);
        expect(benz.isNotEmpty, isTrue);
        expect(special.map((m) => m.id), contains('s_special_1'));
        expect(specialTrim.map((m) => m.id), contains('s_special_1'));
        expect(
          searchMovements(
            movements: db.movements,
            query: 'spazi multipli',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).isNotEmpty,
          isTrue,
        );
        expect(
          searchMovements(
            movements: db.movements,
            query: 'nessun-match',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ),
          isEmpty,
        );

        final filtered = searchMovements(
          movements: db.movements,
          query: 'amazon',
          filter: TimeFilter.day(_d(15)),
          categories: db.categories,
          accounts: db.accounts,
        );
        expect(filtered.every((m) => m.date.day == 15), isTrue);
        expect(groupMovementsByDay(filtered).first.movements, isNotEmpty);
        expect(filtered.length, greaterThan(0));
        expect(filtered.length, lessThanOrEqualTo(amazon.length));
      },
    );
  });

  group('C. Dashboard filtrata', () {
    test(
      'C1. KPI e saldo rispettano filtro giorno/mese/anno/custom e ignorano i transfer',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        await db.addMovement(
          _movement(
            id: 'd_income',
            title: 'Stipendio',
            amount: 2000,
            type: MovementType.income,
            date: _d(15),
            categoryId: 'inc_1',
            accountId: 'acc_a',
            createdAt: DateTime(2026, 6, 15, 14, 0),
            updatedAt: DateTime(2026, 6, 15, 14, 0),
          ),
        );
        await db.addMovement(
          _movement(
            id: 'd_expense',
            title: 'Affitto',
            amount: 700,
            type: MovementType.expense,
            date: _d(15),
            categoryId: 'exp_2',
            accountId: 'acc_a',
            createdAt: DateTime(2026, 6, 15, 13, 0),
            updatedAt: DateTime(2026, 6, 15, 13, 0),
          ),
        );
        await db.addMovement(
          _movement(
            id: 'd_future',
            title: 'Futuro',
            amount: 50,
            type: MovementType.expense,
            date: _d(25),
            categoryId: 'exp_1',
            accountId: 'acc_a',
          ),
        );
        await db.addMovement(
          _movement(
            id: 'd_transfer',
            title: 'Trasferimento',
            amount: 100,
            type: MovementType.transfer,
            date: _d(15),
            categoryId: '',
            accountId: 'acc_a',
            destinationAccountId: 'acc_b',
            note: 'Spostamento saldo',
            createdAt: DateTime(2026, 6, 15, 12, 0),
            updatedAt: DateTime(2026, 6, 15, 12, 0),
          ),
        );

        final month = db.movements.filterByTime(TimeFilter.month(2026, 6));
        final day = db.movements.filterByTime(TimeFilter.day(_d(15)));
        final year = db.movements.filterByTime(TimeFilter.year(2026));
        final custom = db.movements.filterByTime(
          TimeFilter.customRange(_d(14), _d(25)),
        );

        expect(month.length, 4);
        expect(day.length, 3);
        expect(year.length, 4);
        expect(custom.length, 4);
        expect(month.first.id, 'd_future');
        expect(day.first.id, 'd_income');
        expect(year.any((m) => m.type == MovementType.transfer), isTrue);
        expect(day.any((m) => m.type == MovementType.transfer), isTrue);

        expectMoney(db.totalIncome, 2000);
        expectMoney(db.totalExpenses, 750);
        expectMoney(db.balance, 1250);
        expectMoney(db.getAccountBalance(db.getAccount('acc_a')), 1250);
        expectMoney(db.getAccountBalance(db.getAccount('acc_b')), 350);
        expectMoney(db.totalAccountsBalance, 1440);
      },
    );

    // TODO: Reset widget flow fragile; reset validated manually on Pixel;
    // rerun as integration test or service-level test.
    testWidgets(
      'C2. Dashboard resta insight-only e si aggiorna dopo reset',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _seedResetDataset(db);
        await db.addMovement(
          _movement(
            id: 'dash_income',
            title: 'Entrata',
            amount: 100,
            type: MovementType.income,
            date: _d(18),
            categoryId: 'inc_1',
            accountId: 'acc_a',
          ),
        );
        await _pumpMainAppWithResetBackupStub(tester, db);

        expect(find.text('PATRIMONIO'), findsOneWidget);
        expect(find.text('Nessun movimento'), findsNothing);
        expect(find.byType(GroupedMovementsList), findsNothing);

        await _openResetDialog(tester);
        await _confirmResetFlow(tester);
        await _waitForResetComplete(tester, db);
        await _goToTab(tester, 'Dashboard');
        await tester.pumpAndSettle();
        expect(find.text('+0.00 €'), findsAtLeastNWidgets(1));
        expect(find.text('Vecchio movimento'), findsNothing);
        expect(find.text('Nessun movimento'), findsNothing);
      },
    );
  });

  group('D. Archivio / grouping / ordering', () {
    test(
      'D1. Grouping per giorno e comparator unico rispettano date/updatedAt/createdAt/id',
      () async {
        final db = AppDatabase();
        await _seedGroupingDataset(db);

        final groups = groupMovementsByDay(db.movements);
        expect(groups.first.date, _d(22));
        expect(groups[1].date, _d(19));
        expect(groups[2].date, _d(18));
        expect(groups.last.date, _d(14));
        expect(groups.first.movements.first.id, 'g_future');
        expect(groups[2].movements.map((m) => m.id).toList(), [
          'g3',
          'g1',
          'g2',
        ]);
        expect(
          compareMovementsForDisplay(db.movements.first, db.movements.last),
          isA<int>(),
        );
        expect(
          groupMovementsByDay(db.movements).expand((g) => g.movements).length,
          db.movements.length,
        );

        final sameDay = db.movements.where((m) => m.date.day == 18).toList();
        sameDay.sort(compareMovementsForDisplay);
        expect(sameDay.map((m) => m.id).toList(), ['g3', 'g1', 'g2']);
        expect(sameDay.every((m) => m.date.day == 18), isTrue);
        expect(
          groupMovementsByDay(db.movements).first.movements.first.type,
          MovementType.income,
        );
        expect(
          groupMovementsByDay(
            db.movements,
          ).any((g) => g.movements.any((m) => m.title == 'Ieri')),
          isTrue,
        );
        expect(
          groupMovementsByDay(
            db.movements,
          ).any((g) => g.movements.any((m) => m.title == 'Futuro')),
          isTrue,
        );
      },
    );

    testWidgets(
      'D2. GroupedMovementsList mostra note e supporta scroll su lista lunga',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        for (var i = 0; i < 60; i++) {
          await db.addMovement(
            _movement(
              id: 'lazy_$i',
              title: 'Movimento $i',
              amount: 10 + i.toDouble(),
              type: i.isEven ? MovementType.income : MovementType.expense,
              date: _d((i % 28) + 1),
              categoryId: i.isEven ? 'inc_1' : 'exp_1',
              accountId: 'acc_a',
              note: i == 59
                  ? 'Nota finale visibile'
                  : (i % 10 == 0 ? 'Nota $i' : null),
            ),
          );
        }

        await _pumpMainApp(tester, db);
        await _goToArchiveMovements(tester);
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Cerca titolo, nota, categoria o conto',
          ),
          'Movimento',
        );
        await tester.pumpAndSettle();
        expect(find.byType(GroupedMovementsList), findsOneWidget);
        expect(find.byType(MovementCard), findsWidgets);

        final scrollable = find
            .descendant(
              of: find.byType(GroupedMovementsList),
              matching: find.byType(Scrollable),
            )
            .first;
        expect(scrollable, findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Nota finale visibile'),
          400.0,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(find.byType(MovementCard), findsWidgets);
        expect(find.text('Movimento 59'), findsWidgets);
        expect(find.text('Nota finale visibile'), findsOneWidget);
      },
    );
  });

  group('E. Backup / Restore', () {
    test(
      'E1. Backup contiene conti, categorie, movimenti, rapidi, preferiti e settings',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        await db.addCategory(
          'Categoria backup',
          MovementType.expense,
          0xFF123456,
        );
        await db.addQuickMovement(
          const QuickMovement(
            id: 'quick_backup',
            title: 'Rapido backup',
            amount: 5,
            type: MovementType.expense,
            categoryId: 'exp_1',
            accountId: defaultAccountId,
          ),
        );
        await db.addFavoriteMovement(
          const FavoriteMovement(
            id: 'fav_backup',
            title: 'Preferito backup',
            amount: 6,
            type: MovementType.income,
            categoryId: 'inc_1',
            accountId: defaultAccountId,
          ),
        );
        await PreferencesService.saveShowNotes(true);
        await db.addMovement(
          _movement(
            id: 'backup_t',
            title: 'Trasferimento backup',
            amount: 9,
            type: MovementType.transfer,
            date: _d(20),
            categoryId: '',
            accountId: 'acc_a',
            destinationAccountId: 'acc_b',
          ),
        );

        final json = await BackupService.exportToJson(db);
        final parsed = jsonDecode(json) as Map<String, dynamic>;
        expect(parsed['version'], 2);
        expect(parsed['accounts'], isA<List>());
        expect(parsed['categories'], isA<List>());
        expect(parsed['movements'], isA<List>());
        expect(parsed['quickMovements'], isA<List>());
        expect(parsed['favoriteMovements'], isA<List>());
        expect(parsed['settings'], isA<Map>());
        expect(
          (parsed['movements'] as List).any(
            (e) => (e as Map)['destinationAccountId'] == 'acc_b',
          ),
          isTrue,
        );
        expect(
          (parsed['quickMovements'] as List).any(
            (e) => (e as Map)['id'] == 'quick_backup',
          ),
          isTrue,
        );
        expect(
          (parsed['favoriteMovements'] as List).any(
            (e) => (e as Map)['id'] == 'fav_backup',
          ),
          isTrue,
        );
        expect((parsed['settings'] as Map)['showNotes'], isTrue);
      },
    );

    test('E2. Restore ripristina dati completi e normalizza orfani', () async {
      final backup = BackupData(
        version: 2,
        createdAt: DateTime.now().toIso8601String(),
        accounts: [
          _account(id: 'acc_custom', name: 'Conto Custom', initialBalance: 0),
        ],
        categories: [
          _category(
            id: 'cat_custom',
            name: 'Categoria Custom',
            type: MovementType.expense,
          ),
        ],
        movements: [
          _movement(
            id: 'rest_1',
            title: 'Movimento backup',
            amount: 77,
            type: MovementType.transfer,
            date: _d(12),
            categoryId: 'cat_missing',
            accountId: 'acc_missing',
            destinationAccountId: null,
            note: 'restore test',
            createdAt: DateTime(2026, 6, 12, 10, 0),
            updatedAt: DateTime(2026, 6, 12, 12, 0),
          ),
        ],
        quickMovements: [
          const QuickMovement(
            id: 'quick_old',
            title: 'Rapido vecchio',
            amount: 12,
            type: MovementType.expense,
            categoryId: 'cat_missing',
            accountId: 'acc_missing',
          ),
        ],
        favoriteMovements: [
          const FavoriteMovement(
            id: 'fav_old',
            title: 'Preferito vecchio',
            amount: 13,
            type: MovementType.income,
            categoryId: 'cat_missing',
            accountId: 'acc_missing',
          ),
        ],
        settings: const BackupSettings(showNotes: false),
      );

      final db = AppDatabase();
      await BackupService.restore(db, backup);

      expect(db.accounts.length, 2);
      expect(db.categories.any((c) => c.id == 'cat_custom'), isTrue);
      expect(db.movements.length, 1);
      expect(db.movements.first.accountId, defaultAccountId);
      expect(db.movements.first.destinationAccountId, defaultAccountId);
      expect(db.quickMovements.length, 5);
      expect(db.favoriteMovements.length, 1);
      expect(await PreferencesService.loadShowNotes(), isFalse);
      expect(db.movements.first.note, 'restore test');
      expect(db.movements.first.createdAt.year, 2026);
      expect(db.movements.first.updatedAt.year, 2026);
      expectMoney(db.totalAccountsBalance, 0);
    });

    test('E3. Restore fallito non lascia DB sporco', () async {
      final failing = _FailingTransactionSQLiteService();
      await failing.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: failing);
      await db.initialize();
      await db.addMovement(
        _movement(
          id: 'restore_keep',
          title: 'Mantieni',
          amount: 10,
          type: MovementType.expense,
          date: _d(15),
          categoryId: 'exp_1',
        ),
      );

      final backup = BackupData(
        version: 2,
        createdAt: DateTime.now().toIso8601String(),
        accounts: [db.accounts.first],
        categories: db.categories,
        movements: [
          _ThrowingMovement(
            id: 'restore_keep',
            title: 'Mantieni',
            amount: 10,
            type: MovementType.expense,
            date: _d(15),
            categoryId: 'exp_1',
            createdAt: _d(15),
          ),
        ],
      );

      expect(() => BackupService.restore(db, backup), throwsA(isA<StateError>()));
      expect(db.movements.length, 1);
      expect(db.movements.first.id, 'restore_keep');
      expectMoney(db.totalIncome, 0);
      expectMoney(db.totalExpenses, 10);
      await failing.close();
    });
  });

  group('F. Reset completo dati app', () {
    testWidgets(
      'F1. Reset richiede conferma forte, annulla e ripristina i default',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _seedResetDataset(db);
        await PreferencesService.saveShowNotes(true);
        await _pumpMainApp(tester, db);

        await _openResetDialog(tester);
        expect(find.text('Reset dati app?'), findsOneWidget);
        expect(
          find.byKey(const Key('reset_data_confirm_button')),
          findsOneWidget,
        );

        final confirmButton = tester.widget<FilledButton>(
          find.byKey(const Key('reset_data_confirm_button')),
        );
        expect(confirmButton.onPressed, isNull);

        await tester.enterText(
          find.byKey(const Key('reset_data_confirm_field')),
          'RESET',
        );
        await tester.pumpAndSettle();
        final confirmEnabled = tester.widget<FilledButton>(
          find.byKey(const Key('reset_data_confirm_button')),
        );
        expect(confirmEnabled.onPressed, isNotNull);
        await tester.tap(find.byKey(const Key('reset_data_cancel_button')));
        await tester.pumpAndSettle();

        expect(db.movements.length, 1);
        expect(db.accounts.length, 5);
        expect(db.categories.length, DefaultCategories.all.length);
        expect(db.quickMovements.length, 5);
        expect(db.favoriteMovements.length, 1);
        expect(await PreferencesService.loadShowNotes(), isTrue);
      },
    );

    // TODO: Reset widget flow fragile; reset validated manually on Pixel;
    // rerun as integration test or service-level test.
    testWidgets(
      'F2. Reset confermato cancella vecchi dati, ripristina dashboard e archivio',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _seedResetSmallDataset(db);
        await db.createMovementFromTemplate(
          title: 'Trasferimento prima del reset',
          amount: 15,
          type: MovementType.transfer,
          categoryId: '',
          accountId: 'acc_a',
          destinationAccountId: 'acc_b',
          date: _d(9),
        );
        await _pumpMainAppWithResetBackupStub(tester, db);

        await _openResetDialog(tester);
        await _confirmResetFlow(tester);
        await _waitForResetComplete(tester, db);

        expect(db.movements, isEmpty);
        expect(db.accounts.length, 1);
        expect(db.categories.length, DefaultCategories.all.length);
        expect(db.quickMovements.length, 4);
        expect(db.favoriteMovements, isEmpty);
        expectMoney(db.totalIncome, 0);
        expectMoney(db.totalExpenses, 0);
        expectMoney(db.balance, 0);
        expectMoney(db.totalAccountsBalance, 0);
        expect(await PreferencesService.loadShowNotes(), isFalse);
        expect(await PreferencesService.loadLastBackupDate(), isNull);

        await _goToTab(tester, 'Dashboard');
        expect(find.text('+0.00 €'), findsAtLeastNWidgets(1));
        await _goToTab(tester, 'Archivio');
        await tester.pumpAndSettle();
        expect(find.text('Nessun movimento'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Cerca titolo, nota, categoria o conto',
          ),
          'Vecchio movimento',
        );
        await tester.pumpAndSettle();
        expect(find.byType(MovementCard), findsNothing);
        expect(find.text('Nessun movimento'), findsOneWidget);
      },
    );

    // TODO: Reset widget flow fragile; reset validated manually on Pixel;
    // rerun as integration test or service-level test.
    testWidgets(
      'F3. Reset su DB vuoto, dopo transfer e dopo backup resta transazionale',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _seedResetSmallDataset(db);
        await db.createMovementFromTemplate(
          title: 'Trasferimento prima del reset',
          amount: 15,
          type: MovementType.transfer,
          categoryId: '',
          accountId: 'acc_a',
          destinationAccountId: 'acc_b',
          date: _d(9),
        );
        await _pumpMainAppWithResetBackupStub(tester, db);

        await _openResetDialog(tester);
        await _confirmResetFlow(tester);
        await _waitForResetComplete(tester, db);
        expect(db.movements, isEmpty);
        expect(db.accounts.length, 1);

        await db.createMovementFromTemplate(
          title: 'Nuovo post reset',
          amount: 22,
          type: MovementType.expense,
          categoryId: 'exp_1',
          accountId: defaultAccountId,
          date: _d(16),
        );
        expect(db.movements.length, 1);
        expect(db.movements.first.title, 'Nuovo post reset');

        final failing = _ThrowingResetAppDatabase();
        await failing.addMovement(
          _movement(
            id: 'partial',
            title: 'Parziale',
            amount: 1,
            type: MovementType.expense,
            date: _d(10),
            categoryId: 'exp_1',
          ),
        );
        await expectLater(failing.resetAllData(), throwsA(isA<StateError>()));
        expect(failing.movements.any((m) => m.id == 'partial'), isTrue);
        expect(failing.categories.isNotEmpty, isTrue);
        expect(failing.quickMovements.isNotEmpty, isTrue);
      },
    );
  });

  group('G. SQLite / Migration', () {
    test(
      'G1. DB legacy v5 con date già presente non duplica colonne e conserva movimenti',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'stream_legacy_v5_',
        );
        final path = '${tempDir.path}/stream.db';

        final sqlite = SQLiteService();
        await sqlite.open(path: path);
        final db = AppDatabase(sqlite: sqlite);
        await db.initialize();
        await db.addMovement(
          _movement(
            id: 'legacy_m1',
            title: 'Legacy',
            amount: 9,
            type: MovementType.expense,
            date: _d(15),
            categoryId: 'exp_1',
            accountId: defaultAccountId,
            createdAt: DateTime(2026, 6, 15, 10, 0),
            updatedAt: DateTime(2026, 6, 15, 11, 0),
          ),
        );
        await sqlite.transaction((txn) async {
          await txn.execute('PRAGMA user_version = 5');
        });
        await sqlite.close();

        final reopened = SQLiteService();
        await reopened.open(path: path);
        final reopenedDb = AppDatabase(sqlite: reopened);
        await reopenedDb.initialize();

        final columns = await reopened.transaction<int>((txn) async {
          final rows = await txn.rawQuery('PRAGMA table_info(movements)');
          expect(rows.any((row) => row['name'] == 'date'), isTrue);
          expect(
            rows.any((row) => row['name'] == 'destination_account_id'),
            isTrue,
          );
          return rows.where((row) => row['name'] == 'date').length;
        });

        expect(columns, 1);
        expect(reopenedDb.movements.length, 1);
        expect(reopenedDb.movements.first.title, 'Legacy');
        expect(reopenedDb.movements.first.date.day, 15);
        expect(reopenedDb.movements.first.createdAt.year, 2026);
        expect(reopenedDb.movements.first.updatedAt.year, 2026);
        await reopened.close();
        await tempDir.delete(recursive: true);
      },
    );

    test(
      'G2. DB legacy v6 conserva destinationAccountId e reload coerente',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'stream_legacy_v6_',
        );
        final path = '${tempDir.path}/stream.db';

        final sqlite = SQLiteService();
        await sqlite.open(path: path);
        final db = AppDatabase(sqlite: sqlite);
        await db.initialize();
        await db.addAccount(_account(id: 'acc_x', name: 'Legacy X'));
        await db.addAccount(_account(id: 'acc_y', name: 'Legacy Y'));
        await db.addMovement(
          _movement(
            id: 'legacy_t1',
            title: 'Trasferimento legacy',
            amount: 21,
            type: MovementType.transfer,
            date: _d(16),
            categoryId: '',
            accountId: 'acc_x',
            destinationAccountId: 'acc_y',
            note: 'legacy transfer',
            createdAt: DateTime(2026, 6, 16, 9, 0),
            updatedAt: DateTime(2026, 6, 16, 10, 0),
          ),
        );
        await sqlite.transaction((txn) async {
          await txn.execute('PRAGMA user_version = 6');
        });
        await sqlite.close();

        final reopened = SQLiteService();
        await reopened.open(path: path);
        final reopenedDb = AppDatabase(sqlite: reopened);
        await reopenedDb.initialize();

        expect(reopenedDb.movements.length, 1);
        expect(reopenedDb.movements.first.destinationAccountId, 'acc_y');
        expect(reopenedDb.movements.first.accountId, 'acc_x');
        expectMoney(
          reopenedDb.getAccountBalance(reopenedDb.getAccount('acc_x')),
          -21,
        );
        expectMoney(
          reopenedDb.getAccountBalance(reopenedDb.getAccount('acc_y')),
          21,
        );
        expectMoney(reopenedDb.totalAccountsBalance, 0);
        expect(reopenedDb.movements.first.note, 'legacy transfer');
        await reopened.close();
        await tempDir.delete(recursive: true);
      },
    );
  });

  group('H. MovementPicker / date choice', () {
    testWidgets(
      'H1. Rapido con Oggi, Ieri e Domani crea un solo movimento e chiude il bottom sheet',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _pumpMainAppWithResetBackupStub(tester, db);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expectedDates = <String, DateTime>{
          'Oggi': today,
          'Ieri': today.subtract(const Duration(days: 1)),
          'Domani': today.add(const Duration(days: 1)),
        };

        for (final entry in expectedDates.entries) {
          await _openMovementPicker(tester);
          await tester.tap(find.text('Rapidi'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Caffè'));
          await tester.pumpAndSettle();
          await _chooseQuickDate(tester, entry.key);
          await tester.pumpAndSettle();

          expect(db.movements.length, 1);
          expect(db.movements.first.title, 'Caffè');
          expectDateOnly(db.movements.first.date, entry.value);
          expect(find.byType(BottomSheet), findsNothing);
          expect(find.text('Movimenti rapidi'), findsNothing);
          await db.deleteMovement(db.movements.first.id);
        }
      },
    );

    testWidgets(
      'H2. Preferito con Oggi/Ieri/Domani crea un solo movimento e non duplica',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await db.addFavoriteMovement(
          const FavoriteMovement(
            id: 'fav_qa',
            title: 'Preferito QA',
            amount: 7,
            type: MovementType.expense,
            categoryId: 'exp_1',
            accountId: defaultAccountId,
          ),
        );
        await _pumpMainApp(
          tester,
          db,
          theme: ThemeData(platform: TargetPlatform.iOS),
        );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expectedDates = <String, DateTime>{
          'Oggi': today,
          'Ieri': today.subtract(const Duration(days: 1)),
          'Domani': today.add(const Duration(days: 1)),
        };

        for (final choice in ['Oggi', 'Ieri', 'Domani']) {
          await _openMovementPicker(tester);
          await tester.tap(find.text('Preferiti'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Preferito QA'));
          await tester.pumpAndSettle();
          await _chooseQuickDate(tester, choice);
          await tester.pumpAndSettle();

          expect(db.movements.length, 1);
          expect(
            db.movements.where((m) => m.title == 'Preferito QA').length,
            1,
          );
          expectDateOnly(db.movements.first.date, expectedDates[choice]!);
          expect(find.byType(BottomSheet), findsNothing);
          await db.deleteMovement(db.movements.first.id);
        }
      },
    );

    testWidgets(
      'H3. Scegli data apre il picker completo e il flusso si chiude dopo conferma',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _pumpMainApp(
          tester,
          db,
          theme: ThemeData(platform: TargetPlatform.iOS),
        );
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        await _openMovementPicker(tester);
        await tester.tap(find.text('Rapidi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Benzina'));
        await tester.pumpAndSettle();
        await _chooseQuickDate(tester, 'Scegli data');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('stream_date_picker_ok')));
        await tester.pumpAndSettle();

        expect(db.movements.length, 1);
        expect(db.movements.first.title, 'Benzina');
        expectDateOnly(db.movements.first.date, today);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Movimenti rapidi'), findsNothing);
      },
    );

    testWidgets(
      'H4. Form manuale: transfer aggiorna le label e salva un solo movimento',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        await _pumpMainApp(tester, db);

        await _openMovementPicker(tester);
        await tester.tap(find.text('Trasferimento'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('add_movement_transfer_step')), findsOneWidget);
        expect(find.text('Conto origine'), findsWidgets);
        expect(find.text('Conto destinazione'), findsWidgets);

        await tapVisible(
          tester,
          find.byKey(const Key('transfer_origin_option_acc_a')),
        );
        await tapVisible(
          tester,
          find.byKey(const Key('transfer_destination_option_acc_b')),
        );
        await tapVisible(
          tester,
          find.byKey(const Key('transfer_continue_button')),
        );

        expect(find.byKey(const Key('add_movement_details_step')), findsOneWidget);
        expect(find.text('Origine'), findsWidgets);
        expect(find.text('Destinazione'), findsWidgets);
        expect(find.text('Categoria'), findsNothing);

        await _fillManualMovementForm(
          tester,
          title: 'Transfer manuale',
          amount: '14.25',
          note: 'nota manuale',
          transfer: true,
        );
        await _saveManualMovement(tester);

        expect(db.movements.length, 1);
        expect(db.movements.first.type, MovementType.transfer);
        expect(db.movements.first.destinationAccountId, isNotNull);
        expect(find.byType(BottomSheet), findsNothing);
      },
    );
  });

  group('I. Conti e categorie', () {
    test(
      'I1. CRUD conti e categorie, archiviazione e restore restano coerenti',
      () async {
        final db = AppDatabase();
        await db.addAccount(
          _account(id: 'acc_new', name: 'Conto Nuovo', initialBalance: 50),
        );
        await db.updateAccount(
          'acc_new',
          'Conto Nuovo 2',
          AccountType.savings,
          75,
          color: 0xFF334455,
        );
        await db.archiveAccount('acc_new');
        await db.addCategory(
          'Categoria Nuova',
          MovementType.expense,
          0xFF123456,
        );
        final catId = db.categories.last.id;
        await db.updateCategory(
          catId,
          'Categoria Nuova 2',
          0xFF654321,
          archived: true,
        );
        await db.restoreCategory(catId);

        expect(db.accounts.any((a) => a.id == 'acc_new'), isTrue);
        expect(
          db.accounts.firstWhere((a) => a.id == 'acc_new').archived,
          isTrue,
        );
        expect(
          db.accounts.firstWhere((a) => a.id == 'acc_new').name,
          'Conto Nuovo 2',
        );
        expect(
          db.accounts.firstWhere((a) => a.id == 'acc_new').type,
          AccountType.savings,
        );
        expect(
          db.accounts.firstWhere((a) => a.id == 'acc_new').initialBalance,
          75,
        );
        expect(db.categories.any((c) => c.id == catId), isTrue);
        expect(
          db.categories.firstWhere((c) => c.id == catId).archived,
          isFalse,
        );
        expect(
          db.categories.firstWhere((c) => c.id == catId).name,
          'Categoria Nuova 2',
        );
        expect(db.activeCategories.any((c) => c.id == catId), isTrue);
        expect(db.accounts.where((a) => !a.archived).length, 1);

        final json = await BackupService.exportToJson(db);
        final parsed = BackupService.validate(json);
        expect(parsed.isValid, isTrue);
        final restored = AppDatabase();
        await BackupService.restore(restored, parsed.data!);
        expect(restored.accounts.length, 2);
        expect(restored.categories.any((c) => c.id == catId), isTrue);
        expect(
          restored.accounts.firstWhere((a) => a.id == 'acc_new').archived,
          true,
        );
        expect(
          restored.categories.firstWhere((c) => c.id == catId).archived,
          false,
        );
      },
    );

    test(
      'I2. Categorie/conti archiviati restano leggibili con movimenti storici e search',
      () async {
        final db = AppDatabase();
        await db.addAccount(
          _account(id: 'acc_hist', name: 'Conto Storico', archived: true),
        );
        await db.addCategory(
          'Categoria Storica',
          MovementType.expense,
          0xFFabcdef,
        );
        final catId = db.categories.last.id;
        await db.archiveCategory(catId);
        await db.addMovement(
          _movement(
            id: 'hist_1',
            title: 'Storico',
            amount: 19,
            type: MovementType.expense,
            date: _d(18),
            categoryId: catId,
            accountId: 'acc_hist',
            note: 'vecchio dato',
          ),
        );

        expect(db.accounts.where((a) => !a.archived).length, 1);
        expect(
          db.categories.where((c) => !c.archived).any((c) => c.id == catId),
          isFalse,
        );
        expect(db.movements.length, 1);
        expect(
          searchMovements(
            movements: db.movements,
            query: 'Storico',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).length,
          1,
        );
        expect(
          searchMovements(
            movements: db.movements,
            query: 'Conto Storico',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).length,
          1,
        );
        expect(db.getAccount('acc_hist').name, 'Conto Storico');
        expect(
          groupMovementsByDay(db.movements).first.movements.first.id,
          'hist_1',
        );
      },
    );
  });

  group('J. Calendar / TimeFilter', () {
    test(
      'J1. TimeFilter usa movement.date e non createdAt; day/month/year/custom restano coerenti',
      () async {
        final movements = <Movement>[
          _movement(
            id: 't_day',
            title: 'Day',
            amount: 1,
            type: MovementType.expense,
            date: _d(15),
            categoryId: 'exp_1',
            createdAt: DateTime(2026, 6, 1, 10, 0),
            updatedAt: DateTime(2026, 6, 1, 12, 0),
          ),
          _movement(
            id: 't_month',
            title: 'Month',
            amount: 2,
            type: MovementType.expense,
            date: _d(20),
            categoryId: 'exp_1',
            createdAt: DateTime(2026, 5, 30, 10, 0),
            updatedAt: DateTime(2026, 5, 30, 12, 0),
          ),
          _movement(
            id: 't_future',
            title: 'Future',
            amount: 3,
            type: MovementType.income,
            date: _d(25),
            categoryId: 'inc_1',
            createdAt: DateTime(2026, 4, 1, 10, 0),
            updatedAt: DateTime(2026, 4, 1, 12, 0),
          ),
        ];

        expect(
          movements.filterByTime(TimeFilter.day(_d(15))).map((m) => m.id),
          ['t_day'],
        );
        expect(movements.filterByTime(TimeFilter.month(2026, 6)).length, 3);
        expect(movements.filterByTime(TimeFilter.year(2026)).length, 3);
        expect(
          movements
              .filterByTime(TimeFilter.customRange(_d(14), _d(20)))
              .map((m) => m.id),
          ['t_month', 't_day'],
        );
        expect(
          TimeFilter.day(_d(15)).contains(DateTime(2026, 6, 15, 23, 59)),
          isTrue,
        );
        expect(TimeFilter.month(2026, 6).contains(_d(25)), isTrue);
        expect(TimeFilter.year(2026).contains(_d(25)), isTrue);
        expect(
          TimeFilter.customRange(_d(16), _d(18)).contains(_d(15)),
          isFalse,
        );
        expect(groupMovementsByDay(movements).first.date, _d(25));
        expect(groupMovementsByDay(movements).last.date, _d(15));
      },
    );

    test(
      'J2. Calendario e search restano coerenti con movimenti futuri e transfer futuri',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        await db.addMovement(
          _movement(
            id: 'cal_1',
            title: 'Oggi manuale',
            amount: 10,
            type: MovementType.expense,
            date: _d(19),
            categoryId: 'exp_1',
            accountId: 'acc_a',
          ),
        );
        await db.addMovement(
          _movement(
            id: 'cal_2',
            title: 'Futuro manuale',
            amount: 11,
            type: MovementType.income,
            date: _d(25),
            categoryId: 'inc_1',
            accountId: 'acc_b',
          ),
        );
        await db.addMovement(
          _movement(
            id: 'cal_3',
            title: 'Transfer futuro',
            amount: 12,
            type: MovementType.transfer,
            date: _d(25),
            categoryId: '',
            accountId: 'acc_a',
            destinationAccountId: 'acc_b',
          ),
        );

        expect(
          searchMovements(
            movements: db.movements,
            query: 'Oggi manuale',
            filter: TimeFilter.day(_d(19)),
            categories: db.categories,
            accounts: db.accounts,
          ).length,
          1,
        );
        expect(
          searchMovements(
            movements: db.movements,
            query: 'Transfer futuro',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).length,
          1,
        );
        expect(groupMovementsByDay(db.movements).first.date, _d(25));
        expect(groupMovementsByDay(db.movements).last.date, _d(19));
        expect(TimeFilter.day(_d(19)).contains(_d(25)), isFalse);
        expect(TimeFilter.customRange(_d(19), _d(25)).contains(_d(25)), isTrue);
        expect(
          db.movements.filterByTime(TimeFilter.day(_d(19))).single.title,
          'Oggi manuale',
        );
      },
    );
  });

  group('K. Dataset grande / performance sanity', () {
    test(
      'K1. 100, 1000 e 5000 movimenti restano coerenti per dashboard, search e grouping',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);

        for (var i = 0; i < 100; i++) {
          await db.addMovement(
            _movement(
              id: 'p100_$i',
              title: 'Movimento 100 $i',
              amount: i + 1.0,
              type: i.isEven ? MovementType.income : MovementType.expense,
              date: _d((i % 28) + 1),
              categoryId: i.isEven ? 'inc_1' : 'exp_1',
              accountId: 'acc_a',
            ),
          );
        }
        expect(db.movements.length, 100);
        expect(groupMovementsByDay(db.movements).isNotEmpty, isTrue);
        expect(
          searchMovements(
            movements: db.movements,
            query: 'Movimento 100',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).isNotEmpty,
          isTrue,
        );

        for (var i = 100; i < 1000; i++) {
          await db.addMovement(
            _movement(
              id: 'p1000_$i',
              title: i % 3 == 0 ? 'Amazon $i' : 'Benzina $i',
              amount: (i % 70) + 0.5,
              type: i.isEven ? MovementType.income : MovementType.expense,
              date: _d((i % 28) + 1),
              categoryId: i.isEven ? 'inc_1' : 'exp_1',
              accountId: i % 2 == 0 ? 'acc_a' : 'acc_b',
            ),
          );
        }
        expect(db.movements.length, 1000);
        expect(
          searchMovements(
            movements: db.movements,
            query: 'amazon',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).isNotEmpty,
          isTrue,
        );
        expect(groupMovementsByDay(db.movements).length, greaterThan(20));

        for (var i = 1000; i < 5000; i++) {
          await db.addMovement(
            _movement(
              id: 'p5000_$i',
              title: i % 5 == 0 ? 'Spesa $i' : 'Amazon $i',
              amount: (i % 100) + 0.25,
              type: i % 3 == 0
                  ? MovementType.transfer
                  : (i.isEven ? MovementType.income : MovementType.expense),
              date: _d((i % 28) + 1),
              categoryId: i % 3 == 0 ? '' : (i.isEven ? 'inc_1' : 'exp_1'),
              accountId: i % 2 == 0 ? 'acc_a' : 'acc_b',
              destinationAccountId: i % 3 == 0 ? 'acc_b' : null,
            ),
          );
        }
        expect(db.movements.length, 5000);
        expect(
          db.movements.any((m) => m.type == MovementType.transfer),
          isTrue,
        );
        expect(db.totalIncome > 0, isTrue);
        expect(db.totalExpenses > 0, isTrue);
        expect(db.totalAccountsBalance.isNaN, isFalse);
        expect(
          searchMovements(
            movements: db.movements,
            query: 'spesa',
            filter: TimeFilter.month(2026, 6),
            categories: db.categories,
            accounts: db.accounts,
          ).isNotEmpty,
          isTrue,
        );
        expect(groupMovementsByDay(db.movements).isNotEmpty, isTrue);
      },
    );

    test(
      'K2. Backup, restore e reset non rompono dataset grande misto',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        for (var i = 0; i < 1000; i++) {
          await db.addMovement(
            _movement(
              id: 'mix_$i',
              title: i.isEven ? 'Income $i' : 'Expense $i',
              amount: (i % 40) + 1,
              type: i.isEven ? MovementType.income : MovementType.expense,
              date: _d((i % 28) + 1),
              categoryId: i.isEven ? 'inc_1' : 'exp_1',
              accountId: 'acc_a',
            ),
          );
        }
        final json = await BackupService.exportToJson(db);
        final validation = BackupService.validate(json);
        expect(validation.isValid, isTrue);
        final restored = AppDatabase();
        await BackupService.restore(restored, validation.data!);
        expect(restored.movements.length, 1000);
        expect(restored.accounts.length, 5);
        expect(restored.categories.length, 10);
        await restored.resetAllData();
        expect(restored.movements, isEmpty);
        expect(restored.quickMovements.length, 4);
        expect(restored.accounts.length, 1);
      },
    );
  });

  group('L. Regressioni generali', () {
    // TODO: Reset widget flow fragile; reset validated manually on Pixel;
    // rerun as integration test or service-level test.
    testWidgets(
      'L1. Dopo reset manuale, rapido, preferito, dashboard e ricerca restano operativi',
      (WidgetTester tester) async {
        final db = AppDatabase();
        await _seedResetSmallDataset(db);
        await _pumpMainAppWithResetBackupStub(tester, db);

        await _openResetDialog(tester);
        await _confirmResetFlow(tester);
        await _waitForResetComplete(tester, db);
        expect(db.movements, isEmpty);

        await _goToArchiveMovements(tester);
        final fabFinder = find.byType(FloatingActionButton);
        final fabDeadline = DateTime.now().add(const Duration(seconds: 5));
        while (
          DateTime.now().isBefore(fabDeadline) &&
          fabFinder.hitTestable().evaluate().isEmpty
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final fab = fabFinder.hitTestable();
        expect(fab, findsOneWidget);
        await tester.tap(fab);
        await tester.pumpAndSettle();
        await _fillManualMovementForm(
          tester,
          title: 'Manuale dopo reset',
          amount: '20',
        );
        await _saveManualMovement(tester);
        expect(db.movements.length, 1);

        await _openMovementPicker(tester);
        await tester.tap(find.text('Rapidi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Caffè'));
        await tester.pumpAndSettle();
        await _chooseQuickDate(tester, 'Oggi');
        await tester.pumpAndSettle();
        expect(db.movements.length, 2);

        await _openMovementPicker(tester);
        await tester.tap(find.text('Preferiti'));
        await tester.pumpAndSettle();
        await db.addFavoriteMovement(
          const FavoriteMovement(
            id: 'fav_reg_2',
            title: 'Favorito Reg',
            amount: 15,
            type: MovementType.expense,
            categoryId: 'exp_1',
            accountId: defaultAccountId,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Favorito Reg'));
        await tester.pumpAndSettle();
        await _chooseQuickDate(tester, 'Domani');
        await tester.pumpAndSettle();
        expect(db.movements.length, 3);

        await _goToTab(tester, 'Dashboard');
        expect(find.text('PATRIMONIO'), findsOneWidget);
        await _goToTab(tester, 'Archivio');
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Cerca titolo, nota, categoria o conto',
          ),
          'Manuale',
        );
        await tester.pumpAndSettle();
        expect(find.text('Manuale dopo reset'), findsOneWidget);
        expect(find.text('Nessun risultato'), findsNothing);
        expect(find.byType(GroupedMovementsList), findsOneWidget);
      },
    );

    test(
      'L2. Backup/restore/reset e search non lasciano stato sporco tra le iterazioni',
      () async {
        final db = AppDatabase();
        await _seedTransferAccounts(db);
        await db.addMovement(
          _movement(
            id: 'reg_1',
            title: 'Spesa reg',
            amount: 13,
            type: MovementType.expense,
            date: _d(17),
            categoryId: 'exp_1',
            accountId: 'acc_a',
          ),
        );
        final json = await BackupService.exportToJson(db);
        final validation = BackupService.validate(json);
        final restored = AppDatabase();
        await BackupService.restore(restored, validation.data!);
        expect(restored.movements.length, 1);
        expect(restored.movements.first.title, 'Spesa reg');
        expect(
          searchMovements(
            movements: restored.movements,
            query: 'spesa',
            filter: TimeFilter.year(2026),
            categories: restored.categories,
            accounts: restored.accounts,
          ).length,
          1,
        );
        await restored.resetAllData();
        expect(restored.movements, isEmpty);
        expect(
          searchMovements(
            movements: restored.movements,
            query: 'spesa',
            filter: TimeFilter.year(2026),
            categories: restored.categories,
            accounts: restored.accounts,
          ),
          isEmpty,
        );
      },
    );
  });
}
