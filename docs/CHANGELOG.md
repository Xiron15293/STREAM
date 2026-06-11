# CHANGELOG

All notable changes to STREAM will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- **V0.8.7 — Heatmap Settings**
  - soglie heatmap configurabili da `Impostazioni > Heatmap`
  - colori heatmap configurabili da palette di 12 colori
  - anteprima visiva in tempo reale delle bande colore
  - editor soglie con 6 campi numerici e validazione
  - editor colori per ogni banda con palette modale
  - ripristino default con pulsante dedicato
  - persistenza via SharedPreferences: `heatmap_thresholds`, `heatmap_colors`
  - fallback a default se preferenze corrotte
  - aggiornamento live della heatmap Movimenti e legenda via `ValueListenableBuilder`
  - Treemap Categorie separata: continua a usare `category.color`, non toccata
- **V0.8.6 — Category Treemap Analytics**
  - Treemap aggiunta nella schermata `Categorie` come quarta modalita visiva dedicata
  - treemap stile market map:
    - ogni blocco rappresenta una categoria
    - area proporzionale al totale categoria nel periodo selezionato
    - colore basato su `category.color`
    - mostra nome categoria, importo e/o numero movimenti
  - supporto filtri periodo gia presenti in Categorie:
    - Giorno
    - Mese
    - Anno
    - Intervallo
  - supporto ordinamenti:
    - totale decrescente
    - totale crescente
    - nome A-Z
    - numero movimenti decrescente
  - transfer esclusi dai totali categoria
  - tap su blocco categoria apre il dettaglio/sheet categoria esistente
  - empty state dedicato quando non ci sono dati nel periodo
  - nessun DB/schema modificato

### Changed
- Soglie e colori heatmap non più hardcoded: `heatmapColorForAmount()` e `heatmapBandIndex()` accettano `HeatmapSettings` opzionale
- `HeatmapSettings` class introdotta in `heatmap_utils.dart` con validazione, bands dinamiche e label legenda configurabili
- `PreferencesService` esteso con `heatmapSettingsNotifier`, chiavi `heatmap_thresholds`/`heatmap_colors`, metodi load/save/restore
- `MovementsScreen.initState()` carica `loadHeatmapSettings()` per inizializzare il notifier
- `ExpenseHeatmap` e `HeatmapLegend` usano `ValueListenableBuilder<HeatmapSettings>` per aggiornamenti live
- `clearForReset()` non pulisce le preferenze heatmap (impostazioni visive sopravvivono al reset dati)

### Unchanged
- Treemap Categorie separata: continua a usare `category.color`, non influenzata dalle impostazioni heatmap
- Colori e soglie heatmap di default invariati rispetto a V0.8.5
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto

### QA
- `flutter analyze --no-pub`: PASS, 0 issues
- `flutter test --no-pub`: **672/672 All tests passed**
- Test mirati:
  - `test/heatmap_settings_test.dart`: 7 tests (defaults, corruption, invalid save, UI controls, threshold edit, rejection, color update, treemap separation)
  - `test/movements_view_modes_test.dart`: PASS
  - `test/categories_treemap_test.dart`: PASS
  - `test/categories_layout_test.dart`: PASS
  - `test/qa_movements_test.dart`: PASS (nota: warning hit-test noto sul bottone Salva, non blocca)

---

### Planned
- FASE 4 — Lista Movimenti Premium:
  - heatmap annuale stile reference utente
  - card giornaliere aggregate
  - layout premium
- QA hardening opzionale:
  - risolvere warning hit-test sul bottone Salva nei test
  - non indebolire test

---

- **V0.8.5 — Movimenti Analytics e Heatmap**
  - Archivio riorganizzato: tab visibili `Movimenti`, `Conti`, `Categorie`
  - tab Calendario separata rimossa; il calendario ora vive dentro `Movimenti`
  - `Movimenti` ha modalità interne `Lista`, `Calendario`, `Heatmap`
  - selector interno Movimenti con preferenza persistita via `PreferencesService` / Settings
- **Heatmap Movimenti**
  - heatmap basata sulle uscite
  - income e transfer esclusi da colori e metriche heatmap spese
  - legenda/range heatmap
  - utility dedicate in `lib/utils/heatmap_utils.dart`
  - widget dedicato `lib/widgets/expense_heatmap.dart`
