# NEXT SESSION — Stato Progetto e Priorità

> Aggiornato: 2026-06-10

---

## 1. Stato Attuale

| Componente | Versione | Stato |
|------------|----------|-------|
| Hermes V0.1 — MVP Base | Dashboard, Movimenti, Categorie | ✅ COMPLETATO |
| Hermes V0.2 — Speed Layer | Duplica, Rapidi, Preferiti, Suggeriti, Note | ✅ COMPLETATO |
| Hermes V0.3 — Fondamenta | SQLite, Persistenza, Conti | ✅ COMPLETATO |
| Hermes V0.3.1 — Modifica Movimento | Edit, Date picker, UPDATE SQL | ✅ COMPLETATO |
| Hermes V0.3.2 — Completamento | accountId fix + Confirm Delete + Categorie Editabili | ✅ COMPLETATO |
| Hermes V0.4 — Design System STREAM | Tema, Icone, Palette, Restyling, Database V4 | ✅ COMPLETATO |
| Hermes V0.5 — Calendario Foundation | Date movimenti, TimeFilter, Calendario, Archivio filtrato | ✅ COMPLETATO |
| Hermes V0.6.1 — Raggruppamento Giorno | GroupedMovementsList, DayHeader, riepilogo giornaliero | ✅ COMPLETATO |
| Hermes V0.6.2 — Ordinamento Centralizzato | Comparator unico + fix gruppi giorno | ✅ COMPLETATO |
| Hermes V0.6.3 — Ricerca Globale Movimenti | ricerca in-memory in Archivio > Movimenti | ✅ COMPLETATO |
| Hermes V0.6.4 — UX Rapidi/Preferiti Data Picker | Oggi / Ieri / Domani / Scegli data | ✅ COMPLETATO |
| Hermes V0.7.0 — Import CSV 1Money + Saldo Iniziale + Archivio Navigabile | Import CSV validato, saldo iniziale conti, conti/categorie cliccabili | ✅ COMPLETATO |
| Hermes V0.7.1 — QA Reset Stabilizzato | Test reset ripristinati e verdi | ✅ COMPLETATO |
| Hermes V0.8.0 — Calculator Pad | AmountExpressionEvaluator, CalculatorAmountField, fix tastiera nativa | ✅ COMPLETATO |
| Flutter analyze | — | ✅ PASS — 0 issues |
| `flutter test --no-pub` | — | ✅ 579/579 All tests passed |
| `flutter build apk --release --no-pub` | — | ⏳ da rilanciare localmente (con Calculator Pad) |
| `flutter build ios --release --no-codesign --no-pub` | — | ⏳ da rilanciare localmente (con Calculator Pad) |

---

## 2. Ultima Milestone Completata

**Hermes V0.8.0 — Calculator Pad**

### Cosa è stato completato
- `CalculatorAmountField` riusabile per tutti i campi importo
- `AmountExpressionEvaluator` senza `eval` con supporto operatori, decimali, precedenza
- `readOnly: true`, `showCursor: false`, `keyboardType: TextInputType.none` — tastiera nativa bloccata
- `unfocus()` prima dell'apertura del bottom sheet
- Integrazione: movimento manuale, modifica, trasferimento, rapidi, preferiti, saldo iniziale conto

### Test helper creati
- `test/helpers/calculator_test_helpers.dart`:
  - `enterAmountWithCalculator()` — per test UI che inseriscono importi
  - `openPadAndType()` — per espressioni invalide
  - `closeCalculatorPad()` — chiusura forzata

### QA
- `flutter analyze --no-pub`: PASS — 0 issues
- `flutter test --no-pub`: **579/579 All tests passed**
- 49 test legacy aggiornati per usare Calculator Pad al posto di `enterText`

---

## 3. Priorità Immediata (Prossima Sessione)

Una volta effettuato commit e push di V0.8.0:

**Prima di nuove feature:**
1. QA manuale Calculator Pad su Pixel/iPhone
2. Build release APK/iOS aggiornate
3. Eventuale fix minori UX emersi da QA manuale

**Prossimo sprint prodotto (scegliere):**
- 💰 **Trasferimenti tra Conti** (V0.9.0 — 📋 approvata)
- 🗺️ **Calendar Heatmap** (V0.9.1 — 💡 idea)
- 🎯 **Fondi / Obiettivi** (V0.9.2 — 💡 idea)
- 🏷️ **Beneficiario + Etichette** (V0.9.3 — 💡 idea)

---

## 4. Note Tecniche Aperte

- Rumore in migrazione V6: `duplicate column name: date` nei test, ma non blocca l'esecuzione
- Warning futuro Kotlin Gradle Plugin su `file_picker` / `package_info_plus` / `share_plus`
- Reset dati app: verificato manualmente su Pixel 6; i failure QA residui erano dovuti a helper/test fragili e non a un bug confermato del prodotto
- Import CSV 1Money: validato su dataset reale, con 6369 movimenti unici coincidenti tra Stream e 1Money
- Import CSV 1Money: la sezione finale dei conti/fondi esportata da 1Money viene ignorata dalla riga `NOME`
- Se serve riallineare i saldi conto per una verifica manuale, usare i valori del backup Stream validato come riferimento operativo
- Saldo iniziale conti: il saldo attuale è ora sempre derivato da saldo iniziale + movimenti, e la modifica conto espone solo il saldo iniziale come campo editabile
- Archivio > Conti: la vista `Movimenti del conto` è stata aggiunta e usa `TimeFilter` + `GroupedMovementsList`
- Archivio > Categorie: la vista `Movimenti categoria` è stata aggiunta e usa `TimeFilter` + `GroupedMovementsList`
- Conti e categorie archiviate sono consultabili e cliccabili in sezioni separate (`Archiviati`)
- Reset widget flow: `reset_data_test.dart` e `qa_extensive_test.dart` sono verdi; `C2`, `F2`, `F3`, `L1` stabilizzati tramite flusso UI reale con backup pre-reset stub nel test harness dove necessario

---

## 5. Handoff Rapido

Quando si riparte:
- verificare che i dati di test siano puliti prima della sessione
- riprendere dalla pianificazione Calculator Pad
- mantenere Dashboard insight-only
- non introdurre nuove feature fuori priorità senza allineamento
