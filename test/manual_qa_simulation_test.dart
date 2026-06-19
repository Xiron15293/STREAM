import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/accounts_screen.dart';
import 'package:stream_app/screens/calendar_screen.dart';
import 'package:stream_app/screens/categories_screen.dart';
import 'package:stream_app/screens/dashboard_screen.dart';
import 'package:stream_app/screens/movements_screen.dart';
import 'package:stream_app/widgets/movement_picker.dart';

typedef _EntryPointPump =
    Future<void> Function(
      WidgetTester tester,
      AppDatabase db,
      Movement movement,
    );

void main() {
  SharedPreferences.setMockInitialValues({});

  setUp(() {
    SharedPreferences.setMockInitialValues({'category_layout': 'cleanList'});
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
    PreferencesService.categoryLayoutNotifier.value =
        PreferencesService.defaultCategoryLayout;
  });

  tearDown(() {
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
    PreferencesService.categoryLayoutNotifier.value =
        PreferencesService.defaultCategoryLayout;
  });

  final entryPoints = <String, _EntryPointPump>{
    'movements': _openEditFromMovements,
    'dashboard': _openEditFromDashboard,
    'accounts': _openEditFromAccounts,
    'categories': _openEditFromCategories,
    'calendar': _openEditFromCalendar,
  };

  group('Hermes manual QA simulation', () {
    for (final entry in entryPoints.entries) {
      testWidgets(
        'edit flow from ${entry.key} shows sticky header and saves without duplicates',
        (tester) async {
          _setPhoneViewport(tester);
          final db = AppDatabase();
          final movement = await _seedExpenseMovement(
            db,
            id: 'edit_${entry.key}',
            title: 'Original ${entry.key}',
          );

          await entry.value(tester, db, movement);

          expect(find.text('Modifica movimento'), findsOneWidget);
          expect(
            find.byKey(const Key('movement_submit_top_button')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('movement_close_top_button')),
            findsOneWidget,
          );

          await tester.drag(
            find.byKey(const Key('add_movement_details_step')).last,
            const Offset(0, -700),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('movement_amount_sticky')),
            findsOneWidget,
          );

          final updatedTitle = 'Updated ${entry.key}';
          await tester.enterText(
            find.byKey(const Key('movement_title_field')).last,
            updatedTitle,
          );
          await tester.pumpAndSettle();
          await _tapVisible(
            tester,
            find.byKey(const Key('movement_submit_top_button')).last,
          );

          expect(db.movements.length, 1);
          expect(db.movements.single.id, movement.id);
          expect(db.movements.single.title, updatedTitle);
        },
      );
    }

    testWidgets(
      'viewport matrix keeps primary surfaces reachable without overflow',
      (tester) async {
        final sizes = <Size>[
          const Size(320, 568),
          const Size(390, 844),
          const Size(430, 932),
          const Size(768, 1024),
        ];

        for (final size in sizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          final db = AppDatabase();
          await _seedDatasetForViewport(db);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: MovementPicker(db: db)),
            ),
          );
          await tester.pumpAndSettle();
          final categoryOption = find
              .byKey(const Key('category_option_exp_1'))
              .last;
          await tester.ensureVisible(categoryOption);
          await tester.pumpAndSettle();
          await tester.tap(categoryOption, warnIfMissed: false);
          await tester.pumpAndSettle();
          await tester.drag(
            find.byKey(const Key('add_movement_details_step')).last,
            const Offset(0, -700),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('movement_submit_top_button')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('movement_close_top_button')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
          await tester.pumpAndSettle();
          expect(find.byType(Scrollable), findsWidgets);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(MaterialApp(home: AccountsScreen(db: db)));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('account_card_acc_default')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(MaterialApp(home: CategoriesScreen(db: db)));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('category_card_exp_1')), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      },
    );
  });
}

Future<Movement> _seedExpenseMovement(
  AppDatabase db, {
  required String id,
  required String title,
}) async {
  final now = DateTime.now();
  final movement = Movement(
    id: id,
    title: title,
    amount: 42,
    type: MovementType.expense,
    date: DateTime(now.year, now.month, now.day),
    categoryId: 'exp_1',
    accountId: defaultAccountId,
    note: 'Initial note',
    createdAt: now,
  );
  await db.addMovement(movement);
  return movement;
}

Future<void> _seedDatasetForViewport(AppDatabase db) async {
  final now = DateTime.now();
  for (var i = 0; i < 18; i++) {
    await db.addMovement(
      Movement(
        id: 'viewport_$i',
        title: 'Viewport Movement $i',
        amount: 10 + i.toDouble(),
        type: MovementType.expense,
        date: DateTime(now.year, now.month, now.day),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        note: 'Very long note for viewport simulation $i ' * 2,
        payee: 'Long Beneficiary Name $i ' * 2,
        createdAt: now.add(Duration(minutes: i)),
      ),
    );
  }
}

Future<void> _openEditFromMovements(
  WidgetTester tester,
  AppDatabase db,
  Movement movement,
) async {
  await tester.pumpWidget(MaterialApp(home: MovementsScreen(db: db)));
  await tester.pumpAndSettle();
  final card = find.byKey(Key('movement_card_${movement.id}'));
  await _tapVisible(tester, card);
}

Future<void> _openEditFromDashboard(
  WidgetTester tester,
  AppDatabase db,
  Movement movement,
) async {
  await tester.pumpWidget(MaterialApp(home: DashboardScreen(db: db)));
  await tester.pumpAndSettle();
  final categoryRow = find.ancestor(
    of: find.text('Spesa'),
    matching: find.byType(GestureDetector),
  );
  await _tapVisible(tester, categoryRow.first);
  final card = find.byKey(Key('movement_card_${movement.id}')).last;
  await _tapVisible(tester, card);
}

Future<void> _openEditFromAccounts(
  WidgetTester tester,
  AppDatabase db,
  Movement movement,
) async {
  await tester.pumpWidget(MaterialApp(home: AccountsScreen(db: db)));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.byKey(const Key('account_card_acc_default')));
  final card = find.byKey(Key('movement_card_${movement.id}')).last;
  await _tapVisible(tester, card);
}

Future<void> _openEditFromCategories(
  WidgetTester tester,
  AppDatabase db,
  Movement movement,
) async {
  await tester.pumpWidget(MaterialApp(home: CategoriesScreen(db: db)));
  await tester.pumpAndSettle();
  await _tapVisible(tester, find.byKey(const Key('category_card_exp_1')));
  final card = find.byKey(Key('movement_card_${movement.id}')).last;
  await _tapVisible(tester, card);
}

Future<void> _openEditFromCalendar(
  WidgetTester tester,
  AppDatabase db,
  Movement movement,
) async {
  await tester.pumpWidget(MaterialApp(home: CalendarScreen(db: db)));
  await tester.pumpAndSettle();
  final today = DateTime.now().day;
  await _tapVisible(tester, find.text('$today').first);
  final card = find.byKey(Key('movement_card_${movement.id}')).last;
  await _tapVisible(tester, card);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
