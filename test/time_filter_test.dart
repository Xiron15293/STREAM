import 'package:flutter_test/flutter_test.dart';
import 'package:stream_app/models/category.dart';
import 'package:stream_app/models/movement.dart';
import 'package:stream_app/models/time_filter.dart';

void main() {
  group('TimeFilter.day', () {
    test('contiene solo quel giorno', () {
      final f = TimeFilter.day(DateTime(2026, 6, 15));
      expect(f.contains(DateTime(2026, 6, 15)), true);
      expect(f.contains(DateTime(2026, 6, 14)), false);
      expect(f.contains(DateTime(2026, 6, 16)), false);
      expect(f.mode, TimeFilterMode.day);
    });

    test('giorno dopo non incluso', () {
      final f = TimeFilter.day(DateTime(2026, 6, 15));
      expect(f.contains(DateTime(2026, 6, 15, 23, 59, 59)), true);
      expect(f.contains(DateTime(2026, 6, 16)), false);
    });

    test('label: "15 giugno 2026"', () {
      final f = TimeFilter.day(DateTime(2026, 6, 15));
      expect(f.label, '15 giugno 2026');
    });

    test('label gennaio', () {
      final f = TimeFilter.day(DateTime(2026, 1, 1));
      expect(f.label, '1 gennaio 2026');
    });

    test('label dicembre', () {
      final f = TimeFilter.day(DateTime(2026, 12, 31));
      expect(f.label, '31 dicembre 2026');
    });
  });

  group('TimeFilter.month', () {
    test('contiene solo quel mese', () {
      final f = TimeFilter.month(2026, 6);
      expect(f.contains(DateTime(2026, 6, 1)), true);
      expect(f.contains(DateTime(2026, 6, 15)), true);
      expect(f.contains(DateTime(2026, 6, 30)), true);
      expect(f.contains(DateTime(2026, 5, 31)), false);
      expect(f.contains(DateTime(2026, 7, 1)), false);
    });

    test('mese dopo non incluso', () {
      final f = TimeFilter.month(2026, 6);
      expect(f.contains(DateTime(2026, 7, 1)), false);
    });

    test('dicembre → ultimo giorno di dicembre', () {
      final f = TimeFilter.month(2026, 12);
      expect(f.contains(DateTime(2026, 12, 31)), true);
      expect(f.contains(DateTime(2027, 1, 1)), false);
    });

    test('label: "giugno 2026"', () {
      expect(TimeFilter.month(2026, 6).label, 'giugno 2026');
      expect(TimeFilter.month(2026, 1).label, 'gennaio 2026');
      expect(TimeFilter.month(2026, 12).label, 'dicembre 2026');
    });
  });

  group('TimeFilter.year', () {
    test('contiene solo quell\'anno', () {
      final f = TimeFilter.year(2026);
      expect(f.contains(DateTime(2026, 1, 1)), true);
      expect(f.contains(DateTime(2026, 6, 15)), true);
      expect(f.contains(DateTime(2026, 12, 31)), true);
      expect(f.contains(DateTime(2025, 12, 31)), false);
      expect(f.contains(DateTime(2027, 1, 1)), false);
    });

    test('anno dopo non incluso', () {
      final f = TimeFilter.year(2026);
      expect(f.contains(DateTime(2027, 1, 1)), false);
    });

    test('label: "2026"', () {
      expect(TimeFilter.year(2026).label, '2026');
    });
  });

  group('TimeFilter.customRange', () {
    test('contiene range corretto (inclusivo)', () {
      final f = TimeFilter.customRange(
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 30),
      );
      expect(f.contains(DateTime(2026, 6, 15)), true);
      expect(f.contains(DateTime(2026, 6, 20)), true);
      expect(f.contains(DateTime(2026, 6, 29)), true);
      expect(f.contains(DateTime(2026, 6, 14)), false);
      expect(f.contains(DateTime(2026, 6, 30)), true);
      expect(f.contains(DateTime(2026, 7, 1)), false);
    });

    test('endDate inclusiva nell\'intervallo custom', () {
      final f = TimeFilter.customRange(
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 1),
      );
      expect(f.contains(DateTime(2026, 6, 30)), true);
      expect(f.contains(DateTime(2026, 7, 1)), true);
      expect(f.contains(DateTime(2026, 7, 2)), false);
    });

    test('endDate == startDate → range 1 giorno', () {
      final f = TimeFilter.customRange(
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 15),
      );
      expect(f.contains(DateTime(2026, 6, 15)), true);
      expect(f.contains(DateTime(2026, 6, 16)), false);
    });

    test('start > end → range 1 giorno partendo da start', () {
      final f = TimeFilter.customRange(
        DateTime(2026, 6, 20),
        DateTime(2026, 6, 15),
      );
      expect(f.contains(DateTime(2026, 6, 20)), true);
      expect(f.contains(DateTime(2026, 6, 19)), false);
    });

    test('label: "15 giu → 30 giu"', () {
      final f = TimeFilter.customRange(
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 30),
      );
      expect(f.label, '15 giu → 30 giu');
    });
  });

  group('TimeFilter.next()', () {
    test('day: avanza di 1 giorno', () {
      final f = TimeFilter.day(DateTime(2026, 6, 15));
      final next = f.next();
      expect(next.contains(DateTime(2026, 6, 16)), true);
      expect(next.contains(DateTime(2026, 6, 15)), false);
      expect(next.mode, TimeFilterMode.day);
    });

    test('day: capodanno', () {
      final f = TimeFilter.day(DateTime(2026, 12, 31));
      final next = f.next();
      expect(next.contains(DateTime(2027, 1, 1)), true);
    });

    test('month: avanza di 1 mese', () {
      final f = TimeFilter.month(2026, 6);
      final next = f.next();
      expect(next.contains(DateTime(2026, 7, 15)), true);
      expect(next.contains(DateTime(2026, 6, 30)), false);
      expect(next.mode, TimeFilterMode.month);
    });

    test('month: dicembre → gennaio anno+1', () {
      final f = TimeFilter.month(2026, 12);
      final next = f.next();
      expect(next.contains(DateTime(2027, 1, 15)), true);
      expect(next.contains(DateTime(2026, 12, 31)), false);
      expect(next.label, 'gennaio 2027');
    });

    test('year: avanza di 1 anno', () {
      final f = TimeFilter.year(2026);
      final next = f.next();
      expect(next.contains(DateTime(2027, 6, 15)), true);
      expect(next.contains(DateTime(2026, 12, 31)), false);
      expect(next.mode, TimeFilterMode.year);
    });

    test('customRange: restituisce stesso filtro', () {
      final f = TimeFilter.customRange(
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 30),
      );
      expect(f.next(), f);
    });
  });

  group('TimeFilter.previous()', () {
    test('day: indietro di 1 giorno', () {
      final f = TimeFilter.day(DateTime(2026, 6, 15));
      final prev = f.previous();
      expect(prev.contains(DateTime(2026, 6, 14)), true);
      expect(prev.contains(DateTime(2026, 6, 15)), false);
      expect(prev.mode, TimeFilterMode.day);
    });

    test('day: capodanno indietro', () {
      final f = TimeFilter.day(DateTime(2026, 1, 1));
      final prev = f.previous();
      expect(prev.contains(DateTime(2025, 12, 31)), true);
    });

    test('month: indietro di 1 mese', () {
      final f = TimeFilter.month(2026, 6);
      final prev = f.previous();
      expect(prev.contains(DateTime(2026, 5, 15)), true);
      expect(prev.contains(DateTime(2026, 6, 1)), false);
      expect(prev.mode, TimeFilterMode.month);
    });

    test('month: gennaio → dicembre anno-1', () {
      final f = TimeFilter.month(2026, 1);
      final prev = f.previous();
      expect(prev.contains(DateTime(2025, 12, 15)), true);
      expect(prev.contains(DateTime(2026, 1, 1)), false);
      expect(prev.label, 'dicembre 2025');
    });

    test('year: indietro di 1 anno', () {
      final f = TimeFilter.year(2026);
      final prev = f.previous();
      expect(prev.contains(DateTime(2025, 6, 15)), true);
      expect(prev.contains(DateTime(2026, 1, 1)), false);
      expect(prev.mode, TimeFilterMode.year);
    });

    test('customRange: restituisce stesso filtro', () {
      final f = TimeFilter.customRange(
        DateTime(2026, 6, 15),
        DateTime(2026, 6, 30),
      );
      expect(f.previous(), f);
    });
  });

  group('MovementFilter extension', () {
    test('filtra movimenti per giorno', () {
      final movements = [
        Movement(id: 'a', title: 'Oggi', amount: 10, type: MovementType.expense,
            date: DateTime(2026, 6, 15), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15, 10)),
        Movement(id: 'b', title: 'Ieri', amount: 20, type: MovementType.expense,
            date: DateTime(2026, 6, 14), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 14)),
        Movement(id: 'c', title: 'Domani', amount: 30, type: MovementType.expense,
            date: DateTime(2026, 6, 16), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 16)),
      ];
      final filtered = movements.filterByTime(TimeFilter.day(DateTime(2026, 6, 15)));
      expect(filtered.length, 1);
      expect(filtered.first.id, 'a');
    });

    test('filtra movimenti per mese', () {
      final movements = [
        Movement(id: 'a', title: 'Giugno', amount: 10, type: MovementType.expense,
            date: DateTime(2026, 6, 15), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15)),
        Movement(id: 'b', title: 'Luglio', amount: 20, type: MovementType.expense,
            date: DateTime(2026, 7, 1), categoryId: 'exp_1', createdAt: DateTime(2026, 7, 1)),
        Movement(id: 'c', title: 'Maggio', amount: 30, type: MovementType.expense,
            date: DateTime(2026, 5, 31), categoryId: 'exp_1', createdAt: DateTime(2026, 5, 31)),
      ];
      final filtered = movements.filterByTime(TimeFilter.month(2026, 6));
      expect(filtered.length, 1);
      expect(filtered.first.id, 'a');
    });

    test('filtra movimenti per anno', () {
      final movements = [
        Movement(id: 'a', title: '2026', amount: 10, type: MovementType.expense,
            date: DateTime(2026, 6, 15), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15)),
        Movement(id: 'b', title: '2025', amount: 20, type: MovementType.expense,
            date: DateTime(2025, 12, 31), categoryId: 'exp_1', createdAt: DateTime(2025, 12, 31)),
        Movement(id: 'c', title: '2027', amount: 30, type: MovementType.expense,
            date: DateTime(2027, 1, 1), categoryId: 'exp_1', createdAt: DateTime(2027, 1, 1)),
      ];
      final filtered = movements.filterByTime(TimeFilter.year(2026));
      expect(filtered.length, 1);
      expect(filtered.first.id, 'a');
    });

    test('filtra movimenti per range custom (inclusivo)', () {
      final movements = [
        Movement(id: 'a', title: 'Dentro', amount: 10, type: MovementType.expense,
            date: DateTime(2026, 6, 15), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15)),
        Movement(id: 'b', title: 'Fuori sx', amount: 20, type: MovementType.expense,
            date: DateTime(2026, 6, 10), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 10)),
        Movement(id: 'c', title: 'Fuori dx', amount: 30, type: MovementType.expense,
            date: DateTime(2026, 6, 21), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 21)),
        Movement(id: 'd', title: 'Dentro 2', amount: 40, type: MovementType.expense,
            date: DateTime(2026, 6, 18), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 18)),
      ];
      final filtered = movements.filterByTime(
        TimeFilter.customRange(DateTime(2026, 6, 15), DateTime(2026, 6, 20)),
      );
      expect(filtered.length, 2);
      expect(filtered.map((m) => m.id), containsAll(['a', 'd']));
    });

    test('ordinamento: date DESC, createdAt DESC', () {
      final movements = [
        Movement(id: 'a', title: 'Giorno 1 tardi', amount: 10, type: MovementType.expense,
            date: DateTime(2026, 6, 15), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15, 18)),
        Movement(id: 'b', title: 'Giorno 1 presto', amount: 20, type: MovementType.expense,
            date: DateTime(2026, 6, 15), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15, 10)),
        Movement(id: 'c', title: 'Giorno 2', amount: 30, type: MovementType.expense,
            date: DateTime(2026, 6, 16), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 16)),
      ];
      final filtered = movements.filterByTime(
        TimeFilter.customRange(DateTime(2026, 6, 15), DateTime(2026, 6, 17)),
      );
      expect(filtered.length, 3);
      expect(filtered[0].id, 'c');
      expect(filtered[1].id, 'a');
      expect(filtered[2].id, 'b');
    });

    test('lista vuota → risultato vuoto', () {
      final filtered = <Movement>[].filterByTime(TimeFilter.day(DateTime(2026, 6, 15)));
      expect(filtered, isEmpty);
    });

    test('nessun movimento nel periodo → risultato vuoto', () {
      final movements = [
        Movement(id: 'a', title: 'Test', amount: 10, type: MovementType.expense,
            date: DateTime(2026, 6, 15), categoryId: 'exp_1', createdAt: DateTime(2026, 6, 15)),
      ];
      final filtered = movements.filterByTime(TimeFilter.day(DateTime(2026, 6, 16)));
      expect(filtered, isEmpty);
    });
  });

  group('TimeFilter edge cases', () {
    test('data con orario non zero è normalizzata', () {
      final f = TimeFilter.day(DateTime(2026, 6, 15, 14, 30, 45));
      expect(f.startDate, DateTime.utc(2026, 6, 15));
      expect(f.endDate, DateTime.utc(2026, 6, 15));
    });

    test('contains con data con orario non zero', () {
      final f = TimeFilter.day(DateTime(2026, 6, 15));
      expect(f.contains(DateTime(2026, 6, 15, 23, 59, 59)), true);
      expect(f.contains(DateTime(2026, 6, 16, 0, 0, 1)), false);
    });

    test('month bisestile febbraio', () {
      final f = TimeFilter.month(2024, 2);
      expect(f.contains(DateTime(2024, 2, 29)), true);
      expect(f.contains(DateTime(2024, 3, 1)), false);
    });

    test('label mesi: verifica tutti i 12 nomi', () {
      expect(TimeFilter.month(2026, 1).label, 'gennaio 2026');
      expect(TimeFilter.month(2026, 2).label, 'febbraio 2026');
      expect(TimeFilter.month(2026, 3).label, 'marzo 2026');
      expect(TimeFilter.month(2026, 4).label, 'aprile 2026');
      expect(TimeFilter.month(2026, 5).label, 'maggio 2026');
      expect(TimeFilter.month(2026, 6).label, 'giugno 2026');
      expect(TimeFilter.month(2026, 7).label, 'luglio 2026');
      expect(TimeFilter.month(2026, 8).label, 'agosto 2026');
      expect(TimeFilter.month(2026, 9).label, 'settembre 2026');
      expect(TimeFilter.month(2026, 10).label, 'ottobre 2026');
      expect(TimeFilter.month(2026, 11).label, 'novembre 2026');
      expect(TimeFilter.month(2026, 12).label, 'dicembre 2026');
    });
  });
}
