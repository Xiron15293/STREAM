import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/design/stream_icon_library.dart';
import 'package:stream_app/models/beneficiary_profile.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/screens/beneficiaries_screen.dart';
import 'package:stream_app/services/backup_service.dart';
import 'package:stream_app/theme.dart';
import 'package:stream_app/widgets/movement_form.dart';
import 'package:stream_app/widgets/movement_picker.dart';

import 'helpers/calculator_test_helpers.dart';

Widget _wrapScreen(Widget child) {
  return MaterialApp(
    theme: StreamTheme.dark,
    home: Scaffold(body: child),
  );
}

Widget _bottomSheetLauncher({
  required WidgetBuilder builder,
  Key buttonKey = const Key('open_sheet_button'),
}) {
  return MaterialApp(
    theme: StreamTheme.dark,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: buttonKey,
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: builder,
              );
            },
            child: const Text('Apri'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  required WidgetBuilder builder,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(_bottomSheetLauncher(builder: builder));
  await tester.tap(find.byKey(const Key('open_sheet_button')));
  await tester.pumpAndSettle();
}

Future<void> _fillMovementData(
  WidgetTester tester, {
  required String title,
  required String amount,
  String? payee,
}) async {
  await tester.enterText(find.widgetWithText(TextField, 'Titolo'), title);
  if (payee != null) {
    await tester.enterText(
      find.widgetWithText(TextField, 'Beneficiario (opzionale)'),
      payee,
    );
  }
  await enterAmountWithCalculator(tester, amount);
  await tester.pumpAndSettle();
}

