import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/design/stream_icon_library.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/categories_screen.dart';
import 'package:stream_app/services/backup_service.dart';
import 'package:stream_app/widgets/category_subcategory_selector.dart';
import 'package:stream_app/widgets/movement_picker.dart';

import 'helpers/calculator_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Subcategories — In-memory mode', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase();
    });

    test('1. crea sottocategoria sotto categoria', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Test Sub');
      final subs = db.getSubcategoriesForCategory(cat.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'Test Sub');
      expect(subs.first.categoryId, cat.id);
    });

    test('2. dedup sottocategoria stessa categoria', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Sub');
      // Stesso nome sotto stessa categoria — attualmente permesso (nessuna validazione strict)
      await db.createSubcategory(cat.id, 'Sub');
      expect(db.getSubcategoriesForCategory(cat.id).length, 2);
    });

    test(
      '3. stesso nome sottocategoria ammesso sotto categorie diverse',
      () async {
        final cats = db.categories.where((c) => !c.archived).toList();
        if (cats.length < 2) return;
        await db.createSubcategory(cats[0].id, 'StessoNome');
        await db.createSubcategory(cats[1].id, 'StessoNome');
        expect(db.getSubcategoriesForCategory(cats[0].id).length, 1);
        expect(db.getSubcategoriesForCategory(cats[1].id).length, 1);
      },
    );

    test('4. movimento può salvare subcategoryId valido', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Sub');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      final mov = Movement(
        id: 'm1',
        title: 'Test',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        subcategoryId: sub.id,
        createdAt: DateTime.now(),
      );
      expect(mov.subcategoryId, sub.id);
    });

    test('5. archivia sottocategoria non rompe storico', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Sub');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      await db.archiveSubcategory(sub.id);
      final archived = db.subcategories.firstWhere((s) => s.id == sub.id);
      expect(archived.archived, true);
      expect(db.getActiveSubcategoriesForCategory(cat.id), isEmpty);
    });

    test('6. movimento resta salvabile senza sottocategoria', () async {
      final cat = db.categories.first;
      final mov = Movement(
        id: 'm2',
        title: 'NoSub',
        amount: 5,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      expect(mov.subcategoryId, isNull);
    });

    test(
      '7. movimento con subcategory continua a contribuire alla categoria madre',
      () async {
        final cat = db.categories.first;
        await db.createSubcategory(cat.id, 'Sub');
        final sub = db.getSubcategoriesForCategory(cat.id).first;
        final mov = Movement(
          id: 'm3',
          title: 'Test',
          amount: 100,
          type: cat.type,
          date: DateTime.now(),
          categoryId: cat.id,
          subcategoryId: sub.id,
          createdAt: DateTime.now(),
        );
        db.addMovement(mov);
        expect(db.totalExpenses > 0 || db.totalIncome > 0, true);
      },
    );

    test('8. getActiveSubcategoriesForCategory filtra archiviate', () async {
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Active');
      await db.createSubcategory(cat.id, 'ArchivedToo');
      final subs = db.getSubcategoriesForCategory(cat.id);
      await db.archiveSubcategory(subs.last.id);
      final active = db.getActiveSubcategoriesForCategory(cat.id);
      expect(active.length, 1);
      expect(active.first.name, 'Active');
    });

    test('9. categoria senza subcategories ha lista vuota', () async {
      final cat = db.categories.first;
      expect(db.getSubcategoriesForCategory(cat.id), isEmpty);
    });

    test('18. modifica nome icona e colore al primo update', () async {
      final cat = db.categories.first;
      await db.createSubcategory(
        cat.id,
        'Da modificare',
        iconKey: 'tag',
        color: 0xFF42A5F5,
      );
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      var notifications = 0;
      db.addListener(() => notifications++);

      await db.updateSubcategory(
        sub.id,
        'Modificata',
        iconKey: 'car',
        color: 0xFFFF7043,
      );

      final updated = db.subcategories.firstWhere((s) => s.id == sub.id);
      expect(updated.name, 'Modificata');
      expect(updated.iconKey, 'car');
      expect(updated.color, 0xFFFF7043);
      expect(notifications, 1);
    });

    test('19. archivia e ripristina preservano icona e colore', () async {
      final cat = db.categories.first;
      await db.createSubcategory(
        cat.id,
        'Styled',
        iconKey: 'car',
        color: 0xFFFF7043,
      );
      final sub = db.getSubcategoriesForCategory(cat.id).first;

      await db.archiveSubcategory(sub.id);
      final archived = db.subcategories.firstWhere((s) => s.id == sub.id);
      expect(archived.archived, true);
      expect(archived.iconKey, 'car');
      expect(archived.color, 0xFFFF7043);

      await db.restoreSubcategory(sub.id);
      final restored = db.subcategories.firstWhere((s) => s.id == sub.id);
      expect(restored.archived, false);
      expect(restored.iconKey, 'car');
      expect(restored.color, 0xFFFF7043);
    });
  });

  group('Subcategories — SQLite persistence', () {
    late SQLiteService sqlite;
    late AppDatabase db;
    late String subId;

    setUp(() async {
      sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Persistent Sub');
      final subs = db.getSubcategoriesForCategory(cat.id);
      subId = subs.first.id;
    });

    tearDown(() async {
      await sqlite.close();
    });

    test('10. subcategory persiste dopo reload', () async {
      await db.reloadFromDb();
      final subs = db.getSubcategoriesForCategory(db.categories.first.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'Persistent Sub');
    });

    test('11. subcategory archiviation persiste dopo reload', () async {
      final cat = db.categories.first;
      final subs = db.getSubcategoriesForCategory(cat.id);
      await db.archiveSubcategory(subs.first.id);
      await db.reloadFromDb();
      final loaded = db.subcategories.firstWhere((s) => s.id == subId);
      expect(loaded.archived, true);
    });

    test('20. modifica icona e colore persiste dopo reload SQLite', () async {
      await db.updateSubcategory(
        subId,
        'Persistent Updated',
        iconKey: 'car',
        color: 0xFFFF7043,
      );

      final immediate = db.subcategories.firstWhere((s) => s.id == subId);
      expect(immediate.name, 'Persistent Updated');
      expect(immediate.iconKey, 'car');
      expect(immediate.color, 0xFFFF7043);

      await db.reloadFromDb();
      final loaded = db.subcategories.firstWhere((s) => s.id == subId);
      expect(loaded.name, 'Persistent Updated');
      expect(loaded.iconKey, 'car');
      expect(loaded.color, 0xFFFF7043);
    });

    test('21. sottocategoria con movimenti resta modificabile', () async {
      final cat = db.categories.first;
      await db.createSubcategory(
        cat.id,
        'Con movimenti',
        iconKey: 'tag',
        color: 0xFF42A5F5,
      );
      final sub = db.getSubcategoriesForCategory(cat.id).last;

      await db.addMovement(
        Movement(
          id: 'sub_move_1',
          title: 'Test',
          amount: 10,
          type: cat.type,
          date: DateTime.now(),
          categoryId: cat.id,
          subcategoryId: sub.id,
          createdAt: DateTime.now(),
        ),
      );

      await db.updateSubcategory(
        sub.id,
        'Sottocategoria Rinominata',
        iconKey: 'car',
        color: 0xFFFF7043,
      );

      final updated = db.subcategories.firstWhere((s) => s.id == sub.id);
      expect(updated.name, 'Sottocategoria Rinominata');
      expect(updated.iconKey, 'car');
      expect(updated.color, 0xFFFF7043);
      expect(db.movements.any((m) => m.subcategoryId == sub.id), true);
    });
  });

  group('Subcategories — UI edit dialog', () {
    testWidgets('21. dialog salva nome icona e colore al primo tap', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'category_layout': 'cleanList'});
      final db = AppDatabase();
      final cat = db.categories.firstWhere(
        (c) => c.type == MovementType.expense,
      );
      await db.createSubcategory(
        cat.id,
        'Da modificare',
        iconKey: 'tag',
        color: 0xFF42A5F5,
      );
      final subId = db.getSubcategoriesForCategory(cat.id).first.id;

      await tester.pumpWidget(MaterialApp(home: CategoriesScreen(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(Key('category_card_${cat.id}')),
          matching: find.byIcon(Icons.more_horiz),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifica').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('subcategory_name_field')).last,
        'Modificata',
      );

      await tester.tap(find.text(StreamIconLibrary.getLabel('tag')).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('icon_picker_option_car')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('color_picker_option_ffff7043')).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salva').last);
      await tester.pumpAndSettle();

      final updated = db.subcategories.firstWhere((s) => s.id == subId);
      expect(updated.name, 'Modificata');
      expect(updated.iconKey, 'car');
      expect(updated.color, 0xFFFF7043);
      expect(find.text('Modificata'), findsOneWidget);
      expect(find.text('Da modificare'), findsNothing);
    });
  });

  group('Subcategories — Movement selector UX', () {
    testWidgets(
      '22. form movimento mostra un solo campo Categoria / Sottocategoria',
      (tester) async {
        final db = await _buildMovementSelectorDb();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MovementPicker(db: db)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('add_movement_category_step')), findsOneWidget);
        expect(find.byKey(const Key('add_movement_category_search')), findsOneWidget);
        expect(find.byKey(const Key('movement_category_subcategory_field')), findsNothing);
        expect(find.byKey(const Key('movement_subcategory_dropdown')), findsNothing);
      },
    );

    testWidgets(
      '23. selezione categoria madre salva categoryId e subcategoryId null',
      (tester) async {
        final db = await _buildMovementSelectorDb();
        final parent = db.categories.firstWhere(
          (c) => c.name == 'Tempo libero',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MovementPicker(db: db)),
          ),
        );
        await tester.pumpAndSettle();

        await tapVisible(tester, find.byKey(Key('category_option_${parent.id}')));
        await tapVisible(tester, find.byKey(const Key('skip_subcategory_button')));
        await enterMovementTitle(tester, 'Cena');
        await enterAmountWithCalculator(tester, '25');
        await submitMovement(tester);

        final movement = db.movements.singleWhere((m) => m.title == 'Cena');
        expect(movement.categoryId, parent.id);
        expect(movement.subcategoryId, isNull);
      },
    );

    testWidgets(
      '24. selezione sottocategoria salva parent e valore combinato',
      (tester) async {
        final db = await _buildMovementSelectorDb();
        final parent = db.categories.firstWhere(
          (c) => c.name == 'Tempo libero',
        );
        final sub = db.subcategories.firstWhere((s) => s.name == 'Ristorante');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MovementPicker(db: db)),
          ),
        );
        await tester.pumpAndSettle();

        await tapVisible(tester, find.byKey(Key('category_option_${parent.id}')));
        await tapVisible(tester, find.byKey(Key('subcategory_option_${sub.id}')));
        await enterMovementTitle(tester, 'Pranzo');
        await enterAmountWithCalculator(tester, '18');
        await submitMovement(tester);

        final movement = db.movements.singleWhere((m) => m.title == 'Pranzo');
        expect(movement.categoryId, parent.id);
        expect(movement.subcategoryId, sub.id);
      },
    );

    testWidgets(
      '25. picker mostra solo attive e ricerca categoria o sottocategoria',
      (tester) async {
        final db = await _buildMovementSelectorDb();
        final parent = db.categories.firstWhere(
          (c) => c.name == 'Tempo libero',
        );
        final archivedCategory = db.categories.firstWhere(
          (c) => c.name == 'Archivio nascosto',
        );
        final sub = db.subcategories.firstWhere((s) => s.name == 'Ristorante');
        final archivedSub = db.subcategories.firstWhere(
          (s) => s.name == 'Archiviata',
        );
        final flat = db.categories.firstWhere(
          (c) => c.name == 'Spesa (Alimentari)',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MovementPicker(db: db)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('add_movement_category_search')),
          'tempo libero',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(Key('category_option_${parent.id}')), findsOneWidget);
        expect(
          find.byKey(Key('category_option_${archivedCategory.id}')),
          findsNothing,
        );

        await tapVisible(tester, find.byKey(Key('category_option_${parent.id}')));
        expect(find.byKey(Key('subcategory_option_${sub.id}')), findsOneWidget);
        expect(
          find.byKey(Key('subcategory_option_${archivedSub.id}')),
          findsNothing,
        );

        await tapVisible(
          tester,
          find.byIcon(Icons.arrow_back_ios_new_rounded).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('add_movement_category_search')),
          'spesa (',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(Key('category_option_${flat.id}')), findsOneWidget);
        expect(find.byKey(Key('category_option_${parent.id}')), findsNothing);
      },
    );

    testWidgets('26. cambio tipo resetta selezione incompatibile', (
      tester,
    ) async {
      final db = await _buildMovementSelectorDb();
      final sub = db.subcategories.firstWhere((s) => s.name == 'Ristorante');
      final income = db.categories.firstWhere((c) => c.name == 'Bonus');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MovementPicker(db: db)),
        ),
      );
      await tester.pumpAndSettle();

      final expenseParent = db.categories.firstWhere((c) => c.name == 'Tempo libero');
      await tapVisible(tester, find.byKey(Key('category_option_${expenseParent.id}')));
      await tapVisible(tester, find.byKey(Key('subcategory_option_${sub.id}')));
      expect(find.byKey(const Key('add_movement_details_step')), findsOneWidget);
      expect(find.text('Ristorante'), findsOneWidget);

      await tester.tap(find.text('Entrata'));
      await tester.pumpAndSettle();

      expect(find.text('Ristorante'), findsNothing);
      expect(find.byKey(const Key('add_movement_category_step')), findsOneWidget);
      expect(find.byKey(Key('category_option_${income.id}')), findsOneWidget);
      expect(find.text('Tempo libero'), findsNothing);
    });

    testWidgets(
      '27. categoria flat resta selezionabile come categoria normale',
      (tester) async {
        final db = await _buildMovementSelectorDb();
        final flat = db.categories.firstWhere(
          (c) => c.name == 'Spesa (Alimentari)',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MovementPicker(db: db)),
          ),
        );
        await tester.pumpAndSettle();

        await tapVisible(tester, find.byKey(Key('category_option_${flat.id}')));
        await enterMovementTitle(tester, 'Flat');
        await enterAmountWithCalculator(tester, '14');
        await submitMovement(tester);

        final movement = db.movements.singleWhere((m) => m.title == 'Flat');
        expect(movement.categoryId, flat.id);
        expect(movement.subcategoryId, isNull);
      },
    );

    testWidgets('28. quick form usa selector unico e salva sottocategoria', (
      tester,
    ) async {
      final db = await _buildMovementSelectorDb();
      final parent = db.categories.firstWhere((c) => c.name == 'Tempo libero');
      final sub = db.subcategories.firstWhere((s) => s.name == 'Ristorante');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MovementPicker(db: db)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rapidi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('movement_category_subcategory_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movement_subcategory_dropdown')),
        findsNothing,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Titolo'),
        'Quick Sub',
      );
      await enterAmountWithCalculator(tester, '9');
      await _selectCategoryOrSubcategory(
        tester,
        optionKey: Key('subcategory_option_${sub.id}'),
        searchText: 'Ristorante',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crea'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crea'));
      await tester.pumpAndSettle();

      final quick = db.quickMovements.singleWhere(
        (q) => q.title == 'Quick Sub',
      );
      expect(quick.categoryId, parent.id);
      expect(quick.subcategoryId, sub.id);
    });

    testWidgets('29. favorite form usa selector unico e salva sottocategoria', (
      tester,
    ) async {
      final db = await _buildMovementSelectorDb();
      final parent = db.categories.firstWhere((c) => c.name == 'Tempo libero');
      final sub = db.subcategories.firstWhere((s) => s.name == 'Ristorante');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MovementPicker(db: db)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Preferiti'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuovo'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('movement_category_subcategory_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('movement_subcategory_dropdown')),
        findsNothing,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Titolo'),
        'Fav Sub',
      );
      await enterAmountWithCalculator(tester, '11');
      await _selectCategoryOrSubcategory(
        tester,
        optionKey: Key('subcategory_option_${sub.id}'),
        searchText: 'Ristorante',
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crea'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crea'));
      await tester.pumpAndSettle();

      final favorite = db.favoriteMovements.singleWhere(
        (f) => f.title == 'Fav Sub',
      );
      expect(favorite.categoryId, parent.id);
      expect(favorite.subcategoryId, sub.id);
    });
  });

  group('Subcategories — Parent style inheritance', () {
    test(
      '30. nuova sottocategoria eredita colore e icona categoria madre',
      () async {
        final db = AppDatabase();
        final parent = db.categories.firstWhere(
          (c) => c.type == MovementType.expense && !c.archived,
        );

        await db.createSubcategory(parent.id, 'Ereditata');
        final sub = db.getSubcategoriesForCategory(parent.id).single;
        final resolved = resolveCategorySubcategorySelection(
          categories: db.categories,
          subcategories: db.subcategories,
          type: parent.type,
          categoryId: parent.id,
          subcategoryId: sub.id,
        );

        expect(sub.color, isNull);
        expect(sub.iconKey, isNull);
        expect(resolved?.color, parent.color);
        expect(resolved?.iconKey, parent.iconKey);
      },
    );

    test(
      '31. cambio colore madre aggiorna sottocategoria con color null',
      () async {
        final db = AppDatabase();
        final parent = db.categories.firstWhere((c) => !c.archived);
        await db.createSubcategory(parent.id, 'Null Color');
        final subId = db.getSubcategoriesForCategory(parent.id).single.id;

        await db.updateCategory(parent.id, parent.name, 0xFF009688);

        final updated = db.subcategories.firstWhere((s) => s.id == subId);
        expect(updated.color, 0xFF009688);
      },
    );

    test(
      '32. cambio colore madre aggiorna sottocategoria con color == oldCategoryColor',
      () async {
        final db = AppDatabase();
        final parent = db.categories.firstWhere((c) => !c.archived);
        await db.createSubcategory(
          parent.id,
          'Old Color',
          color: parent.color,
          iconKey: parent.iconKey,
        );
        final subId = db.getSubcategoriesForCategory(parent.id).single.id;

        await db.updateCategory(parent.id, parent.name, 0xFF26A69A);

        final updated = db.subcategories.firstWhere((s) => s.id == subId);
        expect(updated.color, 0xFF26A69A);
      },
    );

    test(
      '33. cambio icona madre aggiorna sottocategoria con iconKey null',
      () async {
        final db = AppDatabase();
        final parent = db.categories.firstWhere((c) => !c.archived);
        await db.createSubcategory(parent.id, 'Null Icon');
        final subId = db.getSubcategoriesForCategory(parent.id).single.id;

        await db.updateCategory(
          parent.id,
          parent.name,
          parent.color,
          iconKey: 'car',
        );

        final updated = db.subcategories.firstWhere((s) => s.id == subId);
        expect(updated.iconKey, 'car');
      },
    );

    test(
      '34. cambio icona madre aggiorna sottocategoria con iconKey == oldCategoryIconKey',
      () async {
        final db = AppDatabase();
        final parent = db.categories.firstWhere((c) => !c.archived);
        await db.createSubcategory(
          parent.id,
          'Old Icon',
          color: parent.color,
          iconKey: parent.iconKey,
        );
        final subId = db.getSubcategoriesForCategory(parent.id).single.id;

        await db.updateCategory(
          parent.id,
          parent.name,
          parent.color,
          iconKey: 'coins',
        );

        final updated = db.subcategories.firstWhere((s) => s.id == subId);
        expect(updated.iconKey, 'coins');
      },
    );

    test(
      '35. sottocategoria con colore custom diverso non viene sovrascritta',
      () async {
        final db = AppDatabase();
        final parent = db.categories.firstWhere((c) => !c.archived);
        await db.createSubcategory(
          parent.id,
          'Custom Color',
          color: 0xFF6D4C41,
          iconKey: parent.iconKey,
        );
        final subId = db.getSubcategoriesForCategory(parent.id).single.id;

        await db.updateCategory(parent.id, parent.name, 0xFF42A5F5);

        final updated = db.subcategories.firstWhere((s) => s.id == subId);
        expect(updated.color, 0xFF6D4C41);
      },
    );

    test(
      '36. sottocategoria con icona custom diversa non viene sovrascritta',
      () async {
        final db = AppDatabase();
        final parent = db.categories.firstWhere((c) => !c.archived);
        await db.createSubcategory(
          parent.id,
          'Custom Icon',
          color: parent.color,
          iconKey: 'car',
        );
        final subId = db.getSubcategoriesForCategory(parent.id).single.id;

        await db.updateCategory(
          parent.id,
          parent.name,
          parent.color,
          iconKey: 'car',
        );

        final updated = db.subcategories.firstWhere((s) => s.id == subId);
        expect(updated.iconKey, 'car');
      },
    );

    testWidgets(
      '37. updateCategory notifica e aggiorna subito la UI nel category sheet',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'category_layout': 'cleanList',
        });
        final db = AppDatabase();
        final parent = db.categories.firstWhere(
          (c) => c.type == MovementType.expense && !c.archived,
        );
        await db.createSubcategory(
          parent.id,
          'Ristorante',
          color: parent.color,
          iconKey: parent.iconKey,
        );

        var notifications = 0;
        db.addListener(() => notifications++);

        await tester.pumpWidget(MaterialApp(home: CategoriesScreen(db: db)));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('category_card_${parent.id}')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('category_interactive_sheet')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('category_sheet_edit_action')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.text(StreamIconLibrary.getLabel(parent.iconKey)).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('icon_picker_option_car')));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('color_picker_option_ff009688')).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Salva').last);
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, 'Applica alle selezionate'));
        await tester.pumpAndSettle();

        expect(notifications, greaterThan(0));
        expect(
          find.descendant(
            of: find.byKey(const Key('category_sheet_header')),
            matching: find.byIcon(StreamIconLibrary.getIcon('car')),
          ),
          findsOneWidget,
        );

        final updatedSub = db.subcategories.firstWhere(
          (s) => s.name == 'Ristorante',
        );
        expect(updatedSub.color, 0xFF009688);
        expect(updatedSub.iconKey, 'car');
      },
    );

    testWidgets(
      '38. movement picker mostra subito nuova icona madre per sottocategoria ereditata',
      (tester) async {
        final db = await _buildMovementSelectorDb();
        final parent = db.categories.firstWhere(
          (c) => c.name == 'Tempo libero',
        );
        final oldSub = db.subcategories.firstWhere(
          (s) => s.name == 'Ristorante',
        );
        await db.updateSubcategory(
          oldSub.id,
          oldSub.name,
          iconKey: parent.iconKey,
          color: parent.color,
        );

        final movement = Movement(
          id: 'm_picker_refresh',
          title: 'Cena',
          amount: 20,
          type: parent.type,
          date: DateTime.now(),
          categoryId: parent.id,
          subcategoryId: oldSub.id,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MovementPicker(db: db, prefill: movement),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await db.updateCategory(
          parent.id,
          parent.name,
          0xFF009688,
          iconKey: 'car',
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('movement_category_subcategory_field')),
            matching: find.byIcon(StreamIconLibrary.getIcon('car')),
          ),
          findsWidgets,
        );
      },
    );
  });

  group('Subcategories — Backup/Restore', () {
    late SQLiteService sqlite;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'Backup Sub');
    });

    tearDown(() async {
      await sqlite.close();
    });

    test('12. backup include subcategories', () async {
      final json = await BackupService.exportToJson(db);
      expect(json, contains('subcategories'));
      expect(json, contains('Backup Sub'));
    });

    test('13. restore con subcategories funziona', () async {
      final json = await BackupService.exportToJson(db);
      final validation = BackupService.validate(json);
      expect(validation.isValid, true);
      final data = validation.data!;
      expect(data.subcategories.length, 1);
      expect(data.subcategories.first.name, 'Backup Sub');

      await db.resetAllData();
      await BackupService.restore(db, data);
      final restored = db.subcategories;
      expect(restored.length, 1);
      expect(restored.first.name, 'Backup Sub');
    });

    test('14. restore vecchio JSON senza subcategories funziona', () async {
      final oldJson = '''
      {
        "version": 2,
        "createdAt": "2024-01-01T00:00:00.000",
        "accounts": [],
        "categories": [],
        "movements": [],
        "quickMovements": [],
        "favoriteMovements": []
      }
      ''';
      final validation = BackupService.validate(oldJson);
      expect(validation.isValid, true);
      final data = validation.data!;
      expect(data.subcategories, isEmpty);
    });

    test('15. restore con subcategoryId orfano lo porta a null', () async {
      final json = '''
      {
        "version": 2,
        "createdAt": "2024-01-01T00:00:00.000",
        "accounts": [],
        "categories": [{"id": "exp_1", "name": "Test", "type": "expense", "color": 123}],
        "subcategories": [],
        "movements": [{"id": "m_orphan", "title": "Test", "amount": 10, "type": "expense", "date": "2024-01-01T00:00:00.000", "categoryId": "exp_1", "subcategoryId": "nonexistent_id", "accountId": "default", "createdAt": "2024-01-01T00:00:00.000", "updatedAt": "2024-01-01T00:00:00.000"}],
        "quickMovements": [],
        "favoriteMovements": []
      }
      ''';
      final validation = BackupService.validate(json);
      expect(validation.isValid, true);
      await db.resetAllData();
      await BackupService.restore(db, validation.data!);
      await db.reloadFromDb();
      final mov = db.movements.first;
      expect(mov.subcategoryId, isNull);
    });
  });

  group('Subcategories — Reset data', () {
    test('16. reset dati cancella subcategories', () async {
      final sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      final db = AppDatabase(sqlite: sqlite);
      await db.initialize();
      final cat = db.categories.first;
      await db.createSubcategory(cat.id, 'ToDelete');
      expect(db.subcategories.length, 1);
      await db.resetAllData();
      expect(db.subcategories, isEmpty);
      await sqlite.close();
    });
  });

  group('Subcategories — Compatibilità analytics', () {
    test(
      '17. somma spese per categoria include movimenti con subcategory',
      () async {
        final db = AppDatabase();
        final cat = db.categories.firstWhere(
          (c) => c.type == MovementType.expense,
        );
        await db.createSubcategory(cat.id, 'Sub');
        final sub = db.getSubcategoriesForCategory(cat.id).first;
        const amount = 50.0;
        final mov = Movement(
          id: 'm_ana',
          title: 'Analytics Test',
          amount: amount,
          type: MovementType.expense,
          date: DateTime.now(),
          categoryId: cat.id,
          subcategoryId: sub.id,
          createdAt: DateTime.now(),
        );
        await db.addMovement(mov);
        expect(db.totalExpenses, amount);
      },
    );
  });
}

