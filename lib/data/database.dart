import 'dart:async';
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
    _movements.addAll(await _sqlite.loadMovements());
    _quickMovements = await _sqlite.loadQuickMovements();
    _favoriteMovements.addAll(await _sqlite.loadFavoriteMovements());
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

  Account getAccount(String id) {
    return _accounts.firstWhere((a) => a.id == id);
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

  void addMovement(Movement movement) {
    _movements.add(movement);
    if (_sqlite != null) {
      unawaited(_sqlite.insertMovement(movement));
    }
    notifyListeners();
  }

  void deleteMovement(String id) {
    _movements.removeWhere((m) => m.id == id);
    if (_sqlite != null) {
      unawaited(_sqlite.deleteMovement(id));
    }
    notifyListeners();
  }

  void updateMovement(Movement updated) {
    final index = _movements.indexWhere((m) => m.id == updated.id);
    if (index >= 0) {
      _movements[index] = updated;
      if (_sqlite != null) {
        unawaited(_sqlite.updateMovement(updated));
      }
      notifyListeners();
    }
  }

  void addQuickMovement(QuickMovement qm) {
    _quickMovements.add(qm);
    if (_sqlite != null) {
      unawaited(_sqlite.insertQuickMovement(qm));
    }
    notifyListeners();
  }

  void updateQuickMovement(String id, QuickMovement updated) {
    final index = _quickMovements.indexWhere((q) => q.id == id);
    if (index >= 0) {
      _quickMovements[index] = updated;
      if (_sqlite != null) {
        unawaited(_sqlite.updateQuickMovement(id, updated));
      }
      notifyListeners();
    }
  }

  void deleteQuickMovement(String id) {
    _quickMovements.removeWhere((q) => q.id == id);
    if (_sqlite != null) {
      unawaited(_sqlite.deleteQuickMovement(id));
    }
    notifyListeners();
  }

  void addFavoriteMovement(FavoriteMovement fm) {
    _favoriteMovements.add(fm);
    if (_sqlite != null) {
      unawaited(_sqlite.insertFavoriteMovement(fm));
    }
    notifyListeners();
  }

  void deleteFavoriteMovement(String id) {
    _favoriteMovements.removeWhere((f) => f.id == id);
    if (_sqlite != null) {
      unawaited(_sqlite.deleteFavoriteMovement(id));
    }
    notifyListeners();
  }

  void duplicateMovement(Movement m) {
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
    _movements.add(clone);
    if (_sqlite != null) {
      unawaited(_sqlite.insertMovement(clone));
    }
    notifyListeners();
  }

  void saveMovementAsFavorite(Movement m) {
    final fav = FavoriteMovement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: m.title,
      amount: m.amount,
      type: m.type,
      categoryId: m.categoryId,
      accountId: m.accountId,
      note: m.note,
    );
    _favoriteMovements.add(fav);
    if (_sqlite != null) {
      unawaited(_sqlite.insertFavoriteMovement(fav));
    }
    notifyListeners();
  }

  Movement createMovementFromTemplate({
    required String title,
    required double amount,
    required MovementType type,
    required String categoryId,
    String? note,
    String? accountId,
    DateTime? date,
  }) {
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
    _movements.add(movement);
    if (_sqlite != null) {
      unawaited(_sqlite.insertMovement(movement));
    }
    notifyListeners();
    return movement;
  }

  // ── Categories CRUD ──

  bool categoryHasMovements(String categoryId) {
    return _movements.any((m) => m.categoryId == categoryId);
  }

  List<Category> get activeCategories =>
      _categories.where((c) => !c.archived).toList();

  void addCategory(String name, MovementType type, int color, {String iconKey = StreamIconLibrary.defaultCategoryIcon}) {
    final id = 'cat_${DateTime.now().microsecondsSinceEpoch.toString()}';
    final c = Category(id: id, name: name, type: type, color: color, iconKey: iconKey);
    _categories.add(c);
    if (_sqlite != null) {
      unawaited(_sqlite.insertCategory(c));
    }
    notifyListeners();
  }

  void updateCategory(String id, String name, int color, {bool? archived, MovementType? type, String? iconKey}) {
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
    _categories[index] = updated;
    if (_sqlite != null) {
      unawaited(_sqlite.updateCategory(updated));
    }
    notifyListeners();
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    if (_sqlite != null) {
      unawaited(_sqlite.deleteCategory(id));
    }
    notifyListeners();
  }

  void archiveCategory(String id) {
    updateCategory(id, _categories.firstWhere((c) => c.id == id).name,
        _categories.firstWhere((c) => c.id == id).color, archived: true);
  }

  void restoreCategory(String id) {
    updateCategory(id, _categories.firstWhere((c) => c.id == id).name,
        _categories.firstWhere((c) => c.id == id).color, archived: false);
  }

  // ── Accounts ──

  void addAccount(Account a) {
    _accounts.add(a);
    if (_sqlite != null) {
      unawaited(_sqlite.insertAccount(a));
    }
    notifyListeners();
  }

  void archiveAccount(String id) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index >= 0) {
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
      if (_sqlite != null) {
        unawaited(_sqlite.archiveAccount(id));
      }
      notifyListeners();
    }
  }

  void updateAccount(String id, String name, AccountType type, double initialBalance, {String? iconKey, int? color}) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _accounts[index] = Account(
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
        unawaited(_sqlite.updateAccount(id, _accounts[index]));
      }
      notifyListeners();
    }
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

  void reloadFromDb() {
    if (_sqlite == null) return;
    _sqlite.loadMovements().then((movements) {
      _movements
        ..clear()
        ..addAll(movements);
      return _sqlite.loadCategories();
    }).then((categories) {
      _categories = categories;
      return _sqlite.loadQuickMovements();
    }).then((quickMovements) {
      _quickMovements = quickMovements;
      return _sqlite.loadFavoriteMovements();
    }).then((favoriteMovements) {
      _favoriteMovements
        ..clear()
        ..addAll(favoriteMovements);
      return _sqlite.loadAccounts();
    }).then((accounts) {
      _accounts = accounts;
      notifyListeners();
    });
  }
}
