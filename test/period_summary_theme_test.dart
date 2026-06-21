import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/design/stream_surface_tokens.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/period_summary_card.dart';

void main() {
  final movements = <Movement>[
    Movement(
      id: 'ps_income',
      title: 'Stipendio',
      amount: 1200,
      type: MovementType.income,
      categoryId: 'inc',
      accountId: defaultAccountId,
      date: DateTime(2026, 6, 20),
      createdAt: DateTime(2026, 6, 20),
    ),
    Movement(
      id: 'ps_expense',
      title: 'Spesa',
      amount: 250,
      type: MovementType.expense,
      categoryId: 'exp',
      accountId: defaultAccountId,
      date: DateTime(2026, 6, 20),
      createdAt: DateTime(2026, 6, 20),
    ),
  ];

  Future<void> pumpSummary(WidgetTester tester, StreamThemeId themeId) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: Scaffold(
          body: PeriodSummaryCard(
            timeFilter: TimeFilter.day(DateTime(2026, 6, 20)),
            movements: movements,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('PeriodSummaryCard stays readable in Midnight', (tester) async {
    final palette = StreamThemePalette.of(StreamThemeId.midnight);
    final surface = StreamSurfaceTokens.card(palette, elevated: true);
    await pumpSummary(tester, StreamThemeId.midnight);

    expect(find.byKey(const Key('period_summary_card')), findsOneWidget);
    expect(find.text('Entrate del giorno'), findsOneWidget);
    expect(find.text('Uscite del giorno'), findsOneWidget);
    expect(find.text('Saldo del giorno'), findsOneWidget);

    final container = tester.widget<Container>(
      find.byKey(const Key('period_summary_card')),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, surface.background);
    expect((decoration.border! as Border).top.color, surface.border);
  });

  testWidgets('PeriodSummaryCard stays readable in Minimal Sand', (
    tester,
  ) async {
    await pumpSummary(tester, StreamThemeId.minimalSand);

    expect(find.byKey(const Key('period_summary_income')), findsOneWidget);
    expect(find.byKey(const Key('period_summary_expense')), findsOneWidget);
    expect(find.byKey(const Key('period_summary_balance')), findsOneWidget);
    expect(find.byKey(const Key('period_summary_count')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