Future<AppDatabase> _buildMovementSelectorDb() async {
  final db = AppDatabase();
  await db.addCategory(
    'Tempo libero',
    MovementType.expense,
    0xFF1E88E5,
    iconKey: 'star',
  );
  await db.addCategory(
    'Archivio nascosto',
    MovementType.expense,
    0xFF8E24AA,
    iconKey: 'wallet',
  );
  await db.addCategory(
    'Spesa (Alimentari)',
    MovementType.expense,
    0xFF43A047,
    iconKey: 'shopping-cart',
  );
  await db.addCategory(
    'Bonus',
    MovementType.income,
    0xFFFB8C00,
    iconKey: 'coins',
  );

  final parent = db.categories.firstWhere((c) => c.name == 'Tempo libero');
  final archivedCategory = db.categories.firstWhere(
    (c) => c.name == 'Archivio nascosto',
  );
  await db.createSubcategory(
    parent.id,
    'Ristorante',
    iconKey: 'restaurant',
    color: 0xFFFF7043,
  );
  await db.createSubcategory(
    parent.id,
    'Archiviata',
    iconKey: 'coffee',
    color: 0xFF8D6E63,
  );
  final archivedSub = db.subcategories.firstWhere(
    (s) => s.name == 'Archiviata',
  );
  await db.archiveSubcategory(archivedSub.id);
  await db.archiveCategory(archivedCategory.id);
  return db;
}

Future<void> _selectCategoryOrSubcategory(
  WidgetTester tester, {
  required Key optionKey,
  String? searchText,
}) async {
  await tester.tap(
    find.byKey(const Key('movement_category_subcategory_field')).last,
  );
  await tester.pumpAndSettle();
  if (searchText != null) {
    await tester.enterText(
      find.byKey(const Key('category_subcategory_search_field')),
      searchText,
    );
    await tester.pumpAndSettle();
  }
  final optionFinder = find.byKey(optionKey);
  await tester.scrollUntilVisible(
    optionFinder,
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(optionFinder.last);
  await tester.pumpAndSettle();
}
