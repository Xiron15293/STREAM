import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/design/stream_kpi_style.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/utils/analytics_metrics.dart';
import 'package:stream_app/widgets/charts/stream_donut_chart.dart';

void main() {
  Future<void> pumpDonut(
    WidgetTester tester,
    StreamChartStyleId style,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(
          StreamThemePalette.of(StreamThemeId.streamClassic),
          chartStyle: style,
        ),
        home: Scaffold(
          body: StreamDonutChart(
            slices: const [
              DonutSlice(label: 'A', value: 60, color: Colors.red),
              DonutSlice(label: 'B', value: 40, color: Colors.green),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('donut keeps external labels and empty internal titles', (tester) async {
    await pumpDonut(tester, StreamChartStyleId.editorial);

    expect(find.text('60.0%'), findsOneWidget);
    expect(find.text('40.0%'), findsOneWidget);

    final pieChart = tester.widget<PieChart>(find.byType(PieChart));
    final data = pieChart.data;
    expect(data.sections.every((section) => section.title.isEmpty), isTrue);
  });
}