- **Preview heatmap compatta**
  - sostituita la striscia orizzontale fragile con preview card compatta in Lista
  - file `lib/widgets/movements_heatmap_preview_card.dart`
  - bottone `Apri calendario`
  - nessun overlay sopra `MovementCard`

### Changed
- Search + Heatmap rese coerenti:
  - pipeline esplicita con `periodFilteredMovements`, `searchFilteredMovements`, dati per lista/heatmap/riepilogo
  - la ricerca filtra anche i dati della heatmap
  - ricerca case-insensitive/parziale su titolo, nota, categoria e conto
- Treemap spostata concettualmente fuori da Movimenti:
  - la visualizzazione analitica per categorie vive ora in `Categorie`
  - `Movimenti` mantiene Lista / Calendario / Heatmap
- Filtro periodo corretto in Movimenti:
  - Giorno mostra movimenti del giorno
  - Mese mostra tutti i movimenti del mese
  - Anno mostra tutti i movimenti dell'anno
  - Intervallo mostra tutti i movimenti dell'intervallo
  - `selectedDay` non limita piu Mese/Anno/Intervallo
- Picker data/anno reso coerente:
  - aggiorna selected date / mese visibile / heatmap / lista quando previsto
  - `TimeFilterBar` supporta `onDatePicked`

### Fixed
- Menu `MovementCard` stabile:
  - `showMenu` sperimentale non presente
  - resta `PopupMenuButton`
  - key `movement_card_action`
  - menu `...` tappabile e stabile

### Unchanged
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push
- Colori heatmap invariati
- Annual heatmap premium / redesign completo Lista non implementati

### QA
- `flutter analyze --no-pub`: PASS
- `flutter test --no-pub`: **664/664 All tests passed**
- Test mirati:
  - `test/categories_treemap_test.dart`: 10 passed
  - `test/categories_layout_test.dart`: 28 passed
  - `test/movements_view_modes_test.dart`: PASS
  - `test/accounts_navigation_test.dart`: 8 passed
  - `test/categories_navigation_test.dart`: 5 passed
  - `test/qa_movements_test.dart`: 85 passed

---

## [0.8.4] - 2026-06-10

### Added
- **Interactive Category/Account Menus**
  - tap categoria apre uno sheet interattivo unico con header, riepilogo periodo, azioni rapide e lista movimenti filtrata
  - tap conto apre uno sheet interattivo unico con header, saldo storico/as-of, riepilogo periodo, azioni rapide e lista movimenti filtrata
- **Category sheet**
  - header con icona, nome, tipo e stato
  - totale e conteggio movimenti nel periodo
  - azioni: Movimento, Modifica, Archivia/Ripristina
  - `MovementPicker` aperto con categoria e tipo precompilati
  - transfer esclusi dalla lista/totali categoria
- **Account sheet**
  - header con icona, nome e stato
  - saldo al termine del periodo coerente con V0.8.3
  - riepilogo periodo: entrate, uscite, trasferimenti netti, saldo inizio periodo, movimenti
  - azioni: Movimento, Trasferisci, Modifica, Archivia per conti attivi
  - `MovementPicker` supporta `accountPreFill` e `initialType`
  - azione Trasferisci apre il form in modalità transfer con conto origine precompilato

### Unchanged
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Formula saldo conto V0.8.3 invariata
- Transfer ancora esclusi da Entrate/Uscite/Bilancio globali e inclusi nei saldi conto
- Nessuno skip aggiunto
- Nessun commit/push
- Ripristino conto archiviato non aggiunto: non esisteva API esistente da riusare

### QA
- `flutter analyze --no-pub`: 0 issues
- `flutter test --no-pub`: **627/627 All tests passed**

---

## [0.8.3] - 2026-06-10

### Added
- **Date Filter in Categories and Accounts**
  - filtro periodo nella schermata principale Categorie, riusando `TimeFilter`, `filterByTime()` e `TimeFilterBar`
  - filtro periodo nella schermata principale Conti, riusando gli stessi componenti già presenti in Dashboard/Movimenti
  - il filtro pagina viene passato ai bottom sheet di dettaglio categoria/conto come periodo iniziale
- **Categorie**
  - KPI categorie filtrati per periodo
  - totali e conteggi nei layout Card Stream filtrati per periodo
  - ordinamento Top categorie in Lista grouped basato sui movimenti del periodo
  - transfer esclusi dai totali categoria perché il filtro lavora solo su income/expense
