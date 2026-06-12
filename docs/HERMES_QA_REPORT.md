# HERMES QA REPORT

> Contiene QA e note di verifica per le milestone Hermes completate, incluse V0.8.0 Calculator Pad, V0.8.1 Categories Layout Modes, V0.8.2 Financial KPI Corrections, V0.8.5 Movimenti Analytics e V0.8.6 Category Treemap Analytics.

---

## Hermes V0.8.8 — Subcategories Foundation ✅ COMPLETATO

### Stato sintetico

- Nuova entità `Subcategory` con `id`, `categoryId`, `name`, `archived`, `createdAt`, `updatedAt`
- Nessun `color`/`iconKey` — le sottocategorie ereditano identità visiva dalla categoria madre
- DB version v8 → v9:
  - nuova tabella `subcategories` con `UNIQUE(category_id, name)`
  - colonna nullable `subcategory_id` su `movements`, `quick_movements`, `favorite_movements`
  - CRUD sottocategorie e mappers aggiornati
  - `resetAllData` cancella anche `subcategories`
- Movement/QuickMovement/FavoriteMovement: `subcategoryId` opzionale, retrocompatibile
- Backup/Restore aggiornato:
  - backup include `subcategories`
  - restore vecchio JSON (senza subcategories) funziona
  - restore nuovo JSON (con subcategories) funziona
  - `subcategoryId` orfani normalizzati a `null`
  - nessuna perdita dati
- UI Categorie: sezione sottocategorie nel dialog categoria (aggiungi/rinomina/archivia/ripristina)
- Form movimento: dropdown sottocategoria opzionale (solo per income/expense con subcategories attive)
- QuickMovement/FavoriteMovement: subcategoryId opzionale
- UX Fix: campo Nota nel form movimento rapido
- UX Fix: soglie heatmap con `textInputAction.done` + `onSubmitted` unfocus
- CSV Import 1Money: NON implementato parsing sottocategorie in questa fase
- Nessuna conversione automatica di categorie flat con parentesi

### Test aggiunti / aggiornati

- Nuovo file `test/subcategories_test.dart` — 17 tests:
  - creazione sottocategoria sotto categoria
  - dedup sottocategoria stessa categoria (permesso)
  - stesso nome ammesso sotto categorie diverse
  - movimento con `subcategoryId` valido
  - archiviazione non rompe storico
  - movimento senza sottocategoria (null)
  - movimento con subcategory contribuisce alla categoria madre
  - `getActiveSubcategoriesForCategory` filtra archiviate
  - categoria senza subcategories ha lista vuota
  - persistenza SQLite dopo reload
  - archiviazione persiste dopo reload
  - backup include subcategories
  - restore con subcategories funziona
  - restore vecchio JSON senza subcategories funziona
  - restore con subcategoryId orfano normalizzato a null
  - resetAllData cancella subcategories
  - compatibilità analytics (spese categoria includono subcategory)

### Verifica locale finale

- `flutter analyze --no-pub`: **PASS** — 0 errors, 0 warnings
- `flutter test --no-pub`: **689/689 All tests passed** (672 pre-esistenti + 17 nuovi)
- DB version v9 confermato
- 3 info deprecations pre-existing (`value` → `initialValue`) — non introdotte
- Nessuno skip aggiunto
- Nessun commit/push

### Non completato / futuro

- V0.8.9 — 1Money Subcategory Import
- V0.9.x — Converti categorie flat con parentesi in sottocategorie
- V0.9.x — Subcategories Analytics / Budget / Actual / Scenari
- FASE 4 — Lista Movimenti Premium

---

## Hermes V0.8.6 — Category Treemap Analytics ✅ COMPLETATO

### Stato sintetico

- Treemap aggiunta nella schermata `Categorie` come modalita visuale dedicata
- La treemap definitiva vive in `Categorie`, non in `Movimenti`
- Modalita visuali Categorie ora disponibili:
  - Lista pulita
  - Lista grouped
  - Card Stream
  - Treemap
- Stile market map:
  - ogni blocco rappresenta una categoria
  - area proporzionale al totale categoria nel periodo
  - colore derivato da `category.color`
  - testo con nome categoria, importo e/o numero movimenti
- Tap su blocco categoria apre il dettaglio/sheet categoria esistente
- Empty state dedicato: `Nessun dato categorie nel periodo selezionato.`

### Filtri e ordinamenti coperti

- Filtro periodo sulla treemap:
  - Giorno
  - Mese
  - Anno
  - Intervallo
- Ordinamenti treemap:
  - totale decrescente
  - totale crescente
  - nome A-Z
  - numero movimenti decrescente
- Transfer esclusi dai totali categoria
- Categorie archiviate escluse dalla treemap principale, coerentemente con Categorie
- Colori blocchi verificati da `category.color`

### Test aggiunti / aggiornati

- Nuovo file `test/categories_treemap_test.dart`
- Aggiornato `test/categories_layout_test.dart`
- Aggiornato `test/movements_view_modes_test.dart` per verificare che Movimenti non renderizzi piu la treemap del periodo
- Regressioni coperte:
  - filtro giorno/mese/anno/intervallo sulla treemap
  - ordinamenti treemap
  - transfer esclusi
  - colori `category.color`
  - empty state
  - tap categoria apre sheet/dettaglio categoria
  - nessun overflow con molte categorie a 800x600

### Verifica locale finale

- `flutter analyze --no-pub`: **PASS** — 0 issues
- `flutter test --no-pub test/categories_treemap_test.dart`: **PASS** — 10/10
- `flutter test --no-pub test/categories_layout_test.dart`: **PASS** — 28/28
- `flutter test --no-pub test/categories_navigation_test.dart test/accounts_navigation_test.dart test/dashboard_filtered_test.dart test/qa_movements_test.dart test/movements_view_modes_test.dart`: **PASS**
- `flutter test --no-pub`: **PASS** — 664/664 test verdi
- Nessuno skip aggiunto
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessun commit/push

---

## Hermes V0.8.5 — Movimenti Analytics e Heatmap ✅ COMPLETATO

### Stato sintetico

- Archivio riorganizzato con tab visibili:
  - Movimenti
  - Conti
  - Categorie
- Tab Calendario separata rimossa; il calendario ora vive dentro Movimenti
- Movimenti ha modalita interne:
  - Lista
  - Calendario
  - Heatmap / AdvancedHeatmap
- Preferenza modalita Movimenti persistita via `PreferencesService` / Settings
- Heatmap Movimenti basata sulle uscite:
  - income esclusi dai colori/metriche heatmap spese
  - transfer esclusi dai colori/metriche heatmap spese
  - legenda/range heatmap presenti
  - utility dedicate in `lib/utils/heatmap_utils.dart`
  - widget dedicato `lib/widgets/expense_heatmap.dart`
- Preview heatmap compatta in Lista:
  - file `lib/widgets/movements_heatmap_preview_card.dart`
  - bottone `Apri calendario`
  - nessun overlay sopra `MovementCard`
- Menu `MovementCard` stabile:
  - `PopupMenuButton` mantenuto
  - key `movement_card_action`
  - `showMenu` sperimentale non presente

### Search + filtro periodo

- Pipeline dati chiarita:
  - `periodFilteredMovements`
  - `searchFilteredMovements`
  - dati per lista/heatmap/riepilogo
- Search applicata anche alla heatmap
- Search case-insensitive/parziale su:
  - titolo
  - nota
  - categoria
  - conto
- Filtro periodo corretto:
  - Giorno: solo movimenti del giorno
  - Mese: tutti i movimenti del mese
  - Anno: tutti i movimenti dell'anno
  - Intervallo: tutti i movimenti dell'intervallo
- `selectedDay` non limita Mese/Anno/Intervallo; resta per evidenziazione/drill-down
- Picker data/anno coerente: aggiorna stato, mese visibile, heatmap e lista quando previsto

### Nota treemap

- La treemap del periodo non appartiene piu alla UI di Movimenti
- Movimenti mantiene Lista / Calendario / Heatmap
- L'analisi per categorie tramite treemap e stata spostata nella schermata `Categorie` con V0.8.6

### Regressioni coperte

- Search applicata a heatmap
- Mese/Anno non limitati da `selectedDay`
- Picker data/anno coerente con label, mese visibile, heatmap e lista
- `PopupMenuButton` stabile su `MovementCard`
- Transfer esclusi dalla heatmap spese
- Income esclusi dalla heatmap spese
- Assenza della treemap nella UI Movimenti dopo lo spostamento in Categorie

### Verifica locale

- `flutter analyze --no-pub`: **PASS** — 0 issues
- `flutter test --no-pub test/movements_view_modes_test.dart`: **PASS**
- `flutter test --no-pub test/dashboard_after_delete_test.dart`: **PASS** — 21/21
- `flutter test --no-pub test/accounts_navigation_test.dart`: **PASS** — 8/8
- `flutter test --no-pub test/categories_navigation_test.dart`: **PASS** — 5/5
- `flutter test --no-pub test/qa_movements_test.dart`: **PASS** — 85/85
- `flutter test --no-pub`: **PASS** — 664/664 test verdi
- Nessuno skip aggiunto
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessun commit/push

### Non completato / futuro

- Settings colori/soglie heatmap
- Annual heatmap premium
- Redesign completo Lista Movimenti
- Dashboard analytics avanzata non implementata

---

## Hermes V0.8.2 — Financial KPI Corrections ✅ COMPLETATO

### Stato sintetico

- Corretto il calcolo KPI globale di periodo in Dashboard
- Root cause confermata: la Dashboard usava una logica `if income else expense`, quindi ogni movimento non-income, inclusi i trasferimenti, veniva sommato nelle uscite
- I KPI globali ora usano solo il tipo esplicito del movimento:
  - Entrate = solo `MovementType.income`
  - Uscite = solo `MovementType.expense`
  - Bilancio = Entrate - Uscite
- I trasferimenti restano neutrali per:
  - entrate globali
  - uscite globali
  - bilancio globale
  - spese per categoria
  - riepiloghi giornalieri income/expense
- I trasferimenti restano invece attivi su:
  - saldo conto origine
  - saldo conto destinazione
  - storico movimenti
  - movimenti conto

