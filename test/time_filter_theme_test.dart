import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/time_filter_bar.dart';

void main() {
  Future<void> pumpFilter(
    WidgetTester tester,
    StreamThemeId themeId,
    TimeFilter filter,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: Scaffold(
          body: TimeFilterBar(activeFilter: filter, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('TimeFilterBar shows Mese Anno Intervallo in Stream Classic', (
    tester,
  ) async {
    await pumpFilter(
      tester,
      StreamThemeId.streamClassic,
      TimeFilter.month(2026, 6),
    );

    expect(find.text('Mese'), findsOneWidget);
    expect(find.text('Anno'), findsOneWidget);
    expect(find.text('Intervallo'), findsOneWidget);
  });

  testWidgets('TimeFilterBar keeps selected state readable in High Contrast', (
    tester,
  ) async {
    await pumpFilter(tester, StreamThemeId.highContrast, TimeFilter.year(2026));

    final segmented = tester.widget<SegmentedButton<TimeFilterMode>>(
      find.byType(SegmentedButton<TimeFilterMode>),
    );
    expect(segmented.selected, {TimeFilterMode.year});
    expect(find.text('2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
