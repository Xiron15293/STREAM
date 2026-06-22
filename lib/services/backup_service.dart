import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../data/database.dart';
import '../data/categories_data.dart';
import '../data/preferences_service.dart';
import '../design/stream_icon_library.dart';
import '../models/account.dart';
import '../models/backup_data.dart';
import '../models/beneficiary_profile.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/favorite_movement.dart';
import '../models/movement.dart';
import '../models/quick_movement.dart';

class ValidationResult {
  final bool isValid;
  final String? error;
  final BackupData? data;

  const ValidationResult._({required this.isValid, this.error, this.data});

  factory ValidationResult.valid(BackupData data) =>
      ValidationResult._(isValid: true, data: data);

  factory ValidationResult.invalid(String error) =>
      ValidationResult._(isValid: false, error: error);
}

class BackupService {
  static const int currentVersion = 2;

  static String? _resolveProfileId({
    String? activeProfileId,
    String? profileId,
  }) {
    final candidate = activeProfileId ?? profileId;
    if (candidate == null) return null;
    final trimmed = candidate.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<String> _backupDirPath() async {
    try {
      final dir = Directory(p.join(await getDatabasesPath(), 'backups'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (_) {
      final dir = Directory(
        p.join(Directory.systemTemp.path, 'stream_backups'),
      );
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
  }

  static Future<String> exportToJson(
    AppDatabase db, {
    String? activeProfileId,
    String? profileId,
  }) async {
    final showNotes = await PreferencesService.loadShowNotes();
    final chartStyle = await PreferencesService.loadChartStyleId();
    final kpiStyle = await PreferencesService.loadKpiStyleId();
    final hiddenChartIds = await PreferencesService.loadHiddenChartIds();
    final resolvedProfileId = _resolveProfileId(
      activeProfileId: activeProfileId,
      profileId: profileId,
    );
    final netWorthAccountIds = resolvedProfileId == null
        ? null
        : await PreferencesService.loadDashboardNetWorthAccountIds(
            profileId: resolvedProfileId,
          );
    final chartsAccountFilterIds = resolvedProfileId == null
        ? null
        : await PreferencesService.loadChartsAccountFilterIds(
            profileId: resolvedProfileId,
          );
    final chartsCategoryFilterIds = resolvedProfileId == null
        ? null
        : await PreferencesService.loadChartsCategoryFilterIds(
            profileId: resolvedProfileId,
          );
    final categoriesFilterAccountIds = resolvedProfileId == null
        ? null
        : await PreferencesService.loadCategoriesAccountFilterIds(
            profileId: resolvedProfileId,
          );
    final accountsFilterCategoryIds = resolvedProfileId == null
        ? null
        : await PreferencesService.loadAccountsCategoryFilterIds(
            profileId: resolvedProfileId,
          );
    final beneficiariesFilterAccountIds = resolvedProfileId == null
        ? null
        : await PreferencesService.loadBeneficiariesAccountFilterIds(
            profileId: resolvedProfileId,
          );
    final beneficiariesFilterCategoryIds = resolvedProfileId == null
        ? null
        : await PreferencesService.loadBeneficiariesCategoryFilterIds(
            profileId: resolvedProfileId,
          );
    final categoryLayout = await PreferencesService.loadCategoryLayout();
    final data = BackupData(
      version: currentVersion,
      createdAt: DateTime.now().toIso8601String(),
      accounts: db.accounts.toList(),
      beneficiaryProfiles: db.beneficiaryProfiles.toList(),
      categories: db.categories.toList(),
      subcategories: db.subcategories.toList(),
      movements: db.movements.toList(),
      quickMovements: db.quickMovements.toList(),
      favoriteMovements: db.favoriteMovements.toList(),
      settings: BackupSettings(
        showNotes: showNotes,
        chartStyle: chartStyle != PreferencesService.defaultChartStyle
            ? chartStyle
            : null,
        kpiStyle: kpiStyle != PreferencesService.defaultKpiStyle
            ? kpiStyle
            : null,
        hiddenChartIds: hiddenChartIds.toList(),
        netWorthAccountIds: netWorthAccountIds?.toList(),
        chartsAccountFilterIds: chartsAccountFilterIds?.toList(),
        chartsCategoryFilterIds: chartsCategoryFilterIds?.toList(),
        categoriesFilterAccountIds: categoriesFilterAccountIds?.toList(),
        accountsFilterCategoryIds: accountsFilterCategoryIds?.toList(),
        beneficiariesFilterAccountIds: beneficiariesFilterAccountIds?.toList(),
        beneficiariesFilterCategoryIds: beneficiariesFilterCategoryIds
            ?.toList(),
        categoryLayout:
            categoryLayout != PreferencesService.defaultCategoryLayout
            ? categoryLayout
            : null,
      ),
    );

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data.toJson());
  }

  static Future<String> createPreResetBackup(
    AppDatabase db, {
    String? activeProfileId,
    String? profileId,
  }) async {
    final dirPath = await _backupDirPath();
    final json = await exportToJson(
      db,
      activeProfileId: activeProfileId,
      profileId: profileId,
    );
    final now = DateTime.now();
    final filename =
        'backup_pre_reset_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}.json';
    final file = File(p.join(dirPath, filename));
    await file.writeAsString(json);
    return file.path;
  }

  static ValidationResult validate(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      if (parsed is! Map<String, dynamic>) {
        return ValidationResult.invalid(
          'Formato non valido: root non è un oggetto JSON',
        );
      }

      final version = parsed['version'];
      if (version == null) {
        return ValidationResult.invalid('Campo "version" mancante');
      }
      if (version is! int) {
        return ValidationResult.invalid(
          '"version" deve essere un numero intero',
        );
      }
      if (version < 1 || version > currentVersion) {
        return ValidationResult.invalid(
          'Versione $version non supportata. Versione massima: $currentVersion',
        );
      }

      final requiredFields = ['accounts', 'categories', 'movements'];
      for (final field in requiredFields) {
        if (!parsed.containsKey(field)) {
          return ValidationResult.invalid(
            'Campo obbligatorio "$field" mancante',
          );
        }
        if (parsed[field] is! List) {
          return ValidationResult.invalid(
            'Campo "$field" deve essere una lista',
          );
        }
      }

      final deepError = _deepValidate(parsed);
      if (deepError != null) {
        return ValidationResult.invalid(deepError);
      }

      return ValidationResult.valid(BackupData.fromJson(parsed));
    } on FormatException {
      return ValidationResult.invalid('File JSON non valido: formato errato');
    } catch (e) {
      return ValidationResult.invalid('Errore di lettura: $e');
    }
  }

  static String? _fieldString(Map m, String key) {
    final v = m[key];
    if (v is! String || v.isEmpty) return null;
    return v;
  }

  static String? _deepValidate(Map<String, dynamic> parsed) {
    final validCategoryTypes = {'income', 'expense'};
    final validMovementTypes = {'income', 'expense', 'transfer'};

    // ── Validate accounts ──
    final accounts = parsed['accounts'] as List;
    for (var i = 0; i < accounts.length; i++) {
      final item = accounts[i];
      if (item is! Map) {
        return 'Conto #${i + 1}: non è un oggetto valido';
      }
      if (_fieldString(item, 'id') == null) {
        return 'Conto #${i + 1}: campo "id" mancante o vuoto';
      }
    }

    // ── Validate categories ──
    final categories = parsed['categories'] as List;
    for (var i = 0; i < categories.length; i++) {
      final item = categories[i];
      if (item is! Map) {
        return 'Categoria #${i + 1}: non è un oggetto valido';
      }
      if (_fieldString(item, 'id') == null) {
        return 'Categoria #${i + 1}: campo "id" mancante o vuoto';
      }
      if (_fieldString(item, 'type') == null ||
          !validCategoryTypes.contains(item['type'])) {
        return 'Categoria #${i + 1}: campo "type" mancante o non valido (income/expense)';
      }
    }

    // ── Validate movements ──
    final movements = parsed['movements'] as List;
    for (var i = 0; i < movements.length; i++) {
      final item = movements[i];
      if (item is! Map) {
        return 'Movimento #${i + 1}: non è un oggetto valido';
      }
      if (_fieldString(item, 'id') == null) {
        return 'Movimento #${i + 1}: campo "id" mancante o vuoto';
      }
      if (item['amount'] is! num) {
        return 'Movimento #${i + 1}: campo "amount" mancante o non numerico';
      }
      if (!validMovementTypes.contains(item['type'] as String?)) {
        return 'Movimento #${i + 1}: campo "type" mancante o non valido (income/expense/transfer)';
      }
      if (item['type'] == 'transfer' &&
          _fieldString(item, 'destinationAccountId') == null) {
        return 'Movimento #${i + 1}: campo "destinationAccountId" mancante o vuoto per un transfer';
      }
      final dateStr = item['date'] as String?;
      if (dateStr == null || dateStr.isEmpty) {
        return 'Movimento #${i + 1}: campo "date" mancante o vuoto';
      }
      try {
        DateTime.parse(dateStr);
      } catch (_) {
        return 'Movimento #${i + 1}: campo "date" non è una data valida: "$dateStr"';
      }
    }

    // ── Validate quickMovements (optional list) ──
    if (parsed['quickMovements'] is List) {
      final quickList = parsed['quickMovements'] as List;
      for (var i = 0; i < quickList.length; i++) {
        final item = quickList[i];
        if (item is! Map) {
          return 'Movimento rapido #${i + 1}: non è un oggetto valido';
        }
        if (_fieldString(item, 'id') == null) {
          return 'Movimento rapido #${i + 1}: campo "id" mancante o vuoto';
        }
        if (item['amount'] is! num) {
          return 'Movimento rapido #${i + 1}: campo "amount" mancante o non numerico';
        }
        if (!validMovementTypes.contains(item['type'] as String?)) {
          return 'Movimento rapido #${i + 1}: campo "type" mancante o non valido (income/expense/transfer)';
        }
      }
    }

    // ── Validate beneficiaryProfiles (optional list) ──
    if (parsed['beneficiaryProfiles'] is List) {
      final bpList = parsed['beneficiaryProfiles'] as List;
      for (var i = 0; i < bpList.length; i++) {
        final item = bpList[i];
        if (item is! Map) {
          return 'Beneficiario #${i + 1}: non è un oggetto valido';
        }
        if (_fieldString(item, 'id') == null) {
          return 'Beneficiario #${i + 1}: campo "id" mancante o vuoto';
        }
        if (_fieldString(item, 'key') == null) {
          return 'Beneficiario #${i + 1}: campo "key" mancante o vuoto';
        }
      }
    }

    // ── Validate favoriteMovements (optional list) ──
    if (parsed['favoriteMovements'] is List) {
      final favList = parsed['favoriteMovements'] as List;
      for (var i = 0; i < favList.length; i++) {
        final item = favList[i];
        if (item is! Map) {
          return 'Movimento preferito #${i + 1}: non è un oggetto valido';
        }
        if (_fieldString(item, 'id') == null) {
          return 'Movimento preferito #${i + 1}: campo "id" mancante o vuoto';
        }
        if (item['amount'] is! num) {
          return 'Movimento preferito #${i + 1}: campo "amount" mancante o non numerico';
        }
        if (!validMovementTypes.contains(item['type'] as String?)) {
          return 'Movimento preferito #${i + 1}: campo "type" mancante o non valido (income/expense/transfer)';
        }
      }
    }

    return null; // valid
  }

  static Future<void> restore(
    AppDatabase db,
    BackupData data, {
    String? activeProfileId,
    String? profileId,
  }) async {
    final snapshot = _buildSnapshot(data);
    final sqlite = db.sqliteService;

    try {
      if (sqlite != null) {
        await sqlite.transaction((txn) async {
          await txn.delete('beneficiary_profiles');
          await txn.delete('subcategories');
          await txn.delete('movements');
          await txn.delete('categories');
          await txn.delete('quick_movements');
          await txn.delete('favorite_movements');
          await txn.delete('accounts');

          for (final acc in snapshot.accounts) {
            await txn.insert(
              'accounts',
              _accountToRow(acc),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (final bp in snapshot.beneficiaryProfiles) {
            await txn.insert(
              'beneficiary_profiles',
              _beneficiaryToRow(bp),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (final cat in snapshot.categories) {
            await txn.insert(
              'categories',
              _categoryToRow(cat),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (final sub in snapshot.subcategories) {
            await txn.insert(
              'subcategories',
              _subcategoryToRow(sub),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (final m in snapshot.movements) {
            await txn.insert(
              'movements',
              _movementToRow(m),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (final qm in snapshot.quickMovements) {
            await txn.insert(
              'quick_movements',
              _quickMovementToRow(qm),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          for (final fm in snapshot.favoriteMovements) {
            await txn.insert(
              'favorite_movements',
              _favoriteMovementToRow(fm),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }

      db.replaceState(
        movements: snapshot.movements,
        categories: snapshot.categories,
        subcategories: snapshot.subcategories,
        quickMovements: snapshot.quickMovements,
        favoriteMovements: snapshot.favoriteMovements,
        accounts: snapshot.accounts,
        beneficiaries: snapshot.beneficiaryProfiles,
      );

      if (data.settings != null) {
        final s = data.settings!;
        await PreferencesService.saveShowNotes(s.showNotes);
        if (s.chartStyle != null) {
          await PreferencesService.saveChartStyleId(s.chartStyle!);
        }
        if (s.kpiStyle != null) {
          await PreferencesService.saveKpiStyleId(s.kpiStyle!);
        }
        if (s.hiddenChartIds.isNotEmpty) {
          await PreferencesService.saveHiddenChartIds(s.hiddenChartIds.toSet());
        }
        if (s.categoryLayout != null) {
          await PreferencesService.saveCategoryLayout(s.categoryLayout!);
        }
        final resolvedProfileId = _resolveProfileId(
          activeProfileId: activeProfileId,
          profileId: profileId,
        );
        if (resolvedProfileId != null) {
          if (s.netWorthAccountIds != null &&
              s.netWorthAccountIds!.isNotEmpty) {
            final validIds = PreferencesService.normalizeScopedFilterIds(
              s.netWorthAccountIds!.toSet(),
              snapshot.accounts
                  .where((account) => !account.archived)
                  .map((account) => account.id),
            );
            await PreferencesService.saveDashboardNetWorthAccountIds(
              validIds,
              profileId: resolvedProfileId,
            );
          } else {
            await PreferencesService.clearDashboardNetWorthAccountSelection(
              profileId: resolvedProfileId,
            );
          }

          if (s.chartsAccountFilterIds != null) {
            final validChartAccountIds =
                PreferencesService.normalizeScopedFilterIds(
                  s.chartsAccountFilterIds!.toSet(),
                  snapshot.accounts
                      .where((account) => !account.archived)
                      .map((account) => account.id),
                );
            await PreferencesService.saveChartsAccountFilterIds(
              validChartAccountIds,
              profileId: resolvedProfileId,
            );
          } else {
            await PreferencesService.saveChartsAccountFilterIds(
              null,
              profileId: resolvedProfileId,
            );
          }

          if (s.chartsCategoryFilterIds != null) {
            final validChartCategoryIds =
                PreferencesService.normalizeScopedFilterIds(
                  s.chartsCategoryFilterIds!.toSet(),
                  snapshot.categories
                      .where((category) => !category.archived)
                      .map((category) => category.id),
                );
            await PreferencesService.saveChartsCategoryFilterIds(
              validChartCategoryIds,
              profileId: resolvedProfileId,
            );
          } else {
            await PreferencesService.saveChartsCategoryFilterIds(
              null,
              profileId: resolvedProfileId,
            );
          }

          if (s.categoriesFilterAccountIds != null) {
            final validCategoryAccountIds =
                PreferencesService.normalizeScopedFilterIds(
                  s.categoriesFilterAccountIds!.toSet(),
                  snapshot.accounts
                      .where((account) => !account.archived)
                      .map((account) => account.id),
                );
            await PreferencesService.saveCategoriesAccountFilterIds(
              validCategoryAccountIds,
              profileId: resolvedProfileId,
            );
          } else {
            await PreferencesService.saveCategoriesAccountFilterIds(
              null,
              profileId: resolvedProfileId,
            );
          }

          if (s.accountsFilterCategoryIds != null) {
            final validAccountsCategoryIds =
                PreferencesService.normalizeScopedFilterIds(
                  s.accountsFilterCategoryIds!.toSet(),
                  snapshot.categories
                      .where((category) => !category.archived)
                      .map((category) => category.id),
                );
            await PreferencesService.saveAccountsCategoryFilterIds(
              validAccountsCategoryIds,
              profileId: resolvedProfileId,
            );
          } else {
            await PreferencesService.saveAccountsCategoryFilterIds(
              null,
              profileId: resolvedProfileId,
            );
          }

          if (s.beneficiariesFilterAccountIds != null) {
            final validBeneficiariesAccountIds =
                PreferencesService.normalizeScopedFilterIds(
                  s.beneficiariesFilterAccountIds!.toSet(),
                  snapshot.accounts
                      .where((account) => !account.archived)
                      .map((account) => account.id),
                );
            await PreferencesService.saveBeneficiariesAccountFilterIds(
              validBeneficiariesAccountIds,
              profileId: resolvedProfileId,
            );
          } else {
            await PreferencesService.saveBeneficiariesAccountFilterIds(
              null,
              profileId: resolvedProfileId,
            );
          }

          if (s.beneficiariesFilterCategoryIds != null) {
            final validBeneficiariesCategoryIds =
                PreferencesService.normalizeScopedFilterIds(
                  s.beneficiariesFilterCategoryIds!.toSet(),
                  snapshot.categories
                      .where((category) => !category.archived)
                      .map((category) => category.id),
                );
            await PreferencesService.saveBeneficiariesCategoryFilterIds(
              validBeneficiariesCategoryIds,
              profileId: resolvedProfileId,
            );
          } else {
            await PreferencesService.saveBeneficiariesCategoryFilterIds(
              null,
              profileId: resolvedProfileId,
            );
          }
        } else {
          PreferencesService.netWorthAccountIdsNotifier.value = null;
          PreferencesService.chartsAccountFilterIdsNotifier.value = null;
          PreferencesService.chartsCategoryFilterIdsNotifier.value = null;
          PreferencesService.categoriesAccountFilterIdsNotifier.value = null;
          PreferencesService.accountsCategoryFilterIdsNotifier.value = null;
          PreferencesService.beneficiariesAccountFilterIdsNotifier.value = null;
          PreferencesService.beneficiariesCategoryFilterIdsNotifier.value =
              null;
        }
      }

      db.notify();
    } catch (e) {
      // Recovery: reload from DB to restore consistent state
      await db.reloadFromDb();
      rethrow;
    }
  }

  static List<Category> _defaultCategories() {
    return List<Category>.from(DefaultCategories.all);
  }

  static List<QuickMovement> _defaultQuickMovements() {
    return [
      const QuickMovement(
        id: 'qm_1',
        title: 'Caffè',
        amount: 1.50,
        type: MovementType.expense,
        categoryId: 'exp_4',
      ),
      const QuickMovement(
        id: 'qm_2',
        title: 'Benzina',
        amount: 50.0,
        type: MovementType.expense,
        categoryId: 'exp_3',
      ),
      const QuickMovement(
        id: 'qm_3',
        title: 'Spesa',
        amount: 80.0,
        type: MovementType.expense,
        categoryId: 'exp_1',
      ),
      const QuickMovement(
        id: 'qm_4',
        title: 'Stipendio',
        amount: 2500.0,
        type: MovementType.income,
        categoryId: 'inc_1',
      ),
    ];
  }

  static _RestoreSnapshot _buildSnapshot(BackupData data) {
    final accountMap = <String, Account>{defaultAccountId: _defaultAccount()};
    for (final acc in data.accounts) {
      if (acc.id == defaultAccountId) continue;
      accountMap[acc.id] = acc;
    }

    final categoryMap = <String, Category>{
      for (final category in _defaultCategories()) category.id: category,
    };
    for (final cat in data.categories) {
      categoryMap[cat.id] = cat;
    }

    final subcategoryMap = <String, Subcategory>{
      for (final sub in data.subcategories) sub.id: sub,
    };

    final beneficiaryProfiles = data.beneficiaryProfiles.toList();
    final accounts = accountMap.values.toList();
    final categories = categoryMap.values.toList();
    final subcategories = subcategoryMap.values.toList();
    final quickMovementMap = <String, QuickMovement>{
      for (final quickMovement in _defaultQuickMovements())
        quickMovement.id: quickMovement,
    };
    for (final quickMovement in data.quickMovements) {
      quickMovementMap[quickMovement.id] = quickMovement;
    }
    final movements = data.movements
        .map(
          (m) => _normalizeMovement(m, accountMap, categoryMap, subcategoryMap),
        )
        .toList();
    final quickMovements = quickMovementMap.values
        .map(
          (q) => _normalizeQuickMovement(
            q,
            accountMap,
            categoryMap,
            subcategoryMap,
          ),
        )
        .toList();
    final favoriteMovements = data.favoriteMovements
        .map(
          (f) => _normalizeFavoriteMovement(
            f,
            accountMap,
            categoryMap,
            subcategoryMap,
          ),
        )
        .toList();

    return _RestoreSnapshot(
      accounts: accounts,
      beneficiaryProfiles: beneficiaryProfiles,
      categories: categories,
      subcategories: subcategories,
      movements: movements,
      quickMovements: quickMovements,
      favoriteMovements: favoriteMovements,
    );
  }

  static Account _defaultAccount() {
    return Account(
      id: defaultAccountId,
      name: 'Principale',
      type: AccountType.bank,
      iconKey: StreamIconLibrary.defaultAccountIcon,
      color: StreamColorPalette.defaultColor,
      createdAt: DateTime.now(),
    );
  }

  static Movement _normalizeMovement(
    Movement movement,
    Map<String, Account> accounts,
    Map<String, Category> categories,
    Map<String, Subcategory> subcategories,
  ) {
    final accountId = accounts.containsKey(movement.accountId)
        ? movement.accountId
        : defaultAccountId;
    final destinationAccountId =
        movement.destinationAccountId != null &&
            accounts.containsKey(movement.destinationAccountId)
        ? movement.destinationAccountId
        : (movement.type == MovementType.transfer ? defaultAccountId : null);
    final category = categories[movement.categoryId];
    final categoryId = movement.type == MovementType.transfer
        ? movement.categoryId
        : category != null && category.type == movement.type
        ? category.id
        : _defaultCategoryIdForType(movement.type);
    final subcategoryId = _normalizeSubcategoryId(
      movement.subcategoryId,
      categoryId,
      subcategories,
    );

    return movement.copyWith(
      accountId: accountId,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      destinationAccountId: destinationAccountId,
    );
  }

  static String? _normalizeSubcategoryId(
    String? subcategoryId,
    String categoryId,
    Map<String, Subcategory> subcategories,
  ) {
    if (subcategoryId == null) return null;
    final sub = subcategories[subcategoryId];
    if (sub == null) return null;
    if (sub.categoryId != categoryId) return null;
    return sub.id;
  }

  static QuickMovement _normalizeQuickMovement(
    QuickMovement quickMovement,
    Map<String, Account> accounts,
    Map<String, Category> categories,
    Map<String, Subcategory> subcategories,
  ) {
    final accountId = accounts.containsKey(quickMovement.accountId)
        ? quickMovement.accountId
        : defaultAccountId;
    final category = categories[quickMovement.categoryId];
    final categoryId = category != null && category.type == quickMovement.type
        ? category.id
        : _defaultCategoryIdForType(quickMovement.type);
    final subcategoryId = _normalizeSubcategoryId(
      quickMovement.subcategoryId,
      categoryId,
      subcategories,
    );

    return QuickMovement(
      id: quickMovement.id,
      title: quickMovement.title,
      amount: quickMovement.amount,
      type: quickMovement.type,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      accountId: accountId,
      note: quickMovement.note,
    );
  }

  static FavoriteMovement _normalizeFavoriteMovement(
    FavoriteMovement favoriteMovement,
    Map<String, Account> accounts,
    Map<String, Category> categories,
    Map<String, Subcategory> subcategories,
  ) {
    final accountId = accounts.containsKey(favoriteMovement.accountId)
        ? favoriteMovement.accountId
        : defaultAccountId;
    final category = categories[favoriteMovement.categoryId];
    final categoryId =
        category != null && category.type == favoriteMovement.type
        ? category.id
        : _defaultCategoryIdForType(favoriteMovement.type);
    final subcategoryId = _normalizeSubcategoryId(
      favoriteMovement.subcategoryId,
      categoryId,
      subcategories,
    );

    return FavoriteMovement(
      id: favoriteMovement.id,
      title: favoriteMovement.title,
      amount: favoriteMovement.amount,
      type: favoriteMovement.type,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      accountId: accountId,
      note: favoriteMovement.note,
    );
  }

  static String _defaultCategoryIdForType(MovementType type) {
    return type == MovementType.income ? 'inc_1' : 'exp_1';
  }

  static Map<String, dynamic> _subcategoryToRow(Subcategory subcategory) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': subcategory.id,
      'category_id': subcategory.categoryId,
      'name': subcategory.name,
      'icon_key': subcategory.iconKey,
      'color': subcategory.color,
      'archived': subcategory.archived ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
  }

  static Map<String, dynamic> _beneficiaryToRow(BeneficiaryProfile bp) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': bp.id,
      'key': bp.key,
      'display_name': bp.displayName,
      'icon_key': bp.iconKey,
      'color': bp.color,
      'archived': bp.archived ? 1 : 0,
      'created_at': bp.createdAt.toIso8601String(),
      'updated_at': now,
    };
  }

  static Map<String, dynamic> _accountToRow(Account account) => {
    'id': account.id,
    'name': account.name,
    'type': account.type.name,
    'initial_balance': account.initialBalance,
    'icon_key': account.iconKey,
    'color': account.color,
    'archived': account.archived ? 1 : 0,
    'created_at': account.createdAt.toIso8601String(),
    'updated_at': account.updatedAt.toIso8601String(),
  };

  static Map<String, dynamic> _categoryToRow(Category category) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': category.id,
      'name': category.name,
      'type': category.type.name,
      'color': category.color,
      'icon_key': category.iconKey,
      'archived': category.archived ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    };
  }

  static Map<String, dynamic> _movementToRow(Movement movement) => {
    'id': movement.id,
    'title': movement.title,
    'amount': movement.amount,
    'type': movement.type.name,
    'category_id': movement.categoryId,
    'account_id': movement.accountId,
    'destination_account_id': movement.destinationAccountId,
    'date': movement.date.toIso8601String(),
    'note': movement.note,
    'created_at': movement.createdAt.toIso8601String(),
    'updated_at': movement.updatedAt.toIso8601String(),
  };

  static Map<String, dynamic> _quickMovementToRow(QuickMovement quickMovement) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': quickMovement.id,
      'title': quickMovement.title,
      'amount': quickMovement.amount,
      'type': quickMovement.type.name,
      'category_id': quickMovement.categoryId,
      'account_id': quickMovement.accountId,
      'note': quickMovement.note,
      'created_at': now,
      'updated_at': now,
    };
  }

  static Map<String, dynamic> _favoriteMovementToRow(
    FavoriteMovement favoriteMovement,
  ) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': favoriteMovement.id,
      'title': favoriteMovement.title,
      'amount': favoriteMovement.amount,
      'type': favoriteMovement.type.name,
      'category_id': favoriteMovement.categoryId,
      'account_id': favoriteMovement.accountId,
      'note': favoriteMovement.note,
      'created_at': now,
      'updated_at': now,
    };
  }
}

class _RestoreSnapshot {
  final List<Account> accounts;
  final List<BeneficiaryProfile> beneficiaryProfiles;
  final List<Category> categories;
  final List<Subcategory> subcategories;
  final List<Movement> movements;
  final List<QuickMovement> quickMovements;
  final List<FavoriteMovement> favoriteMovements;

  const _RestoreSnapshot({
    required this.accounts,
    required this.beneficiaryProfiles,
    required this.categories,
    required this.subcategories,
    required this.movements,
    required this.quickMovements,
    required this.favoriteMovements,
  });
}
