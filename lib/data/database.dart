import 'package:flutter/foundation.dart' hide Category;
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/account.dart';
import '../models/quick_movement.dart';
import '../models/favorite_movement.dart';
import 'categories_data.dart';
import 'sqlite_service.dart';

class AppDatabase extends ChangeNotifier {
  final SQLiteService? _sqlite;
  final List<Movement> _movements = [];
  List<Category> _categories = [];
  final List<Subcategory> _subcategories = [];
  List<QuickMovement> _quickMovements = [];
  final List<FavoriteMovement> _favoriteMovements = [];
  List<Account> _accounts = [];

  AppDatabase({SQLiteService? sqlite}) : _sqlite = sqlite {
    if (sqlite == null) {
      _categories = List.from(DefaultCategories.all);
      _quickMovements = _defaultQuickMovements();
      _accounts = [
        Account(
          id: defaultAccountId,
          name: 'Principale',
          type: AccountType.bank,
          iconKey: StreamIconLibrary.defaultAccountIcon,
          color: StreamColorPalette.getDefault(),
          createdAt: DateTime.now(),
        ),
      ];
    }
  }

  List<QuickMovement> _defaultQuickMovements() => [
        const QuickMovement(
          id: 'qm_1', title: 'Caffè', amount: 1.50,
          type: MovementType.expense, categoryId: 'exp_4',
          accountId: defaultAccountId,
        ),
        const QuickMovement(
          id: 'qm_2', title: 'Benzina', amount: 50.0,
          type: MovementType.expense, categoryId: 'exp_3',
          accountId: defaultAccountId,
        ),
        const QuickMovement(
          id: 'qm_3', title: 'Spesa', amount: 80.0,
          type: MovementType.expense, categoryId: 'exp_1',
          accountId: defaultAccountId,
        ),
        const QuickMovement(
          id: 'qm_4', title: 'Stipendio', amount: 2500.0,
          type: MovementType.income, categoryId: 'inc_1',
          accountId: defaultAccountId,
        ),
      ];

  Future<void> initialize() async {
    if (_sqlite == null) return;

    if (await _getCategoriesCount() == 0) {
      _categories = List.from(DefaultCategories.all);
      for (final c in _categories) {
        await _sqlite.insertCategory(c);
      }
      final defaults = _defaultQuickMovements();
      for (final qm in defaults) {
        await _sqlite.insertQuickMovement(qm);
      }
    }

    _categories = await _sqlite.loadCategories();
    _subcategories
      ..clear()
      ..addAll(await _sqlite.loadSubcategories());
    _movements
      ..clear()
      ..addAll(await _sqlite.loadMovements());
    _quickMovements = await _sqlite.loadQuickMovements();
    _favoriteMovements
      ..clear()
      ..addAll(await _sqlite.loadFavoriteMovements());
    _accounts = await _sqlite.loadAccounts();
    notifyListeners();
  }

  Future<int> _getCategoriesCount() async {
    try {
      return await _sqlite!.getCategoriesCount();
    } catch (_) {
      return 0;
    }
  }

  List<Movement> get movements => List.unmodifiable(_movements);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Subcategory> get subcategories => List.unmodifiable(_subcategories);
  List<QuickMovement> get quickMovements => List.unmodifiable(_quickMovements);
  List<FavoriteMovement> get favoriteMovements =>
      List.unmodifiable(_favoriteMovements);
  List<Account> get accounts => List.unmodifiable(_accounts);

  Account? getAccountOrNull(String id) {
    final idx = _accounts.indexWhere((a) => a.id == id);
    return idx >= 0 ? _accounts[idx] : null;
  }

  Account getAccount(String id) {
    return _accounts.firstWhere((a) => a.id == id, orElse: () => Account(
      id: id,
      name: 'Conto eliminato',
      type: AccountType.bank,
      createdAt: DateTime(2020),
    ));
  }

  double getAccountBalance(Account a) {
    final movementsSum = _movements.fold<double>(
      0.0,
      (sum, m) => sum + m.impactForAccount(a.id),
    );
    return a.initialBalance + movementsSum;
  }

  double get totalAccountsBalance {
    double total = 0;
    for (final a in _accounts.where((a) => !a.archived)) {
      total += getAccountBalance(a);
    }
    return total;
  }