### Helper centralizzati

- `Movement.isIncome`
- `Movement.isExpense`
- `Movement.isTransfer`
- `sumIncome()`
- `sumExpenses()`
- `sumTransfers()`
- `netIncomeExpense()`

### Verifiche dataset reale

- Giugno 2026:
  - Entrate: `1142.52`
  - Uscite: `328.08`
  - Trasferimenti: `272.30`
  - Bilancio corretto: `+814.44`
  - Valore errato precedente evitato: uscite `600.38`
- Maggio 2026:
  - Entrate: `1447.97`
  - Uscite: `2115.10`
  - Trasferimenti: `1187.50`
  - Bilancio corretto: `-667.13`
  - Valore errato precedente evitato: uscite `3302.60`

### Test aggiunti / aggiornati

- KPI periodo con income `100`, expense `30`, transfer `50`
- Dashboard giugno 2026 con transfer escluso dai KPI globali
- Dashboard maggio 2026 con transfer escluso dai KPI globali
- Spese per categoria ignorano transfer anche con `categoryId`
- Riepiloghi giornalieri ignorano transfer in income/expense
- Saldo conto con transfer ancora invariato su origine/destinazione

### Verifica locale

- `flutter analyze --no-pub`: **PASS** — 0 issues
- `flutter test --no-pub test/dashboard_after_delete_test.dart`: **PASS**
- `flutter test --no-pub test/categories_layout_test.dart`: **PASS**
- `flutter test --no-pub test/accounts_test.dart`: **PASS**
- `flutter test --no-pub test/qa_extensive_test.dart`: **PASS**
- `flutter test --no-pub test/dashboard_filtered_test.dart`: **PASS** — 42/42
- `flutter test --no-pub`: **PASS** — 619/619 test verdi
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push

---

## Hermes V0.8.1 — Categories Layout Modes ✅ COMPLETATO

### Stato sintetico

- Aggiunta preferenza visuale per la schermata Categorie
- Percorso impostazione: `Impostazioni > Aspetto > Modello categoria`
- Preferenza persistente `category_layout` via SharedPreferences
- `categoryLayoutNotifier` aggiorna la UI in tempo reale
- Default: `cleanList`

### Layout disponibili

- `Lista pulita`
  - layout minimal e compatto
  - icona piccola
  - padding ridotto
  - nessun contenitore pesante
- `Lista grouped`
  - layout a sezioni
  - gruppi distinti
  - header visibili
  - chiavi testabili per top/attive/archiviate
- `Card Stream`
  - card premium
  - padding ampio
  - bordo visibile
  - icona più evidente
  - grid/list coerente con Stream

### Categorie

- Filtro superiore `[ Uscite | Entrate ]`
- Default: `Uscite`
- Categorie archiviate filtrate per tipo
- FAB nuova categoria precompila il tipo dal filtro attivo
- KPI riepilogo categorie con key testabili:
  - `categories_type_summary_card`
  - `categories_summary_title`
  - `categories_summary_active_count`
  - `categories_summary_archived_count`

### Conti archiviati e saldo disponibile

- Saldo disponibile / operativo = somma dei soli conti non archiviati
- Conti archiviati esclusi dal saldo disponibile
- Conti archiviati ancora visibili nell'Archivio
- Movimenti storici dei conti archiviati ancora consultabili
- Saldo attuale conto resta derivato da:
  - `initialBalance + entrate - uscite + trasferimenti netti`
- Nessun campo saldo attuale indipendente

### Verifica locale

- `flutter analyze --no-pub`: **PASS** — 0 issues
- `test/categories_layout_test.dart`: **PASS**
- `test/categories_navigation_test.dart`: **PASS**
- `test/accounts_test.dart`: **PASS**
- `test/accounts_navigation_test.dart`: **PASS**
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto

---

## Hermes V0.7.0 — Saldo iniziale conti

### Stato sintetico

- Introdotto il concetto di saldo iniziale sui conti
- Persistenza su `accounts.initial_balance`
- Il saldo attuale è sempre derivato da `saldo iniziale + entrate - spese + trasferimenti netti`
- La schermata modifica conto mostra:
  - `Saldo iniziale` modificabile
  - `Saldo attuale` in sola lettura
  - nota informativa sul calcolo automatico

### Hermes V0.7.0 — Navigazione conti e archiviati

### Stato sintetico

- In Archivio > Conti, il tap su un conto apre la vista `Movimenti del conto`
- In Archivio > Categorie, il tap su una categoria apre la vista `Movimenti categoria`
- La vista mostra:
  - nome conto
  - saldo iniziale
  - entrate filtrate
  - uscite filtrate
  - trasferimenti netti filtrati
  - saldo attuale
  - numero movimenti
  - lista movimenti filtrata
- Conti e categorie archiviati sono esposti in sezioni separate e consultabili
- Le viste dettaglio usano `TimeFilterBar` e `GroupedMovementsList`

### Test aggiunti

- tap conto apre movimenti conto
- tap categoria apre movimenti categoria
- filtri giorno / mese / anno
- conto senza movimenti mostra empty state
- conti archiviati visibili nella sezione Archiviati
- categorie archiviate visibili nella sezione Archiviati
- import CSV 1Money rieseguito con successo con `dedupeWithinFile=true` / `false`, trailer `NOME` ignorato e `initialBalance = 0`
- `accounts_navigation_test.dart`: PASS
- `categories_navigation_test.dart`: PASS

### Verifica locale

- `flutter analyze --no-pub`: **PASS**
- `flutter test --no-pub test/accounts_navigation_test.dart`: **PASS**
- `flutter test --no-pub test/categories_navigation_test.dart`: **PASS**
- `flutter test --no-pub test/reset_data_test.dart`: **PASS**
- `flutter test --no-pub test/qa_extensive_test.dart`: **PASS**
- `flutter test --no-pub test/one_money_csv_import_test.dart`: **PASS**
- `flutter test --no-pub`: **PASS** — 575 test verdi
- `flutter build apk --release --no-pub`: **PASS** — `app-release.apk` 66.7MB
- `flutter build ios --release --no-codesign --no-pub`: **PASS** al secondo tentativo — `Runner.app` 32.8MB

---

## Hermes V0.8.0 — Calculator Pad (QA iniziale — prima del fix tastiera nativa)

### Stato sintetico

- Aggiunto Calculator Pad riusabile per i campi importo
- Il pad supporta:
  - numeri interi e decimali
  - `+`
  - `-`
  - `*`
  - `/`
  - `:`
  - `=`
  - backspace
  - clear
  - `Fatto`
- `=` calcola l'espressione corrente senza chiudere il pad
- `Fatto` calcola, conferma il valore e chiude il pad
- Divisione per zero ed espressioni incomplete mostrano errore non bloccante
- Parser/evaluator separato dalla UI, senza `eval`

### Integrazione

- Movimento manuale
- Modifica movimento
- Trasferimento manuale
- Movimenti rapidi
- Preferiti
- Saldo iniziale conto

### Test aggiunti

- Unit test evaluator:
  - somma
  - sottrazione
  - moltiplicazione
  - divisione
  - divisione con `:`
  - decimali
  - virgola decimale
  - divisione per zero
  - espressione incompleta
  - input vuoto
  - precedenza operatori
- Widget test pad:
  - numeri e operatori
  - `=` calcola senza chiudere
  - continuazione dopo `=`
  - `Fatto` calcola e chiude
  - backspace e clear
  - errori non bloccanti
- Integrazione:
  - aggiunta spesa
  - aggiunta entrata
  - modifica movimento
  - saldo iniziale conto

### Verifica locale

- `flutter analyze --no-pub`: **PASS**
- `flutter test --no-pub test/calculator_amount_pad_test.dart`: **PASS**
- `flutter test --no-pub test/calculator_amount_pad_test.dart test/qa_movements_test.dart`: **PASS**
- `flutter test --no-pub`: **PASS** — 575 test verdi
- `flutter build apk --release --no-pub`: **PASS** — `app-release.apk` 66.7MB
- `flutter build ios --release --no-codesign --no-pub`: **PASS** al secondo tentativo — `Runner.app` 32.8MB

### Nota build iOS

Il primo tentativo iOS ha fallito in Xcode/DerivedData con `disk I/O error` e file intermedi mancanti. Il secondo tentativo, senza modifiche al codice, è passato.

---

## Hermes V0.8.0 — Calculator Pad ✅ COMPLETATO

### Stato sintetico

- Calculator Pad riusabile per tutti i campi importo
- `CalculatorAmountField` con `readOnly: true`, `showCursor: false`, `keyboardType: TextInputType.none`
- `unfocus()` prima dell'apertura del bottom sheet → tastiera nativa bloccata
- `AmountExpressionEvaluator` senza `eval` con supporto:
  - operatori: `+`, `-`, `*`, `/`, `:`, `=`
  - decimali e virgola decimale
  - backspace, clear, precedenza operatori
  - divisione per zero ed espressioni incomplete gestite
- `=` calcola senza chiudere il pad
- `Fatto` calcola/conferma/chiude

### Integrazione

- Movimento manuale, modifica movimento, trasferimento manuale
- Movimenti rapidi e preferiti
- Saldo iniziale conto

### Fix tastiera nativa (finale V0.8.0)

- **Bug**: dopo tap sul campo importo, tastiera numerica nativa si apriva sopra il pad custom
- **Root cause**: TextField attivava focus/keyboard prima che `onTap` aprisse il bottom sheet; dopo chiusura, il focus residuo riapriva la tastiera
- **Fix**: `readOnly: true`, `showCursor: false`, `keyboardType: TextInputType.none`, `FocusManager.instance.primaryFocus?.unfocus()` in `_showPad()`

### Test helper

- Nuovo file: `test/helpers/calculator_test_helpers.dart`
- Helper riusabili:
  - `enterAmountWithCalculator(tester, amount, {label})` — tap campo → apre pad → tasti → Fatto → chiude
  - `openPadAndType(tester, expression, {label})` — apre pad, digita senza confermare
  - `closeCalculatorPad(tester)` — clear + Fatto per chiusura forzata

### Nota QA — 49 fail legacy

