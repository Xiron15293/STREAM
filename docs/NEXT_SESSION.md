# NEXT SESSION

> Aggiornato: 2026-06-21

Questa pagina è il punto di partenza consigliato per la prossima sessione.

## Stato Attuale

- V0.11l-a-fix1 completata: nel bottom sheet del filtro categorie Movimenti, le categorie sono ora raggruppate visivamente in sezioni "Uscite" (expense) ed "Entrate" (income). Selezione mista ancora supportata. Nessun cambio logica/persistenza. `flutter test` full suite `1104` passati, `~1` skipped.
- V0.11l-a completata: i filtri di conti e categorie sono ora scoped **solo** alla schermata Movimenti e persistono per profilo tramite `movements_filter_account_ids_<profileId>` e `movements_filter_category_ids_<profileId>`.
- V0.11l-a completata anche sul reset: `clearForReset(activeProfileId: ...)` pulisce i filtri Movimenti del solo profilo corrente e riallinea i notifier in-memory.
- QA locale aggiornata: `flutter test` full suite verde con `1100` passati e `~1` skipped; `flutter analyze` resta pulito da warning/error nuovi ma continua a mostrare `34` info pre-esistenti del repo.
- Regressioni coperte: transfer origin/destination, AND tra filtri conti/categorie, sanitize ID invalidi, profile scope, movimenti view modes, show notes, QA movimenti ed extensive.
- V0.11k-fix5 completata: backup/restore Patrimonio Dashboard ora e profile-safe end-to-end; `activeProfileId` passa da `SettingsScreen` a `BackupScreen` e poi a `BackupService` per export, pre-restore backup e restore.
- V0.11k-fix5 completata anche sul fallback sicuro: se `activeProfileId` e nullo, il restore non crea o usa la chiave legacy `dashboard_net_worth_account_ids`.
- QA locale aggiornata: `flutter test` full suite verde con `1091` passati e `~1` skipped; `Package.resolved` puo ancora comparire deleted dopo alcune run Flutter locali ma viene ripristinato senza commit.
- V0.11k-fix2 completata: la selezione conti Patrimonio Dashboard e ora profile-scoped, sanificata contro i conti validi del profilo corrente e ricaricata correttamente al cambio profilo.
- V0.11k-fix2 completata anche sul reset runtime: `clearForReset()` riallinea SharedPreferences e notifier in-memory per tema, KPI, chart style, chart visibility, layout categorie, vista movimenti e filtro conti patrimonio.
- QA locale aggiornata: `flutter test` full suite verde con `1068` passati e `~1` skipped; `android/.kotlin/` non si e ripresentato dopo i test.
- V0.11k-fix1 completata: Archive top tabs single-line — le label `Movimenti`, `Conti`, `Categorie`, `Benefic.` nel `SegmentedButton` dell'Archivio non vanno piu a capo grazie a `FittedBox` + `Text(maxLines:1, softWrap:false)`.
- V0.11k completata: Dashboard Net Worth Account Selection — l'utente puo selezionare quali conti attivi includere nel patrimonio Dashboard tramite bottom sheet con checkbox. Default "Tutti i conti". Preferenza salvata via PreferencesService. Healing automatico per conti archiviati/eliminati. Pill conti hero mostrano solo conti selezionati (max 3 + "+N altri").
- V0.11k fix tab: label SegmentedButton (`Giorno`, `Sett.`, `Mese`, `Anno`, `Intervallo`) non vanno piu a capo grazie a `FittedBox`.
- V0.11k fix form: pulsanti bottom `Salva`/`Trasferisci` rimossi; azione primaria e l'icona check in alto.
- V0.11j-fix4 completata: hero Patrimonio senza duplicazione conti, lista pill compatta con `+N altri`, titolo semplificato e layout pill piu robusto su viewport stretti.
- V0.11j-fix4 completata anche sul lato KPI: `Automatico` non e piu un clone di `Minimal`, ma una scelta consigliata dal tema via `resolveEffectiveKpiStyle(...)`; in Aurora la hero usa davvero il layout split.
- V0.11j-fix1 completata: Hero KPI Cards con `StreamKpiEmphasis` (normal/hero), High Contrast hero giallo/nero, key stabili per tutte le schermate.
- QA locale aggiornata: `flutter test` full suite verde con `1059` passati e `~1` skipped.

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

1. QA manuale filtri Movimenti multi-profilo su device reale: cambio profilo, reset profilo corrente, verifica label e transfer origin/destination
2. QA manuale backup/restore multi-profilo su device reale: export da profilo B, restore su profilo B, verifica assenza bleed su profilo A
3. Follow-up repo hygiene: capire perche alcune run Flutter marcano deleted `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
4. Follow-up P2 fragilita shader test: `Asset 'shaders/ink_sparkle.frag' not found`

## Prossimo Sprint Consigliato

1. QA manuale su device reale per filtri Movimenti scoped + selezione conti patrimonio
2. Hardening ambiente test Material 3 per il caso shader `ink_sparkle.frag`
3. UI polish residui

## Regole Git

- Non usare `git add -A`.
- Se compare `Package.resolved` come deleted, ripristinalo prima di proseguire.
- Preferire commit piccoli e separati per sprint.
- Non mischiare docs, test e codice applicativo nello stesso commit se non è strettamente necessario.

## Rischi Noti

- Restano info-level analyzer già presenti nel progetto.
- `flutter analyze` locale chiude ancora con `34` info legacy del repo; la patch V0.11l-a non ne aggiunge di nuove.
- Fragilita test nota P2: `Asset 'shaders/ink_sparkle.frag' not found` in alcuni ambienti test; non risolta in questa patch per evitare cambi fuori scope.
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
- Movimenti: filtri scoped per conti/categorie persistiti per profilo; trasferimenti inclusi dal filtro conti se matchano origine o destinazione; filtro categorie esclude i transfer uncategorized quando attivo.
- Movimenti: header top con close/confirm, amount sticky compatto, sheet azioni condiviso, tap breve modifica, long-press/tre puntini aprono lo stesso menu.
- Heatmap: fallback legacy `list`, `calendar`, `listHeatmap`, `advancedHeatmap` verso heatmap; la UI utente non deve più esporre lista/calendario come vista predefinita.
- Categorie: safe edit consentito anche con contenuti collegati; blocchi solo per azioni distruttive; duplicate validation su ID + namespace + nome normalizzato.
- Suggerimenti movimento: i chip devono restare compatti, locali, deduplicati e non invasivi; Titolo/Note/Beneficiario condividono la stessa logica di base ma restano focus-aware.
- Valuta: il simbolo è un pref di visualizzazione, non una modifica DB/schema.
- QA audit finale: matrice data-driven, stress/extensive e full suite confermano lo stato Hermes QA green.
