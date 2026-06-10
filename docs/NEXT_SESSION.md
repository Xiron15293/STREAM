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
| Hermes V0.8.1 — Categories Layout Modes | Modello categoria, layout multipli, filtro Entrate/Uscite, KPI categorie | ✅ COMPLETATO |
| Hermes V0.8.2 — Financial KPI Corrections | Transfer esclusi dai KPI globali, helper centralizzati, Dashboard corretta | ✅ COMPLETATO |
| Hermes V0.8.3 — Date Filter Categories/Accounts | TimeFilter nelle schermate principali, saldo conto storico/as-of per periodo | ✅ COMPLETATO |
| Flutter analyze | — | ✅ PASS — 0 issues |
| `flutter test --no-pub` | — | ✅ 625/625 All tests passed |
| `flutter build apk --release --no-pub` | — | ⏳ da rilanciare localmente |
| `flutter build ios --release --no-codesign --no-pub` | — | ⏳ da rilanciare localmente |

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
- `flutter test --no-pub`: PASS
- 49 test legacy aggiornati per usare Calculator Pad al posto di `enterText`

**Hermes V0.8.1 — Categories Layout Modes**

### Cosa è stato completato
- `Impostazioni > Aspetto > Modello categoria`
- Layout categorie:
  - Lista pulita
  - Lista grouped
  - Card Stream
- Filtro `[ Uscite | Entrate ]` nella schermata Categorie
- KPI riepilogo categorie con key testabili
- FAB categoria precompilato in base al filtro attivo
- Layout differenziati visivamente
- Conti archiviati esclusi dal saldo disponibile
- Saldo attuale conto resta derivato da `initialBalance + movimenti netti`

**Hermes V0.8.2 — Financial KPI Corrections**

### Cosa è stato completato
- Transfer esclusi da Entrate/Uscite/Bilancio globali
- Dashboard corretta: rimossa la logica `if income else expense`
- Helper centralizzati in `movement.dart`:
  - `isIncome`
  - `isExpense`
  - `isTransfer`
  - `sumIncome`
  - `sumExpenses`
  - `sumTransfers`
  - `netIncomeExpense`
- Spese per categoria = solo `expense`
- Riepiloghi giornalieri = solo `income` / `expense`
- Saldo conto invariato: transfer ancora inclusi su origine/destinazione

### QA finale
- `flutter analyze --no-pub`: PASS — 0 issues
- `flutter test --no-pub`: **619/619 All tests passed**
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push eseguito

**Hermes V0.8.3 — Date Filter in Categories and Accounts**

### Cosa è stato completato
- Categorie: filtro periodo nella schermata principale con `TimeFilterBar`
- KPI categorie, Card Stream e ordinamento Top categorie filtrati per periodo
- Transfer esclusi dai totali categoria
- Dettaglio categoria aperto con lo stesso filtro della schermata principale
- Conti: filtro periodo nella schermata principale con riepilogo entrate/uscite/trasferimenti/movimenti
- Saldo conto visibile storico/as-of al termine del periodo selezionato
- Formula saldo fine periodo: `initialBalance + impatto di tutti i movimenti con data <= fine periodo`
- Formula saldo inizio periodo: `initialBalance + impatto di tutti i movimenti con data < inizio periodo`
- Movimenti netti periodo: entrate periodo - uscite periodo + trasferimenti netti periodo
- Dettaglio conto allineato allo stesso filtro iniziale
- Helper aggiunti in `movement.dart`: `transferNetForAccount`, `periodTransferNetForAccount`, `movementNetForAccount`, `periodNetForAccount`, `balanceForAccountUntil`, `balanceForAccountBefore`

### QA finale
- `flutter analyze --no-pub`: PASS — 0 issues
- `flutter test --no-pub`: **625/625 All tests passed**
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push eseguito

---

## 3. Priorità Immediata (Prossima Sessione)

Una volta ripresa la sessione:

**Prima di nuove feature:**
1. Commit/push stato finale V0.8.0 + V0.8.1 + V0.8.2 + V0.8.3
2. QA manuale Pixel/iPhone
3. Build release APK/iOS aggiornate
4. Eventuale fix minori UX emersi da QA manuale

**Prossimo sprint prodotto (scegliere):**
- ✏️ **Global Tap-to-Edit Movement**
- 🗓️ **Movimenti: Vista Calendario**

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
- Categories Layout Modes: preferenza `category_layout`, default `cleanList`, reset incluso in `PreferencesService.clearForReset()`
- Financial KPI Corrections: Dashboard, database totals e riepiloghi giornalieri usano helper income/expense espliciti; i transfer restano neutrali sui KPI globali e attivi sui saldi conto
- Date Filter Categories/Accounts: Categorie e Conti hanno `TimeFilterBar` nella schermata principale; nei Conti il saldo visibile è storico/as-of al termine del periodo selezionato

---

## 5. Handoff Rapido

Quando si riparte:
- verificare stato git e preparare commit/push finale
- eseguire QA manuale Pixel/iPhone
- rilanciare build release APK/iOS
- mantenere Dashboard insight-only
- scegliere il prossimo sprint tra Global Tap-to-Edit Movement e Movimenti: Vista Calendario
