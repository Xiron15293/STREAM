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

---

## 2. Feature approvate (📋)

### F12 — V0.4.3 Quick/Favorite Movement Library UX

| Campo | Valore |
|-------|--------|
| **Descrizione** | UX avanzata per Rapidi e Preferiti: ricerca, filtri, salva da Manuale, aggiorna preferito esistente |
| **Motivazione** | Con molti template (10+), la lista verticale non scala. L'utente fatica a trovare il template giusto |
| **Priorità** | Alta |
| **Dipendenze** | Nessuna |
| **Versione candidata** | V0.4.3 (prima o parallela a V0.5) |
| **Stato** | 📋 APPROVATA |

**Sotto-feature:**
1. **Ricerca testuale** in Rapidi e Preferiti — match parziale case-insensitive su: nome, categoria, conto, note, importo
2. **Filtro per categoria** — dropdown che limita la lista alla categoria selezionata
3. **Salva da Manuale** — dal tab Manuale, opzione "Salva come Rapido" / "Salva come Preferito"
4. **Aggiorna preferito esistente** — da modifica movimento, opzione per aggiornare un preferito senza duplicarlo
5. **Helper condivisi** — ridurre duplicazione logica tra Rapidi e Preferiti

**Architettura:** `docs/STREAM_TECH_NOTES.md` sezione dedicata + `docs/HERMES_ROADMAP.md` dettaglio completo.

**Test richiesti:** ~15-20 test (ricerca, filtri, salvataggio, aggiornamento, regressione)

---

### F13 — Calendar Heatmap / Category Heatmap

| Campo | Valore |
|-------|--------|
| **Descrizione** | Griglia mensile con intensità colore per giorno basata su spese/entrate/saldo. Filtro per categoria. Tap giorno → movimenti o aggiunta |
| **Motivazione** | La vista calendario testuale non dà colpo d'occhio immediato sulla distribuzione finanziaria nel mese |
| **Priorità** | Media |
| **Dipendenze** | F09 (date movimenti), F11 (TimeFilter foundation) |
| **Versione candidata** | V0.5.4+ (dopo Calendario tab) |
| **Stato** | 📋 APPROVATA |

**Sotto-feature:**
1. Griglia mensile 7 colonne con celle colorate
2. 3 modalità: spese (rosso), entrate (verde), saldo netto (duale)
3. Filtro per singola categoria
4. Tap giorno → lista movimenti del giorno
5. Tap rapido → aggiungi movimento con data precompilata
6. Totale mese in basso
7. Navigazione mese prec/succ

**Vincoli:** Nessuna nuova tabella SQLite. Palette STREAM esistente. Dopo V0.5 Foundation.

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

**Nota:** Si sovrappone parzialmente a F28 (Error Feedback Utente Migliorato, POST-MVP). F30 ha priorità più alta e ambito più specifico (solo form inline). Da unificare.

---

## 3. Feature in valutazione (🔄)

### F14 — V0.5.4 Calendario Tab (vista mensile)

| Campo | Valore |
|-------|--------|
| **Descrizione** | Nuova tab "Calendario" nella bottom nav. Griglia mensile con indicatori di movimenti, navigazione swipe/frecce, tap giorno → lista |
| **Motivazione** | Visione temporale dei movimenti. Base per heatmap e ricorrenze |
| **Priorità** | Alta |
| **Dipendenze** | F09 (date), F11 (TimeFilter) |
| **Versione candidata** | V0.5.4 |
| **Stato** | ✅ COMPLETATO (V0.5.4) |

**Da definire:** UI esatta della cella giorno, navigazione, integrazione con Archivio/Dashboard.

---

### F15 — V0.5.5 Archivio Filtrato per Data

| Campo | Valore |
|-------|--------|
| **Descrizione** | Filtro periodo nella tab Movimenti di Archivio. Usa TimeFilter per mostrare solo movimenti nel range selezionato |
| **Motivazione** | Senza filtro temporale, la lista movimenti cresce indefinitamente e diventa ingestibile |
| **Priorità** | Alta |
| **Dipendenze** | F11 (TimeFilter) |
| **Versione candidata** | V0.5.5 |
| **Stato** | ✅ COMPLETATO (V0.5.5) |

