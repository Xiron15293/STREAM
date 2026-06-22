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

  testWidgets('Movimenti day/week reset to today and manual navigation works', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpMovements(tester, db);

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(fixedNow).label), findsOneWidget);
    expect(find.text('Oggi'), findsOneWidget);
    expect(find.text('Ieri'), findsNothing);

    await tester.tap(timeFilterChevronRight());
    await tester.pumpAndSettle();
    expect(
      timeFilterLabel(
        TimeFilter.day(fixedNow.add(const Duration(days: 1))).label,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(fixedNow).label), findsOneWidget);
  });

  testWidgets('Categorie day/week reset to today', (tester) async {
    final db = await seededDb();
    await pumpCategories(tester, db);

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(fixedNow).label), findsOneWidget);

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(fixedNow).label), findsOneWidget);
  });

  testWidgets('Conti day/week reset to today', (tester) async {
    final db = await seededDb();
    await pumpAccounts(tester, db);

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(fixedNow).label), findsOneWidget);

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(fixedNow).label), findsOneWidget);
  });

  testWidgets('Dashboard day/week reset to today and manual navigation works', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpDashboard(tester, db);

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(fixedNow).label), findsOneWidget);

    await tester.tap(timeFilterChevronRight());
    await tester.pumpAndSettle();
    expect(
      timeFilterLabel(
        TimeFilter.day(fixedNow.add(const Duration(days: 1))).label,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(fixedNow).label), findsOneWidget);
  });

  testWidgets('Charts day/week reset to today', (tester) async {
    final db = await seededDb();
    await pumpCharts(tester, db);

    await tester.tap(find.text('Giorno'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.day(fixedNow).label), findsOneWidget);

    await tester.tap(find.text('Sett.'));
    await tester.pumpAndSettle();
    expect(timeFilterLabel(TimeFilter.week(fixedNow).label), findsOneWidget);
  });
}
