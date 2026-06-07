# STREAM — Technical Notes

> Decisioni architetturali e note tecniche per sviluppatori.

## Stack

| Layer | Tecnologia | Versione |
|-------|-----------|----------|
| Framework | Flutter | 3.44.1 |
| Linguaggio | Dart | 3.12.1 |
| Database | sqflite (raw SQL) | ^2.4.2 |
| ID | uuid v4 | ^4.5.1 |
| Persistenza toggle | SharedPreferences | ^2.5.5 |
| Min SDK Android | 21 | |
| Target iOS | 12.0 | |

## Application ID / Bundle ID

| Piattaforma | ID | File |
|-------------|----|------|
| Android | `com.mattiasironi.flow` | `android/app/build.gradle.kts:namespace + applicationId` |
| iOS | `com.mattiasironi.flow` | `ios/Runner.xcodeproj/project.pbxproj:PRODUCT_BUNDLE_IDENTIFIER` |

⚠️ **Non modificare** — cambio ID causa perdita dati (il sistema operativo tratta ID diverso come app diversa).

## Architettura

```
┌─────────────────────────────────────────────┐
│                  UI Layer                    │
│  Screens / Widgets / Dialogs                │
│  (StatefulWidget, ListenableBuilder)        │
└──────────────────────┬──────────────────────┘
                       │ ascolda (notifyListeners)
┌──────────────────────▼──────────────────────┐
│             AppDatabase (Model)             │
│  ┌──────────────┐  ┌────────────────────┐   │
│  │ Cache (RAM)  │  │ SQLiteService      │   │
│  │ List<X>      │  │ insert/update/     │   │
│  │              │  │ delete/select      │  │   │
│  └──────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Pattern
- **Model-as-controller**: `AppDatabase` è il modello centrale, notifica i listener, espone metodi CRUD, mantiene cache
- **No BLoC / Provider / Riverpod**: scelta deliberata per MVP. ListenableBuilder + StatefulWidget sono sufficienti per la complessità corrente. Da rivalutare a V0.5+ quando lo stato cresce
- **Raw SQL**: sqflite con query raw invece di Drift ORM (dipendeenza drift presente ma non usata). Scelta per controllo totale e debugging trasparente
- **MovementCard unico**: tutte le schermate usano `lib/widgets/movement_card.dart` per renderizzare un movimento. Nessuna duplicazione di layout. Accetta `movement`, `category`, `account`, callback `onTap`, popup callbacks (`onEdit`, `onDuplicate`, `onSaveAsFavorite`, `onDelete`), `showNotes`, `showDate`. Non scrive su database — solo callback UI.

## Database (V5)

### Movimenti
```sql
CREATE TABLE movements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,        -- 'income' | 'expense'
  categoryId TEXT NOT NULL,
  note TEXT,
  accountId TEXT,
  createdAt TEXT NOT NULL
);
```

### Conti (V0.4.1: +color, +iconKey)
```sql
CREATE TABLE conti (
  id TEXT PRIMARY KEY,
  nome TEXT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'default',  -- 'default' | 'extra'
  saldoIniziale REAL NOT NULL DEFAULT 0.0,
  iconKey TEXT,
  color INTEGER NOT NULL DEFAULT 4278230352  -- 0xFFEF5350
);
```

### Categorie
```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  nome TEXT NOT NULL,
  tipo TEXT NOT NULL,         -- 'income' | 'expense'
  colore INTEGER NOT NULL,
  archiviata INTEGER NOT NULL DEFAULT 0
);
```

### Movimenti Rapidi
```sql
CREATE TABLE quick_movements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  categoryId TEXT NOT NULL,
  note TEXT,
  accountId TEXT
);
```

### Movimenti Preferiti
```sql
CREATE TABLE favorite_movements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  categoryId TEXT NOT NULL,
  note TEXT,
  accountId TEXT
);
```

## Data Persistence Between Updates

### Come funziona

| Scenario | Android | iOS |
|----------|---------|-----|
| `adb install -r` upgrade | ✅ Preserva tutto | N/A |
| `flutter run` su app esistente | ✅ Preserva tutto | ✅ Preserva tutto |
| Xcode Run su app esistente | N/A | ✅ Preserva tutto |
| TestFlight aggiornamento | N/A | ✅ Preserva tutto |
| App Store aggiornamento | N/A | ✅ Preserva tutto |
| **Uninstall + reinstall** | ❌ **Perde tutto** | ❌ **Perde tutto** |
| Cambio applicationId / Bundle ID | ❌ **Perde tutto** | ❌ **Perde tutto** |

### Dati preservati

- `stream.db` (SQLite, 5 tabelle) — posizione: `getDatabasesPath()/stream.db`
- SharedPreferences (toggle `show_notes`)
- File asset in `assets/branding/` (in APK/IPA, non generati runtime)

### Comando upgrade corretto (Android)

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Il flag `-r` (reinstall) è fondamentale. Senza, `adb install` fallisce con "INSTALL_FAILED_ALREADY_EXISTS".

### Procedura upgrade iOS

```bash
flutter run -d <UDID>
# oppure via Xcode: Product > Run (⌘R)
# Bundle ID invariato → sandbox preservato
```

### Rischi noti

1. **Uninstall/reinstall** — unico modo certo per perdere dati in fase di sviluppo
2. **`adb shell pm clear`** — cancella DB e preferenze, non recuperabile
3. **Migration silenziosa** — ALTER TABLE in try/catch ignora errori reali (es. disco pieno)
4. ~~**`CREATE TABLE accounts` in V2 upgrade** non ha try/catch~~ ✅ **FISSATO** — `CREATE TABLE IF NOT EXISTS` + debugPrint in catch
5. **V6 intero in unico try/catch** — se backfill falliva, fallback saltato → date NULL, crash ✅ **FISSATO** — 3 try/catch indipendenti + backfill sicuro con validazione ISO

### Database path (per backup manuale)

```bash
# Android
adb exec-out run-as com.mattiasironi.flow cat databases/stream.db > backup.db

