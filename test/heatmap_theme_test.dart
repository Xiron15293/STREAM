import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/design/stream_surface_tokens.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/period_heatmap_card.dart';

void main() {
  final movements = <Movement>[
    Movement(
      id: 'heat_1',
      title: 'Spesa 1',
      amount: 50,
      type: MovementType.expense,
      categoryId: 'exp',
      accountId: defaultAccountId,
      date: DateTime(2026, 6, 10),
      createdAt: DateTime(2026, 6, 10),
    ),
    Movement(
      id: 'heat_2',
      title: 'Spesa 2',
      amount: 75,
      type: MovementType.expense,
      categoryId: 'exp',
      accountId: defaultAccountId,
      date: DateTime(2026, 6, 18),
      createdAt: DateTime(2026, 6, 18),
    ),
  ];

  Future<void> pumpHeatmap(WidgetTester tester, StreamThemeId themeId) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: Scaffold(
          body: PeriodHeatmapCard(
            timeFilter: TimeFilter.month(2026, 6),
            movements: movements,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('PeriodHeatmapCard uses themed surface in Forest', (
    tester,
  ) async {
    final palette = StreamThemePalette.of(StreamThemeId.forest);
    final surface = StreamSurfaceTokens.card(palette, elevated: true);
    await pumpHeatmap(tester, StreamThemeId.forest);

    final container = tester.widget<Container>(
      find.byKey(const Key('period_heatmap_card')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, surface.background);
    expect(find.byKey(const Key('period_heatmap_month_grid')), findsOneWidget);
  });

  testWidgets('PeriodHeatmapCard renders in High Contrast without crashes', (
    tester,
  ) async {
    await pumpHeatmap(tester, StreamThemeId.highContrast);

    expect(find.byKey(const Key('period_heatmap_title')), findsOneWidget);
    expect(
      find.byKey(const Key('heatmap_no_horizontal_scroll_block')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
