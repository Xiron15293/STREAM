# Hermes Manual QA Simulation Report

> Audit mirato sulla UX Hermes per add/edit movimento, sticky amount, header compatto sempre visibile, valuta globale e reachability dei layout principali.

## Meta

- Data: 2026-06-19
- Ambito: QA automatizzata mirata + documentazione esito
- Stato: simulazione Hermes verde nel perimetro coperto
- Codice prodotto toccato: solo perimetro Hermes già richiesto
- Codice non richiesto: non modificato intenzionalmente

## Executive Summary

- Nuova suite aggiunta: `test/manual_qa_simulation_test.dart`
- Scenari Hermes simulati: `6`
- Entry point edit coperti direttamente: `5`
- Taglie viewport coperte: `4`
- Suite mirata Hermes: verde
- Regressioni mirate add/edit/card/categories: verdi
- Analyzer: nessun errore nuovo, `4` info preesistenti
- Finding extra emerso da suite esistente fuori perimetro Hermes: `1`

## Esecuzioni

### Verde

- `flutter test --no-pub test/manual_qa_simulation_test.dart`
- `flutter test --no-pub test/manual_qa_simulation_test.dart test/add_movement_flow_test.dart test/movement_card_test.dart test/categories_test.dart`

### Analisi statica

- `dart analyze lib/utils/currency_formatter.dart lib/widgets/add_movement_flow.dart lib/widgets/time_filter_bar.dart lib/widgets/day_header.dart lib/widgets/movement_view_renderer.dart lib/screens/dashboard_screen.dart lib/screens/accounts_screen.dart test/manual_qa_simulation_test.dart test/add_movement_flow_test.dart test/movement_card_test.dart`
- Esito: nessun errore nuovo
- Info già presenti:
  - `lib/screens/accounts_screen.dart:49`
  - `lib/screens/accounts_screen.dart:1047`
  - `lib/screens/dashboard_screen.dart:66`
  - `lib/screens/dashboard_screen.dart:796`

## Copertura automatica aggiunta

### 1. Edit flow reale da entry point applicativi

Simulato l’ingresso in modifica dello stesso movimento dai punti reali:

- `Movements`
- `Dashboard`
- `Accounts`
- `Categories`
- `Calendar`

Per ogni entry point la suite verifica:

- apertura del flow di edit reale
- presenza di `X` e conferma nel top header locale
- comparsa dello sticky amount dopo scroll
- salvataggio sullo stesso record senza duplicazione
- aggiornamento del titolo modificato

### 2. Viewport matrix

Taglie simulate:

- `320x568`
- `390x844`
- `430x932`
- `768x1024`

Verifiche eseguite:

- `MovementPicker` raggiungibile e interagibile
- superfici primarie `Dashboard`, `Accounts`, `Categories` renderizzate
- assenza di exception runtime nel pump
- conferma di reachability base su layout piccoli e medi

### 3. Regressioni mirate collegate

Confermate verdi nella suite mirata:

- sticky amount con simbolo valuta globale corretto
- header locale con `X` e check sempre disponibile
- comportamento suggerimenti titolo/note/beneficiario
- action sheet coerente su `MovementCard` anche da tre puntini
- persistenza categorie e riassegnazione lato data/service già coperta da `test/categories_test.dart`

## Coverage Matrix

| Area | Automatico | Esito | Note |
|---|---|---|---|
| Edit da lista movimenti | Sì | PASS | salva senza duplicare |
| Edit da dashboard | Sì | PASS | sticky/header ok |
| Edit da conti | Sì | PASS | sticky/header ok |
| Edit da categorie | Sì | PASS | sticky/header ok |
| Edit da calendario | Sì | PASS | sticky/header ok |
| Sticky amount live | Sì | PASS | compare dopo scroll |
| Valuta globale nel sticky | Sì | PASS | simbolo coerente, nessuna conversione valore |
| Header locale con X/check | Sì | PASS | sempre raggiungibile |
| Viewport piccoli/medi | Sì | PASS | no exception nel perimetro simulato |
| Action sheet card movimento | Sì | PASS | tre puntini non aprono edit diretto |
| Restore conto archiviato | Coperto da suite esistente | PASS | `accounts_navigation_test.dart` scenario dedicato già presente |
| Delete categoria con riassegnazione movimenti | Coperto da suite esistente | PASS | copertura service/persistenza in `categories_test.dart` |

## Findings

### P0

- Nessuno nel perimetro Hermes simulato

### P1

- Nessuno nel perimetro Hermes simulato

### P2

- Nessuno nuovo nel perimetro Hermes simulato

### P3 / extra finding fuori perimetro stretto Hermes

- `test/accounts_navigation_test.dart`
  - scenario: `Archivio mostra conti e categorie archiviati separati`
  - esito del run ampio: fallisce
  - sintomo osservato: nella schermata archivio categorie la categoria archiviata attesa non compare nel tree del test, mentre il dato risulta archiviato nel database di test
  - impatto: non blocca la nuova simulazione Hermes, ma merita audit separato su archivio categorie

## NEEDS_REAL_DEVICE_QA

- Ergonomia reale di tap su `X` e check con tastiera software aperta
- Comportamento visivo dello sticky amount durante overscroll e bounce nativo
- Test su device piccoli iOS/Android con font scale non standard
- Verifica gesture e hit area su cards/azioni in presenza di animazioni di sistema
- Conferma visuale di testi lunghi, localizzazioni e safe area reali

## NOT_APPLICABLE_CURRENT_CODE

- Entry point edit diretto da dettaglio `Beneficiaries`: non esposto nel codice corrente
- Entry point edit diretto da heatmap/treemap con flusso dedicato separato: non presente come route distinta nel perimetro verificato

## Conclusione

La QA automatizzata nuova per Hermes è verde e copre i percorsi reali di add/edit movimento che erano più a rischio: sticky amount, top actions sempre visibili, valuta globale, save senza duplicazione e tenuta dei layout principali su viewport piccoli/medi.

Resta aperto un finding separato sulla resa delle categorie archiviate dentro la suite archivio esistente. Non è stato corretto in questo passaggio per mantenere l’intervento isolato e non toccare codice non richiesto.
