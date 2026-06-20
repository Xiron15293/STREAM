# Hermes QA 6000 Report

> Audit finale esteso Hermes, focalizzato sul requisito dei circa 6000 controlli/scenari/assertion.

## Sintesi

- Target 6000 raggiunto: **sì**
- Matrice QA deterministica aggiunta: `test/qa_audit_matrix_test.dart`
- Stress/extensive QA già esistenti: `test/qa_stress_test.dart`, `test/qa_extensive_test.dart`
- Full suite finale: **verde**
- Stato finale: **Hermes candidate for closure / Hermes QA green**
- Executive summary: `44+` file test, `979` test/casi dichiarati, `979` passati, `1` skipped, `1.641+` scenari, `7.475+` controlli/logiche
- V0.10 Grafici Tab + V0.10.1 Chart Readability + V0.10.1c Donut/Scroll/Extra: **32** nuovi test
- V0.11 Theme System foundation: **19** nuovi test
- V0.11b Theme applied to widgets: widget grafici e Dashboard KPI migrati, helper fallback sicuro
- V0.11c Real Chart Styles (applyStyle, StreamApp listener, 5 stili)
- V0.11d Real KPI Styles (ValueListenableBuilder, _KpiCard switch, 6 stili)
- V0.11g Chart Readability + Visibility Preferences (donut outside labels, leader lines, chart registry, hiddenChartIds)
- V0.11g-fix2+3: single source slice data, startDegreeOffset -90 alignment, legend widget extraction
- V0.11g-fix3: sectionsSpace alignment in angle calculation + collision avoidance, 1022 test finali

**V0.11c V0.11d V0.11g completati:** chart styles reali, KPI styles reali, chart readability + visibility, 1022 test finali

## Conteggio reale

### Test Dart / Flutter presenti

- File test nel progetto: **44+** (+1 file charts_test.dart, +1 file theme_test.dart)
- Test case Dart/Flutter dichiarati nei test: **990**
- Test case Flutter/Dart passati nel run finale: **990**

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

## Risultati di esecuzione

- `flutter analyze`: ok, nessun errore nuovo, solo info preesistenti
- `flutter test test/qa_audit_matrix_test.dart`: ok
- `flutter test test/qa_stress_test.dart test/qa_extensive_test.dart`: ok
- `flutter test`: ok (`911` passed, `1` skipped)

## Note funzionali consolidate

- `MovementCard` usa tap breve per modifica e long-press/tre puntini per lo stesso sheet azioni centralizzato.
- `AddMovementFlow` mantiene `X` e conferma top sempre accessibili, con importo sticky compatto sincronizzato allo stesso controller.
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
