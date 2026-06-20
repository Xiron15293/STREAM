# STREAM — Feature Backlog

> Fonte di verità unica per tutte le feature progettate, approvate o ipotizzate.
> Ogni feature è censita con stato, priorità, dipendenze e versione candidata.
> Le feature implementate sono elencate ma segnate come ✅.

---

## Legenda

| Stato | Significato |
|-------|-------------|
| ✅ COMPLETATA | Implementata, testata, build verificata |
| 📋 APPROVATA | Design approvato, pronta per implementazione |
| 🔄 IN VALUTAZIONE | Idea discussa, design da definire |
| 💡 IDEA FUTURA | Concept emerso, non ancora valutato |
| ⏳ POST-MVP | Rimandata dopo Beta (V1.0+) |
| ❌ ESCLUSA | Decisa per non fare (con motivazione) |

---

## 1. Feature completate (riferimento)

| # | Feature | Versione | Completata |
|---|---------|----------|------------|
| F01 | Core Layer — CRUD movimenti, Dashboard KPI | V0.1 | 2026-06-05 |
| F02 | Speed Layer — Duplica, Rapidi, Preferiti, Suggeriti | V0.2 | 2026-06-05 |
| F03 | SQLite + Conti — persistenza, conti CRUD | V0.3.1 | 2026-06-06 |
| F04 | Categorie Editabili + Confirm Delete | V0.3.2 | 2026-06-06 |
| F05 | Human QA 1500 — 352 scenari, fix CRITICAL | V0.3.3 | 2026-06-06 |
| F06 | Design System STREAM — tema scuro, componenti | V0.4 | 2026-06-06 |
| F07 | Account Icon/Color Refresh | V0.4.1 | 2026-06-06 |
| F08 | Navigation Refactor: Archivio | V0.4.2 | 2026-06-06 |
| F09 | Movement Date — data movimento, SQLite V6 | V0.5.1 | 2026-06-06 |
| F10 | StreamDatePicker — wrapper adattivo | V0.5.2 | 2026-06-06 |
| F11 | TimeFilter Foundation — modello, enum, test | V0.5.3 | 2026-06-06 |
| F14 | Calendario Tab — vista mensile | V0.5.4 | 2026-06-07 |
| F15 | Archivio Filtrato per Data | V0.5.5 | 2026-06-07 |
| F16 | Dashboard Filtrata per Periodo | V0.5.6 | 2026-06-07 |
| — | MovementCard unico (refactor architetturale) | V0.5.6 | 2026-06-07 |
| — | Backup & Restore in Impostazioni | V0.5.6 | 2026-06-08 |
| — | Build release Android fix (file_picker + KGP) | V0.5.6 | 2026-06-08 |
| — | Backup export condivisibile (share sheet) | V0.5.6 | 2026-06-08 |
| F33 | V0.6.1 Raggruppamento Movimenti per Giorno | V0.6.1 | 2026-06-08 |
| F34 | V0.6.0 Click Categoria Dashboard + IntervalPicker | V0.6.0 | 2026-06-08 |
| F23 | V0.6.3 Ricerca Globale Movimenti | V0.6.3 | 2026-06-08 |
| F12 | V0.6.4 UX Movimenti Rapidi/Preferiti — Data Picker | V0.6.4 | 2026-06-08 |
| F37 | V0.6.2 Comparator Centralizzato + Fix Ordinamento | V0.6.2 | 2026-06-08 |
| F38 | V0.6.2 GroupedMovementsList riusabile | V0.6.2 | 2026-06-08 |
| F39 | V0.8.7 Heatmap Settings — soglie/colori configurabili | V0.8.7 | 2026-06-11 |
| F40 | V0.10 Grafici Tab — Analytics Hub | V0.10 | 2026-06-19 |
| F41 | V0.10.1 Chart Readability — barre orizzontali, valori precisi, label leggibili | V0.10.1 | 2026-06-19 |
| F42 | V0.10.1c Donut Charts + Extra Analytics + Scroll UX | V0.10.1c | 2026-06-20 |
| F43 | V0.11 Theme, KPI & Chart Style System | V0.11 | 2026-06-20 |
| F40 | V0.8.8 Subcategories Foundation — subcategory entity, DB v9, UI | V0.8.8 | 2026-06-12 |
| F42 | V0.8.9 Category Conversion & Suggested UX Polish — fix crash categorie, conversione manuale, suggeriti espandibili | V0.8.9 | 2026-06-14 |
| F43 | V0.8.10 Period Views Premium — filtro settimana, card giorno premium, tap giorno seleziona dentro periodo (Week/Month/Year/Range restano in modalità, solo Day cambia), expense breakdown, range premium (blocchi semestrali), chip giorno + reset contestuale per mode, _selectedPeriodDay generalizzato, formatEuro, raggruppamento giorno panel mode, DayHeader Oggi/Ieri/count | V0.8.10 | 2026-06-14 |
| F44 | V0.8.10 Subcategory Hardening — delete sicuro, propagazione colore/icona (condizione `== null || == old`), fix archive/restore async, ListenableBuilder refresh dialog, refresh immediato UI madre→sottocategorie | V0.8.10 | 2026-06-14 |
| F45 | V0.8.10b Universal Movement Actions — ogni `MovementCard` ha popup completo (Modifica/Duplica/Rapido/Preferito/Elimina) in tutte le viste; dashboard sheet reattivo con `ListenableBuilder`; duplica con scelta data utility `showDuplicateDateSheet` | V0.8.10b | 2026-06-13 |
| F46 | Date più chiare — `TimeFilter.customRange.label` con anno, `DayHeader` mese+anno sotto weekday | delta | 2026-06-13 |
| F47 | Dialog propagazione stile categoria — `_CategoryPropagateStyleDialog` con checkbox sottocategorie, `updateCategory` con `propagateToSubcategoryIds` | delta | 2026-06-13 |
| F48 | Beneficiari manuali + save proposal — tab Beneficiari con creazione `BeneficiaryProfile`, merge profili+payee derivati, proposta `No/Salva/Annulla` da form movimento, display metadata su `MovementCard`, backup/restore preservato, iFinance senza dialog | delta | 2026-06-14 |
| F49 | iFinance import transfer pairing hardening — riconoscimento transfer esteso, pairing per `data + importo assoluto`, matching univoco con `Trasferimento da/su`, movimenti normali sbloccati, reimport stesso CSV = `0` nuovi movimenti | delta | 2026-06-14 |
| F50 | Profili separati con isolamento dati reale — registry profili persistito, DB SQLite dedicato per profilo, `MainScaffold` keyed per `activeProfileId`, reset/beneficiari/iFinance isolati, voce Profili visibile solo con callback reale | delta | 2026-06-15 |
| F51 | Movement suggestion chips + currency selector — chip locali per Titolo/Note/Beneficiario, max 5, focus-aware, tap-to-replace, valuta configurabile da Impostazioni con formatter condiviso | delta | 2026-06-18 |
| F52 | Hermes closure stabilization — azioni movimento centralizzate, tap breve modifica, long-press/tre puntini sullo stesso sheet, add/edit movement header compatto + sticky amount, restore conti, delete categoria con riassegnazione sicura | delta | 2026-06-19 |