- **Conti**
  - riepilogo periodo per conto: entrate, uscite, trasferimenti netti e numero movimenti
  - saldo conto visibile storico/as-of: `initialBalance + impatto di tutti i movimenti con data <= fine periodo`
  - saldo inizio periodo: `initialBalance + impatto di tutti i movimenti con data < inizio periodo`
  - movimenti netti periodo: entrate periodo - uscite periodo + trasferimenti netti periodo
  - dettaglio conto allineato allo stesso criterio di saldo storico al termine del periodo
- Helper centralizzati in `movement.dart`:
  - `transferNetForAccount`
  - `periodTransferNetForAccount`
  - `movementNetForAccount`
  - `periodNetForAccount`
  - `balanceForAccountUntil`
  - `balanceForAccountBefore`

### Fixed
- Corretto il saldo periodo dei conti: non usa più `initialBalance + solo movimenti del periodo`, formula insufficiente per rispondere a "quanti soldi avevo a gennaio?".
- Test dei bottom sheet conti/categorie aggiornati per distinguere la `TimeFilterBar` principale da quella del dettaglio.
- Test legacy Card Stream resi più precisi quando lo stesso importo appare sia nel riepilogo sia nella card.

### Unchanged
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push

### QA
- Test mirati:
  - `test/categories_layout_test.dart`
  - `test/categories_navigation_test.dart`
  - `test/accounts_test.dart`
  - `test/accounts_navigation_test.dart`
- `flutter analyze --no-pub`: 0 issues
- `flutter test --no-pub`: **625/625 All tests passed**

---

## [0.8.2] - 2026-06-10

### Fixed
- **Financial KPI Corrections**
  - i trasferimenti sono esclusi da Entrate/Uscite/Bilancio globali
  - Dashboard corretta: non usa più logica ambigua `if income else expense`
  - Entrate = solo `MovementType.income`
  - Uscite = solo `MovementType.expense`
  - Bilancio = Entrate - Uscite
- **Spese per categoria**
  - somma solo movimenti `expense`
  - eventuali transfer con `categoryId` valorizzato non entrano nei totali categoria
- **Riepiloghi giornalieri**
  - `DailyMovementGroup.totalIncome` e `totalExpenses` sono esclusivi income/expense
  - i transfer restano visibili nello storico movimenti ma neutrali per i KPI giornalieri

### Added
- Helper centralizzati in `movement.dart`:
  - `isIncome`
  - `isExpense`
  - `isTransfer`
  - `sumIncome`
  - `sumExpenses`
  - `sumTransfers`
  - `netIncomeExpense`

### Unchanged
- Formula saldo conto invariata:
  - `initialBalance + income - expense + transfer in/out`
- I transfer continuano a modificare correttamente saldo conto origine e destinazione
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati

### QA
- Caso reale Giugno 2026 verificato:
  - Entrate `1142.52`
  - Uscite `328.08`
  - Bilancio `+814.44`
  - transfer `272.30` escluso dai KPI globali
- Caso reale Maggio 2026 verificato:
  - Entrate `1447.97`
  - Uscite `2115.10`
  - Bilancio `-667.13`
  - transfer `1187.50` escluso dai KPI globali
- Test aggiunti/aggiornati:
  - KPI periodo con income/expense/transfer
  - Dashboard giugno/maggio 2026
  - spese per categoria ignorano transfer
  - riepilogo giornaliero ignora transfer nei totali income/expense
  - saldo conto transfer invariato
- `flutter analyze --no-pub`: 0 issues
- `flutter test --no-pub`: **619/619 All tests passed**
- Nessuno skip aggiunto
- Nessun commit/push

---

## [0.8.1] - 2026-06-10

### Added
- **Filtro Entrate/Uscite** nella schermata Categorie
  - SegmentedButton sopra la lista: `[ Uscite | Entrate ]`
  - default: Uscite
  - mostra solo categorie del tipo selezionato
  - le categorie archiviate rispettano lo stesso filtro
  - contatori/sezioni aggiornati coerentemente
- **3 Layout Mode** per la schermata Categorie, selezionabili da Impostazioni > Aspetto > Modello categoria
  - **Lista pulita** (default): tile semplice con icona, nome, popup menu
  - **Lista grouped**: raggruppato in card con header sezione, divisori tra righe
  - **Card Stream**: card con bordo outline, icona, nome, conteggio movimenti, popup menu
- **Preferenza persistente** `category_layout` via SharedPreferences
  - `PreferencesService.categoryLayoutNotifier` per aggiornamenti in tempo reale
  - aggiunta a `clearForReset()`
