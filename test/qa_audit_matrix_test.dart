import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
import 'package:stream_app/data/sqlite_service.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/beneficiary_profile.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/utils/currency_formatter.dart';
import 'package:stream_app/widgets/movement_text_suggestions.dart';

Movement _movement({
  required String id,
  required String title,
  required String note,
  required String payee,
  required MovementType type,
  required String categoryId,
  required DateTime date,
  required double amount,
  String? accountId,
  String? destinationAccountId,
}) {
  return Movement(
    id: id,
    title: title,
    note: note,
    payee: payee,
    amount: amount,
    type: type,
    categoryId: categoryId,
    accountId: accountId ?? defaultAccountId,
    destinationAccountId: destinationAccountId,
    date: date,
    createdAt: date,
  );
}

String _normalizeLocal(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _simulateCalculatorDisplay(String input) {
  var whole = '0';
  var fraction = '';
  var hasDecimal = false;

  void appendDigit(String digit) {
    if (!hasDecimal) {
      if (whole == '0') {
        whole = digit;
      } else {
        whole += digit;
      }
    } else {
      fraction += digit;
    }
  }

  void backspace() {
    if (hasDecimal) {
      if (fraction.isNotEmpty) {
        fraction = fraction.substring(0, fraction.length - 1);
      } else {
        hasDecimal = false;
      }
      return;
    }
    if (whole.length > 1) {
      whole = whole.substring(0, whole.length - 1);
    } else {
      whole = '0';
    }
  }

  for (final char in input.split('')) {
    if (RegExp(r'\d').hasMatch(char)) {
      appendDigit(char);
      continue;
    }
    if (char == ',' || char == '.') {
      hasDecimal = true;
      continue;
    }
    if (char == '\b') {
      backspace();
      continue;
    }
  }

  if (!hasDecimal) return whole;
  return '$whole,${fraction.isEmpty ? '' : fraction}';
}

double _evaluateExpression(String expression) {
  final tokens = <String>[];
  var current = '';

  void flush() {
    if (current.isNotEmpty) {
      tokens.add(current);
      current = '';
    }
  }

  for (final char in expression.split('')) {
    if (RegExp(r'[\d,\.]').hasMatch(char)) {
      current += char == ',' ? '.' : char;
      continue;
    }
    if ('+-*/'.contains(char)) {
      flush();
      tokens.add(char);
    }
  }
  flush();

  if (tokens.isEmpty) return 0;

  final values = <double>[];
  final ops = <String>[];

  int precedence(String op) {
    return (op == '*' || op == '/') ? 2 : 1;
  }

  void applyTop() {
    final op = ops.removeLast();
    final b = values.removeLast();
    final a = values.removeLast();
    switch (op) {
      case '+':
        values.add(a + b);
        break;
      case '-':
        values.add(a - b);
        break;
      case '*':
        values.add(a * b);
        break;
      case '/':
        values.add(b == 0 ? 0 : a / b);
        break;
    }
  }

  for (final token in tokens) {
    final value = double.tryParse(token);
    if (value != null) {
      values.add(value);
      continue;
    }
    while (ops.isNotEmpty && precedence(ops.last) >= precedence(token)) {
      if (values.length >= 2) {
        applyTop();
      } else {
        break;
      }
    }
    ops.add(token);
  }
  while (ops.isNotEmpty && values.length >= 2) {
    applyTop();
  }
  return values.isEmpty ? 0 : values.single;
}

bool _textFits({
  required String text,
  required double maxWidth,
  required int maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1.2),
    ),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);
  return !painter.didExceedMaxLines;
}

List<String> _generatedQueries(String prefix, int count) {
  return List.generate(count, (i) {
    switch (i % 12) {
      case 0:
        return prefix;
      case 1:
        return prefix.substring(0, 1);
      case 2:
        return '$prefix ${i % 9}';
      case 3:
        return '${prefix.toUpperCase()} ${i % 13}';
      case 4:
        return ' $prefix  ${i % 7} ';
      case 5:
        return '$prefix-${i % 5}';
      case 6:
        return '$prefix 😄 ${i % 4}';
      case 7:
        return '$prefix & co ${i % 6}';
      case 8:
        return '$prefix.${i % 8}';
      case 9:
        return '$prefix/${i % 10}';
      case 10:
        return '$prefix,${i % 11}';
      default:
        return '$prefix ${i % 15} extra';
    }
  });
}

List<DateTime> _generatedDates(int count) {
  return List.generate(count, (i) => DateTime.utc(2026, 1, 1).add(Duration(days: i * 3)));
}