**Realizzato**: TimeFilterBar in Archivio → filtra movimenti per periodo con `filterByTime()`. Navigazione Giorno/Mese/Anno/Periodo. Stato vuoto: "Nessun movimento nel periodo selezionato".

---

### F16 — V0.5.6 Dashboard Filtrata per Periodo

| Campo | Valore |
|-------|--------|
| **Descrizione** | KPI Dashboard (entrate, uscite, saldo) calcolati su periodo selezionato via TimeFilter. Hero card patrimonio filtrata |
| **Motivazione** | La Dashboard mostra solo dati totali. L'utente vuole vedere "quanto ho speso questo mese" |
| **Priorità** | Alta |
| **Dipendenze** | F11 (TimeFilter) |
| **Versione candidata** | V0.5.6 |
| **Stato** | ✅ COMPLETATO (V0.5.6) |

**Realizzato**: TimeFilterBar in Dashboard → KPI filtrati per periodo (Entrate, Spese, Saldo, Movimenti). Patrimonio globale non filtrato. Ultime transazioni filtrate. KPI grid 2×2.

---

### F17 — Category Manual Sorting

| Campo | Valore |
|-------|--------|
| **Descrizione** | Campo `sort_order` SQLite su categories. Drag per riordinare con `ReorderableListView` in schermata categorie |
| **Motivazione** | L'ordine alfabetico non è significativo. L'utente vuole le categorie più usate in alto |
| **Priorità** | Media |
| **Dipendenze** | SQLite migration (nuova colonna) |
| **Versione candidata** | V0.5+ |
| **Stato** | 🔄 IN VALUTAZIONE |

**Rischio:** Conflitto con Category Summary Ordering (F18). Non implementare entrambi senza progettazione unificata.

---

### F18 — Category Summary Ordering

| Campo | Valore |
|-------|--------|
| **Descrizione** | Opzioni ordinamento analisi categorie: Nome A-Z/Z-A, Spesa crescente/decrescente, Entrata crescente/decrescente, Conteggio movimenti |
| **Motivazione** | L'analisi per categoria richiede ordinamenti diversi in contesti diversi |
| **Priorità** | Bassa |
| **Dipendenze** | Nessuna (solo UI) |
| **Versione candidata** | V0.5+ |
| **Stato** | 🔄 IN VALUTAZIONE |

**Nota:** Distinto da F17. Ordine manuale = gestione. Ordine automatico = vista analisi.

---

### F32 — UI Inspiration Review

| Campo | Valore |
|-------|--------|
| **Descrizione** | Revisionare la cartella `/Users/mattiasironi1/Documents/FLOW/UI inspiration/` per estrarre pattern utili a Dashboard, Budget, Fondi, Scenario, Categorie e Calendario |
| **Motivazione** | I documenti STREAM citano questa cartella come fonte di ispirazione. Potrebbero emergere pattern non ancora catturati nel backlog |
| **Priorità** | Bassa-Media |
| **Dipendenze** | Nessuna (ricerca, non implementazione) |
| **Versione candidata** | Prima dei refactor grafici avanzati |
| **Stato** | 🔄 IN VALUTAZIONE |

**Vincolo:** Non copiare UI esterne 1:1. Usare solo come ispirazione concettuale.

---

## 4. Future (💡)

### F19 — V0.6 Ricorrenze

| Campo | Valore |
|-------|--------|
| **Descrizione** | Movimenti automatici ricorrenti: settimanali, mensili, annuali. Creazione automatica alla data prevista |
| **Motivazione** | Canone affitto, stipendio, abbonamenti — movimenti che si ripetono sempre uguali |
| **Priorità** | Media |
| **Dipendenze** | F09 (date), F11 (TimeFilter), F14 (Calendario tab) |
| **Versione candidata** | V0.6 |
| **Stato** | 💡 IDEA FUTURA |

