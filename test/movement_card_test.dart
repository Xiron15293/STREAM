import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/account.dart';
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

  group('MovementCard render', () {
    testWidgets('renderizza titolo movimento', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement, category: category, account: account),
      ));
      expect(find.text('Stipendio'), findsOneWidget);
    });

    testWidgets('renderizza importo entrata con segno +', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement, category: category, account: account),
      ));
      expect(find.textContaining('+2500.00'), findsWidgets);
    });

    testWidgets('renderizza importo uscita con segno -', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: expenseMovement, category: category, account: account),
      ));
      expect(find.textContaining('-800.00'), findsWidgets);
    });

    testWidgets('renderizza categoria', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement, category: category, account: account),
      ));
      expect(find.text('Lavoro'), findsOneWidget);
    });

    testWidgets('renderizza account', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement, category: category, account: account),
      ));
      expect(find.text('Conto Corrente'), findsOneWidget);
    });

    testWidgets('entrata e uscita hanno segni diversi', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        Column(
          children: [
            MovementCard(movement: incomeMovement, category: category, account: account),
            MovementCard(movement: expenseMovement, category: category, account: account),
          ],
        ),
      ));
      expect(find.textContaining('+2500.00'), findsWidgets);
      expect(find.textContaining('-800.00'), findsWidgets);
    });

    testWidgets('showDate mostra data formattata', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement, category: category, account: account, showDate: true),
      ));
      expect(find.text('15/06/2026'), findsOneWidget);
    });

    testWidgets('nasconde data se showDate = false', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement, category: category, account: account, showDate: false),
      ));
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
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: movementWithNote, showNotes: true),
      ));
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
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: movementWithNote, showNotes: false),
      ));
      expect(find.text('Nota di test'), findsNothing);
    });

    testWidgets('renderizza senza categoria e account', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement),
      ));
      expect(find.text('Stipendio'), findsOneWidget);
      expect(find.text('inc_1'), findsOneWidget);
    });

    testWidgets('renderizza transfer con origine e destinazione', (tester) async {
      final destAccount = Account(
        id: 'acc_2',
        name: 'Carta',
        type: AccountType.card,
        color: 0xFF4B7BFF,
        createdAt: now,
      );
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(
          movement: transferMovement,
          account: account,
          destinationAccount: destAccount,
        ),
      ));
      expect(find.text('Trasferimento conto'), findsOneWidget);
      expect(find.textContaining('Da Conto Corrente → Carta'), findsOneWidget);
      expect(find.textContaining('120.00'), findsOneWidget);
    });

    testWidgets('onTap viene chiamato al tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(
          movement: incomeMovement,
          category: category,
          account: account,
          onTap: () => tapped = true,
        ),
      ));
      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('popup menu appare con onEdit', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(
          movement: incomeMovement,
          category: category,
          account: account,
          onEdit: () {},
        ),
      ));
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('popup menu assente senza callback', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        MovementCard(movement: incomeMovement, category: category, account: account),
      ));
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });
  });
}
