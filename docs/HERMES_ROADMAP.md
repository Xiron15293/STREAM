# HERMES ROADMAP

> Cronologia versioni Hermes — rilasci e pianificazione.
>
> **Vedi `docs/CHANGELOG.md` per il dettaglio completo di ogni release (added, changed, fixed, QA).**
> Il changelog è la fonte di verità per le release passate.

## Chiuso

| Versione | Nome | Stato | Completato |
|----------|------|-------|------------|
| V0.1 | Core Layer | ✅ COMPLETATO | 2026-06-05 |
| V0.2 | Speed Layer | ✅ COMPLETATO | 2026-06-05 |
| V0.3 | Depth Layer | ✅ COMPLETATO | 2026-06-06 |
| V0.3.1 | SQLite + Conti | ✅ COMPLETATO | 2026-06-06 |
| V0.3.2 | Categorie + Delete | ✅ COMPLETATO | 2026-06-06 |
| V0.3.3 | Human QA 1500 | ✅ COMPLETATO / CLOSED | 2026-06-06 |
| V0.4 | Design System STREAM | ✅ COMPLETATO | 2026-06-06 |
| V0.4.1 | Account Icon/Color Refresh | ✅ COMPLETATO | 2026-06-06 |
| V0.4.2 | Navigation Refactor: Archivio | ✅ COMPLETATO | 2026-06-06 |
| V0.5 | Calendario Foundation | ✅ COMPLETATO | 2026-06-07 |
| V0.5.1 | Movement Date | ✅ COMPLETATO | 2026-06-06 |
| V0.5.2 | StreamDatePicker | ✅ COMPLETATO | 2026-06-06 |
| V0.5.3 | TimeFilter Foundation | ✅ COMPLETATO | 2026-06-06 |
| V0.5.4 | Calendario Tab | ✅ COMPLETATO | 2026-06-07 |
| V0.5.5 | Archivio Filtrato per Data | ✅ COMPLETATO | 2026-06-07 |
| V0.5.6 | Dashboard Filtrata per Periodo | ✅ COMPLETATO | 2026-06-07 |
| — | MovementCard unico (refactor architetturale) | ✅ COMPLETATO | 2026-06-07 |
| — | Backup & Restore in Impostazioni | ✅ COMPLETATO | 2026-06-08 |
| — | Build release Android fix (file_picker + KGP) | ✅ COMPLETATO | 2026-06-08 |
| — | Backup export condivisibile (share sheet) | ✅ COMPLETATO | 2026-06-08 |
| — | Build pipeline: analyze + test + apk --release + ios --release tutti PASS | ✅ COMPLETATO | 2026-06-08 |
| — | Async/Timing Audit + Fix | ✅ COMPLETATO | 2026-06-08 |
| V0.6 | Dashboard Filtrata per Periodo V2 | ✅ COMPLETATO | 2026-06-08 |
| V0.6.1 | Raggruppamento Movimenti per Giorno | ✅ COMPLETATO | 2026-06-08 |
| V0.6.2 | Ordinamento Centralizzato + Fix Gruppi Giorno | ✅ COMPLETATO | 2026-06-08 |
| V0.6.3 | Ricerca Globale Movimenti | ✅ COMPLETATO | 2026-06-08 |
| V0.6.4 | UX Movimenti Rapidi/Preferiti — Data Picker | ✅ COMPLETATO | 2026-06-08 |
| V0.7.0 | Import CSV 1Money + Saldo Iniziale + Archivio Navigabile | ✅ COMPLETATO | 2026-06-09 |
| V0.7.1 | QA Reset Stabilizzato | ✅ COMPLETATO | 2026-06-09 |
| V0.8.0 | Calculator Pad | ✅ COMPLETATO | 2026-06-10 |

## Approvate / Future (V0.9+)

| Versione | Nome | Stato |
|----------|------|-------|
| V0.9.0 | Trasferimenti tra Conti | 📋 APPROVATA |
| V0.9.1 | Calendar Heatmap | 💡 IDEA |
| V0.9.2 | Fondi / Obiettivi | 💡 IDEA |
| V0.9.3 | Beneficiario + Etichette | 💡 IDEA |
| V1.0 | Prima Beta STREAM | ⏳ PIANIFICATA |
| V1.0+ | Adaptive / Tablet Layout | 💡 IDEA |
| V1.0+ | Cloud Sync (backup premium, multi-dispositivo) | 💡 IDEA |
| V1.0+ | Scenari (what-if, pianificazione) | 💡 IDEA |
| V1.0+ | Athena Foundation (Budget, AI categorization, insight) | 💡 IDEA |

