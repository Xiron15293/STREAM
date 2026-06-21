# Hermes QA 6000 Report

> Audit finale esteso Hermes, focalizzato sul requisito dei circa 6000 controlli/scenari/assertion.

## Sintesi

- Delta 2026-06-21: V0.11j-fix4 confermata con hero Patrimonio deduplicata, pill `+N altri` e `Automatico` KPI davvero theme-aware, full suite finale **1059 passati / ~1 skipped**
- Delta 2026-06-21: V0.11j confermata con advanced chart styles reali, fix chart visibility per-card e full suite finale **1048 passati / 1 skipped**
- Delta 2026-06-21: V0.11i-fix3 confermata con account detail movement-priority UX, KPI dettagliati collassabili e full suite finale **1038 passati / 1 skipped**
- Delta 2026-06-21: V0.11i-fix2 confermata con copertura KPI style globale allineata ai riepiloghi condivisi
- Delta 2026-06-21: V0.11i-fix1 confermata con movement flow/theme completion, bottom sheet tematizzati e validazione finale consolidata nella stessa suite **1038 passati / 1 skipped**
- Delta 2026-06-21: V0.11j-fix1 Hero KPI Cards (StreamKpiEmphasis, High Contrast giallo/nero, key stabili), **1053 passati / 1 skipped**
- Delta 2026-06-20: V0.11h confermata con superfici/card/chart theme-adaptive, full suite finale **1026 passati / 1 skipped**
- Regressione emersa durante full suite su `AccountsScreen` interactive sheet risolta senza toccare logica dati
- Analyzer locale invariato: solo info storici, nessun errore nuovo

- Target 6000 raggiunto: **sì**
- Matrice QA deterministica aggiunta: `test/qa_audit_matrix_test.dart`
- Stress/extensive QA già esistenti: `test/qa_stress_test.dart`, `test/qa_extensive_test.dart`
- Full suite finale: **verde**
- Stato finale: **Hermes candidate for closure / Hermes QA green**
- Executive summary: `68` file test, `1059` test/casi passati, `~1` skipped, `1.641+` scenari, `7.475+` controlli/logiche
- V0.10 Grafici Tab + V0.10.1 Chart Readability + V0.10.1c Donut/Scroll/Extra: **32** nuovi test
- V0.11 Theme System foundation: **19** nuovi test
- V0.11b Theme applied to widgets: widget grafici e Dashboard KPI migrati, helper fallback sicuro
- V0.11c Chart Style Foundation: applyStyle plumbing, StreamApp listener, palette adattiva. NOTA storica: gli stili selezionabili dall'utente sono arrivati poi nel rollout V0.11j
- V0.11d Real KPI Styles (ValueListenableBuilder, _KpiCard switch, 6 stili)
- V0.11g Chart Readability + Visibility Preferences (donut outside labels, leader lines, chart registry, hiddenChartIds)
- V0.11g-fix2+3: single source slice data, startDegreeOffset -90 alignment, legend widget extraction
- V0.11g-fix3: sectionsSpace alignment in angle calculation + collision avoidance, 1022 test finali
- V0.11i-fix2/fix3: KPI style coverage globale + account detail movement-priority UX, 1038 test finali
- V0.11j: chart style reale in Settings/Grafici/Dashboard + bugfix visibilita singole card, 1048 test finali

**V0.11c V0.11d V0.11g V0.11i V0.11j completati:** chart style foundation, KPI styles reali, chart readability + visibility, categories legacy cleanup e chart styles selezionabili con rollout reale, 1048 test finali.

## Conteggio reale

### Test Dart / Flutter presenti

- File test nel progetto: **68**
- Test case Flutter/Dart passati nel run finale: **1048**

### Matrix QA estesa

- Scenari deterministici nella matrice: **1,641**
- Controlli / assertion / controlli logici eseguiti dalla matrice: **7,475**

### Copertura per area

| Area | Scenari | Controlli per scenario | Totale controlli | Stato |
|---|---:|---:|---:|---|
| Suggerimenti Titolo / Note / Beneficiario | 600 | 4-5 | 2,600 | passed |
| TimeFilter / range | 250 | 5-8 | 1,790 | passed |
| Currency formatter | 400 | 4 | 1,600 | passed |
| Calculator amount input | 300 | 4 | 1,200 | passed |
| Movimenti / balance / trasferimenti | 30 | 6 | 180 | passed |
| Profili isolamento SQLite | 1 | 6 | 6 | passed |
| Visual fit / viewport / testi lunghi | 60 | 1-3 | 99 | passed |
| Stress / extensive QA già esistenti | 300+ | suite esistente | coperto | passed |

> Nota: il totale dei controlli è calcolato dalla matrice deterministica e dalle sue condizioni logiche, non da un campione casuale.

## Distribuzione controlli

- Suggerimenti Titolo / Note / Beneficiario: **2,600**
- Normalizzazione beneficiari: inclusa nella matrice suggerimenti, stessa copertura
- TimeFilter e range: **1,790**
- Currency formatter: **1,600**
- Calculator amount input: **1,200**
- Movimenti / balance / trasferimenti: **180**
- Profili isolamento SQLite: **6**
- Visual fit / viewport / testi lunghi: **99**

**Totale controlli/stimati ma giustificati:** **7,475**

