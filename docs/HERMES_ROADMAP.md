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
| — | Async/Timing Audit + Fix (Audit sistemico per `void async`, fire-and-forget, race condizioni su 47 file) | ✅ COMPLETATO | 2026-06-08 |
| V0.6 | Dashboard Filtrata per Periodo — V2 (lista movimenti, azione rapida per categoria, fix TimeFilterBar Periodo picker) | ✅ COMPLETATO | 2026-06-08 |

## Approvate / Future (V0.6.x+)

| Versione | Nome | Stato |
|----------|------|-------|
| V0.6.0 | Raggruppamento Movimenti per Giorno | 📋 APPROVATA |
| V0.6.1 | Click Categoria Dashboard | 📋 APPROVATA |
| V0.6.2 | Ricerca Globale Movimenti | 📋 APPROVATA |
| V0.6.3 | UX Movimenti Rapidi/Preferiti — Data Picker | 📋 APPROVATA |
| V0.6.4 | Calendar Heatmap | 📋 APPROVATA |
| V0.6.5 | Beneficiario ed Etichette | 📋 APPROVATA |
| V0.6.6 | Trasferimenti tra Conti | 📋 APPROVATA |
| V0.7 | Athena Foundation (Budget, AI, Insight) | 💡 IDEA |
| V0.8 | Import CSV | 💡 IDEA |
| V0.9 | Scenari | 💡 IDEA |
| V1.1 | Cloud Sync (backup premium, multi-dispositivo) | 💡 IDEA |

Vedi **`docs/STREAM_FEATURE_BACKLOG.md`** per censimento completo (32 feature, tutte classificate).

## Backlog completo

Tutte le feature (approvate, in valutazione, future, post-MVP) sono censite in:
📋 **`docs/STREAM_FEATURE_BACKLOG.md`** — fonte di verità unica (32 feature).

## Visione futura  

| Versione | Focus |
|----------|-------|
| V0.6.0 | Raggruppamento Movimenti per Giorno (📋) — header data, separatore, scroll |
| V0.6.1 | Click Categoria Dashboard (📋) — navigazione Dashboard→Archivio con filtro categoria |
| V0.6.2 | Ricerca Globale Movimenti (📋) — ricerca testo + filtro periodo + raggruppamento |
| V0.6.3 | UX Rapidi/Preferiti — Data Picker (📋) — Oggi/Ieri/Domani/Scegli data |
| V0.6.4 | Calendar Heatmap (📋) — intensità colore, filtro categoria, navigazione |
| V0.6.5 | Beneficiario ed Etichette (📋) — model SQLite migration, UI, backup V2 |
| V0.6.6 | Trasferimenti tra Conti (📋) — MovementType.transfer, saldo duale, backup V3 |
| V0.7 | Athena Foundation (💡) — Budget, AI categorization, insight |
| V0.8 | Import CSV (💡) — import movimenti da home banking |
| V0.9 | Scenari (💡) — proiezioni what-if, pianificazione |
| V1.0 | Prima Beta STREAM (⏳) — distribuzione pubblica |
| V1.0+ | Adaptive / Tablet Layout (💡) — layout reattivi |

---

## Dettaglio feature per versione

