import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/services/backup_service.dart';
import 'package:stream_app/widgets/movement_calculator_pad.dart';
import 'package:stream_app/widgets/movement_picker.dart';
import 'package:stream_app/widgets/movement_text_suggestions.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  setUp(() {
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
  });

  tearDown(() {
    PreferencesService.currencyNotifier.value = AppCurrency.eur;
  });

  group('AddMovementFlow UI', () {
    testWidgets('tap su + Movimento apre flow guidato', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);

      await _openAddMovement(tester);

      expect(
        find.byKey(const Key('add_movement_category_step')),
        findsOneWidget,
      );
      expect(find.text('Spesa'), findsWidgets);
      expect(find.text('Entrata'), findsWidgets);
      expect(find.text('Trasferimento'), findsWidgets);
    });

    testWidgets('cambio tab Entrata / Spesa / Trasferimento', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await tester.tap(find.text('Entrata').last);
      await tester.pumpAndSettle();
      expect(find.text('Scegli categoria entrata'), findsOneWidget);

      await tester.tap(find.text('Spesa').last);
      await tester.pumpAndSettle();
      expect(find.text('Scegli categoria spesa'), findsOneWidget);

      await tester.tap(find.text('Trasferimento').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('add_movement_transfer_step')),
        findsOneWidget,
      );
    });

    testWidgets('Spesa mostra categorie spesa', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      expect(find.text('Casa'), findsWidgets);
      expect(find.text('Spesa'), findsWidgets);
      expect(find.text('Stipendio'), findsNothing);
    });

    testWidgets('Entrata mostra categorie entrata', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await tester.tap(find.text('Entrata').last);
      await tester.pumpAndSettle();

      expect(find.text('Stipendio'), findsWidgets);
      expect(find.text('Rimborso'), findsWidgets);
      expect(find.text('Casa'), findsNothing);
    });

    testWidgets('Trasferimento mostra conti e non categorie', (tester) async {
      final db = AppDatabase();
      await db.addAccount(
        Account(
          id: 'acc_2',
          name: 'Revolut',
          type: AccountType.bank,
          createdAt: DateTime(2026, 6, 15),
        ),
      );
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await tester.tap(find.text('Trasferimento').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('add_movement_transfer_step')),
        findsOneWidget,
      );
      expect(find.text('Conto origine'), findsOneWidget);
      expect(find.text('Conto destinazione'), findsOneWidget);
      expect(find.byKey(const Key('transfer_origin_list')), findsOneWidget);
      expect(
        find.byKey(const Key('transfer_destination_list')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('add_movement_category_step')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('transfer_destination_chip_acc_2')),
        findsNothing,
      );
    });

    testWidgets(
      'selezione categoria spesa apre form spesa e chip conto funziona',
      (tester) async {
        final db = AppDatabase();
        await db.addAccount(
          Account(
            id: 'acc_2',
            name: 'Contanti',
            type: AccountType.cash,
            createdAt: DateTime(2026, 6, 15),
          ),
        );
        await db.createSubcategory('exp_2', 'Affitto');
        final subId = db.getSubcategoriesForCategory('exp_2').single.id;
        await _pumpApp(tester, db);
        await _openAddMovement(tester);

        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_2')),
        );
        expect(
          find.byKey(const Key('add_movement_subcategory_step')),
          findsOneWidget,
        );
        await _tapVisible(tester, find.byKey(Key('subcategory_option_$subId')));
        expect(
          find.byKey(const Key('add_movement_details_step')),
          findsOneWidget,
        );
        expect(find.text('Nuova spesa'), findsOneWidget);

        await _tapVisible(tester, find.text('Da conto').last);
        expect(
          find.byKey(const Key('add_movement_account_step')),
          findsOneWidget,
        );
        await _tapVisible(
          tester,
          find.byKey(const Key('account_option_acc_2')),
        );
        expect(
          find.byKey(const Key('add_movement_details_step')),
          findsOneWidget,
        );
      },
    );

    testWidgets('selezione categoria entrata + conto apre form entrata', (
      tester,
    ) async {
      final db = AppDatabase();
      await db.addAccount(
        Account(
          id: 'acc_2',
          name: 'Contanti',
          type: AccountType.cash,
          createdAt: DateTime(2026, 6, 15),
        ),
      );
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await tester.tap(find.text('Entrata').last);
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.byKey(const Key('category_option_inc_1')));
      await _tapVisible(
        tester,
        find.byKey(const Key('income_account_chip_acc_2')),
      );

      expect(
        find.byKey(const Key('add_movement_details_step')),
        findsOneWidget,
      );
      expect(find.text('Nuova entrata'), findsOneWidget);
    });

    testWidgets(
      'selezione origine/destinazione trasferimento apre form trasferimento',
      (tester) async {
        final db = AppDatabase();
        await db.addAccount(
          Account(
            id: 'acc_2',
            name: 'Contanti',
            type: AccountType.cash,
            createdAt: DateTime(2026, 6, 15),
          ),
        );
        await _pumpApp(tester, db);
        await _openAddMovement(tester);

        await tester.tap(find.text('Trasferimento').last);
        await tester.pumpAndSettle();
        await _tapVisible(
          tester,
          find.byKey(const Key('transfer_origin_option_acc_default')),
        );
        await _tapVisible(
          tester,
          find.byKey(const Key('transfer_destination_option_acc_2')),
        );
        await _tapVisible(
          tester,
          find.byKey(const Key('transfer_continue_button')),
        );

        expect(
          find.byKey(const Key('add_movement_details_step')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('movement_title_field')), findsOneWidget);
      },
    );

    testWidgets('origine e destinazione uguali bloccano il trasferimento', (
      tester,
    ) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await tester.tap(find.text('Trasferimento').last);
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('transfer_origin_option_acc_default')),
      );
      await _tapVisible(
        tester,
        find.byKey(const Key('transfer_destination_option_acc_default')),
      );

      expect(find.byKey(const Key('transfer_continue_button')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('transfer_continue_button')),
            )
            .onPressed,
        isNull,
      );
      expect(
        find.byKey(const Key('transfer_same_account_error')),
        findsOneWidget,
      );
    });

    testWidgets(
      'liste trasferimento mostrano tutti i conti attivi senza duplicare la destinazione',
      (tester) async {
        final db = AppDatabase();
        await db.addAccount(
          Account(
            id: 'acc_2',
            name: 'Revolut',
            type: AccountType.bank,
            createdAt: DateTime(2026, 6, 15),
          ),
        );
        await db.addAccount(
          Account(
            id: 'acc_3',
            name: 'Contanti',
            type: AccountType.cash,
            createdAt: DateTime(2026, 6, 15),
          ),
        );
        await _pumpApp(tester, db);
        await _openAddMovement(tester);

        await tester.tap(find.text('Trasferimento').last);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('transfer_origin_list')), findsOneWidget);
        expect(
          find.byKey(const Key('transfer_destination_list')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_origin_option_acc_default')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_origin_option_acc_2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_origin_option_acc_3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_destination_option_acc_default')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_destination_option_acc_2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_destination_option_acc_3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('transfer_destination_chip_acc_default')),
          findsNothing,
        );
        expect(find.text('I tuoi conti'), findsNothing);
      },
    );

    testWidgets('calculator pad mostra + - * / e backspace funziona', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MovementCalculatorPad(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('movement_pad_+')), findsOneWidget);
      expect(find.byKey(const Key('movement_pad_-')), findsOneWidget);
      expect(find.byKey(const Key('movement_pad_*')), findsOneWidget);
      expect(find.byKey(const Key('movement_pad_/')), findsOneWidget);

      await tester.tap(find.byKey(const Key('movement_pad_1')));
      await tester.tap(find.byKey(const Key('movement_pad_2')));
      await tester.pumpAndSettle();
      expect(controller.text, '12');

      await tester.tap(find.byKey(const Key('movement_pad_backspace')));
      await tester.pumpAndSettle();
      expect(controller.text, '1');
    });

    testWidgets('data modificabile tramite date picker', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      await tester.tap(find.byKey(const Key('movement_date_field')));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsWidgets);
    });

    testWidgets('data singola non viene duplicata nel testo', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      final now = DateTime.now();
      final monthNames = [
        'gennaio',
        'febbraio',
        'marzo',
        'aprile',
        'maggio',
        'giugno',
        'luglio',
        'agosto',
        'settembre',
        'ottobre',
        'novembre',
        'dicembre',
      ];
      final dateText = '${now.day} ${monthNames[now.month - 1]} ${now.year}';

      expect(find.text('$dateText, $dateText'), findsNothing);
      expect(find.textContaining(dateText), findsWidgets);
    });

    testWidgets(
      'importo sticky compatto compare dopo scroll e segue l input live',
      (tester) async {
        final db = AppDatabase();
        await _pumpMovementPickerSheet(tester, db);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        expect(
          find.byKey(const Key('movement_amount_display')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('movement_amount_sticky')), findsNothing);

        await tester.drag(
          find.byKey(const Key('add_movement_details_step')),
          const Offset(0, -700),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('movement_amount_sticky')), findsOneWidget);
        expect(find.text('0 €'), findsWidgets);

        await _tapPadKey(tester, 'movement_pad_5');
        await _tapPadKey(tester, 'movement_pad_0');
        await tester.pumpAndSettle();

        expect(_amountDisplayText(tester), '50');
        expect(
          find.descendant(
            of: find.byKey(const Key('movement_amount_sticky')),
            matching: find.text('50 €'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'sticky amount usa la valuta globale selezionata senza cambiare il valore',
      (tester) async {
        PreferencesService.currencyNotifier.value = AppCurrency.chf;
        final db = AppDatabase();
        await _pumpMovementPickerSheet(tester, db);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        await tester.drag(
          find.byKey(const Key('add_movement_details_step')),
          const Offset(0, -700),
        );
        await tester.pumpAndSettle();

        await _tapPadKey(tester, 'movement_pad_5');
        await _tapPadKey(tester, 'movement_pad_0');
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('movement_amount_sticky')),
            matching: find.text('50 CHF'),
          ),
          findsOneWidget,
        );
        expect(_amountDisplayText(tester), '50');
      },
    );

    testWidgets(
      'X e check restano nel header locale del flow e non al top globale',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final db = AppDatabase();
        await _pumpMovementPickerSheet(tester, db);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        final globalCloseTop = tester
            .getTopLeft(find.byIcon(Icons.close).first)
            .dy;
        final localHeaderTop = tester
            .getTopLeft(find.byKey(const Key('movement_details_header')))
            .dy;
        final localCloseTop = tester
            .getTopLeft(find.byKey(const Key('movement_close_top_button')))
            .dy;
        final localSubmitTop = tester
            .getTopLeft(find.byKey(const Key('movement_submit_top_button')))
            .dy;

        expect(localHeaderTop, greaterThan(globalCloseTop));
        expect(localCloseTop, greaterThan(globalCloseTop));
        expect(localSubmitTop, greaterThan(globalCloseTop));
      },
    );

    testWidgets(
      'header locale resta accessibile dopo scroll e allineato allo sticky amount',
      (tester) async {
        final db = AppDatabase();
        await _pumpMovementPickerSheet(tester, db);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        final headerTopBefore = tester
            .getTopLeft(find.byKey(const Key('movement_details_header')))
            .dy;

        await tester.drag(
          find.byKey(const Key('add_movement_details_step')),
          const Offset(0, -700),
        );
        await tester.pumpAndSettle();

        final headerRect = tester.getRect(
          find.byKey(const Key('movement_details_header')),
        );
        final stickyRect = tester.getRect(
          find.byKey(const Key('movement_amount_sticky')),
        );

        expect(
          tester
              .getTopLeft(find.byKey(const Key('movement_details_header')))
              .dy,
          headerTopBefore,
        );
        expect(stickyRect.top, greaterThanOrEqualTo(headerRect.bottom));
      },
    );

    testWidgets('tap X chiude il flow dettaglio locale', (tester) async {
      final db = AppDatabase();
      await _pumpMovementPickerSheet(tester, db);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      await _tapVisible(
        tester,
        find.byKey(const Key('movement_close_top_button')),
      );

      expect(find.byType(MovementPicker), findsNothing);
    });

    testWidgets('tap check salva dal header locale', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase();
      await _pumpMovementPickerSheet(tester, db);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      await tester.enterText(
        find.byKey(const Key('movement_title_field')),
        'Pranzo',
      );
      await tester.pumpAndSettle();
      final amountPadTwo = find.byKey(const Key('movement_pad_2'));
      final detailsScrollable = find
          .descendant(
            of: find.byKey(const Key('add_movement_details_step')),
            matching: find.byType(Scrollable),
          )
          .last;
      await tester.scrollUntilVisible(
        amountPadTwo,
        200,
        scrollable: detailsScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(amountPadTwo, warnIfMissed: false);
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(const Key('movement_submit_top_button')),
      );

      expect(db.movements, hasLength(1));
      expect(db.movements.single.title, 'Pranzo');
      expect(db.movements.single.amount, 2);
    });

    testWidgets(
      'viewport piccoli e medi non generano overflow con sticky e chip ancora tappabili',
      (tester) async {
        Future<void> runForSize(Size size) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final db = AppDatabase();
          await db.createMovementFromTemplate(
            title: 'Rimborso taxi',
            amount: 12,
            type: MovementType.expense,
            date: DateTime(2026, 6, 10),
            categoryId: 'exp_1',
            accountId: defaultAccountId,
          );
          await _pumpMovementPickerSheet(tester, db);
          await _tapVisible(
            tester,
            find.byKey(const Key('category_option_exp_1')),
          );
          await tester.drag(
            find.byKey(const Key('add_movement_details_step')).last,
            const Offset(0, -650),
          );
          await tester.pumpAndSettle();

          await tester.enterText(
            find.byKey(const Key('movement_title_field')).last,
            'ri',
          );
          await tester.pumpAndSettle();
          await _tapVisible(
            tester,
            find.byKey(const Key('movement_title_suggestion_0')),
          );

          expect(
            find.byKey(const Key('movement_amount_sticky')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          expect(
            find.byKey(const Key('movement_submit_top_button')),
            findsOneWidget,
          );
          await _tapVisible(
            tester,
            find.byKey(const Key('movement_close_top_button')),
          );
          await tester.pumpAndSettle();
        }

        await runForSize(const Size(320, 568));
        await runForSize(const Size(390, 844));
      },
    );

    testWidgets(
      'titolo mostra suggerimenti dopo 2 caratteri e tap compila il campo',
      (tester) async {
        final db = AppDatabase();
        await db.createMovementFromTemplate(
          title: 'Rimborso',
          amount: 12,
          type: MovementType.expense,
          date: DateTime(2026, 6, 10),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
        );
        await db.createMovementFromTemplate(
          title: 'Ferrari Taxi',
          amount: 30,
          type: MovementType.expense,
          date: DateTime(2026, 6, 11),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
        );
        await db.createMovementFromTemplate(
          title: 'Rimborso benzina',
          amount: 8,
          type: MovementType.expense,
          date: DateTime(2026, 6, 12),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
        );

        await _pumpApp(tester, db);
        await _openAddMovement(tester);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        expect(
          find.byKey(const Key('movement_title_suggestion_0')),
          findsNothing,
        );

        await tester.enterText(
          find.byKey(const Key('movement_title_field')),
          'ri',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('movement_title_suggestion_0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('movement_title_suggestion_1')),
          findsOneWidget,
        );

        final suggestionChip = tester.widget<ActionChip>(
          find.byKey(const Key('movement_title_suggestion_0')),
        );
        final expectedTitle = (suggestionChip.label as Text).data!;
        await _tapVisible(
          tester,
          find.byKey(const Key('movement_title_suggestion_0')),
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('movement_title_field')))
              .controller!
              .text,
          expectedTitle,
        );
      },
    );

    testWidgets('titolo non mostra suggerimenti prima di 2 caratteri', (
      tester,
    ) async {
      final db = AppDatabase();
      await db.createMovementFromTemplate(
        title: 'Rimborso',
        amount: 12,
        type: MovementType.expense,
        date: DateTime(2026, 6, 10),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
      );

      await _pumpApp(tester, db);
      await _openAddMovement(tester);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      await tester.enterText(
        find.byKey(const Key('movement_title_field')),
        'r',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('movement_title_suggestion_0')),
        findsNothing,
      );
    });

    testWidgets(
      'i suggerimenti seguono solo il campo attivo e si nascondono cambiando focus',
      (tester) async {
        final db = AppDatabase();
        await db.createMovementFromTemplate(
          title: 'Rimborso taxi',
          amount: 12,
          type: MovementType.expense,
          date: DateTime(2026, 6, 10),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
          payee: 'Mario Rossi',
          note: 'Pranzo lavoro',
        );

        await _pumpApp(tester, db);
        await _openAddMovement(tester);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        await tester.tap(find.byKey(const Key('movement_title_field')));
        await tester.enterText(
          find.byKey(const Key('movement_title_field')),
          'ri',
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('movement_title_suggestion_0')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('movement_counterparty_field')));
        await tester.enterText(
          find.byKey(const Key('movement_counterparty_field')),
          'ma',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('movement_title_suggestion_0')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('movement_beneficiary_suggestion_0')),
          findsOneWidget,
        );
      },
    );

    test('titolo deduplicato e startsWith prima di contains', () async {
      final db = AppDatabase();
      await db.createMovementFromTemplate(
        title: 'Rimborso',
        amount: 12,
        type: MovementType.expense,
        date: DateTime(2026, 6, 10),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
      );
      await db.createMovementFromTemplate(
        title: 'Rimborso ',
        amount: 14,
        type: MovementType.expense,
        date: DateTime(2026, 6, 11),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
      );
      await db.createMovementFromTemplate(
        title: 'Ferrari Rimborso',
        amount: 18,
        type: MovementType.expense,
        date: DateTime(2026, 6, 12),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
      );

      final suggestions = buildMovementTextSuggestions(
        db: db,
        query: 'ri',
        field: MovementTextSuggestionField.title,
        type: MovementType.expense,
        categoryId: 'exp_1',
      );

      expect(suggestions, hasLength(2));
      expect(suggestions.first.text, 'Rimborso');
      expect(suggestions.first.startsWithQuery, isTrue);
      expect(suggestions.last.containsQuery, isTrue);
      expect(
        suggestions.map((s) => s.text).toList(),
        contains('Ferrari Rimborso'),
      );
    });

    test('beneficiario suggerimenti deduplicati e limitati a 5', () async {
      final db = AppDatabase();
      await db.createManualBeneficiaryProfile('McDonalds Grandate');
      await db.createManualBeneficiaryProfile('McDonalds Como');
      await db.createManualBeneficiaryProfile('Mc Donalds');
      await db.createManualBeneficiaryProfile('McDonalds Milano');
      await db.createManualBeneficiaryProfile('McDonalds Varese');
      await db.createManualBeneficiaryProfile('McDonalds Cantu');
      await db.createMovementFromTemplate(
        title: 'Pasto 1',
        amount: 12,
        type: MovementType.expense,
        date: DateTime(2026, 6, 10),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        payee: 'McDonalds Como',
      );

      final suggestions = buildMovementBeneficiarySuggestions(
        db: db,
        query: 'mcd',
        currentValue: 'McDonalds Como',
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.length, lessThanOrEqualTo(5));
      expect(
        suggestions.map((s) => normalizeMovementText(s.text)).toSet(),
        hasLength(suggestions.length),
      );
      expect(
        suggestions.map((s) => s.text).toList(),
        isNot(contains('McDonalds Como')),
      );
    });

    testWidgets(
      'note mostra suggerimenti dopo 2 caratteri e tap compila il campo',
      (tester) async {
        final db = AppDatabase();
        await db.createMovementFromTemplate(
          title: 'Pasto',
          amount: 12,
          type: MovementType.expense,
          date: DateTime(2026, 6, 10),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
          note: 'rimborso',
        );
        await db.createMovementFromTemplate(
          title: 'Benzina',
          amount: 30,
          type: MovementType.expense,
          date: DateTime(2026, 6, 11),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
          note: 'rimborso benzina',
        );
        await db.createMovementFromTemplate(
          title: 'Vuoto',
          amount: 1,
          type: MovementType.expense,
          date: DateTime(2026, 6, 12),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
          note: '',
        );

        await _pumpApp(tester, db);
        await _openAddMovement(tester);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        await tester.enterText(
          find.byKey(const Key('movement_note_field')),
          'ri',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('movement_note_suggestion_0')),
          findsOneWidget,
        );
        final suggestionChip = tester.widget<ActionChip>(
          find.byKey(const Key('movement_note_suggestion_0')),
        );
        final expectedNote = (suggestionChip.label as Text).data!;
        await _tapVisible(
          tester,
          find.byKey(const Key('movement_note_suggestion_0')),
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('movement_note_field')))
              .controller!
              .text,
          expectedNote,
        );
      },
    );

    testWidgets(
      'beneficiario mostra suggerimenti dopo 2 caratteri e tap compila il campo',
      (tester) async {
        final db = AppDatabase();
        await db.createManualBeneficiaryProfile('McDonalds Grandate');
        await db.createManualBeneficiaryProfile('McDonalds Como');
        await db.createMovementFromTemplate(
          title: 'Pranzo',
          amount: 18,
          type: MovementType.expense,
          date: DateTime(2026, 6, 10),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
          payee: 'Mc Donalds',
        );

        await _pumpApp(tester, db);
        await _openAddMovement(tester);
        await _tapVisible(
          tester,
          find.byKey(const Key('category_option_exp_1')),
        );

        await tester.enterText(
          find.byKey(const Key('movement_counterparty_field')),
          'mc',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('movement_beneficiary_suggestion_0')),
          findsOneWidget,
        );
        final suggestionChip = tester.widget<ActionChip>(
          find.byKey(const Key('movement_beneficiary_suggestion_0')),
        );
        final expectedBeneficiary = (suggestionChip.label as Text).data!;
        await _tapVisible(
          tester,
          find.byKey(const Key('movement_beneficiary_suggestion_0')),
        );
        expect(
          tester
              .widget<TextField>(
                find.byKey(const Key('movement_counterparty_field')),
              )
              .controller!
              .text,
          expectedBeneficiary,
        );
      },
    );

    test('note vuote non vengono suggerite', () async {
      final db = AppDatabase();
      await db.createMovementFromTemplate(
        title: 'Vuoto',
        amount: 1,
        type: MovementType.expense,
        date: DateTime(2026, 6, 12),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        note: '',
      );

      final suggestions = buildMovementTextSuggestions(
        db: db,
        query: 'ri',
        field: MovementTextSuggestionField.note,
        type: MovementType.expense,
        categoryId: 'exp_1',
      );

      expect(suggestions, isEmpty);
    });

    testWidgets('suggerimenti non bloccano il salvataggio movimento', (
      tester,
    ) async {
      final db = AppDatabase();
      await db.createMovementFromTemplate(
        title: 'Rimborso',
        amount: 12,
        type: MovementType.expense,
        date: DateTime(2026, 6, 10),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
        note: 'rimborso',
      );

      await _pumpApp(tester, db);
      await _openAddMovement(tester);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      await tester.enterText(
        find.byKey(const Key('movement_title_field')),
        'ri',
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('movement_title_suggestion_0')),
      );

      await tester.enterText(
        find.byKey(const Key('movement_note_field')),
        'ri',
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('movement_note_suggestion_0')),
      );

      await _tapPadKey(tester, 'movement_pad_1');
      await _tapPadKey(tester, 'movement_pad_0');
      await _tapVisible(
        tester,
        find.byKey(const Key('movement_submit_top_button')),
      );

      expect(db.movements, hasLength(2));
      expect(db.movements.last.title, 'Rimborso');
      expect(db.movements.last.note, 'rimborso');
    });

    testWidgets('calculator pad nel flow aggiorna l importo in tempo reale', (
      tester,
    ) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));
      expect(find.text('Nuova spesa'), findsOneWidget);
      expect(_amountDisplayText(tester), '0');

      await _tapVisible(tester, find.byKey(const Key('movement_pad_1')));
      expect(_amountDisplayText(tester), '1');

      await _tapVisible(tester, find.byKey(const Key('movement_pad_2')));
      expect(_amountDisplayText(tester), '12');

      await _tapVisible(
        tester,
        find.byKey(const Key('movement_pad_backspace')),
      );
      expect(_amountDisplayText(tester), '1');

      await _tapVisible(tester, find.byKey(const Key('movement_pad_00')));
      expect(_amountDisplayText(tester), '100');
    });

    testWidgets('importo iniziale parte da zero senza raw duplicate sotto', (
      tester,
    ) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      expect(_amountDisplayText(tester), '0');
    });

    testWidgets('tap 5 0 virgola 5 0 mostra 50,50', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);
      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));

      await _tapVisible(tester, find.byKey(const Key('movement_pad_5')));
      await _tapVisible(tester, find.byKey(const Key('movement_pad_0')));
      await _tapVisible(tester, find.byKey(const Key('movement_pad_,')));
      await _tapVisible(tester, find.byKey(const Key('movement_pad_5')));
      await _tapVisible(tester, find.byKey(const Key('movement_pad_0')));

      expect(_amountDisplayText(tester), '50,50');
    });

    testWidgets('tap 5 da zero sostituisce lo zero', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MovementCalculatorPad(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('movement_pad_5')));
      await tester.pumpAndSettle();

      expect(controller.text, '5');
      expect(find.text('05'), findsNothing);
    });

    testWidgets('tap 5 poi 0 produce 50 non 0,50', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MovementCalculatorPad(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('movement_pad_5')));
      await tester.tap(find.byKey(const Key('movement_pad_0')));
      await tester.pumpAndSettle();

      expect(controller.text, '50');
      expect(find.text('050'), findsNothing);
    });

    testWidgets('salvataggio movimento usa l importo mostrato', (tester) async {
      final db = AppDatabase();
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await _tapVisible(tester, find.byKey(const Key('category_option_exp_1')));
      await _tapVisible(tester, find.byKey(const Key('movement_title_field')));
      await tester.enterText(
        find.byKey(const Key('movement_title_field')),
        'Spesa test',
      );
      await tester.ensureVisible(find.byType(MovementCalculatorPad));
      await tester.pumpAndSettle();

      await _tapPadKey(tester, 'movement_pad_1');
      await _tapPadKey(tester, 'movement_pad_0');
      await _tapPadKey(tester, 'movement_pad_+');
      await _tapPadKey(tester, 'movement_pad_5');

      expect(_amountDisplayText(tester), '10+5');
      await _tapVisible(
        tester,
        find.byKey(const Key('movement_submit_top_button')),
      );

      expect(db.movements, hasLength(1));
      expect(db.movements.single.amount, 15);
      expect(db.movements.single.type, MovementType.expense);
    });

    testWidgets('trasferimento usa l importo mostrato', (tester) async {
      final db = AppDatabase();
      await db.addAccount(
        Account(
          id: 'acc_2',
          name: 'Contanti',
          type: AccountType.cash,
          createdAt: DateTime(2026, 6, 15),
        ),
      );
      await _pumpApp(tester, db);
      await _openAddMovement(tester);

      await tester.tap(find.text('Trasferimento').last);
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(const Key('transfer_origin_option_acc_default')),
      );
      await _tapVisible(
        tester,
        find.byKey(const Key('transfer_destination_option_acc_2')),
      );
      await _tapVisible(
        tester,
        find.byKey(const Key('transfer_continue_button')),
      );

      await _tapVisible(tester, find.byKey(const Key('movement_title_field')));
      await tester.enterText(
        find.byKey(const Key('movement_title_field')),
        'Trasferimento test',
      );
      await tester.ensureVisible(find.byType(MovementCalculatorPad));
      await tester.pumpAndSettle();

      await _tapPadKey(tester, 'movement_pad_2');
      await _tapPadKey(tester, 'movement_pad_0');
      await _tapPadKey(tester, 'movement_pad_-');
      await _tapPadKey(tester, 'movement_pad_5');

      expect(_amountDisplayText(tester), '20-5');
      await _tapVisible(
        tester,
        find.byKey(const Key('movement_submit_top_button')),
      );

      expect(db.movements, hasLength(1));
      expect(db.movements.single.type, MovementType.transfer);
      expect(db.movements.single.amount, 15);
      expect(db.movements.single.accountId, defaultAccountId);
      expect(db.movements.single.destinationAccountId, 'acc_2');
    });

    testWidgets(
      'modifica movimento usa il flow guidato e salva sullo stesso record',
      (tester) async {
        final db = AppDatabase();
        final movement = Movement(
          id: 'm_edit',
          title: 'Spesa iniziale',
          amount: 10,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'exp_1',
          accountId: defaultAccountId,
          createdAt: DateTime(2026, 6, 15),
        );
        await db.addMovement(movement);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MovementPicker(db: db, prefill: movement),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Modifica movimento'), findsOneWidget);
        expect(find.byKey(const Key('movement_title_field')), findsOneWidget);
        expect(
          find.byKey(const Key('movement_amount_display')),
          findsOneWidget,
        );
        expect(_amountDisplayText(tester), '10');

        await tester.enterText(
          find.byKey(const Key('movement_title_field')),
          'Spesa aggiornata',
        );
        for (var i = 0; i < 5; i++) {
          await _tapPadKey(tester, 'movement_pad_backspace');
        }
        await _tapPadKey(tester, 'movement_pad_2');
        await _tapPadKey(tester, 'movement_pad_5');

        expect(_amountDisplayText(tester), '25');
        await _tapVisible(
          tester,
          find.byKey(const Key('movement_submit_top_button')),
        );

        expect(db.movements, hasLength(1));
        expect(db.movements.single.id, 'm_edit');
        expect(db.movements.single.title, 'Spesa aggiornata');
        expect(db.movements.single.amount, 25);
        expect(db.movements.single.type, MovementType.expense);
      },
    );
  });

  group('AddMovementFlow logic', () {
    test('entrata aumenta saldo conto', () async {
      final db = AppDatabase();
      await db.addAccount(
        Account(
          id: 'acc_2',
          name: 'Contanti',
          type: AccountType.cash,
          createdAt: DateTime(2026, 6, 15),
        ),
      );

      final before = db.getAccountBalance(db.getAccount('acc_2'));
      await db.createMovementFromTemplate(
        title: 'Stipendio',
        amount: 100,
        type: MovementType.income,
        date: DateTime(2026, 6, 15),
        categoryId: 'inc_1',
        accountId: 'acc_2',
      );

      expect(db.movements.single.type, MovementType.income);
      expect(db.getAccountBalance(db.getAccount('acc_2')), before + 100);
    });

    test('spesa diminuisce saldo conto', () async {
      final db = AppDatabase();
      final before = db.getAccountBalance(db.getAccount(defaultAccountId));
      await db.createMovementFromTemplate(
        title: 'Spesa casa',
        amount: 25,
        type: MovementType.expense,
        date: DateTime(2026, 6, 15),
        categoryId: 'exp_1',
        accountId: defaultAccountId,
      );

      expect(db.movements.single.type, MovementType.expense);
      expect(
        db.getAccountBalance(db.getAccount(defaultAccountId)),
        before - 25,
      );
    });

    test('trasferimento muove saldi e lascia patrimonio invariato', () async {
      final db = AppDatabase();
      await db.addAccount(
        Account(
          id: 'acc_2',
          name: 'Salvadanaio',
          type: AccountType.savings,
          createdAt: DateTime(2026, 6, 15),
        ),
      );

      final beforeOrigin = db.getAccountBalance(
        db.getAccount(defaultAccountId),
      );
      final beforeDestination = db.getAccountBalance(db.getAccount('acc_2'));
      final beforeTotal = db.totalAccountsBalance;

      await db.createMovementFromTemplate(
        title: 'Trasferimento interno',
        amount: 40,
        type: MovementType.transfer,
        date: DateTime(2026, 6, 15),
        categoryId: '',
        accountId: defaultAccountId,
        destinationAccountId: 'acc_2',
      );

      expect(db.movements.single.type, MovementType.transfer);
      expect(
        db.getAccountBalance(db.getAccount(defaultAccountId)),
        beforeOrigin - 40,
      );
      expect(
        db.getAccountBalance(db.getAccount('acc_2')),
        beforeDestination + 40,
      );
      expect(db.totalAccountsBalance, beforeTotal);
      expect(db.totalIncome, 0);
      expect(db.totalExpenses, 0);
    });

    test('backup export/validate conserva trasferimenti', () async {
      final db = AppDatabase();
      await db.addAccount(
        Account(
          id: 'acc_2',
          name: 'Contanti',
          type: AccountType.cash,
          createdAt: DateTime(2026, 6, 15),
        ),
      );
      await db.createMovementFromTemplate(
        title: 'Trasferimento interno',
        amount: 35,
        type: MovementType.transfer,
        date: DateTime(2026, 6, 15),
        categoryId: '',
        accountId: defaultAccountId,
        destinationAccountId: 'acc_2',
      );

      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);
      expect(validation.isValid, isTrue);
      expect(validation.data!.movements.length, 1);
      expect(validation.data!.movements.single.type, MovementType.transfer);
      expect(validation.data!.movements.single.destinationAccountId, 'acc_2');
    });
  });
}

Future<void> _pumpApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
  await tester.pumpAndSettle();
}

Future<void> _pumpMovementPickerSheet(
  WidgetTester tester,
  AppDatabase db,
) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
  );
  final context = tester.element(find.byType(Scaffold));
  // ignore: unawaited_futures
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => MovementPicker(db: db),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _openAddMovement(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('bottom_nav_archive')));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapPadKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  final scrollable = find.byType(Scrollable).last;
  await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _amountDisplayText(WidgetTester tester) {
  return tester
      .widget<Text>(find.byKey(const Key('movement_amount_display')))
      .data!;
}
