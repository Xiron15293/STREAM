# HERMES V0.2 — Speed Layer

## 1. Obiettivo

Ridurre drasticamente il tempo necessario per inserire movimenti frequenti nell'app STREAM.

## 2. Perché esiste

Hermes V0.1 richiedeva la compilazione manuale di tutti i campi (titolo, importo, tipo, categoria, nota) per ogni movimento. Per movimenti ripetitivi come Caffè (1.50€ al giorno) o Stipendio (2500€ al mese), l'attrito era troppo alto.

V0.2 introduce tre modalità di inserimento (Manuale, Rapidi, Preferiti) e la possibilità di duplicare movimenti esistenti, coprendo:

- **Duplica**: 2 tap per movimenti occasionali simili a uno già inserito
- **Rapidi**: 3 tap per movimenti frequenti pre-configurati
- **Preferiti**: 3 tap per template salvati manualmente
- **Suggeriti**: proposta automatica dopo 5+ movimenti simili

## 3. Problema utente risolto

| Problema | Soluzione V0.2 |
|----------|----------------|
| "Devo inserire il caffè tutti i giorni e ogni volta è lungo" | Movimento Rapido "Caffè" — 3 tap e via |
| "Ho già un movimento simile, devo riscriverlo" | Duplica — 2 tap dal menu contestuale |
| "Vorrei salvare un modello per la spesa settimanale" | Salva come Preferito — dal menu contestuale |
| "L'app potrebbe imparare cosa faccio spesso" | Suggeriti dopo 5+ movimenti simili |

## 4. Feature incluse

### 4.1 Duplica Movimento

- Azione disponibile dal menu contestuale (⋮) nella lista movimenti
- Copia: titolo, importo, categoria, tipo, nota
- Data impostata a `DateTime.now()`
- Nuovo ID univoco
- **Scelta implementativa**: duplicazione immediata (nessun form precompilato) — meno bug, più veloce

### 4.2 Movimenti Rapidi

- Sezione nella mini-tab "Rapidi" del MovementPicker
- Ogni rapido contiene: titolo, importo, tipo (entrata/uscita), categoria, nota (opzionale)
- CRUD completo: crea, modifica, elimina
- 4 default: Caffè (1.50€, Svago), Benzina (50€, Auto), Spesa (80€, Spesa), Stipendio (2500€, Stipendio)
- Uso: tocca ▶ per creare movimento reale con data corrente

### 4.3 Movimenti Preferiti

- Sezione nella mini-tab "Preferiti" del MovementPicker
- Stessa struttura di un rapido (titolo, importo, tipo, categoria, nota)
- Si possono creare ex-novo o salvare da un movimento esistente
- CRUD completo: crea, modifica, elimina
- Distinti visivamente dai Suggeriti

### 4.4 Suggeriti automatici

- Appaiono nella sezione "Suggeriti" sotto i Preferiti
- Soglia: ≥5 movimenti con stessa (categoria + titolo normalizzato + tipo)
- Importo suggerito = ultimo importo inserito (non media)
- Data sempre `DateTime.now()` quando usato
- **Limitazione**: match case-insensitive su titolo, non copre varianti parziali

## 5. Flusso UX

### Flusso principale

```
Lista Movimenti → tap + → MovementPicker
                           ├── [Manuale] (default) → form classico → Salva
                           ├── [Rapidi] → lista quick → ▶ → movimento creato
                           └── [Preferiti] → lista preferiti + suggeriti → ▶ → movimento creato
```

### Flusso Duplica

```
Lista Movimenti → ⋮ → Duplica → movimento duplicato (SnackBar conferma)
```

### Flusso Salva come Preferito

```
Lista Movimenti → ⋮ → Salva preferito → preferito salvato (SnackBar conferma)
```

## 6. Criteri di accettazione

| # | Criterio | Stato |
|---|----------|-------|
| 1 | Duplicando un movimento, la lista mostra un nuovo movimento separato | ✅ |
| 2 | Duplicando un movimento, la Dashboard aggiorna saldo/totali | ✅ |
| 3 | Toccare un Movimento Rapido crea un movimento reale con data corrente | ✅ |
| 4 | Dashboard aggiornata dopo movimento rapido | ✅ |
| 5 | Usando un Preferito, il movimento creato è nuovo, data corrente, lista aggiornata | ✅ |
| 6 | Dashboard aggiornata dopo preferito | ✅ |
| 7 | Dopo ≥5 movimenti simili, il sistema propone un suggerito | ✅ |
| 8 | Tutte le modalità passano dallo stesso metodo di creazione movimento | ✅ |
| 9 | Parsing virgola/punto ancora funzionante | ✅ |
| 10 | Lista mostra movimenti creati da modalità diverse | ✅ |

