# NEXT SESSION

> Aggiornato: 2026-06-21

Questa pagina è il punto di partenza consigliato per la prossima sessione.

## Stato Attuale

- V0.11j completata: lo `chart_style` scelto in Impostazioni ora cambia davvero card, barre, donut, legenda, empty state e superfici heatmap collegate ai grafici senza toccare dati o calcoli.
- Fix di audit incluso in V0.11j: le chart visibility preferences ora filtrano davvero il render di ogni card singola, quindi cambiare stile non riattiva grafici nascosti e nascondere un grafico non resetta lo stile.
- V0.11i-fix3 completata: la sheet dettaglio conto ora e movement-first. Header, azioni, filtro periodo e mini-summary occupano meno spazio; il `Riepilogo dettagliato` e collassabile e la lista movimenti entra nel primo viewport molto prima.
- V0.11i-fix2 completata: gli stili KPI globali hanno copertura coerente anche nei riepiloghi condivisi e nelle card legacy gia migrate al tema.
- V0.11i-fix1 completata: summary periodali, heatmap, flow add/edit, picker e suggerimenti movimento usano superfici/palette dinamiche senza cambiare logica business.
- V0.11j-fix1 completata: Hero KPI Cards con `StreamKpiEmphasis` (normal/hero), High Contrast hero giallo/nero, key stabili per tutte le schermate. KPI style e Chart style restano separati. `flutter test`: 1053 passati, ~1 skipped.
- QA locale aggiornata: `flutter analyze` resta info-only per warning storici fuori scope; `flutter test` full suite verde con `1053` passati e `1` skipped.
- Residuo principale fuori sprint: warning analyzer legacy in `database.dart`, `backup_screen.dart`, `categories_screen.dart` e `theme_test.dart`, ma nessun errore bloccante nell’area Conti/Movimenti/KPI.

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
- Hermes Extended QA Audit completato: `1.641` scenari data-driven, `7.475` controlli/logiche, `test/qa_audit_matrix_test.dart` + stress/extensive + full suite verdi (`1048` passati, `1` skipped).
- Hermes QA green / closure candidate: nessun nuovo P0/P1/P2 trovato nel perimetro dell’audit finale.

## Focus consigliato

1. QA manuale multi-tema su combinazioni `theme + chart_style + hidden_chart_ids` in Dashboard, Grafici e heatmap
2. Pulizia warning analyzer storici fuori scope
3. Verifica visuale finale su device reale della nuova sheet account in viewport piccoli e su piu temi/KPI styles

## Prossimo Sprint Consigliato

1. Pulizia warning analyzer/documentazione storica incoerente dopo la chiusura V0.11j
2. QA manuale su device reale per flussi più sensibili
3. UI polish residui sulle combinazioni tema/grafici

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
- Le superfici heatmap ora condividono token chart-style sulle card esterne: eventuali test futuri non devono piu aspettarsi la vecchia surface elevata generica.
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
