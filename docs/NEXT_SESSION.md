# NEXT SESSION

> Aggiornato: 2026-06-18

Questa pagina è il punto di partenza consigliato per la prossima sessione.

## Stato Attuale

- Profili separati e isolamento DB sono attivi e verificati.
- Il nuovo flow guidato `+ Movimento` è stabile per Entrata, Spesa e Trasferimento.
- Il calculator pad è condiviso e l’importo si aggiorna in realtime.
- Titolo, Note e Beneficiario hanno suggerimenti locali a chip, compatti e tappabili.
- La valuta è configurabile da Impostazioni e il formatter condiviso aggiorna simboli e riepiloghi.
- La schermata Movimenti usa la heatmap come vista utente principale per i periodi.
- Le impostazioni heatmap espongono solo `Configura heatmap`.
- Categorie e sottocategorie supportano safe edit e duplicate validation corretta.
- La suite test completa è verde al momento dell’ultimo check (`881 passed, 1 skipped`).

## Prossimo Sprint Consigliato

1. Normalizzare tutte le occorrenze di `aggiungi/modifica movimento`.
2. Rendere cliccabile il chip conto nel flow movimento.
3. Fare in modo che il tap su una card movimento da Dashboard, Movimenti e Archivio apra sempre l’editor normalizzato.
4. Uniformare i campi input con conferma esplicita dove manca ancora.
5. Rifinire eventuali edge case residui del flow guidato prima di aggiungere nuove feature.

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

## Storico Utile

- Profili: DB separato per profilo, `MainScaffold` keyed su `activeProfileId`, registry healing dei `dbFileName`.
- Movimenti: form guidato con `AddMovementFlow`, `MovementCalculatorPad`, account/category selector, supporto transfer.
- Heatmap: fallback legacy `list`, `calendar`, `listHeatmap`, `advancedHeatmap` verso heatmap; la UI utente non deve più esporre lista/calendario come vista predefinita.
- Categorie: safe edit consentito anche con contenuti collegati; blocchi solo per azioni distruttive; duplicate validation su ID + namespace + nome normalizzato.
- Suggerimenti movimento: i chip devono restare compatti, locali, deduplicati e non invasivi; Titolo/Note/Beneficiario condividono la stessa logica di base.
- Valuta: il simbolo è un pref di visualizzazione, non una modifica DB/schema.