**Da progettare:** Modello ricorrenza, generazione automatica, notifiche, gestione eccezioni.

---

### F20 — V0.7 Athena Foundation (Budget, AI, Insight)

| Campo | Valore |
|-------|--------|
| **Descrizione** | Budget mensili per categoria. Actual vs Budget. Delta. AI categorization automatica. Insight intelligenti |
| **Motivazione** | L'utente vuole sapere se sta spendendo troppo. Assegnazione manuale categoria è faticosa |
| **Priorità** | Media |
| **Dipendenze** | F09 (date), F11 (TimeFilter), F16 (Dashboard filtrata) |
| **Versione candidata** | V0.7 |
| **Stato** | 💡 IDEA FUTURA |

**Sotto-feature candidate:**
1. Budget — impostazione budget mensile per categoria
2. Actual — spesa reale nel periodo (riusa TimeFilter)
3. Delta — differenza budget vs actual
4. KPI mensili — risparmio, tasso di risparmio, categoria top spesa
5. AI categorization — suggerimento automatico categoria basato su titolo e storico
6. Insight automatici — "Questo mese hai speso 30% in più al ristorante"

---

### F21 — V0.8 Import CSV

| Campo | Valore |
|-------|--------|
| **Descrizione** | Import guidato movimenti da CSV home banking. Mapping colonne, fingerprint, deduplica intelligente |
| **Motivazione** | Inserire decine/centinaia di movimenti a mano è improponibile all'onboarding |
| **Priorità** | Media |
| **Dipendenze** | F09 (date) |
| **Versione candidata** | V0.8 |
| **Stato** | 💡 IDEA FUTURA |

**Sotto-feature candidate:**
1. Import guidato — seleziona file, preview, conferma
2. Mapping colonne — l'utente associa colonne CSV a campi STREAM
3. Fingerprint — hash (conto + data + importo + titolo) per identificare univocamente
4. ImportedFingerprintLedger — registro dei fingerprint importati
5. Deduplica intelligente — stesso fingerprint → skip (anche su import multipli)
6. Export dati — esporta movimenti in CSV

---

### F22 — V0.9 Scenari

| Campo | Valore |
|-------|--------|
| **Descrizione** | Proiezioni what-if: "Se risparmio 200€ al mese per 12 mesi, quanto ho?". Simulazioni e forecast semplici |
| **Motivazione** | L'utente vuole pianificare il futuro, non solo registrare il passato |
| **Priorità** | Bassa |
| **Dipendenze** | F20 (Athena — per dati budget), F11 (TimeFilter) |
| **Versione candidata** | V0.9 |
| **Stato** | 💡 IDEA FUTURA |

**Da progettare:** UI scenari, motore di calcolo, salvataggio scenari.

---

### F23 — Ricerca Globale Movimenti

| Campo | Valore |
|-------|--------|
| **Descrizione** | Campo di ricerca testuale nella lista movimenti (e/o Archivio). Filtra per titolo, categoria, conto, note, importo |
| **Motivazione** | Con centinaia di movimenti, trovarne uno per scorrimento è impossibile |
| **Priorità** | Media |
| **Dipendenze** | Nessuna (solo UI/filtro in-memory) |
| **Versione candidata** | V0.5+ |
| **Stato** | 💡 IDEA FUTURA |

**Nota:** Più semplice di F12 (ricerca solo in Rapidi/Preferiti). Può essere implementata prima.

---

### F24 — Refactor Grafico Categorie

| Campo | Valore |
|-------|--------|
| **Descrizione** | Visualizzazione più visuale e moderna delle categorie: icone grandi, griglia anziché lista, colori prominenti |
| **Motivazione** | UI categorie attuale è funzionale ma poco ispirata |
| **Priorità** | Bassa |
| **Dipendenze** | Nessuna (solo UI) |
| **Versione candidata** | V0.5+ |
| **Stato** | 💡 IDEA FUTURA |

