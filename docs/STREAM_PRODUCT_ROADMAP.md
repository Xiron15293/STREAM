# STREAM — Product Roadmap (Visione completa)

## Concept

STREAM è un'app di budgeting personale minimalista, gratuita, orientata alla privacy.
Niente ads, niente cloud forzato, niente abbonamenti per funzioni base.

## Milestone

| # | Milestone | Stato | Release | Dettaglio |
|---|-----------|-------|---------|-----------|
| 1 | Hermes V0.1 — Core Layer | ✅ COMPLETATO | TBD | CRUD movimenti, Dashboard KPI, validazione input |
| 2 | Hermes V0.2 — Speed Layer | ✅ COMPLETATO | TBD | Duplica, Rapidi, Preferiti, Suggeriti, Note toggle |
| 3 | Hermes V0.3 — Depth Layer | ✅ COMPLETATO | TBD | SQLite, Conti, Modifica, Confirm Delete, Categorie editabili |
| 3.1 | Hermes V0.3.1 — SQLite + Conti | ✅ COMPLETATO | TBD | Persistenza SQLite, conti CRUD |
| 3.2 | Hermes V0.3.2 — Categorie + Delete | ✅ COMPLETATO | TBD | Categorie editabili, confirm delete, dashboard dopo delete |
| 3.3 | Hermes V0.3.3 — Human QA | ✅ COMPLETATO / CLOSED | TBD | 352 scenari QA, 1 bug CRITICAL corretto, 193 test |
| 4 | Hermes V0.4 — Design System | ✅ COMPLETATO | TBD | Tema scuro, palette, componenti, typography
| 4.1 | Hermes V0.4.1 — Account Icon/Color | ✅ COMPLETATO | TBD | Colore/icona conti salvati, ColorPicker funzionante |
| 4.2 | Hermes V0.4.2 — Navigation Refactor | ✅ COMPLETATO | TBD | Archivio: Movimenti, Conti, Categorie in unica tab |
| 4.3 | Hermes V0.4.3 — Quick/Favorite Library UX | 📋 APPROVATA | TBD | Ricerca, filtri categoria, salva da manuale, aggiorna preferito |
| 5 | Hermes V0.5 — Calendario Foundation | ✅ COMPLETATO | V0.5.6 | Date movimenti (✅), TimeFilter (✅), Calendario tab (✅), Archivio filtrato (✅), Dashboard filtrata (✅), MovementCard unico (✅) |
| 5.4 | Calendar Heatmap / Category Heatmap | 📋 APPROVATA | TBD | Griglia mensile con intensità colore, filtro categoria |
| 5.6 | UX Booster — Ricerca Globale, Preferiti, Categorie Frequenti | 💡 PROPOSTO | TBD | Micro-feature post V0.5, basso sforzo, sfruttano MovementCard |
| 6 | Hermes V0.6.1 — Raggruppamento Movimenti per Giorno | ✅ COMPLETATO | TBD | Grouped display, DayHeader, daily riepilogo |
| 6.1 | Hermes V0.6.2 — Ordinamento Centralizzato + Fix | ✅ COMPLETATO | TBD | Comparator unico, updatedAt sort, fix gruppi giorno |
| 6.2 | Hermes V0.6.3 — Ricerca Globale Movimenti | ✅ COMPLETATO | TBD | Ricerca testo + filtro periodo + raggruppamento |
| 6.3 | Hermes V0.6.4 — UX Rapidi/Preferiti Data Picker | ✅ COMPLETATO | TBD | Oggi/Ieri/Domani/Scegli data |
| 6.4 | Hermes V0.6.5 — Reset dati app | 📋 APPROVATA | TBD | Reset controllato, conferma, ripartenza pulita |
| 6.5 | Hermes V0.6.6 — Trasferimenti tra Conti | 📋 APPROVATA | TBD | MovementType.transfer, saldo duale, backup compatibile |
| 6.6 | Hermes V0.6.7 — Import CSV 1Money | 📋 APPROVATA | TBD | Import dopo supporto transfer, molti record "Trasferimento" |
| 6.7 | Hermes V0.8.7 — Heatmap Settings | ✅ COMPLETATO | TBD | Soglie/colori heatmap configurabili, preview, restore defaults, SharedPreferences only |
| 6.8 | Hermes V0.8.8 — Subcategories Foundation | ✅ COMPLETATO | TBD | Subcategory entity, DB v9, subcategory_id nullable, backup/restore, UI gestione, fix UX |
| 6.9 | Hermes V0.8.9 — 1Money Subcategory Import | 📋 APPROVATA | TBD | Parsing Categoria (Sottocategoria) nel CSV 1Money |
| 6.10 | Hermes V0.6.8 — Calendar Heatmap | 💡 IDEA | TBD | Intensità colore, filtro categoria, navigazione |
| 8 | Hermes V0.8 — Import CSV | ✅ COMPLETATO (parziale) | TBD | Import CSV 1Money completato in V0.7.0 |
| 9 | Hermes V0.9 — Scenari | 💡 IDEA | TBD | Proiezioni what-if, pianificazione |
| 10 | Hermes V1.0 — Prima Beta STREAM | ⏳ POST-MVP | TBD | Distribuzione pubblica beta |
| 11 | Hermes V1.1 — Backup Locale | ✅ COMPLETATO | V0.5.6 | Export/import JSON, restore transazionale, share sheet nativo |
| 12 | Hermes V1.2 — Cloud Sync | ⏳ POST-MVP | TBD | Backup premium, multi-dispositivo |
| — | Inline Form Validation (F30) | 📋 APPROVATA | V0.4.x | Errori inline nei form invece di SnackBar |
| — | UI Inspiration Review (F32) | 🔄 IN VALUTAZIONE | Pre-refactor | Revisione pattern esterni UI |
| — | Adaptive / Tablet Layout (F31) | 💡 IDEA FUTURA | V1.0+ | Layout reattivo per tablet/desktop |

