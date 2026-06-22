import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/screens/charts_screen.dart';
import 'package:stream_app/screens/dashboard_screen.dart';
import 'package:stream_app/screens/accounts_screen.dart';
import 'package:stream_app/screens/categories_screen.dart';
import 'package:stream_app/screens/movements_screen.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/time_filter_bar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final fixedNow = DateTime(2026, 6, 21);

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    await db.archiveAccount(defaultAccountId);
    await db.addAccount(
      Account(
        id: 'acc_a',
        name: 'Intesa',
        type: AccountType.bank,
        createdAt: fixedNow,
      ),
    );
    await db.addMovement(
      Movement(
        id: 'm_today',
        title: 'Oggi',
        amount: 20,
        type: MovementType.expense,
        date: fixedNow,
        categoryId: 'exp_1',
        accountId: 'acc_a',
        createdAt: fixedNow,
      ),
    );
    await db.addMovement(
      Movement(
        id: 'm_prev_day',
        title: 'Ieri',
        amount: 10,
        type: MovementType.expense,
        date: fixedNow.subtract(const Duration(days: 1)),
        categoryId: 'exp_1',
        accountId: 'acc_a',
        createdAt: fixedNow.subtract(const Duration(days: 1)),
      ),
    );
    return db;
  }

  Finder timeFilterLabel(String label) => find.descendant(
    of: find.byType(TimeFilterBar).first,
    matching: find.text(label),
  );

  Finder timeFilterChevronRight() => find.descendant(
    of: find.byType(TimeFilterBar).first,
    matching: find.byIcon(Icons.chevron_right),
  );

  Future<void> pumpMovements(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme:
            StreamTheme.build(
              StreamThemePalette.of(StreamThemeId.streamClassic),
            ).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
        home: MovementsScreen(
          db: db,
          activeProfileId: 'profile_a',
          timeFilterNowProvider: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpCategories(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme:
            StreamTheme.build(
              StreamThemePalette.of(StreamThemeId.streamClassic),
            ).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
        home: CategoriesScreen(
          db: db,
          activeProfileId: 'profile_a',
          timeFilterNowProvider: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpAccounts(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme:
            StreamTheme.build(
              StreamThemePalette.of(StreamThemeId.streamClassic),
            ).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
        home: AccountsScreen(
          db: db,
          activeProfileId: 'profile_a',
          timeFilterNowProvider: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDashboard(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme:
            StreamTheme.build(
              StreamThemePalette.of(StreamThemeId.streamClassic),
            ).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
        home: DashboardScreen(
          db: db,
          activeProfileId: 'profile_a',
          timeFilterNowProvider: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpCharts(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(
      MaterialApp(
        theme:
            StreamTheme.build(
              StreamThemePalette.of(StreamThemeId.streamClassic),
            ).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
        home: ChartsScreen(
          db: db,
          activeProfileId: 'profile_a',
          timeFilterNowProvider: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Movimenti — month day switch preserves context', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db);
    final junEnd = TimeFilter.month(2026, 6).endDate;

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(junEnd).label), findsOneWidget);

    await tester.tap(timeFilterChevronRight());
    await tester.pumpAndSettle();
    expect(
      timeFilterLabel(
        TimeFilter.day(junEnd.add(const Duration(days: 1))).label,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(junEnd).label), findsOneWidget);
  });

  testWidgets('Categorie — month day preserves context', (tester) async {
    final db = await seededDb();
    await pumpCategories(tester, db);
    final junEnd = TimeFilter.month(2026, 6).endDate;

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(junEnd).label), findsOneWidget);

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(junEnd).label), findsOneWidget);
  });

  testWidgets('Conti — month day preserves context', (tester) async {
    final db = await seededDb();
    await pumpAccounts(tester, db);
    final junEnd = TimeFilter.month(2026, 6).endDate;

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(junEnd).label), findsOneWidget);

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(junEnd).label), findsOneWidget);
  });

  testWidgets('Dashboard — month day preserves context', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpDashboard(tester, db);
    final junEnd = TimeFilter.month(2026, 6).endDate;

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(junEnd).label), findsOneWidget);

    await tester.tap(timeFilterChevronRight());
    await tester.pumpAndSettle();
    expect(
      timeFilterLabel(
        TimeFilter.day(junEnd.add(const Duration(days: 1))).label,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(junEnd).label), findsOneWidget);
  });

  testWidgets('Charts — month day preserves context', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);
    final junEnd = TimeFilter.month(2026, 6).endDate;

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(junEnd).label), findsOneWidget);

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(junEnd).label), findsOneWidget);
  });

  testWidgets('Mese Maggio 2026 → Giorno → 31 maggio 2026', (tester) async {
    final db = await seededDb();
    await pumpMovements(tester, db);
    final mayEnd = TimeFilter.month(2026, 5).endDate;

    await tester.tap(find.text('Mese'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(mayEnd).label), findsOneWidget);
  });

  testWidgets('Week passata → Giorno → ultimo giorno settimana', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db);
    final junEnd = TimeFilter.month(2026, 6).endDate;
    final weekFromMonthEnd = TimeFilter.week(junEnd);
    final weekEnd = weekFromMonthEnd.endDate;

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(weekFromMonthEnd.label), findsOneWidget);

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(weekEnd).label), findsOneWidget);
  });

  testWidgets('Mese Maggio 2026 → Settimana → settimana contenente 31 maggio', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db);
    final mayEnd = TimeFilter.month(2026, 5).endDate;

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(mayEnd).label), findsOneWidget);
  });
}