I 49 test che fallivano dopo V0.8.0 NON erano regressioni business logic:
- **Causa**: `CalculatorAmountField` ora readOnly → `tester.enterText` non scrive più sui campi importo. Controller restava vuoto → movimenti non salvati → bottom sheet/overlay aperti → tap successivi colpivano widget sbagliati
- **Fix**: 44 `saveMovement`/direct `enterText` calls + 5 UI widget test aggiornati per usare il Calculator Pad come l'utente reale
- **Nessun indebolimento assert, nessuno skip**

### Verifica locale

- `flutter analyze --no-pub`: **PASS** — 0 issues
- `test/calculator_amount_pad_test.dart`: **30/30 PASS**
- `test/qa_movements_test.dart`: **85/85 PASS**
- `test/widget_test.dart`: **9/9 PASS**
- `test/dashboard_after_delete_test.dart`: **21/21 PASS**
- `test/qa_extensive_test.dart`: **30/30 PASS**
- `flutter test --no-pub`: **579/579 All tests passed**
- `flutter build apk --release --no-pub`: da rilanciare
- `flutter build ios --release --no-codesign --no-pub`: da rilanciare

---

## Hermes V0.7.0 — Import CSV 1Money (prima versione)

### Stato sintetico

- Import dedicato al CSV esportato da 1Money, non importatore generico
- Mapping supportato:
  - `TIPOLOGIA` → `MovementType.expense` / `income` / `transfer`
  - `DATA` → `movement.date` nel formato `dd/MM/yy`
  - `DAL CONTO` → conto sorgente
  - `AL CONTO / ALLA CATEGORIA` → categoria o conto destinazione
  - `IMPORTO` → `double` con supporto a virgola e punto
  - `NOTE` → `movement.note`
- Auto-creazione di conti e categorie mancanti
- Trasferimenti nativi Stream con `destinationAccountId`
- Deduplica tramite fingerprint `data + tipo + importo + conto + categoria + nota`
- La sezione finale 1Money dei conti/fondi viene ignorata a partire dalla riga `NOME`
- `BackupScreen` ora espone una azione dedicata `Importa CSV 1Money`

### Test aggiunti

- import spesa
- import entrata
- import trasferimento
- conto auto-creato
- categoria auto-creata
- note importate
- data corretta
- duplicato ignorato
- stress 1000 movimenti
- import stesso file due volte senza duplicati

### Verifica locale

- `flutter analyze --no-pub`: **PASS**
- `flutter test --no-pub test/one_money_csv_import_test.dart`: **PASS**
- Suite completa: da rilanciare
- `flutter build apk --release --no-pub`: da rilanciare localmente in ambiente completo
- `flutter build ios --release --no-codesign --no-pub`: da rilanciare localmente in ambiente completo

### Validazione dataset reale

- Backup Stream: 6369 movimenti
- CSV 1Money unici: 6369 movimenti
- Overlap: 6369
- Backup-only: 0
- CSV-only: 0
- Nessuna perdita movimenti

---

## Hermes V0.6.3 / V0.6.4 — QA recente

### Stato sintetico

- `flutter analyze --no-pub`: **No issues found**
- `flutter test --no-pub`: **492/492 pass**
- `flutter build apk --release --no-pub`: **PASS**
- `flutter build ios --release --no-codesign --no-pub`: **da rilanciare localmente**

### Cosa è stato validato

- Ricerca globale movimenti in Archivio > Movimenti
- Ricerca case-insensitive e con trim
- Ricerca parziale su titolo, nota, categoria e conto
- Combinazione ricerca + `TimeFilter`
- Risultati con `GroupedMovementsList`
- Movimenti rapidi / preferiti con scelta data rapida
- Form movimento con label corretta:
  - Entrata / Uscita = `Conto`
  - Trasferimento = `Conto origine`

### Test rapidi / preferiti sistemati

I test widget che avevano fallito sono stati ricondotti a regressioni di test, non a bug del comportamento app.

#### Cause osservate
- Finder ambiguo su `Scegli data`
- Bottom sheet lasciato aperto tra le interazioni
- Lazy rendering della `ListView` non ancora in viewport
- `scrollUntilVisible` usato con `ListView` invece di `Scrollable`

#### Risoluzione
- `Key` stabili per:
  - `quick_date_today`
  - `quick_date_yesterday`
  - `quick_date_tomorrow`
  - `quick_date_custom`
  - `stream_date_picker_cancel`
  - `stream_date_picker_ok`
- Chiusura sempre esplicita dei bottom sheet / picker
- `pumpAndSettle` dopo ogni interazione con sheet o picker
- Uso corretto di `Scrollable` nei test di scroll

### Conclusione

- I problemi finali erano regressioni di test
- Il comportamento app è rimasto coerente
- La suite è tornata verde a 492 test

## Reset Data Verification

Durante la fase QA sono comparsi failure nei test:

- C2
- F2
- F3
- L1
- `reset_data_test`

L'analisi ha mostrato che:

- `AppDatabase.resetAllData()` funziona correttamente
- `SQLiteService.resetAllData()` funziona correttamente
- i movimenti vengono cancellati
- i preferiti vengono cancellati
- gli account vengono ripristinati ai default
- le categorie vengono ripristinate ai default
- i quick movements vengono ripristinati ai default

### Verifica manuale

Il flusso è stato verificato direttamente su dispositivo Android reale (Pixel 6):

1. creazione dati utente
2. apertura `Impostazioni`
3. `Reset dati app`
4. digitazione `RESET`
5. conferma reset
6. eventuale `Backup pre-reset fallito` -> `Continua`

### Risultato osservato

- archivio svuotato
- movimenti eliminati
- preferiti eliminati
- conti riportati al default
- categorie riportate al default

### Conclusione

Nessun bug prodotto confermato nel reset. I failure erano riconducibili a finder fragili, gestione del dialog secondario backup fallito, timing dei widget test e attese UI basate su snackbar/dialog, non a un malfunzionamento di `resetAllData()`.

### Stato test reset

I test widget del reset sono stati ripristinati e stabilizzati:

- `reset_data_test.dart`: **PASS**
- `qa_extensive_test.dart`: **PASS**
- `C2`, `F2`, `F3`, `L1`: stabilizzati
- Il reset è validato tramite flusso UI reale nei test
- Il test harness usa backup pre-reset stub dove necessario per evitare fragilità del backup asincrono
- Nessuna business logic/UI modificata

## 1. Data test

2026-06-08 (V0.6.0 QA)

## 2. Versione app/test

- **App**: STREAM powered by BudgetFlow — Hermes V0.5.6
- **Flutter**: 3.44.1 (channel stable)
- **Dart**: 3.12.1
- **SDK constraint**: `^3.12.1`

## 3. Device Android testato

| Campo | Valore |
|-------|--------|
| Device | Pixel 6 |
| ID | `22091FDF6001QG` |
| OS | Android 13 (API 33) |

## 4. Device iOS testato

| Campo | Valore |
|-------|--------|
| Device | iPhone di Mattia |
| ID | `00008140-001E29803CD1801C` |
| OS | iOS 26.5 (23F77) |

**Note iOS**: L'app è stata lanciata con successo su iPhone (Xcode build 8.8s, auto-signing con team QDZN3K5LUM). CocoaPods non è installato ma non serve per il debug. Per distribuzione beta sarà necessario `pod install` o configurazione delle dipendenze native.

## 5. Risultato flutter analyze

```
Analyzing stream_app...
No issues found! (ran in 4.9s)
```

*(V0.3.3: 0 issues)*

## 6. Risultato flutter test

```
00:04 +50: All tests passed!
```

- `test/widget_test.dart` — 7 test (originali + aggiornati)
- `test/qa_movements_test.dart` — 43 test (copertura 50 scenari)

## 7. Risultato build Android

