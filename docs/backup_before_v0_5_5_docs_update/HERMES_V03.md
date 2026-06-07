# HERMES V0.3 — Depth Layer (STORICO)

> **Documento storico.** Hermes V0.3 è stato completato e chiuso in V0.3.3. Questo documento è mantenuto solo per riferimento.
> Per lo stato attuale, vedere `docs/HERMES_ROADMAP.md`.

## 1. Obiettivo

Portare STREAM da prototipo dimostrativo a vera app: persistenza su disco, conti reali, categorie personalizzabili, modifica ed eliminazione sicura.

## 2. Perché esiste

Hermes V0.1-V0.2 usavano esclusivamente memoria volatile. Tutti i dati — movimenti, rapidi, preferiti — sparivano alla chiusura dell'app. V0.3 risolve il problema più grande dell'app, aggiunge conti (requiresiti base per fare budgeting), e completa il CRUD con modifica, delete confermata e categorie editabili.

## 3. Feature incluse

### 3.1 SQLite (V0.3.1 ✅)

| Feature | Dettaglio | Stato |
|---------|-----------|-------|
| Motore database | Drift (SQLite) | ✅ |
| `AppDatabase` | Classe singleton con cache in-memory + SQLite come source of truth | ✅ |
| Caricamento iniziale | Tutti i record letti da SQLite all'avvio | ✅ |
| Salvataggio | CRUD scrive sempre su SQLite + aggiorna cache | ✅ |
| Rapidi e Preferiti | Persistono anch'essi su SQLite | ✅ |
| Architettura | `SQLiteService` si occupa delle query raw, `AppDatabase` coordina | ✅ |

### 3.2 Conti (V0.3.1 ✅)

| Feature | Dettaglio | Stato |
|---------|-----------|-------|
| Modello Conto | `Conto` con id, nome, tipo (default/extra), saldoIniziale | ✅ |
| CRUD Conti | Aggiungi, modifica, elimina | ✅ |
| Conto di default ("Principale") | Creato automaticamente, non eliminabile | ✅ |
| Assegnazione | Ogni movimento ha un `contoId` | ✅ |
| Dashboard KPI | Mostra `totalIncome`, `totalExpenses`, `balance` | ✅ |
| Saldo per conto | `balanceByAccount(contoId)`, `totalAccountsBalance` | ✅ |
| Aggiornamento | Modifica/delete movimento aggiorna i saldi | ✅ |

### 3.3 Modifica Movimento (V0.3.1 ✅)

| Feature | Dettaglio | Stato |
|---------|-----------|-------|
| Tap su movimento | Apre MovementForm precompilato | ✅ |
| Campi editabili | Titolo, importo, categoria, tipo, conto, nota | ✅ |
| Salva modifiche | `updateMovement()` → SQLite + cache | ✅ |
| Dashboard aggiornata | Dopo modifica, ListenableBuilder ricostruisce | ✅ |

### 3.4 Confirm Delete (V0.3.2 ✅)

| Feature | Dettaglio | Stato |
|---------|-----------|-------|
| Dialog conferma | `AlertDialog` con "Elimina"/"Annulla" prima di eliminare | ✅ |
| Annulla | Chiude dialog senza eliminare, nessun cambiamento | ✅ |
| Test | 2 test dedicati (conferma + annulla UI) | ✅ |

### 3.5 Categorie Editabili (V0.3.2 ✅)

| Feature | Dettaglio | Stato |
|---------|-----------|-------|
| CRUD Categorie | Aggiungi, modifica nome/colore/tipo, elimina | ✅ |
| Archivia/Ripristina | Archivia senza perdere dati, ripristina | ✅ |
| Protezione | Eliminazione bloccata se categoria ha movimenti | ✅ |
| Test | 17 test dedicati (in-memory + SQLite) | ✅ |

### 3.6 Dashboard dopo Delete (V0.3.2 ✅)

| Feature | Dettaglio | Stato |
|---------|-----------|-------|
| KPI dopo delete | totalIncome, totalExpenses, balance aggiornati | ✅ (15 test in-memory) |
| SQLite dopo delete | KPI persistono dopo reload | ✅ (3 test SQLite) |
| UI update dopo delete | Widget test confermano aggiornamento UI | ✅ (3 test UI) |
| 21 test totali | Copre entrate, uscite, conti, annulla, doppio delete | ✅ |

## 4. Architettura SQLite

```
Utente → AppDatabase
            ├── Cache in-memory (List<Movement>, List<QuickMovement>, ...)
            └── SQLiteService
                    ├── insert()
                    ├── update()
                    ├── delete()
                    └── select()

AppDatabase.notifyListeners() → rebuild UI
```

- `SQLiteService` gestisce le query raw SQL
- `AppDatabase` espone metodi CRUD, mantiene cache, notifica listeners
- Drift non usato come ORM (query raw per controllo totale), ma la dipendenza è in `pubspec.yaml`
- `SharedPreferences` per `showNotes` toggle (non SQLite, per isolamento)

## 5. Scelte tecniche

| Decisione | Scelta | Motivazione |
|-----------|--------|-------------|
| ORM vs Raw SQL | Raw SQL con `sqflite` package | Controllo totale, nessun codegen, debugging trasparente |
| Cache + DB | Doppio layer (cache in-memory + SQLite) | Performance lettura, UI reattiva, dati persistenti |
| `drift` in pubspec | Dipendenza presente ma non usata | Pronta per futuro, nessun conflitto con sqflite |
| Modello Conto | Classe separata `Conto` con `saldoIniziale` | Permette calcolo saldo cumulativo corretto |
| `contoId` nullable | `null` = conto predefinito | Retrocompatibile con movimenti V0.1-V0.2 |
| `uuid` per ID | UUID v4 invece di auto-increment | Merge futuro, sync cloud, no collisioni |
| `ensureVisible` | Aggiunto nei test helper per scroll | I test UI richiedono widget visibili nel viewport |