## 7. Rischi

| # | Rischio | Probabilità | Mitigazione |
|---|---------|-------------|-------------|
| 1 | Rapidi/Preferiti persi alla chiusura (in-memory) | Certa | Documentato, priorità persistenza post-V0.2 |
| 2 | Soglia 5 suggeriti troppo alta/bassa | Media | Regolabile dopo feedback, parametro hardcoded oggi |
| 3 | Match esatto titolo per suggeriti ("caffè" ≠ "Caffe") | Bassa | Normalizzazione lower-case, ma non copre typo |
| 4 | Troppe feature senza utenti reali | Media | Roadmap condizionale: fermarsi se nessun feedback |

## 8. Cosa NON include

- Budget / Actual
- Scenari / Forecast
- Profili / Nirvana
- Import CSV
- Cloud / Login / Abbonamenti
- Categorie personalizzabili
- Ricerca / filtri
- Persistenza SQLite

## 9. Test richiesti

Tutti superati (vedi `HERMES_QA_REPORT.md` sezione V0.2):

- Duplica movimento (db + UI)
- Movimento rapido crea movimento reale
- Dashboard aggiornata dopo rapido
- Preferito crea movimento reale
- Salva movimento come preferito
- Dashboard aggiornata dopo preferito
- Suggerito dopo 5+ movimenti simili
- Nessun suggerito con <5 movimenti
- Suggeriti multipli con gruppi distinti
- Parsing virgola invariato
- Lista mostra movimenti da modalità diverse
- Rapido personalizzato via UI
- Rapidi iniziali presenti

## 10. Hermes V0.2.x — Note visibili nella lista movimenti

**Feature**: permettere all'utente di vedere le note dei movimenti direttamente nella lista, con toggle ON/OFF persistente.

### Comportamento

| Toggle | Movimento con nota | Movimento senza nota |
|--------|-------------------|---------------------|
| OFF (default) | Lista invariata | Lista invariata |
| ON | Nota sotto categoria/data (max 2 righe, ellipsis) | Lista invariata (nessuna riga extra) |

### UX adottata

- Impostazione accessibile dall'icona ⚙️ nell'AppBar della lista Movimenti
- Bottom sheet con SwitchListTile "Mostra note nei movimenti"
- Nota visualizzata come terza riga sotto il subtitle (categoria • data)
- Max 2 righe, overflow con ellipsis — nessun layout rotto
- Colore grigio più scuro (`Colors.grey[600]`), font 12 — distinta dal titolo

### Persistenza

- Salvata in `SharedPreferences` (chiave `show_notes`)
- Indipendente dal database principali (movimenti, rapidi, preferiti)
- Non richiede migrazioni né build_runner
- Default: `false` (OFF) — Hermes rimane pulito per nuovi utenti

### Test aggiunti (test 66-73 in qa_movements_test.dart)

| # | Test | Stato |
|---|------|-------|
| 66 | Toggle OFF nasconde note | ✅ |
| 67 | Toggle ON mostra note | ✅ |
| 68 | Movimento senza nota non mostra riga extra | ✅ |
| 69 | Nota corta visibile con toggle ON | ✅ |
| 70 | Nota lunga con ellipsis (overflow gestito) | ✅ |
| 71 | Persistenza impostazione showNotes | ✅ |
| 72 | Dashboard non influenzata da showNotes | ✅ |
| 73 | Nessun overflow UI con note (layout intatto) | ✅ |

### File modificati

- `pubspec.yaml` — aggiunto `shared_preferences: ^2.5.5`
- `lib/screens/movements_screen.dart` — convertito in StatefulWidget, showNotes state, settings icon, note rendering
- `test/qa_movements_test.dart` — 8 nuovi test (66-73)
- `test/widget_test.dart` — mock SharedPreferences
- `lib/data/preferences_service.dart` — **CREATO**

## 11. Stato finale

**READY FOR HERMES V0.2 QA** — Vedi `HERMES_QA_REPORT.md` per dettagli completi.

Prossimo passo consigliato: persistenza SQLite prima della distribuzione beta.
