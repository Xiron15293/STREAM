import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/widgets/time_filter_bar.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  ThemeData testTheme() => ThemeData(useMaterial3: true).copyWith(
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
  );

  group('TimeFilter Picker Routing', () {
    testWidgets('Day opens only day picker (calendar)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Material(
            child: TimeFilterBar(
              activeFilter: TimeFilter.day(DateTime(2026, 6, 22)),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('22 giugno 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.byKey(const Key('time_filter_week_picker')), findsNothing);
      expect(
        find.byKey(const Key('time_filter_month_picker_month_wheel')),
        findsNothing,
      );
      expect(find.byKey(const Key('time_filter_year_picker')), findsNothing);
    });

    testWidgets('Week opens only week list', (tester) async {
      final fixedNow = DateTime(2026, 6, 21);
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Material(
            child: TimeFilterBar(
              activeFilter: TimeFilter.week(fixedNow),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text(TimeFilter.week(fixedNow).label));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('time_filter_week_picker')), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(
        find.byKey(const Key('time_filter_month_picker_month_wheel')),
        findsNothing,
      );
      expect(find.byKey(const Key('time_filter_year_picker')), findsNothing);
      expect(find.byType(CupertinoPicker), findsNothing);
    });

    testWidgets('Month opens only month+year wheel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Material(
            child: TimeFilterBar(
              activeFilter: TimeFilter.month(2026, 6),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('giugno 2026'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('time_filter_month_picker_month_wheel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('time_filter_month_picker_year_wheel')),
        findsOneWidget,
      );
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byKey(const Key('time_filter_week_picker')), findsNothing);
      expect(find.byKey(const Key('time_filter_year_picker')), findsNothing);
      expect(find.byType(CupertinoPicker), findsNWidgets(2));
    });

    testWidgets('Year opens only year wheel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Material(
            child: TimeFilterBar(
              activeFilter: TimeFilter.year(2026),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('time_filter_year_picker')), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byKey(const Key('time_filter_week_picker')), findsNothing);
      expect(
        find.byKey(const Key('time_filter_month_picker_month_wheel')),
        findsNothing,
      );
      expect(find.byType(CupertinoPicker), findsOneWidget);
    });

    testWidgets('Interval opens only interval picker', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Material(
            child: TimeFilterBar(
              activeFilter: TimeFilter.customRange(
                DateTime(2026, 6, 15),
                DateTime(2026, 6, 30),
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('15 giu 2026 \u2192 30 giu 2026'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('time_filter_interval_picker_sheet')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('time_filter_week_picker')), findsNothing);
      expect(
        find.byKey(const Key('time_filter_month_picker_month_wheel')),
        findsNothing,
      );
      expect(find.byKey(const Key('time_filter_year_picker')), findsNothing);
    });
  });
}
