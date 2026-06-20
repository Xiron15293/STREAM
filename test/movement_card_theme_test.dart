import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/movement_card.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, StreamThemeId themeId) async {
    final now = DateTime(2026, 6, 20);
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: Scaffold(
          body: MovementCard(
            movement: Movement(
              id: 'theme_mov',
              title: 'Cena',
              amount: 18.5,
              type: MovementType.expense,
              categoryId: 'exp_food',
              accountId: defaultAccountId,
              date: now,
              createdAt: now,
              note: 'Con amici',
            ),
            category: const Category(
              id: 'exp_food',
              name: 'Food',
              type: MovementType.expense,
              color: 0xFFAA5500,
            ),
            account: Account(
              id: defaultAccountId,
              name: 'Main',
              type: AccountType.card,
              createdAt: now,
            ),
            showNotes: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('MovementCard renders in Midnight and Minimal Sand', (
    tester,
  ) async {
    await pumpCard(tester, StreamThemeId.midnight);
    expect(find.text('Cena'), findsOneWidget);
    expect(find.text('Con amici'), findsOneWidget);
    expect(find.byKey(const Key('movement_card_theme_mov')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpCard(tester, StreamThemeId.minimalSand);
    expect(find.text('Cena'), findsOneWidget);
    expect(find.text('Con amici'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