```
flutter build apk --debug
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

Build completata in ~13s.

## 8. Risultato run Android

```
flutter run -d 22091FDF6001QG
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Installing... EXIT_CODE: 0
```

App avviata e installata su Pixel 6. Nessun crash.

## 9. Risultato build/run iOS

```
flutter run -d 00008140-001E29803CD1801C
Automatically signing iOS for device deployment using specified development team in Xcode project: QDZN3K5LUM
Running Xcode build... Xcode build done. (8.8s)
Installing and launching... OK
```

iOS build e run riusciti. CocoaPods non presente ma non necessario per debug. Bundle Identifier: `com.mattiasironi.flow`.

---

## Hermes V0.5.6 — Dashboard Filtrata per Periodo + UI alignment ✅

## Data test

2026-06-08

## Stato

COMPLETATO

## Verifica sintetica

- [x] `TimeFilterBar` in Dashboard
- [x] KPI filtrati per periodo
- [x] KPI non filtrati per patrimonio/saldi attuali
- [x] Sezione `Spese per categoria` al posto della lista movimenti
- [x] Max 5 categorie visibili
- [x] Empty state: `Nessuna spesa nel periodo selezionato`
- [x] `MovementCard` condivisa per le schermate operative
- [x] Fix `heroTag` FAB mantenuto
- [x] Backup/Restore raggiungibile da `Impostazioni`
- [x] Navigazione finale: `Dashboard / Archivio / Impostazioni`
- [x] `Calendario` dentro `Archivio`
- [x] `flutter analyze` ok
- [x] `flutter test` ok
- [x] `flutter build apk --release` **PASS** (66.1MB) — fix KGP per `file_picker` in `android/build.gradle.kts`
- [x] `flutter build ios --release --no-codesign` **PASS** (32.7MB)

## Decisioni architetturali registrate

- Dashboard = sintesi del periodo, non secondo Archivio
- Backup/Restore = card dentro Impostazioni, non tab separata
- Restore = transazionale con rollback automatico
- Orfani account/categorie = gestiti durante il restore
- Colori categoria = letti dal model corrente, fallback solo se il colore non è disponibile
- Confronto col periodo precedente = solo per filtri semplici, non per custom range

## Esito build

```
flutter analyze               → No issues found
flutter test                   → 363/363 All tests passed
flutter build apk --release    → PASS (66.1MB)
flutter build ios --release    → PASS (32.7MB, --no-codesign)
```

## 10. Tabella dei 50 test

| # | Test | Stato | Tipo | Note |
|---|------|-------|------|------|
| 1 | Crea entrata 100€ | ✅ PASS | automatico | |
| 2 | Crea uscita 100€ | ✅ PASS | automatico | |
| 3 | Crea entrata 100,50 (virgola) | ✅ PASS | automatico | Bug #1 corretto |
| 4 | Crea entrata 100.50 (punto) | ✅ PASS | automatico | |
| 5 | Blocca uscita 0€ | ✅ PASS | automatico | |
| 6 | Blocca entrata 0€ | ✅ PASS | automatico | |
| 7 | Blocca importo negativo | ✅ PASS | automatico | |
| 8 | Blocca importo vuoto | ✅ PASS | automatico | |
| 9 | Blocca titolo vuoto | ✅ PASS | automatico | |
| 10 | Categoria non selezionata | ✅ PASS | manuale | Default categoria auto-assegnata in build() |
| 11 | Crea movimento 0,01€ | ✅ PASS | automatico | |
| 12 | Crea movimento 999999€ | ✅ PASS | automatico | |
| 13 | Crea movimento 999999,99€ | ✅ PASS | automatico | |
| 14 | Crea movimento 1,1€ | ✅ PASS | automatico | |
| 15 | Crea movimento 1,11€ | ✅ PASS | automatico | |
| 16 | Crea movimento 1,111€ | ✅ PASS | automatico | Arrotondamento a 2 decimali in visualizzazione |
| 17 | Una entrata: totale entrate | ✅ PASS | automatico | |
| 18 | Una uscita: totale uscite | ✅ PASS | automatico | |
| 19 | Tre entrate: somma | ✅ PASS | automatico | |
| 20 | Tre uscite: somma | ✅ PASS | automatico | |
| 21 | Entrate + uscite: saldo | ✅ PASS | automatico | |
| 22 | Saldo negativo | ✅ PASS | automatico | Formato "-X.XX €" |
| 23 | Saldo positivo | ✅ PASS | automatico | Formato "+X.XX €" |
| 24 | Saldo zero | ✅ PASS | automatico | Formato "+0.00 €" |
| 25 | Dashboard aggiornata dopo salvataggio | ✅ PASS | automatico | Bug #2 corretto |
| 26 | Ordine: più recente in alto | ✅ PASS | automatico | |
| 27 | Lista con 10 movimenti | ✅ PASS | automatico | |
| 28 | Lista con 50 movimenti | ✅ PASS | automatico | |
| 29 | Lista con 100 movimenti | ✅ PASS | automatico | |
| 30 | Scroll lista fluido | ⚠️ NON TESTATO | manuale | Testabile solo su device fisico |
| 31 | Titolo molto lungo | ✅ PASS | automatico | |
| 32 | Emoji nel titolo 🍕 Pizza | ✅ PASS | automatico | |
| 33 | Accenti: Farmàcia | ✅ PASS | automatico | |
| 34 | Apostrofi: Lidl d'estate | ✅ PASS | automatico | |
| 35 | Caratteri speciali: @ + (€) | ✅ PASS | automatico | |
| 36 | Categoria Spesa | ✅ PASS | automatico | |
| 37 | Categoria Auto | ✅ PASS | automatico | Selezione dropdown funziona |
| 38 | Categoria Svago | ✅ PASS | automatico | |
| 39 | Categoria Stipendio | ✅ PASS | automatico | Categoria di default per entrate |
| 40 | Categorie iniziali presenti | ✅ PASS | automatico | 10 categorie (4 entrate + 6 uscite) |
| 41 | Persistenza chiudi/riapri | ❌ NON TESTATO | manuale | Store in-memory, nessuna persistenza. **KNOWN LIMITATION** |
| 42 | Persistenza riavvio telefono | ❌ NON TESTATO | manuale | Idem |
| 43 | Hot reload / hot restart | ✅ PASS | manuale | App ricostruita correttamente |
| 44 | Tab D → M → D | ✅ PASS | automatico | Dati corretti dopo navigazione |
| 45 | Tab M → C → M | ✅ PASS | automatico | |
| 46 | Elimina movimento | ✅ PASS | automatico | |
| 47 | Elimina + riapri app | ❌ NON TESTATO | manuale | Store in-memory |
| 48 | 100 movimenti (db) | ✅ PASS | automatico | Aggregate validation |
| 49 | 500+ movimenti | ❌ NON TESTATO | manuale | Non realistico per MVP senza DB persistente |
| 50 | Performance con molti movimenti | ✅ PASS | automatico | Scroll test con 100 item |

### Legenda

| Stato | Significato |
|-------|-------------|
| ✅ PASS | Test superato |
| ❌ FAIL | Test fallito |
| ⚠️ NON TESTATO | Non eseguibile in automazione o bloccato da limitazione nota |

---

## 11. Bug trovati

### Bug #1 — Separatore decimale (CRITICAL) ✅ CORRETTO

**File**: `lib/widgets/movement_form.dart:39`

**Sintomo**: L'utente digita un importo con virgola (es. `10,50`) ma `double.tryParse` restituisce `null` perché Dart accetta solo il punto come separatore decimale. Su Android italiano la tastiera numerica mostra la virgola. Il `_submit()` abortisce senza salvare né mostrare errori.

**Fix**: `amountText.replaceAll(',', '.')` prima del parsing.

### Bug #2 — Dashboard stale (HIGH) ✅ CORRETTO

**File**: `lib/screens/dashboard_screen.dart:15-18`

**Sintomo**: `income`, `expenses`, `balance`, `last` erano calcolati fuori dal builder di `ListenableBuilder`. Dopo un salvataggio, il builder si ricostruiva ma con valori vecchi (catturati per closure). L'utente non vedeva cambiamenti in Dashboard.

**Fix**: Spostati i calcoli dentro il builder del `ListenableBuilder`.

---

## 12. Bug corretti

| # | Bug | Priorità | Stato |
|---|-----|----------|-------|
| 1 | Separatore decimale virgola non supportato | CRITICAL | ✅ Corretto in `movement_form.dart:39` |
| 2 | Dashboard non si aggiorna dopo salvataggio | HIGH | ✅ Corretto in `dashboard_screen.dart:19-23` |

## 13. Bug rimasti

| # | Bug | Priorità | Impatto |
|---|-----|----------|---------|
| — | Nessun bug open noto | — | — |

## 14. Blocker

| Blocker | Dettaglio | Impatto |
|---------|-----------|---------|
| Nessuna persistenza | Store in-memory (`AppDatabase` usa `List<Movement>`). Tutti i dati sono persi alla chiusura dell'app. | **KNOWN LIMITATION**: roadmap prevede Drift/SQLite nella Fase 2. Non è un blocker per beta, ma va comunicato ai tester. |
| CocoaPods non installato | `pod` non trovato su questo Mac. Il debug su iOS funziona senza, ma per build release/con distribuzione serve. | Non bloccante per beta Android. Blocco minore per iOS. |
| Validazione silenziosa | Campi vuoti o importi invalidi non mostrano messaggi di errore all'utente. | UX migliorabile ma non funzionalmente bloccante. |

---

## 15. Raccomandazione finale

# ✅ READY FOR BETA

**Condizioni soddisfatte**:

| Criterio | Stato |
|----------|-------|
| Android build OK | ✅ |
| Android run OK | ✅ |
| flutter analyze OK | ✅ No issues found |
| flutter test OK | ✅ 50/50 passed |
| Nessun crash nei flussi principali | ✅ |
| Salvataggio movimenti OK | ✅ Punto e virgola |
| Dashboard corretta | ✅ |
| Categorie corrette | ✅ |
| Persistenza OK | ⚠️ In-memory (comunicato ai tester) |
| iOS testato o blocco documentato | ✅ iOS run riuscito |

**Raccomandazione**: L'app è pronta per beta testing su Android. Consegnare l'APK `build/app/outputs/flutter-apk/app-debug.apk` ai beta tester.

**Avvertenze da comunicare ai tester**:
1. I dati sono in memoria — alla chiusura dell'app TUTTO viene perso. Non inserire dati reali/importanti.
2. La validazione degli importi è silenziosa: se il pulsante Salva non reagisce, controllare titolo, importo (>0) e categoria.
3. iOS funziona in debug ma per distribuzione serve configurare CocoaPods e provisioning profile.

---

# HERMES V0.2 — Speed Layer

## 1. Data test

2026-06-05

## 2. Versione app/test

- **App**: STREAM powered by BudgetFlow — Hermes V0.2
- **Flutter**: 3.44.1 (channel stable)
- **Dart**: 3.12.1

## 3. Feature implementate

| # | Feature | Stato | Note |
|---|---------|-------|------|
| 1 | Mini-tab Manuale/Rapidi/Preferiti | ✅ | SegmentedButton sostituisce il form singolo |
| 2 | Duplica movimento | ✅ | Immediata, senza form intermedio |
| 3 | Movimenti Rapidi | ✅ | 4 default + CRUD utente |
| 4 | Movimenti Preferiti | ✅ | Salva da movimento esistente + CRUD diretto |
| 5 | Suggeriti automatici | ✅ | Soglia ≥5, raggruppa per categoria+titolo+tipo |
| 6 | Salva movimento come preferito | ✅ | Dal menu contestuale (⋮) nella lista |

## 4. Risultato flutter analyze

```
Analyzing stream_app...
No issues found! (ran in 3.4s)
```

## 5. Risultato flutter test

```
00:05 +65: All tests passed!
```

- `test/widget_test.dart` — 7 test (invariati)
- `test/qa_movements_test.dart` — 58 test (43 originali + 15 nuovi V0.2)

### Nuovi test V0.2

| # | Test | Stato |
|---|------|-------|
| 51 | Duplica movimento via database | ✅ PASS |
| 52 | Duplica movimento aggiorna dashboard | ✅ PASS |
| 53 | Duplica movimento dalla UI | ✅ PASS |
| 54 | Movimento rapido crea movimento reale | ✅ PASS |
| 55 | Dashboard aggiornata dopo movimento rapido | ✅ PASS |
| 56 | Preferito crea movimento reale | ✅ PASS |
| 57 | Salva movimento come preferito | ✅ PASS |
| 58 | Dashboard aggiornata dopo preferito | ✅ PASS |
| 59 | Suggerito appare dopo 5 movimenti simili | ✅ PASS |
| 60 | Nessun suggerito con meno di 5 movimenti | ✅ PASS |
| 61 | Suggeriti multipli con gruppi distinti | ✅ PASS |
| 62 | Parsing virgola ancora funzionante dalla UI | ✅ PASS |
| 63 | Lista mostra movimenti da modalità diverse | ✅ PASS |
| 64 | Movimento rapido personalizzato via UI | ✅ PASS |
| 65 | Movimenti rapidi iniziali presenti | ✅ PASS |

## 6. Risultato build Android

```
flutter build apk --debug
✓ Built build/app/outputs/flutter-apk/app-debug.apk (5.8s)
```

## 7. Scelte UX

| Decisione | Scelta | Motivazione |
|-----------|--------|-------------|
| Duplica: immediata vs form precompilato | **Immediata** | Meno bug, meno click, zero rischi UX |
| Mini-tab: TabBar vs SegmentedButton | **SegmentedButton** | Nessun problema di altezza variabile, più compatto |
| Suggeriti: media vs ultimo importo | **Ultimo importo** | Semplice, prevedibile, nessuna media aritmetica |
| Menu contestuale: icona singola vs PopupMenuButton | **PopupMenuButton (⋮)** | Scalabile per future azioni, non sovraccarica la tile |
| Validazione fallita: silenziosa vs SnackBar | **SnackBar** | Feedback visivo minimale, non rompe UX |

## 8. Scelte tecniche

| Decisione | Scelta | Motivazione |
|-----------|--------|-------------|
| Modello Rapidi/Preferiti | Classi separate (QuickMovement, FavoriteMovement) | Stessa struttura ma domini diversi, chiarezza semantica |
| Persistenza Rapidi/Preferiti | In-memory (stessa lista di movements) | Coerente con architettura V0.1, nessuna dipendenza aggiuntiva |
| Suggeriti calcolati vs memorizzati | **Calcolati on-the-fly** | Nessuna duplicazione dati, sempre aggiornati |
| `createMovementFromTemplate()` | Metodo centralizzato in AppDatabase | Tutte le modalità passano dallo stesso punto, zero duplicazione logica salvataggio |
| Movement.copyWith() | Aggiunto per completezza | Non usato in V0.2 (duplica è immediata), utile per future fasi |

## 9. Rischi e limitazioni

| # | Rischio | Impatto |
|---|---------|---------|
| 1 | Rapidi e Preferiti sono in-memory — persi alla chiusura | Come per i movimenti V0.1, limite noto |
| 2 | Suggeriti: soglia 5 fissa, non configurabile | Potrebbe servire una regolazione dopo feedback utenti |
| 3 | Suggeriti: match esatto su titolo (case-insensitive) | "Caffè" e "caffè" matchano, "Caffe" no |
| 4 | Nessuna persistenza SQLite aggiunta | Rapidi/Preferiti muoiono con l'app |
| 5 | Validazione ancora in SnackBar, non inline | Miglioramento UX posticipato |

## 10. Bug trovati in V0.2

Nessun bug nuovo trovato.

## 11. Blocker

| Blocker | Dettaglio |
|---------|-----------|
| Nessuna persistenza | Rapidi, Preferiti, movimenti — tutto in-memory. Comunicato ai tester. |
| CocoaPods | Non installato su questo Mac, iOS release/distribuzione bloccata |

## 12. Raccomandazione finale

# ✅ READY FOR HERMES V0.2 QA

**Condizioni soddisfatte:**

| Criterio | Stato |
|----------|-------|
| flutter analyze OK | ✅ No issues found |
| flutter test OK | ✅ 65/65 passed |
| flutter build apk --debug OK | ✅ 5.8s |
| Duplica funzionante | ✅ Testato (automatico + UI) |
| Rapidi funzionanti | ✅ Testato |
| Preferiti funzionanti | ✅ Testato |
| Suggeriti funzionanti | ✅ Testato |
| Salvataggio movimenti invariato | ✅ Tutti i test V0.1 ancora passano |
| Parsing virgola/punto invariato | ✅ Test 62 conferma |
| Dashboard aggiornata dopo ogni modalità | ✅ Test 52, 55, 58 confermano |
| Regressioni V0.1 | ❌ Nessuna — QA V0.1 era READY FOR BETA, V0.2 non rompe nulla |

---

# HERMES V0.3.2 — Categorie + Delete + Chiusura V0.3

## 1. Data test

2026-06-06

## 2. Versione app/test

- **App**: STREAM powered by BudgetFlow — Hermes V0.3.2
- **Flutter**: 3.44.1 (channel stable)
- **Dart**: 3.12.1
- **SDK constraint**: `^3.12.1`

## 3. Feature completate in V0.3

| # | Feature | Versione | Stato | Note |
|---|---------|----------|-------|------|
| 1 | SQLite persistenza | V0.3.1 | ✅ | Movimenti, Rapidi, Preferiti su disco |
| 2 | Conti (CRUD + saldo) | V0.3.1 | ✅ | Conto default "Principale" non eliminabile |
| 3 | Modifica movimento | V0.3.1 | ✅ | Tap → form precompilato, update SQLite |
| 4 | Confirm Delete dialog | V0.3.2 | ✅ | AlertDialog con Elimina/Annulla |
| 5 | Categorie editabili | V0.3.2 | ✅ | CRUD + archivia/ripristina + protezione |
| 6 | AccountId Rapidi/Preferiti | V0.3.2 | ✅ | Fix allineamento conto |
| 7 | Dashboard dopo delete | V0.3.2 | ✅ | KPI aggiornati confermati (21 test) |

## 4. Device testati

| Piattaforma | Device | Build | Install | Apribile senza PC |
|-------------|--------|-------|---------|-------------------|
| Android | Pixel 6 (API 33) | ✅ APK debug 207MB | ✅ via adb | ✅ SÌ |
| iOS | iPhone di Mattia (iOS 26.5) | ✅ IPA debug 31MB | ✅ via ideviceinstaller | ⚠️ SÌ, 7 giorni (account free) |

## 5. Risultato flutter analyze

```
Analyzing stream_app...
warning • Unused import: 'package:stream_app/models/quick_movement.dart'.
Try removing the import directive • test/dashboard_after_delete_test.dart:11:8 • unused_import

