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
| Share sheet | share_plus | ^12.0.2 |
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
- **MovementCard unico**: le schermate operative usano `lib/widgets/movement_card.dart` per renderizzare un movimento. La Dashboard ora mostra KPI e spese per categoria, non una lista movimenti. Dettaglio completo nella sezione "MovementCard Widget" sotto.

## MovementCard Widget

> Widget unico per renderizzare movimenti in tutta l'app. Sostituisce 4 classi private duplicate (~376 righe eliminate).

**File**: `lib/widgets/movement_card.dart`
**Test**: `test/movement_card_test.dart` (14 widget test)
**Versione**: Introdotto in V0.5.6+ (dopo Dashboard Filtrata)

### API

| Prop | Tipo | Default | Descrizione |
|------|------|---------|-------------|
| movement | Movement | required | Dati del movimento da renderizzare |
| category | Category? | null | Categoria risolta da db.categories |
| account | Account? | null | Conto risolto da db.accounts |
| onTap | VoidCallback? | null | Tap sull'intera card |
| onEdit | VoidCallback? | null | Azione modifica (solo popup) |
| onDuplicate | VoidCallback? | null | Azione duplica (solo popup) |
| onSaveAsFavorite | VoidCallback? | null | Salva come preferito (solo popup) |
| onDelete | VoidCallback? | null | Elimina movimento (solo popup) |
| showNotes | bool | false | Mostra testo nota sotto il titolo |
| showDate | bool | false | Mostra data in alto a destra |

### Comportamento

- **Popup menu**: appare automaticamente se almeno uno tra `onEdit`, `onDuplicate`, `onSaveAsFavorite`, `onDelete` è fornito
- **Delete confirm**: dialog interno (`_confirmDelete`) — pura UI, il callback `onDelete` esegue la logica DB
- **Icona**: 36×36 px (standardizzata, era 40×40 in Dashboard)
- **Layout**: icona + titolo + categoria + conto + importo, opzionali date/note/popup

### Contratto

MovementCard è **solo vista**:
- ✅ Accetta dati risolti (category/account già trovati)
- ✅ Espone callback per azioni UI
- ❌ Non scrive su database
- ❌ Non aggiorna Actual / aggregati
- ❌ Non calcola saldi o statistiche
- ❌ Non modifica lo stato globale

### Utilizzo

| Schermata | File | Come viene usato |
|-----------|------|------------------|
| Dashboard | `lib/screens/dashboard_screen.dart` | Non usa `MovementCard`: mostra KPI periodici + spese per categoria |
| Calendario | `lib/screens/calendar_screen.dart` | `MovementCard(movement:, category:, account:, onTap: → edit)` — tap apre modifica |
| Movimenti | `lib/screens/movements_screen.dart` | `MovementCard(movement:, category:, account:, onEdit:, onDuplicate:, onSaveAsFavorite:, onDelete:, showNotes:, showDate:)` |

## Dashboard Filtrata (V0.5.6)

- **Obiettivo UX**: la Dashboard risponde a "come sta andando il periodo selezionato?", non a "quali movimenti ho registrato?"
- **Riusi**: `TimeFilter`, `TimeFilterBar`, `filterByTime()`
- **Filtrati**: entrate periodo, uscite periodo, saldo periodo, numero movimenti, spese per categoria
- **Non filtrati**: patrimonio totale, saldi conti, fondi/situazione conti attuale
- **Spese per categoria**: solo uscite, raggruppate per categoria, massimo 5 righe, ordine decrescente, percentuale solo se il totale spese è > 0
- **Colori**: usa `Category.color` salvato; fallback al colore di default del design system se il colore non è disponibile
- **Empty state**: `Nessuna spesa nel periodo selezionato`
- **Periodo precedente**: confronto semplice per i filtri standard; saltato sui range custom per evitare logica fragile
- **Vincolo**: nessuna lista movimenti in Dashboard, nessuna nuova ricerca o grafico complesso

## Database (V6)

### Movimenti (V6: +date)
```sql
CREATE TABLE movements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,        -- 'income' | 'expense'
  category_id TEXT NOT NULL,
  account_id TEXT NOT NULL DEFAULT 'acc_default',
  date TEXT NOT NULL,         -- ISO data (AAAA-MM-GG), V6
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Conti (V0.4.1: +color, +iconKey)
```sql
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,         -- 'bank' | 'cash' | 'card' | 'savings' | 'other'
  initial_balance REAL NOT NULL DEFAULT 0.0,
  icon_key TEXT NOT NULL DEFAULT 'account_balance',
  color INTEGER NOT NULL DEFAULT 4278230352,
  archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Categorie (V4: +icon_key)