- **FAB precompila tipo** in base al filtro attivo:
  - se su Entrate → nuova categoria di tipo Entrata
  - se su Uscite → nuova categoria di tipo Uscita
  - l'utente può comunque cambiare tipo manualmente nel form
- **Sezione Aspetto** nelle Impostazioni con voce "Modello categoria"
  - dialog di selezione con 3 opzioni + descrizione
  - RadioGroup pattern (Flutter 3.44 compatibile)

### Fixed
- **Conti archiviati esclusi dal saldo disponibile**
  - saldo disponibile / operativo = somma dei saldi solo dei conti non archiviati
  - conti archiviati restano visibili e consultabili nell'Archivio
  - movimenti storici dei conti archiviati restano consultabili
  - saldo derivato del singolo conto archiviato resta mostrabile nel dettaglio archivio
- **Saldo attuale conto resta derivato**
  - nessun campo indipendente per il saldo attuale
  - formula invariata: `initialBalance + entrate - uscite + trasferimenti netti`

### QA
- `test/categories_navigation_test.dart`: PASS (aggiornati per filtro tipo)
- `test/categories_layout_test.dart`: PASS (copre preferenza, filtro, layout, azioni, KPI)
- `test/accounts_navigation_test.dart`: fix regressione (categoria archiviata type expense per filtro default)
- `flutter analyze --no-pub`: 0 issues
- `flutter test --no-pub`: PASS
- Nessun DB/schema modificato
- Nessuna business logic finanziaria modificata
- Nessun backup/restore/import/reset modificato
- Nessuno skip aggiunto

---

## [0.7.0] - 2026-06-09

### Added
- Import CSV 1Money, prima versione dedicata al formato esportato da 1Money
  - supporto ai campi `DATA`, `TIPOLOGIA`, `DAL CONTO`, `AL CONTO / ALLA CATEGORIA`, `IMPORTO`, `NOTE`
  - mapping `Spesa` / `Entrata` / `Trasferimento` verso `MovementType.expense` / `income` / `transfer`
  - `movement.date` ricavata da `DATA` nel formato `dd/MM/yy`
  - import di `note` e fallback del `title` su categoria/destinazione quando la nota è vuota
  - auto-creazione di conti e categorie mancanti
  - trasferimenti nativi Stream con `destinationAccountId`
  - dedupe per fingerprint `data + tipo + importo + conto + categoria + note`
  - ignorata la sezione finale 1Money dei conti/fondi a partire dalla riga `NOME`
- UI Impostazioni aggiornata con azione dedicata `Importa CSV 1Money`
- Saldo iniziale dei conti
  - aggiunta persistenza `accounts.initial_balance`
  - il saldo attuale è sempre derivato da saldo iniziale + movimenti
  - formula saldo attuale: saldo iniziale + entrate - spese + trasferimenti netti
  - la modifica conto mostra saldo iniziale modificabile e saldo attuale in sola lettura
- Navigazione conti in Archivio
  - tocco su un conto apre la vista `Movimenti del conto`
  - riepilogo con saldo iniziale, entrate filtrate, uscite filtrate, trasferimenti netti, saldo attuale e numero movimenti
  - filtro periodo riusando `TimeFilter` e `TimeFilterBar`
  - lista movimenti riusando `GroupedMovementsList`
- Navigazione categorie in Archivio
  - tocco su una categoria apre la vista `Movimenti categoria`
  - filtro periodo riusando `TimeFilter` e `TimeFilterBar`
  - lista movimenti riusando `GroupedMovementsList`
- Gestione archiviati resa più esplicita in Archivio
  - conti attivi e archiviati mostrati in sezioni separate
  - categorie attive e archiviate mostrate in sezioni separate
  - elementi archiviati consultabili e cliccabili

### QA
- Test unitari aggiunti per import spesa, entrata, trasferimento, auto-creazione, nota, data, duplicati e stress 1000 righe
- Test navigazione Archivio verdi:
  - `test/accounts_navigation_test.dart`: PASS
  - `test/categories_navigation_test.dart`: PASS
- Re-test import CSV 1Money mantenuto verde
- `flutter analyze --no-pub`: PASS
- `flutter test --no-pub`: da rilanciare localmente in ambiente completo
- `flutter build apk --release --no-pub`: da rilanciare localmente in ambiente completo
- `flutter build ios --release --no-codesign --no-pub`: da rilanciare localmente in ambiente completo

