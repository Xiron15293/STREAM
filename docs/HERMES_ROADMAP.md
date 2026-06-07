# HERMES ROADMAP

> Cronologia versioni Hermes — rilasci e pianificazione.

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

## Approvate / Future

| Versione | Nome | Stato |
|----------|------|-------|
| V0.5.6 | UX Booster (Ricerca Globale, Preferiti, Categorie Frequenti, Heatmap) | 💡 PROPOSTO |
| V0.4.3 | Quick/Favorite Movement Library UX | 📋 APPROVATA |
| — | Calendar Heatmap / Category Heatmap | 📋 APPROVATA |
| V0.6 | Ricorrenze | 💡 IDEA |
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
| V0.5 | Calendario Foundation — ✅ COMPLETATO (6 sub-features) |
| V0.5.6 | UX Booster (💡) — Ricerca Globale, Preferiti Rapid, Categorie Frequenti, Calendar Heatmap |
| V0.6 | Ricorrenze (💡) — movimenti automatici ricorrenti |
| V0.7 | Athena Foundation (💡) — Budget, AI categorization, insight |
| V0.8 | Import CSV (💡) — import movimenti da home banking |
| V0.9 | Scenari (💡) — proiezioni what-if, pianificazione |
| V0.4.3 | Quick/Favorite Movement Library UX (📋) — ricerca, filtri, salva da manuale, aggiorna preferito |
| V0.4.x | Inline Form Validation (📋) — errori inline nei form |
| V0.5+ | UI Inspiration Review (🔄) — revisione pattern esterni |
| V1.0 | Prima Beta STREAM (⏳) — distribuzione pubblica |
| V1.0+ | Adaptive / Tablet Layout (💡) — layout reattivi |
| V1.2 | Cloud Sync (⏳) — backup premium, multi-dispositivo |

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

### V0.5.5 — Dashboard Filtrata per Periodo ✅

> **Feature**: F16 — Dashboard Filtrata per Periodo
> **Test**: 13 nuovi (10 logica + 3 widget) | test/dashboard_filtered_test.dart
> **Refactor**: MovementCard unico (+14 test) | test/movement_card_test.dart
> **Risultato**: 326 test pass | flutter analyze: 2 pre-existing

**Riutilizzato**:
- `TimeFilter` (lib/models/time_filter.dart) — invariato
- `TimeFilterBar` (lib/widgets/time_filter_bar.dart) — già usata in CalendarScreen
- `filterByTime()` — già implementata su `List<Movement>`

**KPI filtrati** (dipendono dal periodo selezionato):
- Entrate periodo, Spese periodo, Saldo periodo, Numero movimenti

**KPI non filtrati** (sempre globali):
- Patrimonio totale (totalAccountsBalance), Saldi conti

**UI**:
- `TimeFilterBar` sopra la hero card (Giorno/Mese/Anno/Periodo + navigazione frecce)
- Default: mese corrente
- KPI grid 2×2 (Entrate, Uscite, Saldo, Movimenti)
- Ultime transazioni filtrate (last 5 del periodo)
- Empty state: "Nessun movimento nel periodo selezionato" quando il periodo è vuoto ma ci sono movimenti globali

**Vincoli rispettati**:
- Nessuna modifica DB, migration, Bundle ID, applicationId
- Nessuna modifica a Calendario, Archivio, popup movimenti
- DashboardScreen convertita da StatelessWidget a StatefulWidget

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
- UI originale STREAM — non copiare app esterne
- Palette STREAM esistente (StreamColors) per colori heatmap

---
