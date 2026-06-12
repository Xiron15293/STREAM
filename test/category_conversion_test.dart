import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/quick_movement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('FIX 1 — Modifica categoria con movimenti', () {
    late AppDatabase db;
    late Category cat;

    setUp(() {
      db = AppDatabase();
      cat = db.categories.first;
    });

    test('1. categoria con movimenti può essere rinominata', () {
      final mov = Movement(
        id: 'm1',
        title: 'Test',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);
      expect(db.categoryHasMovements(cat.id), true);

      db.updateCategory(cat.id, 'NuovoNome', cat.color);
      final updated = db.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.name, 'NuovoNome');
    });

    test('2. movimento resta collegato dopo rename categoria', () {
      final mov = Movement(
        id: 'm2',
        title: 'Test',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);
      db.updateCategory(cat.id, 'NuovoNome2', cat.color, iconKey: cat.iconKey);

      final m = db.movements.firstWhere((m) => m.id == 'm2');
      expect(m.categoryId, cat.id);
      expect(m.amount, 10);
    });

    test('3. categoria con movimenti può cambiare colore', () {
      final mov = Movement(
        id: 'm3',
        title: 'Test',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);
      db.updateCategory(cat.id, cat.name, 0xFF123456, iconKey: cat.iconKey);
      final updated = db.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.color, 0xFF123456);
    });

    test('4. categoria con movimenti può cambiare icona', () {
      final mov = Movement(
        id: 'm4',
        title: 'Test',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);
      db.updateCategory(cat.id, cat.name, cat.color, iconKey: 'shopping_cart');
      final updated = db.categories.firstWhere((c) => c.id == cat.id);
      expect(updated.iconKey, 'shopping_cart');
    });
  });

  group('FIX 2 — Sottocategorie su categoria con movimenti', () {
    late AppDatabase db;
    late Category cat;

    setUp(() {
      db = AppDatabase();
      cat = db.categories.first;
    });

    test('5. posso aggiungere sottocategoria a categoria con movimenti', () async {
      final mov = Movement(
        id: 'm5',
        title: 'Test',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);

      await db.createSubcategory(cat.id, 'SubConMovimenti');
      final subs = db.getSubcategoriesForCategory(cat.id);
      expect(subs.length, 1);
      expect(subs.first.name, 'SubConMovimenti');
    });

    test('6. vecchio movimento resta con subcategoryId null dopo creazione sottocategoria', () async {
      final mov = Movement(
        id: 'm6',
        title: 'Vecchio',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);

      await db.createSubcategory(cat.id, 'Sub2');
      final m = db.movements.firstWhere((m) => m.id == 'm6');
      expect(m.subcategoryId, isNull);
    });

    test('7. nuovo movimento può usare sottocategoria su categoria con movimenti', () async {
      final mov = Movement(
        id: 'm7a',
        title: 'Vecchio',
        amount: 10,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(mov);

      await db.createSubcategory(cat.id, 'Sub3');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      final nuovo = Movement(
        id: 'm7b',
        title: 'Nuovo',
        amount: 20,
        type: cat.type,
        date: DateTime.now(),
        categoryId: cat.id,
        subcategoryId: sub.id,
        createdAt: DateTime.now(),
      );
      db.addMovement(nuovo);
      expect(nuovo.subcategoryId, sub.id);
    });

    test('8. rinomino sottocategoria su categoria con movimenti', () async {
      await db.createSubcategory(cat.id, 'SubDaRinominare');
      final sub = db.getSubcategoriesForCategory(cat.id).first;
      await db.updateSubcategory(sub.id, 'Rinominata');

      final updated = db.subcategories.firstWhere((s) => s.id == sub.id);
      expect(updated.name, 'Rinominata');
    });

    test('9. archivio/ripristino sottocategoria su categoria con movimenti', () async {
      await db.createSubcategory(cat.id, 'SubArchivio');
      final sub = db.getSubcategoriesForCategory(cat.id).first;

      await db.archiveSubcategory(sub.id);
      expect(db.subcategories.firstWhere((s) => s.id == sub.id).archived, true);

      await db.restoreSubcategory(sub.id);
      expect(db.subcategories.firstWhere((s) => s.id == sub.id).archived, false);
    });
  });

  group('Conversione — Categoria flat in sottocategoria', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase();
    });

    test('10. categoria "Spesa \\(Alimentari\\)" è convertibile', () {
      final flat = Category(
        id: 'flat_1',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);
      expect(db.categories.any((c) => c.id == 'flat_1'), true,
          reason: 'categoria flat aggiunta');

      final report = db.convertFlatCategoryToSubcategory('flat_1');
      expect(report, isNotNull);
      expect(report!.parentCategoryName, 'Spesa');
      expect(report.subcategoryName, 'Alimentari');
      // Default categories già contengono "Spesa" (exp_1)
      expect(report.parentCategoryCreated, false);
      expect(report.subcategoryCreated, true);
      expect(report.oldCategoryArchived, true);

      final archived = db.categories.firstWhere((c) => c.id == 'flat_1');
      expect(archived.archived, true);

      final parent = db.categories.firstWhere((c) => c.name == 'Spesa');
      expect(parent.archived, false);

      final subs = db.getSubcategoriesForCategory(parent.id);
      expect(subs.any((s) => s.name == 'Alimentari'), true);
    });

    test('11. categoria "Spesa" non è convertibile', () {
      final cat = db.categories.first;
      final report = db.convertFlatCategoryToSubcategory(cat.id);
      expect(report, isNull);
    });

    test('12. categoria malformata non è convertibile', () {
      final flat = Category(
        id: 'flat_malformed',
        name: 'SenzaParen',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);
      expect(db.convertFlatCategoryToSubcategory('flat_malformed'), isNull);

      final flat2 = Category(
        id: 'flat_malformed2',
        name: 'SoloOpen (',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat2);
      expect(db.convertFlatCategoryToSubcategory('flat_malformed2'), isNull);

      final flat3 = Category(
        id: 'flat_malformed3',
        name: '(SoloSub)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat3);
      expect(db.convertFlatCategoryToSubcategory('flat_malformed3'), isNull);
    });

    test('13. conversione riusa categoria madre esistente', () {
      // Crea prima una categoria madre con nome unico (non default)
      final parent = Category(
        id: 'existing_parent',
        name: 'Extra',
        type: MovementType.expense,
        color: 0xFF123456,
        iconKey: 'shopping_cart',
      );
      db.internalAddCategory(parent);

      // Poi la flat
      final flat = Category(
        id: 'flat_2',
        name: 'Extra (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      final report = db.convertFlatCategoryToSubcategory('flat_2');
      expect(report, isNotNull);
      expect(report!.parentCategoryCreated, false);
      expect(report.subcategoryCreated, true);

      // Categoria madre preserva colore/icona originali
      final updatedParent = db.categories.firstWhere((c) => c.id == 'existing_parent');
      expect(updatedParent.color, 0xFF123456);
      expect(updatedParent.iconKey, 'shopping_cart');
    });

    test('14. conversione riusa sottocategoria esistente', () async {
      // La categoria "Spesa" (exp_1) esiste già nei default
      final spesaId = db.categories.firstWhere((c) => c.name == 'Spesa').id;
      await db.createSubcategory(spesaId, 'Alimentari');

      final flat = Category(
        id: 'flat_3',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      final report = db.convertFlatCategoryToSubcategory('flat_3');
      expect(report, isNotNull);
      expect(report!.parentCategoryCreated, false);
      expect(report.subcategoryCreated, false);
    });

    test('15. riassegna movimenti alla categoria madre con sottocategoria', () {
      final flat = Category(
        id: 'flat_4',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      db.addMovement(Movement(
        id: 'conv_m1',
        title: 'Mov1',
        amount: 10,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'flat_4',
        createdAt: DateTime.now(),
      ));
      db.addMovement(Movement(
        id: 'conv_m2',
        title: 'Mov2',
        amount: 20,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'flat_4',
        createdAt: DateTime.now(),
      ));

      final report = db.convertFlatCategoryToSubcategory('flat_4');
      expect(report!.movementsUpdated, 2);

      final m1 = db.movements.firstWhere((m) => m.id == 'conv_m1');
      final parent = db.categories.firstWhere((c) => c.name == 'Spesa');
      expect(m1.categoryId, parent.id);
      expect(m1.subcategoryId, isNotNull);

      final m2 = db.movements.firstWhere((m) => m.id == 'conv_m2');
      expect(m2.categoryId, parent.id);
      expect(m2.subcategoryId, isNotNull);
    });

    test('16. riassegna quick_movements', () {
      final flat = Category(
        id: 'flat_5',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      // Usa internalAddQuickMovement per aggirare account requirement
      db.internalAddQuickMovement(
        const QuickMovement(
          id: 'conv_qm1',
          title: 'Quick1',
          amount: 5,
          type: MovementType.expense,
          categoryId: 'flat_5',
        ),
      );

      final report = db.convertFlatCategoryToSubcategory('flat_5');
      expect(report!.quickMovementsUpdated, 1);

      final qm = db.quickMovements.firstWhere((q) => q.id == 'conv_qm1');
      final parent = db.categories.firstWhere((c) => c.name == 'Spesa');
      expect(qm.categoryId, parent.id);
      expect(qm.subcategoryId, isNotNull);
    });

    test('17. riassegna favorite_movements', () {
      final flat = Category(
        id: 'flat_6',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      db.internalAddFavoriteMovement(
        const FavoriteMovement(
          id: 'conv_fm1',
          title: 'Fav1',
          amount: 5,
          type: MovementType.expense,
          categoryId: 'flat_6',
        ),
      );

      final report = db.convertFlatCategoryToSubcategory('flat_6');
      expect(report!.favoriteMovementsUpdated, 1);

      final fm = db.favoriteMovements.firstWhere((f) => f.id == 'conv_fm1');
      final parent = db.categories.firstWhere((c) => c.name == 'Spesa');
      expect(fm.categoryId, parent.id);
      expect(fm.subcategoryId, isNotNull);
    });

    test('18. categoria flat archiviata ma non eliminata', () {
      final flat = Category(
        id: 'flat_7',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      db.convertFlatCategoryToSubcategory('flat_7');

      final archived = db.categories.firstWhere((c) => c.id == 'flat_7');
      expect(archived.archived, true);
      // La categoria è ancora presente nel database
      expect(db.categories.any((c) => c.id == 'flat_7'), true);
    });

    test('19. report contiene conteggi corretti', () {
      final flat = Category(
        id: 'flat_8',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      db.addMovement(Movement(
        id: 'conv_r1',
        title: 'R1',
        amount: 10,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'flat_8',
        createdAt: DateTime.now(),
      ));
      db.internalAddQuickMovement(
        const QuickMovement(
          id: 'conv_qr1',
          title: 'QR1',
          amount: 5,
          type: MovementType.expense,
          categoryId: 'flat_8',
        ),
      );
      db.internalAddFavoriteMovement(
        const FavoriteMovement(
          id: 'conv_fr1',
          title: 'FR1',
          amount: 3,
          type: MovementType.expense,
          categoryId: 'flat_8',
        ),
      );

      final report = db.convertFlatCategoryToSubcategory('flat_8');
      expect(report!.oldCategoryName, 'Spesa (Alimentari)');
      expect(report.parentCategoryName, 'Spesa');
      expect(report.subcategoryName, 'Alimentari');
      expect(report.movementsUpdated, 1);
      expect(report.quickMovementsUpdated, 1);
      expect(report.favoriteMovementsUpdated, 1);
      expect(report.oldCategoryArchived, true);
    });

    test('20. categoria archiviata non è convertibile', () {
      final flat = Category(
        id: 'flat_archived',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
        archived: true,
      );
      db.internalAddCategory(flat);
      expect(db.convertFlatCategoryToSubcategory('flat_archived'), isNull);
    });

    test('21. treemap aggregazione corretta dopo conversione', () {
      final flat = Category(
        id: 'flat_treemap',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      db.addMovement(Movement(
        id: 'conv_tm1',
        title: 'TM1',
        amount: 100,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'flat_treemap',
        createdAt: DateTime.now(),
      ));

      db.convertFlatCategoryToSubcategory('flat_treemap');

      final parent = db.categories.firstWhere((c) => c.name == 'Spesa');
      // Il movimento ora punta a parent
      final total = db.movements
          .where((m) => m.categoryId == parent.id)
          .fold<double>(0.0, (sum, m) => sum + m.amount);
      expect(total, 100);
    });
  });

  group('Conversione — SQLite persistence', () {
    late SQLiteService sqlite;
    late AppDatabase db;

    setUp(() async {
      sqlite = SQLiteService();
      await sqlite.open(path: inMemoryDatabasePath);
      db = AppDatabase(sqlite: sqlite);
      await db.initialize();
    });

    tearDown(() async {
      await sqlite.close();
    });

    test('22. conversione persiste dopo reload', () async {
      final flat = Category(
        id: 'flat_persist',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      await db.internalAddCategory(flat);

      await db.addMovement(Movement(
        id: 'conv_p1',
        title: 'Persist',
        amount: 50,
        type: MovementType.expense,
        date: DateTime.now(),
        categoryId: 'flat_persist',
        createdAt: DateTime.now(),
      ));

      final report = db.convertFlatCategoryToSubcategory('flat_persist');
      expect(report, isNotNull);
      expect(report!.movementsUpdated, 1);

      await db.reloadFromDb();

      // Categoria flat archiviata
      final archived = db.categories.firstWhere((c) => c.id == 'flat_persist');
      expect(archived.archived, true);

      // Categoria madre creata
      final parent = db.categories.firstWhere((c) => c.name == 'Spesa');
      expect(parent.archived, false);

      // Movimento riassegnato
      final m = db.movements.firstWhere((m) => m.id == 'conv_p1');
      expect(m.categoryId, parent.id);
      expect(m.subcategoryId, isNotNull);
    });
  });
}