Vedi **`docs/STREAM_FEATURE_BACKLOG.md`** per il censimento completo e lo stato aggiornato delle feature.

## Visione futura  

| Versione | Focus |
|----------|-------|
| V0.9.0 | Trasferimenti tra Conti (📋) — saldo duale, backup compatibile |
| V0.9.1 | Calendar Heatmap (💡) — intensità colore, filtro categoria, navigazione |
| V0.9.2 | Fondi / Obiettivi (💡) — evoluzione area insight e goal |
| V0.9.3 | Beneficiario + Etichette (💡) — tagging avanzato movimenti |
| V1.0 | Prima Beta STREAM (⏳) — distribuzione pubblica |
| V1.0+ | Adaptive / Tablet Layout (💡) — layout reattivi |
| V1.0+ | Cloud Sync (💡) — backup premium, multi-dispositivo |
| V1.0+ | Scenari (💡) — proiezioni what-if, pianificazione |
| V1.0+ | Athena Foundation (💡) — Budget, AI categorization, insight |

---

## Dettaglio feature per versione

### V0.6.2 — Ordinamento Centralizzato + Fix Gruppi Giorno ✅

> **Interventi**: Comparator unico, ordinamento `updatedAt` desc, fix chiave gruppo giorno, GroupedMovementsList, Dashboard insight-only
> **Test**: 457 test pass (+10 da V0.6.1) | `flutter analyze` 0 issues
> **Build**: APK 66.2MB ✅ | iOS 32.7MB ✅

**Cosa è stato fatto (V0.6.2 completa):**

### 1. Comparator Centralizzato `compareMovementsForDisplay`
- Top-level function in `lib/models/movement.dart`
- Ordine: `updatedAt desc → createdAt desc → id asc`
- `categoryId`, `type`, `amount`, `title` NON influenzano
- Sostituisce 3 implementazioni separate:
  - `daily_group.dart` (within-day sort) — OK
  - `time_filter.dart` (filterByTime) — usava `createdAt` ❌
  - `database.dart` (lastMovements) — usava `createdAt` ❌

### 2. Ordinamento `updatedAt` desc dentro gruppi giorno
- Prima: `createdAt desc` → movimento creato dopo ma non modificato stava sopra
- Dopo: `updatedAt desc` → movimento modificato più recentemente sta sopra
- Fallback: `createdAt desc → id asc`

### 3. Fix CRITICAL — Ordinamento gruppi giorno
- **Problema**: chiave `"2026-6-8"` > `"2026-6-12"` (lessicografico: '8' > '1')
- **Sintomo**: 8 giugno appariva sopra 12 giugno nella UI
- **Fix**: `padLeft(2, '0')` → `"2026-06-08"` < `"2026-06-12"` ✅
- **Root cause**: string key non zero-padded in `groupMovementsByDay()`

### 4. GroupedMovementsList riusabile
- `lib/widgets/grouped_movements_list.dart`
- Widget unico con `scrollController` opzionale
- Usato da: `MovementsScreen`, `_CategoryDetailSheet` (Dashboard)

### 5. Dashboard insight-only (no movement list)
- Rimosso `_FilteredMovementsList` dalla Dashboard
- Restano solo KPI + Spese per categoria + dettaglio categoria

### 6. Test aggiunti
- +10 test: 3 updatedAt sort, 2 categoryId ignored, 1 comparator direct, 2 mixed digit dates, 1 future dates, 1 widget UI order

