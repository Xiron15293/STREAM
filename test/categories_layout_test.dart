import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/main.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/screens/categories_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PreferencesService.categoryLayoutNotifier.value =
        PreferencesService.defaultCategoryLayout;
  });

  group('Category Layout Preference', () {
    testWidgets('default layout is cleanList', (WidgetTester tester) async {
      final db = AppDatabase();
      await db.addCategory('Prova Test', MovementType.expense, 0xFF42A5F5);
      final cat = db.categories.firstWhere((c) => c.name == 'Prova Test');

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('category_card_${cat.id}'), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byType(SegmentedButton<MovementType>), findsOneWidget);
    });

    testWidgets('cleanList layout renders categories correctly', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();
      await db.addCategory('Prova Clean', MovementType.expense, 0xFF42A5F5);
      final cat = db.categories.firstWhere((c) => c.name == 'Prova Clean');

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('category_card_${cat.id}'), skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.more_horiz), findsWidgets);
    });

    testWidgets('groupedList layout renders categories correctly', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'category_layout': 'groupedList',
      });
      final db = AppDatabase();
      await db.addCategory('Prova Grouped', MovementType.expense, 0xFF42A5F5);
      final cat = db.categories.firstWhere((c) => c.name == 'Prova Grouped');
      for (var i = 0; i < 4; i++) {
        await db.addMovement(
          Movement(
            id: 'grouped_mov_$i',
            title: 'Movimento grouped $i',
            amount: 10,
            type: MovementType.expense,
            date: DateTime.now(),
            categoryId: cat.id,
            accountId: defaultAccountId,
            createdAt: DateTime.now(),
          ),
        );
      }

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(find.text('TOP USCITE'), findsOneWidget);

      final card = find.byKey(
        Key('category_card_${cat.id}'),
        skipOffstage: false,
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);
    });

    testWidgets('streamCards layout renders categories correctly', (
      WidgetTester tester,
    ) async {
      await SharedPreferences.getInstance().then(
        (prefs) => prefs.setString('category_layout', 'streamCards'),
      );
      PreferencesService.categoryLayoutNotifier.value = 'streamCards';
      final db = AppDatabase();
      await db.addCategory('Prova Stream', MovementType.expense, 0xFF42A5F5);
      final visibleCat = db.categories.firstWhere(
        (c) => c.type == MovementType.expense,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CategoriesScreen(db: db)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('categories_layout_stream_cards')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('category_card_${visibleCat.id}'), skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('Type Filter', () {
    testWidgets('Entrate tab shows only income categories', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();
      await db.addCategory('Custom Uscita', MovementType.expense, 0xFFFF453A);
      await db.addCategory('Custom Entrata', MovementType.income, 0xFF34C759);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categories_filter_income')));
      await tester.pumpAndSettle();

      expect(find.text('Custom Entrata', skipOffstage: false), findsOneWidget);
      expect(find.text('Custom Uscita', skipOffstage: false), findsNothing);
    });

    testWidgets('Uscite tab shows only expense categories', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();
      await db.addCategory('Custom Uscita', MovementType.expense, 0xFFFF453A);
      await db.addCategory('Custom Entrata', MovementType.income, 0xFF34C759);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(find.text('Custom Uscita', skipOffstage: false), findsOneWidget);
      expect(find.text('Custom Entrata', skipOffstage: false), findsNothing);
    });

    testWidgets('archived categories respect active filter', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();
      await db.addCategory('Arch Only Income', MovementType.income, 0xFF34C759);
      final cat = db.categories.firstWhere((c) => c.name == 'Arch Only Income');
      await db.archiveCategory(cat.id);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_archived_section'),
          skipOffstage: false,
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('categories_filter_income')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_archived_section'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });
  });

  group('Category Actions', () {
    testWidgets('tap category opens movements sheet', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();
      await db.addCategory('Test Tap Cat', MovementType.expense, 0xFF42A5F5);
      final cat = db.categories.firstWhere((c) => c.name == 'Test Tap Cat');
      await db.addMovement(
        Movement(
          id: 'mov_tap_1',
          title: 'Movimento tap',
          amount: 50,
          type: MovementType.expense,
          date: DateTime.now(),
          categoryId: cat.id,
          accountId: defaultAccountId,
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      final card = find.byKey(
        Key('category_card_${cat.id}'),
        skipOffstage: false,
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_movements_name')), findsOneWidget);
    });

    testWidgets('popup edit opens dialog', (WidgetTester tester) async {
      final db = AppDatabase();
      await db.addCategory(
        'Da Modificare Test',
        MovementType.expense,
        0xFF42A5F5,
      );
      final cat = db.categories.firstWhere(
        (c) => c.name == 'Da Modificare Test',
      );

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      final card = find.byKey(
        Key('category_card_${cat.id}'),
        skipOffstage: false,
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();

      final popup = find.descendant(
        of: card,
        matching: find.byIcon(Icons.more_horiz),
      );
      await tester.tap(popup);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Modifica'));
      await tester.pumpAndSettle();

      expect(find.text('Modifica categoria'), findsOneWidget);
    });

    testWidgets('FAB adds category pre-filled with income type', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categories_filter_income')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categories_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Nuova categoria'), findsOneWidget);
      expect(find.text('Entrata'), findsOneWidget);
    });

    testWidgets('FAB from expense filter pre-fills expense type', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categories_fab')));
      await tester.pumpAndSettle();

      expect(find.text('Nuova categoria'), findsOneWidget);
      expect(find.text('Uscita'), findsOneWidget);
    });
  });

  group('KPI Summary Card', () {
    testWidgets('KPI appears on Uscite filter', (WidgetTester tester) async {
      final db = AppDatabase();
      await db.addCategory('Cibo', MovementType.expense, 0xFF42A5F5);
      await db.addCategory('Trasporti', MovementType.expense, 0xFFFF453A);
      await db.addCategory('Stipendio', MovementType.income, 0xFF34C759);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_type_summary_card'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('categories_summary_title'), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('categories_summary_active_count'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('categories_summary_archived_count'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets('KPI appears on Entrate filter', (WidgetTester tester) async {
      final db = AppDatabase();
      await db.addCategory('Cibo', MovementType.expense, 0xFF42A5F5);
      await db.addCategory('Stipendio', MovementType.income, 0xFF34C759);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categories_filter_income')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_type_summary_card'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('categories_summary_active_count'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('KPI updates counts when switching filter', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();
      await db.addCategory('Cibo', MovementType.expense, 0xFF42A5F5);
      await db.addCategory('Trasporti', MovementType.expense, 0xFFFF453A);
      await db.addCategory('Stipendio', MovementType.income, 0xFF34C759);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('categories_type_summary_card')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('categories_filter_income')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('categories_type_summary_card')),
        findsOneWidget,
      );
    });

    testWidgets('KPI counts archived filtered by type', (
      WidgetTester tester,
    ) async {
      final db = AppDatabase();
      await db.addCategory('Cibo', MovementType.expense, 0xFF42A5F5);
      await db.addCategory('Stipendio', MovementType.income, 0xFF34C759);
      final archCat = db.categories.firstWhere((c) => c.name == 'Cibo');
      await db.archiveCategory(archCat.id);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_summary_archived_count'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.text('1 archiviata', skipOffstage: false), findsOneWidget);

      await tester.tap(find.byKey(const Key('categories_filter_income')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_summary_archived_count'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });
  });

  group('Layout Keys', () {
    testWidgets('Clean list has key categories_layout_clean_list', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'category_layout': 'cleanList'});
      final db = AppDatabase();
      await db.addCategory('Test', MovementType.expense, 0xFF42A5F5);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_layout_clean_list'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Grouped list has key categories_layout_grouped_list', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'category_layout': 'groupedList',
      });
      final db = AppDatabase();
      await db.addCategory('Test', MovementType.expense, 0xFF42A5F5);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_layout_grouped_list'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Grouped list has key categories_top_group', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'category_layout': 'groupedList',
      });
      final db = AppDatabase();
      await db.addCategory('Test', MovementType.expense, 0xFF42A5F5);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('categories_top_group'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets(
      'Grouped list has categories_top_group, categories_active_group and categories_archived_group',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'category_layout': 'groupedList',
        });
        final db = AppDatabase();
        await db.addCategory('Cat 1', MovementType.expense, 0xFF42A5F5);
        await db.addCategory('Cat 2', MovementType.expense, 0xFFFF453A);
        await db.addCategory('Cat 3', MovementType.expense, 0xFF34C759);
        await db.addCategory('Cat 4', MovementType.expense, 0xFFFF9F0A);
        await db.addCategory('Cat 5', MovementType.expense, 0xFF007AFF);
        await db.addCategory('Archived Cat', MovementType.expense, 0xFFFF453A);
        final arch = db.categories.firstWhere((c) => c.name == 'Archived Cat');
        await db.archiveCategory(arch.id);

        await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('bottom_nav_archive')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('archive_section_categories')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('categories_top_group'), skipOffstage: false),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('categories_active_group'), skipOffstage: false),
          findsOneWidget,
        );

        await tester.drag(
          find.byKey(const Key('categories_layout_grouped_list')),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('categories_archived_group'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Stream cards has key categories_layout_stream_cards', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'category_layout': 'streamCards',
      });
      final db = AppDatabase();
      await db.addCategory('Test', MovementType.expense, 0xFF42A5F5);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_layout_stream_cards'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Stream cards grid has key categories_stream_card_grid', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'category_layout': 'streamCards',
      });
      final db = AppDatabase();
      await db.addCategory('Test', MovementType.expense, 0xFF42A5F5);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_stream_card_grid'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Stream cards grid items have categories_stream_category_card key',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'category_layout': 'streamCards',
        });
        final db = AppDatabase();
        await db.addCategory('Test', MovementType.expense, 0xFF42A5F5);

        await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('bottom_nav_archive')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('archive_section_categories')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const Key('categories_stream_category_card'),
            skipOffstage: false,
          ),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'Stream cards grid items with multiple categories show multiple category_card keys',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'category_layout': 'streamCards',
        });
        final db = AppDatabase();
        await db.addCategory('Cat A', MovementType.expense, 0xFF42A5F5);
        await db.addCategory('Cat B', MovementType.expense, 0xFFFF453A);
        await db.addCategory('Cat C', MovementType.expense, 0xFF34C759);

        await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('bottom_nav_archive')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('archive_section_categories')));
        await tester.pumpAndSettle();

        final cats = db.categories
            .where((c) => !c.archived && c.type == MovementType.expense)
            .take(4)
            .toList();
        for (final c in cats) {
          expect(
            find.byKey(Key('category_card_${c.id}'), skipOffstage: false),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'Stream card grid shows total amount for category with movements',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'category_layout': 'streamCards',
        });
        final db = AppDatabase();
        await db.addCategory('Cibo', MovementType.expense, 0xFF42A5F5);
        final cat = db.categories.firstWhere((c) => c.name == 'Cibo');
        await db.addMovement(
          Movement(
            id: 'mov_test_1',
            title: 'Spesa',
            amount: 125.50,
            type: MovementType.expense,
            date: DateTime.now(),
            categoryId: cat.id,
            accountId: defaultAccountId,
            createdAt: DateTime.now(),
          ),
        );
        await db.addMovement(
          Movement(
            id: 'mov_test_2',
            title: 'Ristorante',
            amount: 45.00,
            type: MovementType.expense,
            date: DateTime.now(),
            categoryId: cat.id,
            accountId: defaultAccountId,
            createdAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('bottom_nav_archive')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('archive_section_categories')));
        await tester.pumpAndSettle();

        expect(find.text('+170.50 €', skipOffstage: false), findsOneWidget);
        expect(find.text('2 movimenti', skipOffstage: false), findsOneWidget);
      },
    );

    testWidgets(
      'Stream card grid shows 0.00 € when category has no movements',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'category_layout': 'streamCards',
        });
        final db = AppDatabase();
        await db.addCategory('Vuota', MovementType.expense, 0xFF42A5F5);
        final visibleCat = db.categories.firstWhere(
          (c) => c.type == MovementType.expense,
        );

        await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('bottom_nav_archive')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('archive_section_categories')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(
              Key('category_card_${visibleCat.id}'),
              skipOffstage: false,
            ),
            matching: find.text('+0.00 €', skipOffstage: false),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Layout Mode Switch', () {
    testWidgets('Changing layout mode changes UI structure', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'category_layout': 'cleanList'});
      final db = AppDatabase();
      await db.addCategory('Test', MovementType.expense, 0xFF42A5F5);

      await tester.pumpWidget(MaterialApp(home: MainScaffold(db: db)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bottom_nav_archive')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('archive_section_categories')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_layout_clean_list'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      PreferencesService.categoryLayoutNotifier.value = 'groupedList';
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key('categories_layout_grouped_list'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('categories_layout_clean_list'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });
  });
}