### V0.1 — Core Layer ✅
- Form movimento completo (titolo, importo, categoria, nota)
- CRUD base movimento
- Dashboard con KPI (entrate, uscite, saldo, ultimi)
- Lista movimenti con ordinamento e scroll
- Validazione input (importo >0, titolo non vuoto)
- Supporto virgola e punto decimale (Bug #1 corretto)
- Dashboard aggiornata dopo salvataggio (Bug #2 corretto)
- 50+ test automatici

### V0.2 — Speed Layer ✅
- Duplica movimento (immediata, 2 tap dal menu ⋮)
- Movimenti Rapidi (4 default + CRUD)
- Movimenti Preferiti (CRUD + salva da esistente)
- Suggeriti automatici (soglia ≥5)
- Mini-tab Manuale/Rapidi/Preferiti (SegmentedButton)
- Note visibili in lista (toggle ON/OFF persistente con SharedPreferences)
- 73 test automatici, nessuna regressione V0.1

### V0.3 — Depth Layer ✅
- **SQLite** — persistenza dati (Drift/sqflite)
  - Movimenti, Rapidi, Preferiti persistono su disco
  - Cache in-memory + SQLite come source of truth
  - Auto-caricamento all'avvio
- **Conti** — gestione conti correnti
  - CRUD conti
  - Saldo per conto in Dashboard
  - Assegnazione conto nei movimenti
- **Modifica movimento** — tap movimento → form precompilato
- **Confirm Delete** — dialog di conferma prima di eliminare
- **Categorie editabili** — CRUD + archivia/ripristina
  - Categoria con nome, tipo, colore
  - Protezione cancellazione se usata
  - 17 test dedicati
- **AccountId Rapidi/Preferiti** — fix allineamento account
- **Dashboard dopo delete** — KPI aggiornati confermati (21 test)

### V0.3.3 — Human QA 1500 ✅
- QA estesa: 352 scenari combinati unici in 30 aree
- Bug CRITICAL trovato e corretto: Category Rename Consistency (`DefaultCategories.byId`)
- Fix applicato in 6 punti (Movimenti, Dashboard, Picker Rapidi, Picker Preferiti)
- +27 test automatici (10 rename + 17 risky)
- 193 test automatici totali, 0 issue analyze
- Build Android e iOS verificati

### V0.4 — Design System STREAM ✅
- Dark mode completo: tema Material 3 scuro in `lib/theme.dart`
- Palette STREAM: canvas `#0C0E12`, surface `#15171D`, primary `#4B7BFF`, income `#34C759`, expense `#FF453A`
- Typography system: display 40px → micro 11px, tutti via `StreamTypography`
- Spacing system: `StreamSpacing` (xs=4 → section=32)
- Border radius scale: `StreamRadius` (sm=8 → xl=20)
- Componenti temizzati: Card, Input, Button, FAB, BottomNav, Dialog, BottomSheet, SegmentedButton, Switch, SnackBar, PopupMenu, DatePicker
- Dashboard: hero card patrimonio con gradiente, KPI grid 3 colonne, empty state
- Movimenti: card compatte con note inline, popup menu aggiornato
- Conti: card con icona rettangolare colorata, saldo prominente
- Categorie: card con badge tipo colorato, count badge sezioni
- Form: input filled senza bordo, dropdown consistenti
- 0 issue analyze, 193 test preserved, build APK e iOS OK

### V0.4.1 — Account Icon/Color Refresh ✅
- **Root cause**: Account model mancava campo `color`. ColorPicker decorativo — colore mai salvato. Account rendering usava `StreamColors.primary` hardcoded.
- **Fix**: Aggiunto `int color` ad Account model (default `0xFFEF5350`). SQLite V5 migration aggiunge `color INTEGER`. `updateAccount()` accetta `color` opzionale. `archiveAccount()` preserva iconKey e color.
- **Views aggiornate**: accounts_screen (card bg usa account.color), movement_form (dropdown icon usa account.color), movement_picker (3 punti, icon account usa account.color), dashboard_screen (tile movimento mostra icon account con colore), movements_screen (card movimento mostra icon account con colore).
- **Regola**: Views devono sempre risolvere `accountId → db.accounts` per nome/tipo/colore/iconKey. Mai hardcoded.
- **Test**: test/account_icon_color_test.dart (15 nuovi test)
- **Total tests**: 235/235 (220 + 15) | flutter analyze: 0 errors
- **Future**: Categorie ordinabili manualmente (V0.5+) con `categories.sort_order INTEGER`

### V0.4.2 — Navigation Refactor: Archivio ✅
- **Spostate** le tab Movimenti, Conti, Categorie dentro una singola tab "Archivio"
- **Nuova schermata**: `lib/screens/archive_screen.dart` con `SegmentedButton` interno
  - Sezioni: Movimenti (Icons.swap_vert), Conti (Icons.account_balance), Categorie (Icons.category)
  - `IndexedStack` preserva lo stato di ogni sezione
- **SafeArea fix**: Archivio avvolto in `SafeArea` con padding top 12px oltre safe area — compatibile con Dynamic Island, notch, punch hole, tablet
- **Bottom nav**: ora 2 elementi — Dashboard, Archivio
- **Rapidi e Preferiti** restano sotto Movimenti
- **Nessuna migrazione database** — solo refactor navigazione
- **Test**: 235/235 preserved | flutter analyze: 0 errors in lib/

### V0.5.6 — Dashboard Filtrata per Periodo ✅

> **Feature**: F16 — Dashboard Filtrata per Periodo
> **Test**: 363 test pass
> **Risultato**: `flutter analyze` pulito; build release native **PASS** dopo fix KGP per `file_picker`

**Struttura reale attuale**
- `Dashboard` = sintesi/insight del periodo selezionato, non lista movimenti
- `Archivio` = area operativa con Movimenti / Conti / Categorie / Calendario
- `Impostazioni` = Backup & Restore e voci di configurazione future

**Riutilizzato**:
- `TimeFilter` (lib/models/time_filter.dart) — invariato
- `TimeFilterBar` (lib/widgets/time_filter_bar.dart) — già usata in CalendarScreen
- `filterByTime()` — già implementata su `List<Movement>`

**KPI filtrati** (dipendono dal periodo selezionato):
- Entrate periodo
- Spese periodo
- Saldo periodo
- Numero movimenti periodo
- Totale spese per categoria nel periodo

**KPI non filtrati** (sempre globali):
- Patrimonio totale (totalAccountsBalance)
- Saldi conti
- Fondi / situazione conti attuale

**UI**:
- `TimeFilterBar` sopra la hero card (Giorno/Mese/Anno/Periodo + navigazione frecce)
- Default: mese corrente
- Card patrimonio/situazione attuale non filtrata dal periodo
- KPI grid periodo con confronto spese rispetto al periodo precedente quando semplice
- Sezione `Spese per categoria` al posto della lista movimenti
- Massimo 5 categorie visibili, ordinate per spesa decrescente
- Categoria più costosa leggermente evidenziata
- Empty state: `Nessuna spesa nel periodo selezionato`

**Vincoli rispettati**:
- Nessuna modifica a database, migration, model
- Nessuna lista movimenti in Dashboard
- Nessuna modifica a Backup/Restore, navigazione o Archivio
- DashboardScreen resta la fonte della sintesi del periodo

### Build release Android fix

**Root cause**: `file_picker 11.0.2/android/build.gradle` ha una condizione `if (!isAgp9OrAbove) apply plugin: 'org.jetbrains.kotlin.android'`. Con AGP 9.0.1, KGP non viene applicato. Flutter's `detectApplyingKotlinGradlePlugin` legge il testo del build file, trova `kotlin.android`, e salta l'applicazione. Risultato: sorgenti Kotlin non compilate → `FilePickerPlugin` assente.

**Fix** (`android/build.gradle.kts`): `subprojects` block applica KGP a `file_picker` prima della sua evaluation, e forza `jvmTarget=17`.

**Esito**: `flutter build apk --release` ✅ (66.1MB)

### Backup export condivisibile (share sheet)

**Aggiunta**: dipendenza `share_plus ^12.0.2`. Dopo "Crea backup", SnackBar con pulsante "Condividi" apre share sheet nativo. Ogni backup nella lista "Backup salvati" ha icona share.

- **Android**: `Intent.ACTION_SEND` → Drive, email, Downloads
- **iOS**: `UIActivityViewController` → Files, iCloud, Mail, AirDrop
- Se la condivisione fallisce, il backup interno resta salvato

### Refactor: MovementCard unico (architetturale)

> Non è una feature ma un refactor architetturale. Elimina 3 duplicazioni di layout movimento.

**Problema**: Ogni schermata aveva il proprio widget privato per renderizzare un movimento:
- `DashboardScreen._MovementTile` (40×40 icon, no date, no popup)
- `CalendarScreen._CalendarMovementCard` (36×36 icon, no date, no popup)
- `MovementsScreen._MovementCard` (36×36 icon, date, notes, popup menu)

**Soluzione**: `lib/widgets/movement_card.dart` — widget unico, riutilizzabile, con callback per azioni.

**API**:
| Prop | Tipo | Default | Usato da |
|------|------|---------|----------|
| movement | Movement | required | tutti |
| category | Category? | null | tutti |
| account | Account? | null | tutti |
| onTap | VoidCallback? | null | Calendar (→ edit) |
| onEdit | VoidCallback? | null | Movements |
| onDuplicate | VoidCallback? | null | Movements |
| onSaveAsFavorite | VoidCallback? | null | Movements |
| onDelete | VoidCallback? | null | Movements |
| showNotes | bool | false | Movements |
| showDate | bool | false | Movements |

**Icona fissa**: 36×36 px in tutte le schermate (standardizzato, era 40×40 in Dashboard).
**Test**: 14 nuovi widget test in `test/movement_card_test.dart`.
**Risultato**: 326 test pass | flutter analyze: 2 pre-existing.

**UI note**
- Fix `heroTag` FAB: i tag Hero devono restare univoci o assenti quando più FAB possono convivere tra schermate, per evitare collisioni in transizione.

---

## Feature future approvate

### V0.4.3 — Quick/Favorite Movement Library UX 📋 APPROVATA

> Feature approvata, non ancora implementata. Da pianificare prima o durante V0.5.

**Problema**: Quando Rapidi e Preferiti diventano molti, la navigazione corrente (semplice lista verticale) non scala. L'utente fatica a trovare il template giusto.

**Soluzione proposta**:

#### 1. Ricerca rapidi/preferiti
- Campo di ricerca testuale nei tab Rapidi e Preferiti del popup aggiunta movimento
- La ricerca trova occorrenze per: nome movimento, categoria, conto, note, importo
- Match parziale e case-insensitive

#### 2. Filtro per categoria
- Filtro dropdown per categoria nei tab Rapidi e Preferiti
- Utile quando la lista supera 10-15 elementi
- Mostra solo i template associati alla categoria selezionata

#### 3. Salva da Manuale
- Dal tab Manuale del popup aggiunta movimento, possibilità di salvare il movimento corrente come:
  - Nuovo Rapido
  - Nuovo Preferito
- Salva titolo, importo, categoria, conto, nota come template

#### 4. Aggiorna Preferito esistente
- Da Manuale o da modifica movimento: opzione "Aggiorna preferito esistente"
- Permette di aggiornare importo, conto, categoria o nota di un preferito senza duplicarlo

#### 5. Vincoli architetturali
- Non duplicare logica tra Rapidi e Preferiti — helper condivisi
- Rapidi e Preferiti restano template/scorciatoie, non movimenti reali
- Nessuna modifica al database senza progettazione dedicata
- Nessuna confusione tra movimento reale e template rapido/preferito
- Popup CRUD movimenti invariato nella struttura (Manuale / Rapido / Preferito)

#### 6. Posizionamento roadmap
- Può essere V0.4.3 (prima di Calendario) o integrata in V0.5
- Dipende da priorità: UX rapidi/preferiti vs Calendario

### Calendar Heatmap / Category Heatmap 📋 APPROVATA

> Feature approvata, non implementata. Evoluzione visuale di V0.5 Calendario Foundation.
> Dipende da: date nei movimenti + TimeFilter globale (V0.5 Foundation).

**Problema**: La vista calendario testuale non dà un colpo d'occhio immediato su come sono distribuite spese, entrate e saldo nel mese.

**Soluzione proposta**:

- Griglia mensile con giorni in celle
- Ogni giorno ha un colore/intensità basata sui dati finanziari
- Modalità visive:
  - **Totale spese** — rosso più intenso = più speso
  - **Totale entrate** — verde più intenso = più guadagnato
  - **Saldo netto** — colore duale (verde/rosso) con intensità
- **Filtro per singola categoria** — heatmap limitata a una categoria specifica
- **Tap su giorno** → lista movimenti del giorno (riusa logica V0.5)
- **Tap/azione rapida** → aggiungi movimento con data precompilata
- **Totale mese** in basso (entrate, spese, saldo)
- **Navigazione** mese precedente/successivo

**Vincoli**:
- Prima implementare V0.5 Foundation: date nei movimenti e TimeFilter globale
- Heatmap usa dati già disponibili, nessuna nuova tabella SQLite

---

## V0.6 — Dashboard Filtrata per Periodo V2 ✅

> **Feature**: V0.6 — Evoluzione Dashboard con lista movimenti filtrata, azione rapida categorie, IntervalPickerSheet, dettaglio categoria
> **Test**: 426 test pass (+14) | `flutter analyze` 0 issues
> **Build**: APK 66.1MB ✅ | iOS 32.6MB ✅
> **QA**: 500 scenari analizzati, 416 coperti, 84 gap, 14 nuovi test implementati

**Cosa è stato fatto** (V0.6 completa):

### 1. IntervalPickerSheet (sostituisce showDateRangePicker)
- Nuovo widget `lib/widgets/interval_picker_sheet.dart`: bottom sheet dedicato
- Header "Seleziona intervallo", Da/A cards tappabili, Annulla/Applica
- Tap su Da o A apre `StreamDatePicker.show()` individualmente
- Validazione: "Applica" disabilitato se A < Da; Annulla non modifica filtro attivo
- Label intervallo: formato breve "15 giu → 30 giu" (compact per SegmentedButton)
- "Periodo" rinominato in "Intervallo" nel SegmentedButton

### 2. Lista movimenti filtrata in Dashboard
- Nuova sezione `_FilteredMovementsList` sotto le spese per categoria
- Mostra fino a 20 movimenti del periodo selezionato
- Usa `MovementCard` con `showDate: true` per data visibile
- Se >20 movimenti, mostra "Mostra tutti: altri N movimenti in Archivio"
- Si aggiorna in tempo reale al cambio filtro (ListenableBuilder)
- Non appare se il periodo non ha movimenti (SizedBox.shrink)

### 3. Fix CRITICAL — IntervalPickerSheet mai aperto
- **Problema**: `_onModeChanged(customRange)` non chiamava `onChanged`, quindi `_pickDate` leggeva `activeFilter.mode == month` e apriva il picker mese.
- **Fix**: `_pickDate` accetta `forcedMode` parametro. `_onModeChanged(customRange)` passa `forcedMode: TimeFilterMode.customRange`.
- **Prima**: Tap "Intervallo" → month picker (BUG)
- **Dopo**: Tap "Intervallo" → IntervalPickerSheet con Da/A cards

### 4. Categoria dettaglio bottom sheet
- `_CategoryExpenseRow` tappabile (Expanded+GesterDetector layout fix)
- `_CategoryDetailSheet`: nome, totale, conteggio, movimenti filtrati nel periodo

### 4. Azione rapida "+" per categoria
- Ogni riga "Spese per categoria" ha icona `add_circle_outline`
- Apre `MovementPicker` con categoria pre-selezionata
- Nuovo parametro `categoryPreFill` in `MovementPicker` → `_ManualForm`
- Dopo salvataggio, il movimento appare subito nella lista se rientra nel periodo
- Form precompilato: tipo (entrata/uscite) e categoria già impostati

### 5. TimeFilter.contains() fix
- `contains()` ora usa `!cmp.isBefore(startDate) && !cmp.isAfter(endDate)`
- Normalizzazione timezone: tutti tre i DateTime convertiti a `DateTime(year,month,day)` (local time)
- `customRange` preserva la data esatta scelta dall'utente (no +1 day offset)
- Comportamento inclusivo: `endDate` incluso nel range

### 6. Test aggiunti
- `dashboard_filtered_test.dart`: +22 test
  - 2.5–2.8: Lista movimenti filtrata, limite 20, cambio filtro
  - 3.1: Pulsante "Intervallo" esiste ed è tappabile
  - 4.1–4.3: Stress test 1000 movimenti (mese, patrimonio invariato, custom range)
- `time_filter_bar_test.dart`: label "Intervallo" aggiornata
- `time_filter_test.dart`: label customRange + contains() inclusivo

### 7. Dettaglio implementazione

**File modificati:**
| File | Modifica |
|------|----------|
| `lib/widgets/interval_picker_sheet.dart` | **NUOVO** — `showIntervalPicker()` + `_IntervalPickerSheet` |
| `lib/screens/dashboard_screen.dart` | +MovementPicker, +_FilteredMovementsList, +quickAdd, +_CategoryDetailSheet |
| `lib/widgets/time_filter_bar.dart` | "Periodo"→"Intervallo", `showDateRangePicker`→`showIntervalPicker` |
| `lib/models/time_filter.dart` | customRange label formato breve, `_shortMonthNames`, contains() fix |
| `test/time_filter_bar_test.dart` | label "Intervallo" |
| `test/time_filter_test.dart` | label customRange + contains assert |
| `test/dashboard_filtered_test.dart` | +22 test completi |
| `docs/CHANGELOG.md` | **NUOVO** — release history V0.1–V0.6 |

**API MovementPicker** (aggiunta):
| Parametro | Tipo | Default | Scopo |
|-----------|------|---------|-------|
| `categoryPreFill` | `String?` | null | Pre-seleziona categoria nel form manuale |

**Vincoli rispettati:**
- Nessuna modifica a model, database, SQLite migration
- Nessuna duplicazione logica di creazione movimento
- Nessuna modifica ad altre schermate (Calendar, Archivio, Movimenti, Impostazioni)
- Tutti i KPI non filtrati (patrimonio, saldi conti) restano globali
- MovementCard riusato per ogni riga movimento
- UI originale STREAM — non copiare app esterne
- Palette STREAM esistente (StreamColors) per colori heatmap

---
