# NEXT SESSION

> Aggiornato: 2026-06-19

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

## Prossimo Sprint Consigliato

1. Eseguire solo QA manuale residua su device reale per i flussi più sensibili Hermes prima di aprire nuovo scope prodotto.
2. Valutare se aggiungere un entry point diretto all’edit movimento nel dettaglio Beneficiari: oggi la lista usa `GroupedMovementsList` senza callback `onEdit`.
3. Eventualmente rifinire piccoli allineamenti UX residui del flow movimento, ma senza riaprire regressioni sui controller condivisi.
4. Se parte un nuovo sprint funzionale, trattare Hermes come chiusura candidata già stabilizzata e aprire scope separato.

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
