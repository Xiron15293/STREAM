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
| V0.8.0 | Import CSV 1Money (prima versione) | 🛠️ IMPLEMENTATO | 2026-06-09 |

## Approvate / Future (V0.6.x+)

| Versione | Nome | Stato |
|----------|------|-------|
| V0.6.5 | Reset dati app | 📋 APPROVATA |
| V0.6.6 | Trasferimenti tra Conti | 📋 APPROVATA |
| V0.6.8 | Calendar Heatmap | 💡 IDEA |
| V0.6.9 | Fondi / Obiettivi | 💡 IDEA |
| V0.7 | Athena Foundation (Budget, AI, Insight) | 💡 IDEA |
| V0.8 | Import CSV | 💡 IDEA |
| V0.9 | Scenari | 💡 IDEA |
| V1.1 | Cloud Sync (backup premium, multi-dispositivo) | 💡 IDEA |

Vedi **`docs/STREAM_FEATURE_BACKLOG.md`** per il censimento completo e lo stato aggiornato delle feature.

## Visione futura  

| Versione | Focus |
|----------|-------|
| V0.6.5 | Reset dati app (📋) — reset controllato e ripartenza pulita |
| V0.6.6 | Trasferimenti tra Conti (📋) — saldo duale, backup compatibile |
| V0.6.8 | Calendar Heatmap (💡) — intensità colore, filtro categoria, navigazione |
| V0.6.9 | Fondi / Obiettivi (💡) — evoluzione area insight e goal |
| V0.7 | Athena Foundation (💡) — Budget, AI categorization, insight |
| V0.8 | Import CSV (💡) — import movimenti da home banking |
| V0.9 | Scenari (💡) — proiezioni what-if, pianificazione |
| V1.0 | Prima Beta STREAM (⏳) — distribuzione pubblica |
| V1.0+ | Adaptive / Tablet Layout (💡) — layout reattivi |

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

Vedi `CHANGELOG.md` per dettaglio completo di V0.5.x, V0.4.x, V0.3.x, V0.2, V0.1.
