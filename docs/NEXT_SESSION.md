# NEXT SESSION

> Aggiornato: 2026-06-20

Questa pagina è il punto di partenza consigliato per la prossima sessione.

## Stato Attuale

- Profili separati e isolamento DB sono attivi e verificati.
- Il flow guidato `+ Movimento` copre creazione e modifica con prefill per Entrata, Spesa e Trasferimento.
- Header compatto con `X` e check è sempre accessibile; `Fatto/Annulla` non dipendono più dal fondo dello scroll.
- Il calculator pad è condiviso, l’importo si aggiorna in realtime e il riepilogo sticky compatto compare durante lo scroll.
- Titolo, Note e Beneficiario hanno suggerimenti locali a chip, compatti, deduplicati, focus-aware e tappabili; il tap sostituisce il campo.
- La valuta è configurabile da Impostazioni e il formatter condiviso aggiorna simboli e riepiloghi senza conversione dei valori.
- Le azioni movimento sono centralizzate nello stesso sheet: tap breve = modifica, tap lungo o tre puntini = menu azioni.
- `MovementCard` mantiene questo comportamento nelle viste che la usano, incluse le superfici con riepilogo/heatmap e lista movimenti.
- I conti archiviati hanno `Ripristina`; categorie e sottocategorie archiviate mantengono `Ripristina` preservando icona/colore e storico collegato.
- L’eliminazione categoria con movimenti collegati può passare da archiviazione o riassegnazione verso categoria valida dello stesso tipo, con pulizia `subcategoryId` incompatibili.
- La schermata Movimenti usa la heatmap come vista utente principale per i periodi.
- Le impostazioni heatmap espongono solo `Configura heatmap`.
- Categorie e sottocategorie supportano safe edit, duplicate validation corretta e restore coerente.
- Hermes Extended QA Audit completato: `1.641` scenari data-driven, `7.475` controlli/logiche, `test/qa_audit_matrix_test.dart` + stress/extensive + full suite verdi (`911` passati, `1` skipped).
- Hermes QA green / closure candidate: nessun nuovo P0/P1/P2 trovato nel perimetro dell’audit finale.

## Stato Attuale — V0.11b (Theme Applied to Widgets + KPI + Charts)

- **Helper theme**: `context.streamTheme`, `context.$palette`, `context.$chart` con fallback sicuro a palette Stream Classic
- **Widget grafici migrati**: StreamChartCard, ChartEmptyState, StreamDonutChart, StreamHorizontalBarChart, StreamBarChart — tutti usano palette dinamica
- **Dashboard migrata**: `_KpiCard` usa palette; stili KPI (minimal, dense, outline, solid, split) attivi con padding/bordi/sfondo variabili
- **ChartsScreen**: chip sezione e legenda usano `context.$palette`
- **TimeFilterBar**: label data usa palette
- **StreamColors residue**: ~520 occorrenze in widget non prioritari (accounts, categories, backup, heatmap, calendar, movement_card, day_header) — migrazione completa come follow-up V0.12
- **KPI styles visibili**: Minimal/Dense/Glass/Outline/Solid/Split hanno layout/sfondo/bordi diverso
- **Chart styles reali**: V0.11c (automatic/soft/technical/highContrast/editorial con `applyStyle`)
- **Chart palette effettiva** calcolata in `StreamTheme.build()` con chart style, ascoltata da `StreamApp`
- **Budget non implementato**, resta futuro
- **V0.11g**: donut outside labels + leader lines, chart visibility preferences (registry, hiddenChartIds, settings sheet)
- **1015 test totali**, tutti verdi

## Stato Attuale — V0.11f (Archive + Charts Shell + KPI Hero)

- `ArchiveScreen` ora applica il tema sulla shell principale; `MovementsScreen` usa `canvas` dinamico
- `MovementCard`, `MovementViewRenderer`, `DayHeader`, `MovementActionsSheet` usano palette tema per superfici, testi, divider, icone e danger action
- `ChartsScreen` usa shell e metric colors coerenti con il tema corrente
- Hero `Patrimonio` è collegato allo stile KPI: `dense` è compatto, `minimal` è più arioso, `solid/outline/glass/split` hanno differenze visive reali
- Verifica locale aggiornata: `flutter analyze` pulito sui file toccati; `flutter test` full suite **1015 pass / 1 skipped**
- Residui `StreamColors` fuori scope sprint: `categories_screen.dart` (`77`), `accounts_screen.dart` (`24`), `dashboard_screen.dart` (`9`)
- `Package.resolved` può comparire come deleted nel workspace iOS: non è stato corretto automaticamente in questa sessione

## Prossimo Sprint Consigliato

1. **V0.12 — UI Polish / Migrazione StreamColors residui** con priorità su `categories_screen.dart`, residui `accounts_screen.dart` e residui `dashboard_screen.dart`
2. Oppure **V0.12 — Budget Foundation** se decisione prodotto orientata a Budget
3. QA manuale su device reale per flussi più sensibili

## Regole Git

- Non usare `git add -A`.
- Se compare `Package.resolved` come deleted, ripristinalo prima di proseguire.
- Preferire commit piccoli e separati per sprint.
- Non mischiare docs, test e codice applicativo nello stesso commit se non è strettamente necessario.

## Rischi Noti

- Restano info-level analyzer già presenti nel progetto.
- Alcuni file doc storici contengono dettagli vecchi utili; se li aggiorni, non perdere il contesto precedente.
- Le viste Movimenti/Archivio hanno ancora molta logica di stato e vanno toccate con attenzione.
- Il flusso categorie ha regole di sicurezza e duplicati già consolidate: qualsiasi refactor futuro deve preservare ID, namespace e normalizzazione.
- I suggerimenti locali Titolo/Note/Beneficiario restano basati su euristiche e possono produrre falsi positivi/negativi non critici.
- La QA automatizzata è forte, ma alcune verifiche restano da fare manualmente su device reale.
- Non documentare un entry point edit da Beneficiari finché il dettaglio beneficiario non passa callback `onEdit` alla lista movimenti.

## Storico Utile

- Profili: DB separato per profilo, `MainScaffold` keyed su `activeProfileId`, registry healing dei `dbFileName`.
- Movimenti: form guidato con `AddMovementFlow`, `MovementCalculatorPad`, account/category selector, supporto transfer.
- Movimenti: header top con close/confirm, amount sticky compatto, sheet azioni condiviso, tap breve modifica, long-press/tre puntini aprono lo stesso menu.
- Heatmap: fallback legacy `list`, `calendar`, `listHeatmap`, `advancedHeatmap` verso heatmap; la UI utente non deve più esporre lista/calendario come vista predefinita.
- Categorie: safe edit consentito anche con contenuti collegati; blocchi solo per azioni distruttive; duplicate validation su ID + namespace + nome normalizzato.
- Suggerimenti movimento: i chip devono restare compatti, locali, deduplicati e non invasivi; Titolo/Note/Beneficiario condividono la stessa logica di base ma restano focus-aware.
- Valuta: il simbolo è un pref di visualizzazione, non una modifica DB/schema.
- QA audit finale: matrice data-driven, stress/extensive e full suite confermano lo stato Hermes QA green.
