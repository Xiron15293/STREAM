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
| 6.2 | Hermes V0.6.3 — Ricerca Globale Movimenti | 📋 APPROVATA | TBD | Ricerca testo + filtro periodo + raggruppamento |
| 6.3 | Hermes V0.6.4 — UX Rapidi/Preferiti Data Picker | 📋 APPROVATA | TBD | Oggi/Ieri/Domani/Scegli data |
| 6.4 | Hermes V0.6.5 — Calendar Heatmap | 📋 APPROVATA | TBD | Intensità colore, filtro categoria, navigazione |
| 6.5 | Hermes V0.6.6 — Beneficiario ed Etichette | 📋 APPROVATA | TBD | Model SQLite migration, UI, backup V2 |
| 6.6 | Hermes V0.6.7 — Trasferimenti tra Conti | 📋 APPROVATA | TBD | MovementType.transfer, saldo duale, backup V3 |
| 7 | Hermes V0.7 — Athena Foundation | 💡 IDEA | TBD | Budget, AI categorization, insight |
| 8 | Hermes V0.8 — Import CSV | 💡 IDEA | TBD | Import da banche, export dati |
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
- **Prepara**: Ricerca Globale (F23), Preferiti (F12), Import Preview (F21), Heatmap detail-on-tap (F13)

### Calendar Heatmap / Category Heatmap 📋 APPROVATA
> Evoluzione visuale di V0.5. Dipende da: date nei movimenti + TimeFilter globale.

- Griglia mensile con intensità colore per giorno basata su spese/entrate/saldo
- Modalità: spese, entrate, saldo netto
- Filtro per singola categoria
- Tap giorno → lista movimenti
- Tap rapido → aggiungi movimento con data precompilata
- Totale mese in basso, navigazione mese prec/succ
- Palette STREAM esistente, nessuna nuova tabella SQLite

---

## Backlog completo

Tutte le feature (33 totali) sono censite in:
📋 **`docs/STREAM_FEATURE_BACKLOG.md`**
Include: 3 approvate, 6 in valutazione, 7 future, 5 post-MVP, 9 escluse con motivazione.