### F31 — Adaptive / Tablet Layout

| Campo | Valore |
|-------|--------|
| **Descrizione** | Adattare layout a tablet, schermi grandi e desktop. Esempi: layout a due colonne, sidebar su tablet, form più larghi, dashboard più spaziosa |
| **Motivazione** | STREAM è Flutter multipiattaforma e potrà girare anche su tablet/desktop |
| **Priorità** | Bassa |
| **Dipendenze** | Beta mobile prima |
| **Versione candidata** | Post-MVP / Tablet phase |
| **Stato** | 💡 IDEA FUTURA |

**Nota:** Si sovrappone a F29 (Layout Tablet Adattivo, POST-MVP). Da unificare prima dell'implementazione.

---

## 5. Post-MVP (⏳)

### F25 — V1.0 Beta Pubblica

| Campo | Valore |
|-------|--------|
| **Descrizione** | Distribuzione su App Store e Play Store. Pagina prodotto, screenshot, descrizione. Beta testing con utenti reali |
| **Motivazione** | Raccogliere feedback, validare PMF, iniziare crescita utenti |
| **Priorità** | Alta (per tempistiche) |
| **Dipendenze** | Tutte le feature prioritarie |
| **Versione candidata** | V1.0 |
| **Stato** | ⏳ POST-MVP |

> **⚠️ QA/Build — Beta Build Checklist**
> Le build beta distribuite devono essere **release build**, non debug.
> Evitare APK/IPA debug con banner "DEBUG" per test esterni.
> ```
> flutter build apk --release
> flutter build ios --release
> ```
> Il banner debug è accettabile solo per sviluppo locale/test su device proprio.
> Non è una feature roadmap, ma un requisito QA per distribuzione beta.

---

### F26 — Backup Locale

| Campo | Valore |
|-------|--------|
| **Descrizione** | Export/import completo JSON (accounts, categories, movements, quickMovements, favoriteMovements, settings). Restore transazionale con rollback SQLite. Share sheet nativo per esportazione file |
| **Motivazione** | L'utente può salvare e ripristinare i dati su/dispositivo o copiarli fuori dall'app |
| **Priorità** | Alta |
| **Dipendenze** | F09 (date) |
| **Versione** | V0.5.6 |
| **Stato** | ✅ COMPLETATO (V0.5.6) |

**Dettaglio tecnico**:
- File: `lib/services/backup_service.dart`, `lib/models/backup_data.dart`, `lib/screens/backup_screen.dart`
- `BackupService.exportToJson()` → JSON con tutte le entità
- Salvataggio interno: `getDatabasesPath()/backups/backup_YYYY_MM_DD_HH_mm.json`
- Condivisione via `share_plus ^12.0.2` — SnackBar con "Condividi" + icona share in lista backup
- Restore transazionale: `sqlite.transaction()` → DELETE + INSERT
- Pre-restore backup automatico prima del restore
- Import via `FilePicker.pickFiles(allowedExtensions: ['json'])`
- Validazione: JSON, version (1–1), campi obbligatori
- Orfani account/categoryId gestiti con fallback a default

---

### F27 — V1.2 Cloud Sync

| Campo | Valore |
|-------|--------|
| **Descrizione** | Backup premium su cloud. Sincronizzazione multi-dispositivo. Criptato end-to-end |
| **Motivazione** | Utenti con più dispositivi vogliono dati sempre aggiornati. Fonte di revenue (abbonamento opzionale) |
| **Priorità** | Media |
| **Dipendenze** | F26 (Backup Locale) |
| **Versione candidata** | V1.2 |
| **Stato** | ⏳ POST-MVP |

**Modello di business:** Gratuito per funzioni base. Premium (abbonamento) per backup cloud e multi-dispositivo.

---

### F28 — Error Feedback Utente Migliorato