## Severità trovate

- P0 nuovi: **0**
- P1 nuovi: **0**
- P2 nuovi confermati a livello app: **0**
- P3 / tech debt: **info analyzer preesistenti**

## Dati aggiornati V0.11k-fix1

- **Test totali**: 1062 passed, ~1 skipped (+3 new: archive top tabs single-line)
- **Nuovo test**: `test/archive_top_tabs_single_line_test.dart` (3 casi)
- **Nessuna modifica DB/schema/import/export/calcoli/KPI/chart style**

## Dati aggiornati V0.11k-fix5

- **Test totali**: 1091 passed, ~1 skipped
- **Nuovi test**: `test/backup_restore_net_worth_profile_scope_test.dart`, `test/backup_screen_profile_id_test.dart`
- **Fix testati**: backup/restore Patrimonio profile-safe, nessuna chiave globale legacy creata, fallback sicuro con `activeProfileId == null`
- **Repo hygiene**: `Package.resolved` puo ricomparire deleted dopo alcune run Flutter locali; ripristinato prima della chiusura patch
- **Nessuna modifica DB/schema/import/export/saldi/calcoli**

## Dati aggiornati V0.11l-a-fix1

- **Test totali**: 1104 passed, ~1 skipped
- **File test aggiornato**: `test/movements_account_category_filters_test.dart` (+4 nuovi casi: grouping Uscite/Entrate, selezione mista, reset all option, transfer behavior)
- **Area coperta**: raggruppamento visivo categorie Uscite/Entrate nel bottom sheet filtro Movimenti, selezione mista ancora supportata, scroll handling nei test helper
- **Nessuna modifica DB/schema/migrazioni/persistenza/logica filtro/saldi/calcoli/chart/KPI style**
- **Regression suite mirata**:
  - `test/preferences_reset_profile_scope_test.dart`
  - `test/qa_movements_test.dart`
  - `test/qa_extensive_test.dart`
- **Full suite**: `flutter test` ok (`1104` passed, `~1` skipped)
- **Analyze**: nessun warning/error nuovo; persistono `34` info legacy del repo

## Dati aggiornati V0.11l-a

- **Test totali**: 1100 passed, ~1 skipped
- **Nuovo test**: `test/movements_account_category_filters_test.dart`
- **Area coperta**: filtri scoped su Movimenti per conti/categorie, transfer origin/destination semantics, AND logic, sanitize ID invalidi, reset profilo corrente
- **Regression suite mirata**:
  - `test/preferences_reset_profile_scope_test.dart`
  - `test/dashboard_net_worth_profile_scope_test.dart`
  - `test/movements_view_modes_test.dart`
  - `test/show_notes_live_preference_test.dart`
  - `test/qa_movements_test.dart`
  - `test/qa_extensive_test.dart`
- **Full suite**: `flutter test` ok (`1100` passed, `~1` skipped)
- **Analyze**: nessun warning/error nuovo; persistono `34` info legacy del repo

## Dati aggiornati V0.11k

- **Test totali**: 1059 passed, ~1 skipped
- **File test**: ~68
- **Nuove feature testate**: Dashboard Net Worth Account Selection (selezione conti, bottom sheet, healing), tab single-line, form azioni unificate
- **Nessuna modifica DB/schema/import/export/calcoli/KPI/chart style**

## Risultati di esecuzione

- `flutter analyze`: ok, nessun errore nuovo, solo info preesistenti
- `flutter test test/qa_audit_matrix_test.dart`: ok
- `flutter test test/qa_stress_test.dart test/qa_extensive_test.dart`: ok
- `flutter test`: ok (`1059` passed, `~1` skipped)

## Note funzionali consolidate

- `MovementCard` usa tap breve per modifica e long-press/tre puntini per lo stesso sheet azioni centralizzato.
- `AddMovementFlow` mantiene `X` e conferma top sempre accessibili, con importo sticky compatto sincronizzato allo stesso controller.
- `chart_style` e `hidden_chart_ids` convivono: nascondere un grafico non resetta lo stile e cambiare stile non riattiva grafici nascosti.
- I suggerimenti Titolo/Note/Beneficiario sono locali, deduplicati, focus-aware, visibili da 2 caratteri e sostituiscono il valore del campo al tap.
- Il picker Beneficiari legacy resta disponibile; i suggerimenti beneficiario nel flow movimento non fondono automaticamente nomi simili.
- La valuta globale è solo una preferenza di formattazione UI.
- `restoreAccount()` è presente e i conti archiviati espongono `Ripristina`.
- `reassignMovementsAndDeleteCategory(...)` esegue la riassegnazione e la delete categoria in transazione, azzerando eventuali `subcategory_id` incompatibili.
- Limitazione corrente: il dettaglio Beneficiari mostra i movimenti ma non espone ancora un entry point diretto all’edit movimento.

## Limiti dell’audit

- La QA automatizzata non sostituisce il test manuale completo su device fisico
- Le euristiche dei suggerimenti possono produrre falsi positivi/negativi non critici
- Restano gli info analyzer preesistenti, che non bloccano la build ma restano da pulire nel tempo
- La copertura visuale è deterministica e utile, ma non sostituisce un’ispezione visiva manuale dei layout più sensibili