---

## Priorità prossime

1. V0.9.0 — Beneficiary detail direct edit entry + manual QA closure
2. V0.9.1 — Notes & Tags
3. V0.9.2 — Dashboard recalcolo + tabella editor
4. Subcategories Analytics (Budget/Actual/Scenari)

---

## 2. Feature approvate (📋)

### F12 — V0.6.4 UX Movimenti Rapidi/Preferiti — Data Picker ✅ COMPLETATA

| Campo | Valore |
|-------|--------|
| **Descrizione** | UX avanzata per Rapidi e Preferiti: quando si usa un template, aprire scelta data (Oggi, Ieri, Domani, Scegli data) prima di salvare il movimento |
| **Motivazione** | Attualmente un rapido/preferito crea il movimento con la data corrente. L'utente vuole poter assegnare una data diversa senza passare dalla modifica |
| **Priorità** | Alta |
| **Dipendenze** | Nessuna |
| **Versione candidata** | V0.6.4 |
| **Stato** | ✅ COMPLETATA |

**Sotto-feature:**
1. **Data Picker al salvataggio** — quando si seleziona un rapido/preferito, mostrare schermata di scelta data prima di confermare
2. **Tab rapide** — Oggi, Ieri, Domani (selezione istantanea senza calendario)
3. **Tab "Scegli data"** — date picker a rotella (riusa StreamDatePicker)
4. **Salvataggio** — crea movimento con data selezionata + tutti i campi del template