| Campo | Valore |
|-------|--------|
| **Descrizione** | Validazione visiva in tempo reale nei form. Messaggi di errore contestuali. SnackBar per operazioni riuscite |
| **Motivazione** | La validazione attuale è silenziosa in alcuni casi. L'utente non sa perché un'azione fallisce |
| **Priorità** | Bassa |
| **Dipendenze** | Nessuna |
| **Versione candidata** | V1.0+ |
| **Stato** | ⏳ POST-MVP |

---

### F29 — Layout Tablet Adattivo

| Campo | Valore |
|-------|--------|
| **Descrizione** | Adaptive layout per tablet: split view, navigazione laterale, griglie più ampie |
| **Motivazione** | Su tablet l'app appare vuota e sproporzionata |
| **Priorità** | Bassa |
| **Dipendenze** | Nessuna (solo UI) |
| **Versione candidata** | V1.0+ |
| **Stato** | ⏳ POST-MVP |

---

## 6. Feature escluse (❌)

| # | Feature | Motivazione |
|---|---------|-------------|
| E01 | Autenticazione / Login | L'app è offline-first e privacy-centrica. Login obbligherebbe account. Esclusa per sempre |
| E02 | Pubblicità | Nessuna pubblicità in-app. Modello premium per cloud sync. Esclusa per sempre |
| E03 | Profili utente multipli | Troppo complesso per MVP. Ogni dispositivo è un profilo. Cloud sync potrebbe abilitarlo in futuro |
| E04 | Valute multiple | Non necessario per utenza italiana iniziale. Da rivalutare solo dopo Beta (V1.0+) |
| E05 | Notifiche push | Richiede server backend. Troppo complesso pre-Beta. Da rivalutare solo dopo cloud sync |
| E06 | Widget iOS/Android | Home screen widget potrebbe essere bello, ma non necessario. Posticipato a V1.0+ |
| E07 | Apple Watch / WearOS | Niche. Priorità bassissima. Non prima di V2.0 |
| E08 | Gamification (badge, streak) | Rischia di distrarre dal valore reale. Esclusa salvo richieste esplicite beta |
| E09 | OCR scontrini/fatture | Troppo complesso, costo API alto, accuratezza variabile. Non pianificata |

---

## 7. Statistiche backlog

| Metrica | Valore |
|---------|--------|
| **Totale feature censite** | 32 |
| **Feature completate** | 15+ (F01–F11, F14–F16, F26; + MovementCard, Backup & Restore, Build fix, Share sheet) |
| **Feature approvate** | 3 (F12–F13, F30) |
| **Feature in valutazione** | 3 (F17–F18, F32) |
| **Feature future** | 6 (F19–F24 restano) |
| **Feature post-MVP** | 4 (F25, F27–F29) |
| **Feature escluse** | 9 (E01–E09) |
| **Refactor architetturale** | 1 (MovementCard unico ✅, non è feature ma prepara F12, F13, F21, F23) |

---

## 8. Priorità consigliate prima della Beta

Basate sul criterio: **massimo impatto utente per minimo sforzo tecnico.**

### Novità architetturale: MovementCard unico
Il refactor MovementCard (`lib/widgets/movement_card.dart`) ha eliminato 4 classi duplicate e prepara tecnicamente le feature che richiedono renderizzazione movimenti:

| Feature | Dipendenza da MovementCard |
|---------|---------------------------|
| F12 — Quick/Favorite UX | Mostrare template rapidi/preferiti come card |
| F13 — Calendar Heatmap | Detail-on-tap del giorno |
| F21 — Import CSV Preview | Preview movimenti importati |
| F23 — Ricerca Globale | Risultati ricerca come card |

### 🥇 Priorità Alta (prossima sessione — V0.6+)

| Ordine | Feature | Impatto | Sforzo | Note |
|--------|---------|---------|--------|------|
| 1 | F23 — Ricerca Globale Movimenti | Alto | Basso | MovementCard pronto ✅ |
| 2 | F12 — V0.4.3 UX Rapidi/Preferiti | Alto | Basso-Medio | MovementCard pronto ✅ |
| 3 | F13 — Calendar Heatmap | Medio | Basso | V0.5 Foundation ✅ |
| 4 | F30 — Inline Form Validation | Medio | Basso | |
| 5 | F17 — Category Sorting | Medio | Basso | |