### File modificati
| File | Modifica |
|------|----------|
| `lib/models/movement.dart` | `compareMovementsForDisplay()` + `compareForDisplay()` instance method |
| `lib/models/daily_group.dart` | Zero-padded key; usa `compareMovementsForDisplay` |
| `lib/models/time_filter.dart` | filterByTime usa `compareMovementsForDisplay` |
| `lib/data/database.dart` | lastMovements usa `compareMovementsForDisplay` |
| `lib/widgets/grouped_movements_list.dart` | **NUOVO** — widget riusabile |
| `lib/widgets/day_header.dart` | FittedBox anti-overflow |
| `lib/screens/dashboard_screen.dart` | Rimosso `_FilteredMovementsList` |
| `test/daily_group_test.dart` | +8 test (14–20) |
| `test/time_filter_bar_test.dart` | +1 widget test real UI order |

---

### V0.6.3 — Ricerca Globale Movimenti ✅

> **Interventi**: ricerca in-memory in Archivio > Movimenti, combinazione con `TimeFilter`, risultati raggruppati con `GroupedMovementsList`
> **Test**: 492 test pass | `flutter analyze` 0 issues
> **Build**: APK release PASS ✅ | iOS release no-codesign da rilanciare localmente

**Cosa è stato fatto (V0.6.3 completa):**

### 1. Ricerca globale in-memory
- Helper condiviso `lib/utils/movement_search.dart`
- Ricerca case-insensitive e con trim
- Match parziale su:
  - titolo
  - nota
  - nome categoria
  - nome conto
- Nessun FTS / SQLite full-text search

### 2. Integrazione con Archivio
- La sezione `Movimenti` in Archivio ospita la ricerca globale
- Risultati combinati con `TimeFilter` esistente:
  - giorno
  - mese
  - anno
  - periodo custom
- Risultati renderizzati con `GroupedMovementsList`

### 3. Regole di display
- Nessuna nuova `MovementCard`
- Ordine mantenuto tramite `compareMovementsForDisplay`
- Raggruppamento per giorno invariato

### 4. Test introdotti / aggiornati
- Ricerca per titolo
- Ricerca case-insensitive
- Ricerca parziale
- Ricerca per nota
- Ricerca per categoria
- Ricerca per conto
- Query vuota / empty state
- Query con spazi iniziali/finali
- Ricerca combinata con filtro mese
- Ricerca combinata con periodo custom
- Risultati raggruppati per giorno
- Ordinamento coerente con comparator unico
- Dataset grande (1000+ movimenti) con performance ragionevole

---

### V0.6.4 — UX Movimenti Rapidi/Preferiti — Data Picker ✅

> **Interventi**: scelta data rapida per template, fix bottom sheet/date picker, fix label `Conto` / `Conto origine`
> **Test**: 492 test pass | `flutter analyze` 0 issues
> **Build**: APK release PASS ✅ | iOS release no-codesign da rilanciare localmente

**Cosa è stato fatto (V0.6.4 completa):**

### 1. Scelta data rapida per Rapidi / Preferiti
- Quando si usa un rapido o preferito, il flusso apre una scelta data prima del salvataggio
- Opzioni:
  - Oggi
  - Ieri
  - Domani
  - Scegli data
- `Scegli data` riusa `StreamDatePicker`

### 2. Stabilità test widget
- `Key` stabili per i bottoni del bottom sheet
- Chiusura corretta dei bottom sheet e dei picker
- `scrollUntilVisible` usato con `Scrollable` valido nei test lazy list

### 3. Form movimento
- Label condizionale del conto:
  - Entrata / Uscita = `Conto`
  - Trasferimento = `Conto origine`

### 4. QA
- Test rapidi / preferiti sistemati
- I problemi finali erano regressioni di test, non del comportamento app
- `flutter test` aggiornato a 492 pass

---

### V0.6.1 — Raggruppamento Movimenti per Giorno ✅

> **Feature**: V0.6.1 — Movimenti/Archivio raggruppati per giorno con header e riepilogo giornaliero
> **Test**: 447 test pass (+21) | `flutter analyze` 0 issues
> **Build**: APK 66.2MB ✅ | iOS 32.6MB ✅

**Cosa è stato fatto (V0.6.1 completa):**

### 1. DailyMovementGroup model + groupMovementsByDay helper
- `lib/models/daily_group.dart`: classe `DailyMovementGroup` con `totalIncome`, `totalExpenses`, `balance`
- `groupMovementsByDay(List<Movement>)`: O(n) HashMap raggruppamento per chiave `YYYY-MM-DD`, sort desc per data