### Validation finale dataset reale
- Validazione completata su dataset reale 1Money / Stream
- Movimenti unici coincidenti: 6369 / 6369
- Nessuna perdita di movimenti, nessuna inversione di segno e nessuna divergenza contabile sui movimenti importati
- Le differenze residue osservate nelle verifiche precedenti erano dovute a dataset di confronto diversi e non a un bug dell'importatore

---

## [0.7.1] - 2026-06-09

### QA
- Test reset ripristinati e verdi:
  - `reset_data_test.dart`: PASS
  - `qa_extensive_test.dart`: PASS
  - `C2`, `F2`, `F3`, `L1` stabilizzati
  - reset validato tramite flusso UI reale nei test, con backup pre-reset stub nel test harness dove necessario
  - nessuna business logic/UI modificata
- `flutter analyze --no-pub`: PASS
- `flutter test --no-pub`: PASS, 575 test verdi
- `flutter build apk --release --no-pub`: PASS, `app-release.apk` 66.7MB
- `flutter build ios --release --no-codesign --no-pub`: PASS al secondo tentativo, `Runner.app` 32.8MB
- Nota build iOS: primo tentativo fallito per errore Xcode/DerivedData `disk I/O error`, rilancio senza modifiche passato

---

## [0.8.0] - 2026-06-10

### Added
- Calculator Pad riusabile per i campi importo
  - nuovo `CalculatorAmountField` con pad custom
  - evaluator separato senza `eval`
  - supporto a `+`, `-`, `*`, `/`, `:`, `=`, decimale, backspace, clear e `Fatto`
  - `=` calcola e lascia il pad aperto
  - `Fatto` calcola/conferma e chiude il pad
  - integrazione su movimenti manuali, modifica movimento, trasferimenti, rapidi, preferiti e saldo iniziale conto

### Fixed
- **Tastiera nativa non si apre più** sui campi importo CalculatorAmountField
  - root cause: TextField richiedeva focus/keyboard prima che `onTap` aprisse il bottom sheet; dopo chiusura, focus residuo riapriva la tastiera
  - fix: `readOnly: true`, `showCursor: false`, `keyboardType: TextInputType.none`, `FocusManager.instance.primaryFocus?.unfocus()` prima del bottom sheet
  - `test/helpers/calculator_test_helpers.dart` — 3 nuovi helper per test (enterAmountWithCalculator, openPadAndType, closeCalculatorPad)
  - 49 test legacy aggiornati: `tester.enterText` su campi importo readOnly non funzionava più → sostituito con helper Calculator Pad
  - nessun indebolimento assert, nessuno skip aggiunto

### QA
- `test/calculator_amount_pad_test.dart`: 30/30 PASS (11 evaluator + 15 widget pad + 4 keyboard prevention + 4 integrazione)
- `test/qa_movements_test.dart`: 85/85 PASS
- `test/widget_test.dart`: 9/9 PASS
- `test/dashboard_after_delete_test.dart`: 21/21 PASS
- `test/qa_extensive_test.dart`: 30/30 PASS
- `flutter test --no-pub`: **579/579 All tests passed**
- `flutter analyze --no-pub`: 0 issues
- Nessuno skip aggiunto

---

## [0.6.4] - 2026-06-08

### Added
- Ricerca globale movimenti in `Archivio > Movimenti`
  - ricerca case-insensitive e con trim
  - match parziale su titolo, nota, nome categoria e nome conto
  - combinabile con `TimeFilter` (giorno, mese, anno, periodo custom)
  - risultati renderizzati con `GroupedMovementsList`
- Movimenti rapidi / preferiti con scelta data rapida
  - scelta immediata: `Oggi`, `Ieri`, `Domani`
  - opzione `Scegli data` per aprire il date picker completo
  - il movimento viene salvato con `Movement.date` valorizzata dalla scelta
- `StreamDatePicker` riusato nel flusso data rapida / custom
- `MovementPicker` e form manuale allineati al flusso rapido-preferiti

### Fixed
- Bottom sheet / date picker rapidi con `Key` stabili per i test widget
- Test lazy list: `scrollUntilVisible` corretto con `Scrollable`, non con `ListView`
- Label form movimento:
  - Entrata / Uscita = `Conto`
  - Trasferimento = `Conto origine`

### QA
- Test suite aggiornata: **492/492 pass**
- `flutter analyze --no-pub`: PASS
- `flutter build apk --release --no-pub`: PASS
- `flutter build ios --release --no-codesign --no-pub`: da rilanciare localmente