```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,         -- 'income' | 'expense'
  color INTEGER NOT NULL,
  icon_key TEXT NOT NULL DEFAULT 'category',
  archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Movimenti Rapidi (V3: +account_id)
```sql
CREATE TABLE quick_movements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  category_id TEXT NOT NULL,
  account_id TEXT NOT NULL DEFAULT 'acc_default',
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Movimenti Preferiti (V3: +account_id)
```sql
CREATE TABLE favorite_movements (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  category_id TEXT NOT NULL,
  account_id TEXT NOT NULL DEFAULT 'acc_default',
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
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

### Navigation finale (V0.5.6+)

- **Bottom nav**: 3 elementi reali — Dashboard, Archivio, Impostazioni
- **Dentro Archivio**: Movimenti, Conti, Categorie e Calendario restano nell'area operativa
- **Calendario**: non è una tab principale, vive dentro Archivio
- **Backup/Restore**: non è una tab separata, vive dentro Impostazioni
- **Dashboard**: resta solo sintesi/insight del periodo selezionato

### Backup & Restore (Impostazioni)

- **Posizionamento UI**: card/sezione `Backup & Restore` dentro `Impostazioni`
- **Backup**: export in JSON con `BackupService.exportToJson()`. Include: accounts, categories, movements, quickMovements, favoriteMovements, settings (showNotes)
- **Salvataggio**: cartella interna `getDatabasesPath()/backups/` con nome `backup_YYYY_MM_DD_HH_mm.json`
- **Share sheet esportazione**: dopo "Crea backup", SnackBar con "Condividi" apre share sheet nativo via `share_plus`. Ogni backup nella lista "Backup salvati" ha icona share.
  - Android: `Intent.ACTION_SEND` → Drive, email, Downloads
  - iOS: `UIActivityViewController` → Files, iCloud, Mail, AirDrop
  - Se la condivisione fallisce, il backup interno resta salvato
- **Restore**: transazionale (`sqlite.transaction()`). DELETE su tutte le tabelle → INSERT dati backup.
  - **Rollback**: SQLite rollbacka se la transazione fallisce. `db.replaceState()` (in-memory) eseguito dopo il commit.
  - **Orfani**: `_normalizeMovement/Quick/Favorite` gestisce accountId/categoryId mancanti → fallback a `defaultAccountId` o `_defaultCategoryIdForType`.
  - **Pre-restore backup**: `createPreRestoreBackup()` salva stato corrente prima del restore.
  - **Conferma**: dialog con conteggio entity (conti, categorie, movimenti, rapidi, preferiti).
- **Import**: `FilePicker.pickFiles(allowedExtensions: ['json'])` — seleziona da qualsiasi posizione accessibile.
- **Validazione**: `BackupService.validate()` controlla JSON, version (1–1), campi obbligatori (accounts, categories, movements).
- **File sorgente**: `lib/services/backup_service.dart`, `lib/models/backup_data.dart`, `lib/screens/backup_screen.dart`
- **Dipendenza**: `share_plus ^12.0.2`

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

### `flutter build apk --release` FAIL: `file_picker` — classe `FilePickerPlugin` non trovata

**Sintomo**:
```
error: cannot find symbol
  class FilePickerPlugin
```

**Causa** (root):
`file_picker 11.0.2/android/build.gradle` contiene:
```groovy
def isAgp9OrAbove = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.tokenize('.')[0].toInteger() >= 9
apply plugin: 'com.android.library'
if (!isAgp9OrAbove) {
    apply plugin: 'org.jetbrains.kotlin.android'
}
```
Con AGP 9.0.1, `isAgp9OrAbove = true` → KGP **non** applicato. Flutter's `detectApplyingKotlinGradlePlugin` legge il testo del build file, trova `kotlin.android` (riga 30), e salta l'applicazione di KGP. Risultato: nessun KGP → sorgenti Kotlin non compilate → `FilePickerPlugin` assente nell'AAR.

**Fix** (`android/build.gradle.kts`):
```kotlin
subprojects {
    if (project.name == "file_picker") {
        pluginManager.apply("kotlin-android")
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}
```
KGP applicato al subprogetto `file_picker` **prima** della sua evaluation (il blocco `subprojects {}` in root `build.gradle.kts` esegue durante la configurazione, prima del `build.gradle` del plugin). Anche il `jvmTarget` è forzato a 17 perché il plugin salta il blocco `kotlinOptions` quando AGP >= 9.

**Perché non `builtInKotlin=true`**: Flutter applicherebbe KGP a `flutter_plugin_android_lifecycle` (puro Java), e AGP 9.0.1 rifiuta KGP su progetti Java con `builtInKotlin=true`.

## Metriche

| Metrica | V0.1 | V0.2 | V0.3.2 | V0.3.3 | V0.4 | V0.4.1 | V0.4.2 | V0.5.4 | V0.5.5+refactor | V0.5.6 |
|---------|------|------|--------|--------|------|--------|--------|--------|-----------------|--------|
| Test | 50 | 65 | 166 | 193 | 193 | 235 | 235 | 299 | 326 | 363 |
| Analyze issues | 0 | 0 | 1 warning | 0 | 0 | 0 | 0 | 2 pre-existing | 2 pre-existing | 0 |
| Build APK debug | 13s | 5.8s | 8.1s | 5.7s | 5.5s | 5.5s | 5.5s | 5.5s | 5.5s | 5.5s |
| Build APK release | — | — | — | — | — | — | — | — | — | **98.6s** (66.1MB) |
| Build iOS debug | N/A | N/A | 12.3s | 10.2s | 12.8s | 12.8s | 12.8s | 20.7s | 20.7s | 44.1s |
| Build iOS release | — | — | — | — | — | — | — | — | — | **44.1s** (32.7MB) |
| APK size (debug) | N/A | N/A | 207MB | 207MB | 207MB | 207MB | 207MB | 207MB | 207MB | 207MB |
| APK size (release) | — | — | — | — | — | — | — | — | — | **66.1MB** |
| IPA size (release) | — | — | — | — | — | — | — | — | — | **32.7MB** |
| share_plus | — | — | — | — | — | — | — | — | — | ^12.0.2 |
