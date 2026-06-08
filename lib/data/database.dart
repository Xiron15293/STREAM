import 'package:flutter/foundation.dart' hide Category;
import '../design/stream_icon_library.dart';
import '../models/movement.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/quick_movement.dart';
import '../models/favorite_movement.dart';
import 'categories_data.dart';
import 'sqlite_service.dart';

class AppDatabase extends ChangeNotifier {
  final SQLiteService? _sqlite;
  final List<Movement> _movements = [];
  List<Category> _categories = [];
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
    final movementsSum = _movements
        .where((m) => m.accountId == a.id)
        .fold<double>(0.0, (sum, m) {
      return m.type == MovementType.income ? sum + m.amount : sum - m.amount;
    });
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
        return b.createdAt.compareTo(a.createdAt);
      });
    return sorted.take(5).toList();
  }

  double get totalIncome {
    return _movements
        .where((m) => m.type == MovementType.income)
        .fold(0.0, (sum, m) => sum + m.amount);
  }

  double get totalExpenses {
    return _movements
        .where((m) => m.type == MovementType.expense)
        .fold(0.0, (sum, m) => sum + m.amount);
  }

  double get balance => totalIncome - totalExpenses;

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
    String? note,
    String? accountId,
    DateTime? date,
  }) async {
    final movement = Movement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      type: type,
      date: date ?? DateTime.now(),
      categoryId: categoryId,
      accountId: accountId,
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

  void notify() {
    notifyListeners();
  }

  // ── Backup/Restore internal API ──

  SQLiteService? get sqliteService => _sqlite;

  void clearMemory() {
    _movements.clear();
    _categories.clear();
    _quickMovements.clear();
    _favoriteMovements.clear();
    _accounts.clear();
  }

  void replaceState({
    required List<Movement> movements,
    required List<Category> categories,
    required List<QuickMovement> quickMovements,
    required List<FavoriteMovement> favoriteMovements,
    required List<Account> accounts,
  }) {
    _movements
      ..clear()
      ..addAll(movements);
    _categories = List.from(categories);
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
