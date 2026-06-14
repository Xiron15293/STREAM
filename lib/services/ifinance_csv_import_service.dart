import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/favorite_movement.dart';
import '../models/movement.dart';
import '../models/quick_movement.dart';
import '../models/subcategory.dart';

class IFinanceCsvRow {
  final int lineNumber;
  final DateTime date;
  final double rawAmount;
  final String title;
  final String? payee;
  final String account;
  final String comment;
  final String labels;
  final String categoryRaw;
  final String categoryParent;
  final String subcategoryName;
  int occurrenceIndex;

  IFinanceCsvRow({
    required this.lineNumber,
    required this.date,
    required this.rawAmount,
    required this.title,
    this.payee,
    required this.account,
    this.comment = '',
    this.labels = '',
    required this.categoryRaw,
    this.categoryParent = '',
    this.subcategoryName = '',
    this.occurrenceIndex = 0,
  });

  bool get isExpense => rawAmount < 0;
  bool get isIncome => rawAmount > 0;
  double get amount => rawAmount.abs();
  MovementType get type => isIncome ? MovementType.income : MovementType.expense;

  bool get hasCategory => categoryRaw.isNotEmpty;

  String get note {
    final parts = <String>[];
    final c = comment.trim();
    final l = labels.trim();
    if (c.isNotEmpty) parts.add(c);
    if (l.isNotEmpty && l != c) parts.add(l);
    return parts.join('\n');
  }

  bool isLikelyTransfer() {
    final haystack = [
      title,
      payee ?? '',
      labels,
      categoryRaw,
      categoryParent,
    ].join(' ').toLowerCase();
    return haystack.contains('trasferiment');
  }
}

class IFinanceTransferPair {
  final IFinanceCsvRow negativeRow;
  final IFinanceCsvRow positiveRow;

  const IFinanceTransferPair({required this.negativeRow, required this.positiveRow});

  DateTime get date => negativeRow.date;
  double get amount => negativeRow.amount;
  String get accountSource => negativeRow.account;
  String get accountDestination => positiveRow.account;

  String get title {
    final src = negativeRow.title.isNotEmpty ? negativeRow.title : positiveRow.title;
    final payeeCandidate = negativeRow.payee ?? positiveRow.payee;
    return payeeCandidate != null && payeeCandidate.isNotEmpty
        ? '$src - $payeeCandidate'
        : src;
  }

  String get note {
    final parts = <String>[];
    void add(String? s) {
      final t = s?.trim() ?? '';
      if (t.isNotEmpty && !parts.contains(t)) parts.add(t);
    }
    add(negativeRow.comment);
    add(negativeRow.labels);
    add(positiveRow.comment);
    add(positiveRow.labels);
    return parts.join('\n');
  }
}

class IFinanceImportPreview {
  final int totalRows;
  final int duplicatesSkipped;
  final int intraFileRepeats;
  final List<IFinanceCsvRow> movements;
  final List<IFinanceTransferPair> transfers;
  final List<IFinanceCsvRow> ambiguousTransfers;
  final List<String> accountsToCreate;
  final List<String> categoriesToCreate;
  final List<CategorySubPreview> subcategoriesToCreate;
  final DateTime? dateMin;
  final DateTime? dateMax;
  final List<String> errors;

  final List<String> accountsFromMetadata;
  final int accountsFoundInCsv;
  final int accountsUsedByMovements;
  final int accountsExistingInDb;
  final List<String> metadataOnlyAccounts;
  final int transferCandidateRows;
  final int ambiguousTransferGroups;

  const IFinanceImportPreview({
    required this.totalRows,
    required this.duplicatesSkipped,
    required this.intraFileRepeats,
    required this.movements,
    required this.transfers,
    required this.ambiguousTransfers,
    required this.accountsToCreate,
    required this.categoriesToCreate,
    required this.subcategoriesToCreate,
    this.dateMin,
    this.dateMax,
    required this.errors,
    this.accountsFromMetadata = const [],
    this.accountsFoundInCsv = 0,
    this.accountsUsedByMovements = 0,
    this.accountsExistingInDb = 0,
    this.metadataOnlyAccounts = const [],
    this.transferCandidateRows = 0,
    this.ambiguousTransferGroups = 0,
  });

  int get movementsToImport => movements.length;
  int get transfersToImport => transfers.length;
  int get totalToImport => movementsToImport + transfersToImport;
  int get errorCount => errors.length;
}

class CategorySubPreview {
  final String category;
  final String subcategory;
  const CategorySubPreview({required this.category, required this.subcategory});

  String get _normalizedKey =>
      '${_normalizeKeyPart(category)}|${_normalizeKeyPart(subcategory)}';

  static String _normalizeKeyPart(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  bool operator ==(Object other) =>
      other is CategorySubPreview && other._normalizedKey == _normalizedKey;

  @override
  int get hashCode => _normalizedKey.hashCode;
}


class IFinanceImportReport {
  final int movementsImported;
  final int transfersImported;
  final int duplicatesSkipped;
  final int accountsCreated;
  final int categoriesCreated;
  final int subcategoriesCreated;
  final int errorsCount;
  final List<String> errors;

  const IFinanceImportReport({
    required this.movementsImported,
    required this.transfersImported,
    required this.duplicatesSkipped,
    required this.accountsCreated,
    required this.categoriesCreated,
    required this.subcategoriesCreated,
    required this.errorsCount,
    required this.errors,
  });
}

class IFinanceCsvImportService {
  static Future<IFinanceImportPreview> previewCsv(
    AppDatabase db,
    String csvText,
  ) async {
    final plan = _IFinanceImportPlan.fromDb(db);
    return plan.buildPreview(csvText);
  }

