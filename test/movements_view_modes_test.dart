import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/screens/movements_screen.dart';
import 'package:stream_app/utils/heatmap_utils.dart';
import 'package:stream_app/widgets/grouped_movements_list.dart';
import 'package:stream_app/widgets/movement_card.dart';
import 'package:stream_app/widgets/period_category_treemap.dart';

void main() {
  late DateTime today;

  setUp(() {
    today = DateTime.now();
    PreferencesService.movementsViewModeNotifier.value =
        PreferencesService.defaultMovementsViewMode;
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppDatabase seededDb() {
    final db = AppDatabase();
    final day = DateTime(today.year, today.month, today.day, 9);
    db.addMovement(
      Movement(
        id: 'income_today',
        title: 'Entrata oggi',
        amount: 50,
        type: MovementType.income,
        date: day,
        categoryId: 'inc_1',
        accountId: defaultAccountId,
        createdAt: day,
      ),
    );
    db.addMovement(
      Movement(
        id: 'expense_today',
        title: 'Uscita oggi',
        amount: 20,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: day,
      ),
    );
    db.addMovement(
      Movement(
        id: 'transfer_today',
        title: 'Transfer oggi',
        amount: 100,
        type: MovementType.transfer,
        date: day,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        destinationAccountId: defaultAccountId,
        createdAt: day,
      ),
    );
    return db;
  }

  Future<void> pumpMovements(
    WidgetTester tester,
    AppDatabase db, {
    required String mode,
  }) async {
    SharedPreferences.setMockInitialValues({'movements_view_mode': mode});
    await tester.pumpWidget(MaterialApp(home: MovementsScreen(db: db)));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'list heatmap mode shows preview card and grouped list, no calendar/advanced',
    (tester) async {
      await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

      expect(
        find.byKey(const Key('movements_layout_list_heatmap')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movements_list_heatmap_preview_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movements_list_heatmap_preview_grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movements_list_open_calendar_action')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movements_list_mini_heatmap')),
        findsNothing,
      );
      expect(find.byKey(const Key('calendar_month_surface')), findsNothing);
      expect(find.byKey(const Key('advanced_heatmap_surface')), findsNothing);
      expect(find.byType(MovementCard), findsAtLeast(1));
      expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);
      expect(
        find.byKey(const Key('movements_layout_advanced_heatmap')),
        findsNothing,
      );
      expect(find.byKey(const Key('day_filter_transfer')), findsNothing);
      expect(_hasHorizontalScroll(tester), isFalse);
    },
  );

  testWidgets(
    'calendar mode uses month grid and day panel without list heatmap',
    (tester) async {
      await pumpMovements(tester, seededDb(), mode: 'calendar');

      expect(
        find.byKey(const Key('movements_layout_calendar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movements_calendar_month_grid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('calendar_large_month_heatmap')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('calendar_month_surface')), findsOneWidget);
      expect(
        find.byKey(const Key('heatmap_no_horizontal_scroll_block')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('advanced_heatmap_surface')), findsNothing);
      expect(find.byKey(const Key('heatmap_selected_day')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('movements_layout_calendar')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('day_movements_panel')), findsOneWidget);
      expect(find.byKey(const Key('day_income_total')), findsOneWidget);
      expect(find.byKey(const Key('day_expense_total')), findsOneWidget);
      expect(find.byKey(const Key('day_balance')), findsOneWidget);
      expect(find.byKey(const Key('day_movement_count')), findsOneWidget);
      expect(
        find.byKey(const Key('movements_list_mini_heatmap')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('movements_list_heatmap_preview_card')),
        findsNothing,
      );
      expect(find.byType(GroupedMovementsList), findsNothing);
      expect(find.byKey(const Key('day_filter_transfer')), findsNothing);
      expect(_hasHorizontalScroll(tester), isFalse);
      expect(find.text('< 1€'), findsOneWidget);
      expect(find.text('1–5€'), findsOneWidget);
      expect(find.text('5–20€'), findsOneWidget);
      expect(find.text('20–50€'), findsOneWidget);
      expect(find.text('50–150€'), findsOneWidget);
      expect(find.text('150–500€'), findsOneWidget);
      expect(find.text('> 500€'), findsOneWidget);
      expect(find.byKey(const Key('heatmap_legend_item')), findsNWidgets(7));
      expect(find.byKey(const Key('heatmap_legend_color')), findsNWidgets(7));
      expect(find.byKey(const Key('heatmap_legend_label')), findsNWidgets(7));
    },
  );

  testWidgets('advanced heatmap mode exposes day filters and transfer filter', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'advancedHeatmap');

    expect(
      find.byKey(const Key('movements_layout_advanced_heatmap')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movements_calendar_month_grid')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('advanced_heatmap_surface')), findsOneWidget);
    expect(find.byKey(const Key('advanced_heatmap_grid')), findsOneWidget);
    expect(find.byKey(const Key('advanced_large_heatmap')), findsOneWidget);
    expect(find.byKey(const Key('calendar_month_surface')), findsNothing);
    expect(
      find.byKey(const Key('heatmap_no_horizontal_scroll_block')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const Key('movements_layout_advanced_heatmap')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('advanced_heatmap_kpi_panel')), findsOneWidget);
    expect(find.byKey(const Key('day_movements_panel')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_all')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_income')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_expense')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_transfer')), findsOneWidget);
    expect(find.byKey(const Key('movements_list_mini_heatmap')), findsNothing);
    expect(find.byType(GroupedMovementsList), findsNothing);
    expect(find.text('Entrata oggi', skipOffstage: false), findsOneWidget);
    expect(find.text('Uscita oggi', skipOffstage: false), findsOneWidget);
    expect(find.text('Transfer oggi', skipOffstage: false), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('movements_layout_advanced_heatmap')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('day_filter_transfer')));
    await tester.pumpAndSettle();

    expect(find.text('Transfer oggi', skipOffstage: false), findsOneWidget);
    expect(find.text('Entrata oggi'), findsNothing);
    expect(find.text('Uscita oggi'), findsNothing);
    expect(find.byKey(const Key('day_income_total')), findsOneWidget);
    expect(find.byKey(const Key('day_expense_total')), findsOneWidget);
    expect(find.byKey(const Key('day_balance')), findsOneWidget);
    expect(_hasHorizontalScroll(tester), isFalse);
  });

  test('heatmap daily totals exclude income and transfer movements', () {
    final db = seededDb();
    final totals = dailyExpenseTotals(today.year, today.month, db.movements);

    expect(totals[today.day], 20);
    expect(
      dailyExpenseTotal(
        DateTime(today.year, today.month, today.day),
        db.movements,
      ),
      20,
    );
    expect(
      dayBalance(DateTime(today.year, today.month, today.day), db.movements),
      30,
    );
  });

  testWidgets('inline mode selector is visible with 3 options', (tester) async {
    await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

    expect(
      find.byKey(const Key('movements_mode_inline_selector')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('movements_mode_inline_list')), findsOneWidget);
    expect(
      find.byKey(const Key('movements_mode_inline_calendar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('movements_mode_inline_advanced')),
      findsOneWidget,
    );
  });

  testWidgets('tap Calendario in inline selector switches to calendar layout', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

    expect(
      find.byKey(const Key('movements_layout_list_heatmap')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);

    await tester.tap(
      find.byKey(const Key('movements_mode_inline_calendar')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movements_layout_list_heatmap')),
      findsNothing,
    );
    expect(find.byKey(const Key('movements_layout_calendar')), findsOneWidget);
  });

  testWidgets('tap Heatmap in inline selector switches to advanced layout', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

    await tester.tap(
      find.byKey(const Key('movements_mode_inline_advanced')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movements_layout_list_heatmap')),
      findsNothing,
    );
    expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);
    expect(
      find.byKey(const Key('movements_layout_advanced_heatmap')),
      findsOneWidget,
    );
  });

  testWidgets('tap Lista in inline selector switches back to list layout', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'calendar');

    expect(find.byKey(const Key('movements_layout_calendar')), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('movements_mode_inline_list')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);
    expect(
      find.byKey(const Key('movements_layout_list_heatmap')),
      findsOneWidget,
    );
  });

  testWidgets(
    'tap "Apri calendario" in preview card switches to calendar mode',
    (tester) async {
      await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

      expect(
        find.byKey(const Key('movements_layout_list_heatmap')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('movements_layout_calendar')), findsNothing);

      await tester.tap(
        find
            .byKey(const Key('movements_list_open_calendar_action'))
            .hitTestable(),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('movements_layout_list_heatmap')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('movements_layout_calendar')),
        findsOneWidget,
      );

      final savedMode = await PreferencesService.loadMovementsViewMode();
      expect(savedMode, MovementsViewMode.calendar);
    },
  );

  testWidgets('inline selector saves preference via PreferencesService', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

    await tester.tap(
      find.byKey(const Key('movements_mode_inline_calendar')).hitTestable(),
    );
    await tester.pumpAndSettle();

    final savedMode = await PreferencesService.loadMovementsViewMode();
    expect(savedMode, MovementsViewMode.calendar);
  });

  testWidgets('inline selector stays synced when Settings changes mode', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

    expect(
      find.byKey(const Key('movements_layout_list_heatmap')),
      findsOneWidget,
    );

    // Simulate change from Settings
    await PreferencesService.saveMovementsViewMode(
      MovementsViewMode.advancedHeatmap,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movements_layout_list_heatmap')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('movements_layout_advanced_heatmap')),
      findsOneWidget,
    );
  });

  testWidgets('calendar mode renders month grid and day panel via selector', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

    await tester.tap(
      find.byKey(const Key('movements_mode_inline_calendar')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('movements_calendar_month_grid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('calendar_large_month_heatmap')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('heatmap_no_horizontal_scroll_block')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const Key('movements_layout_calendar')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('day_movements_panel')), findsOneWidget);
  });

  testWidgets('advanced heatmap mode renders grid and filters via selector', (
    tester,
  ) async {
    await pumpMovements(tester, seededDb(), mode: 'listHeatmap');

    await tester.tap(
      find.byKey(const Key('movements_mode_inline_advanced')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('advanced_heatmap_grid')), findsOneWidget);
    expect(find.byKey(const Key('advanced_large_heatmap')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('movements_layout_advanced_heatmap')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('advanced_heatmap_kpi_panel')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_all')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_income')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_expense')), findsOneWidget);
    expect(find.byKey(const Key('day_filter_transfer')), findsOneWidget);
  });

  testWidgets('search in year filters list and preview heatmap', (
    tester,
  ) async {
    final db = AppDatabase();
    final coffeeDay = DateTime(today.year, today.month, 8, 10);
    final groceriesDay = DateTime(today.year, today.month, 9, 10);
    db.addMovement(
      Movement(
        id: 'coffee_year',
        title: 'Caffe filtro anno',
        amount: 3,
        type: MovementType.expense,
        date: coffeeDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: coffeeDay,
      ),
    );
    db.addMovement(
      Movement(
        id: 'groceries_year',
        title: 'Spesa filtro anno',
        amount: 40,
        type: MovementType.expense,
        date: groceriesDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: groceriesDay,
      ),
    );

    await pumpMovements(tester, db, mode: 'listHeatmap');
    await tester.tap(find.text('Anno'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'caffe');
    await tester.pumpAndSettle();

    expect(find.text('Caffe filtro anno'), findsOneWidget);
    expect(find.text('Spesa filtro anno'), findsNothing);
    expect(_heatmapCellColor(tester, coffeeDay.day), isNot(Colors.transparent));
    expect(_heatmapCellColor(tester, groceriesDay.day), Colors.transparent);
  });

  testWidgets('search in month matches notes and keeps all matching days', (
    tester,
  ) async {
    final db = AppDatabase();
    final firstDay = DateTime(today.year, today.month, 5, 10);
    final secondDay = DateTime(today.year, today.month, 17, 10);
    db.addMovement(
      Movement(
        id: 'note_1',
        title: 'Primo',
        note: 'espresso ufficio',
        amount: 2,
        type: MovementType.expense,
        date: firstDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: firstDay,
      ),
    );
    db.addMovement(
      Movement(
        id: 'note_2',
        title: 'Secondo',
        note: 'espresso casa',
        amount: 4,
        type: MovementType.expense,
        date: secondDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: secondDay,
      ),
    );

    await pumpMovements(tester, db, mode: 'calendar');
    await tester.enterText(find.byType(TextField), 'espresso');
    await tester.pumpAndSettle();

    expect(find.text('Primo', skipOffstage: false), findsOneWidget);
    expect(find.text('Secondo', skipOffstage: false), findsOneWidget);
    expect(find.text('Movimenti'), findsWidgets);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('month mode shows movements from multiple selected-month days', (
    tester,
  ) async {
    final db = AppDatabase();
    final firstDay = DateTime(today.year, today.month, 3, 10);
    final secondDay = DateTime(today.year, today.month, 21, 10);
    db.addMovement(
      Movement(
        id: 'month_1',
        title: 'Inizio mese',
        amount: 10,
        type: MovementType.expense,
        date: firstDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: firstDay,
      ),
    );
    db.addMovement(
      Movement(
        id: 'month_2',
        title: 'Fine mese',
        amount: 12,
        type: MovementType.expense,
        date: secondDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: secondDay,
      ),
    );

    await pumpMovements(tester, db, mode: 'calendar');
    await tester.tap(find.byKey(Key('heatmap_day_cell_${firstDay.day}')));
    await tester.pumpAndSettle();

    expect(find.text('Inizio mese', skipOffstage: false), findsOneWidget);
    expect(find.text('Fine mese', skipOffstage: false), findsOneWidget);
  });

  testWidgets('year mode shows movements from multiple months', (tester) async {
    final db = AppDatabase();
    final january = DateTime(today.year, 1, 8, 10);
    final june = DateTime(today.year, 6, 8, 10);
    db.addMovement(
      Movement(
        id: 'year_1',
        title: 'Gennaio anno',
        amount: 10,
        type: MovementType.expense,
        date: january,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: january,
      ),
    );
    db.addMovement(
      Movement(
        id: 'year_2',
        title: 'Giugno anno',
        amount: 12,
        type: MovementType.expense,
        date: june,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: june,
      ),
    );

    await pumpMovements(tester, db, mode: 'calendar');
    await tester.tap(find.text('Anno'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('heatmap_day_cell_${june.day}')));
    await tester.pumpAndSettle();

    expect(find.text('Gennaio anno', skipOffstage: false), findsOneWidget);
    expect(find.text('Giugno anno', skipOffstage: false), findsOneWidget);
  });

  testWidgets('clear search restores period list and heatmap', (tester) async {
    final db = AppDatabase();
    final coffeeDay = DateTime(today.year, today.month, 6, 10);
    final groceriesDay = DateTime(today.year, today.month, 7, 10);
    db.addMovement(
      Movement(
        id: 'clear_1',
        title: 'Caffe clear',
        amount: 3,
        type: MovementType.expense,
        date: coffeeDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: coffeeDay,
      ),
    );
    db.addMovement(
      Movement(
        id: 'clear_2',
        title: 'Spesa clear',
        amount: 40,
        type: MovementType.expense,
        date: groceriesDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: groceriesDay,
      ),
    );

    await pumpMovements(tester, db, mode: 'listHeatmap');
    await tester.enterText(find.byType(TextField), 'caffe');
    await tester.pumpAndSettle();
    expect(find.text('Spesa clear'), findsNothing);
    expect(_heatmapCellColor(tester, groceriesDay.day), Colors.transparent);

    await tester.tap(find.byTooltip('Pulisci ricerca'));
    await tester.pumpAndSettle();

    expect(find.text('Caffe clear'), findsOneWidget);
    expect(find.text('Spesa clear'), findsOneWidget);
    expect(
      _heatmapCellColor(tester, groceriesDay.day),
      isNot(Colors.transparent),
    );
  });

  testWidgets('date picker selection updates year visible month and list', (
    tester,
  ) async {
    final db = AppDatabase();
    final picked = DateTime(today.year, 6, 15);
    db.addMovement(
      Movement(
        id: 'picker_june',
        title: 'Picker giugno',
        amount: 9,
        type: MovementType.expense,
        date: picked,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: picked,
      ),
    );

    SharedPreferences.setMockInitialValues({'movements_view_mode': 'calendar'});
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: MovementsScreen(db: db),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${today.year}'));
    await tester.pumpAndSettle();

    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    picker.onDateTimeChanged(picked);
    await tester.tap(find.byKey(const Key('stream_date_picker_ok')));
    await tester.pumpAndSettle();

    expect(find.text('${today.year}'), findsWidgets);
    expect(find.text('giugno ${today.year}'), findsOneWidget);
    expect(find.text('Picker giugno', skipOffstage: false), findsOneWidget);
    expect(_heatmapCellColor(tester, picked.day), isNot(Colors.transparent));
  });

  testWidgets('period category treemap day uses only selected day categories', (
    tester,
  ) async {
    final db = AppDatabase();
    final day = DateTime(today.year, today.month, today.day, 10);
    final otherDay = day.add(const Duration(days: 1));
    db.addMovement(
      Movement(
        id: 'treemap_day_spesa',
        title: 'Spesa giorno',
        amount: 10,
        type: MovementType.expense,
        date: day,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: day,
      ),
    );
    db.addMovement(
      Movement(
        id: 'treemap_day_casa',
        title: 'Casa altro giorno',
        amount: 12,
        type: MovementType.expense,
        date: otherDay,
        categoryId: 'exp_2',
        accountId: defaultAccountId,
        createdAt: otherDay,
      ),
    );

    await pumpPeriodCategoryTreemap(
      tester,
      movements: db.movements.filterByTime(TimeFilter.day(day)),
      categories: db.categories,
      filter: TimeFilter.day(day),
    );

    expect(find.text('Categorie del giorno'), findsOneWidget);
    expect(_periodTreemapLabels(tester), contains('Spesa'));
    expect(_periodTreemapLabels(tester), isNot(contains('Casa')));
  });

  testWidgets('period category treemap custom range uses interval categories', (
    tester,
  ) async {
    final db = AppDatabase();
    final start = DateTime(today.year, today.month, 3, 10);
    final middle = DateTime(today.year, today.month, 5, 10);
    final outside = DateTime(today.year, today.month, 9, 10);
    db.addMovement(
      Movement(
        id: 'treemap_range_spesa',
        title: 'Range spesa',
        amount: 10,
        type: MovementType.expense,
        date: start,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: start,
      ),
    );
    db.addMovement(
      Movement(
        id: 'treemap_range_casa',
        title: 'Range casa',
        amount: 12,
        type: MovementType.expense,
        date: middle,
        categoryId: 'exp_2',
        accountId: defaultAccountId,
        createdAt: middle,
      ),
    );
    db.addMovement(
      Movement(
        id: 'treemap_range_auto',
        title: 'Fuori range',
        amount: 40,
        type: MovementType.expense,
        date: outside,
        categoryId: 'exp_3',
        accountId: defaultAccountId,
        createdAt: outside,
      ),
    );
    final filter = TimeFilter.customRange(start, middle);

    await pumpPeriodCategoryTreemap(
      tester,
      movements: db.movements.filterByTime(filter),
      categories: db.categories,
      filter: filter,
    );

    expect(find.text('Categorie del periodo'), findsOneWidget);
    expect(_periodTreemapLabels(tester), containsAll(['Spesa', 'Casa']));
    expect(_periodTreemapLabels(tester), isNot(contains('Auto')));
  });

  testWidgets('calendar month no longer renders period category treemap', (
    tester,
  ) async {
    final db = AppDatabase();
    final firstDay = DateTime(today.year, today.month, 4, 10);
    final secondDay = DateTime(today.year, today.month, 22, 10);
    db.addMovement(
      Movement(
        id: 'treemap_month_spesa',
        title: 'Mese spesa',
        amount: 10,
        type: MovementType.expense,
        date: firstDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: firstDay,
      ),
    );
    db.addMovement(
      Movement(
        id: 'treemap_month_casa',
        title: 'Mese casa',
        amount: 12,
        type: MovementType.expense,
        date: secondDay,
        categoryId: 'exp_2',
        accountId: defaultAccountId,
        createdAt: secondDay,
      ),
    );

    await pumpMovements(tester, db, mode: 'calendar');
    await tester.tap(find.byKey(Key('heatmap_day_cell_${firstDay.day}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('period_category_treemap')), findsNothing);
    expect(find.text('Mese spesa', skipOffstage: false), findsOneWidget);
    expect(find.text('Mese casa', skipOffstage: false), findsOneWidget);
  });

  testWidgets('calendar year no longer renders period category treemap', (
    tester,
  ) async {
    final db = AppDatabase();
    final january = DateTime(today.year, 1, 8, 10);
    final june = DateTime(today.year, 6, 8, 10);
    db.addMovement(
      Movement(
        id: 'treemap_year_spesa',
        title: 'Anno spesa',
        amount: 10,
        type: MovementType.expense,
        date: january,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: january,
      ),
    );
    db.addMovement(
      Movement(
        id: 'treemap_year_casa',
        title: 'Anno casa',
        amount: 12,
        type: MovementType.expense,
        date: june,
        categoryId: 'exp_2',
        accountId: defaultAccountId,
        createdAt: june,
      ),
    );

    await pumpMovements(tester, db, mode: 'calendar');
    await tester.tap(find.text('Anno'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('heatmap_day_cell_${june.day}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('period_category_treemap')), findsNothing);
    expect(find.text('Anno spesa', skipOffstage: false), findsOneWidget);
    expect(find.text('Anno casa', skipOffstage: false), findsOneWidget);
  });

  testWidgets('calendar year search still filters movements without treemap', (
    tester,
  ) async {
    final db = AppDatabase();
    final coffeeDay = DateTime(today.year, 1, 8, 10);
    final rentDay = DateTime(today.year, 6, 8, 10);
    db.addMovement(
      Movement(
        id: 'treemap_search_spesa',
        title: 'Caffe annuale',
        amount: 10,
        type: MovementType.expense,
        date: coffeeDay,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: coffeeDay,
      ),
    );
    db.addMovement(
      Movement(
        id: 'treemap_search_casa',
        title: 'Affitto annuale',
        amount: 12,
        type: MovementType.expense,
        date: rentDay,
        categoryId: 'exp_2',
        accountId: defaultAccountId,
        createdAt: rentDay,
      ),
    );

    await pumpMovements(tester, db, mode: 'calendar');
    await tester.tap(find.text('Anno'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'caffe');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('period_category_treemap')), findsNothing);
    expect(find.text('Caffe annuale', skipOffstage: false), findsOneWidget);
    expect(find.text('Affitto annuale', skipOffstage: false), findsNothing);
  });

  testWidgets(
    'period category treemap shows transfer empty state and income categories',
    (tester) async {
      final db = seededDb();
      final filter = TimeFilter.day(today);

      await pumpPeriodCategoryTreemap(
        tester,
        movements: db.movements.filterByTime(filter),
        categories: db.categories,
        filter: filter,
        selectedType: MovementType.transfer,
      );

      expect(
        find.byKey(const Key('period_category_treemap_transfer_empty')),
        findsOneWidget,
      );
      expect(
        find.text('I trasferimenti non sono distribuiti per categoria.'),
        findsOneWidget,
      );

      await pumpPeriodCategoryTreemap(
        tester,
        movements: db.movements.filterByTime(filter),
        categories: db.categories,
        filter: filter,
        selectedType: MovementType.income,
      );

      expect(_periodTreemapLabels(tester), contains('Stipendio'));
    },
  );
}

Future<void> pumpPeriodCategoryTreemap(
  WidgetTester tester, {
  required List<Movement> movements,
  required List<Category> categories,
  required TimeFilter filter,
  MovementType? selectedType,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PeriodCategoryTreemap(
          movements: movements,
          categories: categories,
          filter: filter,
          selectedType: selectedType,
        ),
      ),
    ),
  );
}

bool _hasHorizontalScroll(WidgetTester tester) {
  final scrollables = tester.widgetList<SingleChildScrollView>(
    find.byType(SingleChildScrollView),
  );
  return scrollables.any(
    (scrollable) => scrollable.scrollDirection == Axis.horizontal,
  );
}

Color? _heatmapCellColor(WidgetTester tester, int day) {
  final widget = tester.widget(find.byKey(Key('heatmap_day_cell_$day')).first);
  final decoration = switch (widget) {
    Container(:final decoration) => decoration,
    AnimatedContainer(:final decoration) => decoration,
    _ => null,
  };
  if (decoration is BoxDecoration) return decoration.color;
  return null;
}

List<String> _periodTreemapLabels(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.byKey(
          const Key('period_category_treemap_label'),
          skipOffstage: false,
        ),
      )
      .map((text) => text.data ?? '')
      .where((text) => text.isNotEmpty)
      .toList();
}
