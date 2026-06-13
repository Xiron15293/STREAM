import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_icon_library.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/subcategory.dart';
import 'package:stream_app/widgets/movement_card.dart';
import 'package:stream_app/theme.dart';

Widget wrapWithTheme(Widget child) {
  return MaterialApp(
    theme: StreamTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  final now = DateTime(2026, 6, 15);

  final incomeMovement = Movement(
    id: 'm1',
    title: 'Stipendio',
    amount: 2500,
    type: MovementType.income,
    date: now,
    categoryId: 'inc_1',
    createdAt: now,
  );

  final expenseMovement = Movement(
    id: 'm2',
    title: 'Affitto',
    amount: 800,
    type: MovementType.expense,
    date: now,
    categoryId: 'exp_1',
    createdAt: now,
  );

  final transferMovement = Movement(
    id: 'm3',
    title: 'Trasferimento conto',
    amount: 120,
    type: MovementType.transfer,
    date: now,
    categoryId: '',
    accountId: 'acc_1',
    destinationAccountId: 'acc_2',
    createdAt: now,
  );

  final category = Category(
    id: 'inc_1',
    name: 'Lavoro',
    type: MovementType.income,
    color: 0xFF34C759,
  );

  final account = Account(
    id: 'acc_1',
    name: 'Conto Corrente',
    type: AccountType.bank,
    color: 0xFF4B7BFF,
    createdAt: now,
  );

  final subcategory = Subcategory(
    id: 'sub_1',
    categoryId: 'inc_1',
    name: 'Bonus',
    iconKey: 'coins',
    color: 0xFFFFA726,
    createdAt: now,
  );

  group('MovementCard render', () {
    testWidgets('renderizza titolo movimento', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
          ),
        ),
      );
      expect(find.text('Stipendio'), findsOneWidget);
    });

    testWidgets('renderizza importo entrata con segno +', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
          ),
        ),
      );
      expect(find.textContaining('+2500.00'), findsWidgets);
    });

    testWidgets('renderizza importo uscita con segno -', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: expenseMovement,
            category: category,
            account: account,
          ),
        ),
      );
      expect(find.textContaining('-800.00'), findsWidgets);
    });

    testWidgets('renderizza categoria', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
          ),
        ),
      );
      expect(find.text('Lavoro'), findsOneWidget);
    });

    testWidgets('renderizza account', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
          ),
        ),
      );
      expect(find.text('Conto Corrente'), findsOneWidget);
    });

    testWidgets('renderizza categoria e sottocategoria in formato combinato', (
      tester,
    ) async {
      final movementWithSub = incomeMovement.copyWith(
        subcategoryId: subcategory.id,
      );
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: movementWithSub,
            category: category,
            subcategory: subcategory,
            account: account,
          ),
        ),
      );
      expect(find.text('Lavoro / Bonus'), findsOneWidget);
      expect(find.text('Bonus'), findsNothing);
    });

    testWidgets('entrata e uscita hanno segni diversi', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: [
              MovementCard(
                movement: incomeMovement,
                category: category,
                account: account,
              ),
              MovementCard(
                movement: expenseMovement,
                category: category,
                account: account,
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('+2500.00'), findsWidgets);
      expect(find.textContaining('-800.00'), findsWidgets);
    });

    testWidgets('showDate mostra data formattata', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
            showDate: true,
          ),
        ),
      );
      expect(find.text('15/06/2026'), findsOneWidget);
    });

    testWidgets('nasconde data se showDate = false', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
            showDate: false,
          ),
        ),
      );
      expect(find.text('15/06/2026'), findsNothing);
    });

    testWidgets('mostra nota se showNotes e nota presente', (tester) async {
      final movementWithNote = Movement(
        id: 'm3',
        title: 'Spesa',
        amount: 50,
        type: MovementType.expense,
        date: now,
        categoryId: 'exp_1',
        note: 'Nota di test',
        createdAt: now,
      );
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(movement: movementWithNote, showNotes: true),
        ),
      );
      expect(find.text('Nota di test'), findsOneWidget);
    });

    testWidgets('nasconde nota se showNotes = false', (tester) async {
      final movementWithNote = Movement(
        id: 'm3',
        title: 'Spesa',
        amount: 50,
        type: MovementType.expense,
        date: now,
        categoryId: 'exp_1',
        note: 'Nota di test',
        createdAt: now,
      );
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(movement: movementWithNote, showNotes: false),
        ),
      );
      expect(find.text('Nota di test'), findsNothing);
    });

    testWidgets('renderizza senza categoria e account', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(MovementCard(movement: incomeMovement)),
      );
      expect(find.text('Stipendio'), findsOneWidget);
      expect(find.text('inc_1'), findsOneWidget);
    });

    testWidgets('renderizza transfer con origine e destinazione', (
      tester,
    ) async {
      final destAccount = Account(
        id: 'acc_2',
        name: 'Carta',
        type: AccountType.card,
        color: 0xFF4B7BFF,
        createdAt: now,
      );
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: transferMovement,
            account: account,
            destinationAccount: destAccount,
          ),
        ),
      );
      expect(find.text('Trasferimento conto'), findsOneWidget);
      expect(find.textContaining('Da Conto Corrente → Carta'), findsOneWidget);
      expect(find.textContaining('120.00'), findsOneWidget);
    });

    testWidgets('onTap viene chiamato al tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('popup menu appare con onEdit', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
            onEdit: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('popup menu assente senza callback', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          MovementCard(
            movement: incomeMovement,
            category: category,
            account: account,
          ),
        ),
      );
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets(
      'aggiorna subito icona sottocategoria dopo update della madre',
      (tester) async {
        final db = AppDatabase();
        await db.addCategory(
          'Tempo libero',
          MovementType.expense,
          0xFF1E88E5,
          iconKey: 'star',
        );
        final parent = db.categories.firstWhere(
          (c) => c.name == 'Tempo libero',
        );
        await db.createSubcategory(
          parent.id,
          'Ristorante',
          iconKey: parent.iconKey,
          color: parent.color,
        );
        final sub = db.subcategories.firstWhere((s) => s.name == 'Ristorante');
        final movement = Movement(
          id: 'm_refresh',
          title: 'Cena',
          amount: 18,
          type: MovementType.expense,
          date: now,
          categoryId: parent.id,
          subcategoryId: sub.id,
          createdAt: now,
        );

        await tester.pumpWidget(
          wrapWithTheme(
            ListenableBuilder(
              listenable: db,
              builder: (context, _) {
                final liveCategory = db.categories.firstWhere(
                  (c) => c.id == parent.id,
                );
                final liveSub = db.subcategories.firstWhere(
                  (s) => s.id == sub.id,
                );
                return MovementCard(
                  movement: movement,
                  category: liveCategory,
                  subcategory: liveSub,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await db.updateCategory(
          parent.id,
          parent.name,
          0xFF009688,
          iconKey: 'wallet',
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(StreamIconLibrary.getIcon('wallet')), findsWidgets);
        final liveSub = db.subcategories.firstWhere((s) => s.id == sub.id);
        expect(liveSub.color, 0xFF009688);
        expect(liveSub.iconKey, 'wallet');
      },
    );
  });
}