  List<Movement> get lastMovements {
    final sorted = List<Movement>.from(_movements)
      ..sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return compareMovementsForDisplay(a, b);
      });
    return sorted.take(5).toList();
  }

  double get totalIncome {
    return sumIncome(_movements);
  }

  double get totalExpenses {
    return sumExpenses(_movements);
  }

  double get balance => netIncomeExpense(_movements);

  Future<void> addMovement(Movement movement) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertMovement(movement);
      } catch (_) {
        return;
      }
    }
    _movements.add(movement);
    notifyListeners();
  }

  Future<void> deleteMovement(String id) async {
    if (_sqlite != null) {
      try {
        await _sqlite.deleteMovement(id);
      } catch (_) {
        return;
      }
    }
    _movements.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> updateMovement(Movement updated) async {
    final index = _movements.indexWhere((m) => m.id == updated.id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.updateMovement(updated);
      } catch (_) {
        return;
      }
    }
    _movements[index] = updated;
    notifyListeners();
  }

  Future<void> addQuickMovement(QuickMovement qm) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertQuickMovement(qm);
      } catch (_) {
        return;
      }
    }
    _quickMovements.add(qm);
    notifyListeners();
  }

  Future<void> updateQuickMovement(String id, QuickMovement updated) async {
    final index = _quickMovements.indexWhere((q) => q.id == id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.updateQuickMovement(id, updated);
      } catch (_) {
        return;
      }
    }
    _quickMovements[index] = updated;
    notifyListeners();
  }

  Future<void> deleteQuickMovement(String id) async {
    if (_sqlite != null) {
      try {
        await _sqlite.deleteQuickMovement(id);
      } catch (_) {
        return;
      }
    }
    _quickMovements.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  Future<void> addFavoriteMovement(FavoriteMovement fm) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertFavoriteMovement(fm);
      } catch (_) {
        return;
      }
    }
    _favoriteMovements.add(fm);
    notifyListeners();
  }

  Future<void> updateFavoriteMovement(FavoriteMovement updated) async {
    final index = _favoriteMovements.indexWhere((f) => f.id == updated.id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.updateFavoriteMovement(updated);
      } catch (_) {
        return;
      }
    }
    _favoriteMovements[index] = updated;
    notifyListeners();
  }

  Future<void> deleteFavoriteMovement(String id) async {
    if (_sqlite != null) {
      try {
        await _sqlite.deleteFavoriteMovement(id);
      } catch (_) {
        return;
      }
    }
    _favoriteMovements.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  Future<void> duplicateMovement(Movement m) async {
    final clone = Movement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: m.title,
      amount: m.amount,
      type: m.type,
      date: DateTime.now(),
      categoryId: m.categoryId,
      subcategoryId: m.subcategoryId,
      accountId: m.accountId,
      note: m.note,
      createdAt: DateTime.now(),
    );
    if (_sqlite != null) {
      try {
        await _sqlite.insertMovement(clone);
      } catch (_) {
        return;
      }
    }
    _movements.add(clone);
    notifyListeners();
  }

  Future<void> saveMovementAsFavorite(Movement m) async {
    final fav = FavoriteMovement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: m.title,
      amount: m.amount,
      type: m.type,
      categoryId: m.categoryId,
      subcategoryId: m.subcategoryId,
      accountId: m.accountId,
      note: m.note,
    );
    if (_sqlite != null) {
      try {
        await _sqlite.insertFavoriteMovement(fav);
      } catch (_) {
        return;
      }
    }
    _favoriteMovements.add(fav);
    notifyListeners();
  }

  Future<Movement> createMovementFromTemplate({
    required String title,
    required double amount,
    required MovementType type,
    required String categoryId,
    String? subcategoryId,
    String? note,
    String? accountId,
    String? destinationAccountId,
    DateTime? date,
  }) async {
    final sanitizedTitle = title.trim();
    final originAccountId = accountId ?? defaultAccountId;
    final finalTitle = sanitizedTitle.isNotEmpty
        ? sanitizedTitle
        : type == MovementType.transfer
            ? _buildTransferTitle(originAccountId, destinationAccountId)
            : title;
    final movement = Movement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: finalTitle,
      amount: amount,
      type: type,
      date: date ?? DateTime.now(),
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      accountId: originAccountId,
      destinationAccountId: destinationAccountId,
      note: note,
      createdAt: DateTime.now(),
    );
    if (_sqlite != null) {
      try {
        await _sqlite.insertMovement(movement);
      } catch (_) {
        return movement;
      }
    }
    _movements.add(movement);
    notifyListeners();
    return movement;
  }

  String _buildTransferTitle(String originAccountId, String? destinationAccountId) {
    final origin = getAccount(originAccountId).name;
    final destination = destinationAccountId == null
        ? 'Conto destinazione'
        : getAccount(destinationAccountId).name;
    return 'Trasferimento: $origin → $destination';
  }

  // ── Categories CRUD ──

  bool categoryHasMovements(String categoryId) {
    return _movements.any((m) => m.categoryId == categoryId);
  }

  List<Category> get activeCategories =>
      _categories.where((c) => !c.archived).toList();

  Future<void> addCategory(String name, MovementType type, int color, {String iconKey = StreamIconLibrary.defaultCategoryIcon}) async {
    final id = 'cat_${DateTime.now().microsecondsSinceEpoch.toString()}';
    final c = Category(id: id, name: name, type: type, color: color, iconKey: iconKey);
    if (_sqlite != null) {
      try {
        await _sqlite.insertCategory(c);
      } catch (_) {
        return;
      }
    }
    _categories.add(c);
    notifyListeners();
  }

  Future<void> updateCategory(String id, String name, int color, {bool? archived, MovementType? type, String? iconKey}) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final old = _categories[index];
    final updated = Category(
      id: id,
      name: name,
      type: type ?? old.type,
      color: color,
      iconKey: iconKey ?? old.iconKey,
      archived: archived ?? old.archived,
    );
    if (_sqlite != null) {
      try {
        await _sqlite.updateCategory(updated);
      } catch (_) {
        return;
      }
    }
    _categories[index] = updated;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    if (_sqlite != null) {
      try {
        await _sqlite.deleteCategory(id);
      } catch (_) {
        return;
      }
    }
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> archiveCategory(String id) async {
    final cat = _categories.firstWhere((c) => c.id == id);
    await updateCategory(id, cat.name, cat.color, archived: true);
  }

  Future<void> restoreCategory(String id) async {
    final cat = _categories.firstWhere((c) => c.id == id);
    await updateCategory(id, cat.name, cat.color, archived: false);
  }

  // ── Subcategories CRUD ──

  List<Subcategory> getSubcategoriesForCategory(String categoryId) {
    return _subcategories.where((s) => s.categoryId == categoryId).toList();
  }

  List<Subcategory> getActiveSubcategoriesForCategory(String categoryId) {
    return _subcategories
        .where((s) => s.categoryId == categoryId && !s.archived)
        .toList();
  }

  bool subcategoryNameExists(String categoryId, String name) {
    return _subcategories.any(
      (s) => s.categoryId == categoryId &&
          s.name.toLowerCase() == name.trim().toLowerCase(),
    );
  }

  Future<void> createSubcategory(String categoryId, String name) async {
    final id = 'sub_${DateTime.now().microsecondsSinceEpoch.toString()}';
    final now = DateTime.now();
    final s = Subcategory(
      id: id,
      categoryId: categoryId,
      name: name.trim(),
      createdAt: now,
    );
    if (_sqlite != null) {
      try {
        await _sqlite.insertSubcategory(s);
      } catch (_) {
        return;
      }
    }
    _subcategories.add(s);
    notifyListeners();
  }

  Future<void> updateSubcategory(String id, String name) async {
    final index = _subcategories.indexWhere((s) => s.id == id);
    if (index < 0) return;
    final old = _subcategories[index];
    final updated = Subcategory(
      id: id,
      categoryId: old.categoryId,
      name: name.trim(),
      archived: old.archived,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    if (_sqlite != null) {
      try {
        await _sqlite.updateSubcategory(updated);
      } catch (_) {
        return;
      }
    }
    _subcategories[index] = updated;
    notifyListeners();
  }

  Future<void> archiveSubcategory(String id) async {
    final index = _subcategories.indexWhere((s) => s.id == id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.archiveSubcategory(id);
      } catch (_) {
        return;
      }
    }
    final old = _subcategories[index];
    _subcategories[index] = Subcategory(
      id: id,
      categoryId: old.categoryId,
      name: old.name,
      archived: true,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> restoreSubcategory(String id) async {
    final index = _subcategories.indexWhere((s) => s.id == id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.restoreSubcategory(id);
      } catch (_) {
        return;
      }
    }
    final old = _subcategories[index];
    _subcategories[index] = Subcategory(
      id: id,
      categoryId: old.categoryId,
      name: old.name,
      archived: false,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> deleteSubcategory(String id) async {
    if (_sqlite != null) {
      try {
        await _sqlite.deleteSubcategory(id);
      } catch (_) {
        return;
      }
    }
    _subcategories.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ── Accounts ──

  Future<void> addAccount(Account a) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertAccount(a);
      } catch (_) {
        return;
      }
    }
    _accounts.add(a);
    notifyListeners();
  }

  Future<void> archiveAccount(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.archiveAccount(id);
      } catch (_) {
        return;
      }
    }
    _accounts[index] = Account(
      id: _accounts[index].id,
      name: _accounts[index].name,
      type: _accounts[index].type,
      initialBalance: _accounts[index].initialBalance,
      iconKey: _accounts[index].iconKey,
      color: _accounts[index].color,
      archived: true,
      createdAt: _accounts[index].createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> updateAccount(String id, String name, AccountType type, double initialBalance, {String? iconKey, int? color}) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index < 0) return;
    final updated = Account(
      id: id,
      name: name,
      type: type,
      initialBalance: initialBalance,
      iconKey: iconKey ?? _accounts[index].iconKey,
      color: color ?? _accounts[index].color,
      archived: _accounts[index].archived,
      createdAt: _accounts[index].createdAt,
      updatedAt: DateTime.now(),
    );
    if (_sqlite != null) {
      try {
        await _sqlite.updateAccount(id, updated);
      } catch (_) {
        return;
      }
    }
    _accounts[index] = updated;
    notifyListeners();
  }

  List<FavoriteMovement> getSuggestions() {
    final groups = <String, List<Movement>>{};
    for (final m in _movements) {
      final key =
          '${m.categoryId}|${m.title.toLowerCase().trim()}|${m.type.index}';
      groups.putIfAbsent(key, () => []).add(m);
    }

    final suggestions = <FavoriteMovement>[];
    for (final entry in groups.entries) {
      if (entry.value.length >= 5) {
        final m = entry.value.last;
        suggestions.add(FavoriteMovement(
          id: 'sug_${entry.key.hashCode}',
          title: m.title,
          amount: m.amount,
          type: m.type,
          categoryId: m.categoryId,
          accountId: m.accountId,
          note: m.note,
        ));
      }
    }
    return suggestions;
  }

  Future<void> reloadFromDb() async {
    if (_sqlite == null) return;
    try {
      _movements
        ..clear()
        ..addAll(await _sqlite.loadMovements());
      _categories = await _sqlite.loadCategories();
      _subcategories
        ..clear()
        ..addAll(await _sqlite.loadSubcategories());
      _quickMovements = await _sqlite.loadQuickMovements();
      _favoriteMovements
        ..clear()
        ..addAll(await _sqlite.loadFavoriteMovements());
      _accounts = await _sqlite.loadAccounts();
    } catch (e) {
      debugPrint('reloadFromDb error: $e');
    }
    notifyListeners();
  }

  Future<void> resetAllData() async {
    if (_sqlite == null) {
      _movements.clear();
      _categories = List.from(DefaultCategories.all);
      _subcategories.clear();
      _quickMovements = _defaultQuickMovements();
      _favoriteMovements.clear();
      _accounts = [
        Account(
          id: defaultAccountId,
          name: 'Principale',
          type: AccountType.bank,
          iconKey: StreamIconLibrary.defaultAccountIcon,
          color: StreamColorPalette.getDefault(),
          createdAt: DateTime.now(),
        ),
      ];
      notifyListeners();
      return;
    }

    await _sqlite.resetAllData();
    await reloadFromDb();
  }

  void notify() {
    notifyListeners();
  }

  // ── Backup/Restore internal API ──

  SQLiteService? get sqliteService => _sqlite;

  void clearMemory() {
    _movements.clear();
    _categories.clear();
    _subcategories.clear();
    _quickMovements.clear();
    _favoriteMovements.clear();
    _accounts.clear();
  }

  CategoryConversionReport? convertFlatCategoryToSubcategory(String categoryId) {
    final oldIndex = _categories.indexWhere((c) => c.id == categoryId);
    if (oldIndex < 0) return null;
    final oldCat = _categories[oldIndex];
    if (oldCat.archived) return null;

    final parsed = _parseCategoryName(oldCat.name);
    if (parsed == null) return null;
    final (parentName, subcategoryName) = parsed;

    // Find or create parent category
    Category? existingParent;
    try {
      existingParent = _categories.firstWhere(
        (c) => c.name == parentName && c.type == oldCat.type && !c.archived,
      );
    } catch (_) {}
    bool parentCreated = false;
    Category parent;
    if (existingParent != null) {
      parent = existingParent;
    } else {
      parent = Category(
        id: 'cat_${DateTime.now().microsecondsSinceEpoch.toString()}',
        name: parentName,
        type: oldCat.type,
        color: oldCat.color,
        iconKey: oldCat.iconKey,
      );
      _categories.add(parent);
      parentCreated = true;
      if (_sqlite != null) {
        _sqlite.insertCategory(parent);
      }
    }

    // Find or create subcategory
    bool subcategoryCreated = false;
    Subcategory sub;
    Subcategory? existingSub;
    try {
      existingSub = _subcategories.firstWhere(
        (s) => s.categoryId == parent.id && s.name == subcategoryName,
      );
    } catch (_) {}
    if (existingSub != null) {
      sub = existingSub;
    } else {
      sub = Subcategory(
        id: 'sub_${DateTime.now().microsecondsSinceEpoch.toString()}',
        categoryId: parent.id,
        name: subcategoryName,
        createdAt: DateTime.now(),
      );
      _subcategories.add(sub);
      subcategoryCreated = true;
      if (_sqlite != null) {
        _sqlite.insertSubcategory(sub);
      }
    }

    // Reassign movements
    int movementsUpdated = 0;
    for (var i = 0; i < _movements.length; i++) {
      final m = _movements[i];
      if (m.categoryId == oldCat.id) {
        final updated = m.copyWith(categoryId: parent.id, subcategoryId: sub.id);
        _movements[i] = updated;
        if (_sqlite != null) {
          _sqlite.updateMovement(updated);
        }
        movementsUpdated++;
      }
    }

    // Reassign quick movements
    int quickMovementsUpdated = 0;
    for (var i = 0; i < _quickMovements.length; i++) {
      final qm = _quickMovements[i];
      if (qm.categoryId == oldCat.id) {
        final updated = QuickMovement(
          id: qm.id,
          title: qm.title,
          amount: qm.amount,
          type: qm.type,
          categoryId: parent.id,
          subcategoryId: sub.id,
          accountId: qm.accountId,
          note: qm.note,
        );
        _quickMovements[i] = updated;
        if (_sqlite != null) {
          _sqlite.updateQuickMovement(qm.id, updated);
        }
        quickMovementsUpdated++;
      }
    }

    // Reassign favorite movements
    int favoriteMovementsUpdated = 0;
    for (var i = 0; i < _favoriteMovements.length; i++) {
      final fm = _favoriteMovements[i];
      if (fm.categoryId == oldCat.id) {
        final updated = FavoriteMovement(
          id: fm.id,
          title: fm.title,
          amount: fm.amount,
          type: fm.type,
          categoryId: parent.id,
          subcategoryId: sub.id,
          accountId: fm.accountId,
          note: fm.note,
        );
        _favoriteMovements[i] = updated;
        if (_sqlite != null) {
          _sqlite.updateFavoriteMovement(updated);
        }
        favoriteMovementsUpdated++;
      }
    }

    // Archive old category
    final archived = _categories[oldIndex];
    final oldArchived = Category(
      id: archived.id,
      name: archived.name,
      type: archived.type,
      color: archived.color,
      iconKey: archived.iconKey,
      archived: true,
    );
    _categories[oldIndex] = oldArchived;
    if (_sqlite != null) {
      _sqlite.updateCategory(oldArchived);
    }

    notifyListeners();

    return CategoryConversionReport(
      oldCategoryName: oldCat.name,
      parentCategoryName: parentName,
      subcategoryName: subcategoryName,
      parentCategoryCreated: parentCreated,
      subcategoryCreated: subcategoryCreated,
      movementsUpdated: movementsUpdated,
      quickMovementsUpdated: quickMovementsUpdated,
      favoriteMovementsUpdated: favoriteMovementsUpdated,
      oldCategoryArchived: true,
    );
  }

  (String, String)? _parseCategoryName(String name) {
    var trimmed = name.trim();
    final parenOpen = trimmed.lastIndexOf('(');
    if (parenOpen < 1) return null;
    final parenClose = trimmed.indexOf(')', parenOpen);
    if (parenClose < 0 || parenClose != trimmed.length - 1) return null;
    var parentName = trimmed.substring(0, parenOpen).trim();
    var subName = trimmed.substring(parenOpen + 1, parenClose).trim();
    parentName = parentName.replaceAll(RegExp(r'\s{2,}'), ' ');
    subName = subName.replaceAll(RegExp(r'\s{2,}'), ' ');
    if (parentName.isEmpty || subName.isEmpty) return null;
    return (parentName, subName);
  }

  void replaceState({
    required List<Movement> movements,
    required List<Category> categories,
    required List<Subcategory> subcategories,
    required List<QuickMovement> quickMovements,
    required List<FavoriteMovement> favoriteMovements,
    required List<Account> accounts,
  }) {
    _movements
      ..clear()
      ..addAll(movements);
    _categories = List.from(categories);
    _subcategories
      ..clear()
      ..addAll(subcategories);
    _quickMovements = List.from(quickMovements);
    _favoriteMovements
      ..clear()
      ..addAll(favoriteMovements);
    _accounts = List.from(accounts);
  }

  Future<void> internalAddAccount(Account a) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertAccount(a);
      } catch (_) {
        return;
      }
    }
    _accounts.add(a);
  }

  Future<void> internalAddCategory(Category c) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertCategory(c);
      } catch (_) {
        return;
      }
    }
    _categories.add(c);
  }

  Future<void> internalAddOrUpdateCategory(Category c) async {
    if (_sqlite != null) {
      try {
        final idx = _categories.indexWhere((x) => x.id == c.id);
        if (idx >= 0) {
          await _sqlite.updateCategory(c);
        } else {
          await _sqlite.insertCategory(c);
        }
      } catch (_) {
        return;
      }
    }
    final idx = _categories.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      _categories[idx] = c;
    } else {
      _categories.add(c);
    }
  }

  Future<void> internalAddMovement(Movement m) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertMovement(m);
      } catch (_) {
        return;
      }
    }
    _movements.add(m);
  }

  Future<void> internalAddQuickMovement(QuickMovement qm) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertQuickMovement(qm);
      } catch (_) {
        return;
      }
    }
    _quickMovements.add(qm);
  }

  Future<void> internalAddSubcategory(Subcategory s) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertSubcategory(s);
      } catch (_) {
        return;
      }
    }
    _subcategories.add(s);
  }

  Future<void> internalAddFavoriteMovement(FavoriteMovement fm) async {
    if (_sqlite != null) {
      try {
        await _sqlite.insertFavoriteMovement(fm);
      } catch (_) {
        return;
      }
    }
    _favoriteMovements.add(fm);
  }
}

class CategoryConversionReport {
  final String oldCategoryName;
  final String parentCategoryName;
  final String subcategoryName;
  final bool parentCategoryCreated;
  final bool subcategoryCreated;
  final int movementsUpdated;
  final int quickMovementsUpdated;
  final int favoriteMovementsUpdated;
  final bool oldCategoryArchived;

  const CategoryConversionReport({
    required this.oldCategoryName,
    required this.parentCategoryName,
    required this.subcategoryName,
    required this.parentCategoryCreated,
    required this.subcategoryCreated,
    required this.movementsUpdated,
    required this.quickMovementsUpdated,
    required this.favoriteMovementsUpdated,
    required this.oldCategoryArchived,
  });
}
