import '../design/stream_icon_library.dart';
import 'account.dart';
import 'beneficiary_profile.dart';
import 'category.dart';
import 'subcategory.dart';
import 'movement.dart';
import 'quick_movement.dart';
import 'favorite_movement.dart';

class BackupSettings {
  final bool showNotes;
  final String? chartStyle;
  final String? kpiStyle;
  final List<String> hiddenChartIds;
  final List<String>? netWorthAccountIds;
  final List<String>? movementsAccountFilterIds;
  final List<String>? movementsCategoryFilterIds;
  final List<String>? chartsAccountFilterIds;
  final List<String>? chartsCategoryFilterIds;
  final List<String>? categoriesFilterAccountIds;
  final List<String>? accountsFilterCategoryIds;
  final List<String>? beneficiariesFilterAccountIds;
  final List<String>? beneficiariesFilterCategoryIds;
  final String? categoryLayout;
  const BackupSettings({
    required this.showNotes,
    this.chartStyle,
    this.kpiStyle,
    this.hiddenChartIds = const [],
    this.netWorthAccountIds,
    this.movementsAccountFilterIds,
    this.movementsCategoryFilterIds,
    this.chartsAccountFilterIds,
    this.chartsCategoryFilterIds,
    this.categoriesFilterAccountIds,
    this.accountsFilterCategoryIds,
    this.beneficiariesFilterAccountIds,
    this.beneficiariesFilterCategoryIds,
    this.categoryLayout,
  });

  Map<String, dynamic> toJson() => {
    'showNotes': showNotes,
    if (chartStyle != null) 'chartStyle': chartStyle,
    if (kpiStyle != null) 'kpiStyle': kpiStyle,
    if (hiddenChartIds.isNotEmpty) 'hiddenChartIds': hiddenChartIds,
    if (netWorthAccountIds != null) 'netWorthAccountIds': netWorthAccountIds,
    if (movementsAccountFilterIds != null)
      'movementsAccountFilterIds': movementsAccountFilterIds,
    if (movementsCategoryFilterIds != null)
      'movementsCategoryFilterIds': movementsCategoryFilterIds,
    if (chartsAccountFilterIds != null)
      'chartsAccountFilterIds': chartsAccountFilterIds,
    if (chartsCategoryFilterIds != null)
      'chartsCategoryFilterIds': chartsCategoryFilterIds,
    if (categoriesFilterAccountIds != null)
      'categoriesFilterAccountIds': categoriesFilterAccountIds,
    if (accountsFilterCategoryIds != null)
      'accountsFilterCategoryIds': accountsFilterCategoryIds,
    if (beneficiariesFilterAccountIds != null)
      'beneficiariesFilterAccountIds': beneficiariesFilterAccountIds,
    if (beneficiariesFilterCategoryIds != null)
      'beneficiariesFilterCategoryIds': beneficiariesFilterCategoryIds,
    if (categoryLayout != null) 'categoryLayout': categoryLayout,
  };

