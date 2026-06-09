import 'package:sqflite/sqflite.dart';

import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/favorite_movement.dart';
import '../models/movement.dart';
import '../models/quick_movement.dart';

class OneMoneyCsvImportReport {
  final int movementsRead;
  final int importedMovements;
  final int duplicateMovements;
  final int duplicateDbMovements;
  final int duplicateWithinFileMovements;
  final int duplicateWithinFileImportedMovements;
  final int accountsCreated;
  final int categoriesCreated;
  final List<String> errors;

  const OneMoneyCsvImportReport({
    required this.movementsRead,
    required this.importedMovements,
    required this.duplicateMovements,
    required this.duplicateDbMovements,
    required this.duplicateWithinFileMovements,
    required this.duplicateWithinFileImportedMovements,
    required this.accountsCreated,
    required this.categoriesCreated,
    required this.errors,
  });

  int get errorCount => errors.length;

  int get duplicateWithinFileSkippedMovements =>
      duplicateWithinFileMovements - duplicateWithinFileImportedMovements;
}

class OneMoneyCsvImportService {
  static Future<OneMoneyCsvImportReport> importCsv(
    AppDatabase db,
    String csvText,
    {bool dedupeWithinFile = true}) async {
    final plan = _OneMoneyImportPlan.fromDb(db);
    final parsed = _CsvParser.parse(csvText);

    if (parsed.rows.isEmpty) {
      return OneMoneyCsvImportReport(
        movementsRead: 0,
        importedMovements: 0,
        duplicateMovements: 0,
        duplicateDbMovements: 0,
        duplicateWithinFileMovements: 0,
        duplicateWithinFileImportedMovements: 0,
        accountsCreated: 0,
        categoriesCreated: 0,
        errors: const ['File CSV vuoto o senza righe dati'],
      );
    }

    final headerMap = _buildHeaderMap(parsed.rows.first);
    final missingHeaders = _requiredHeaders
        .where((header) => !headerMap.containsKey(_headerKey(header)))
        .toList();
    if (missingHeaders.isNotEmpty) {
      return OneMoneyCsvImportReport(
        movementsRead: 0,
        importedMovements: 0,
        duplicateMovements: 0,
        duplicateDbMovements: 0,
        duplicateWithinFileMovements: 0,
        duplicateWithinFileImportedMovements: 0,
        accountsCreated: 0,
        categoriesCreated: 0,
        errors: [
          'Colonne mancanti: ${missingHeaders.map(_prettyHeaderLabel).join(', ')}',
        ],
      );
    }

    for (var i = 1; i < parsed.rows.length; i++) {
      final row = parsed.rows[i];
      if (_rowIsEmpty(row)) continue;
      if (_isTrailerSectionStart(row)) break;

      plan.movementsRead++;

      final parsedRow = _parseRow(
        row,
        headerMap,
        lineNumber: i + 1,
      );
      if (parsedRow == null) {
        continue;
      }
      if (!parsedRow.isValid) {
        plan.errors.add('Riga ${parsedRow.lineNumber}: ${parsedRow.error}');
        continue;
      }

      final fingerprint = plan.fingerprintFor(parsedRow);
      if (plan.isDbDuplicate(fingerprint)) {
        plan.duplicateMovements++;
        plan.duplicateDbMovements++;
        continue;
      }

      final isWithinFileDuplicate = plan.isWithinFileDuplicate(fingerprint);
      if (isWithinFileDuplicate) {
        plan.duplicateWithinFileMovements++;
        if (dedupeWithinFile) {
          plan.duplicateMovements++;
          continue;
        }
      } else {
        plan.markWithinFileFingerprint(fingerprint);
      }

      final importedMovement = plan.importRow(parsedRow);
      if (importedMovement == null) {
        if (!isWithinFileDuplicate) {
          plan.unmarkWithinFileFingerprint(fingerprint);
        }
        continue;
      }

      plan.importedMovements++;
      if (isWithinFileDuplicate && !dedupeWithinFile) {
        plan.duplicateWithinFileImportedMovements++;
      }
    }

    if (db.sqliteService != null) {
      await db.sqliteService!.transaction((txn) async {
        for (final account in plan.createdAccounts) {
          await txn.insert(
            'accounts',
            _accountToRow(account),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final category in plan.createdCategories) {
          await txn.insert(
            'categories',
            _categoryToRow(category),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final movement in plan.createdMovements) {
          await txn.insert(
            'movements',
            _movementToRow(movement),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      await db.reloadFromDb();
    } else {
      db.replaceState(
        movements: plan.movements,
        categories: plan.categories,
        quickMovements: plan.quickMovements,
        favoriteMovements: plan.favoriteMovements,
        accounts: plan.accounts,
      );
      db.notify();
    }

    return plan.buildReport();
  }
}

const List<String> _requiredHeaders = [
  'DATA',
  'TIPOLOGIA',
  'DAL CONTO',
  'AL CONTO / ALLA CATEGORIA',
  'IMPORTO',
  'NOTE',
];

String _prettyHeaderLabel(String header) {
  switch (header) {
    case 'DAL CONTO':
      return 'DAL CONTO';
    case 'AL CONTO / ALLA CATEGORIA':
      return 'AL CONTO / ALLA CATEGORIA';
    default:
      return header;
  }
}

String _normalizeText(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String _fingerprintAmount(double amount) {
  return amount.toString();
}

String _headerKey(String value) {
  return value.trim().toUpperCase().replaceAll(RegExp(r'[\s/]+'), '');
}

bool _rowIsEmpty(List<String> row) {
  for (final cell in row) {
    if (cell.trim().isNotEmpty) return false;
  }
  return true;
}

bool _isTrailerSectionStart(List<String> row) {
  if (row.isEmpty) return false;
  return _normalizeText(row.first) == 'nome';
}

Map<String, int> _buildHeaderMap(List<String> headerRow) {
  final map = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    map[_headerKey(headerRow[i])] = i;
  }
  return map;
}

String _cell(
  List<String> row,
  Map<String, int> headerMap,
  String header,
) {
  final index = headerMap[_headerKey(header)];
  if (index == null || index < 0 || index >= row.length) return '';
  return row[index];
}

MovementType? _parseMovementType(String value) {
  switch (_normalizeText(value)) {
    case 'spesa':
      return MovementType.expense;
    case 'entrata':
      return MovementType.income;
    case 'trasferimento':
      return MovementType.transfer;
  }
  return null;
}

DateTime? _parseCsvDate(String value) {
  final parts = value.trim().split('/');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final yearPart = int.tryParse(parts[2]);
  if (day == null || month == null || yearPart == null) return null;
  final year = yearPart < 100 ? 2000 + yearPart : yearPart;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return DateTime(year, month, day);
}

double? _parseCsvAmount(String value) {
  var normalized = value.trim().replaceAll(' ', '');
  if (normalized.isEmpty) return null;
  normalized = normalized.replaceAll(RegExp(r'[^0-9,\.\-]'), '');
  final hasComma = normalized.contains(',');
  final hasDot = normalized.contains('.');
  if (hasComma && hasDot) {
    final lastComma = normalized.lastIndexOf(',');
    final lastDot = normalized.lastIndexOf('.');
    if (lastComma > lastDot) {
      normalized = normalized.replaceAll('.', '');
      normalized = normalized.replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }
  } else if (hasComma) {
    normalized = normalized.replaceAll(',', '.');
  }
  return double.tryParse(normalized);
}

_ParsedOneMoneyRow? _parseRow(
  List<String> row,
  Map<String, int> headerMap, {
  required int lineNumber,
}) {
  final date = _parseCsvDate(_cell(row, headerMap, 'DATA'));
  if (date == null) {
    return _ParsedOneMoneyRow.error(
      lineNumber,
      'DATA non valida: "${_cell(row, headerMap, 'DATA')}"',
    );
  }

  final type = _parseMovementType(_cell(row, headerMap, 'TIPOLOGIA'));
  if (type == null) {
    return _ParsedOneMoneyRow.error(
      lineNumber,
      'TIPOLOGIA non valida: "${_cell(row, headerMap, 'TIPOLOGIA')}"',
    );
  }

  final amount = _parseCsvAmount(_cell(row, headerMap, 'IMPORTO'));
  if (amount == null) {
    return _ParsedOneMoneyRow.error(
      lineNumber,
      'IMPORTO non valido: "${_cell(row, headerMap, 'IMPORTO')}"',
    );
  }

  final sourceAccount = _cell(row, headerMap, 'DAL CONTO').trim();
  final targetLabel = _cell(row, headerMap, 'AL CONTO / ALLA CATEGORIA').trim();
  final note = _cell(row, headerMap, 'NOTE').trim();
  final noteOrEmpty = note.isEmpty ? '' : note;

  if (sourceAccount.isEmpty) {
    return _ParsedOneMoneyRow.error(
      lineNumber,
      'DAL CONTO mancante o vuoto',
    );
  }

  if ((type == MovementType.income || type == MovementType.expense) && targetLabel.isEmpty) {
    return _ParsedOneMoneyRow.error(
      lineNumber,
      'AL CONTO / ALLA CATEGORIA mancante o vuoto',
    );
  }

  if (type == MovementType.transfer && targetLabel.isEmpty) {
    return _ParsedOneMoneyRow.error(
      lineNumber,
      'AL CONTO / ALLA CATEGORIA mancante o vuoto per un trasferimento',
    );
  }

  final fallbackTitle = targetLabel;
  final title = noteOrEmpty.isNotEmpty ? noteOrEmpty : fallbackTitle;

  return _ParsedOneMoneyRow(
    lineNumber: lineNumber,
    date: date,
    type: type,
    amount: amount,
    sourceAccount: sourceAccount,
    targetLabel: targetLabel,
    note: noteOrEmpty,
    title: title.isNotEmpty ? title : type == MovementType.transfer ? 'Trasferimento' : type.name,
  );
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

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic> _movementToRow(Movement m) => {
      'id': m.id,
      'title': m.title,
      'amount': m.amount,
      'type': m.type.name,
      'category_id': m.categoryId,
      'account_id': m.accountId,
      'destination_account_id': m.destinationAccountId,
      'date': _dateOnly(m.date),
      'note': m.note,
      'created_at': m.createdAt.toIso8601String(),
      'updated_at': m.updatedAt.toIso8601String(),
    };

class _ParsedOneMoneyRow {
  final int lineNumber;
  final DateTime? date;
  final MovementType? type;
  final double? amount;
  final String sourceAccount;
  final String targetLabel;
  final String note;
  final String title;
  final String? error;

  const _ParsedOneMoneyRow({
    required this.lineNumber,
    required this.date,
    required this.type,
    required this.amount,
    required this.sourceAccount,
    required this.targetLabel,
    required this.note,
    required this.title,
    this.error,
  });

  const _ParsedOneMoneyRow.error(int lineNumber, String error)
      : this(
          lineNumber: lineNumber,
          date: null,
          type: null,
          amount: null,
          sourceAccount: '',
          targetLabel: '',
          note: '',
          title: '',
          error: error,
        );

  bool get isValid => error == null && date != null && type != null && amount != null;
}

class _OneMoneyImportPlan {
  final List<Account> accounts;
  final List<Category> categories;
  final List<QuickMovement> quickMovements;
  final List<FavoriteMovement> favoriteMovements;
  final List<Movement> movements;

  final List<Account> createdAccounts = [];
  final List<Category> createdCategories = [];
  final List<Movement> createdMovements = [];
  final Set<String> _dbFingerprints = {};
  final Set<String> _fileFingerprints = {};
  final Map<String, Account> _accountsByName = {};
  final Map<String, Category> _categoriesByKey = {};
  final Map<String, Account> _accountsById = {};
  final Map<String, Category> _categoriesById = {};
  final List<String> errors = [];

  int movementsRead = 0;
  int importedMovements = 0;
  int duplicateMovements = 0;
  int duplicateDbMovements = 0;
  int duplicateWithinFileMovements = 0;
  int duplicateWithinFileImportedMovements = 0;
  int accountsCreated = 0;
  int categoriesCreated = 0;

  _OneMoneyImportPlan._({
    required this.accounts,
    required this.categories,
    required this.quickMovements,
    required this.favoriteMovements,
    required this.movements,
  }) {
    for (final account in accounts) {
      _accountsByName[_normalizedAccountKey(account.name)] = account;
      _accountsById[account.id] = account;
    }
    for (final category in categories) {
      _categoriesByKey[_categoryKey(category.type, category.name)] = category;
      _categoriesById[category.id] = category;
    }
    for (final movement in movements) {
      _dbFingerprints.add(fingerprintForMovement(movement));
    }
  }

  factory _OneMoneyImportPlan.fromDb(AppDatabase db) {
    return _OneMoneyImportPlan._(
      accounts: db.accounts.toList(),
      categories: db.categories.toList(),
      quickMovements: db.quickMovements.toList(),
      favoriteMovements: db.favoriteMovements.toList(),
      movements: db.movements.toList(),
    );
  }

  OneMoneyCsvImportReport buildReport() => OneMoneyCsvImportReport(
        movementsRead: movementsRead,
        importedMovements: importedMovements,
        duplicateMovements: duplicateMovements,
        duplicateDbMovements: duplicateDbMovements,
        duplicateWithinFileMovements: duplicateWithinFileMovements,
        duplicateWithinFileImportedMovements: duplicateWithinFileImportedMovements,
        accountsCreated: accountsCreated,
        categoriesCreated: categoriesCreated,
        errors: List.unmodifiable(errors),
      );

  bool isDbDuplicate(String fingerprint) {
    return _dbFingerprints.contains(fingerprint);
  }

  bool isWithinFileDuplicate(String fingerprint) {
    return _fileFingerprints.contains(fingerprint);
  }

  bool markWithinFileFingerprint(String fingerprint) {
    return _fileFingerprints.add(fingerprint);
  }

  void unmarkWithinFileFingerprint(String fingerprint) {
    _fileFingerprints.remove(fingerprint);
  }

  String fingerprintFor(_ParsedOneMoneyRow row) {
    final type = row.type!;
    final sourceKey = _normalizedAccountKey(row.sourceAccount);
    final targetKey = _normalizeText(row.targetLabel);
    final targetFingerprint = type == MovementType.transfer
        ? targetKey
        : _normalizeText(row.targetLabel);
    return [
      _dateOnly(row.date!),
      type.name,
      _fingerprintAmount(row.amount!),
      sourceKey,
      targetFingerprint,
      _normalizeText(row.note),
    ].join('|');
  }

  String fingerprintForMovement(Movement movement) {
    final source = _accountsById[movement.accountId]?.name ?? movement.accountId;
    final target = movement.type == MovementType.transfer
        ? (_accountsById[movement.destinationAccountId ?? '']?.name ??
            movement.destinationAccountId ??
            '')
        : (_categoriesById[movement.categoryId]?.name ?? movement.categoryId);
    return [
      _dateOnly(movement.date),
      movement.type.name,
      _fingerprintAmount(movement.amount),
      _normalizedAccountKey(source),
      _normalizeText(target),
      _normalizeText(movement.note ?? ''),
    ].join('|');
  }

  Movement? importRow(_ParsedOneMoneyRow row) {
    if (!row.isValid) {
      errors.add('Riga ${row.lineNumber}: ${row.error}');
      return null;
    }

    final type = row.type!;
    final sourceAccount = _ensureAccount(row.sourceAccount);
    if (sourceAccount == null) {
      errors.add('Riga ${row.lineNumber}: conto sorgente non valido "${row.sourceAccount}"');
      return null;
    }

    Category? category;
    Account? destinationAccount;
    if (type == MovementType.transfer) {
      destinationAccount = _ensureAccount(row.targetLabel);
      if (destinationAccount == null) {
        errors.add('Riga ${row.lineNumber}: conto destinazione non valido "${row.targetLabel}"');
        return null;
      }
    } else {
      category = _ensureCategory(row.targetLabel, type);
      if (category == null) {
        errors.add('Riga ${row.lineNumber}: categoria non valida "${row.targetLabel}"');
        return null;
      }
    }

    final now = DateTime.now();
    final movement = Movement(
      id: _newId('imp_mv'),
      title: row.title,
      amount: row.amount!,
      type: type,
      date: row.date!,
      categoryId: type == MovementType.transfer ? '' : category!.id,
      accountId: sourceAccount.id,
      destinationAccountId: destinationAccount?.id,
      note: row.note,
      createdAt: now,
      updatedAt: now,
    );

    movements.add(movement);
    createdMovements.add(movement);
    return movement;
  }

  Account? _ensureAccount(String rawName) {
    final normalized = _normalizedAccountKey(rawName);
    final existing = _accountsByName[normalized];
    if (existing != null) return existing;

    final now = DateTime.now();
    final account = Account(
      id: _newId('imp_acc'),
      name: rawName.trim(),
      type: AccountType.bank,
      iconKey: StreamIconLibrary.defaultAccountIcon,
      color: StreamColorPalette.getDefault(),
      createdAt: now,
      updatedAt: now,
    );
    accounts.add(account);
    createdAccounts.add(account);
    accountsCreated++;
    _accountsByName[normalized] = account;
    _accountsById[account.id] = account;
    return account;
  }

  Category? _ensureCategory(String rawName, MovementType type) {
    final normalized = _categoryKey(type, rawName);
    final existing = _categoriesByKey[normalized];
    if (existing != null) return existing;

    final category = Category(
      id: _newId('imp_cat'),
      name: rawName.trim(),
      type: type,
      color: StreamColorPalette.getDefault(),
      iconKey: StreamIconLibrary.defaultCategoryIcon,
    );
    categories.add(category);
    createdCategories.add(category);
    categoriesCreated++;
    _categoriesByKey[normalized] = category;
    _categoriesById[category.id] = category;
    return category;
  }

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${createdMovements.length + createdAccounts.length + createdCategories.length}';
  }
}

String _normalizedAccountKey(String value) {
  return _normalizeText(value);
}

String _categoryKey(MovementType type, String value) {
  return '${type.name}|${_normalizeText(value)}';
}

class _CsvParser {
  final List<List<String>> rows;
  final String delimiter;

  const _CsvParser._(this.rows, this.delimiter);

  static _CsvParser parse(String input) {
    final normalized = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final trimmed = normalized.startsWith('\uFEFF')
        ? normalized.substring(1)
        : normalized;
    final delimiter = _detectDelimiter(trimmed);
    final rows = _parseRows(trimmed, delimiter);
    return _CsvParser._(rows, delimiter);
  }

  static String _detectDelimiter(String input) {
    final lines = input.split('\n').where((line) => line.trim().isNotEmpty);
    final firstLine = lines.isEmpty ? '' : lines.first;
    if (firstLine.isEmpty) return ';';

    var bestDelimiter = ';';
    var bestScore = -1;
    for (final delimiter in [';', ',', '\t']) {
      final score = _countOutsideQuotes(firstLine, delimiter);
      if (score > bestScore) {
        bestScore = score;
        bestDelimiter = delimiter;
      }
    }
    return bestDelimiter;
  }

  static int _countOutsideQuotes(String input, String delimiter) {
    var count = 0;
    var inQuotes = false;
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (!inQuotes && char == delimiter) {
        count++;
      }
    }
    return count;
  }

  static List<List<String>> _parseRows(String input, String delimiter) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    void commitField() {
      currentRow.add(buffer.toString());
      buffer.clear();
    }

    void commitRow() {
      if (currentRow.isEmpty) return;
      rows.add(List<String>.from(currentRow));
      currentRow.clear();
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (!inQuotes && char == delimiter) {
        commitField();
        continue;
      }

      if (!inQuotes && char == '\n') {
        commitField();
        if (!_rowIsEmpty(currentRow)) {
          commitRow();
        } else {
          currentRow.clear();
        }
        continue;
      }

      buffer.write(char);
    }

    commitField();
    if (!_rowIsEmpty(currentRow)) {
      commitRow();
    }

    return rows;
  }
}