**Test richiesti:** ~15-20 test (date selection, quick tabs, custom date, backward compatibility)

**Rischio tecnico:** BASSO — solo UI, nessun cambiamento model/database

---

### F13 — V0.6.8 Calendar Heatmap / Category Heatmap

| Campo | Valore |
|-------|--------|
| **Descrizione** | Griglia mensile con intensità colore per giorno basata su spese/entrate/saldo. Filtro per categoria. Filtro per mese/anno/periodo custom. Navigazione mese prec/succ |
| **Motivazione** | La vista calendario testuale non dà colpo d'occhio immediato sulla distribuzione finanziaria nel mese |
| **Priorità** | Alta |
| **Dipendenze** | F09 (date movimenti) ✅, F11 (TimeFilter) ✅, F14 (Calendario tab) ✅ |
| **Versione candidata** | V0.6.8 |
| **Stato** | 💡 IDEA FUTURA |

**Sotto-feature:**
1. Griglia mensile 7 colonne con celle colorate (intensità = spesa totale del giorno)
2. 3 modalità: spese (rosso), entrate (verde), saldo netto (duale)
3. Filtro per singola categoria — heatmap limitata a una categoria specifica
4. Filtro per mese/anno/periodo custom
5. Tap giorno → lista movimenti del giorno (riusa logica V0.5 ✅)
6. Tap rapido → aggiungi movimento con data precompilata
7. Totale mese in basso (entrate, spese, saldo)
8. Navigazione mese prec/succ

**Vincoli:** Nessuna nuova tabella SQLite. Palette STREAM esistente.

**Test richiesti:** ~12-15 test (intensità colore, filtri, navigazione, tap giorno)

**Rischio tecnico:** MEDIO — UI complessa ma dati già disponibili, nessuna migration

---

### F40 — V0.8.8 Subcategories Foundation ✅ COMPLETATA

| Campo | Valore |
|-------|--------|
| **Descrizione** | Nuova entità Subcategory, DB v8→v9, subcategory_id opzionale su movements/quick/favorite, backup/restore compatibile, UI gestione in Categorie, dropdown nel form movimento, fix UX nota rapida e soglie heatmap |
| **Motivazione** | Necessaria gerarchia Categoria→Sottocategoria per futuro Budget/Actual/Scenari e import CSV 1Money |
| **Priorità** | Alta |
| **Dipendenze** | V0.8.7 (nessuna diretta) |
| **Versione candidata** | V0.8.8 |
| **Stato** | ✅ COMPLETATA |

**Sotto-feature:**
1. **Subcategory model** — `id`, `categoryId`, `name`, `archived`, `createdAt`, `updatedAt`; nessun color/iconKey
2. **DB v9** — tabella `subcategories`, colonne `subcategory_id` nullable su movements/quick/favorite, CRUD, migration
3. **Backup/Restore** — export/import subcategories, orfani normalizzati a null, backward compat
4. **UI Categorie** — sezione sottocategorie nel dialog (aggiungi/rinomina/archivia/ripristina)
5. **Form movimento** — dropdown sottocategoria opzionale, reset su cambio categoria
6. **Quick/Favorite** — subcategoryId opzionale + Nota nel form rapido
7. **Heatmap soglie UX** — Done/Fatto con onSubmitted unfocus
8. **Non implementato:** CSV import sottocategorie, conversione categorie flat, Budget/Actual/Scenari

**Test:** 17 test in `test/subcategories_test.dart` + regressioni suite completa (689 test)

**Rischio tecnico:** MEDIO — migration SQLite, backup compatibilità, UI form integrata

---

### F39 — V0.8.7 Heatmap Settings ✅ COMPLETATA

### F42 — V0.8.9 Category Conversion & Suggested UX Polish ✅ COMPLETATA