## 6. File modificati/creati

### V0.3.1
- `pubspec.yaml` — aggiunto `sqflite`, `path`, `uuid`
- `lib/data/app_database.dart` — SQLiteService integrato, cache + DB
- `lib/data/sqlite_service.dart` — CREATO: query SQL raw
- `lib/models/conto.dart` — CREATO: modello Conto
- `lib/screens/dashboard_screen.dart` — KPI conti, ListenableBuilder
- `lib/screens/movements_screen.dart` — modifica movimento, confirm delete
- `lib/widgets/movement_form.dart` — campo conto
- `test/qa_movements_test.dart` — +53 test (V0.3.x)
- `test/widget_test.dart` — setup SQLite

### V0.3.2
- `lib/widgets/confirm_delete_dialog.dart` — CREATO
- `lib/screens/movements_screen.dart` — integrazione confirm delete
- `test/confirm_delete_test.dart` — CREATO: 2 test
- `lib/models/categoria.dart` — modello aggiornato (nome, tipo, colore, archiviata)
- `lib/screens/categories_screen.dart` — CREATO: CRUD + archive/restore
- `lib/data/app_database.dart` — metodi categorie + protezione (categoriaUsata)
- `test/categories_test.dart` — CREATO: 17 test
- `test/dashboard_after_delete_test.dart` — CREATO: 21 test
- `test/movement_test_helper.dart` — ensureVisible per test helper

## 7. Test V0.3.x

```
flutter test → 193/193 passed
flutter analyze → 0 issues
```

| Test file | Test | Copertura |
|-----------|------|-----------|
| `qa_movements_test.dart` | 126 | V0.1 + V0.2 + V0.3.1 (SQLite, Conti, Modifica) |
| `categories_test.dart` | 27 | CRUD Categorie + Archivia/Ripristina + Protezione + Rename propagazione |
| `dashboard_after_delete_test.dart` | 21 | KPI dopo delete (in-memory 15, SQLite 3, UI 3) |
| `widget_test.dart` | 2 | Confirm Delete UI |
| `qa_risky_scenarios_test.dart` | 17 | Conti, SQLite, Suggeriti, Duplica, Rapidi, Preferiti |
| **Totale** | **193** | |

## 8. Build installabili

### Android
```
flutter build apk --debug
→ build/app/outputs/flutter-apk/app-debug.apk (207MB)
Install su Pixel 6: ✅
Apribile senza PC: ✅ SÌ
```

### iOS
```
flutter build ios --debug (signing auto QDZN3K5LUM)
→ build/ios/iphoneos/Runner.app
→ compresso in Stream_Dev.ipa (31MB)
Install su iPhone: ✅ (via ideviceinstaller)
Apribile senza PC: ⚠️ SÌ, ma 7 giorni (limite account Apple gratuito)
```

## 9. Cosa NON include V0.3

- Tema scuro / Design System → V0.4
- Budget / Actual → V0.5
- Scenari / Forecast → V0.6
- Profili / Nirvana → V0.7
- Import CSV → V0.8
- Cloud / Sync → V0.9
- App Store / Play Store → V1.0

## 10. Debiti tecnici aperti

| # | Debito | Priorità | Note |
|---|--------|----------|------|
| 1 | Tema scuro | Media | Posticipato a V0.4 |
| 2 | Layout tablet | Bassa | Schermo singolo, nessun adaptive layout |
| 3 | Error feedback utente | Media | Validazione ancora silenziosa in alcuni casi |

## 11. V0.3.3 — Human QA 1500 (CLOSED)

### Bug CRITICAL trovato e corretto: DefaultCategories.byId()

**Problema**: `movements_screen.dart`, `dashboard_screen.dart`, `movement_picker.dart` usavano `DefaultCategories.byId(categoryId)` per cercare nome e colore della categoria. `DefaultCategories` è una lista **hardcoded** di 10 categorie, quindi:
- Rinomina categoria → Movimenti/Dashboard/Picker ignoravano la modifica
- Categoria custom → mostrava l'ID (es. `cat_1712345678901`) al posto del nome

**Fix**: Sostituito con `db.categories.where((c) => c.id == ...).firstOrNull` in 6 punti.

**Impatto architetturale**: Le categorie sono ora risolte esclusivamente tramite `categoryId → db.categories`. Eliminata dipendenza da `DefaultCategories` per il rendering runtime. Movement salva solo `categoryId`; nome e colore categoria vengono sempre risolti runtime da `AppDatabase.categories`. Questo garantisce supporto a categorie custom, rename e archive/restore senza inconsistenze UI.

### Risultati QA

| Metrica | Valore |
|---------|--------|
| Scenari analizzati | 352 |
| Bug CRITICAL | 1 (corretto) |
| Bug HIGH | 0 |
| Bug MEDIUM | 1 (backlog) |
| Bug LOW | 1 (backlog) |
| Test aggiunti | 27 (10 rename + 17 risky) |
| Test totali | 193 |
| flutter analyze | 0 issues |
| flutter build apk | ✅ |
| flutter build ios | ✅ |

## 12. Note per beta

- **iPhone beta amici** — richiede TestFlight / Apple Developer ($99/anno)
- **Android beta amici** — APK debug distribuibile direttamente
- **Prima di V0.4** — serve uso reale per 2-3 giorni per raccogliere feedback

## 13. Stato finale

# ✅ HERMES V0.3 — COMPLETATO

Tutte le feature pianificate per V0.3 sono state implementate, testate e distribuite su entrambe le piattaforme. QA umana estesa (352 scenari) completata con 1 bug CRITICAL corretto.
