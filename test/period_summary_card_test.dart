import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/utils/movement_period_metrics.dart';
import 'package:stream_app/widgets/period_heatmap_card.dart';
import 'package:stream_app/widgets/period_summary_card.dart';

void main() {
  final movements = [
    Movement(
      id: 'income_1',
      title: 'Entrata',
      amount: 120,
      type: MovementType.income,
      date: DateTime(2026, 5, 2, 10),
      categoryId: 'inc_1',
      accountId: defaultAccountId,
      createdAt: DateTime(2026, 5, 2, 10),
    ),
    Movement(
      id: 'expense_1',
      title: 'Uscita',
      amount: 45,
      type: MovementType.expense,
      date: DateTime(2026, 5, 2, 12),
      categoryId: 'exp_1',
      accountId: defaultAccountId,
      createdAt: DateTime(2026, 5, 2, 12),
    ),
    Movement(
      id: 'transfer_1',
      title: 'Transfer',
      amount: 10,
      type: MovementType.transfer,
      date: DateTime(2026, 5, 2, 18),
      categoryId: 'exp_1',
      accountId: defaultAccountId,
      destinationAccountId: defaultAccountId,
      createdAt: DateTime(2026, 5, 2, 18),
    ),
    Movement(
      id: 'expense_2',
      title: 'Uscita range',
      amount: 30,
      type: MovementType.expense,
      date: DateTime(2026, 5, 14, 9),
      categoryId: 'exp_1',
      accountId: defaultAccountId,
      createdAt: DateTime(2026, 5, 14, 9),
    ),
    Movement(
      id: 'expense_outside',
      title: 'Fuori range',
      amount: 99,
      type: MovementType.expense,
      date: DateTime(2026, 5, 20, 9),
      categoryId: 'exp_1',
      accountId: defaultAccountId,
      createdAt: DateTime(2026, 5, 20, 9),
    ),
  ];

  Future<void> pumpSummary(
    WidgetTester tester, {
    required TimeFilter filter,
    required List<Movement> filteredMovements,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodSummaryCard(
            timeFilter: filter,
            movements: filteredMovements,
          ),
        ),
      ),
    );
  }

  test('period metrics calculate income expense balance and count', () {
    final metrics = MovementPeriodMetrics.fromMovements(movements.take(3));

    expect(metrics.totalIncome, 120);
    expect(metrics.totalExpense, 45);
    expect(metrics.netBalance, 75);
    expect(metrics.movementCount, 3);
  });

  testWidgets('PeriodSummaryCard renders day summary', (tester) async {
    final filter = TimeFilter.day(DateTime(2026, 5, 2));
    await pumpSummary(
      tester,
      filter: filter,
      filteredMovements: movements.take(3).toList(),
    );

    expect(find.text('2 maggio 2026'), findsOneWidget);
    expect(find.text('120,00 €'), findsOneWidget);
    expect(find.text('45,00 €'), findsOneWidget);
    expect(find.text('+75,00 €'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('PeriodSummaryCard renders month summary', (tester) async {
    final filter = TimeFilter.month(2026, 5);
    await pumpSummary(
      tester,
      filter: filter,
      filteredMovements: movements.take(4).toList(),
    );

    expect(find.text('Maggio 2026'), findsOneWidget);
    expect(find.text('120,00 €'), findsOneWidget);
    expect(find.text('75,00 €'), findsOneWidget);
    expect(find.text('+45,00 €'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('PeriodSummaryCard renders year summary', (tester) async {
    final filter = TimeFilter.year(2026);
    await pumpSummary(tester, filter: filter, filteredMovements: movements);

    expect(find.text('2026'), findsWidgets);
    expect(find.text('120,00 €'), findsOneWidget);
    expect(find.text('174,00 €'), findsOneWidget);
    expect(find.text('-54,00 €'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('PeriodSummaryCard renders range summary', (tester) async {
    final filter = TimeFilter.customRange(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 14),
    );
    await pumpSummary(
      tester,
      filter: filter,
      filteredMovements: movements.where((movement) {
        return !movement.date.isBefore(DateTime(2026, 5, 1)) &&
            !movement.date.isAfter(DateTime(2026, 5, 14, 23, 59));
      }).toList(),
    );

    expect(find.text('1 mag 2026 – 14 mag 2026'), findsOneWidget);
    expect(find.text('120,00 €'), findsOneWidget);
    expect(find.text('75,00 €'), findsOneWidget);
    expect(find.text('+45,00 €'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets(
    'PeriodHeatmapCard shows monthly and yearly variants only when expected',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                PeriodHeatmapCard(
                  timeFilter: TimeFilter.month(2026, 5),
                  movements: movements
                      .where((movement) => movement.date.month == 5)
                      .toList(),
                ),
                PeriodHeatmapCard(
                  timeFilter: TimeFilter.year(2026),
                  movements: movements,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('period_heatmap_month_surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('period_heatmap_year_surface')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('annual_heatmap')), findsOneWidget);
      expect(
        find.byKey(const Key('annual_heatmap_year_title')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('annual_heatmap_subtitle')), findsOneWidget);
      expect(find.text('Andamento annuale'), findsOneWidget);
      expect(find.text('Heatmap annuale compatta dei 12 mesi'), findsNothing);
      expect(find.byKey(const Key('annual_heatmap_legend')), findsOneWidget);
      for (int month = 1; month <= 12; month++) {
        expect(find.byKey(Key('annual_heatmap_month_label_$month')), findsOneWidget);
      }
    },
  );

  testWidgets(
    'annual heatmap keeps unique day keys per month and custom colors',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                PeriodHeatmapCard(
                  timeFilter: TimeFilter.year(2026),
                  movements: [
                    Movement(
                      id: 'jan_day',
                      title: 'Gen',
                      amount: 0.5,
                      type: MovementType.expense,
                      date: DateTime(2026, 1, 1, 10),
                      categoryId: 'exp_1',
                      accountId: defaultAccountId,
                      createdAt: DateTime(2026, 1, 1, 10),
                    ),
                    Movement(
                      id: 'feb_day',
                      title: 'Feb',
                      amount: 0.5,
                      type: MovementType.expense,
                      date: DateTime(2026, 2, 1, 10),
                      categoryId: 'exp_1',
                      accountId: defaultAccountId,
                      createdAt: DateTime(2026, 2, 1, 10),
                    ),
                    Movement(
                      id: 'transfer_ignored',
                      title: 'Transfer',
                      amount: 500,
                      type: MovementType.transfer,
                      date: DateTime(2026, 1, 2, 10),
                      categoryId: 'exp_1',
                      accountId: defaultAccountId,
                      destinationAccountId: defaultAccountId,
                      createdAt: DateTime(2026, 1, 2, 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('annual_heatmap_day_2026_1_1')), findsOneWidget);
      expect(find.byKey(const Key('annual_heatmap_day_2026_2_1')), findsOneWidget);
      expect(_annualHeatmapCellColor(tester, 2026, 1, 2), Colors.transparent);
    },
  );

  testWidgets('PeriodHeatmapCard for range shows day cells in range only', (
    tester,
  ) async {
    final filter = TimeFilter.customRange(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 14),
    );
    final filteredMovements = movements.where((movement) {
      return !movement.date.isBefore(DateTime(2026, 5, 1)) &&
          !movement.date.isAfter(DateTime(2026, 5, 14, 23, 59));
    }).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodHeatmapCard(
            timeFilter: filter,
            movements: filteredMovements,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('period_heatmap_range_surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('range_period_income')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('range_period_expense')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('range_period_balance')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('range_period_movements_count')),
      findsOneWidget,
    );

    // Day in range (May 2) exists
    expect(
      find.byKey(const Key('range_heatmap_day_2026_5_2')),
      findsOneWidget,
    );

    // Day in range (May 14) exists
    expect(
      find.byKey(const Key('range_heatmap_day_2026_5_14')),
      findsOneWidget,
    );

    // Day outside range (May 20) does not exist
    expect(
      find.byKey(const Key('range_heatmap_day_2026_5_20')),
      findsNothing,
    );

    // Day outside range (Apr 30) does not exist
    expect(
      find.byKey(const Key('range_heatmap_day_2026_4_30')),
      findsNothing,
    );
  });

  testWidgets('range heatmap with selectedPeriodDay shows chip and clear button', (
    tester,
  ) async {
    final filter = TimeFilter.customRange(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 14),
    );
    final filteredMovements = movements.where((movement) {
      return !movement.date.isBefore(DateTime(2026, 5, 1)) &&
          !movement.date.isAfter(DateTime(2026, 5, 14, 23, 59));
    }).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodHeatmapCard(
            timeFilter: filter,
            movements: filteredMovements,
            selectedPeriodDay: DateTime(2026, 5, 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('range_selected_day_chip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('range_clear_selected_day')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('period_selected_day_2026_5_2')),
      findsOneWidget,
    );
  });

  testWidgets('range heatmap onClearSelectedDay is called when clear button tapped', (
    tester,
  ) async {
    final filter = TimeFilter.customRange(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 14),
    );
    final filteredMovements = movements.where((movement) {
      return !movement.date.isBefore(DateTime(2026, 5, 1)) &&
          !movement.date.isAfter(DateTime(2026, 5, 14, 23, 59));
    }).toList();

    bool cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodHeatmapCard(
            timeFilter: filter,
            movements: filteredMovements,
            selectedPeriodDay: DateTime(2026, 5, 2),
            onClearSelectedDay: () => cleared = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('range_clear_selected_day')));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
  });

  testWidgets('range heatmap >6 months shows semester grid blocks', (
    tester,
  ) async {
    final filter = TimeFilter.customRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 12, 31),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeriodHeatmapCard(
              timeFilter: filter,
              movements: movements,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('range_semester_heatmap')),
      findsOneWidget,
    );
  });

  testWidgets('range heatmap cross-year >6 months shows semester blocks', (
    tester,
  ) async {
    final filter = TimeFilter.customRange(
      DateTime(2026, 3, 1),
      DateTime(2027, 6, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeriodHeatmapCard(
              timeFilter: filter,
              movements: movements,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('range_semester_heatmap')),
      findsOneWidget,
    );
  });

  testWidgets('range heatmap partial semester shows only days in range', (
    tester,
  ) async {
    final filter = TimeFilter.customRange(
      DateTime(2026, 3, 1),
      DateTime(2026, 9, 30),
    );

    final filteredMovements = movements.where((m) =>
        !m.date.isBefore(DateTime(2026, 3, 1)) &&
        !m.date.isAfter(DateTime(2026, 9, 30, 23, 59))).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeriodHeatmapCard(
              timeFilter: filter,
              movements: filteredMovements,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('period_heatmap_range_surface')),
      findsOneWidget,
    );
  });
}

Color? _annualHeatmapCellColor(WidgetTester tester, int year, int month, int day) {
  final container = tester.widget<Container>(
    find.byKey(Key('annual_heatmap_day_${year}_${month}_$day')).first,
  );
  final decoration = container.decoration as BoxDecoration?;
  return decoration?.color;
}