| Campo | Valore |
|-------|--------|
| **Descrizione** | Fix crash menu categorie, categorie con movimenti modificabili, conversione manuale flat→sottocategoria, suggeriti espandibili/raggruppati, heatmap palette comune |
| **Motivazione** | UX categorie bloccata da crash e impossibilità di modificare categorie con movimenti; conversione manuale necessaria per utenti 1Money |
| **Priorità** | Alta |
| **Dipendenze** | V0.8.8 Subcategories Foundation ✅ |
| **Versione candidata** | V0.8.9 |
| **Stato** | ✅ COMPLETATA |

**Sotto-feature:**
1. **Fix crash** — `_isConvertibleCategory` non crasha più su nomi senza parentesi
2. **Categorie con movimenti modificabili** — nome/colore/icona editabili, tipo bloccato
3. **Conversione manuale** — `Spesa (Alimentari)` → `Spesa` + `Alimentari`
4. **UX conversione** — visibile in 3 layout popup, sheet movimenti, dialog modifica
5. **Suggeriti espandibili/ricercabili/raggruppati** — per categoria
6. **Heatmap palette comune** — `StreamColorPalette.colors`

**Test:** +7 test (711 totali), 0 warning

**Rischio tecnico:** BASSO

---

### F52 — Hermes closure stabilization ✅ COMPLETATA

| Campo | Valore |
|-------|--------|
| **Descrizione** | Chiusura del perimetro Hermes su UX movimenti e safety: azioni centralizzate, add/edit flow rifinito, restore conti, delete categoria con riassegnazione |
| **Versione candidata** | delta |
| **Stato** | ✅ COMPLETATA |

**Sotto-feature:**
1. `MovementCard` con tap breve = modifica
2. Long-press e tre puntini allineati sullo stesso `showMovementActionsSheet`
3. `AddMovementFlow` con header top compatto, `X` e conferma sempre raggiungibili
4. Sticky amount sincronizzato allo stesso controller durante lo scroll
5. `restoreAccount()` esposto nell’UI dei conti archiviati
6. Delete categoria con movimenti: archiviazione o riassegnazione verso categoria valida dello stesso tipo
7. Pulizia `subcategoryId` incompatibili e operazione transazionale lato SQLite

### F41 — V0.9.2 Dashboard recalcolo + tabella editor 🔄 IN VALUTAZIONE

| Campo | Valore |
|-------|--------|
| **Descrizione** | Recalcolo KPI dashboard, tabella editor per modifiche rapide |
| **Priorità** | Media |
| **Versione candidata** | V0.9.2 |
| **Stato** | 🔄 IN VALUTAZIONE |

---

### F23 — V0.6.3 Ricerca Globale Movimenti ✅ COMPLETATA

| Campo | Valore |
|-------|--------|
| **Descrizione** | Campo di ricerca testuale permanente nella lista movimenti di Archivio. Cerca in: titolo, categoria, conto, nota, beneficiario (F35), etichette (F35). Filtro per giorno/mese/anno/periodo custom. Risultati raggruppati per data |
| **Motivazione** | Con centinaia di movimenti, trovarne uno per scorrimento è impossibile. La ricerca testuale è il metodo più rapido |
| **Priorità** | Alta |
| **Dipendenze** | GroupedMovementsList (F38 ✅) riusabile per raggruppamento risultati |
| **Versione candidata** | V0.6.3 |
| **Stato** | ✅ COMPLETATA |

**Sotto-feature:**
1. **Campo di ricerca** — TextField persistente nella testata della lista movimenti
2. **Match parziale** — case-insensitive su titolo, importo (formattato), nome categoria, nome conto, nota
3. **Estensione futura** — beneficiario (F35), etichette (F35) quando disponibili
4. **Filtro periodo** — dropdown/combo per giorno/mese/anno/periodo custom, combinato con testo ricerca
5. **Risultati raggruppati per data** — riusa `GroupedMovementsList` (F38 ✅)
6. **Empty state** — "Nessun risultato per la ricerca"

**Nota:** helper condivisi per logica di match.

**Test richiesti:** ~18-22 test (ricerca per campo, combinazione con filtro periodo, raggruppamento, empty state, performance su 1000+ movimenti)

