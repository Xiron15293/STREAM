import 'package:flutter_test/flutter_test.dart';

import 'package:stream_app/data/database.dart';
import 'package:stream_app/data/preferences_service.dart';
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
}) {
  return Movement(
    id: id,
    title: title,
    note: note,
    payee: payee,
    amount: 10.0,
    type: type,
    categoryId: categoryId,
    date: date,
    createdAt: date,
  );
}

void main() {
  group('QA audit matrix', () {
    test('movement suggestion matrix covers titles, notes and beneficiaries', () {
      final db = AppDatabase();
      final seed = <Movement>[
        _movement(
          id: 'm1',
          title: 'Spesa supermercato',
          note: 'Note spesa settimanale',
          payee: 'Coop',
          type: MovementType.expense,
          categoryId: 'exp_1',
          date: DateTime(2026, 6, 1),
        ),
        _movement(
          id: 'm2',
          title: 'Spesa benzina',
          note: 'Note carburante',
          payee: 'Eni',
          type: MovementType.expense,
          categoryId: 'exp_3',
          date: DateTime(2026, 6, 2),
        ),
        _movement(
          id: 'm3',
          title: 'Stipendio giugno',
          note: 'Bonifico stipendio',
          payee: 'Azienda',
          type: MovementType.income,
          categoryId: 'inc_1',
          date: DateTime(2026, 6, 3),
        ),
      ];
      for (final movement in seed) {
        db.addMovement(movement);
      }
      db.addBeneficiaryProfile(
        BeneficiaryProfile(
          id: 'bp_1',
          key: 'coop',
          displayName: 'Coop',
          createdAt: DateTime(2026, 6, 4),
        ),
      );
      db.addBeneficiaryProfile(
        BeneficiaryProfile(
          id: 'bp_2',
          key: 'mc donalds grandate',
          displayName: 'McDonalds Grandate',
          createdAt: DateTime(2026, 6, 4),
        ),
      );

      final titleCases = <String>[
        'Sp',
        'spe',
        'spesa',
        'benz',
        'stip',
        'spesa ',
      ];
      for (final query in titleCases) {
        final suggestions = buildMovementTextSuggestions(
          db: db,
          query: query,
          field: MovementTextSuggestionField.title,
          type: MovementType.expense,
          categoryId: 'exp_1',
          beneficiary: 'Coop',
        );
        expect(
          suggestions.length <= 5,
          isTrue,
          reason: 'Titolo: troppi suggerimenti per "$query"',
        );
        expect(
          suggestions.map((s) => s.text.toLowerCase()).toSet().length,
          suggestions.length,
          reason: 'Titolo: duplicati per "$query"',
        );
      }

      final noteCases = <String>['no', 'not', 'nota', 'carb', 'stip', 'note sp'];
      for (final query in noteCases) {
        final suggestions = buildMovementTextSuggestions(
          db: db,
          query: query,
          field: MovementTextSuggestionField.note,
          type: MovementType.expense,
          categoryId: 'exp_3',
          beneficiary: 'Eni',
        );
        expect(suggestions.length <= 5, isTrue);
        expect(
          suggestions.where((s) => s.text.trim().isEmpty),
          isEmpty,
          reason: 'Note: suggeriti testi vuoti per "$query"',
        );
      }

      final beneficiaryCases = <String>[
        'co',
        'coop',
        'mc',
        'mcd',
        'azienda',
        'grand',
        'grandate',
      ];
      for (final query in beneficiaryCases) {
        final suggestions = buildMovementBeneficiarySuggestions(
          db: db,
          query: query,
          currentValue: 'Coop',
        );
        expect(suggestions.length <= 5, isTrue);
        expect(
          suggestions.map((s) => normalizeMovementText(s.text)).toSet().length,
          suggestions.length,
        );
        expect(
          suggestions.map((s) => normalizeMovementText(s.text)),
          isNot(contains(normalizeMovementText('Coop'))),
          reason: 'Beneficiario corrente non deve essere suggerito',
        );
      }
    });

    test('time filter matrix stays coherent across modes and ranges', () {
      final dates = <DateTime>[
        DateTime(2026, 1, 1),
        DateTime(2026, 2, 14),
        DateTime(2026, 3, 31),
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 15),
        DateTime(2026, 7, 30),
        DateTime(2026, 12, 31),
      ];

      for (final date in dates) {
        final day = TimeFilter.day(date);
        expect(day.contains(date), isTrue);
        expect(day.label.contains('${date.year}'), isTrue);

        final week = TimeFilter.week(date);
        expect(week.contains(date), isTrue);
        expect(week.next().startDate.isAfter(week.startDate), isTrue);
        expect(week.previous().startDate.isBefore(week.startDate), isTrue);

        final month = TimeFilter.month(date.year, date.month);
        expect(month.contains(date), isTrue);
        expect(month.label.contains('${date.year}'), isTrue);

        final year = TimeFilter.year(date.year);
        expect(year.contains(date), isTrue);
      }

      final ranges = <(DateTime, DateTime)>[
        (DateTime(2026, 6, 16), DateTime(2026, 6, 16)),
        (DateTime(2026, 6, 16), DateTime(2026, 6, 18)),
        (DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
      ];
      for (final (start, end) in ranges) {
        final range = TimeFilter.customRange(start, end);
        expect(range.contains(start), isTrue);
        expect(range.contains(end), isTrue);
        expect(range.label.contains('→'), isTrue);
        expect(range.endDate.isBefore(range.startDate), isFalse);
      }
    });

    test('currency formatter matrix keeps symbol and sign coherent', () {
      final currencies = AppCurrency.values;
      final values = <double>[
        -1250.5,
        -1.0,
        0.0,
        1.0,
        12.34,
        9999.99,
      ];

      for (final currency in currencies) {
        PreferencesService.currencyNotifier.value = currency;
        for (final value in values) {
          final formatted = formatMovementCurrency(
            value,
            showPositiveSign: true,
          );
          expect(formatted.contains(' '), isTrue);
          expect(formatted.isNotEmpty, isTrue);
          if (value < 0) {
            expect(formatted.startsWith('-'), isTrue);
          } else {
            expect(formatted.startsWith('+'), isTrue);
          }
        }
      }
      PreferencesService.currencyNotifier.value = AppCurrency.eur;
    });

    test('beneficiary normalization matrix keeps exact and similar values separate', () {
      final db = AppDatabase();
      db.addBeneficiaryProfile(
        BeneficiaryProfile(
          id: 'b1',
          key: 'adidas',
          displayName: 'Adidas',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      db.addBeneficiaryProfile(
        BeneficiaryProfile(
          id: 'b2',
          key: 'mc donalds grandate',
          displayName: 'McDonalds Grandate',
          createdAt: DateTime(2026, 1, 2),
        ),
      );
      db.addBeneficiaryProfile(
        BeneficiaryProfile(
          id: 'b3',
          key: 'mc donalds como',
          displayName: 'McDonalds Como',
          createdAt: DateTime(2026, 1, 3),
        ),
      );

      final queries = <String>[
        'ad',
        'adi',
        'adid',
        'mc',
        'mcd',
        'grand',
        'como',
        'donalds',
      ];
      for (final query in queries) {
        final suggestions = buildMovementBeneficiarySuggestions(
          db: db,
          query: query,
          currentValue: '',
        );
        expect(suggestions.length <= 5, isTrue);
        expect(
          suggestions.map((s) => normalizeMovementText(s.text)).toSet().length,
          suggestions.length,
        );
      }

      final similar = buildMovementBeneficiarySuggestions(
        db: db,
        query: 'mc don',
        currentValue: '',
      );
      expect(similar.any((s) => s.text == 'McDonalds Grandate'), isTrue);
      expect(similar.any((s) => s.text == 'McDonalds Como'), isTrue);
      expect(
        similar.map((s) => s.text).contains('Adidas'),
        isFalse,
      );
    });
  });
}