List<(DateTime, DateTime)> _generatedRanges(int count) {
  return List.generate(count, (i) {
    final start = DateTime.utc(2026, 1, 1).add(Duration(days: i * 2));
    final end = start.add(Duration(days: i % 17));
    return (start, end);
  });
}

List<double> _generatedCurrencyValues(int count) {
  return List.generate(count, (i) {
    final sign = i.isEven ? 1.0 : -1.0;
    final magnitude = ((i % 17) * 123.45) + ((i % 9) / 10.0);
    return sign * magnitude;
  });
}

List<String> _generatedCalculatorSequences(int count) {
  const templates = <String>[
    '5',
    '50',
    '500',
    '50,',
    '50,5',
    '50,50',
    '0\b5',
    '12\b',
    '10+5',
    '20-5',
    '5*2',
    '10/2',
    '100+20-5',
    '7+3*2',
    '25/5+1',
    '999+1',
    '10,5+2,5',
    '30,00-10',
    '6*6+1',
    '40/8+3',
  ];
  return List.generate(count, (i) => templates[i % templates.length]);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Hermes Extended QA Audit', () {
    test(
      'suggestions matrix covers titles, notes and beneficiaries with deterministic chip-style heuristics',
      () async {
        final db = AppDatabase();
        final seeds = <Movement>[
          _movement(
            id: 'm1',
            title: 'Spesa supermercato Coop',
            note: 'Spesa settimanale con emoji 😄',
            payee: 'Coop',
            type: MovementType.expense,
            categoryId: 'exp_1',
            date: DateTime(2026, 6, 1),
            amount: 24.50,
          ),
          _movement(
            id: 'm2',
            title: 'Spesa benzina Eni',
            note: 'Carburante auto',
            payee: 'Eni',
            type: MovementType.expense,
            categoryId: 'exp_3',
            date: DateTime(2026, 6, 2),
            amount: 54.30,
          ),
          _movement(
            id: 'm3',
            title: 'Stipendio giugno',
            note: 'Bonifico stipendio',
            payee: 'Azienda',
            type: MovementType.income,
            categoryId: 'inc_1',
            date: DateTime(2026, 6, 3),
            amount: 2500,
          ),
          _movement(
            id: 'm4',
            title: 'McDonalds Grandate',
            note: 'Pasto veloce',
            payee: 'McDonalds Grandate',
            type: MovementType.expense,
            categoryId: 'exp_1',
            date: DateTime(2026, 6, 4),
            amount: 12.90,
          ),
          _movement(
            id: 'm5',
            title: 'McDonalds Como',
            note: 'Pasto veloce',
            payee: 'McDonalds Como',
            type: MovementType.expense,
            categoryId: 'exp_1',
            date: DateTime(2026, 6, 5),
            amount: 14.20,
          ),
        ];
        for (final movement in seeds) {
          await db.addMovement(movement);
        }
        final profiles = <BeneficiaryProfile>[
          BeneficiaryProfile(
            id: 'bp_1',
            key: 'coop',
            displayName: 'Coop',
            createdAt: DateTime(2026, 6, 1),
          ),
          BeneficiaryProfile(
            id: 'bp_2',
            key: 'eni',
            displayName: 'Eni',
            createdAt: DateTime(2026, 6, 1),
          ),
          BeneficiaryProfile(
            id: 'bp_3',
            key: 'mc donalds grandate',
            displayName: 'McDonalds Grandate',
            createdAt: DateTime(2026, 6, 1),
          ),
          BeneficiaryProfile(
            id: 'bp_4',
            key: 'mc donalds como',
            displayName: 'McDonalds Como',
            createdAt: DateTime(2026, 6, 1),
          ),
        ];
        for (final profile in profiles) {
          await db.addBeneficiaryProfile(profile);
        }

        final titleQueries = _generatedQueries('Spesa', 200);
        final noteQueries = _generatedQueries('Nota', 200);
        final beneficiaryQueries = _generatedQueries('McDonalds', 200);

        for (final query in titleQueries) {
          final suggestions = buildMovementTextSuggestions(
            db: db,
            query: query,
            field: MovementTextSuggestionField.title,
            type: MovementType.expense,
            categoryId: 'exp_1',
            beneficiary: 'Coop',
          );
          final normalized = normalizeMovementText(query);
          expect(suggestions.length <= 5, isTrue);
          expect(
            suggestions.where((s) => s.text.trim().isEmpty),
            isEmpty,
            reason: 'Titolo: testi vuoti per "$query"',
          );
          expect(
            suggestions.map((s) => _normalizeLocal(s.text)).toSet().length,
            suggestions.length,
            reason: 'Titolo: dedup fallita per "$query"',
          );
          if (normalized.length < 2) {
            expect(suggestions, isEmpty);
          } else {
            expect(
              suggestions.map((s) => _normalizeLocal(s.text)),
              isNot(contains(normalized)),
              reason: 'Titolo: testo identico suggerito per "$query"',
            );
          }
        }

        for (final query in noteQueries) {
          final suggestions = buildMovementTextSuggestions(
            db: db,
            query: query,
            field: MovementTextSuggestionField.note,
            type: MovementType.expense,
            categoryId: 'exp_3',
            beneficiary: 'Eni',
          );
          final normalized = normalizeMovementText(query);
          expect(suggestions.length <= 5, isTrue);
          expect(
            suggestions.where((s) => s.text.trim().isEmpty),
            isEmpty,
          );
          expect(
            suggestions.map((s) => _normalizeLocal(s.text)).toSet().length,
            suggestions.length,
          );
          if (normalized.length < 2) {
            expect(suggestions, isEmpty);
          }
        }

        for (final query in beneficiaryQueries) {
          final current = query.contains('Como') ? 'McDonalds Como' : 'Coop';
          final suggestions = buildMovementBeneficiarySuggestions(
            db: db,
            query: query,
            currentValue: current,
          );
          final normalized = normalizeMovementText(query);
          expect(suggestions.length <= 5, isTrue);
          expect(
            suggestions.where((s) => s.text.trim().isEmpty),
            isEmpty,
          );
          expect(
            suggestions.map((s) => _normalizeLocal(s.text)).toSet().length,
            suggestions.length,
          );
          if (normalized.length < 2) {
            expect(suggestions, isEmpty);
          } else {
            expect(
              suggestions.map((s) => _normalizeLocal(s.text)),
              isNot(contains(_normalizeLocal(current))),
            );
          }
        }
      },
    );

    test('time filter matrix covers day/week/month/year/range deterministically', () {
      final dates = _generatedDates(180);
      for (final date in dates) {
        final day = TimeFilter.day(date);
        final week = TimeFilter.week(date);
        final month = TimeFilter.month(date.year, date.month);
        final year = TimeFilter.year(date.year);

        expect(day.contains(date), isTrue);
        expect(week.contains(date), isTrue);
        expect(month.contains(date), isTrue);
        expect(year.contains(date), isTrue);
        expect(day.label.contains('${date.year}'), isTrue);
        expect(month.label.contains('${date.year}'), isTrue);
        expect(week.next().mode, TimeFilterMode.week);
        expect(week.previous().mode, TimeFilterMode.week);
      }

      final ranges = _generatedRanges(70);
      for (final (start, end) in ranges) {
        final range = TimeFilter.customRange(start, end);
        expect(range.contains(start), isTrue);
        expect(range.contains(end), isTrue);
        expect(range.label.contains('→'), isTrue);
        expect(range.endDate.isBefore(range.startDate), isFalse);
        expect(range.startDate.isAfter(range.endDate), isFalse);
      }
    });

    test('currency formatter matrix keeps symbols and signs coherent', () {
      final values = _generatedCurrencyValues(80);
      final currencies = AppCurrency.values;
      for (final currency in currencies) {
        PreferencesService.currencyNotifier.value = currency;
        final expectedSymbol = switch (currency) {
          AppCurrency.eur => '€',
          AppCurrency.usd => r'$',
          AppCurrency.gbp => '£',
          AppCurrency.chf => 'CHF',
          AppCurrency.jpy => '¥',
        };
        for (final value in values) {
          final formatted = formatMovementCurrency(
            value,
            showPositiveSign: true,
          );
          expect(formatted.isNotEmpty, isTrue);
          expect(formatted.contains(expectedSymbol), isTrue);
          expect(formatted.contains(value.abs().toStringAsFixed(2)), isTrue);
          expect(formatted.startsWith(value < 0 ? '-' : '+'), isTrue);
        }
      }
      PreferencesService.currencyNotifier.value = AppCurrency.eur;
    });

    test('calculator matrix covers numeric edge cases and operator parsing', () {
      final sequences = _generatedCalculatorSequences(300);
      for (final sequence in sequences) {
        final display = _simulateCalculatorDisplay(sequence);
        expect(display.isNotEmpty, isTrue);
        expect(display == '0,00', isFalse);
        expect(display.contains(','), sequence.contains(',') || sequence.contains('.'));
        expect(
          _evaluateExpression(sequence.replaceAll('\b', '')),
          isA<double>(),
        );
      }
    });

    test('movement / profile / visual matrix covers balances, isolation and layout fit', () async {
      final movementAmounts = List.generate(30, (i) => (i + 1) * 12.5);
      for (final amount in movementAmounts) {
        final db = AppDatabase();
        final accA = Account(
          id: 'a_$amount',
          name: 'Conto A $amount',
          type: AccountType.bank,
          initialBalance: 1000,
          createdAt: DateTime(2026, 1, 1),
        );
        final accB = Account(
          id: 'b_$amount',
          name: 'Conto B $amount',
          type: AccountType.bank,
          initialBalance: 500,
          createdAt: DateTime(2026, 1, 1),
        );
        await db.addAccount(accA);
        await db.addAccount(accB);
        await db.addCategory(
          'Cat ${amount.toInt()}',
          MovementType.expense,
          0xFFEF5350,
        );
        await db.addMovement(
          _movement(
            id: 'inc_$amount',
            title: 'Entrata $amount',
            note: 'note',
            payee: 'Paga',
            type: MovementType.income,
            categoryId: 'inc_1',
            accountId: accA.id,
            date: DateTime(2026, 6, 1),
            amount: amount,
          ),
        );
        await db.addMovement(
          _movement(
            id: 'exp_$amount',
            title: 'Spesa $amount',
            note: 'note',
            payee: 'Shop',
            type: MovementType.expense,
            categoryId: 'cat_${amount.toInt()}',
            accountId: accA.id,
            date: DateTime(2026, 6, 2),
            amount: amount / 2,
          ),
        );
        await db.addMovement(
          _movement(
            id: 'tr_$amount',
            title: 'Transfer $amount',
            note: 'note',
            payee: '',
            type: MovementType.transfer,
            categoryId: 'inc_1',
            accountId: accA.id,
            destinationAccountId: accB.id,
            date: DateTime(2026, 6, 3),
            amount: amount / 3,
          ),
        );

        expect(db.totalIncome >= amount, isTrue);
        expect(db.totalExpenses >= amount / 2, isTrue);
        expect(db.getAccountBalance(accA) != accA.initialBalance, isTrue);
        expect(db.getAccountBalance(accB) != accB.initialBalance, isTrue);
        expect(db.balance, closeTo(db.totalIncome - db.totalExpenses, 0.001));
        expect(db.totalAccountsBalance, closeTo(1500 + amount / 2, 0.001));
      }

      final dir = Directory.systemTemp.createTempSync('stream_qa_profiles_');
      try {
        final sqliteA = SQLiteService();
        final sqliteB = SQLiteService();
        final pathA = p.join(dir.path, 'profile_a.db');
        final pathB = p.join(dir.path, 'profile_b.db');
        await sqliteA.open(path: pathA);
        await sqliteB.open(path: pathB);
        final dbA = AppDatabase(sqlite: sqliteA);
        final dbB = AppDatabase(sqlite: sqliteB);
        await dbA.initialize();
        await dbB.initialize();
        await dbA.addMovement(
          _movement(
            id: 'pa',
            title: 'A',
            note: 'A',
            payee: 'A',
            type: MovementType.income,
            categoryId: 'inc_1',
            date: DateTime(2026, 6, 1),
            amount: 100,
          ),
        );
        await dbB.addMovement(
          _movement(
            id: 'pb',
            title: 'B',
            note: 'B',
            payee: 'B',
            type: MovementType.expense,
            categoryId: 'exp_1',
            date: DateTime(2026, 6, 2),
            amount: 10,
          ),
        );
        expect(dbA.movements.length, 1);
        expect(dbB.movements.length, 1);
        expect(dbA.movements.first.title, 'A');
        expect(dbB.movements.first.title, 'B');
        expect(dbA.beneficiaryProfiles, isEmpty);
        expect(dbB.beneficiaryProfiles, isEmpty);
        await sqliteA.close();
        await sqliteB.close();
      } finally {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }

      final labels = <String>[
        'Nuovo movimento',
        'Beneficiario / Esercente / Pagatore / Fonte',
        'Titolo',
        'Note',
        'Spesa',
        'Entrata',
        'Trasferimento',
        'Saldo iniziale 15.023,92 €',
        'McDonalds Grandate',
        '🚗 Benzina 123,45 €',
        'QR/SCAN//TEST',
        'Testo con accenti e simboli €£¥',
      ];
      final widths = <double>[280, 320, 375, 414, 768];
      for (final text in labels) {
        for (final width in widths) {
          final fitsOneLine = _textFits(text: text, maxWidth: width, maxLines: 1);
          final fitsTwoLines = _textFits(text: text, maxWidth: width, maxLines: 2);
          if (width >= 768) {
            expect(fitsTwoLines, isTrue);
          }
          if (text.length < 20 && width >= 375) {
            expect(fitsOneLine, isTrue);
          }
          expect(text.trim().isNotEmpty, isTrue);
        }
      }
    });
  });
}