Future<void> _tapSaveButton(WidgetTester tester) async {
  final saveButton = find.widgetWithText(FilledButton, 'Salva');
  await tester.ensureVisible(saveButton);
  await tester.pumpAndSettle();
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BeneficiariesScreen', () {
    testWidgets(
      'mostra tasto + e crea beneficiario manuale con zero movimenti',
      (tester) async {
        final db = AppDatabase();

        await tester.pumpWidget(
          _wrapScreen(BeneficiariesScreen(db: db)),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('beneficiaries_add_button')), findsOneWidget);

        await tester.tap(find.byKey(const Key('beneficiaries_add_button')));
        await tester.pumpAndSettle();

        expect(find.text('Nuovo beneficiario'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('beneficiary_name_field')),
          'Mario Rossi',
        );
        await tester.tap(
          find.byKey(const Key('beneficiary_create_confirm_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mario Rossi'), findsOneWidget);
        expect(find.text('0 movimenti'), findsOneWidget);
        expect(find.text('Entrate 0.00 €'), findsOneWidget);
        expect(find.text('Uscite 0.00 €'), findsOneWidget);
        expect(find.text('Saldo 0.00 €'), findsOneWidget);
        expect(db.beneficiaryProfiles, hasLength(1));
        expect(db.beneficiaryProfiles.first.key, 'mario rossi');
      },
    );

    testWidgets('ricerca trova beneficiario manuale senza movimenti', (
      tester,
    ) async {
      final db = AppDatabase();
      await db.createManualBeneficiaryProfile('Studio Dentistico');

      await tester.pumpWidget(
        _wrapScreen(BeneficiariesScreen(db: db)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('beneficiaries_search_field')),
        'dent',
      );
      await tester.pumpAndSettle();

      expect(find.text('Studio Dentistico'), findsOneWidget);
      expect(find.text('Nessun beneficiario trovato'), findsNothing);
    });

    testWidgets('non permette duplicato normalizzato', (tester) async {
      final db = AppDatabase();
      await db.createManualBeneficiaryProfile('Mario Rossi');

      await tester.pumpWidget(
        _wrapScreen(BeneficiariesScreen(db: db)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('beneficiaries_add_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('beneficiary_name_field')),
        '  mario   rossi  ',
      );
      await tester.tap(
        find.byKey(const Key('beneficiary_create_confirm_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Esiste gi\u00e0 un beneficiario con questo nome'),
        findsOneWidget,
      );
      expect(db.beneficiaryProfiles, hasLength(1));
    });

    test('backup/restore preserva beneficiario manuale senza movimenti', () async {
      final sourceDb = AppDatabase();
      await sourceDb.createManualBeneficiaryProfile(
        'Mario Rossi',
        iconKey: BeneficiaryProfile.defaultIconKey,
        color: StreamColorPalette.defaultColor,
      );

      final json = await BackupService.exportToJson(sourceDb);
      final validation = BackupService.validate(json);

      expect(validation.isValid, isTrue);
      expect(validation.data, isNotNull);

      final targetDb = AppDatabase();
      await BackupService.restore(targetDb, validation.data!);

      expect(targetDb.beneficiaryProfiles, hasLength(1));
      expect(targetDb.beneficiaryProfiles.first.displayName, 'Mario Rossi');
      expect(targetDb.beneficiaryProfiles.first.key, 'mario rossi');
      expect(targetDb.movements, isEmpty);
    });

    testWidgets('merge manuale + derivato resta una sola entry ricercabile', (
      tester,
    ) async {
      final db = AppDatabase();
      await db.createManualBeneficiaryProfile('Tigros Spa');
      await db.updateBeneficiaryProfile(
        db.beneficiaryProfiles.first.copyWith(displayName: 'Tigros'),
      );
      await db.createMovementFromTemplate(
        title: 'Spesa',
        amount: 45,
        type: MovementType.expense,
        categoryId: 'exp_1',
        payee: '  Tigros   Spa ',
      );

      await tester.pumpWidget(_wrapScreen(BeneficiariesScreen(db: db)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('beneficiary_card_tigros spa')), findsOneWidget);
      expect(find.text('Tigros'), findsOneWidget);
      expect(find.text('1 movimenti'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('beneficiaries_search_field')),
        'spa',
      );
      await tester.pumpAndSettle();
      expect(find.text('Tigros'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('beneficiaries_search_field')),
        'tigros',
      );
      await tester.pumpAndSettle();
      expect(find.text('Tigros'), findsOneWidget);
    });

    testWidgets('tap beneficiario apre dettaglio con movimenti filtrati', (
      tester,
    ) async {
      final db = AppDatabase();
      await db.createManualBeneficiaryProfile('Tigros Spa');
      await db.createMovementFromTemplate(
        title: 'Spesa 1',
        amount: 20,
        type: MovementType.expense,
        categoryId: 'exp_1',
        payee: 'Tigros Spa',
      );
      await db.createMovementFromTemplate(
        title: 'Spesa 2',
        amount: 15,
        type: MovementType.expense,
        categoryId: 'exp_1',
        payee: ' tigros  spa ',
      );
      await db.createMovementFromTemplate(
        title: 'Altro',
        amount: 9,
        type: MovementType.expense,
        categoryId: 'exp_1',
        payee: 'Bar Centrale',
      );

      await tester.pumpWidget(_wrapScreen(BeneficiariesScreen(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tigros Spa').first);
      await tester.pumpAndSettle();

      final detailSheet = find.byKey(const Key('beneficiary_detail_sheet'));
      expect(detailSheet, findsOneWidget);
      expect(
        find.descendant(of: detailSheet, matching: find.text('Spesa 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detailSheet, matching: find.text('Spesa 2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detailSheet, matching: find.text('Altro')),
        findsNothing,
      );
    });
  });

  group('Movement beneficiary proposal', () {
    testWidgets('"No, solo movimento" salva movimento ma non profilo', (
      tester,
    ) async {
      final db = AppDatabase();
      await _openSheet(
        tester,
        builder: (_) => MovementPicker(db: db),
      );

      await _fillMovementData(
        tester,
        title: 'Cena',
        amount: '25',
        payee: 'Ristorante Blu',
      );
      await _tapSaveButton(tester);

      expect(find.text('Vuoi salvare questo beneficiario?'), findsOneWidget);

      await tester.tap(find.text('No, solo movimento'));
      await tester.pumpAndSettle();

      expect(db.movements, hasLength(1));
      expect(db.movements.first.payee, 'Ristorante Blu');
      expect(db.beneficiaryProfiles, isEmpty);
    });

    testWidgets('"Salva beneficiario" salva movimento e profilo', (
      tester,
    ) async {
      final db = AppDatabase();
      await _openSheet(
        tester,
        builder: (_) => MovementPicker(db: db),
      );

      await _fillMovementData(
        tester,
        title: 'Farmacia',
        amount: '18',
        payee: 'Farmacia Centrale',
      );
      await _tapSaveButton(tester);
      await tester.tap(find.text('Salva beneficiario'));
      await tester.pumpAndSettle();

      expect(db.movements, hasLength(1));
      expect(db.beneficiaryProfiles, hasLength(1));
      expect(db.beneficiaryProfiles.first.key, 'farmacia centrale');
      expect(db.beneficiaryProfiles.first.displayName, 'Farmacia Centrale');
      expect(
        db.beneficiaryProfiles.first.iconKey,
        BeneficiaryProfile.defaultIconKey,
      );
    });

    testWidgets('"Annulla" non salva nulla', (tester) async {
      final db = AppDatabase();
      await _openSheet(
        tester,
        builder: (_) => MovementPicker(db: db),
      );

      await _fillMovementData(
        tester,
        title: 'Pranzo',
        amount: '12',
        payee: 'Bar Roma',
      );
      await _tapSaveButton(tester);
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(db.movements, isEmpty);
      expect(db.beneficiaryProfiles, isEmpty);
    });

    testWidgets('beneficiario già esistente non mostra proposta', (
      tester,
    ) async {
      final db = AppDatabase();
      await db.createManualBeneficiaryProfile('Ristorante Blu');
      await _openSheet(
        tester,
        builder: (_) => MovementPicker(db: db),
      );

      await _fillMovementData(
        tester,
        title: 'Cena',
        amount: '25',
        payee: '  ristorante   blu ',
      );
      await _tapSaveButton(tester);

      expect(find.text('Vuoi salvare questo beneficiario?'), findsNothing);
      expect(db.movements, hasLength(1));
      expect(db.beneficiaryProfiles, hasLength(1));
    });

    testWidgets('movement_form legacy propone salvataggio beneficiario', (
      tester,
    ) async {
      final db = AppDatabase();
      await _openSheet(
        tester,
        builder: (_) => MovementForm(db: db),
      );

      await _fillMovementData(
        tester,
        title: 'Colazione',
        amount: '6',
        payee: 'Bar Centrale',
      );
      await _tapSaveButton(tester);

      expect(find.text('Vuoi salvare questo beneficiario?'), findsOneWidget);
      await tester.tap(find.text('Salva beneficiario'));
      await tester.pumpAndSettle();

      expect(db.movements, hasLength(1));
      expect(db.beneficiaryProfiles, hasLength(1));
      expect(db.beneficiaryProfiles.first.displayName, 'Bar Centrale');
    });
  });
}