**Rischio tecnico:** BASSO-MEDIO — solo UI/filtro in-memory, nessun cambiamento model/database

---

### F30 — Inline Form Validation

| Campo | Valore |
|-------|--------|
| **Descrizione** | Migliorare la validazione dei form mostrando errori inline sotto i campi invece di usare solo SnackBar. Esempi: titolo vuoto, importo 0, importo negativo, campi obbligatori mancanti |
| **Motivazione** | Migliora UX, accessibilità e chiarezza. Attualmente la validazione silenziosa confonde l'utente |
| **Priorità** | Media |
| **Dipendenze** | Nessuna |
| **Versione candidata** | V0.4.x / Pre-Beta |
| **Stato** | 📋 APPROVATA |

---

### F35 — V0.6.6 Beneficiario ed Etichette

| Campo | Valore |
|-------|--------|
| **Descrizione** | Aggiungere due nuovi campi opzionali al modello Movement: beneficiario (stringa) e etichette/tag (lista di stringhe). Campi disabilitabili da Impostazioni. Aggiornare model, SQLite, migration, backup/restore, UI e test |
| **Motivazione** | "A chi ho pagato?" e "per cosa?" sono domande naturali. Beneficiario e tag arricchiscono il dato senza rompere la semplicità |
| **Priorità** | Media |
| **Dipendenze** | GroupedMovementsList (F38) ✅ — MovementCard modificabile |
| **Versione candidata** | V0.6.6 |
| **Stato** | 📋 APPROVATA |

**Test richiesti:** ~25-30 test

**Rischio tecnico:** ALTO (migration SQLite, backup compatibilità)

---

### F36 — V0.6.7 Trasferimenti tra Conti

| Campo | Valore |
|-------|--------|
| **Descrizione** | Nuovo tipo movimento "Trasferimento" insieme a Entrata e Uscita. Richiede conto origine, conto destinazione e importo. Aggiorna saldo di entrambi i conti. Backup/restore e test dedicati |
| **Motivazione** | Spostare denaro tra conti (es. CC → Carta) è un'operazione comune |
| **Priorità** | Alta |
| **Dipendenze** | F35 (beneficiario/tag) |
| **Versione candidata** | V0.6.7 |
| **Stato** | 📋 APPROVATA |

**Test richiesti:** ~30-35 test

**Rischio tecnico:** ALTO (saldo duale atomico, migration SQLite, KPI esclusione)

---

## 3. Feature in valutazione (🔄)

### F17 — Category Manual Sorting

| Campo | Valore |
|-------|--------|
| **Priorità** | Media |
| **Dipendenze** | SQLite migration |
| **Versione candidata** | V0.5+ |
| **Stato** | 🔄 IN VALUTAZIONE |

### F18 — Category Summary Ordering

| Campo | Valore |
|-------|--------|
| **Priorità** | Bassa |
| **Dipendenze** | Nessuna |
| **Versione candidata** | V0.5+ |
| **Stato** | 🔄 IN VALUTAZIONE |

### F32 — UI Inspiration Review

| Campo | Valore |
|-------|--------|
| **Priorità** | Bassa-Media |
| **Dipendenze** | Nessuna |
| **Stato** | 🔄 IN VALUTAZIONE |

---

## 4. Future (💡)

### F43 — V0.9.2 Subcategories Analytics (Budget/Actual/Scenari) 💡 IDEA FUTURA

| Campo | Valore |
|-------|--------|
| **Priorità** | Media |
| **Dipendenze** | V0.8.8 Subcategories Foundation ✅, Budget/Actual foundation |
| **Versione candidata** | V0.9.2 |
| **Stato** | 💡 IDEA FUTURA |

**Sotto-feature:**
1. **Treemap toggle** — switch tra vista categorie e vista sottocategorie
2. **Filtri** — filtra per sottocategoria
3. **Budget/Actual** — breakdown per sottocategoria
4. **Scenari** — pianificazione con sottocategorie

---

### F24 — Refactor Grafico Categorie

| Campo | Valore |
|-------|--------|
| **Priorità** | Bassa |
| **Dipendenze** | Nessuna |
| **Versione candidata** | V0.5+ |
| **Stato** | 💡 IDEA FUTURA |

