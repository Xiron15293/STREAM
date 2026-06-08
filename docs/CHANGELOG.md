# CHANGELOG

All notable changes to STREAM will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Planned
- V0.6.2 — Ricerca Globale Movimenti
- V0.6.3 — UX Movimenti Rapidi/Preferiti Data Picker
- V0.6.4 — Calendar Heatmap
- V0.6.5 — Beneficiario ed Etichette
- V0.6.6 — Trasferimenti tra Conti

---

## [0.6.1] - 2026-06-08

### Added
- Raggruppamento Movimenti per Giorno in Archivio
  - Header giornaliero: numero giorno (07), giorno settimana (SABATO), mese + anno (GIUGNO 2026)
  - Riepilogo economico per giorno: Entrate, Uscite, Saldo (sempre visibili, anche a 0,00 €)
  - Colori: entrate income, uscite expense, saldo positivo income, negativo expense, zero neutro
  - Gruppi ordinati dal più recente al più vecchio
  - Movimenti dentro ogni gruppo ordinati dal più recente al più vecchio
- `DailyMovementGroup` model + `groupMovementsByDay()` helper
- `DayHeader` widget — header giornaliero con riepilogo
- Info app in Impostazioni (versione, build, ambiente, piattaforma, pacchetto)
- `package_info_plus` dependency per lettura versione/build nativa