  static BackupSettings fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      showNotes: json['showNotes'] as bool? ?? false,
      chartStyle: json['chartStyle'] as String?,
      kpiStyle: json['kpiStyle'] as String?,
      hiddenChartIds:
          (json['hiddenChartIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      netWorthAccountIds: (json['netWorthAccountIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      movementsAccountFilterIds:
          (json['movementsAccountFilterIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      movementsCategoryFilterIds:
          (json['movementsCategoryFilterIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      chartsAccountFilterIds: (json['chartsAccountFilterIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      chartsCategoryFilterIds:
          (json['chartsCategoryFilterIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      categoriesFilterAccountIds:
          (json['categoriesFilterAccountIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      accountsFilterCategoryIds:
          (json['accountsFilterCategoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      beneficiariesFilterAccountIds:
          (json['beneficiariesFilterAccountIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      beneficiariesFilterCategoryIds:
          (json['beneficiariesFilterCategoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      categoryLayout: json['categoryLayout'] as String?,
    );
  }
}

class BackupData {
  final int version;
  final String createdAt;
  final List<Account> accounts;
  final List<BeneficiaryProfile> beneficiaryProfiles;
  final List<Category> categories;
  final List<Subcategory> subcategories;
  final List<Movement> movements;
  final List<QuickMovement> quickMovements;
  final List<FavoriteMovement> favoriteMovements;
  final BackupSettings? settings;

  const BackupData({
    required this.version,
    required this.createdAt,
    required this.accounts,
    this.beneficiaryProfiles = const [],
    required this.categories,
    this.subcategories = const [],
    required this.movements,
    this.quickMovements = const [],
    this.favoriteMovements = const [],
    this.settings,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt,
    'accounts': accounts.map((a) => _accountToMap(a)).toList(),
    'beneficiaryProfiles': beneficiaryProfiles
        .map((b) => _beneficiaryToMap(b))
        .toList(),
    'categories': categories.map((c) => _categoryToMap(c)).toList(),
    'subcategories': subcategories.map((s) => _subcategoryToMap(s)).toList(),
    'movements': movements.map((m) => _movementToMap(m)).toList(),
    'quickMovements': quickMovements
        .map((q) => _quickMovementToMap(q))
        .toList(),
    'favoriteMovements': favoriteMovements
        .map((f) => _favoriteMovementToMap(f))
        .toList(),
    'settings': settings?.toJson(),
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int,
      createdAt: json['createdAt'] as String? ?? '',
      accounts:
          (json['accounts'] as List<dynamic>?)
              ?.map((e) => _accountFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      beneficiaryProfiles:
          (json['beneficiaryProfiles'] as List<dynamic>?)
              ?.map((e) => _beneficiaryFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => _categoryFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      subcategories:
          (json['subcategories'] as List<dynamic>?)
              ?.map((e) => _subcategoryFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      movements:
          (json['movements'] as List<dynamic>?)
              ?.map((e) => _movementFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      quickMovements:
          (json['quickMovements'] as List<dynamic>?)
              ?.map((e) => _quickMovementFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      favoriteMovements:
          (json['favoriteMovements'] as List<dynamic>?)
              ?.map((e) => _favoriteMovementFromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      settings: json['settings'] != null
          ? BackupSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : null,
    );
  }

  static Map<String, dynamic> _accountToMap(Account a) => {
    'id': a.id,
    'name': a.name,
    'type': a.type.name,
    'initialBalance': a.initialBalance,
    'iconKey': a.iconKey,
    'color': a.color,
    'archived': a.archived,
    'createdAt': a.createdAt.toIso8601String(),
    'updatedAt': a.updatedAt.toIso8601String(),
  };

  static DateTime _parseDateSafe(dynamic value, {required DateTime fallback}) {
    if (value is! String || value.isEmpty) return fallback;
    final parsed = DateTime.tryParse(value);
    if (parsed != null && parsed.isAfter(DateTime(2000))) return parsed;
    return fallback;
  }

  static Account _accountFromMap(Map<String, dynamic> m) => Account(
    id: m['id'] as String,
    name: m['name'] as String,
    type: AccountType.values.byName(m['type'] as String),
    initialBalance: (m['initialBalance'] as num?)?.toDouble() ?? 0.0,
    iconKey: m['iconKey'] as String? ?? StreamIconLibrary.defaultAccountIcon,
    color: m['color'] as int? ?? StreamColorPalette.defaultColor,
    archived: m['archived'] as bool? ?? false,
    createdAt: _parseDateSafe(m['createdAt'], fallback: DateTime(2020, 1, 1)),
    updatedAt: m['updatedAt'] != null
        ? _parseDateSafe(m['updatedAt'], fallback: DateTime(2020, 1, 1))
        : null,
  );

  static Map<String, dynamic> _beneficiaryToMap(BeneficiaryProfile b) => {
    'id': b.id,
    'key': b.key,
    'displayName': b.displayName,
    'iconKey': b.iconKey,
    'color': b.color,
    'archived': b.archived,
    'createdAt': b.createdAt.toIso8601String(),
    'updatedAt': b.updatedAt?.toIso8601String(),
  };

  static BeneficiaryProfile _beneficiaryFromMap(
    Map<String, dynamic> m,
  ) => BeneficiaryProfile(
    id: m['id'] as String,
    key: m['key'] as String,
    displayName: m['displayName'] as String,
    iconKey: m['iconKey'] as String? ?? StreamIconLibrary.defaultCategoryIcon,
    color: m['color'] as int? ?? StreamColorPalette.defaultColor,
    archived: m['archived'] as bool? ?? false,
    createdAt: _parseDateSafe(m['createdAt'], fallback: DateTime(2020, 1, 1)),
    updatedAt: m['updatedAt'] != null
        ? _parseDateSafe(m['updatedAt'], fallback: DateTime(2020, 1, 1))
        : null,
  );

  static Map<String, dynamic> _subcategoryToMap(Subcategory s) => {
    'id': s.id,
    'categoryId': s.categoryId,
    'name': s.name,
    'iconKey': s.iconKey,
    'color': s.color,
    'archived': s.archived,
  };

  static Subcategory _subcategoryFromMap(Map<String, dynamic> m) => Subcategory(
    id: m['id'] as String,
    categoryId: m['categoryId'] as String,
    name: m['name'] as String,
    iconKey: m['iconKey'] as String?,
    color: m['color'] as int?,
    archived: m['archived'] as bool? ?? false,
    createdAt: _parseDateSafe(m['createdAt'], fallback: DateTime(2020, 1, 1)),
    updatedAt: m['updatedAt'] != null
        ? _parseDateSafe(m['updatedAt'], fallback: DateTime(2020, 1, 1))
        : null,
  );

  static Map<String, dynamic> _categoryToMap(Category c) => {
    'id': c.id,
    'name': c.name,
    'type': c.type.name,
    'color': c.color,
    'iconKey': c.iconKey,
    'archived': c.archived,
  };

  static Category _categoryFromMap(Map<String, dynamic> m) => Category(
    id: m['id'] as String,
    name: m['name'] as String,
    type: MovementType.values.byName(m['type'] as String),
    color: m['color'] as int? ?? StreamColorPalette.defaultColor,
    iconKey: m['iconKey'] as String? ?? StreamIconLibrary.defaultCategoryIcon,
    archived: m['archived'] as bool? ?? false,
  );

  static Map<String, dynamic> _movementToMap(Movement m) => {
    'id': m.id,
    'title': m.title,
    'amount': m.amount,
    'type': m.type.name,
    'date': m.date.toIso8601String(),
    'categoryId': m.categoryId,
    'subcategoryId': m.subcategoryId,
    'accountId': m.accountId,
    'destinationAccountId': m.destinationAccountId,
    'note': m.note,
    'payee': m.payee,
    'createdAt': m.createdAt.toIso8601String(),
    'updatedAt': m.updatedAt.toIso8601String(),
  };

  static Movement _movementFromMap(Map<String, dynamic> m) => Movement(
    id: m['id'] as String,
    title: m['title'] as String,
    amount: (m['amount'] as num).toDouble(),
    type: MovementType.values.byName(m['type'] as String),
    date: _parseDateSafe(
      m['date'],
      fallback: _parseDateSafe(m['createdAt'], fallback: DateTime(2020, 1, 1)),
    ),
    categoryId: m['categoryId'] as String,
    subcategoryId: m['subcategoryId'] as String?,
    accountId: m['accountId'] as String?,
    destinationAccountId: m['destinationAccountId'] as String?,
    note: m['note'] as String?,
    payee: m['payee'] as String?,
    createdAt: _parseDateSafe(m['createdAt'], fallback: DateTime(2020, 1, 1)),
    updatedAt: m['updatedAt'] != null
        ? _parseDateSafe(m['updatedAt'], fallback: DateTime(2020, 1, 1))
        : null,
  );

  static Map<String, dynamic> _quickMovementToMap(QuickMovement q) => {
    'id': q.id,
    'title': q.title,
    'amount': q.amount,
    'type': q.type.name,
    'categoryId': q.categoryId,
    'subcategoryId': q.subcategoryId,
    'accountId': q.accountId,
    'note': q.note,
  };

  static QuickMovement _quickMovementFromMap(Map<String, dynamic> m) =>
      QuickMovement(
        id: m['id'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: MovementType.values.byName(m['type'] as String),
        categoryId: m['categoryId'] as String,
        subcategoryId: m['subcategoryId'] as String?,
        accountId: m['accountId'] as String? ?? defaultAccountId,
        note: m['note'] as String?,
      );

  static Map<String, dynamic> _favoriteMovementToMap(FavoriteMovement f) => {
    'id': f.id,
    'title': f.title,
    'amount': f.amount,
    'type': f.type.name,
    'categoryId': f.categoryId,
    'subcategoryId': f.subcategoryId,
    'accountId': f.accountId,
    'note': f.note,
  };

  static FavoriteMovement _favoriteMovementFromMap(Map<String, dynamic> m) =>
      FavoriteMovement(
        id: m['id'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: MovementType.values.byName(m['type'] as String),
        categoryId: m['categoryId'] as String,
        subcategoryId: m['subcategoryId'] as String?,
        accountId: m['accountId'] as String? ?? defaultAccountId,
        note: m['note'] as String?,
      );
}