1 issue found. (ran in 1.7s)
```

**Nota**: 1 warning (unused import) — non bloccante per build/run. **Risolto in V0.3.3 (0 issues).**

## 6. Risultato flutter test

```
00:09 +166: All tests passed!
```

*(V0.3.3: 193/193 passed)*

### Distribuzione test

| File | Test | Cosa copre |
|------|------|------------|
| `qa_movements_test.dart` | 126 | V0.1 + V0.2 + V0.3.1 (SQLite, Conti, Modifica, Duplica, Rapidi, Preferiti, Suggeriti, Note) |
| `categories_test.dart` | 27 | CRUD Categorie + Archivia/Ripristina + Protezione + Rename propagazione |
| `dashboard_after_delete_test.dart` | 21 | KPI dopo delete (in-memory 15, SQLite 3, UI 3) |
| `widget_test.dart` | 2 | Confirm Delete dialog UI |
| `qa_risky_scenarios_test.dart` | 17 | Conti, SQLite, Suggeriti, Duplica, Rapidi, Preferiti (V0.3.3) |
| **Totale** | **193** | |

## 7. Risultato build Android

```
flutter build apk --debug
✓ Built build/app/outputs/flutter-apk/app-debug.apk (8.1s)
```

APK size: 207MB (debug, non ottimizzato)

## 8. Risultato install Android

```
~/Library/Android/sdk/platform-tools/adb -s 22091FDF6001QG install -r build/app/outputs/flutter-apk/app-debug.apk
Performing Streamed Install
Success
```

## 9. Risultato build iOS

```
flutter build ios --debug
Automatically signing iOS for device deployment using specified development team in Xcode project: QDZN3K5LUM
Running Xcode build... Xcode build done. (12.3s)
✓ Built build/ios/iphoneos/Runner.app
```

## 10. Risultato install iOS

```
Creato IPA: Stream_Dev.ipa (31MB)
ideviceinstaller install build/ios/iphoneos/Stream_Dev.ipa
Copying to device... DONE.
Install: Complete
```

App verificata su iPhone: `com.mattiasironi.flow` — "Stream App" v1.0.0

## 11. Bug trovati e corretti in V0.3

| # | Bug | Versione | Priorità | Stato |
|---|-----|----------|----------|-------|
| 1 | Nessuna persistenza — dati persi alla chiusura | V0.3.1 | CRITICAL | ✅ Corretto con SQLite |
| 2 | Dashboard non aggiornata dopo modifica movimento | V0.3.1 | HIGH | ✅ Corretto (ListenableBuilder) |
| 3 | Confirm Delete mancante — eliminazione immediata | V0.3.2 | MEDIUM | ✅ Corretto (dialog) |
| 4 | Categorie fisse — non personalizzabili | V0.3.2 | MEDIUM | ✅ Corretto (CRUD + archive) |
| 5 | AccountId non allineato su Rapidi/Preferiti | V0.3.2 | LOW | ✅ Corretto |
| 6 | Test helper senza ensureVisible (falsi fallimenti UI) | V0.3.2 | LOW | ✅ Corretto |

## 12. Bug rimasti

| # | Bug | Priorità | Impatto |
|---|-----|----------|---------|
| — | Nessun bug open noto | — | — |

## 13. Blocker

| Blocker | Dettaglio | Impatto |
|---------|-----------|---------|
| iPhone beta amici | Richiede TestFlight / Apple Developer ($99/anno) | Distribuzione iOS bloccata senza account a pagamento |
| Account Apple gratuito | Provisioning 7 giorni, nessun TestFlight, nessun Release IPA | iOS non distribuibile pubblicamente |
| APK debug banner | Debug build mostra banner rosso "Debug". Usare `--release` per beta externe | UX non ideale per beta testing. **Risoluzione:** `flutter build apk --release` / `flutter build ios --release` per distribuzione |
| APK 207MB | Non ottimizzato (debug, full symbols) | Normale per debug, si riduce in release |

## 14. Raccomandazione finale

# ✅ HERMES V0.3.2 — COMPLETATO

**Condizioni soddisfatte:**

| Criterio | Stato |
|----------|-------|
| flutter analyze | ⚠️ 1 warning (non bloccante) → **0 issues V0.3.3** |
| flutter test | ✅ 166/166 passed → **193/193 V0.3.3** |
| flutter build apk --debug | ✅ |
| Android install su Pixel 6 | ✅ |
| Android apribile senza PC | ✅ SÌ |
| iOS build debug | ✅ |
| iOS install su iPhone | ✅ |
| iOS apribile senza PC | ⚠️ SÌ (7 giorni, account free) |
| SQLite persistenza | ✅ Testata (scrittura + reload) |
| Conti CRUD | ✅ Testato |
| Modifica movimento | ✅ Testato |
| Confirm Delete | ✅ Testato (2 test) |
| Categorie editabili | ✅ Testato (17 test) |
| Dashboard dopo delete | ✅ Testato (21 test) |
| Nessuna regressione V0.1/V0.2 | ✅ 193 test ancora passano |

**Note per beta:**
1. Android beta amici: possibile via APK debug
2. iPhone beta amici: richiede TestFlight / Apple Developer ($99/anno)
3. Prima di V0.4: serve uso reale per 2-3 giorni per validare la profondità V0.3

---

# HERMES V0.3.3 — Human QA Assurance

## Data test

2026-06-06

## 352 scenari QA combinatori unici

Verificati in 30 aree, copertura completa: movimenti, modifiche, delete, duplica, rapidi, preferiti, suggeriti, conti, saldi, dashboard, categorie, rename, archivia, note, SQLite, reload, migrazioni, form, picker, sequenze miste, build.

## Bug trovati

### Bug CRITICAL — Category Rename Consistency Bug

**Causa**: uso di `DefaultCategories.byId()` invece di `db.categories`.

**Punti interessati**:
- `lib/screens/movements_screen.dart:124`
- `lib/screens/dashboard_screen.dart:127`
- `lib/widgets/movement_picker.dart:387,400,757,769`

**Impatto**:
- Categorie rinominate mostravano dati incoerenti (nome vecchio in Movimenti/Dashboard/Picker)
- Categorie custom non sempre visualizzate correttamente (mostravano ID al posto del nome)

**Fix**: Tutte le viste ora leggono dalla fonte di verità: `db.categories`.

| # | Bug | Priorità | Fix |
|---|-----|----------|-----|
| 1 | DefaultCategories.byId() usata invece di db.categories | CRITICAL | Sostituito con db.categories in 6 file |
| 2 | Validazione silenziosa (SnackBar) | MEDIUM | Backlog V0.4+ |
| 3 | Colori hardcoded per tipo | LOW | Backlog |

## Test

```
flutter analyze → 0 issues
flutter test   → 193/193 passed
flutter build apk --debug → ✅ (5.7s)
flutter build ios --debug → ✅ (10.2s)
```

- **Totale test**: 193 (era 166, +27 nuovi)
- **Nuovi test**: 10 rename categoria + 17 risky scenarios

## Stato finale

# ✅ HERMES V0.3.3 — COMPLETATO

---

# HERMES V0.4.2 — Navigation Refactor: Archivio

## Data test

2026-06-06

## Modifica

Le tab Conti, Categorie e Movimenti sono state consolidate dentro una singola tab "Archivio" nella bottom navigation.

**Nuova struttura bottom nav**:
1. Dashboard (Icons.dashboard)
2. Archivio (Icons.folder)

**Dentro Archivio** (`lib/screens/archive_screen.dart`):
- `SegmentedButton` con 3 sezioni: Movimenti, Conti, Categorie
- `IndexedStack` preserva lo stato di ogni sezione
- Movimenti è la sezione default (index 0)

## Cosa NON è cambiato

- Popup CRUD (movimenti, conti, categorie) — identici
- Rapidi e Preferiti — ancora sotto Movimenti
- Database / migrazioni SQLite — nessuna modifica
- Bundle ID — `com.mattiasironi.flow`
- Logiche refresh icone/colori — funzionanti
- Fonte categorie runtime — `AppDatabase.categories`
- Fonte conti runtime — `AppDatabase.accounts`

## Test

```
flutter analyze → 0 errors (2 pre-existing in test/)
flutter test   → 235/235 passed
```

Nessun test aggiunto, tutti i 235 test esistenti passano senza modifiche strutturali. Le navigazioni nei test sono state aggiornate per usare `Archivio` invece delle vecchie tab.

---

# HERMES V0.4.1 — Account Icon/Color Refresh

## Data test

2026-06-06

## Bug trovato e corretto

### Account Icon/Color Bug (CRITICAL)

**Root cause**: Il modello `Account` non aveva un campo `color`. Il `ColorPicker` nella schermata di modifica conto era puramente decorativo — l'utente poteva selezionare un colore ma non veniva mai salvato. Tutti i rendering degli account usavano `StreamColors.primary` hardcoded, ignorando qualsiasi preferenza utente.

**Fix**:
1. Aggiunto campo `int color` al modello `Account` (default `StreamColorPalette.defaultColor` = 0xFFEF5350)
2. SQLite V5 migration aggiunge colonna `color INTEGER NOT NULL DEFAULT 4278230352`
3. `updateAccount()` accetta parametro `color` opzionale
4. `archiveAccount()` preserva `iconKey` e `color` (non venivano salvati)
5. 5 views aggiornate per usare `account.color`:
   - `accounts_screen.dart` — card bg
   - `movement_form.dart` — dropdown icon
   - `movement_picker.dart` — 3 punti (Rapidi, Preferiti, lista)
   - `dashboard_screen.dart` — tile movimento
   - `movements_screen.dart` — card movimento

## Regola

Views devono sempre risolvere `accountId → db.accounts` per nome/tipo/colore/iconKey. Mai usare hardcoded per account rendering.

## Test

```
flutter analyze → 0 issues
flutter test   → 235/235 passed
flutter build apk --debug → ✅
flutter build ios --debug → ✅
```

**Test totali**: 235 (era 220, +15 nuovi)
- **Nuovo file**: `test/account_icon_color_test.dart` — 15 test dedicati:
  - Account model serializza/deserializza color
  - updateAccount salva color
  - archiveAccount preserva iconKey e color
  - Viste mostrano colore corretto (UI test)
  - Colore default applicato se assente
  - Regressione: tutte le viste esistenti ancora funzionano
  - Nessuna regressione V0.1-V0.4 (220 test ancora passano)

## Build

| Piattaforma | Build | Install | Note |
|-------------|-------|---------|------|
| Android | ✅ APK debug 5.5s | ❌ Pixel 6 non collegato via USB | APK pronto ma non installato |
| iOS | ✅ IPA debug 12.8s | ✅ via ideviceinstaller su iPhone | Upgrade eseguito, dati preservati |

## Build V0.4.2

| Piattaforma | Build | Risultato |
|-------------|-------|-----------|
| Android | `flutter build apk --debug` | ✅ |
| iOS (debug) | `flutter build ios --debug --no-codesign` | ✅ |
| iOS (profile) | `flutter build ios --profile` | ✅ |

## Regressioni V0.4.2

Tutti i 235 test esistenti continuano a passare. Nessuna regressione nelle versioni V0.1-V0.4.2.
Navigazione invariata: Rapidi e Preferiti ancora sotto Movimenti. Popup CRUD intatti.

## SafeArea UX Fix

Aggiunto `SafeArea` ad ArchiveScreen con padding top 12px oltre la safe area. Il SegmentedButton ora rispetta correttamente i margini di sicurezza su iPhone (Dynamic Island e notch), Android (punch hole) e tablet.
Nessuna modifica a logica, stato, navigazione, popup, database.

## Stato finale

# ✅ HERMES V0.4.2 — COMPLETATO

# ✅ PRE-BETA SQLITE MIGRATION ROBUSTNESS FIX — COMPLETATO

Fix applicati in `lib/data/sqlite_service.dart`:

| Fix | Impatto |
|-----|---------|
| V6: try/catch ALTER TABLE/backfill/fallback separati | Backfill fallito non blocca più il fallback → date mai NULL |
| V6: backfill sicuro con validazione ISO | `substr` eseguito solo su date con dash in pos. 5 e 8 |
| V6: fallback copre `OR date = ''` | Stringhe vuote non lasciano date non parseable |
| V2: `CREATE TABLE IF NOT EXISTS` | Previene crash loop su upgrade V1→V2 |
| `debugPrint` in tutti i catch | Nessun errore migration silenzioso |

**Test**: 299/299 pass, analyze 2 pre-existing.
**Nuovi test**: 6 test V5→V6 (backfill, fallback malformato, fallback vuoto, fallback dash errate, idempotenza accounts, V1→V6 completo)

## Hermes V0.4.3 — Quick/Favorite Movement Library UX 📋 APPROVATA

> Feature approvata, non ancora implementata. QA futura quando sviluppata.

**TODO QA futuri**:
- [ ] Ricerca testuale funziona per nome, categoria, conto, note, importo
- [ ] Filtro categoria filtra correttamente i template
- [ ] Salva da Manuale crea Rapido/Preferito con dati corretti
- [ ] Aggiorna Preferito modifica il template senza creare duplicati
- [ ] Helper condivisi tra Rapidi e Preferiti (nessuna duplicazione logica)
- [ ] Regressione: popup aggiunta movimento ancora funzionante
- [ ] Regressione: Rapidi/Preferiti esistenti ancora funzionanti
- [ ] Regressione: movimenti reali non confusi con template
- [ ] flutter analyze: 0 errors
- [ ] flutter test: nessuna regressione

---

## Hermes V0.5.5 — Dashboard Filtrata per Periodo ✅

> Feature completata il 2026-06-07

**File modificato**: `lib/screens/dashboard_screen.dart`
**Test**: 13 nuovi in `test/dashboard_filtered_test.dart`
**Risultato**: 312 test pass, flutter analyze: 0 nuovi issue

### QA Checklist

- [x] TimeFilterBar presente in dashboard (Giorno/Mese/Anno/Periodo + navigazione)
- [x] Default filter = mese corrente
- [x] Entrate filtrate per periodo
- [x] Spese filtrate per periodo
- [x] Saldo filtrato per periodo
- [x] Numero movimenti filtrato
- [x] Patrimonio (totalAccountsBalance) NON filtrato — globale
- [x] Cambio giorno: KPI aggiornati
- [x] Cambio mese: KPI aggiornati
- [x] Cambio anno: KPI aggiornati
- [x] Periodo custom: KPI aggiornati
- [x] Stato vuoto: "Nessun movimento nel periodo selezionato" quando periodo vuoto ma ci sono movimenti globali
- [x] Stato vuoto originale preservato quando nessun movimento globale
- [x] Nessuna modifica a database, migration, Calendario, Archivio, popup movimenti
- [x] flutter analyze: 0 nuovi issue
- [x] flutter test: 312/312 pass (13 nuovi + 299 pre-esistenti)

### KPI filtrati
| KPI | Fonte |
|-----|-------|
| Entrate periodo | `movements.filterByTime(filter).where(income).sum` |
| Spese periodo | `movements.filterByTime(filter).where(expense).sum` |
| Saldo periodo | entrate − spese periodo |
| Movimenti periodo | `filteredMovements.length` |

### KPI non filtrati
| KPI | Fonte | Motivo |
|-----|-------|--------|
| Patrimonio totale | `db.totalAccountsBalance` | Valore globale, indipendente dal periodo |
| Saldi conti | `db.getAccountBalance()` | Strutturale, non temporale |
| Fondi | N/A | Non implementato |

*Documento generato il 2026-06-07*

---

## MovementCard unico — Refactor Architetturale ✅

> Completato il 2026-06-07, dopo V0.5.5 Dashboard Filtrata

**File nuovo**: `lib/widgets/movement_card.dart`

**File modificati**:
- `lib/screens/dashboard_screen.dart` — rimosso `_MovementTile` (~71 righe)
- `lib/screens/calendar_screen.dart` — rimosso `_CalendarMovementCard` (~84 righe)
- `lib/screens/movements_screen.dart` — rimosso `_MovementCard` + `_PopupMenu` (~221 righe)

**Totale righe duplicate rimosse**: ~376

### Cause

Ogni schermata aveva il proprio widget privato per renderizzare un movimento:
1. `DashboardScreen._MovementTile` (40×40 icon, no popup)
2. `CalendarScreen._CalendarMovementCard` (36×36 icon, no popup)
3. `MovementsScreen._MovementCard` + `_PopupMenu` (36×36 icon, popup completo)

### Soluzione

Widget unico in `lib/widgets/movement_card.dart` con:
- API dichiarativa: `movement`, `category`, `account`, `onTap`, `onEdit`, `onDuplicate`, `onSaveAsFavorite`, `onDelete`, `showNotes`, `showDate`
- Popup menu automatico quando almeno una callback popup è fornita
- Card puramente UI: non scrive su database, non aggiorna Actual, non calcola aggregati
- Icona standardizzata a 36×36 px (prima 40×40 in Dashboard)

### Dove viene usato

| Schermata | Contesto | Callback usati |
|-----------|----------|----------------|
| Dashboard | Ultime 5 transazioni del periodo | nessuno (solo visuale) |
| Calendario | Movimenti del giorno selezionato | `onTap` → apre modifica |
| Movimenti/Archivio | Lista filtrata | `onEdit`, `onDuplicate`, `onSaveAsFavorite`, `onDelete` |

### Test

- **Nuovo file**: `test/movement_card_test.dart` — 14 widget test
- Copertura: render nome, importo, categoria, account, distinzione entrata/spesa, `onTap`, popup menu, `showNotes`/`showDate`

### Risultato finale

| Metrica | Valore |
|---------|--------|
| flutter test | **326/326 pass** (era 312) |
| flutter analyze | **2 pre-existing** (0 nuovi) |
| +14 nuovi widget test | ✅ |
| ~376 righe duplicate rimosse | ✅ |

### Posizionamento architetturale

MovementCard prepara tecnicamente:

| Feature futura | Come riusa MovementCard |
|----------------|------------------------|
| Ricerca Globale (F23) | Card per mostrare risultati ricerca |
| Preferiti rapidi (F12) | Card per template preferiti |
| Import Preview (F21) | Card per preview CSV |
| Heatmap Calendario (F13) | Card nel detail-on-tap del giorno |

### Rischio residuo

`movement_card.dart` contiene ancora il confirmation dialog interno per delete (`_confirmDelete`). È pura UI (non scrive su DB). Per ora accettabile. In futuro valutare spostamento della conferma nelle screen o in un dialog service per coerenza architetturale. La distinzione è: MovementCard gestisce UI del delete (dialog), il callback `onDelete` esegue la logica (rimozione DB).

---

# AUDIT ASYNC/TIMING — 2026-06-08

## Contesto

Dopo la correzione del bug `void async` sui 22 CRUD methods di `AppDatabase` (convertiti da `void async` a `Future<void> async`), è stato eseguito un audit completo del progetto alla ricerca di problemi async/timing simili.

## Scansione

- **47 file** ispezionati (lib/ + test/)
- **22 metodi** `void async` → `Future<void> async` (già fixati)
- **0 `void async`** rimasti nel codice
- **0 `unawaited()`** calls
- **0 `.then()`** chains in produzione

## Risultati

### CRITICAL — Applicati

| # | File | Linea | Problema | Fix |
|---|------|-------|----------|-----|
| C1 | `backup_screen.dart` | 149 | `_import(json)` chiamato senza `await` — eccezioni perse, UI state non aggiornato | Aggiunto `await` |
| C2 | `movements_screen.dart` | 67-70 | `_toggleShowNotes(value)` non awaitato in `onChanged` — `_showNotes` aggiornato dopo rebuild UI | `_showNotes` settato prima di `setSheetState` |

### HIGH — Applicati

| # | File | Linea | Problema | Fix |
|---|------|-------|----------|-----|
| H1 | `database.dart` | 389,394 | `archiveCategory`/`restoreCategory` dichiarati `void` ma chiamavano `Future<void> updateCategory` — fire-and-forget, eccezioni perse | Convertiti a `Future<void> async` con `await updateCategory` |
| H2 | `dashboard_after_delete_test.dart` | Gruppo 2 (SQLite reload) | CRUD chiamati senza `await`, sincronizzati con `Future.delayed(100ms)` fragile | Aggiunto `await` a 8 CRUD calls, rimosse 6 `Future.delayed` |
| H3 | `persistence_test.dart` | 179 | `db2.addMovement(...)` non awaitato con SQLite attivo | Aggiunto `await` |

### MEDIUM — Applicati

| # | File | Linea | Problema | Fix |
|---|------|-------|----------|-----|
| M1 | `qa_risky_scenarios_test.dart` | Tutti i test in-memory | CRUD calls non awaitate (safe oggi perché `_sqlite == null`, ma fragili per refactoring) | Aggiunto `await` a ~30 CRUD calls, rimosse 3 `Future.delayed` superflue |
| M2 | `dashboard_after_delete_test.dart` | Gruppo 1 (in-memory) | 36 CRUD calls non awaitate, test non `async` | Test convertiti a `async`, aggiunto `await` a 36 CRUD calls |

### LOW — Non applicati (monitorati)

| # | File | Linea | Probleta | Nota |
|---|------|-------|----------|------|
| L1 | `database.dart` | 488-504 | `reloadFromDb()` — stato parziale visibile tra `await` points | Architetturale, fix complesso (snapshot). Rischi reali bassi. |
| L2 | `database.dart` | 59-83 | `initialize()` — stesso problema di stato parziale | Idem. Non si sovrappone a CRUD in produzione. |
| L3 | `qa_risky_scenarios_test.dart` | 312-315 | Test N1 è no-op (`expect(true, true)`) | Rimuovere in prossimo batch. |

## Stato finale

| Metrica | Valore |
|---------|--------|
| flutter analyze | **0 issues** |
| flutter test | **387/387 pass** |
| flutter build apk --release | **PASS** (66.3MB) |
| flutter build ios --release --no-codesign | **PASS** (32.7MB) |
| 22 CRUD methods | `Future<void>` |
| `void async` residui | **0** |
| `unawaited()` calls | **0** |
| Test con `Future.delayed` per timing | **0** (rimossi tutti) |

---

# V0.6 — Dashboard Filtrata per Periodo V2 — 2026-06-08

## Versione app/test

- **App**: STREAM powered by BudgetFlow — Hermes V0.6
- **Flutter**: 3.44.1 (channel stable)
- **Dart**: 3.12.1

## Risultati

```
flutter analyze: No issues found
flutter test: 412/412 pass
flutter build apk --release: PASS (66.3MB)
flutter build ios --release --no-codesign: PASS (32.7MB)
```

## Cosa è stato testato

### Nuovi test dashboard (8):

| Test | Cosa verifica |
|------|---------------|
| 2.5 | Lista movimenti filtrata mostra movimenti dentro il periodo, nasconde fuori |
| 2.6 | Lista nascosta (SizedBox.shrink) quando nessun movimento nel periodo |
| 2.7 | Limite 20 movimenti + messaggio "altri N" quando >20 |
| 2.8 | Lista si aggiorna al cambio filtro da Mese a Giorno |
| 3.1 | Pulsante "Periodo" esiste ed è tappabile |
| 4.1 | Filtro mese correttamente su 1000 movimenti (500 dentro, 500 fuori) |
| 4.2 | Patrimonio invariato dopo filtro su 1000 movimenti |
| 4.3 | Filtro custom range su 1000 movimenti (360/1000 nel range 10-19) |

### TimeFilterBar fix:
- "Periodo" rinominato in "Intervallo" nel SegmentedButton
- Tap su "Intervallo" ora apre `IntervalPickerSheet` immediatamente (via `addPostFrameCallback`)
- `showDateRangePicker` nativo sostituito da `IntervalPickerSheet`

### IntervalPickerSheet:
- Nuovo widget `lib/widgets/interval_picker_sheet.dart`: bottom sheet dedicato
- Header: "Seleziona intervallo", Da/A cards tappabili, Annulla/Applica
- Tap su Da o A apre `StreamDatePicker.show()` individualmente
- Validazione: A >= Da; "Applica" disabilitato se intervallo invalido
- Label filtro: formato breve "15 giu → 30 giu" (compact per SegmentedButton)

### Categoria dettaglio:
- `_CategoryExpenseRow` tappabile → `_CategoryDetailSheet` bottom sheet
- Dettaglio: nome categoria, totale, conteggio, movimenti filtrati nel periodo
- Quick-add "+" icona su ogni riga categoria

### Azione rapida categoria:
- Ogni riga "Spese per categoria" ha icona "+"
- Apre `MovementPicker` con categoria pre-selezionata (`categoryPreFill`)
- `_ManualForm.initState` gestisce `categoryPreFill` per pre-selezionare tipo e categoria
- `createMovementFromTemplate` usato per creazione (non updateMovement)

# V0.6.0 — QA Completa (500 scenari analizzati)
 
## Data test
 
2026-06-08
 
## Versione
 
- **App**: STREAM powered by BudgetFlow — Hermes V0.6.0
- **Flutter**: 3.44.1 (channel stable)
- **Dart**: 3.12.1
- **Build**: APK 66.1MB | iOS 32.6MB
 
## Risultati verify

```
flutter analyze    → 0 issues
flutter test       → 426/426 All tests passed
build apk release  → PASS (66.1MB)
build ios release  → PASS (32.6MB, --no-codesign)
```

## Copertura scenari (500 totali)

| Area | Scenari | Coperti | Scoperti | Automatizzabili | Nuovi test |
|------|---------|---------|----------|----------------|------------|
| TF — TimeFilter Model | 34 | 34 | 0 | 34 | — |
| TFB — TimeFilterBar | 15 | 11 | 4 | 11 | 3 widget |
| D — Dashboard Filtered | 30 | 24 | 6 | 27 | 4 widget |
| DAD — Dashboard After Delete | 25 | 22 | 3 | 24 | 1 unit |
| M — Movements | 65 | 61 | 4 | 63 | 2 widget |
| R — Risky/Edge | 20 | 16 | 4 | 16 | 1 unit |
| ST — Stress/Load | 20 | 12 | 8 | 10 | — |
| C — Categories | 30 | 28 | 2 | 29 | 1 unit |
| A — Accounts | 40 | 37 | 3 | 38 | 2 unit |
| B — Backup Service | 45 | 41 | 4 | 43 | — |
| P — Persistence SQLite | 30 | 29 | 1 | 30 | — |
| PM — Persistence Migration | 30 | 29 | 1 | 30 | — |
| CA — Calendario | 25 | 20 | 5 | 21 | 1 widget |
| UI — Navigazione/UX | 55 | 30 | 25 | 25 | 6 widget |
| DOC — Documentazione | 26 | 22 | 4 | 0 (static) | — |
| **TOTALE** | **500** | **416** | **84** | **394** | **14 nuovi** |

## Bug trovati e corretti

### B1 — CRITICAL: TimeFilterBar apre month picker invece di IntervalPickerSheet
- **File**: `lib/widgets/time_filter_bar.dart`
- **Problema**: `_onModeChanged(customRange)` schedulava `_pickDate` via `addPostFrameCallback` ma **non chiamava `onChanged`**. Quando `_pickDate` eseguiva, `activeFilter.mode` era ancora `month`, quindi entrava nel branch `month` invece di `customRange`. L'IntervalPickerSheet non veniva mai mostrato.
- **Fix**: `_pickDate` ora accetta parametro `forcedMode: TimeFilterMode?.` `_onModeChanged(customRange)` passa `forcedMode: TimeFilterMode.customRange`, bypassando `activeFilter.mode`.
- **Test**: 3.1–3.4 (4 nuovi widget test)

### B2 — MEDIUM: customRange label test hardcoded alla data odierna
- **File**: `test/dashboard_filtered_test.dart` (test 3.4)
- **Problema**: Il test cercava la data odierna ("08/06/2026") ma l'IntervalPicker mostra il primo del mese ("01/06/2026")
- **Fix**: Test aggiornato a cercare "01/..." invece di today

### B3 — MEDIUM: Category expense row off-screen nei widget test
- **File**: `test/dashboard_filtered_test.dart` (test 4.2, 4.3)
- **Problema**: La riga categoria "Spesa" era fuori schermo (Dashboard usa ListView), `tap()` trovava coordinate fuori dal render tree
- **Fix**: Aggiunto `ensureVisible()` prima di `tap()`, usato `find.ancestor` per trovare il GestureDetector univoco

## Bug rimasti (noti, non bloccanti)
 
- **Lista movimenti limitata a 20**: Se il periodo ha 100+ movimenti, l'utente deve andare in Archivio. Voluto per MVP.
- **categoryPreFill vs prefill**: Se entrambi passati a MovementPicker, `prefill` ha priorità. Non c'è caso d'uso attuale.
- **Nessun test per Device Rotation**: Landscape non testato (app locked portrait).
- **Nessun test per BackupScreen UI**: Testata solo reachability, non interazione.
 
## Aree più deboli (gap >5)
 
1. **UI/Navigazione (25 gap)**: Bottom sheet, MovementPicker interazioni, Archive section switching, Calendar FAB
2. **Stress/Load (8 gap)**: Performance test, memory, scroll con 10K items (manuali)
3. **Calendario (5 gap)**: Movimenti del giorno, FAB + MovementPicker, giorni senza movimenti
4. **Dashboard (6 gap)**: Negative balance, zero KPI, color consistency, rapid interval picker

## Raccomandazione finale
 
**PRONTO per prossimo sprint.** 426 test pass, 0 issue analyze, build APK/iOS OK.
 
Rischio residuo basso. Nessun CRITICAL bug aperto. 14 nuovi test aggiunti in questa sessione.

## Rischio residuo

- **Lista movimenti in Dashboard**: primo MVP con max 20 items. Se il periodo ha molti movimenti (es. 100+), l'utente deve andare su Archivio per vederli tutti. Performance OK per uso normale (max ~100 movimenti/mese).
- **categoryPreFill in MovementPicker**: se il MovementPicker viene esteso in futuro, assicurarsi che `prefill` e `categoryPreFill` non creino conflitti (attualmente `prefill` ha priorità su `categoryPreFill`).

## Validazione finale CSV 1Money

- Dataset reale validato: **6369 movimenti unici**
- Intersezione esatta Stream / 1Money: **6369**
- Movimenti presenti solo nel backup Stream: **0**
- Movimenti presenti solo nel CSV 1Money: **0**
- Le differenze residue osservate durante i controlli precedenti erano dovute a dataset di confronto diversi, non a perdita di dati nell'import
- Il comportamento dell'import CSV 1Money può essere considerato validato sul dataset reale usato per la QA finale

---

# V0.8.3 — Date Filter in Categories and Accounts

## Data test

2026-06-10

## Risultati verify

```
flutter analyze --no-pub → 0 issues
flutter test --no-pub    → 625/625 All tests passed
```

## Cosa è stato verificato

### Categorie
- `TimeFilterBar` presente nella schermata principale Categorie
- KPI categorie filtrati dal periodo selezionato
- Card Stream usa importi e conteggi del periodo selezionato
- Lista grouped ordina le Top categorie usando i movimenti del periodo
- Transfer esclusi dai totali categoria
- Bottom sheet categoria inizializzato con il filtro della pagina

### Conti
- `TimeFilterBar` presente nella schermata principale Conti
- Riepilogo periodo per conto: entrate, uscite, trasferimenti netti, numero movimenti
- Saldo conto visibile storico/as-of al termine del periodo selezionato
- Formula saldo fine periodo: `initialBalance + impatto di tutti i movimenti con data <= fine periodo`
- Formula saldo inizio periodo: `initialBalance + impatto di tutti i movimenti con data < inizio periodo`
- Movimenti netti periodo: entrate periodo - uscite periodo + trasferimenti netti periodo
- Corretto il caso gennaio: storico precedente al periodo contribuisce al saldo finale
- Bottom sheet conto inizializzato con il filtro della pagina

### Regressioni
- V0.8.2 confermata: transfer ancora esclusi da Entrate/Uscite/Bilancio globali
- Transfer ancora inclusi correttamente nei saldi conto origine/destinazione
- Test legacy bottom sheet aggiornati per distinguere filtro pagina e filtro dettaglio
- Saldo attuale reale (`getAccountBalance`) resta derivato da `initialBalance + tutti i movimenti`

## Vincoli confermati

- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push eseguito

---

# V0.8.4 — Interactive Category/Account Menus

## Data test

2026-06-10

## Risultati verify

```
flutter analyze --no-pub → 0 issues
flutter test --no-pub    → 627/627 All tests passed
```

## Cosa è stato verificato

### Categoria
- Tap categoria apre `category_interactive_sheet`
- Header, riepilogo periodo, azioni e lista movimenti hanno key testabili
- Azione Movimento apre `MovementPicker` con tipo categoria precompilato
- Azioni Modifica e Archivia/Ripristina riusano logiche esistenti
- Lista movimenti resta filtrata dal periodo e dai soli income/expense della categoria

### Conto
- Tap conto apre `account_interactive_sheet`
- Header, saldo as-of, riepilogo periodo, azioni e lista movimenti hanno key testabili
- Azione Movimento apre `MovementPicker` con conto precompilato
- Azione Trasferisci apre `MovementPicker` in modalità transfer con conto origine precompilato
- Saldo as-of V0.8.3 invariato
- Conti archiviati restano consultabili; archiviazione disponibile sui conti attivi

### Regressioni
- Transfer esclusi da Entrate/Uscite/Bilancio globali
- Transfer inclusi nei saldi conto origine/destinazione
- Conti archiviati esclusi dal saldo disponibile
- Calculator Pad ancora usato dai form importo tramite `MovementPicker`

## Vincoli confermati

- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push eseguito