### F31 — Adaptive / Tablet Layout

| Campo | Valore |
|-------|--------|
| **Priorità** | Bassa |
| **Dipendenze** | Beta mobile prima |
| **Versione candidata** | Post-MVP |
| **Stato** | 💡 IDEA FUTURA |

---

## 5. Post-MVP (⏳)

### F25 — V1.0 Beta Pubblica

| Campo | Valore |
|-------|--------|
| **Descrizione** | Distribuzione su App Store e Play Store |
| **Priorità** | Alta |
| **Dipendenze** | Tutte le feature prioritarie |
| **Versione candidata** | V1.0 |
| **Stato** | ⏳ POST-MVP |

### F26 — Backup Locale (✅ completato in V0.5.6)

### F27 — V1.2 Cloud Sync

| Campo | Valore |
|-------|--------|
| **Priorità** | Media |
| **Dipendenze** | F26 (Backup Locale) |
| **Versione candidata** | V1.2 |
| **Stato** | ⏳ POST-MVP |

### F28 — Error Feedback Utente Migliorato

| Campo | Valore |
|-------|--------|
| **Priorità** | Bassa |
| **Versione candidata** | V1.0+ |
| **Stato** | ⏳ POST-MVP |

### F29 — Layout Tablet Adattivo

| Campo | Valore |
|-------|--------|
| **Priorità** | Bassa |
| **Versione candidata** | V1.0+ |
| **Stato** | ⏳ POST-MVP |

---

## 6. Feature escluse (❌)

| # | Feature | Motivazione |
|---|---------|-------------|
| E01 | Autenticazione / Login | L'app è offline-first e privacy-centrica. Esclusa per sempre |
| E02 | Pubblicità | Nessuna pubblicità in-app. Esclusa per sempre |
| E03 | Profili utente multipli | Troppo complesso per MVP |
| E04 | Valute multiple | Non necessario per utenza italiana iniziale |
| E05 | Notifiche push | Richiede server backend |
| E06 | Widget iOS/Android | Posticipato a V1.0+ |
| E07 | Apple Watch / WearOS | Priorità bassissima |
| E08 | Gamification (badge, streak) | Rischia di distrarre dal valore reale |
| E09 | OCR scontrini/fatture | Troppo complesso, costo API alto |

---

## 7. Statistiche backlog

| Metrica | Valore |
|---------|--------|
| **Totale feature censite** | 38 |
| **Feature completate** | 29+ (F01–F11, F12, F14–F16, F23, F33–F34, F37–F40, F42–F47; + MovementCard, Backup, Build fix, Share — **aggiornato F46/F47 al 2026-06-13**) |
| **Feature approvate** | 3 (F30, F35–F36; + F41 V0.9.1 in valutazione) |
| **Feature in valutazione** | 4 (F17–F18, F32, F41) |
| **Feature future** | 4 (F43, F19–F22, F24, F31) |
| **Feature post-MVP** | 3 (F25, F27–F29) |
| **Feature escluse** | 9 (E01–E09) |

---

---

## 8. Conflitti e duplicazioni individuati

| # | Descrizione | Risoluzione |
|---|-------------|-------------|
| C01 | F17 vs F18 — stessa UI categorie ma logica diversa | Tenere distinti |
| C02 | F23 ricerca globale vs test rapidi/preferiti | Usare `Key` stabili e helper condivisi |
| C03 | F15 vs F16 — stesso TimeFilter | TimeFilter già condiviso |
| C04 | Calendar Heatmap come feature vs sotto-feature | Unificata in F13 |
| C05 | F28 vs F30 — stessa finalità | F30 priorità più alta |
| C06 | F29 vs F31 — feature identica tablet | Unificare prima dell'implementazione |

---

## 9. Riferimenti

- `docs/HERMES_ROADMAP.md` — cronologia versioni Hermes
- `docs/NEXT_SESSION.md` — piano prossima sessione
- `docs/STREAM_PRODUCT_ROADMAP.md` — visione prodotto completa
- `docs/STREAM_TECH_NOTES.md` — note tecniche e architettura
- `docs/STREAM_MVP_ROADMAP.md` — criteri MVP e stato
