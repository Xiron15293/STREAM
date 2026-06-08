import 'package:flutter_test/flutter_test.dart';
import 'package:stream_app/models/account.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/daily_group.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';
import 'package:stream_app/utils/movement_search.dart';

void main() {
  final categories = <Category>[
    const Category(
      id: 'cat_spesa',
      name: 'Spesa',
      type: MovementType.expense,
      color: 0xFF2E7D32,
    ),
    const Category(
      id: 'cat_casa',
      name: 'Casa',
      type: MovementType.expense,
      color: 0xFF1565C0,
    ),
    const Category(
      id: 'cat_stipendio',
      name: 'Stipendio',
      type: MovementType.income,
      color: 0xFF6A1B9A,
    ),
  ];

  final accounts = <Account>[
    Account(
      id: 'acc_postepay',
      name: 'Postepay',
      type: AccountType.card,
      color: 0xFFE65100,
      createdAt: DateTime(2026, 1, 1),
    ),
    Account(
      id: 'acc_iban',
      name: 'Conto Principale',
      type: AccountType.bank,
      color: 0xFF455A64,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  Movement movement({
    required String id,
    required String title,
    required double amount,
    required MovementType type,
    required DateTime date,
    required String categoryId,
    required String accountId,
    String? destinationAccountId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Movement(
      id: id,
      title: title,
      amount: amount,
      type: type,
      date: date,
      categoryId: categoryId,
      accountId: accountId,
      destinationAccountId: destinationAccountId,
      note: note,
      createdAt: createdAt ?? date,
      updatedAt: updatedAt,
    );
  }

  group('movement search', () {
    test('1. cerca per titolo', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Esselunga',
          amount: 42,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
        movement(
          id: 'm2',
          title: 'Amazon',
          amount: 19,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'Esselunga',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('2. cerca case-insensitive', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Amazon',
          amount: 19,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'amazon',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('3. cerca per match parziale', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Benzina',
          amount: 55,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'benz',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('4. cerca per nota', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Varie',
          amount: 12,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
          note: 'Spesa grande al supermercato',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'supermercato',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('4b. cerca trasferimento per conto origine e destinazione', () {
      final movements = [
        movement(
          id: 't1',
          title: 'Trasferimento regalo',
          amount: 75,
          type: MovementType.transfer,
          date: DateTime(2026, 6, 15),
          categoryId: '',
          accountId: 'acc_postepay',
          destinationAccountId: 'acc_iban',
          note: 'Spostamento saldo',
        ),
      ];

      final byOrigin = searchMovements(
        movements: movements,
        query: 'postepay',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );
      final byDestination = searchMovements(
        movements: movements,
        query: 'conto principale',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(byOrigin.map((m) => m.id), ['t1']);
      expect(byDestination.map((m) => m.id), ['t1']);
    });

    test('5. cerca per categoria', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Buono pasto',
          amount: 10,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'Spesa',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('6. cerca per conto', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Pagamento',
          amount: 10,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'Postepay',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('6b. cerca trasferimento per nota e match parziale', () {
      final movements = [
        movement(
          id: 't1',
          title: 'Giroconto carta',
          amount: 20,
          type: MovementType.transfer,
          date: DateTime(2026, 6, 15),
          categoryId: '',
          accountId: 'acc_iban',
          destinationAccountId: 'acc_postepay',
          note: 'Ricarica carta prepagata',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'ricarica',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['t1']);
    });

    test('7. query senza risultati', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Esselunga',
          amount: 42,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'inesistente',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result, isEmpty);
    });

    test('8. query con spazi iniziali e finali', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Amazon',
          amount: 19,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: '  Amazon  ',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('9. ricerca combinata con filtro mese', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Benzina giugno',
          amount: 50,
          type: MovementType.expense,
          date: DateTime(2026, 6, 10),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
        movement(
          id: 'm2',
          title: 'Benzina luglio',
          amount: 60,
          type: MovementType.expense,
          date: DateTime(2026, 7, 10),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'benz',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('10. ricerca combinata con periodo custom', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Affitto giugno',
          amount: 700,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_casa',
          accountId: 'acc_iban',
        ),
        movement(
          id: 'm2',
          title: 'Affitto luglio',
          amount: 700,
          type: MovementType.expense,
          date: DateTime(2026, 7, 1),
          categoryId: 'cat_casa',
          accountId: 'acc_iban',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: 'affitto',
        filter: TimeFilter.customRange(
          DateTime(2026, 6, 10),
          DateTime(2026, 6, 30),
        ),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['m1']);
    });

    test('11. risultati raggruppati per giorno', () {
      final movements = [
        movement(
          id: 'm1',
          title: 'Primo',
          amount: 10,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
        movement(
          id: 'm2',
          title: 'Secondo',
          amount: 20,
          type: MovementType.expense,
          date: DateTime(2026, 6, 16),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
        movement(
          id: 'm3',
          title: 'Terzo',
          amount: 30,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: '',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );
      final groups = groupMovementsByDay(result);

      expect(groups.length, 2);
      expect(groups.map((g) => g.date.day), [16, 15]);
      expect(groups[0].movements.map((m) => m.id), ['m2']);
      expect(groups[1].movements.map((m) => m.id), ['m1', 'm3']);
    });

    test('12. ordinamento coerente con compareMovementsForDisplay', () {
      final movements = [
        movement(
          id: 'a',
          title: 'Primo',
          amount: 10,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
          createdAt: DateTime(2026, 6, 15, 10),
          updatedAt: DateTime(2026, 6, 15, 12),
        ),
        movement(
          id: 'b',
          title: 'Secondo',
          amount: 20,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
          createdAt: DateTime(2026, 6, 15, 11),
          updatedAt: DateTime(2026, 6, 15, 12),
        ),
        movement(
          id: 'c',
          title: 'Terzo',
          amount: 30,
          type: MovementType.expense,
          date: DateTime(2026, 6, 15),
          categoryId: 'cat_spesa',
          accountId: 'acc_postepay',
          createdAt: DateTime(2026, 6, 15, 9),
          updatedAt: DateTime(2026, 6, 15, 13),
        ),
      ];

      final result = searchMovements(
        movements: movements,
        query: '',
        filter: TimeFilter.day(DateTime(2026, 6, 15)),
        categories: categories,
        accounts: accounts,
      );

      expect(result.map((m) => m.id), ['c', 'b', 'a']);
    });

    test('13. dataset grande da 1000 movimenti', () {
      final largeMovements = List.generate(1000, (index) {
        final day = (index % 28) + 1;
        return movement(
          id: 'm$index',
          title: 'Movimento $index',
          amount: index.toDouble(),
          type: index.isEven ? MovementType.expense : MovementType.income,
          date: DateTime(2026, 6, day),
          categoryId: index.isEven ? 'cat_spesa' : 'cat_stipendio',
          accountId: index.isEven ? 'acc_postepay' : 'acc_iban',
          note: index % 100 == 0 ? 'special $index' : 'nota $index',
        );
      });

      final result = searchMovements(
        movements: largeMovements,
        query: 'special',
        filter: TimeFilter.month(2026, 6),
        categories: categories,
        accounts: accounts,
      );

      expect(result.length, 10);
      expect(result.every((m) => m.note?.contains('special') ?? false), true);
    });
  });
}