## Principi guida

1. **Privacy prima di tutto** — niente account obbligatorio, niente dati che lasciano il dispositivo
2. **Gratuito per funzioni base** — Budget, forecast, conti illimitati gratis
3. **Premium solo per cloud/sync** — abbonamento opzionale per backup e multi-dispositivo
4. **Minimalista** — non aggiungere feature "perché si può". Ogni feature risolve un problema reale
5. **Offline-first** — l'app funziona perfettamente senza internet

## Strategia release

- Versioni Hermes (V0.x) sono milestone interne, non release pubbliche
- Le release pubbliche coincidono con distribuzione su store (V1.0+)
- Beta testing su Android via APK diretto
- Beta testing su iPhone via TestFlight (richiede Apple Developer $99/anno)
- Ogni versione deve passare: flutter analyze ✅ → flutter test ✅ → build ✅ → install device ✅

## Future features

### Categorie ordinabili manualmente (V0.5+)
- Campo `categories.sort_order INTEGER` in SQLite
- Drag per riordinare categorie con `ReorderableListView`
- Ordine persistente, rispettato in form/picker

### Category summary ordering (V0.5+)
Opzioni ordinamento analisi categorie: Ordine manuale, Nome A-Z, Nome Z-A, Spesa crescente, Spesa decrescente, Entrata crescente, Entrata decrescente, Conteggio movimenti crescente, Conteggio movimenti decrescente.
- **Nota**: Ordine manuale = gestione categorie. Ordine automatico = vista analisi. Non confondere.

### MovementCard unico (refactor architetturale) ✅
- **Problema**: 4 classi private duplicate (_MovementTile, _CalendarMovementCard, _MovementCard, _PopupMenu) in 3 schermate, ~376 righe duplicate
- **Soluzione**: `lib/widgets/movement_card.dart` — widget unico, riutilizzabile, con callback per azioni UI. Non scrive su DB.
- **API**: movement, category, account, onTap, onEdit/onDuplicate/onSaveAsFavorite/onDelete, showNotes, showDate
- **Test**: 14 nuovi widget test
- **Prepara**: Import Preview (F21), Heatmap detail-on-tap (F13), supporto ai flussi futuri Reset dati / Trasferimenti / CSV

### Calendar Heatmap / Category Heatmap 💡 IDEA
> Evoluzione visuale di V0.5. Dipende da: date nei movimenti + TimeFilter globale.

- Griglia mensile con intensità colore per giorno basata su spese/entrate/saldo
- Modalità: spese, entrate, saldo netto
- Filtro per singola categoria
- Tap giorno → lista movimenti
- Tap rapido → aggiungi movimento con data precompilata
- Totale mese in basso, navigazione mese prec/succ
- Palette STREAM esistente, nessuna nuova tabella SQLite

### Reset dati app 📋 APPROVATA
- Ripristino controllato dei dati locali per iniziare da zero
- Conferma esplicita prima dell'azione
- Preserva la struttura app, non modifica schema

### Import CSV 1Money 📋 APPROVATA
- Importazione prevista dopo il supporto ai trasferimenti
- Il CSV contiene numerosi movimenti classificati come trasferimento
- Il flusso dovrà riconoscere e normalizzare questi record prima del mapping finale

---

## Backlog completo

Tutte le feature sono censite in:
📋 **`docs/STREAM_FEATURE_BACKLOG.md`**
Il backlog contiene lo stato aggiornato di completate, approvate, in valutazione, future, post-MVP ed escluse.