### Reset Data Verification

Durante la fase QA sono comparsi failure nei test:

- C2
- F2
- F3
- L1
- `reset_data_test`

L'analisi e la verifica manuale hanno confermato che:

- `AppDatabase.resetAllData()` funziona correttamente
- `SQLiteService.resetAllData()` funziona correttamente
- i movimenti vengono cancellati
- i preferiti vengono cancellati
- gli account vengono ripristinati ai default
- le categorie vengono ripristinate ai default
- i quick movements vengono ripristinati ai default

Verifica manuale eseguita su dispositivo Android reale (Pixel 6):

1. creazione dati utente
2. apertura `Impostazioni`
3. `Reset dati app`
4. digitazione `RESET`
5. conferma reset
6. eventuale `Backup pre-reset fallito` -> `Continua`

Risultato osservato:

- archivio svuotato
- movimenti eliminati
- preferiti eliminati
- conti riportati al default
- categorie riportate al default

Conclusione:

Nessun bug prodotto confermato nel reset. I failure erano dovuti a finder fragili, gestione del dialog secondario di backup fallito, timing dei widget test e attese UI basate su snackbar/dialog, non a un malfunzionamento di `resetAllData()`.

---

## [0.6.3] - 2026-06-08

### Added
- Ricerca globale movimenti in-memory, senza modifiche a database/schema/model
  - campi cercati: titolo, nota, categoria, conto
  - ricerca parziale e case-insensitive
  - combinazione con i filtri temporali già esistenti
  - risultato finale raggruppato per giorno con `GroupedMovementsList`
- UI Archivio aggiornata con barra di ricerca nella sezione Movimenti

### QA
- Test ricerca e regressioni: pass pass
- `flutter analyze --no-pub`: PASS

---

## [0.6.2] - 2026-06-08

### Added
- `compareMovementsForDisplay(a, b)` — comparator unico centralizzato per tutte le liste movimenti
  - Ordine: `updatedAt desc → createdAt desc → id asc`
  - `categoryId`, `type`, `amount`, `title` NON influenzano l'ordine
  - Usato da: `groupMovementsByDay`, `filterByTime`, `lastMovements`
- `GroupedMovementsList` widget riusabile con scrollController opzionale per `DraggableScrollableSheet`
- `Movement.compareForDisplay()` — instance method per comodità

### Changed
- **Sort dentro gruppi giorno**: `createdAt desc` → `updatedAt desc`. Un movimento modificato dopo ora appare sopra.
- **Chiave raggruppamento giorno**: zero-padded (`"2026-06-08"` invece di `"2026-6-8"`). Fix: gruppi con date 8, 12, 24 ora ordinati 24 → 12 → 8, non più 8 → 12 → 24.
- **Dashboard**: rimosso `_FilteredMovementsList` — resta insight-only (KPI + spese per categoria)
- **`_CategoryDetailSheet`**: ora usa `GroupedMovementsList` per lista movimenti raggruppata
- `MovementsScreen._buildMovementsList`: usa `GroupedMovementsList`
- `filterByTime` e `lastMovements`: tiebreaker `createdAt` → `compareMovementsForDisplay`
- `DayHeader` summary Row avvolto in `FittedBox(boxFit.scaleDown)` per evitare overflow in narrow bottom sheet

### Fixed
- **CRITICAL** — Ordinamento gruppi giorno per data con string key non zero-padded: `"2026-6-8" > "2026-6-12"` per confronto lessicografico. Fix: `padLeft(2, '0')` su mese e giorno.
- **HIGH** — Ordinamento dentro gruppi giorno usava `createdAt` invece di `updatedAt`. Un movimento modificato dopo restava sotto anche se più recente.
- **HIGH** — 3 implementazioni separate di sort Movement: `daily_group.dart` (corretta), `time_filter.dart` (createdAt), `database.dart` (createdAt). Unificate in `compareMovementsForDisplay`.
- DayHeader Row overflow in `DraggableScrollableSheet` ristretto (iPhone)

### QA
- 457 test pass (+10 da V0.6.1: +3 updatedAt sort, +2 categoryId ignored, +1 comparator direct, +2 mixed digit dates, +1 future dates, +1 widget UI order)
- flutter analyze: 0 issues
- Android release build PASS (66.2MB)
- iOS release build PASS (32.7MB)

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