### 🥈 Priorità Media (V0.6–V0.7)

| Ordine | Feature | Impatto | Sforzo |
|--------|---------|---------|--------|
| 5 | F13 — Calendar Heatmap | Medio | Basso (dipende da F14 ✅) |
| 6 | F23 — Ricerca Globale | Alto | Basso |
| 7 | F20 — Athena Foundation | Alto | Alto |

### 🥉 Priorità Bassa (V0.8–V1.0)

| Ordine | Feature | Impatto | Sforzo |
|--------|---------|---------|--------|
| 9 | F21 — Import CSV | Alto | Alto |
| 10 | F22 — Scenari | Medio | Alto |
| 11 | F24 — Refactor Grafico Categorie | Basso | Basso |
| 12 | F28 — Error Feedback | Medio | Basso |
| 13 | F29 / F31 — Layout Tablet | Basso | Alto |

---

## 9. Dipendenze grafico (semplificato)

```
V0.4.2 ✅
  ├── V0.4.3 (F12) — nessuna dipendenza ✓
  ├── V0.5 (F09–F11, F14–F16) ✅ COMPLETATO
  │     ├── F09 ✅ → F10 ✅ → F11 ✅ → F14 ✅
  │     ├── F15 ✅ (Archivio, riusa TimeFilter)
  │     └── F16 ✅ (Dashboard, riusa TimeFilter)
  ├── F13 (Heatmap) ← F14 + F11
  ├── F19 (Ricorrenze) ← F14
  ├── F20 (Athena) ← F16
  ├── F21 (CSV) ← F09
  └── F22 (Scenari) ← F20 + F11
```

---

## 10. Conflitti e duplicazioni individuati

| # | Descrizione | Risoluzione |
|---|-------------|-------------|
| C01 | F17 (Manual Sorting) vs F18 (Summary Ordering) — stessa UI categorie ma logica diversa | Tenere distinti. Manual sorting nella schermata gestione categorie. Summary ordering nella vista analisi. Documentare che non confliggono |
| C02 | F12.1 (Ricerca Rapidi/Preferiti) vs F23 (Ricerca Globale) — motore di ricerca simile in contesti diversi | Condividere helper di ricerca/filtro. F23 è più generale (movimenti reali), F12 è su template. Non duplicare logica |
| C03 | F15 (Archivio Filtrato) vs F16 (Dashboard Filtrata) — stesso TimeFilter, UI diversa | TimeFilter (F11) già condiviso. Le UI sono separate e indipendenti. Nessun vero conflitto |
| C04 | V0.4.3 Calendar Heatmap menzionata sia come feature a sé stante sia come sotto-feature di V0.5 | Unificata in F13. È un'evoluzione visuale di V0.5 Calendario, non una feature parallela |
| C05 | F28 (Error Feedback, POST-MVP) vs F30 (Inline Form Validation, APPROVATA) — stessa finalità ma priorità/ambito diversi | F30 ha priorità più alta e ambito specifico (solo form inline). Unificare: promuovere F30 a feature primaria, deprecare o assorbire F28 |
| C06 | F29 (Layout Tablet Adattivo, POST-MVP) vs F31 (Adaptive / Tablet Layout, FUTURA) — feature identica | Unificare prima dell'implementazione. Tenere F29 come entry principale (POST-MVP). F31 è segnaposto per futura ri-prioritizzazione |

---

## 11. Riferimenti

- `docs/HERMES_ROADMAP.md` — cronologia versioni Hermes
- `docs/NEXT_SESSION.md` — piano prossima sessione
- `docs/STREAM_PRODUCT_ROADMAP.md` — visione prodotto completa
- `docs/STREAM_TECH_NOTES.md` — note tecniche e architettura
- `docs/STREAM_MVP_ROADMAP.md` — criteri MVP e stato