# iOS
# Xcode > Window > Devices > seleziona iPhone > STREAM > ⚙️ > Download Container
```

## Design System (V0.4)

Il tema STREAM è definito in `lib/theme.dart` con le classi:
- `StreamColors` — palette completa (canvas, surface, primary, income, expense, text)
- `StreamTypography` — text style scale (display, h1, h2, h3, body, caption, micro, amount)
- `StreamSpacing` — spacing scale (xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, section=32)
- `StreamRadius` — border radius scale (sm=8, md=12, lg=16, xl=20)
- `StreamTheme.dark` — tema completo Material 3 dark con tutti i componenti temizzati

### Principi
- **Content-first**: dati al centro, UI al servizio
- **Luminance hierarchy**: card distinte per luminosità, mai bordi
- **Dark native**: `#0C0E12` canvas, `#15171D` surface
- **Accento unico**: `#4B7BFF` per CTA, nessun altro colore per chrome

### Account Color Field (V0.4.1)
- **Model**: `Account` ha campo `int color` con default `StreamColorPalette.defaultColor` (0xFFEF5350)
- **SQLite**: V5 migration aggiunge `color INTEGER NOT NULL DEFAULT 4278230352` (0xFFEF5350 in signed 32-bit)
- **AppDatabase**: `updateAccount()` accetta `color` opzionale; `archiveAccount()` preserva iconKey e color
- **Regola rendering**: Views devono risolvere `accountId → db.accounts` per nome/tipo/colore/iconKey. Mai usare hardcoded `StreamColors.primary` per account.
- **File chiave**: `lib/models/account.dart`, `lib/data/sqlite_service.dart` (V5 migration), `lib/screens/accounts_screen.dart`, `lib/screens/movement_form.dart`, `lib/widgets/movement_picker.dart`, `lib/screens/dashboard_screen.dart`, `lib/screens/movements_screen.dart`, `lib/widgets/movement_card.dart`