### 2. DayHeader widget
- `lib/widgets/day_header.dart`: header giornaliero con:
  - Numero giorno (07), giorno settimana (SABATO), mese + anno (GIUGNO 2026)
  - Riepilogo: Entrate, Uscite, Saldo con colori income/expense/neutro
  - Righe sempre visibili anche a 0,00 €

### 3. MovementsScreen grouped layout
- `_buildMovementsList` ora usa `ListView.builder` con grouped display
- `DayHeader` + `MovementCard` intercalati
- MovementCard con `showDate: false` (data già nell'header)

### 4. Info app in Impostazioni
- Placeholder "Info app" attivato → bottom sheet informativo

### 5. Performance
- `groupMovementsByDay`: O(n) con HashMap, target 1000+ movimenti verificato

### V0.6 — Dashboard Filtrata per Periodo V2 ✅

> **Feature**: V0.6 — Evoluzione Dashboard con IntervalPickerSheet, categoria dettaglio, azione rapida
> **Test**: 426 test pass | `flutter analyze` 0 issues
> **Build**: APK 66.1MB ✅ | iOS 32.6MB ✅

**Cosa è stato fatto (V0.6 completa):**
1. IntervalPickerSheet (sostituisce showDateRangePicker)
2. Lista movimenti filtrata in Dashboard (poi rimossa in V0.6.2)
3. Categoria dettaglio bottom sheet
4. Azione rapida "+" per categoria
5. TimeFilter.contains() fix

---

### V0.7.0 — Import CSV 1Money + Saldo Iniziale + Archivio Navigabile ✅

> **Interventi**: Import CSV 1Money con validazione dataset reale, saldo iniziale conti, Archivio navigabile conti/categorie
> **Test**: 575 test pass | `flutter analyze` 0 issues
> **Build**: APK release PASS ✅ | iOS release PASS ✅

**Cosa è stato fatto (V0.7.0 completa):**

### 1. Import CSV 1Money
- Import da CSV 1Money con validazione dataset reale (6369 movimenti)
- Zero perdita: backup 6369, CSV unici 6369, overlap 6369, backup-only 0, csv-only 0
- `test/one_money_csv_import_test.dart` verde
- Nessuna duplicazione al re-import

### 2. Saldo Iniziale Conti
- `accounts.initial_balance` nel modello
- Saldo attuale = saldo iniziale + entrate − spese ± trasferimenti netti
- Modifica conto: saldo iniziale editabile, saldo attuale derivato in sola lettura

### 3. Archivio Navigabile
- **Archivio > Conti**: conti cliccabili → bottom sheet "Movimenti del conto" con saldo iniziale, entrate/uscite/trasferimenti filtrati, TimeFilterBar, GroupedMovementsList
- **Archivio > Categorie**: categorie cliccabili → bottom sheet movimenti categoria (spesa mostra spese, entrata mostra entrate, trasferimenti esclusi)
- Conti/categorie attivi e archiviati in sezioni separate; archiviati consultabili/cliccabili

### File modificati (V0.7.0)
| File | Modifica |
|------|----------|
| `lib/data/database.dart` | Saldo iniziale, query filtrate archivio |
| `lib/models/account.dart` | `initialBalance` field |
| `lib/screens/accounts_screen.dart` | Archivio conti navigabile |
| `lib/screens/categories_screen.dart` | Archivio categorie navigabile |
| `lib/widgets/account_detail_sheet.dart` | **NUOVO** — dettaglio conto |
| `lib/widgets/category_movements_sheet.dart` | **NUOVO** — dettaglio categoria |
| + `lib/import/` | Modulo import CSV 1Money |

---

### V0.7.1 — QA Reset Stabilizzato ✅

> **Interventi**: Stabilizzazione test reset, eliminata dipendenza da stato db pregresso
> **Test**: 575 test pass | `flutter analyze` 0 issues
> **Build**: APK release PASS ✅ | iOS release PASS ✅

**Cosa è stato fatto (V0.7.1 completa):**
- `reset_data_test.dart` verde
- `qa_extensive_test.dart` verde (C2/F2/F3/L1 stabilizzati)
- Reset validato tramite flusso UI reale nei test
- Backup pre-reset stub nel test harness dove necessario
- Nessuna modifica business logic / UI per stabilizzare i test

---

### V0.8.0 — Calculator Pad ✅

> **Interventi**: CalculatorAmountField riusabile, AmountExpressionEvaluator, integrazione in form movimento/trasferimento/conto
> **Test**: 579 test pass (+30 calculator pad) | `flutter analyze` 0 issues
> **Build**: APK release PASS ✅ | iOS release PASS ✅

**Cosa è stato fatto (V0.8.0 completa):**

### 1. CalculatorAmountField
- `lib/widgets/calculator_amount_pad.dart` — widget riusabile
- TextField `readOnly: true`, `showCursor: false`, `keyboardType: TextInputType.none` → tastiera nativa bloccata
- `onTap` apre il calculator pad custom via bottom sheet
- Focus rimosso prima dell'apertura (`FocusManager.instance.primaryFocus?.unfocus()`)
- Valore nel controller persistente dopo chiusura pad

### 2. AmountExpressionEvaluator
- `AmountExpressionEvaluator` in `calculator_amount_pad.dart`
- Supporto operatori: `+`, `-`, `*`, `/`, `:`, `=`
- Decimali (`.`) e virgola decimale (`,`)
- Backspace, clear
- Precedenza operatori (`2 + 3 * 4 = 14`)
- Divisione per zero gestita
- Espressioni incomplete gestite
- **Nessun `eval()`** — parser custom safe

### 3. Comportamento pad
- `=` calcola senza chiudere il bottom sheet
- "Fatto" calcola, conferma, e chiude il bottom sheet
- Dopo `=` si può continuare l'operazione

### 4. Integrazione
- Movimento manuale (spesa/entrata)
- Modifica movimento
- Trasferimento manuale
- Movimenti rapidi & preferiti
- Saldo iniziale conto

### 5. Fix tastiera nativa (V0.8.0 finale)
- **Bug**: dopo tap sul campo importo, tastiera numerica nativa si apriva sopra il pad custom
- **Root cause**: TextField attivava focus/keyboard prima che `onTap` aprisse il bottom sheet; dopo chiusura, il focus residuo riapriva la tastiera
- **Fix**: `readOnly: true`, `showCursor: false`, `keyboardType: TextInputType.none`, `unfocus()` in `_showPad()`
- **Test**: 4 nuovi test (readOnly, showCursor, keyboardType, tap apre pad custom, Fatto chiude e mantiene valore, = calcola senza chiudere)
- **49 test legacy aggiornati**: `tester.enterText` su campo readOnly non funzionava più → sostituito con helper Calculator Pad
- **Nuovo helper test**: `test/helpers/calculator_test_helpers.dart` con `enterAmountWithCalculator`, `openPadAndType`, `closeCalculatorPad`
- **Nessun indebolimento assert, nessuno skip**
- **Verifica**: 30/30 calculator pad test pass, 579/579 suite completa, analyze 0 issues

### File modificati (V0.8.0)
| File | Modifica |
|------|----------|
| `lib/widgets/calculator_amount_pad.dart` | CalculatorAmountField + CalculatorAmountPad + AmountExpressionEvaluator |
| `lib/widgets/movement_picker.dart` | Usa CalculatorAmountField (3 campi) |
| `lib/widgets/movement_form.dart` | Usa CalculatorAmountField (1 campo) |
| `lib/screens/accounts_screen.dart` | Usa CalculatorAmountField (saldo iniziale) |
| `test/calculator_amount_pad_test.dart` | 30 test (evaluator + widget + integrazione) |
| `test/helpers/calculator_test_helpers.dart` | **NUOVO** — helper test Calculator Pad |
| `test/qa_movements_test.dart` | `saveMovement` e 3 test aggiornati per Calculator Pad |
| `test/widget_test.dart` | 3 test aggiornati per Calculator Pad |
| `test/dashboard_after_delete_test.dart` | `saveMovement` aggiornato per Calculator Pad |
| `test/qa_extensive_test.dart` | `_fillManualMovementForm` aggiornato per Calculator Pad |

---

Vedi `CHANGELOG.md` per dettaglio completo di V0.5.x, V0.4.x, V0.3.x, V0.2, V0.1.
