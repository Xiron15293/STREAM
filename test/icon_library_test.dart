import 'package:flutter_test/flutter_test.dart';
import 'package:stream_app/design/stream_icon_library.dart';

void main() {
  group('StreamIconLibrary — Bugfix etichette', () {
    test('1. Motocicletta compare nella ricerca', () {
      final label = StreamIconLibrary.getLabel('bird');
      expect(label, 'Motocicletta');
    });

    test('2. Fumo compare nella ricerca', () {
      final label = StreamIconLibrary.getLabel('tooth');
      expect(label, 'Fumo');
    });

    test('3. Bird non compare più come label utente', () {
      final label = StreamIconLibrary.getLabel('bird');
      expect(label, isNot('Uccello'));
      expect(label, 'Motocicletta');
    });

    test('4. Tooth non compare più come label utente', () {
      final label = StreamIconLibrary.getLabel('tooth');
      expect(label, isNot('Dente'));
      expect(label, 'Fumo');
    });
  });

  group('StreamIconLibrary — Gruppi icone', () {
    test('5. Gruppo Veicoli contiene icone attese', () {
      final groups = StreamIconLibrary.categoryIconGroups;
      expect(groups.containsKey('Veicoli'), isTrue);
      final veicoli = groups['Veicoli']!;
      expect(veicoli, contains('car'));
      expect(veicoli, contains('motorcycle'));
      expect(veicoli, contains('bird'));
      expect(veicoli, contains('bicycle'));
      expect(veicoli, contains('train'));
      expect(veicoli, contains('airplane'));
    });

    test('6. Gruppo Casa contiene icone attese', () {
      final groups = StreamIconLibrary.categoryIconGroups;
      expect(groups.containsKey('Casa'), isTrue);
      final casa = groups['Casa']!;
      expect(casa, contains('house'));
      expect(casa, contains('sofa'));
      expect(casa, contains('key'));
      expect(casa, contains('lock'));
      expect(casa, contains('lamp'));
    });

    test('7. Gruppo Finanza & Entrate contiene icone attese', () {
      final groups = StreamIconLibrary.categoryIconGroups;
      expect(groups.containsKey('Finanza & Entrate'), isTrue);
      final finanza = groups['Finanza & Entrate']!;
      expect(finanza, contains('money'));
      expect(finanza, contains('bank'));
      expect(finanza, contains('wallet'));
      expect(finanza, contains('piggy-bank'));
      expect(finanza, contains('trend-up'));
      expect(finanza, contains('chart-pie'));
    });

    test('Tutti i gruppi hanno icone valide', () {
      for (final entry in StreamIconLibrary.categoryIconGroups.entries) {
        for (final key in entry.value) {
          final icon = StreamIconLibrary.getIcon(key);
          expect(icon, isNot(StreamIconLibrary.fallbackIcon),
              reason: '${entry.key}: $key -> fallback');
        }
      }
    });

    test('Tutti i gruppi conto hanno icone valide', () {
      for (final entry in StreamIconLibrary.accountIconGroups.entries) {
        for (final key in entry.value) {
          final icon = StreamIconLibrary.getAccountIcon(key);
          expect(icon, isNot(StreamIconLibrary.fallbackIcon),
              reason: '${entry.key}: $key -> fallback');
        }
      }
    });
  });

  group('StreamIconLibrary — Fallback', () {
    test('8. Fallback icon funzionante per chiave inesistente', () {
      final icon = StreamIconLibrary.getIcon('nonexistent-key');
      expect(icon, StreamIconLibrary.fallbackIcon);
    });

    test('Fallback account icon per chiave inesistente', () {
      final icon = StreamIconLibrary.getAccountIcon('nonexistent-key');
      expect(icon, StreamIconLibrary.fallbackIcon);
    });

    test('Fallback label restituisce la chiave stessa', () {
      final label = StreamIconLibrary.getLabel('nonexistent-key');
      expect(label, 'nonexistent-key');
    });
  });

  group('StreamIconLibrary — Getters base', () {
    test('categoryIconsWithLabels contiene tutte le label', () {
      final items = StreamIconLibrary.categoryIconsWithLabels;
      expect(items.length, greaterThan(100));
      expect(items.any((e) => e.key == 'bird'), isTrue);
      expect(items.any((e) => e.value == 'Motocicletta'), isTrue);
    });

    test('accountIconsWithLabels contiene tutte le label', () {
      final items = StreamIconLibrary.accountIconsWithLabels;
      expect(items.length, 20);
      expect(items.any((e) => e.key == 'wallet'), isTrue);
    });

    test('findGroupForKey restituisce gruppo corretto', () {
      expect(StreamIconLibrary.findGroupForKey('car'), 'Veicoli');
      expect(StreamIconLibrary.findGroupForKey('house'), 'Casa');
      expect(StreamIconLibrary.findGroupForKey('pizza'), 'Cibo & Cucina');
      expect(StreamIconLibrary.findGroupForKey('money'), 'Finanza & Entrate');
      expect(StreamIconLibrary.findGroupForKey('dog'), 'Animali & Natura');
    });
  });

  group('StreamIconLibrary — Gruppi lista', () {
    test('categoryIconGroupsList contiene tutti i gruppi', () {
      final groups = StreamIconLibrary.categoryIconGroupsList;
      expect(groups.length, greaterThanOrEqualTo(10));
      final names = groups.map((g) => g.name).toSet();
      expect(names, contains('Veicoli'));
      expect(names, contains('Casa'));
      expect(names, contains('Cibo & Cucina'));
      expect(names, contains('Finanza & Entrate'));
      expect(names, contains('Varie'));
    });

    test('accountIconGroupsList contiene tutti i gruppi', () {
      final groups = StreamIconLibrary.accountIconGroupsList;
      expect(groups.length, greaterThanOrEqualTo(5));
      final names = groups.map((g) => g.name).toSet();
      expect(names, contains('Principali'));
      expect(names, contains('Risparmio'));
    });

    test('Ogni gruppo nella lista ha entries non vuote', () {
      for (final group in StreamIconLibrary.categoryIconGroupsList) {
        expect(group.entries, isNotEmpty, reason: group.name);
      }
    });
  });
}