  static Future<IFinanceImportReport> commitImport(
    AppDatabase db,
    IFinanceImportPreview preview,
  ) async {
    final plan = _IFinanceImportPlan.fromDb(db);
    return plan.commit(db, preview);
  }
}

final RegExp _headerStartPattern = RegExp(r'^Data\s*;\s*Importo');
final RegExp _datePattern = RegExp(r'^\d{2}/\d{2}/\d{2}$');
const String _iFinanceFingerprintPrefix = 'ifinance';

List<List<String>> _parseCsvRows(String input) {
  final normalized = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final trimmed = normalized.startsWith('\uFEFF') ? normalized.substring(1) : normalized;
  final rows = <List<String>>[];
  final currentRow = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  void commitField() {
    currentRow.add(buffer.toString());
    buffer.clear();
  }

  void commitRow() {
    if (currentRow.isNotEmpty) {
      rows.add(List<String>.from(currentRow));
    }
    currentRow.clear();
  }

  for (var i = 0; i < trimmed.length; i++) {
    final char = trimmed[i];
    if (char == '"') {
      if (inQuotes && i + 1 < trimmed.length && trimmed[i + 1] == '"') {
        buffer.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }
    if (!inQuotes && char == ';') {
      commitField();
      continue;
    }
    if (!inQuotes && char == '\n') {
      commitField();
      commitRow();
      continue;
    }
    buffer.write(char);
  }
  commitField();
  if (currentRow.isNotEmpty) commitRow();

  return rows;
}

DateTime? _parseIFinanceDate(String value) {
  final parts = value.trim().split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  var yearPart = int.tryParse(parts[2]);
  if (day == null || month == null || yearPart == null) return null;
  if (yearPart < 100) yearPart += 2000;
  if (day < 1 || day > 31 || month < 1 || month > 12) return null;
  final date = DateTime(yearPart, month, day);
  if (date.year != yearPart || date.month != month || date.day != day) return null;
  return date;
}

double _parseIFinanceAmount(String value) {
  var s = value.trim().replaceAll(' ', '');
  if (s.isEmpty) return double.nan;
  if (s.contains(',') && s.contains('.')) {
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '');
      s = s.replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (s.contains(',')) {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s) ?? double.nan;
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _normalizeText(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String _transferGroupKey(DateTime date, double amount) =>
    '${_dateOnly(date)}|${amount.toStringAsFixed(2)}';

class _TransferDirectionHint {
  final String? sourceAccount;
  final String? destinationAccount;

  const _TransferDirectionHint({
    this.sourceAccount,
    this.destinationAccount,
  });
}

_TransferDirectionHint _parseTransferDirectionHint(IFinanceCsvRow row) {
  final payee = row.payee ?? '';
  final normalized = _normalizeText(payee);
  final fromMatch = RegExp(r'trasferimento\s+da\s+(.+)$', caseSensitive: false)
      .firstMatch(normalized);
  final toMatch = RegExp(r'trasferimento\s+su\s+(.+)$', caseSensitive: false)
      .firstMatch(normalized);

  String? cleanAccount(String? value) {
    if (value == null) return null;
    final stripped = value
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return stripped.isEmpty ? null : stripped;
  }

  return _TransferDirectionHint(
    sourceAccount: cleanAccount(fromMatch?.group(1)),
    destinationAccount: cleanAccount(toMatch?.group(1)),
  );
}

class _TransferPreviewStats {
  final int candidateRows;
  final int ambiguousGroups;

  const _TransferPreviewStats({
    required this.candidateRows,
    required this.ambiguousGroups,
  });
}

class _IFinanceImportPlan {
  final List<Account> accounts;
  final List<Category> categories;
  final List<Subcategory> subcategories;
  final List<QuickMovement> quickMovements;
  final List<FavoriteMovement> favoriteMovements;
  final List<Movement> movements;

  final Map<String, Account> _accountsByName = {};
  final Map<String, Account> _accountsById = {};
  final Map<String, Category> _categoriesByKey = {};
  final Map<String, Category> _categoriesById = {};
  final Map<String, List<Subcategory>> _subcategoriesByCategory = {};
  final Set<String> _dbFingerprints = {};

  _IFinanceImportPlan._({
    required this.accounts,
    required this.categories,
    required this.subcategories,
    required this.quickMovements,
    required this.favoriteMovements,
    required this.movements,
  }) {
    for (final a in accounts) {
      _accountsByName[_normalizeText(a.name)] = a;
      _accountsById[a.id] = a;
    }
    for (final c in categories) {
      _categoriesByKey[_categoryKey(c.type, c.name)] = c;
      _categoriesById[c.id] = c;
    }
    for (final s in subcategories) {
      _subcategoriesByCategory.putIfAbsent(s.categoryId, () => []).add(s);
    }
    for (final m in movements) {
      _dbFingerprints.add(_fingerprintForMovement(m));
    }
  }

  factory _IFinanceImportPlan.fromDb(AppDatabase db) {
    return _IFinanceImportPlan._(
      accounts: db.accounts.toList(),
      categories: db.categories.toList(),
      subcategories: db.subcategories.toList(),
      quickMovements: db.quickMovements.toList(),
      favoriteMovements: db.favoriteMovements.toList(),
      movements: db.movements.toList(),
    );
  }

  String _categoryKey(MovementType type, String name) =>
      '${type.name}|${_normalizeText(name)}';

  IFinanceTransferPair? _buildTransferPair({
    required IFinanceCsvRow negativeRow,
    required IFinanceCsvRow positiveRow,
  }) {
    if (_normalizeText(negativeRow.account) == _normalizeText(positiveRow.account)) {
      return null;
    }
    return IFinanceTransferPair(
      negativeRow: negativeRow,
      positiveRow: positiveRow,
    );
  }

  _TransferMatchCandidate? _buildMatchCandidate({
    required IFinanceCsvRow negativeRow,
    required IFinanceCsvRow positiveRow,
  }) {
    final pair = _buildTransferPair(
      negativeRow: negativeRow,
      positiveRow: positiveRow,
    );
    if (pair == null) {
      return null;
    }

    final positiveHint = _parseTransferDirectionHint(positiveRow);
    final negativeHint = _parseTransferDirectionHint(negativeRow);
    final negativeAccount = _normalizeText(negativeRow.account);
    final positiveAccount = _normalizeText(positiveRow.account);

    var score = 0;

    if (positiveHint.sourceAccount != null) {
      if (_normalizeText(positiveHint.sourceAccount!) != negativeAccount) {
        return null;
      }
      score += 3;
    }

    if (negativeHint.destinationAccount != null) {
      if (_normalizeText(negativeHint.destinationAccount!) != positiveAccount) {
        return null;
      }
      score += 3;
    }

    if (positiveHint.sourceAccount != null &&
        negativeHint.destinationAccount != null) {
      score += 2;
    }

    if (positiveHint.sourceAccount == null && negativeHint.destinationAccount == null) {
      score = 1;
    }

    return _TransferMatchCandidate(
      pair: pair,
      negativeRow: negativeRow,
      positiveRow: positiveRow,
      score: score,
    );
  }

  List<_TransferMatchCandidate>? _findUniqueTransferMatching(
    List<IFinanceCsvRow> negatives,
    List<IFinanceCsvRow> positives,
    List<_TransferMatchCandidate> candidates,
  ) {
    final byNegative = <IFinanceCsvRow, List<_TransferMatchCandidate>>{};
    for (final candidate in candidates) {
      byNegative.putIfAbsent(candidate.negativeRow, () => []).add(candidate);
    }
    for (final negative in negatives) {
      final options = byNegative[negative];
      if (options == null || options.isEmpty) {
        return null;
      }
      options.sort((a, b) => b.score.compareTo(a.score));
    }

    final orderedNegatives = [...negatives]
      ..sort((a, b) => (byNegative[a]!.length).compareTo(byNegative[b]!.length));
    final usedPositives = <IFinanceCsvRow>{};
    final current = <_TransferMatchCandidate>[];
    List<_TransferMatchCandidate>? unique;
    var solutions = 0;

    void search(int index) {
      if (solutions > 1) {
        return;
      }
      if (index == orderedNegatives.length) {
        if (current.length == positives.length) {
          solutions++;
          unique = List<_TransferMatchCandidate>.from(current);
        }
        return;
      }

      final negative = orderedNegatives[index];
      for (final candidate in byNegative[negative]!) {
        if (usedPositives.contains(candidate.positiveRow)) {
          continue;
        }
        usedPositives.add(candidate.positiveRow);
        current.add(candidate);
        search(index + 1);
        current.removeLast();
        usedPositives.remove(candidate.positiveRow);
        if (solutions > 1) {
          return;
        }
      }
    }

    search(0);
    return solutions == 1 ? unique : null;
  }

  String _fingerprintForMovement(Movement m) {
    final accName = _accountsById[m.accountId]?.name ?? m.accountId;
    final destAccName = m.destinationAccountId != null
        ? (_accountsById[m.destinationAccountId]?.name ?? m.destinationAccountId!)
        : '';
    final catName = _categoriesById[m.categoryId]?.name ?? m.categoryId;
    final subName = m.subcategoryId != null
        ? (subcategories.where((s) => s.id == m.subcategoryId).firstOrNull?.name ?? '')
        : '';
    return [
      _iFinanceFingerprintPrefix,
      _dateOnly(m.date),
      m.type.name,
      m.amount.toStringAsFixed(2),
      _normalizeText(accName),
      _normalizeText(destAccName),
      _normalizeText(catName),
      _normalizeText(subName),
      _normalizeText(m.title),
      _normalizeText(m.payee ?? ''),
      _normalizeText(m.note ?? ''),
    ].join('|');
  }

  String _fingerprintForRow({
    required DateTime date,
    required MovementType type,
    required double amount,
    required String accountName,
    required String destinationAccountName,
    required String categoryName,
    required String subcategoryName,
    required String title,
    required String? payee,
    required String note,
    int occurrenceIndex = 0,
  }) {
    final fp = [
      _iFinanceFingerprintPrefix,
      _dateOnly(date),
      type.name,
      amount.toStringAsFixed(2),
      _normalizeText(accountName),
      _normalizeText(destinationAccountName),
      _normalizeText(categoryName),
      _normalizeText(subcategoryName),
      _normalizeText(title),
      _normalizeText(payee ?? ''),
      _normalizeText(note),
    ].join('|');
    if (occurrenceIndex > 0) return '$fp#$occurrenceIndex';
    return fp;
  }

  /// Checks [fingerprint] against DB fingerprints.
  ///
  /// 1. Exact match: `_dbFingerprints.contains(fingerprint)`.
  /// 2. Backward compat with old imports (no suffix in DB): if [fingerprint]
  ///    carries a `#N` suffix, extract the base and check if the exact base
  ///    exists in `_dbFingerprints`.
  /// 3. Does NOT match two different suffixed entries (e.g. `baseFp#1` vs
  ///    `baseFp#2`) only by their normalized base.
  bool isDuplicate(String fingerprint) {
    if (_dbFingerprints.contains(fingerprint)) return true;
    final hashPos = fingerprint.lastIndexOf('#');
    if (hashPos > 0) {
      final suffix = fingerprint.substring(hashPos + 1);
      if (suffix.isNotEmpty && suffix.codeUnits.every((c) => c >= 48 && c <= 57)) {
        return _dbFingerprints.contains(fingerprint.substring(0, hashPos));
      }
    }
    return false;
  }

  IFinanceImportPreview buildPreview(String csvText) {
    final allRows = _parseCsvRows(csvText);
    if (allRows.isEmpty) {
      return IFinanceImportPreview(
        totalRows: 0,
        duplicatesSkipped: 0,
        intraFileRepeats: 0,
        movements: const [],
        transfers: const [],
        ambiguousTransfers: const [],
        accountsToCreate: const [],
        categoriesToCreate: const [],
        subcategoriesToCreate: const [],
        errors: ['File CSV vuoto'],
        accountsFromMetadata: const [],
        accountsFoundInCsv: 0,
        accountsUsedByMovements: 0,
        accountsExistingInDb: 0,
        metadataOnlyAccounts: const [],
      );
    }

    var headerIndex = -1;
    final metadataLines = <List<String>>[];
    for (var i = 0; i < allRows.length; i++) {
      if (allRows[i].isNotEmpty && _headerStartPattern.hasMatch(allRows[i].join(';'))) {
        headerIndex = i;
        break;
      }
      if (allRows[i].isNotEmpty) {
        metadataLines.add(allRows[i]);
      }
    }

    // Parse "Conti:" from metadata
    final accountsFromMetadata = <String>{};
    for (final meta in metadataLines) {
      final line = meta.join(';').trim();
      if (line.startsWith('Conti:') || line.startsWith('Conti :')) {
        final afterColon = line.substring(line.indexOf(':') + 1).trim();
        for (final raw in afterColon.split(',')) {
          final name = raw.trim();
          if (name.isNotEmpty) accountsFromMetadata.add(name);
        }
        break;
      }
    }

    if (headerIndex < 0) {
      return IFinanceImportPreview(
        totalRows: allRows.length,
        duplicatesSkipped: 0,
        intraFileRepeats: 0,
        movements: const [],
        transfers: const [],
        ambiguousTransfers: const [],
        accountsToCreate: const [],
        categoriesToCreate: const [],
        subcategoriesToCreate: const [],
        errors: ['Intestazione CSV non trovata. Cercata: "Data;Importo;..."'],
        accountsFromMetadata: const [],
        accountsFoundInCsv: 0,
        accountsUsedByMovements: 0,
        accountsExistingInDb: 0,
        metadataOnlyAccounts: const [],
      );
    }

    final headerRow = allRows[headerIndex];
    final columnMap = _buildColumnMap(headerRow);

    if (!columnMap.containsKey('data') || !columnMap.containsKey('importo')) {
      return IFinanceImportPreview(
        totalRows: allRows.length,
        duplicatesSkipped: 0,
        intraFileRepeats: 0,
        movements: const [],
        transfers: const [],
        ambiguousTransfers: const [],
        accountsToCreate: const [],
        categoriesToCreate: const [],
        subcategoriesToCreate: const [],
        errors: ['Colonne obbligatorie "Data" e "Importo" non trovate nell\'intestazione.'],
        accountsFromMetadata: const [],
        accountsFoundInCsv: 0,
        accountsUsedByMovements: 0,
        accountsExistingInDb: 0,
        metadataOnlyAccounts: const [],
      );
    }

    final errors = <String>[];
    final parsedRows = <IFinanceCsvRow>[];
    var dataRowCount = 0;

    String cell(int rowIdx, String col) {
      final normalized = col.trim().toLowerCase().replaceAll(RegExp(r'[\s/]'), '');
      final ci = columnMap[normalized];
      if (ci == null || ci >= allRows[rowIdx].length) return '';
      return allRows[rowIdx][ci].trim();
    }

    for (var i = headerIndex + 1; i < allRows.length; i++) {
      final row = allRows[i];
      if (row.every((c) => c.trim().isEmpty)) continue;

      dataRowCount++;

      final dateStr = cell(i, 'data');
      final amountStr = cell(i, 'importo');

      if (dateStr.isEmpty && amountStr.isEmpty) continue;

      if (dateStr.isEmpty) {
        errors.add('Riga ${i + 1}: data mancante');
        continue;
      }

      if (!_datePattern.hasMatch(dateStr)) {
        errors.add('Riga ${i + 1}: formato data non valido "$dateStr" (atteso dd/MM/yy)');
        continue;
      }

      final date = _parseIFinanceDate(dateStr);
      if (date == null) {
        errors.add('Riga ${i + 1}: data non valida "$dateStr"');
        continue;
      }

      if (amountStr.isEmpty) {
        errors.add('Riga ${i + 1}: importo mancante');
        continue;
      }

      final amount = _parseIFinanceAmount(amountStr);
      if (amount.isNaN) {
        errors.add('Riga ${i + 1}: importo non valido "$amountStr"');
        continue;
      }

      if (amount == 0) {
        errors.add('Riga ${i + 1}: importo zero, ignorata');
        continue;
      }

      final title = cell(i, 'causale');
      final payee = cell(i, 'beneficiario/contribuente');
      final categoryRaw = cell(i, 'categoria');
      final comment = cell(i, 'commento');
      final labels = cell(i, 'etichette');
      final account = cell(i, 'conto');

      if (account.isEmpty) {
        errors.add('Riga ${i + 1}: conto mancante');
        continue;
      }

      final categoryParts = categoryRaw.isNotEmpty ? categoryRaw.split(':') : <String>[''];
      final categoryParent = categoryParts.isNotEmpty ? categoryParts[0].trim() : '';
      final subcategoryName = categoryParts.length > 1
          ? categoryParts.sublist(1).join(':').trim()
          : '';

      parsedRows.add(IFinanceCsvRow(
        lineNumber: i + 1,
        date: date,
        rawAmount: amount,
        title: title,
        payee: payee.isNotEmpty ? payee : null,
        account: account,
        comment: comment,
        labels: labels,
        categoryRaw: categoryRaw,
        categoryParent: categoryParent,
        subcategoryName: subcategoryName,
      ));
    }

    // First pass: compute base fingerprint for each row
    final rowFingerprints = <String>[];
    for (final row in parsedRows) {
      final baseFp = _fingerprintForRow(
        date: row.date,
        type: row.type,
        amount: row.amount,
        accountName: row.account,
        destinationAccountName: '',
        categoryName: row.categoryParent,
        subcategoryName: row.subcategoryName,
        title: row.title,
        payee: row.payee,
        note: row.note,
      );
      rowFingerprints.add(baseFp);
    }

    // Count base fingerprint occurrences within the file
    final baseFpCounts = <String, int>{};
    for (final fp in rowFingerprints) {
      baseFpCounts[fp] = (baseFpCounts[fp] ?? 0) + 1;
    }
    var intraFileRepeats = 0;
    for (final count in baseFpCounts.values) {
      if (count > 1) intraFileRepeats += count - 1;
    }

    // Compute occurrenceIndex for each row (1-based per baseFp group)
    final occurrenceCounters = <String, int>{};
    for (var i = 0; i < parsedRows.length; i++) {
      final baseFp = rowFingerprints[i];
      final count = (occurrenceCounters[baseFp] ?? 0) + 1;
      occurrenceCounters[baseFp] = count;
      if (baseFpCounts[baseFp]! > 1) {
        parsedRows[i].occurrenceIndex = count;
      }
    }

    // Second pass: skip only rows whose final fingerprint already exists in DB
    var duplicatesSkipped = 0;
    final dedupedRows = <IFinanceCsvRow>[];
    for (var i = 0; i < parsedRows.length; i++) {
      final row = parsedRows[i];
      final finalFp = _fingerprintForRow(
        date: row.date,
        type: row.type,
        amount: row.amount,
        accountName: row.account,
        destinationAccountName: '',
        categoryName: row.categoryParent,
        subcategoryName: row.subcategoryName,
        title: row.title,
        payee: row.payee,
        note: row.note,
        occurrenceIndex: row.occurrenceIndex,
      );
      if (isDuplicate(finalFp)) {
        duplicatesSkipped++;
        continue;
      }
      dedupedRows.add(row);
    }

    final transferRows = <IFinanceCsvRow>[];
    final nonTransferRows = <IFinanceCsvRow>[];
    for (final row in dedupedRows) {
      if (row.isLikelyTransfer()) {
        transferRows.add(row);
      } else {
        nonTransferRows.add(row);
      }
    }

    final paired = <IFinanceTransferPair>[];
    final ambiguous = <IFinanceCsvRow>[];
    final transferStats = _pairTransfers(transferRows, paired, ambiguous);
    final transferFpCounts = <String, int>{};
    final pairFinalFingerprints = <String>[];
    for (final pair in paired) {
      final baseFp = _fingerprintForRow(
        date: pair.date,
        type: MovementType.transfer,
        amount: pair.amount,
        accountName: pair.accountSource,
        destinationAccountName: pair.accountDestination,
        categoryName: '',
        subcategoryName: '',
        title: pair.title,
        payee: null,
        note: pair.note,
      );
      transferFpCounts[baseFp] = (transferFpCounts[baseFp] ?? 0) + 1;
      final occurrence = transferFpCounts[baseFp]!;
      pairFinalFingerprints.add(
        occurrence > 1 ? '$baseFp#$occurrence' : baseFp,
      );
    }

    final finalTransfers = <IFinanceTransferPair>[];
    for (var i = 0; i < paired.length; i++) {
      if (isDuplicate(pairFinalFingerprints[i])) {
        duplicatesSkipped++;
        continue;
      }
      finalTransfers.add(paired[i]);
    }
    final unusedTransferRows = ambiguous;

    // Collect accounts from all importable rows (deduped by normalized key)
    final accountsSet = <String, String>{}; // normalizedKey -> originalName
    final categoriesSet = <String, String>{}; // key: "typeIndex|normalizedName" -> originalName
    final subcategoriesSet = <CategorySubPreview>{};
    DateTime? minDate;
    DateTime? maxDate;

    for (final row in nonTransferRows) {
      accountsSet[_normalizeText(row.account)] = row.account;
      if (row.hasCategory && row.categoryParent.isNotEmpty) {
        final cat = _categoriesByKey[_categoryKey(row.type, row.categoryParent)];
        if (cat != null) {
          if (row.subcategoryName.isNotEmpty) {
            final existingSubs = _subcategoriesByCategory[cat.id] ?? [];
            final exists = existingSubs.any((s) => _normalizeText(s.name) == _normalizeText(row.subcategoryName));
            if (!exists) {
              subcategoriesSet.add(CategorySubPreview(
                category: row.categoryParent,
                subcategory: row.subcategoryName,
              ));
            }
          }
        } else {
          categoriesSet['${row.type.index}|${_normalizeText(row.categoryParent)}'] = row.categoryParent;
          if (row.subcategoryName.isNotEmpty) {
            subcategoriesSet.add(CategorySubPreview(
              category: row.categoryParent,
              subcategory: row.subcategoryName,
            ));
          }
        }
      }
      if (minDate == null || row.date.isBefore(minDate)) minDate = row.date;
      if (maxDate == null || row.date.isAfter(maxDate)) maxDate = row.date;
    }

    for (final pair in finalTransfers) {
      accountsSet[_normalizeText(pair.accountSource)] = pair.accountSource;
      accountsSet[_normalizeText(pair.accountDestination)] = pair.accountDestination;
    }
    for (final row in unusedTransferRows) {
      accountsSet[_normalizeText(row.account)] = row.account;
      if (minDate == null || row.date.isBefore(minDate)) minDate = row.date;
      if (maxDate == null || row.date.isAfter(maxDate)) maxDate = row.date;
    }

    // Compute account stats
    final accountsUsedNames = accountsSet.values.map((n) => n.trim()).toSet();
    final accountsUsedCount = accountsUsedNames.length;

    final existingAccountNormalized = accounts.map((a) => _normalizeText(a.name)).toSet();
    final accountsToCreate = <String>{};
    for (final name in accountsUsedNames) {
      if (!existingAccountNormalized.contains(_normalizeText(name))) {
        accountsToCreate.add(name);
      }
    }
    final accountsToCreateList = accountsToCreate.toList()..sort();

    // Metadata-only accounts (not used by any importable row)
    final metadataOnlyAccounts = <String>{};
    for (final metaName in accountsFromMetadata) {
      final trimmed = metaName.trim();
      if (trimmed.isNotEmpty) {
        final normalized = _normalizeText(trimmed);
        if (!accountsSet.containsKey(normalized)) {
          metadataOnlyAccounts.add(trimmed);
        }
      }
    }
    final metadataOnlyList = metadataOnlyAccounts.toList()..sort();

    final accountsFoundCount = accountsSet.length + metadataOnlyAccounts.length;
    final accountsExistingCount = accountsUsedNames
        .where((n) => existingAccountNormalized.contains(_normalizeText(n)))
        .length;

    final existingCategoryKeys = _categoriesByKey.keys.toSet();
    final categoriesToCreate = <String>{};
    final subcategoriesToCreate = <CategorySubPreview>{};
    for (final entry in categoriesSet.entries) {
      final parts = entry.key.split('|');
      final typeIdx = int.parse(parts[0]);
      final name = entry.value;
      final type = MovementType.values[typeIdx];
      final key = _categoryKey(type, name);
      if (!existingCategoryKeys.contains(key)) {
        categoriesToCreate.add(name.trim());
      }
    }
    categoriesToCreate.removeWhere((c) => c.trim().isEmpty);
    for (final sc in subcategoriesSet) {
      subcategoriesToCreate.add(sc);
    }

    return IFinanceImportPreview(
      totalRows: dataRowCount,
      duplicatesSkipped: duplicatesSkipped,
      intraFileRepeats: intraFileRepeats,
      movements: nonTransferRows,
      transfers: finalTransfers,
      ambiguousTransfers: unusedTransferRows,
      accountsToCreate: accountsToCreateList,
      categoriesToCreate: categoriesToCreate.toList()..sort(),
      subcategoriesToCreate: subcategoriesToCreate.toList(),
      dateMin: minDate,
      dateMax: maxDate,
      errors: errors,
      accountsFromMetadata: accountsFromMetadata.toList()..sort(),
      accountsFoundInCsv: accountsFoundCount,
      accountsUsedByMovements: accountsUsedCount,
      accountsExistingInDb: accountsExistingCount,
      metadataOnlyAccounts: metadataOnlyList,
      transferCandidateRows: transferStats.candidateRows,
      ambiguousTransferGroups: transferStats.ambiguousGroups,
    );
  }

  _TransferPreviewStats _pairTransfers(
    List<IFinanceCsvRow> rows,
    List<IFinanceTransferPair> paired,
    List<IFinanceCsvRow> ambiguous,
  ) {
    final groups = <String, List<IFinanceCsvRow>>{};
    for (final row in rows) {
      groups.putIfAbsent(_transferGroupKey(row.date, row.amount), () => []).add(row);
    }

    var ambiguousGroups = 0;
    for (final group in groups.values) {
      final positives = group.where((row) => row.isIncome).toList();
      final negatives = group.where((row) => row.isExpense).toList();

      if (positives.isEmpty || negatives.isEmpty) {
        ambiguous.addAll(group);
        ambiguousGroups++;
        continue;
      }

      if (positives.length == 1 && negatives.length == 1) {
        final pair = _buildTransferPair(
          negativeRow: negatives.first,
          positiveRow: positives.first,
        );
        if (pair != null) {
          paired.add(pair);
        } else {
          ambiguous.addAll(group);
          ambiguousGroups++;
        }
        continue;
      }

      final matches = <_TransferMatchCandidate>[];
      for (final negative in negatives) {
        for (final positive in positives) {
          final candidate = _buildMatchCandidate(
            negativeRow: negative,
            positiveRow: positive,
          );
          if (candidate != null) {
            matches.add(candidate);
          }
        }
      }

      if (matches.isEmpty) {
        ambiguous.addAll(group);
        ambiguousGroups++;
        continue;
      }

      final chosen = _findUniqueTransferMatching(
        negatives,
        positives,
        matches,
      );
      if (chosen == null) {
        ambiguous.addAll(group);
        ambiguousGroups++;
        continue;
      }

      for (final candidate in chosen) {
        paired.add(candidate.pair);
      }
    }

    return _TransferPreviewStats(
      candidateRows: rows.length,
      ambiguousGroups: ambiguousGroups,
    );
  }

  Future<IFinanceImportReport> commit(
    AppDatabase db,
    IFinanceImportPreview preview,
  ) async {
    var accountsCreated = 0;
    var categoriesCreated = 0;
    var subcategoriesCreated = 0;
    var movementsImported = 0;
    var transfersImported = 0;
    final errors = <String>[];

    final accountNameCache = <String, Account>{};
    for (final a in accounts) {
      accountNameCache[_normalizeText(a.name)] = a;
      _accountsByName[_normalizeText(a.name)] = a;
      _accountsById[a.id] = a;
    }

    Account getOrCreateAccount(String name) {
      final key = _normalizeText(name);
      var existing = accountNameCache[key];
      if (existing != null) return existing;
      existing = _accountsByName[key];
      if (existing != null) return existing;

      final now = DateTime.now();
      final a = Account(
        id: 'if_acc_${DateTime.now().microsecondsSinceEpoch}_$accountsCreated',
        name: name.trim(),
        type: AccountType.bank,
        iconKey: StreamIconLibrary.defaultAccountIcon,
        color: StreamColorPalette.getDefault(),
        createdAt: now,
        updatedAt: now,
      );
      accountNameCache[key] = a;
      _accountsByName[key] = a;
      _accountsById[a.id] = a;
      accountsCreated++;
      return a;
    }

    Category getOrCreateCategory(String name, MovementType type) {
      final key = _categoryKey(type, name);
      var existing = _categoriesByKey[key];
      if (existing != null) return existing;

      final c = Category(
        id: 'if_cat_${DateTime.now().microsecondsSinceEpoch}_$categoriesCreated',
        name: name.trim(),
        type: type,
        color: StreamColorPalette.getDefault(),
        iconKey: StreamIconLibrary.defaultCategoryIcon,
      );
      _categoriesByKey[key] = c;
      _categoriesById[c.id] = c;
      categoriesCreated++;
      return c;
    }

    Subcategory? getOrCreateSubcategory(Category parent, String name) {
      final existingList = _subcategoriesByCategory[parent.id] ?? [];
      final existing = existingList.where(
        (s) => _normalizeText(s.name) == _normalizeText(name),
      ).firstOrNull;
      if (existing != null) return existing;

      final now = DateTime.now();
      final s = Subcategory(
        id: 'if_sub_${DateTime.now().microsecondsSinceEpoch}_$subcategoriesCreated',
        categoryId: parent.id,
        name: name.trim(),
        createdAt: now,
        updatedAt: now,
      );
      _subcategoriesByCategory.putIfAbsent(parent.id, () => []).add(s);
      subcategoriesCreated++;
      return s;
    }

    void writeMovement(Movement m) {
      movements.add(m);
    }

    for (final row in preview.movements) {
      try {
        final acc = getOrCreateAccount(row.account);

        Category cat;
        Subcategory? subcat;
        if (row.hasCategory && row.categoryParent.isNotEmpty) {
          cat = getOrCreateCategory(row.categoryParent, row.type);
          if (row.subcategoryName.isNotEmpty) {
            subcat = getOrCreateSubcategory(cat, row.subcategoryName);
          }
        } else {
          cat = getOrCreateCategory('Varie', row.type);
        }

        final now = DateTime.now();
        final m = Movement(
          id: 'if_mv_${DateTime.now().microsecondsSinceEpoch}_$movementsImported',
          title: row.title.isNotEmpty ? row.title : cat.name,
          amount: row.amount,
          type: row.type,
          date: row.date,
          categoryId: cat.id,
          subcategoryId: subcat?.id,
          accountId: acc.id,
          note: row.note.isNotEmpty ? row.note : null,
          payee: row.payee,
          createdAt: now,
          updatedAt: now,
        );
        writeMovement(m);
        movementsImported++;
      } catch (e) {
        errors.add('Errore riga ${row.lineNumber}: $e');
      }
    }

    for (final pair in preview.transfers) {
      try {
        final srcAcc = getOrCreateAccount(pair.accountSource);
        final dstAcc = getOrCreateAccount(pair.accountDestination);
        final now = DateTime.now();
        final m = Movement(
          id: 'if_tr_${DateTime.now().microsecondsSinceEpoch}_$transfersImported',
          title: pair.title.isNotEmpty ? pair.title : 'Trasferimento',
          amount: pair.amount,
          type: MovementType.transfer,
          date: pair.date,
          categoryId: '',
          accountId: srcAcc.id,
          destinationAccountId: dstAcc.id,
          note: pair.note.isNotEmpty ? pair.note : null,
          createdAt: now,
          updatedAt: now,
        );
        writeMovement(m);
        transfersImported++;
      } catch (e) {
        errors.add('Errore trasferimento (${pair.date}): $e');
      }
    }

    // Ensure all accountsToCreate are actually created (covers ambiguous transfers etc.)
    for (final accountName in preview.accountsToCreate) {
      getOrCreateAccount(accountName);
    }

    if (db.sqliteService != null) {
      await db.sqliteService!.transaction((txn) async {
        final allAccounts = _accountsByKey.values.toList();
        for (final a in allAccounts) {
          await txn.insert('accounts', _accountToRow(a),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        final allCategories = _categoriesByKey.values.toList();
        for (final c in allCategories) {
          await txn.insert('categories', _categoryToRow(c),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        final allSubcategories = _subcategoriesByCategory.values.expand((l) => l).toList();
        for (final s in allSubcategories) {
          await txn.insert('subcategories', _subcategoryToRow(s),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        final allMovements = movements.toList();
        for (final m in allMovements) {
          if (m.id.startsWith('if_')) {
            await txn.insert('movements', _movementToRow(m),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });
      await db.reloadFromDb();
    } else {
      db.replaceState(
        movements: movements,
        categories: _categoriesByKey.values.toList(),
        subcategories: _subcategoriesByCategory.values.expand((l) => l).toList(),
        quickMovements: quickMovements,
        favoriteMovements: favoriteMovements,
        accounts: _accountsByKey.values.toList(),
      );
      db.notify();
    }

    return IFinanceImportReport(
      movementsImported: movementsImported,
      transfersImported: transfersImported,
      duplicatesSkipped: preview.duplicatesSkipped,
      accountsCreated: accountsCreated,
      categoriesCreated: categoriesCreated,
      subcategoriesCreated: subcategoriesCreated,
      errorsCount: errors.length,
      errors: errors,
    );
  }

  Map<String, Account> get _accountsByKey {
    final result = <String, Account>{};
    for (final a in accounts) {
      result[a.id] = a;
    }
    for (final entry in _accountsById.entries) {
      result[entry.key] = entry.value;
    }
    return result;
  }
}

class _TransferMatchCandidate {
  final IFinanceTransferPair pair;
  final IFinanceCsvRow negativeRow;
  final IFinanceCsvRow positiveRow;
  final int score;

  const _TransferMatchCandidate({
    required this.pair,
    required this.negativeRow,
    required this.positiveRow,
    required this.score,
  });
}

Map<String, int> _buildColumnMap(List<String> headerRow) {
  final map = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    final key = headerRow[i].trim().toLowerCase().replaceAll(RegExp(r'[\s/]'), '');
    map[key] = i;
  }
  return map;
}

Map<String, dynamic> _accountToRow(Account a) => {
      'id': a.id,
      'name': a.name,
      'type': a.type.name,
      'initial_balance': a.initialBalance,
      'icon_key': a.iconKey,
      'color': a.color,
      'archived': a.archived ? 1 : 0,
      'created_at': a.createdAt.toIso8601String(),
      'updated_at': a.updatedAt.toIso8601String(),
    };

Map<String, dynamic> _categoryToRow(Category c) => {
      'id': c.id,
      'name': c.name,
      'type': c.type.name,
      'color': c.color,
      'icon_key': c.iconKey,
      'archived': c.archived ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

Map<String, dynamic> _subcategoryToRow(Subcategory s) => {
      'id': s.id,
      'category_id': s.categoryId,
      'name': s.name,
      'icon_key': s.iconKey,
      'color': s.color,
      'archived': s.archived ? 1 : 0,
      'created_at': s.createdAt.toIso8601String(),
      'updated_at': s.updatedAt.toIso8601String(),
    };

Map<String, dynamic> _movementToRow(Movement m) => {
      'id': m.id,
      'title': m.title,
      'amount': m.amount,
      'type': m.type.name,
      'category_id': m.categoryId,
      'subcategory_id': m.subcategoryId,
      'account_id': m.accountId,
      'destination_account_id': m.destinationAccountId,
      'date': _dateOnly(m.date),
      'note': m.note,
      'payee': m.payee,
      'created_at': m.createdAt.toIso8601String(),
      'updated_at': m.updatedAt.toIso8601String(),
    };

class IFinanceImportPreviewDialog extends StatelessWidget {
  final IFinanceImportPreview preview;

  const IFinanceImportPreviewDialog({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final p = preview;
    const maxItems = 20;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Text('Anteprima import iFinance',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Righe dati lette: ${p.totalRows}'),
                  Text('Movimenti importabili: ${p.movementsToImport}'),
                  Text('Righe candidate transfer: ${p.transferCandidateRows}'),
                  Text('Transfer riconosciuti: ${p.transfersToImport}'),
                  if (p.ambiguousTransfers.isNotEmpty)
                    Text(
                      'Transfer ambigui: ${p.ambiguousTransfers.length} righe in ${p.ambiguousTransferGroups} gruppi',
                      style: TextStyle(color: Colors.orange.shade300),
                    ),
                  if (p.intraFileRepeats > 0)
                    Text(
                        'Righe ripetute nel file: ${p.intraFileRepeats} — verranno importate come movimenti separati',
                        style: TextStyle(color: Colors.orange.shade300)),
                  if (p.duplicatesSkipped > 0)
                    Text('Duplicati già presenti: ${p.duplicatesSkipped} — verranno saltati',
                        style: TextStyle(color: Colors.orange.shade300)),
                  if (p.errorCount > 0)
                    Text('Errori: ${p.errors.length}',
                        style: TextStyle(color: Colors.red.shade300)),
                  if (p.dateMin != null && p.dateMax != null)
                    Text(
                        'Periodo: ${_fmtDate(p.dateMin!)} - ${_fmtDate(p.dateMax!)}'),
                  if (p.accountsFoundInCsv > 0 || p.accountsFromMetadata.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Conti', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('  Trovati nel CSV: ${p.accountsFoundInCsv}'),
                    Text('  Usati da movimenti: ${p.accountsUsedByMovements}'),
                    Text('  Già esistenti: ${p.accountsExistingInDb}'),
                    if (p.accountsToCreate.isNotEmpty) ...[
                      Text('  Da creare: ${p.accountsToCreate.length}'),
                      ...p.accountsToCreate.take(maxItems).map((a) =>
                          Text('    • $a', style: const TextStyle(fontSize: 12))),
                      if (p.accountsToCreate.length > maxItems)
                        Text('    + altri ${p.accountsToCreate.length - maxItems}',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade400)),
                    ],
                    if (p.metadataOnlyAccounts.isNotEmpty) ...[
                      Text('  Solo nei metadati (non usati): ${p.metadataOnlyAccounts.length}'),
                      ...p.metadataOnlyAccounts.take(maxItems).map((a) =>
                          Text('    • $a', style: TextStyle(fontSize: 12, color: Colors.grey.shade400))),
                      if (p.metadataOnlyAccounts.length > maxItems)
                        Text('    + altri ${p.metadataOnlyAccounts.length - maxItems}',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade400)),
                    ],
                    const Text('  Nota: il CSV iFinance non contiene la gerarchia cartelle dei conti; Stream importa i conti reali, non le cartelle iFinance.',
                        style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ],
                  if (p.categoriesToCreate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Categorie da creare (${p.categoriesToCreate.length}):',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    ...p.categoriesToCreate.take(maxItems).map((c) =>
                        Text('  • $c',
                            style: const TextStyle(fontSize: 12))),
                    if (p.categoriesToCreate.length > maxItems)
                      Text('  + altri ${p.categoriesToCreate.length - maxItems}',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade400)),
                  ],
                  if (p.subcategoriesToCreate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                        'Sottocategorie da creare (${p.subcategoriesToCreate.length}):',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    ...p.subcategoriesToCreate.take(maxItems).map((s) =>
                        Text('  • ${s.category}: ${s.subcategory}',
                            style: const TextStyle(fontSize: 12))),
                    if (p.subcategoriesToCreate.length > maxItems)
                      Text(
                          '  + altri ${p.subcategoriesToCreate.length - maxItems}',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade400)),
                  ],
                  if (p.errorCount > 0) ...[
                    const SizedBox(height: 8),
                    Text('Errori (${p.errors.length}):',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade300)),
                    ...p.errors.take(maxItems).map(
                        (e) => Text('  $e',
                            style: TextStyle(
                                fontSize: 11, color: Colors.red.shade300))),
                    if (p.errors.length > maxItems)
                      Text('  + altri ${p.errors.length - maxItems}',
                          style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.red.shade300)),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annulla'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: p.errorCount == 0
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: Text(p.errorCount == 0
                      ? 'Conferma import'
                      : 'Correggi errori'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
