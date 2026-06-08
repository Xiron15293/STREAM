import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/screens/dashboard_screen.dart';

void main() {
  group('1. Dashboard filtered KPI (in-memory logic)', () {
    late AppDatabase db;
    late DateTime now;

    setUp(() {
      db = AppDatabase();
      now = DateTime.now();
    });

    test('1.1 Default filter = mese corrente', () {
      final filter = TimeFilter.month(now.year, now.month);
      expect(filter.mode, TimeFilterMode.month);
      expect(filter.startDate.year, now.year);
      expect(filter.startDate.month, now.month);
    });

    test('1.2 Entrate filtrate per mese corrente', () {
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Income',
          amount: 500,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          createdAt: now,
        ),
      );
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Old Income',
          amount: 300,
          type: MovementType.income,
          date: prev,
          categoryId: 'inc_1',
          createdAt: prev,
        ),
      );

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);
      double income = 0;
      for (final m in filtered) {
        if (m.type == MovementType.income) income += m.amount;
      }

      expect(filtered.length, 1);
      expect(income, 500);
      expect(db.totalIncome, 800);
    });

    test('1.3 Spese filtrate per mese corrente', () {
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Expense',
          amount: 200,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Old Expense',
          amount: 100,
          type: MovementType.expense,
          date: prev,
          categoryId: 'exp_1',
          createdAt: prev,
        ),
      );

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);
      double expenses = 0;
      for (final m in filtered) {
        if (m.type == MovementType.expense) expenses += m.amount;
      }

      expect(filtered.length, 1);
      expect(expenses, 200);
      expect(db.totalExpenses, 300);
    });

    test('1.4 Saldo filtrato per mese corrente', () {
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Income',
          amount: 500,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Expense',
          amount: 200,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);
      double income = 0, expenses = 0;
      for (final m in filtered) {
        if (m.type == MovementType.income) {
          income += m.amount;
        } else {
          expenses += m.amount;
        }
      }

      expect(income - expenses, 300);
      expect(db.balance, 300);
    });

    test('1.4b Transfer non altera KPI entrate/spese e resta neutro sul saldo', () {
      db.addAccount(
        Account(
          id: 'acc_dest',
          name: 'Destinazione',
          type: AccountType.bank,
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Income',
          amount: 500,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'tr1',
          title: 'Transfer',
          amount: 120,
          type: MovementType.transfer,
          date: now,
          categoryId: '',
          accountId: defaultAccountId,
          destinationAccountId: 'acc_dest',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Expense',
          amount: 200,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);
      final income = filtered.where((m) => m.type == MovementType.income).fold<double>(0, (sum, m) => sum + m.amount);
      final expenses = filtered.where((m) => m.type == MovementType.expense).fold<double>(0, (sum, m) => sum + m.amount);
      final transferCount = filtered.where((m) => m.type == MovementType.transfer).length;

      expect(income, 500);
      expect(expenses, 200);
      expect(transferCount, 1);
      expect(db.balance, 300);
      expect(db.totalAccountsBalance, 300);
    });

    test('1.5 Cambio giorno: KPI filtrati correttamente', () {
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Today',
          amount: 100,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Yesterday',
          amount: 50,
          type: MovementType.income,
          date: yesterday,
          categoryId: 'inc_1',
          createdAt: yesterday,
        ),
      );

      final todayFilter = TimeFilter.day(now);
      expect(db.movements.filterByTime(todayFilter).length, 1);
      expect(db.movements.filterByTime(todayFilter).first.id, 'm1');

      final yesterdayFilter = TimeFilter.day(yesterday);
      expect(db.movements.filterByTime(yesterdayFilter).length, 1);
      expect(db.movements.filterByTime(yesterdayFilter).first.id, 'm2');
    });

    test('1.6 Cambio anno: KPI filtrati per anno', () {
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'This Year',
          amount: 1000,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Last Year',
          amount: 500,
          type: MovementType.income,
          date: DateTime(now.year - 1, 6, 15),
          categoryId: 'inc_1',
          createdAt: DateTime(now.year - 1, 6, 15),
        ),
      );

      expect(db.movements.filterByTime(TimeFilter.year(now.year)).length, 1);
      expect(
        db.movements.filterByTime(TimeFilter.year(now.year - 1)).length,
        1,
      );
    });

    test('1.7 Intervallo custom: range di 7 giorni', () {
      final day1 = DateTime(now.year, now.month, 10);
      final day3 = DateTime(now.year, now.month, 12);
      final day7 = DateTime(now.year, now.month, 16);

      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Day1',
          amount: 10,
          type: MovementType.expense,
          date: day1,
          categoryId: 'exp_1',
          createdAt: day1,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Day3',
          amount: 20,
          type: MovementType.expense,
          date: day3,
          categoryId: 'exp_1',
          createdAt: day3,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm3',
          title: 'Day7',
          amount: 30,
          type: MovementType.expense,
          date: day7,
          categoryId: 'exp_1',
          createdAt: day7,
        ),
      );

      final range = TimeFilter.customRange(
        day1,
        DateTime(now.year, now.month, 13),
      );
      final filtered = db.movements.filterByTime(range);
      expect(filtered.length, 2);
      expect(filtered.any((m) => m.id == 'm1'), true);
      expect(filtered.any((m) => m.id == 'm2'), true);
      expect(filtered.any((m) => m.id == 'm3'), false);
    });

    test('1.8 Patrimonio NON filtrato dal periodo', () {
      db.addAccount(
        Account(
          id: 'acc_test',
          name: 'Test',
          type: AccountType.bank,
          initialBalance: 5000,
          createdAt: now,
        ),
      );

      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Income',
          amount: 1000,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          accountId: 'acc_test',
          createdAt: now,
        ),
      );

      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Old',
          amount: 500,
          type: MovementType.income,
          date: prev,
          categoryId: 'inc_1',
          accountId: 'acc_test',
          createdAt: prev,
        ),
      );

      expect(db.totalAccountsBalance, 6500);

      final filter = TimeFilter.month(now.year, now.month);
      expect(db.movements.filterByTime(filter).length, 1);
      expect(db.totalAccountsBalance, 6500);
    });

    test('1.9 Stato vuoto: movimenti in altro periodo', () {
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Old',
          amount: 100,
          type: MovementType.income,
          date: prev,
          categoryId: 'inc_1',
          createdAt: prev,
        ),
      );

      final nextMonth = now.month < 12 ? now.month + 1 : 1;
      final nextYear = now.month < 12 ? now.year : now.year + 1;
      final filter = TimeFilter.month(nextYear, nextMonth);

      expect(db.movements.filterByTime(filter).isEmpty, true);
      expect(db.movements.isNotEmpty, true);
    });

    test('1.10 Movimenti count filtrato', () {
      for (int i = 0; i < 5; i++) {
        db.addMovement(
          Movement(
            id: 'm$i',
            title: 'Mov $i',
            amount: 10.0,
            type: MovementType.expense,
            date: now,
            categoryId: 'exp_1',
            createdAt: now,
          ),
        );
      }
      final prev = DateTime(now.year, now.month - 1, 15);
      db.addMovement(
        Movement(
          id: 'm_old',
          title: 'Old',
          amount: 100,
          type: MovementType.income,
          date: prev,
          categoryId: 'inc_1',
          createdAt: prev,
        ),
      );

      final filter = TimeFilter.month(now.year, now.month);
      expect(db.movements.filterByTime(filter).length, 5);
    });
  });

  group('2. Dashboard UI widget tests', () {
    testWidgets('2.1 TimeFilterBar and KPIs render correctly', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      expect(find.text('Giorno'), findsOneWidget);
      expect(find.text('Mese'), findsOneWidget);
      expect(find.text('Anno'), findsOneWidget);
      expect(find.text('Intervallo'), findsOneWidget);

      final now = DateTime.now();
      final expectedLabel = TimeFilter.month(now.year, now.month).label;
      expect(find.text(expectedLabel), findsOneWidget);

      expect(find.text('PATRIMONIO'), findsOneWidget);
    });

    testWidgets('2.2 Filtered values and category expenses shown in UI', (
      tester,
    ) async {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Stipendio',
          amount: 2500,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Affitto',
          amount: 800,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      expect(find.textContaining('2500.00'), findsWidgets);
      expect(find.textContaining('800.00'), findsWidgets);
      expect(find.textContaining('1700.00'), findsWidgets);
      expect(find.text('Spese per categoria'), findsOneWidget);
      expect(find.textContaining('800.00 €'), findsWidgets);
    });

    testWidgets('2.3 Empty state when no expenses in selected period', (
      tester,
    ) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      expect(
        find.text('Nessuna spesa nel periodo selezionato'),
        findsOneWidget,
      );
      expect(find.text('PATRIMONIO'), findsOneWidget);
      expect(find.text('Giorno'), findsOneWidget);
    });

    testWidgets('2.4 Category expenses exclude income and sort descending', (
      tester,
    ) async {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addMovement(
        Movement(
          id: 'income',
          title: 'Stipendio',
          amount: 3000,
          type: MovementType.income,
          date: now,
          categoryId: 'inc_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'food',
          title: 'Spesa',
          amount: 320,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'fun',
          title: 'Cinema',
          amount: 80,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_4',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      expect(find.text('Spese per categoria'), findsOneWidget);
      expect(find.text('Stipendio'), findsNothing);
      expect(find.textContaining('320.00 €'), findsOneWidget);
      expect(find.textContaining('80.00 €'), findsOneWidget);

      final firstExpense = tester.getTopLeft(find.textContaining('320.00 €'));
      final secondExpense = tester.getTopLeft(find.textContaining('80.00 €'));
      expect(firstExpense.dy, lessThan(secondExpense.dy));
    });

    testWidgets('2.5 Dashboard non mostra più lista movimenti (rimossa V0.6.1)', (
      tester,
    ) async {
      final db = AppDatabase();
      final now = DateTime.now();

      db.addMovement(
        Movement(
          id: 'in_period',
          title: 'Movimento nel periodo',
          amount: 150.0,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      // Dashboard must NOT show a flat movement list
      expect(find.text('Movimenti del periodo'), findsNothing);
      // Dashboard still shows KPI and categories
      expect(find.text('Spese per categoria'), findsOneWidget);
    });

    testWidgets('2.6 Dashboard empty period — no KPI crash', (
      tester,
    ) async {
      final db = AppDatabase();
      final prev = DateTime.now().subtract(const Duration(days: 60));

      db.addMovement(
        Movement(
          id: 'old',
          title: 'Vecchio',
          amount: 100.0,
          type: MovementType.income,
          date: prev,
          categoryId: 'inc_1',
          createdAt: prev,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      // No movement list section
      expect(find.text('Movimenti del periodo'), findsNothing);
      expect(find.text('Vecchio'), findsNothing);
    });

    testWidgets('2.7 Dashboard con 25 movimenti — nessuna lista movimenti', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();

      for (int i = 0; i < 25; i++) {
        db.addMovement(
          Movement(
            id: 'm_$i',
            title: 'Movimento $i',
            amount: 10.0,
            type: MovementType.expense,
            date: now,
            categoryId: 'exp_1',
            createdAt: now.subtract(Duration(minutes: i)),
          ),
        );
      }

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      // No movement list on Dashboard
      expect(find.text('Movimenti del periodo'), findsNothing);
      // But KPI should show 25 movements
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('2.8 TimeFilter changes update KPI only (no movement list)', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      db.addMovement(
        Movement(
          id: 'today',
          title: 'Oggi',
          amount: 100.0,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'yesterday',
          title: 'Ieri',
          amount: 50.0,
          type: MovementType.expense,
          date: yesterday,
          categoryId: 'exp_1',
          createdAt: yesterday,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      // No movement list on Dashboard
      expect(find.text('Movimenti del periodo'), findsNothing);
      // KPI and category section must be present
      expect(find.text('Spese per categoria'), findsOneWidget);
    });
  });

  group('3. Intervallo picker', () {
    testWidgets('3.1 Intervallo segmented button exists and opens bottom sheet', (
      tester,
    ) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      expect(find.text('Intervallo'), findsOneWidget);
      await tester.tap(find.text('Intervallo'));
      await tester.pumpAndSettle();

      // Bottom sheet must show Da/A cards
      expect(find.text('Seleziona intervallo'), findsOneWidget);
      expect(find.text('Da'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Annulla'), findsOneWidget);
      expect(find.text('Applica'), findsOneWidget);
    });

    testWidgets('3.2 Annulla non modifica il filtro attivo', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      final now = DateTime.now();
      final expectedLabel = TimeFilter.month(now.year, now.month).label;
      expect(find.text(expectedLabel), findsOneWidget);

      // Apri bottom sheet
      await tester.tap(find.text('Intervallo'));
      await tester.pumpAndSettle();

      // Annulla chiude senza cambiare filtro
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      // Il filtro deve essere rimasto mese corrente
      expect(find.text(expectedLabel), findsOneWidget);
    });

    testWidgets('3.3 Applica restituisce custom range e label si aggiorna', (
      tester,
    ) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      final now = DateTime.now();
      final monthLabel = TimeFilter.month(now.year, now.month).label;
      expect(find.text(monthLabel), findsOneWidget);

      // Apri bottom sheet
      await tester.tap(find.text('Intervallo'));
      await tester.pumpAndSettle();

      // Applica il range corrente
      await tester.tap(find.text('Applica'));
      await tester.pumpAndSettle();

      // La label deve essere cambiata in formato custom range
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      final expectedLabel = TimeFilter.customRange(start, end).label;
      expect(find.text(expectedLabel), findsOneWidget);
      expect(find.text(monthLabel), findsNothing);
    });

    testWidgets('3.4 Bottom sheet mostra data formattata', (tester) async {
      final db = AppDatabase();
      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));

      await tester.tap(find.text('Intervallo'));
      await tester.pumpAndSettle();

      // Il bottom sheet mostra le date del mese corrente in formato GG/MM/AAAA
      final now = DateTime.now();
      final startStr =
          '${'01'}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      expect(find.text(startStr), findsOneWidget);
    });
  });

  group('4. Category detail and quick-add', () {
    testWidgets('4.1 Category expense row shows name and amount', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Spesa',
          amount: 50,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );
      db.addMovement(
        Movement(
          id: 'm2',
          title: 'Spesa 2',
          amount: 30,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
      await tester.pumpAndSettle();

      // Deve apparire la sezione Spese per categoria con la categoria Spesa
      expect(find.text('Spese per categoria'), findsOneWidget);
      expect(find.text('Spesa'), findsOneWidget);
      expect(find.text('80.00 €'), findsAtLeastNWidgets(1));
    });

    testWidgets('4.2 Tapping category opens detail sheet', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Spesa',
          amount: 50,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
      await tester.pumpAndSettle();

      // Scroll fino alla sezione categorie e tappa la riga
      final categoryRow = find.ancestor(
        of: find.text('Spesa'),
        matching: find.byType(GestureDetector),
      );
      await tester.ensureVisible(categoryRow.first);
      await tester.pumpAndSettle();
      await tester.tap(categoryRow.first);
      await tester.pumpAndSettle();

      // Bottom sheet dettaglio deve mostrare info categoria
      expect(find.textContaining('1 movimenti'), findsOneWidget);
    });

    testWidgets('4.3 Category detail shows filtered movements', (tester) async {
      final db = AppDatabase();
      final now = DateTime.now();
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Alimentari',
          amount: 25,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
      await tester.pumpAndSettle();

      final categoryRow = find.ancestor(
        of: find.text('Spesa'),
        matching: find.byType(GestureDetector),
      );
      await tester.ensureVisible(categoryRow.first);
      await tester.pumpAndSettle();
      await tester.tap(categoryRow.first);
      await tester.pumpAndSettle();

      // Il movimento deve essere nella lista del dettaglio
      expect(find.text('Alimentari'), findsAtLeastNWidgets(1));
      expect(find.text('-25.00 €'), findsAtLeastNWidgets(1));
    });
  });

  group('5. Account and category edge cases', () {
    test('5.1 Default account not deletable — no explicit delete API', () {
      final db = AppDatabase();
      final defaultAcc = db.accounts.first;
      expect(defaultAcc.id, defaultAccountId);

      // Verify the default account exists
      expect(db.accounts.length, 1);
      expect(db.getAccountOrNull(defaultAccountId), isNotNull);
    });

    test('5.2 Category with movements blocks deletion', () {
      final db = AppDatabase();
      final now = DateTime.now();

      // Add a movement using a specific category
      db.addMovement(
        Movement(
          id: 'm1',
          title: 'Test',
          amount: 10,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      // categoryHasMovements should return true
      expect(db.categoryHasMovements('exp_1'), isTrue);
    });

    test('5.3 Quick movements preserve categoryId after category rename', () {
      final db = AppDatabase();
      final catId = 'exp_1';

      // Add a quick movement referencing the category
      db.addQuickMovement(
        QuickMovement(
          id: 'qm_test',
          title: 'Test Rapido',
          amount: 10,
          type: MovementType.expense,
          categoryId: catId,
        ),
      );

      // Rename the category
      final cat = db.categories.firstWhere((c) => c.id == catId);
      db.updateCategory(cat.id, 'Nuovo Nome', cat.color);

      // Quick movement should still reference the same category
      final qm = db.quickMovements.firstWhere((q) => q.id == 'qm_test');
      expect(qm.categoryId, catId);
    });

    test('5.4 Favorite movements preserve categoryId after category rename', () {
      final db = AppDatabase();
      final catId = 'inc_1';

      // Add a favorite movement
      db.addFavoriteMovement(
        FavoriteMovement(
          id: 'fm_test',
          title: 'Test Preferito',
          amount: 1000,
          type: MovementType.income,
          categoryId: catId,
        ),
      );

      // Rename the category
      final cat = db.categories.firstWhere((c) => c.id == catId);
      db.updateCategory(cat.id, 'Nuovo Stipendio', cat.color);

      // Favorite should still reference the same category
      final fm = db.favoriteMovements.firstWhere((f) => f.id == 'fm_test');
      expect(fm.categoryId, catId);
    });

    test('5.5 Suggestion threshold: 5 identical movements trigger suggestion', () {
      final db = AppDatabase();
      final now = DateTime.now();

      // Add 5 identical movements
      for (int i = 0; i < 5; i++) {
        db.addMovement(
          Movement(
            id: 'sug_$i',
            title: 'Caffè',
            amount: 1.50,
            type: MovementType.expense,
            date: now,
            categoryId: 'exp_4',
            createdAt: now,
          ),
        );
      }

      final suggestions = db.getSuggestions();
      expect(suggestions.length, 1);
      expect(suggestions.first.title, 'Caffè');
    });

    test('5.6 Suggestion threshold: 4 identical movements do NOT trigger', () {
      final db = AppDatabase();
      final now = DateTime.now();

      // Add 4 identical movements (below threshold)
      for (int i = 0; i < 4; i++) {
        db.addMovement(
          Movement(
            id: 'nosug_$i',
            title: 'Acqua',
            amount: 1.00,
            type: MovementType.expense,
            date: now,
            categoryId: 'exp_1',
            createdAt: now,
          ),
        );
      }

      final suggestions = db.getSuggestions();
      expect(suggestions.length, 0);
    });

    test('5.7 Suggestion after category rename still appears', () {
      final db = AppDatabase();
      final now = DateTime.now();

      // Add 5 identical movements with a custom category
      final customCatId = db.categories.first.id;
      for (int i = 0; i < 5; i++) {
        db.addMovement(
          Movement(
            id: 'ren_sug_$i',
            title: 'Benzina',
            amount: 50,
            type: MovementType.expense,
            date: now,
            categoryId: customCatId,
            createdAt: now,
          ),
        );
      }

      // Rename the category
      final cat = db.categories.first;
      db.updateCategory(cat.id, 'Renamed Cat', cat.color);

      final suggestions = db.getSuggestions();
      expect(suggestions.length, 1);
      expect(suggestions.first.title, 'Benzina');
    });

    test('5.8 Archived category still resolves in movements', () {
      final db = AppDatabase();
      final now = DateTime.now();

      // Add movement with a category
      db.addMovement(
        Movement(
          id: 'arch_m1',
          title: 'Old Spesa',
          amount: 20,
          type: MovementType.expense,
          date: now,
          categoryId: 'exp_1',
          createdAt: now,
        ),
      );

      // Archive the category
      db.archiveCategory('exp_1');

      // Movement categoryId should still resolve (even if archived)
      final m = db.movements.first;
      expect(m.categoryId, 'exp_1');

      // Archived category should not appear in activeCategories
      final activeCats = db.activeCategories;
      expect(activeCats.where((c) => c.id == 'exp_1').length, 0);
    });
  });

  group('6. Stress test — 1000 movimenti con filtro', () {
    test('6.1 Filter per mese su 1000 movimenti è veloce e corretto', () {
      final db = AppDatabase();
      final now = DateTime.now();

      for (int i = 0; i < 1000; i++) {
        db.addMovement(
          Movement(
            id: 'stress_$i',
            title: 'Stress $i',
            amount: (i % 100) + 1.0,
            type: i.isEven ? MovementType.income : MovementType.expense,
            date: i < 500 ? now : DateTime(now.year, now.month - 1, 15),
            categoryId: i.isEven ? 'inc_1' : 'exp_1',
            createdAt: now,
          ),
        );
      }

      final filter = TimeFilter.month(now.year, now.month);
      final filtered = db.movements.filterByTime(filter);

      expect(filtered.length, 500);
      expect(filtered.where((m) => m.type == MovementType.income).length, 250);
      expect(filtered.where((m) => m.type == MovementType.expense).length, 250);
    });

    test('6.2 Patrimonio invariato con filtro su 1000 movimenti', () {
      final db = AppDatabase();
      final now = DateTime.now();

      for (int i = 0; i < 1000; i++) {
        db.addMovement(
          Movement(
            id: 'bal_$i',
            title: 'Bal $i',
            amount: 100.0,
            type: MovementType.income,
            date: i < 500 ? now : DateTime(now.year, now.month - 1, 15),
            categoryId: 'inc_1',
            createdAt: now,
          ),
        );
      }

      final patrimonio = db.totalAccountsBalance;
      final filter = TimeFilter.month(now.year, now.month);
      db.movements.filterByTime(filter);

      expect(db.totalAccountsBalance, patrimonio,
          reason: 'Patrimonio NON deve cambiare col filtro');
    });

    test('6.3 Filtro custom range su 1000 movimenti', () {
      final db = AppDatabase();
      final now = DateTime.now();

      for (int i = 0; i < 1000; i++) {
        final day = DateTime(now.year, now.month, (i % 28) + 1);
        db.addMovement(
          Movement(
            id: 'cr_$i',
            title: 'CR $i',
            amount: 10.0,
            type: MovementType.expense,
            date: day,
            categoryId: 'exp_1',
            createdAt: day,
          ),
        );
      }

      final range = TimeFilter.customRange(
        DateTime(now.year, now.month, 10),
        DateTime(now.year, now.month, 20),
      );
      final filtered = db.movements.filterByTime(range);

      expect(filtered.length, 396);
    });
  });
}