### Navigation Refactor: Archivio (V0.4.2)
- **Tab Movimenti, Conti, Categorie consolidate** in unica tab "Archivio" nella bottom navigation
- **Nuova schermata**: `lib/screens/archive_screen.dart`
  - `SegmentedButton` con 3 sezioni: Movimenti (Icons.swap_vert), Conti (Icons.account_balance), Categorie (Icons.category)
  - `IndexedStack` preserva lo stato di ogni sezione
  - Nessun Scaffold proprio — ogni child ha il suo Scaffold (AppBar, FAB)
  - **SafeArea** avvolge il contenuto con padding top 12px extra — compatibile Dynamic Island, notch, punch hole, tablet
- **Bottom nav**: 2 elementi — Dashboard (index 0), Archivio (index 1)
- **Rapidi e Preferiti** restano sotto Movimenti
- **Nessuna migrazione database** — solo refactor navigazione
- **Test**: 235/235 preserved

### Quick/Favorite Movement Library UX (V0.4.3) 📋 APPROVATA

> Feature approvata, non implementata. Dettaglio in `HERMES_ROADMAP.md`.

**Problema**: Rapidi/Preferiti non scalano con liste lunghe. Nessuna ricerca, nessun filtro, nessun modo per salvare da Manuale.

**Architettura proposta**:

```
PopupMovimenti (Manuale / Rapido / Preferito)
  ├── Manuale: + opzioni "Salva come Rapido" / "Salva come Preferito"
  ├── Rapido:  + campo ricerca + filtro categoria
  └── Preferito: + campo ricerca + filtro categoria + "Aggiorna da Manuale"
```

**Vincoli da rispettare**:
- Rapidi e Preferiti restano template, non movimenti reali
- Helper condivisi per ridurre duplicazione logica
- Nessuna modifica DB senza progettazione
- Ricerca deve trovare per: nome, categoria, conto, note, importo
- Filtro categoria deve usare `AppDatabase.activeCategories` come fonte di verità

### Calendar Heatmap / Category Heatmap 📋 APPROVATA

> Feature approvata, non implementata. Evoluzione visuale di V0.5 Foundation.
> Dipende da: date nei movimenti + TimeFilter globale (V0.5 Foundation).

**Architettura proposta**:
- Griglia mensile (`GridView`) con 7 colonne (giorni della settimana)
- Colore cella determinato da funzione di intensità: `f(movementsDelGiorno, mode)` → `Color`
- Modalità: spese (StreamColors.expense), entrate (StreamColors.income), saldo netto (dual color)
- Filtro categoria: filtra `db.movements` prima di calcolare heatmap
- Tap giorno: naviga a vista movimenti filtrata per data
- Tap rapido: apre form movimento con `date` precompilata
- Totale mese: calcolato da `db.totalIncome` / `db.totalExpenses` con filtro data applicato

**Vincoli tecnici**:
- Nessuna nuova tabella SQLite — dati già disponibili in `db.movements`
- Palette STREAM esistente (`StreamColors`) per scala colore heatmap
- Implementare solo dopo V0.5 Foundation (date + TimeFilter)

### Categorie integrazioni
Fonti ispirazione: UI Dashboard, UI Budget, UI Fondi, UI Scenario in `/Users/mattiasironi1/Documents/FLOW/UI inspiration/`

### Category Resolution Strategy

**Fonte di verità**: `AppDatabase.categories`

**Regola**: Movement salva solo `categoryId`. Nome e colore categoria vengono sempre risolti runtime tramite `db.categories.where((c) => c.id == categoryId).firstOrNull`.

**Motivazione**:
- Supporto categorie custom create dall'utente
- Supporto rename categoria (propagazione automatica a tutte le viste)
- Supporto archive/restore (categoria archiviata ancora risolvibile nello storico)
- Eliminazione inconsistenze UI (valore unico, non duplicato)

**⚠️ NON usare mai `DefaultCategories.byId(categoryId)`** — ignora categorie modificate/aggiunte dall'utente. Bug CRITICAL #1 corretto in V0.3.3.

