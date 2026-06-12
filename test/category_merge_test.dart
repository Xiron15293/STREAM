import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stream_app/data/database.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/favorite_movement.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/quick_movement.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/subcategory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Merge Category → Category', () {
    late AppDatabase db;
    late Category source;
    late Category target;

    setUp(() {
      db = AppDatabase();
      source = Category(
        id: 'src_cat',
        name: 'Alimentari',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      target = db.categories.firstWhere((c) => c.name == 'Spesa');
      db.internalAddCategory(source);
    });

    test('1. merge categoria → categoria sposta movimenti', () {
      db.addMovement(Movement(
        id: 'm1', title: 'M1', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
      ));

      expect(report.sourceType, 'category');
      expect(report.movementsUpdated, 1);
      expect(report.sourceCategoryArchived, true);

      final m = db.movements.firstWhere((m) => m.id == 'm1');
      expect(m.categoryId, target.id);
      expect(m.subcategoryId, isNull);
    });

    test('2. merge categoria → categoria sposta quick e favorite', () {
      db.internalAddQuickMovement(const QuickMovement(
        id: 'qm1', title: 'QM1', amount: 5,
        type: MovementType.expense, categoryId: 'src_cat',
      ));
      db.internalAddFavoriteMovement(const FavoriteMovement(
        id: 'fm1', title: 'FM1', amount: 3,
        type: MovementType.expense, categoryId: 'src_cat',
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
      ));

      expect(report.quickMovementsUpdated, 1);
      expect(report.favoriteMovementsUpdated, 1);

      final qm = db.quickMovements.firstWhere((q) => q.id == 'qm1');
      expect(qm.categoryId, target.id);

      final fm = db.favoriteMovements.firstWhere((f) => f.id == 'fm1');
      expect(fm.categoryId, target.id);
    });

    test('3. categoria sorgente archiviata ma non eliminata', () {
      db.internalAddQuickMovement(const QuickMovement(
        id: 'qm_arc', title: 'Q', amount: 5,
        type: MovementType.expense, categoryId: 'src_cat',
      ));

      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
      ));

      final archived = db.categories.firstWhere((c) => c.id == source.id);
      expect(archived.archived, true);
      expect(db.categories.any((c) => c.id == source.id), true);
    });
  });

  group('Merge Category → Subcategory', () {
    late AppDatabase db;
    late Category source;
    late Category target;

    setUp(() {
      db = AppDatabase();
      source = Category(
        id: 'src_cat2', name: 'Invisibili (Caffetteria)',
        type: MovementType.expense, color: 0xFF42A5F5,
      );
      target = db.categories.firstWhere((c) => c.name == 'Svago');
      db.internalAddCategory(source);
    });

    test('4. merge categoria → sottocategoria esistente', () async {
      await db.createSubcategory(target.id, 'Bar');
      final sub = db.getActiveSubcategoriesForCategory(target.id).first;

      db.addMovement(Movement(
        id: 'm4', title: 'Caffè', amount: 1.5,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        targetSubcategoryId: sub.id,
      ));

      expect(report.movementsUpdated, 1);
      expect(report.targetSubcategoryName, 'Bar');

      final m = db.movements.firstWhere((m) => m.id == 'm4');
      expect(m.categoryId, target.id);
      expect(m.subcategoryId, sub.id);
    });

    test('5. merge categoria → nuova sottocategoria', () {
      db.addMovement(Movement(
        id: 'm5', title: 'M5', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        createTargetSubcategoryName: 'Bar',
      ));

      expect(report.targetSubcategoryCreated, true);
      expect(report.movementsUpdated, 1);

      final m = db.movements.firstWhere((m) => m.id == 'm5');
      final sub = db.getActiveSubcategoriesForCategory(target.id).first;
      expect(m.categoryId, target.id);
      expect(m.subcategoryId, sub.id);
      expect(sub.name, 'Bar');
    });

    test('6. merge categoria → nuova sottocategoria riusa esistente', () async {
      await db.createSubcategory(target.id, 'Bar');
      final sub = db.getActiveSubcategoriesForCategory(target.id).first;

      db.addMovement(Movement(
        id: 'm6', title: 'M6', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        createTargetSubcategoryName: 'Bar',
      ));

      expect(report.targetSubcategoryCreated, false);
      expect(report.movementsUpdated, 1);

      final m = db.movements.firstWhere((m) => m.id == 'm6');
      expect(m.subcategoryId, sub.id);
    });
  });

  group('Merge Subcategory → Category', () {
    late AppDatabase db;
    late Category cat;
    late Subcategory sub;

    setUp(() async {
      db = AppDatabase();
      cat = db.categories.firstWhere((c) => c.name == 'Spesa');
      await db.createSubcategory(cat.id, 'Alimentari');
      sub = db.getActiveSubcategoriesForCategory(cat.id).first;
    });

    test('7. merge sottocategoria → categoria', () {
      db.addMovement(Movement(
        id: 'm7', title: 'M7', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: cat.id, subcategoryId: sub.id,
        createdAt: DateTime.now(),
      ));

      final target = db.categories.firstWhere((c) => c.name == 'Auto');
      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: cat.id,
        sourceSubcategoryId: sub.id,
        targetCategoryId: target.id,
      ));

      expect(report.sourceType, 'subcategory');
      expect(report.movementsUpdated, 1);
      expect(report.sourceSubcategoryArchived, true);

      final m = db.movements.firstWhere((m) => m.id == 'm7');
      expect(m.categoryId, target.id);
      expect(m.subcategoryId, isNull);
    });

    test('8. sottocategoria sorgente archiviata, categoria sorgente no', () {
      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: cat.id,
        sourceSubcategoryId: sub.id,
        targetCategoryId: db.categories.firstWhere((c) => c.id != cat.id && !c.archived && c.type == cat.type).id,
      ));

      expect(db.subcategories.firstWhere((s) => s.id == sub.id).archived, true);
      expect(db.categories.firstWhere((c) => c.id == cat.id).archived, false);
    });

    test('9. merge muove solo movimenti con quella sottocategoria', () {
      db.addMovement(Movement(
        id: 'm9a', title: 'ConSub', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: cat.id, subcategoryId: sub.id,
        createdAt: DateTime.now(),
      ));
      db.addMovement(Movement(
        id: 'm9b', title: 'SenzaSub', amount: 20,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: cat.id, createdAt: DateTime.now(),
      ));

      final target = db.categories.firstWhere((c) => c.name == 'Auto');
      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: cat.id,
        sourceSubcategoryId: sub.id,
        targetCategoryId: target.id,
      ));

      expect(db.subcategories.firstWhere((s) => s.id == sub.id).archived, true);
      expect(db.categories.firstWhere((c) => c.id == cat.id).archived, false);
    });
  });

  group('Merge Subcategory → Subcategory', () {
    late AppDatabase db;
    late Category cat;
    late Subcategory sourceSub;
    late Subcategory targetSub;

    setUp(() async {
      db = AppDatabase();
      cat = db.categories.firstWhere((c) => c.name == 'Spesa');
      await db.createSubcategory(cat.id, 'Alimentari');
      await db.createSubcategory(cat.id, 'Supermercato');
      sourceSub = db.subcategories.firstWhere((s) => s.name == 'Alimentari');
      targetSub = db.subcategories.firstWhere((s) => s.name == 'Supermercato');
    });

    test('10. merge sottocategoria → sottocategoria', () {
      db.addMovement(Movement(
        id: 'm10', title: 'M10', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: cat.id, subcategoryId: sourceSub.id,
        createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: cat.id,
        sourceSubcategoryId: sourceSub.id,
        targetCategoryId: cat.id,
        targetSubcategoryId: targetSub.id,
      ));

      expect(report.movementsUpdated, 1);
      expect(report.sourceSubcategoryArchived, true);

      final m = db.movements.firstWhere((m) => m.id == 'm10');
      expect(m.categoryId, cat.id);
      expect(m.subcategoryId, targetSub.id);
    });

    test('11. sottocategoria archiviata dopo merge', () {
      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: cat.id,
        sourceSubcategoryId: sourceSub.id,
        targetCategoryId: cat.id,
        targetSubcategoryId: targetSub.id,
      ));

      final archived = db.subcategories.firstWhere((s) => s.id == sourceSub.id);
      expect(archived.archived, true);
      expect(db.subcategories.any((s) => s.id == sourceSub.id), true);
    });

    test('12. quick/favorite movement con sottocategoria sorgente vengono spostati', () {
      db.internalAddQuickMovement(QuickMovement(
        id: 'qm_sub', title: 'QM', amount: 5,
        type: MovementType.expense, categoryId: cat.id,
        subcategoryId: sourceSub.id,
      ));
      db.internalAddFavoriteMovement(FavoriteMovement(
        id: 'fm_sub', title: 'FM', amount: 3,
        type: MovementType.expense, categoryId: cat.id,
        subcategoryId: sourceSub.id,
      ));

      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: cat.id,
        sourceSubcategoryId: sourceSub.id,
        targetCategoryId: cat.id,
        targetSubcategoryId: targetSub.id,
      ));

      expect(db.quickMovements.firstWhere((q) => q.id == 'qm_sub').subcategoryId, targetSub.id);
      expect(db.favoriteMovements.firstWhere((f) => f.id == 'fm_sub').subcategoryId, targetSub.id);
    });
  });

  group('Merge — Validazione e safety', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase();
    });

    test('13. source == target non permesso', () {
      final cat = db.categories.first;
      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: cat.id,
        targetCategoryId: cat.id,
      ));
      expect(report.warnings, isNotEmpty);
      expect(report.movementsUpdated, 0);
    });

    test('14. target archiviata non permesso', () {
      final src = db.categories.firstWhere((c) => !c.archived);
      final target = Category(
        id: 'arch_target', name: 'Archiviata',
        type: MovementType.expense, color: 0xFF000000, archived: true,
      );
      db.internalAddCategory(target);

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: src.id,
        targetCategoryId: target.id,
      ));
      expect(report.warnings, isNotEmpty);
    });

    test('15. report ha conteggi esatti', () {
      final src = Category(
        id: 'report_src', name: 'ReportSrc',
        type: MovementType.expense, color: 0xFF42A5F5,
      );
      db.internalAddCategory(src);
      final tgt = db.categories.firstWhere((c) => c.name == 'Spesa');

      db.addMovement(Movement(
        id: 'rpt_m', title: 'M', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: src.id, createdAt: DateTime.now(),
      ));
      db.internalAddQuickMovement(const QuickMovement(
        id: 'rpt_qm', title: 'Q', amount: 5,
        type: MovementType.expense, categoryId: 'report_src',
      ));
      db.internalAddFavoriteMovement(const FavoriteMovement(
        id: 'rpt_fm', title: 'F', amount: 3,
        type: MovementType.expense, categoryId: 'report_src',
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: src.id,
        targetCategoryId: tgt.id,
      ));

      expect(report.sourceCategoryName, 'ReportSrc');
      expect(report.targetCategoryName, 'Spesa');
      expect(report.movementsUpdated, 1);
      expect(report.quickMovementsUpdated, 1);
      expect(report.favoriteMovementsUpdated, 1);
      expect(report.sourceCategoryArchived, true);
    });

    test('16. merge con creazione nuova sottocategoria su altra categoria', () {
      final src = Category(
        id: 'cross_src', name: 'Extra1',
        type: MovementType.expense, color: 0xFF42A5F5,
      );
      db.internalAddCategory(src);
      final tgt = db.categories.firstWhere((c) => c.name == 'Salute');

      db.addMovement(Movement(
        id: 'cross_m', title: 'Cross', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: src.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: src.id,
        targetCategoryId: tgt.id,
        createTargetSubcategoryName: 'ExtraCategory',
      ));

      expect(report.targetSubcategoryCreated, true);
      expect(report.movementsUpdated, 1);
      expect(report.sourceCategoryArchived, true);

      final subs = db.getActiveSubcategoriesForCategory(tgt.id);
      expect(subs.any((s) => s.name == 'ExtraCategory'), true);

      final m = db.movements.firstWhere((m) => m.id == 'cross_m');
      expect(m.categoryId, tgt.id);
    });
  });

  group('Merge — Compatibilità conversione flat', () {
    test('17. conversione flat funziona ancora dopo aggiunta merge', () {
      final db = AppDatabase();
      final flat = Category(
        id: 'flat_compat',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      db.addMovement(Movement(
        id: 'flat_cm', title: 'FlatMov', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: 'flat_compat', createdAt: DateTime.now(),
      ));

      final report = db.convertFlatCategoryToSubcategory('flat_compat');
      expect(report, isNotNull);
      expect(report!.movementsUpdated, 1);
      expect(report.oldCategoryArchived, true);

      final parent = db.categories.firstWhere((c) => c.name == 'Spesa');
      final m = db.movements.firstWhere((m) => m.id == 'flat_cm');
      expect(m.categoryId, parent.id);
      expect(m.subcategoryId, isNotNull);
    });

    test('18. flat category unita manualmente verso target diverso', () {
      final db = AppDatabase();
      final tgt = db.categories.firstWhere((c) => c.name == 'Salute');

      final flat = Category(
        id: 'flat_manual',
        name: 'Spesa (Alimentari)',
        type: MovementType.expense,
        color: 0xFF42A5F5,
      );
      db.internalAddCategory(flat);

      db.addMovement(Movement(
        id: 'flat_man_m', title: 'M', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: 'flat_manual', createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: 'flat_manual',
        targetCategoryId: tgt.id,
        createTargetSubcategoryName: 'Alimentari',
      ));

      expect(report.movementsUpdated, 1);
      expect(report.targetSubcategoryCreated, true);
      expect(report.sourceCategoryArchived, true);

      final m = db.movements.firstWhere((m) => m.id == 'flat_man_m');
      expect(m.categoryId, tgt.id);
    });
  });

  group('Merge — categoria con sottocategorie figlie', () {
    late AppDatabase db;
    late Category source;
    late Category target;

    setUp(() {
      db = AppDatabase();
      source = Category(
        id: 'src_parent', name: 'Genitore',
        type: MovementType.expense, color: 0xFF42A5F5,
      );
      target = db.categories.firstWhere((c) => c.name == 'Spesa');
      db.internalAddCategory(source);
    });

    test('21. merge categoria senza sottocategorie figlie resta invariato', () {
      db.addMovement(Movement(
        id: 'm21', title: 'M21', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
      ));

      expect(report.movementsUpdated, 1);
      expect(report.sourceCategoryArchived, true);
      expect(report.childSubcategoriesMoved, 0);
      expect(report.childSubcategoriesMerged, 0);
      expect(report.childSubcategoriesArchived, 0);
    });

    test('22. merge categoria con sottocategorie figlie spostate sotto target', () async {
      await db.createSubcategory(source.id, 'Figlia1');
      final child = db.subcategories.firstWhere((s) => s.name == 'Figlia1');

      db.addMovement(Movement(
        id: 'm22a', title: 'M22a', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, subcategoryId: child.id,
        createdAt: DateTime.now(),
      ));
      db.addMovement(Movement(
        id: 'm22b', title: 'M22b', amount: 20,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        childSubcategoryActions: [
          ChildSubcategoryAction(
            subcategoryId: child.id, action: 'move',
          ),
        ],
      ));

      expect(report.movementsUpdated, 2);
      expect(report.childSubcategoriesMoved, 1);
      expect(report.sourceCategoryArchived, true);

      // Child subcategory moved to target
      final movedSub = db.subcategories.firstWhere((s) => s.id == child.id);
      expect(movedSub.categoryId, target.id);
      expect(movedSub.archived, false);

      // Movement with subcategory now points to target
      final m = db.movements.firstWhere((m) => m.id == 'm22a');
      expect(m.categoryId, target.id);
      expect(m.subcategoryId, child.id);
    });

    test('23. merge categoria con sottocategoria figlia unita a sottocategoria target esistente', () async {
      await db.createSubcategory(source.id, 'Bar');
      final child = db.subcategories.firstWhere((s) => s.name == 'Bar');
      await db.createSubcategory(target.id, 'Caffetteria');
      final targetSub = db.subcategories.firstWhere((s) => s.name == 'Caffetteria');

      db.addMovement(Movement(
        id: 'm23', title: 'M23', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, subcategoryId: child.id,
        createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        childSubcategoryActions: [
          ChildSubcategoryAction(
            subcategoryId: child.id,
            action: 'merge',
            targetSubcategoryId: targetSub.id,
          ),
        ],
      ));

      expect(report.movementsUpdated, 1);
      expect(report.childSubcategoriesMerged, 1);
      expect(db.subcategories.firstWhere((s) => s.id == child.id).archived, true);

      final m = db.movements.firstWhere((m) => m.id == 'm23');
      expect(m.categoryId, target.id);
      expect(m.subcategoryId, targetSub.id);
    });

    test('24. quick/favorite seguono mapping figlie', () async {
      await db.createSubcategory(source.id, 'QM');
      final child = db.subcategories.firstWhere((s) => s.name == 'QM');

      db.internalAddQuickMovement(QuickMovement(
        id: 'qm_child', title: 'QM', amount: 5,
        type: MovementType.expense, categoryId: source.id,
        subcategoryId: child.id,
      ));
      db.internalAddFavoriteMovement(FavoriteMovement(
        id: 'fm_child', title: 'FM', amount: 3,
        type: MovementType.expense, categoryId: source.id,
        subcategoryId: child.id,
      ));

      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        childSubcategoryActions: [
          ChildSubcategoryAction(subcategoryId: child.id, action: 'move'),
        ],
      ));

      expect(db.quickMovements.firstWhere((q) => q.id == 'qm_child').categoryId, target.id);
      expect(db.favoriteMovements.firstWhere((f) => f.id == 'fm_child').categoryId, target.id);
    });

    test('25. sottocategoria figlia archiviata esplicitamente', () async {
      await db.createSubcategory(source.id, 'Archivia');
      final child = db.subcategories.firstWhere((s) => s.name == 'Archivia');

      db.addMovement(Movement(
        id: 'm25', title: 'M25', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: source.id, subcategoryId: child.id,
        createdAt: DateTime.now(),
      ));

      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        childSubcategoryActions: [
          ChildSubcategoryAction(subcategoryId: child.id, action: 'archive'),
        ],
      ));

      expect(db.subcategories.firstWhere((s) => s.id == child.id).archived, true);
      // Movement still moved to target category (no subcategory)
      final m = db.movements.firstWhere((m) => m.id == 'm25');
      expect(m.categoryId, target.id);
    });

    test('26. sottocategoria figlia mantenuta (non archiviata)', () async {
      await db.createSubcategory(source.id, 'Mantieni');
      final child = db.subcategories.firstWhere((s) => s.name == 'Mantieni');

      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        childSubcategoryActions: [
          ChildSubcategoryAction(subcategoryId: child.id, action: 'keep'),
        ],
      ));

      // Child stays under source category (which is archived)
      expect(db.subcategories.firstWhere((s) => s.id == child.id).archived, false);
    });

    test('27. report dettagliato corretto con figlie multiple', () async {
      await db.createSubcategory(source.id, 'A');
      await db.createSubcategory(source.id, 'B');
      await db.createSubcategory(source.id, 'C');
      final a = db.subcategories.firstWhere((s) => s.name == 'A');
      final b = db.subcategories.firstWhere((s) => s.name == 'B');
      final c = db.subcategories.firstWhere((s) => s.name == 'C');

      await db.createSubcategory(target.id, 'Btarget');
      final bTarget = db.subcategories.firstWhere((s) => s.name == 'Btarget');

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: source.id,
        targetCategoryId: target.id,
        childSubcategoryActions: [
          ChildSubcategoryAction(subcategoryId: a.id, action: 'move'),
          ChildSubcategoryAction(
            subcategoryId: b.id, action: 'merge',
            targetSubcategoryId: bTarget.id,
          ),
          ChildSubcategoryAction(subcategoryId: c.id, action: 'archive'),
        ],
      ));

      expect(report.childSubcategoriesMoved, 1);
      expect(report.childSubcategoriesMerged, 1);
      expect(report.childSubcategoriesArchived, 1);
      expect(report.childSubcategoriesKept, 0);
      expect(report.childSubcategoryDetails.length, 3);

      expect(db.subcategories.firstWhere((s) => s.id == a.id).categoryId, target.id);
      expect(db.subcategories.firstWhere((s) => s.id == b.id).archived, true);
      expect(db.subcategories.firstWhere((s) => s.id == c.id).archived, true);
    });
  });

  group('Merge — SQLite persistence', () {
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

    test('19. merge persiste dopo reload', () async {
      final cats = db.activeCategories;
      final src = cats.firstWhere((c) => c.name == 'Spesa');
      final tgt = cats.firstWhere((c) => c.name == 'Auto');

      await db.addMovement(Movement(
        id: 'persist_m', title: 'Persist', amount: 10,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: src.id, createdAt: DateTime.now(),
      ));

      final report = db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: src.id,
        targetCategoryId: tgt.id,
      ));
      expect(report.movementsUpdated, 1);

      await db.reloadFromDb();

      final m = db.movements.firstWhere((m) => m.id == 'persist_m');
      expect(m.categoryId, tgt.id);

      final archived = db.categories.firstWhere((c) => c.id == src.id);
      expect(archived.archived, true);
    });

    test('20. merge con sottocategoria persiste dopo reload', () async {
      final cats = db.activeCategories;
      final src = cats.firstWhere((c) => c.name == 'Casa');
      final tgt = cats.firstWhere((c) => c.name == 'Spesa');

      await db.createSubcategory(src.id, 'Cinema');
      final sub = db.getActiveSubcategoriesForCategory(src.id).first;

      await db.addMovement(Movement(
        id: 'persist_sub_m', title: 'Sub', amount: 15,
        type: MovementType.expense, date: DateTime.now(),
        categoryId: src.id, subcategoryId: sub.id,
        createdAt: DateTime.now(),
      ));

      await db.createSubcategory(tgt.id, 'Intrattenimento');
      final tgtSub = db.getActiveSubcategoriesForCategory(tgt.id).first;

      db.mergeCategoryOrSubcategory(CategoryMergeRequest(
        sourceCategoryId: src.id,
        sourceSubcategoryId: sub.id,
        targetCategoryId: tgt.id,
        targetSubcategoryId: tgtSub.id,
      ));

      await db.reloadFromDb();

      final m = db.movements.firstWhere((m) => m.id == 'persist_sub_m');
      expect(m.categoryId, tgt.id);
      expect(m.subcategoryId, tgtSub.id);

      expect(db.subcategories.firstWhere((s) => s.id == sub.id).archived, true);
    });
  });
}
