import 'package:flutter/foundation.dart' hide Category;
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/account.dart';
import '../models/quick_movement.dart';
import '../models/favorite_movement.dart';
import '../models/beneficiary_profile.dart';
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
  final List<BeneficiaryProfile> _beneficiaryProfiles = [];

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
      id: 'qm_1',
      title: 'Caffè',
      amount: 1.50,
      type: MovementType.expense,
      categoryId: 'exp_4',
      accountId: defaultAccountId,
    ),
    const QuickMovement(
      id: 'qm_2',
      title: 'Benzina',
      amount: 50.0,
      type: MovementType.expense,
      categoryId: 'exp_3',
      accountId: defaultAccountId,
    ),
    const QuickMovement(
      id: 'qm_3',
      title: 'Spesa',
      amount: 80.0,
      type: MovementType.expense,
      categoryId: 'exp_1',
      accountId: defaultAccountId,
    ),
    const QuickMovement(
      id: 'qm_4',
      title: 'Stipendio',
      amount: 2500.0,
      type: MovementType.income,
      categoryId: 'inc_1',
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
    _beneficiaryProfiles
      ..clear()
      ..addAll(await _sqlite.loadBeneficiaryProfiles());
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
  List<BeneficiaryProfile> get beneficiaryProfiles =>
      List.unmodifiable(_beneficiaryProfiles);

  Account? getAccountOrNull(String id) {
    final idx = _accounts.indexWhere((a) => a.id == id);
    return idx >= 0 ? _accounts[idx] : null;
  }

  Account getAccount(String id) {
    return _accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => Account(
        id: id,
        name: 'Conto eliminato',
        type: AccountType.bank,
        createdAt: DateTime(2020),
      ),
    );
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

  Future<void> duplicateMovement(Movement m, {DateTime? date}) async {
    final now = DateTime.now();
    final clone = Movement(
      id: now.microsecondsSinceEpoch.toString(),
      title: m.title,
      amount: m.amount,
      type: m.type,
      date: date ?? now,
      categoryId: m.categoryId,
      subcategoryId: m.subcategoryId,
      accountId: m.accountId,
      destinationAccountId: m.destinationAccountId,
      note: m.note,
      payee: m.payee,
      createdAt: now,
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

  Future<void> saveMovementAsQuick(Movement m) async {
    final qm = QuickMovement(
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
        await _sqlite.insertQuickMovement(qm);
      } catch (_) {
        return;
      }
    }
    _quickMovements.add(qm);
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
    String? payee,
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
      payee: payee,
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

  String _buildTransferTitle(
    String originAccountId,
    String? destinationAccountId,
  ) {
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

  int categoryMovementCount(String categoryId) {
    return _movements.where((m) => m.categoryId == categoryId).length;
  }

  String _normalizeName(String value) => value.trim().toLowerCase();

  bool categoryNameExists(
    MovementType type,
    String name, {
    String? excludingCategoryId,
  }) {
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) return false;
    return _categories.any(
      (c) =>
          c.type == type &&
          c.id != excludingCategoryId &&
          _normalizeName(c.name) == normalized,
    );
  }

  bool categoryHasSubcategories(String categoryId) {
    return _subcategories.any((s) => s.categoryId == categoryId);
  }

  bool categoryHasQuickMovements(String categoryId) {
    return _quickMovements.any((q) => q.categoryId == categoryId);
  }

  bool categoryHasFavoriteMovements(String categoryId) {
    return _favoriteMovements.any((f) => f.categoryId == categoryId);
  }

  bool categoryHasLinkedContent(String categoryId) {
    return categoryHasMovements(categoryId) ||
        categoryHasSubcategories(categoryId) ||
        categoryHasQuickMovements(categoryId) ||
        categoryHasFavoriteMovements(categoryId);
  }

  List<Category> get activeCategories =>
      _categories.where((c) => !c.archived).toList();

  Future<void> addCategory(
    String name,
    MovementType type,
    int color, {
    String iconKey = StreamIconLibrary.defaultCategoryIcon,
  }) async {
    final id = 'cat_${DateTime.now().microsecondsSinceEpoch.toString()}';
    final c = Category(
      id: id,
      name: name,
      type: type,
      color: color,
      iconKey: iconKey,
    );
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

  Future<void> updateCategory(
    String id,
    String name,
    int color, {
    bool? archived,
    MovementType? type,
    String? iconKey,
    Set<String>? propagateToSubcategoryIds,
  }) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final old = _categories[index];
    final oldCategoryColor = old.color;
    final oldCategoryIconKey = old.iconKey;
    final newCategoryColor = color;
    final newCategoryIconKey = iconKey ?? old.iconKey;
    final updated = Category(
      id: id,
      name: name,
      type: type ?? old.type,
      color: newCategoryColor,
      iconKey: newCategoryIconKey,
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

    if (propagateToSubcategoryIds != null) {
      for (int i = 0; i < _subcategories.length; i++) {
        if (_subcategories[i].categoryId != id) continue;
        if (!propagateToSubcategoryIds.contains(_subcategories[i].id)) continue;
        final sc = _subcategories[i];
        final updatedSub = Subcategory(
          id: sc.id,
          categoryId: sc.categoryId,
          name: sc.name,
          iconKey: newCategoryIconKey,
          color: newCategoryColor,
          archived: sc.archived,
          createdAt: sc.createdAt,
          updatedAt: DateTime.now(),
        );
        if (_sqlite != null) {
          try {
            await _sqlite.updateSubcategory(updatedSub);
          } catch (_) {}
        }
        _subcategories[i] = updatedSub;
      }
    } else {
      for (int i = 0; i < _subcategories.length; i++) {
        if (_subcategories[i].categoryId != id) continue;
        final sc = _subcategories[i];
        final updateColor = sc.color == null || sc.color == oldCategoryColor;
        final updateIcon =
            sc.iconKey == null || sc.iconKey == oldCategoryIconKey;
        if (!updateColor && !updateIcon) continue;
        final updatedSub = Subcategory(
          id: sc.id,
          categoryId: sc.categoryId,
          name: sc.name,
          iconKey: updateIcon ? newCategoryIconKey : sc.iconKey,
          color: updateColor ? newCategoryColor : sc.color,
          archived: sc.archived,
          createdAt: sc.createdAt,
          updatedAt: DateTime.now(),
        );
        if (_sqlite != null) {
          try {
            await _sqlite.updateSubcategory(updatedSub);
          } catch (_) {}
        }
        _subcategories[i] = updatedSub;
      }
    }

    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    if (categoryHasLinkedContent(id)) {
      return;
    }
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

  bool subcategoryNameExists(
    String categoryId,
    String name, {
    String? excludingSubcategoryId,
  }) {
    final normalized = _normalizeName(name);
    if (normalized.isEmpty) return false;
    return _subcategories.any(
      (s) =>
          s.categoryId == categoryId &&
          s.id != excludingSubcategoryId &&
          _normalizeName(s.name) == normalized,
    );
  }

  Future<void> createSubcategory(
    String categoryId,
    String name, {
    String? iconKey,
    int? color,
  }) async {
    final id = 'sub_${DateTime.now().microsecondsSinceEpoch.toString()}';
    final now = DateTime.now();
    final s = Subcategory(
      id: id,
      categoryId: categoryId,
      name: name.trim(),
      iconKey: iconKey,
      color: color,
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

  Future<void> updateSubcategory(
    String id,
    String name, {
    String? iconKey,
    int? color,
  }) async {
    final index = _subcategories.indexWhere((s) => s.id == id);
    if (index < 0) return;
    final old = _subcategories[index];
    final updated = Subcategory(
      id: id,
      categoryId: old.categoryId,
      name: name.trim(),
      iconKey: iconKey ?? old.iconKey,
      color: color ?? old.color,
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
      iconKey: old.iconKey,
      color: old.color,
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
      iconKey: old.iconKey,
      color: old.color,
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

  int subcategoryMovementCount(String subcategoryId) {
    return _movements.where((m) => m.subcategoryId == subcategoryId).length;
  }

  int subcategoryQuickCount(String subcategoryId) {
    return _quickMovements
        .where((q) => q.subcategoryId == subcategoryId)
        .length;
  }

  int subcategoryFavoriteCount(String subcategoryId) {
    return _favoriteMovements
        .where((f) => f.subcategoryId == subcategoryId)
        .length;
  }

  Future<void> deleteSubcategoryCascade(String id) async {
    if (_sqlite != null) {
      try {
        await _sqlite.clearSubcategoryFromMovements(id);
        await _sqlite.deleteSubcategory(id);
      } catch (_) {
        return;
      }
    }
    _subcategories.removeWhere((s) => s.id == id);
    for (int i = 0; i < _movements.length; i++) {
      if (_movements[i].subcategoryId == id) {
        _movements[i] = _movements[i].copyWith(
          subcategoryId: null,
          updatedAt: DateTime.now(),
        );
      }
    }
    for (int i = 0; i < _quickMovements.length; i++) {
      if (_quickMovements[i].subcategoryId == id) {
        _quickMovements[i] = QuickMovement(
          id: _quickMovements[i].id,
          title: _quickMovements[i].title,
          amount: _quickMovements[i].amount,
          type: _quickMovements[i].type,
          categoryId: _quickMovements[i].categoryId,
          subcategoryId: null,
          accountId: _quickMovements[i].accountId,
          note: _quickMovements[i].note,
        );
      }
    }
    for (int i = 0; i < _favoriteMovements.length; i++) {
      if (_favoriteMovements[i].subcategoryId == id) {
        _favoriteMovements[i] = FavoriteMovement(
          id: _favoriteMovements[i].id,
          title: _favoriteMovements[i].title,
          amount: _favoriteMovements[i].amount,
          type: _favoriteMovements[i].type,
          categoryId: _favoriteMovements[i].categoryId,
          subcategoryId: null,
          accountId: _favoriteMovements[i].accountId,
          note: _favoriteMovements[i].note,
        );
      }
    }
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

  Future<void> restoreAccount(String id) async {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.restoreAccount(id);
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
      archived: false,
      createdAt: _accounts[index].createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<bool> reassignMovementsAndDeleteCategory({
    required String sourceCategoryId,
    required String targetCategoryId,
  }) async {
    if (sourceCategoryId == targetCategoryId) return false;
    final sourceIndex = _categories.indexWhere((c) => c.id == sourceCategoryId);
    final target = _categories
        .where((c) => c.id == targetCategoryId)
        .firstOrNull;
    if (sourceIndex < 0 || target == null || target.archived) return false;

    final source = _categories[sourceIndex];
    if (source.type != target.type) return false;
    if (categoryHasQuickMovements(sourceCategoryId) ||
        categoryHasFavoriteMovements(sourceCategoryId)) {
      return false;
    }

    if (_sqlite != null) {
      try {
        await _sqlite.reassignMovementsAndDeleteCategory(
          sourceCategoryId: sourceCategoryId,
          targetCategoryId: targetCategoryId,
        );
      } catch (_) {
        return false;
      }
    }

    final now = DateTime.now();
    for (int i = 0; i < _movements.length; i++) {
      final movement = _movements[i];
      if (movement.categoryId != sourceCategoryId) continue;
      _movements[i] = movement.copyWith(
        categoryId: targetCategoryId,
        subcategoryId: null,
        updatedAt: now,
      );
    }
    _subcategories.removeWhere((s) => s.categoryId == sourceCategoryId);
    _categories.removeAt(sourceIndex);
    notifyListeners();
    return true;
  }

  Future<void> updateAccount(
    String id,
    String name,
    AccountType type,
    double initialBalance, {
    String? iconKey,
    int? color,
  }) async {
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
        suggestions.add(
          FavoriteMovement(
            id: 'sug_${entry.key.hashCode}',
            title: m.title,
            amount: m.amount,
            type: m.type,
            categoryId: m.categoryId,
            accountId: m.accountId,
            note: m.note,
          ),
        );
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
      _beneficiaryProfiles
        ..clear()
        ..addAll(await _sqlite.loadBeneficiaryProfiles());
    } catch (e) {
      debugPrint('reloadFromDb error: $e');
    }
    notifyListeners();
  }

  Future<void> resetAllData() async {
    final dbPath = _sqlite?.path;
    debugPrint('[Reset] resetAllData dbPath=${dbPath ?? 'in-memory'}');
    if (_sqlite == null) {
      _movements.clear();
      _categories = List.from(DefaultCategories.all);
      _subcategories.clear();
      _quickMovements = _defaultQuickMovements();
      _favoriteMovements.clear();
      _beneficiaryProfiles.clear();
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
    _beneficiaryProfiles.clear();
    _accounts.clear();
  }

  CategoryConversionReport? convertFlatCategoryToSubcategory(
    String categoryId,
  ) {
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
        final updated = m.copyWith(
          categoryId: parent.id,
          subcategoryId: sub.id,
        );
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
    List<BeneficiaryProfile>? beneficiaries,
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
    if (beneficiaries != null) {
      _beneficiaryProfiles
        ..clear()
        ..addAll(beneficiaries);
    }
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

  // ── Beneficiary Profiles ──

  BeneficiaryProfile? getBeneficiaryProfile(String key) {
    final idx = _beneficiaryProfiles.indexWhere((b) => b.key == key);
    return idx >= 0 ? _beneficiaryProfiles[idx] : null;
  }

  bool hasBeneficiaryProfile(String key) {
    return _beneficiaryProfiles.any((b) => b.key == key);
  }

  bool get hasAnyBeneficiaryProfiles => _beneficiaryProfiles.isNotEmpty;

  String cleanBeneficiaryName(String? payee) {
    if (payee == null) return '';
    return BeneficiaryProfile.cleanDisplayName(payee);
  }

  BeneficiaryProfile? resolveBeneficiaryProfile(String? payee) {
    final cleaned = cleanBeneficiaryName(payee);
    if (cleaned.isEmpty) return null;
    return getBeneficiaryProfile(BeneficiaryProfile.normalizeKey(cleaned));
  }

  Future<void> addBeneficiaryProfile(BeneficiaryProfile bp) async {
    final existingIndex = _beneficiaryProfiles.indexWhere(
      (b) => b.key == bp.key,
    );
    if (existingIndex >= 0) {
      _beneficiaryProfiles[existingIndex] = bp.copyWith(
        id: _beneficiaryProfiles[existingIndex].id,
        createdAt: _beneficiaryProfiles[existingIndex].createdAt,
        updatedAt: DateTime.now(),
      );
      if (_sqlite != null) {
        try {
          await _sqlite.updateBeneficiaryProfile(
            _beneficiaryProfiles[existingIndex],
          );
        } catch (_) {
          return;
        }
      }
      notifyListeners();
      return;
    }
    if (_sqlite != null) {
      try {
        await _sqlite.insertBeneficiaryProfile(bp);
      } catch (_) {
        return;
      }
    }
    _beneficiaryProfiles.add(bp);
    notifyListeners();
  }

  Future<void> updateBeneficiaryProfile(BeneficiaryProfile bp) async {
    final index = _beneficiaryProfiles.indexWhere((b) => b.id == bp.id);
    if (index < 0) return;
    if (_sqlite != null) {
      try {
        await _sqlite.updateBeneficiaryProfile(bp);
      } catch (_) {
        return;
      }
    }
    _beneficiaryProfiles[index] = bp;
    notifyListeners();
  }

  Future<void> deleteBeneficiaryProfile(String id) async {
    if (_sqlite != null) {
      try {
        await _sqlite.deleteBeneficiaryProfile(id);
      } catch (_) {
        return;
      }
    }
    _beneficiaryProfiles.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<BeneficiaryProfile?> createManualBeneficiaryProfile(
    String rawName, {
    String iconKey = BeneficiaryProfile.defaultIconKey,
    int color = StreamColorPalette.defaultColor,
  }) async {
    final cleaned = cleanBeneficiaryName(rawName);
    if (cleaned.isEmpty) return null;
    final key = BeneficiaryProfile.normalizeKey(cleaned);
    if (hasBeneficiaryProfile(key)) return getBeneficiaryProfile(key);

    final profile = BeneficiaryProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      key: key,
      displayName: cleaned,
      iconKey: iconKey,
      color: color,
      createdAt: DateTime.now(),
    );
    await addBeneficiaryProfile(profile);
    return getBeneficiaryProfile(key) ?? profile;
  }

  String resolveBeneficiaryDisplayName(String? payee) {
    final cleaned = cleanBeneficiaryName(payee);
    if (cleaned.isEmpty) return '';
    final profile = resolveBeneficiaryProfile(cleaned);
    return profile?.displayName ?? cleaned;
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

class ChildSubcategoryAction {
  final String subcategoryId;
  final String action; // 'move', 'merge', 'archive', 'keep'
  final String? targetSubcategoryId;
  final String? createTargetSubcategoryName;

  const ChildSubcategoryAction({
    required this.subcategoryId,
    required this.action,
    this.targetSubcategoryId,
    this.createTargetSubcategoryName,
  });
}

class CategoryMergeRequest {
  final String sourceCategoryId;
  final String? sourceSubcategoryId;
  final String targetCategoryId;
  final String? targetSubcategoryId;
  final String? createTargetSubcategoryName;
  final bool archiveSource;
  final bool archiveEmptySourceCategory;
  final List<ChildSubcategoryAction>? childSubcategoryActions;

  const CategoryMergeRequest({
    required this.sourceCategoryId,
    this.sourceSubcategoryId,
    required this.targetCategoryId,
    this.targetSubcategoryId,
    this.createTargetSubcategoryName,
    this.archiveSource = true,
    this.archiveEmptySourceCategory = false,
    this.childSubcategoryActions,
  });
}

class ChildSubcategoryReportEntry {
  final String subcategoryName;
  final String action;
  final bool archived;

  const ChildSubcategoryReportEntry({
    required this.subcategoryName,
    required this.action,
    required this.archived,
  });
}

class CategoryMergeReport {
  final String sourceType; // 'category' | 'subcategory'
  final String sourceCategoryName;
  final String? sourceSubcategoryName;
  final String targetCategoryName;
  final String? targetSubcategoryName;
  final bool targetSubcategoryCreated;
  final int movementsUpdated;
  final int quickMovementsUpdated;
  final int favoriteMovementsUpdated;
  final bool sourceCategoryArchived;
  final bool sourceSubcategoryArchived;
  final bool emptySourceCategoryArchived;
  final int childSubcategoriesMoved;
  final int childSubcategoriesMerged;
  final int childSubcategoriesArchived;
  final int childSubcategoriesKept;
  final List<ChildSubcategoryReportEntry> childSubcategoryDetails;
  final List<String> warnings;

  const CategoryMergeReport({
    required this.sourceType,
    required this.sourceCategoryName,
    this.sourceSubcategoryName,
    required this.targetCategoryName,
    this.targetSubcategoryName,
    this.targetSubcategoryCreated = false,
    this.movementsUpdated = 0,
    this.quickMovementsUpdated = 0,
    this.favoriteMovementsUpdated = 0,
    this.sourceCategoryArchived = false,
    this.sourceSubcategoryArchived = false,
    this.emptySourceCategoryArchived = false,
    this.childSubcategoriesMoved = 0,
    this.childSubcategoriesMerged = 0,
    this.childSubcategoriesArchived = 0,
    this.childSubcategoriesKept = 0,
    this.childSubcategoryDetails = const [],
    this.warnings = const [],
  });
}

extension AppDatabaseMerge on AppDatabase {
  CategoryMergeReport mergeCategoryOrSubcategory(CategoryMergeRequest req) {
    final warnings = <String>[];

    // Validate source and target are different
    if (req.sourceCategoryId == req.targetCategoryId &&
        req.sourceSubcategoryId == req.targetSubcategoryId) {
      return CategoryMergeReport(
        sourceType: req.sourceSubcategoryId != null
            ? 'subcategory'
            : 'category',
        sourceCategoryName: _catName(req.sourceCategoryId),
        sourceSubcategoryName: _subcatName(req.sourceSubcategoryId),
        targetCategoryName: _catName(req.targetCategoryId),
        targetSubcategoryName: _subcatName(req.targetSubcategoryId),
        warnings: ['Source and target are the same'],
      );
    }

    // Find source category
    final sourceCatIdx = _categories.indexWhere(
      (c) => c.id == req.sourceCategoryId,
    );
    if (sourceCatIdx < 0) {
      return CategoryMergeReport(
        sourceType: req.sourceSubcategoryId != null
            ? 'subcategory'
            : 'category',
        sourceCategoryName: req.sourceCategoryId,
        targetCategoryName: _catName(req.targetCategoryId),
        warnings: ['Source category not found'],
      );
    }
    final sourceCat = _categories[sourceCatIdx];

    // Find target category
    final targetCatIdx = _categories.indexWhere(
      (c) => c.id == req.targetCategoryId,
    );
    if (targetCatIdx < 0) {
      return CategoryMergeReport(
        sourceType: req.sourceSubcategoryId != null
            ? 'subcategory'
            : 'category',
        sourceCategoryName: sourceCat.name,
        targetCategoryName: req.targetCategoryId,
        warnings: ['Target category not found'],
      );
    }
    final targetCat = _categories[targetCatIdx];

    if (targetCat.archived) {
      return CategoryMergeReport(
        sourceType: req.sourceSubcategoryId != null
            ? 'subcategory'
            : 'category',
        sourceCategoryName: sourceCat.name,
        sourceSubcategoryName: _subcatName(req.sourceSubcategoryId),
        targetCategoryName: targetCat.name,
        targetSubcategoryName: _subcatName(req.targetSubcategoryId),
        warnings: ['Target category is archived'],
      );
    }

    // Resolve target subcategory
    String? resolvedTargetSubcategoryId = req.targetSubcategoryId;
    bool targetSubcatCreated = false;

    if (req.createTargetSubcategoryName != null &&
        req.createTargetSubcategoryName!.trim().isNotEmpty) {
      final subName = req.createTargetSubcategoryName!.trim();
      Subcategory? existing;
      try {
        existing = _subcategories.firstWhere(
          (s) =>
              s.categoryId == req.targetCategoryId &&
              s.name == subName &&
              !s.archived,
        );
      } catch (_) {}
      if (existing != null) {
        resolvedTargetSubcategoryId = existing.id;
      } else {
        final newSub = Subcategory(
          id: 'sub_${DateTime.now().microsecondsSinceEpoch.toString()}',
          categoryId: req.targetCategoryId,
          name: subName,
          createdAt: DateTime.now(),
        );
        _subcategories.add(newSub);
        if (_sqlite != null) {
          _sqlite.insertSubcategory(newSub);
        }
        resolvedTargetSubcategoryId = newSub.id;
        targetSubcatCreated = true;
      }
    } else if (resolvedTargetSubcategoryId != null) {
      // Validate target subcategory is active
      try {
        final ts = _subcategories.firstWhere(
          (s) => s.id == resolvedTargetSubcategoryId,
        );
        if (ts.archived) {
          warnings.add('Target subcategory is archived');
        }
      } catch (_) {
        warnings.add('Target subcategory not found');
        resolvedTargetSubcategoryId = null;
      }
    }

    final isSubcategoryMerge = req.sourceSubcategoryId != null;

    // ── Handle child subcategories FIRST ──
    int childMoved = 0;
    int childMerged = 0;
    int childArchived = 0;
    int childKept = 0;
    final childDetails = <ChildSubcategoryReportEntry>[];
    final handledChildSubIds = <String>{};
    final childMergeTargetMap = <String, String>{};

    if (!isSubcategoryMerge && req.childSubcategoryActions != null) {
      for (final act in req.childSubcategoryActions!) {
        final subIdx = _subcategories.indexWhere(
          (s) => s.id == act.subcategoryId,
        );
        if (subIdx < 0) {
          warnings.add('Child subcategory ${act.subcategoryId} not found');
          continue;
        }
        final childSub = _subcategories[subIdx];
        switch (act.action) {
          case 'move':
            _subcategories[subIdx] = Subcategory(
              id: childSub.id,
              categoryId: req.targetCategoryId,
              name: childSub.name,
              archived: childSub.archived,
              createdAt: childSub.createdAt,
              updatedAt: DateTime.now(),
            );
            if (_sqlite != null)
              _sqlite.updateSubcategory(_subcategories[subIdx]);
            childMoved++;
            handledChildSubIds.add(childSub.id);
            childDetails.add(
              ChildSubcategoryReportEntry(
                subcategoryName: childSub.name,
                action: 'move',
                archived: false,
              ),
            );

          case 'merge':
            String? resolvedId;
            if (act.createTargetSubcategoryName != null &&
                act.createTargetSubcategoryName!.trim().isNotEmpty) {
              final subName = act.createTargetSubcategoryName!.trim();
              Subcategory? existing;
              try {
                existing = _subcategories.firstWhere(
                  (s) =>
                      s.categoryId == req.targetCategoryId &&
                      s.name == subName &&
                      !s.archived,
                );
              } catch (_) {}
              if (existing != null) {
                resolvedId = existing.id;
              } else {
                resolvedId =
                    'sub_${DateTime.now().microsecondsSinceEpoch.toString()}';
                _subcategories.add(
                  Subcategory(
                    id: resolvedId,
                    categoryId: req.targetCategoryId,
                    name: subName,
                    createdAt: DateTime.now(),
                  ),
                );
                if (_sqlite != null)
                  _sqlite.insertSubcategory(_subcategories.last);
              }
            } else if (act.targetSubcategoryId != null) {
              resolvedId = act.targetSubcategoryId;
              try {
                final ts = _subcategories.firstWhere((s) => s.id == resolvedId);
                if (ts.archived)
                  warnings.add(
                    'Target child subcategory ${ts.name} is archived',
                  );
              } catch (_) {
                warnings.add('Target child subcategory not found');
                resolvedId = null;
              }
            }
            if (resolvedId != null) {
              childMergeTargetMap[childSub.id] = resolvedId;
              handledChildSubIds.add(childSub.id);
              childMerged++;
              childDetails.add(
                ChildSubcategoryReportEntry(
                  subcategoryName: childSub.name,
                  action: 'merge',
                  archived: true,
                ),
              );
            } else {
              warnings.add(
                'Could not resolve target for child subcategory ${childSub.name}',
              );
              childKept++;
              childDetails.add(
                ChildSubcategoryReportEntry(
                  subcategoryName: childSub.name,
                  action: 'keep',
                  archived: false,
                ),
              );
            }

          case 'archive':
            _subcategories[subIdx] = Subcategory(
              id: childSub.id,
              categoryId: childSub.categoryId,
              name: childSub.name,
              archived: true,
              createdAt: childSub.createdAt,
              updatedAt: DateTime.now(),
            );
            if (_sqlite != null) _sqlite.archiveSubcategory(childSub.id);
            childArchived++;
            childDetails.add(
              ChildSubcategoryReportEntry(
                subcategoryName: childSub.name,
                action: 'archive',
                archived: true,
              ),
            );

          default: // 'keep'
            childKept++;
            childDetails.add(
              ChildSubcategoryReportEntry(
                subcategoryName: childSub.name,
                action: 'keep',
                archived: false,
              ),
            );
        }
      }
    }

    // ── Reassign movements for child sub 'move' and 'merge' actions ──
    int movementsUpdated = 0;
    for (var i = 0; i < _movements.length; i++) {
      final m = _movements[i];
      if (childMergeTargetMap.containsKey(m.subcategoryId)) {
        // 'merge' action: redirect to target subcategory
        final targetSubId = childMergeTargetMap[m.subcategoryId]!;
        _movements[i] = Movement(
          id: m.id,
          title: m.title,
          amount: m.amount,
          type: m.type,
          date: m.date,
          categoryId: req.targetCategoryId,
          subcategoryId: targetSubId,
          accountId: m.accountId,
          destinationAccountId: m.destinationAccountId,
          note: m.note,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        );
        if (_sqlite != null) _sqlite.updateMovement(_movements[i]);
        movementsUpdated++;
      } else if (handledChildSubIds.contains(m.subcategoryId)) {
        // 'move' action: keep subcategoryId, change categoryId only
        _movements[i] = Movement(
          id: m.id,
          title: m.title,
          amount: m.amount,
          type: m.type,
          date: m.date,
          categoryId: req.targetCategoryId,
          subcategoryId: m.subcategoryId,
          accountId: m.accountId,
          destinationAccountId: m.destinationAccountId,
          note: m.note,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        );
        if (_sqlite != null) _sqlite.updateMovement(_movements[i]);
        movementsUpdated++;
      }
    }

    // ── Generic movement loop (for all other movements from source category) ──
    for (var i = 0; i < _movements.length; i++) {
      final m = _movements[i];
      if (handledChildSubIds.contains(m.subcategoryId))
        continue; // already handled above
      bool match;
      if (isSubcategoryMerge) {
        match = m.subcategoryId == req.sourceSubcategoryId;
      } else {
        match = m.categoryId == req.sourceCategoryId;
      }
      if (match) {
        _movements[i] = Movement(
          id: m.id,
          title: m.title,
          amount: m.amount,
          type: m.type,
          date: m.date,
          categoryId: req.targetCategoryId,
          subcategoryId: resolvedTargetSubcategoryId,
          accountId: m.accountId,
          destinationAccountId: m.destinationAccountId,
          note: m.note,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        );
        if (_sqlite != null) _sqlite.updateMovement(_movements[i]);
        movementsUpdated++;
      }
    }

    int quickMovementsUpdated = 0;
    int favoriteMovementsUpdated = 0;

    // Child sub quick/favorite: 'move'
    if (!isSubcategoryMerge && req.childSubcategoryActions != null) {
      for (final act in req.childSubcategoryActions!) {
        if (act.action == 'move') {
          for (var i = 0; i < _quickMovements.length; i++) {
            if (_quickMovements[i].subcategoryId == act.subcategoryId) {
              _quickMovements[i] = QuickMovement(
                id: _quickMovements[i].id,
                title: _quickMovements[i].title,
                amount: _quickMovements[i].amount,
                type: _quickMovements[i].type,
                categoryId: req.targetCategoryId,
                subcategoryId: act.subcategoryId,
                accountId: _quickMovements[i].accountId,
                note: _quickMovements[i].note,
              );
              if (_sqlite != null)
                _sqlite.updateQuickMovement(
                  _quickMovements[i].id,
                  _quickMovements[i],
                );
              quickMovementsUpdated++;
            }
          }
          for (var i = 0; i < _favoriteMovements.length; i++) {
            if (_favoriteMovements[i].subcategoryId == act.subcategoryId) {
              _favoriteMovements[i] = FavoriteMovement(
                id: _favoriteMovements[i].id,
                title: _favoriteMovements[i].title,
                amount: _favoriteMovements[i].amount,
                type: _favoriteMovements[i].type,
                categoryId: req.targetCategoryId,
                subcategoryId: act.subcategoryId,
                accountId: _favoriteMovements[i].accountId,
                note: _favoriteMovements[i].note,
              );
              if (_sqlite != null)
                _sqlite.updateFavoriteMovement(_favoriteMovements[i]);
              favoriteMovementsUpdated++;
            }
          }
        }
        // 'merge': use childMergeTargetMap
        if (act.action == 'merge' &&
            childMergeTargetMap.containsKey(act.subcategoryId)) {
          final targetSubId = childMergeTargetMap[act.subcategoryId]!;
          for (var i = 0; i < _quickMovements.length; i++) {
            if (_quickMovements[i].subcategoryId == act.subcategoryId) {
              _quickMovements[i] = QuickMovement(
                id: _quickMovements[i].id,
                title: _quickMovements[i].title,
                amount: _quickMovements[i].amount,
                type: _quickMovements[i].type,
                categoryId: req.targetCategoryId,
                subcategoryId: targetSubId,
                accountId: _quickMovements[i].accountId,
                note: _quickMovements[i].note,
              );
              if (_sqlite != null)
                _sqlite.updateQuickMovement(
                  _quickMovements[i].id,
                  _quickMovements[i],
                );
              quickMovementsUpdated++;
            }
          }
          for (var i = 0; i < _favoriteMovements.length; i++) {
            if (_favoriteMovements[i].subcategoryId == act.subcategoryId) {
              _favoriteMovements[i] = FavoriteMovement(
                id: _favoriteMovements[i].id,
                title: _favoriteMovements[i].title,
                amount: _favoriteMovements[i].amount,
                type: _favoriteMovements[i].type,
                categoryId: req.targetCategoryId,
                subcategoryId: targetSubId,
                accountId: _favoriteMovements[i].accountId,
                note: _favoriteMovements[i].note,
              );
              if (_sqlite != null)
                _sqlite.updateFavoriteMovement(_favoriteMovements[i]);
              favoriteMovementsUpdated++;
            }
          }
          // Archive source child subcategory after merge
          final subIdx = _subcategories.indexWhere(
            (s) => s.id == act.subcategoryId,
          );
          if (subIdx >= 0) {
            final oldSub = _subcategories[subIdx];
            _subcategories[subIdx] = Subcategory(
              id: oldSub.id,
              categoryId: oldSub.categoryId,
              name: oldSub.name,
              archived: true,
              createdAt: oldSub.createdAt,
              updatedAt: DateTime.now(),
            );
            if (_sqlite != null) _sqlite.archiveSubcategory(oldSub.id);
          }
        }
      }
    }

    // Generic quick/favorite loop
    for (var i = 0; i < _quickMovements.length; i++) {
      final qm = _quickMovements[i];
      if (handledChildSubIds.contains(qm.subcategoryId)) continue;
      bool match;
      if (isSubcategoryMerge) {
        match = qm.subcategoryId == req.sourceSubcategoryId;
      } else {
        match = qm.categoryId == req.sourceCategoryId;
      }
      if (match) {
        _quickMovements[i] = QuickMovement(
          id: qm.id,
          title: qm.title,
          amount: qm.amount,
          type: qm.type,
          categoryId: req.targetCategoryId,
          subcategoryId: resolvedTargetSubcategoryId,
          accountId: qm.accountId,
          note: qm.note,
        );
        if (_sqlite != null)
          _sqlite.updateQuickMovement(qm.id, _quickMovements[i]);
        quickMovementsUpdated++;
      }
    }

    for (var i = 0; i < _favoriteMovements.length; i++) {
      final fm = _favoriteMovements[i];
      if (handledChildSubIds.contains(fm.subcategoryId)) continue;
      bool match;
      if (isSubcategoryMerge) {
        match = fm.subcategoryId == req.sourceSubcategoryId;
      } else {
        match = fm.categoryId == req.sourceCategoryId;
      }
      if (match) {
        _favoriteMovements[i] = FavoriteMovement(
          id: fm.id,
          title: fm.title,
          amount: fm.amount,
          type: fm.type,
          categoryId: req.targetCategoryId,
          subcategoryId: resolvedTargetSubcategoryId,
          accountId: fm.accountId,
          note: fm.note,
        );
        if (_sqlite != null)
          _sqlite.updateFavoriteMovement(_favoriteMovements[i]);
        favoriteMovementsUpdated++;
      }
    }

    // ── Archive source ──
    bool sourceCatArchived = false;
    bool sourceSubcatArchived = false;
    bool emptySourceCatArchived = false;

    if (req.archiveSource) {
      if (isSubcategoryMerge) {
        final subIdx = _subcategories.indexWhere(
          (s) => s.id == req.sourceSubcategoryId,
        );
        if (subIdx >= 0) {
          final old = _subcategories[subIdx];
          _subcategories[subIdx] = Subcategory(
            id: old.id,
            categoryId: old.categoryId,
            name: old.name,
            archived: true,
            createdAt: old.createdAt,
            updatedAt: DateTime.now(),
          );
          if (_sqlite != null) {
            _sqlite.archiveSubcategory(old.id);
          }
          sourceSubcatArchived = true;

          // Optionally archive empty source category
          if (req.archiveEmptySourceCategory && !sourceCat.archived) {
            final remainingSubs = _subcategories.any(
              (s) => s.categoryId == req.sourceCategoryId && !s.archived,
            );
            final remainingMovements = _movements.any(
              (m) => m.categoryId == req.sourceCategoryId,
            );
            if (!remainingSubs && !remainingMovements) {
              _categories[sourceCatIdx] = Category(
                id: sourceCat.id,
                name: sourceCat.name,
                type: sourceCat.type,
                color: sourceCat.color,
                iconKey: sourceCat.iconKey,
                archived: true,
              );
              if (_sqlite != null) {
                _sqlite.updateCategory(_categories[sourceCatIdx]);
              }
              emptySourceCatArchived = true;
            }
          }
        }
      } else {
        if (!sourceCat.archived) {
          _categories[sourceCatIdx] = Category(
            id: sourceCat.id,
            name: sourceCat.name,
            type: sourceCat.type,
            color: sourceCat.color,
            iconKey: sourceCat.iconKey,
            archived: true,
          );
          if (_sqlite != null) {
            _sqlite.updateCategory(_categories[sourceCatIdx]);
          }
          sourceCatArchived = true;
        }
      }
    }

    notify();

    return CategoryMergeReport(
      sourceType: isSubcategoryMerge ? 'subcategory' : 'category',
      sourceCategoryName: sourceCat.name,
      sourceSubcategoryName: isSubcategoryMerge
          ? _subcatName(req.sourceSubcategoryId)
          : null,
      targetCategoryName: targetCat.name,
      targetSubcategoryName: _subcatName(resolvedTargetSubcategoryId),
      targetSubcategoryCreated: targetSubcatCreated,
      movementsUpdated: movementsUpdated,
      quickMovementsUpdated: quickMovementsUpdated,
      favoriteMovementsUpdated: favoriteMovementsUpdated,
      sourceCategoryArchived: sourceCatArchived,
      sourceSubcategoryArchived: sourceSubcatArchived,
      emptySourceCategoryArchived: emptySourceCatArchived,
      childSubcategoriesMoved: childMoved,
      childSubcategoriesMerged: childMerged,
      childSubcategoriesArchived: childArchived,
      childSubcategoriesKept: childKept,
      childSubcategoryDetails: childDetails,
      warnings: warnings,
    );
  }

  String _catName(String? id) {
    if (id == null) return '';
    try {
      return _categories.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return id;
    }
  }

  String _subcatName(String? id) {
    if (id == null) return '';
    try {
      return _subcategories.firstWhere((s) => s.id == id).name;
    } catch (_) {
      return id;
    }
  }
}