### Codice
- `camelCase` per variabili e metodi
- `PascalCase` per classi e tipi
- `snake_case` per colonne SQL
- Prefisso `_` per metodi privati
- `// TODO:` per work-in-progress
- Nessun commenti nei file finali (salvo docstring essenziali)

### Test
- Test file: `test/<nome>_test.dart`
- Helper: `test/movement_test_helper.dart`
- Nome test: `#. Descrizione azione → risultato atteso`
- Categorie test: in-memory + SQLite + UI
- `ensureVisible` necessario per widget test con scroll

### Git
- Branch: `main` è staging, feature branch per V.x
- Commit: messaggi descrittivi in italiano
- Niente commit di secreti, chiavi o dati sensibili

## Build & Deploy

### Android (dev)
```bash
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk
# ⚠️ -r è obbligatorio per upgrade, altrimenti fallisce con INSTALL_FAILED_ALREADY_EXISTS
# ⚠️ Senza -r farebbe uninstall prima di installare → dati persi
```

### iOS (dev via Xcode)
```bash
flutter run -d 00008140-001E29803CD1801C
# oppure apri Runner.xcworkspace in Xcode e ⌘R
# Bundle ID com.mattiasironi.flow invariato → sandbox preservato
```

### iOS (IPA per beta)
```bash
flutter build ios --release --no-codesign
mkdir -p build/ios/iphoneos/Payload
cp -r build/ios/iphoneos/Runner.app build/ios/iphoneos/Payload/
cd build/ios/iphoneos && zip -qr Stream_Dev.ipa Payload/
```

### Limiti account Apple gratuito
1. Provisioning profile scade in 7 giorni — reinstall necessaria
2. Nessun TestFlight — serve Apple Developer $99/anno
3. Nessun Release IPA — solo debug
4. App mostra banner "Debug"

## Troubleshooting

### `flutter install` non trova APK
`flutter install` cerca `app-release.apk`. Usare `adb install -r build/.../app-debug.apk`. **Sempre con `-r`** per non perdere dati.

### Dati persi dopo upgrade
Verificare:
1. `applicationId` in `android/app/build.gradle.kts` non è cambiato
2. `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj` non è cambiato
3. Comando usato include `-r` (Android) o è `flutter run` (iOS)
4. L'app non è stata disinstallata tra un upgrade e l'altro
5. `adb shell pm clear` non è stato eseguito
6. L'utente non ha cancellato manualmente l'app

### IDE non trova adb
`adb` si trova in `~/Library/Android/sdk/platform-tools/adb`. Usare path completo.

### iOS install fallisce
Probabilmente signing non configurato. Verificare:
1. Team QDZN3K5LUM in Xcode
2. Bundle ID com.mattiasironi.flow
3. Dispositivo fidato (Trust this computer)
4. Provare Xcode → Product → Run

## Metriche

| Metrica | V0.1 | V0.2 | V0.3.2 | V0.3.3 | V0.4 | V0.4.1 | V0.4.2 | V0.5.4 | V0.5.5+refactor |
|---------|------|------|--------|--------|------|--------|--------|--------|-----------------|
| Test | 50 | 65 | 166 | 193 | 193 | 235 | 235 | 299 | 326 |
| Analyze issues | 0 | 0 | 1 warning | 0 | 0 | 0 | 0 | 2 pre-existing | 2 pre-existing |
| Build APK | 13s | 5.8s | 8.1s | 5.7s | 5.5s | 5.5s | 5.5s | 5.5s | 5.5s |
| Build iOS | N/A | N/A | 12.3s | 10.2s | 12.8s | 12.8s | 12.8s | 20.7s | 20.7s |
| APK size | N/A | N/A | 207MB | 207MB | 207MB | 207MB | 207MB | 207MB | 207MB |
| IPA size | N/A | N/A | 31MB | 31MB | 31MB | 31MB | 31MB | 28.8MB | 28.8MB |
