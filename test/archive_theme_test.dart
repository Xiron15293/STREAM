import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/design/stream_surface_tokens.dart';
import 'package:stream_app/design/stream_theme_palette.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/daily_group.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/archive_screen.dart';
import 'package:stream_app/screens/movements_screen.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/day_header.dart';
import 'package:stream_app/widgets/movement_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
  });

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase();
    final now = DateTime(2026, 6, 20);
    await db.addMovement(
      Movement(
        id: 'archive_mov_1',
        title: 'Spesa test',
        amount: 42,
        type: MovementType.expense,
        date: now,
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        createdAt: now,
        note: 'Nota archivio',
      ),
    );
    await db.addAccount(
      Account(
        id: 'archive_acc_1',
        name: 'Secondario',
        type: AccountType.bank,
        initialBalance: 1000,
        createdAt: now,
      ),
    );
    return db;
  }

  Future<void> pumpTheme(
    WidgetTester tester,
    Widget child,
    StreamThemeId themeId,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: StreamTheme.build(StreamThemePalette.of(themeId)),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ArchiveScreen shell follows app theme', (tester) async {
    final db = await seededDb();
    await pumpTheme(tester, ArchiveScreen(db: db), StreamThemeId.forest);

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ArchiveScreen),
            matching: find.byType(Container),
          )
          .first,
    );
    final decorationColor = container.color;
    expect(decorationColor, StreamThemePalette.of(StreamThemeId.forest).canvas);
  });

  testWidgets('MovementsScreen uses theme background with Minimal Sand', (
    tester,
  ) async {
    final db = await seededDb();
    await pumpTheme(tester, MovementsScreen(db: db), StreamThemeId.minimalSand);

    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(MovementsScreen),
        matching: find.byType(Scaffold),
      ),
    );
    expect(
      scaffold.backgroundColor,
      StreamThemePalette.of(StreamThemeId.minimalSand).canvas,
    );
  });

  testWidgets('MovementCard uses theme surface and border', (tester) async {
    final palette = StreamThemePalette.of(StreamThemeId.highContrast);
    final surface = StreamSurfaceTokens.card(palette);
    final now = DateTime(2026, 6, 20);
    await pumpTheme(
      tester,
      Scaffold(
        body: MovementCard(
          movement: Movement(
            id: 'card_1',
            title: 'Carta tema',
            amount: 10,
            type: MovementType.expense,
            date: now,
            categoryId: 'exp_1',
            accountId: defaultAccountId,
            createdAt: now,
            note: 'Visibile',
          ),
          category: const Category(
            id: 'exp_1',
            name: 'Casa',
            type: MovementType.expense,
            color: 0xFFAA0000,
          ),
          account: Account(
            id: defaultAccountId,
            name: 'Principale',
            type: AccountType.bank,
            createdAt: now,
          ),
          showNotes: true,
        ),
      ),
      StreamThemeId.highContrast,
    );

    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.byKey(const Key('movement_card_card_1')),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, surface.background);
    expect((decoration.border! as Border).top.color, surface.border);
  });

  testWidgets('DayHeader remains readable in High Contrast', (tester) async {
    final palette = StreamThemePalette.of(StreamThemeId.highContrast);
    final now = DateTime(2026, 6, 20);
    await pumpTheme(
      tester,
      Scaffold(
        body: DayHeader(
          group: DailyMovementGroup(
            date: now,
            movements: [
              Movement(
                id: 'd1',
                title: 'Entrata',
                amount: 100,
                type: MovementType.income,
                date: now,
                categoryId: 'inc_1',
                accountId: defaultAccountId,
                createdAt: now,
              ),
            ],
          ),
        ),
      ),
      StreamThemeId.highContrast,
    );

    final headerNumber = tester.widget<Text>(find.text('20'));
    expect(headerNumber.style?.color, palette.textPrimary);
    expect(tester.takeException(), isNull);
  });
}