### Changed
- `MovementsScreen._buildMovementsList`: `ListView.separated` → `ListView.builder` con grouped layout
- MovementCard ora usa `showDate: false` nei gruppi (la data è nell'header)
- SettingsScreen: placeholder "Info app" → tappabile, apre bottom sheet informativo
- SettingsScreen: `import 'dart:io'` e `package_info_plus` aggiunti

### Performance
- `groupMovementsByDay`: O(n) map + sort, target 1000+ movimenti
- Nessun sort multiplo o raggruppamento ripetuto nel build

### QA
- 447 test pass (+11 unit daily_group + 10 widget raggruppamento/regression)
- flutter analyze: 0 issues
- Android release build PASS (66.2MB)
- iOS release build PASS (32.6MB)

---

## [0.6.0] - 2026-06-08

### Added
- Dashboard: lista movimenti filtrata per periodo (max 20)
- Dashboard: quick-add movimento per categoria (+ icona su ogni categoria)
- Dashboard: categorie tappabili → dettaglio categoria (nome, totale, conteggio, movimenti filtrati)
- MovementPicker: parametro `categoryPreFill` per preselezionare tipo + categoria
- `IntervalPickerSheet`: bottom sheet dedicato per selezione intervallo Da/A con Annulla/Applica
- Label filtro custom: formato breve "1 giu → 30 giu"

### Changed
- TimeFilterBar: "Periodo" rinominato in "Intervallo" nel SegmentedButton
- TimeFilterBar: `showDateRangePicker` nativo sostituito da `IntervalPickerSheet`
- TimeFilter: `contains()` usa confronto inclusivo (`!isBefore && !isAfter`) con normalizzazione
- TimeFilter.customRange: `endDate` preserva la data esatta scelta dall'utente
- IntervalPickerSheet: formato data nei _DateCard "DD/MM/AAAA"

### Fixed
- **CRITICAL** — TimeFilterBar "Intervallo" APRIVA IL PICKER MESE invece di `IntervalPickerSheet`. Causa: `_onModeChanged(customRange)` non chiamava `onChanged`, quindi `_pickDate` leggeva `activeFilter.mode == month` e apriva StreamDatePicker per mese. Fix: `_pickDate` accetta `forcedMode` parametro, `_onModeChanged` passa `forcedMode: TimeFilterMode.customRange`.
- CategoryExpenseRow: `Expanded` nidificato causava unbounded width constraint
- TimeFilter.day/month/year: `endDate` allineato al nuovo comportamento inclusivo

### QA (500 scenari)
- 426 test pass (+14 nuovi: 4 interval picker widget, 3 category detail widget, 7 unit edge case)
- flutter analyze: 0 issues
- Android release build PASS (66.1MB)
- iOS release build PASS (32.6MB)

---

## [0.5.6] - 2026-06-07

### Added
- TimeFilterBar in Dashboard (Giorno/Mese/Anno/Periodo)
- KPI filtrati per periodo: Entrate, Spese, Saldo, Movimenti
- Spese per categoria nel periodo
- Backup locale (crea/ripristina JSON in Impostazioni)
- Backup export condivisibile (share sheet via share_plus)
- MovementCard: widget unico condiviso (-376 righe da 3 screen duplicati)
- Scaffolding Calendario in Archivio
- Build pipeline: analize + test + apk + ios (tutti PASS)

### Changed
- Navigazione finale: Dashboard / Archivio / Impostazioni
- MovementCard API: movement, category, account, onTap, onEdit, onDuplicate, onSaveAsFavorite, onDelete, showNotes, showDate
- Icona standardizzata a 36x36px

### Fixed
- Build release Android: KGP applicato a file_picker in android/build.gradle.kts
- Async/Timing Audit: 22 metodi `void async` → `Future<void> async`, 0 `unawaited()` rimasti
- Dashboard stale dopo salvataggio (ListenableBuilder)
- Separatore decimale virgola (V0.2, confermato funzionante)
- 3 CRITICAL fix nell'audit async

### QA
- 387 test pass (+24 backup, +17 stress, +14 MovementCard)
- flutter analyze: 0 issues
- Android release: 98.6s (66.1MB)
- iOS release: 44.1s (32.7MB)

---

## [0.5.5] - 2026-06-07

### Added
- Archivio filtrato per data: TimeFilter in MovimentiScreen
- TimeFilter model: day/month/year/customRange con label localizzata
- TimeFilterBar widget (Giorno/Mese/Anno/Periodo con navigazione frecce)

### Changed
- MovimentiScreen ora usa TimeFilter (non più hardcoded current month)
- Dashboard mostra KPI filtrati per periodo

### QA
- 326 test pass (13 nuovi dashboard_filtered_test.dart)
- flutter analyze: 2 pre-existing (in test/, non in lib/)

---

## [0.5.4] - 2026-06-07

### Added
- Calendario Tab: griglia mensile con indicatori di movimento
- Navigazione mese con frecce sinistra/destra
- StreamDatePicker: date picker modale personalizzato

### QA
- 299 test pass

---

## [0.5.3] - 2026-06-06

### Added
- TimeFilter model foundation
- StreamDatePicker: struttura base

### QA
- (incluso in V0.5.4)

---

## [0.5.2] - 2026-06-06

### Added
- StreamDatePicker: design system custom picker

### QA
- (incluso in V0.5.4)

---

## [0.5.1] - 2026-06-06

### Added
- Campo data nei movimenti (date)
- Selezione data durante creazione/modifica

### QA
- (incluso in V0.5.4)

---

## [0.5.0] - 2026-06-06

### Added
- Calendario Foundation: struttura navigazione calendario

### QA
- (incluso in V0.5.4)

---

## [0.4.2] - 2026-06-06

### Changed
- Navigation refactor: Conti, Categorie, Movimenti → "Archivio"
- Bottom navigation: 2 voci (Dashboard, Archivio)
- **MVP COMPLETO** — tutti i criteri MVP soddisfatti

### QA
- 235 test pass (preservati)

---

## [0.4.1] - 2026-06-06

### Added
- Account Icon/Color Refresh: ColorPicker funzionante
- Migration SQLite V5: campo `color` in accounts
- 5 views aggiornate per usare account.color

### Fixed
- **CRITICAL**: Account model mancava campo `color` — tutti gli account mostravano colore default

### QA
- 235 test pass (+15 nuovi account_icon_color_test.dart)

---

## [0.4.0] - 2026-06-06

### Added
- Design System STREAM: colori, tipografia, spaziatura, radius
- Componenti: Card, Input, Button, FAB, BottomNav, Dialog, BottomSheet
- Tema scuro nativo
- Schemas: Dashboard (hero + KPI + empty), Movimenti, Conti, Categorie, Form

### QA
- 193 test pass (preservati)

---

## [0.3.3] - 2026-06-06

### Added
- Human QA 1500: 352 scenari combinatoriali su 30 aree

### Fixed
- **CRITICAL**: DefaultCategories.byId() ignorava rinomina/categorie personalizzate
- flutter analyze: 1 warning → 0 issues

### QA
- 193 test pass (+27 da V0.3.2)
- Android APK debug (Pixel 6)
- iOS IPA debug (iPhone, 7 giorni)

---

## [0.3.2] - 2026-06-06

### Added
- Categorie editabili: CRUD + archivia/ripristina + protezione default
- Confirm Delete dialog (AlertDialog)
- AccountId su Rapidi/Preferiti
- Dashboard dopo delete test: 21 test

### Changed
- Persistenza SQLite per tutte le entità
- AppDatabase + SQLiteService dual layer (cache + raw SQL)
- UUID v4 per ID entities

### Fixed
- Categorie fisse non personalizzabili → CRUD editabile
- Confirm Delete mancante (eliminazione immediata)

### QA
- 166 test pass

---

## [0.3.1] - 2026-06-06

### Added
- SQLite persistenza (sqflite, raw SQL)
- Conti (Accounts): CRUD + saldo, default "Principale" non eliminabile
- Modifica movimento: tap → form precompilato

### Fixed
- **CRITICAL**: Dati persi alla chiusura (nessuna persistenza)
- Dashboard non aggiornata dopo modifica movimento

### QA
- (incluso in V0.3.2)

---

## [0.3.0] - 2026-06-06

### Added
- Depth Layer: struttura base SQLite, Conti, Categorie

### QA
- (incluso in V0.3.2)

---

## [0.2.0] - 2026-06-05

### Added
- Speed Layer: Duplica movimento
- Movimenti Rapidi: 4 default + CRUD
- Movimenti Preferiti: CRUD + salva da esistente
- Suggeriti automatici (threshold >=5)
- Note toggle (SharedPreferences)
- MovementPicker modale con SegmentedButton

### Fixed
- **CRITICAL**: Separatore decimale virgola non supportato
- **HIGH**: Dashboard non aggiornata dopo salvataggio

### QA
- 65 test pass
- flutter analyze: 0 issues
- Build APK: 5.8s

---

## [0.1.0] - 2026-06-05

### Added
- Core Layer: inserimento movimento manuale
- Dashboard KPI: entrate/uscite/saldo del mese
- Lista movimenti completa
- Validazione input
- In-memory database (AppDatabase)
- Modelli: Movement, Category, Account

### QA
- 50 test pass
- flutter analyze: 0 issues
- Build APK debug: 13s
