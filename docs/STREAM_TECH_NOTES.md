# STREAM — Technical Notes

> Decisioni architetturali e note tecniche per sviluppatori.

**Stato:** Hermes closure candidate / QA stabilized + V0.11l-d total hardening backup-reset-filters + dashboard hero dedup + effective automatic KPI style mapping + advanced chart styles rollout + global KPI style coverage + account detail movement-priority UX + movement theme completion + movement actions sheet centralizzato + beneficiari manuali auditati + movement suggestion chips + currency preference + profili separati | **DB:** v12 per singolo profilo | **Build:** ✅ nessun errore bloccante (`flutter analyze` info-only fuori scope)

## Update 2026-06-22 — V0.11l-d Total Hardening Filters, Profiles, Backup and Charts

- Audit confermato su `MainScaffold`, `ArchiveScreen`, `SettingsScreen` e `BackupScreen`: `activeProfileId` continua a propagarsi correttamente verso Dashboard, Movimenti, Grafici, Categorie, Conti e Beneficiari
- Nessuna nuova chiave scoped usa storage globale per errore; restano profile-scoped:
  - `dashboard_net_worth_account_ids_<profileId>`
  - `movements_filter_account_ids_<profileId>`
  - `movements_filter_category_ids_<profileId>`
  - `charts_filter_account_ids_<profileId>`
  - `charts_filter_category_ids_<profileId>`
  - `categories_filter_account_ids_<profileId>`
  - `accounts_filter_category_ids_<profileId>`
  - `beneficiaries_filter_account_ids_<profileId>`
  - `beneficiaries_filter_category_ids_<profileId>`
- Fix P1 su backup/restore:
  - `BackupSettings` ora serializza anche `movementsAccountFilterIds` e `movementsCategoryFilterIds`
  - `netWorthAccountIds` viene serializzato anche quando e un array vuoto, cosi `empty = nessuno` non collassa piu in `null`
  - `BackupService.restore()` ripristina i default lean di `chartStyle`, `kpiStyle`, `hiddenChartIds` e `categoryLayout` quando il backup non contiene override espliciti
  - Restore scoped continua a usare `normalizeScopedFilterIds(...)` per eliminare ID invalidi/archiviati senza perdere i veri empty-set
- Nessuna modifica a DB/schema/migrazioni o a logiche di scrittura movimenti/conti: il fix resta confinato a preferenze e backup/restore
- Validazione locale:
  - test mirati hardening verdi
  - `flutter test` full suite verde con `1157` passati e `1` skipped
  - `flutter analyze` con soli `34` info preesistenti del repo

## Update 2026-06-21 — V0.11j-fix4 Dashboard Hero Dedup + Effective Automatic KPI Style

- In `lib/screens/dashboard_screen.dart` la hero Patrimonio non renderizza piu una seconda lista bottom-level di account pill: la duplicazione nasceva dal fatto che `_BalanceHero` aggiungeva una wrap extra oltre a quelle gia prodotte da `_HeroStacked` / `_HeroSplit`
- La hero mantiene una sola lista compatta con massimo `3` conti visibili e pill finale `+N altri`; nessuna modifica a ordine, saldi o calcolo del patrimonio
- La label interna `PATRIMONIO` e stata rimossa: il titolo principale resta `Patrimonio netto`, mentre il contesto testuale non duplica piu lo stesso concetto
- `_AccountBalancePill` ora applica un `maxWidth` relativo al viewport e usa `ellipsis` sul nome conto per ridurre il rischio di overflow orizzontale
- `resolveEffectiveKpiStyle(StreamThemePalette, StreamKpiStyleId)` resta il punto centrale per rendere `automatic` davvero theme-aware: Classic/Forest → `glass`, Midnight → `outline`, Aurora → `split`, Minimal Sand → `minimal`, High Contrast → `solid`
- Correzione importante: la hero Dashboard ora usa lo stile effettivo anche per scegliere il layout; prima `automatic` poteva risolvere a `split` ma continuare a usare il layout stacked
- Test aggiunti: `dashboard_hero_account_dedup_test.dart`, `kpi_automatic_style_resolution_test.dart`
- Test aggiornati: `kpi_hero_theme_test.dart`, `stream_kpi_card_theme_emphasis_test.dart`, `dashboard_filtered_test.dart`, `qa_extensive_test.dart`
- Validazione finale locale: `flutter test` full suite verde con `1059` passati e `~1` skipped

## Update 2026-06-21 — V0.11j Advanced Chart Styles Settings Rollout

- `PreferencesService.chartStyleNotifier` e `chart_style` non sono piu solo plumbing: `StreamApp` ricostruisce il `ThemeData` anche al cambio stile grafici e l'intera `context.$chart` riceve token coerenti per lo stile scelto
- `lib/design/stream_chart_palette.dart` ora controlla non solo colori, ma anche superfici card, bordi, shadow, empty state, legenda, track/radius/bar width e parametri donut (`center/outer radius`, `labelDistance`, `legendDotSize`)
- `ChartsScreen` applica lo stile alle card principali e ai widget chart (`StreamChartCard`, `StreamBarChart`, `StreamHorizontalBarChart`, `StreamDonutChart`, `ChartEmptyState`)
- Audit bugfix incluso: la visibilita chart non era usata in modo uniforme per il render delle singole card; ora ogni chart passa da `_chartIsVisible(id)` e `hidden_chart_ids` convive correttamente con `chart_style`
- `Dashboard` collega `Spese per categoria` ai token chart-style tramite card/background/border e mini progress bar, mantenendo invariati valori, percentuali e ordinamento
- `PeriodHeatmapCard`, `AnnualHeatmapCard` e `MovementsHeatmapPreviewCard` usano superfici chart-style per il contenitore esterno senza cambiare logica heatmap o intensita celle
- `SettingsScreen` espone opzioni `automatic`, `soft`, `technical`, `highContrast`, `editorial` con key stabili e descrizioni brevi lato UI
- Regressione test emersa in full suite: `test/heatmap_theme_test.dart` verificava la vecchia surface generica; riallineato al nuovo token chart-style
- Validazione finale: `68` file test, `1048` passati, `1` skipped

## Update 2026-06-21 — V0.11i-fix3 Account Detail Movement Priority UX

- `AccountsScreen` account detail sheet riorganizzata con priorita alla lista movimenti: top area piu compatta, azioni 2x2 alleggerite e filtro periodo subito raggiungibile
- Aggiunti mini-summary compatto e sezione `Riepilogo dettagliato` collassabile, chiusa di default quando esistono movimenti e aperta sugli empty state
- KPI dettagliati continuano a usare il sistema globale di stile tramite `StreamKpiCard`; corretta anche la variante split per evitare constraint verticali infiniti nelle card con accent stripe
- Nuove key stabili per test/UI automation del dettaglio conto; aggiornati test navigazione e aggiunto test dedicato agli stili KPI nel dettaglio account
- Nessuna modifica a calcoli conto, TimeFilter, formattazione valuta o persistenza

## Update 2026-06-21 — V0.11i-fix2 Global KPI Style Coverage

- Copertura estesa degli stili KPI globali nei riepiloghi condivisi e nelle card legacy gia migrate al sistema tema/KPI
- Consolidato l'uso di `StreamKpiCard` come base coerente per varianti `minimal`, `dense`, `glass`, `outline`, `solid`, `split`
- Validazione assorbita nella full suite finale piu recente: `1038` passati, `1` skipped

## Update 2026-06-21 — V0.11i-fix1 Movement Flow Theme Completion

- Completata la migrazione tema delle superfici legacy collegate ai movimenti usando `StreamSurfaceTokens` + `context.$palette`
- `PeriodSummaryCard`, `PeriodHeatmapCard`, `AnnualHeatmapCard`, `MovementsHeatmapPreviewCard` e `TimeFilterBar` usano superfici, border e shadow coerenti col tema corrente
- `MovementPicker`, `MovementForm`, `AddMovementFlow`, `CategorySubcategorySelector`, `MovementCalculatorPad` e `MovementTextSuggestions` non dipendono più da sfondi statici lato utente
- Bottom sheet/picker con `ListTile` dentro superfici decorate ora hanno `Material` locale, evitando assert Flutter su background/ink invisibili
- Test legacy aggiornati: annual heatmap empty/ignored days ora verificati contro la superficie neutra tema, non più contro `Colors.transparent`
- Nessuna modifica a calcoli heatmap, TimeFilter, movimenti o persistenza

## Update 2026-06-20 — V0.11h Theme Adaptive Cards and Charts

- Aggiunto `lib/design/stream_surface_tokens.dart` come strato condiviso per `card(...)` e `onAccent(...)`
- `StreamThemePalette` ora espone detector di identità tema per abilitare adattamenti visuali mirati senza hardcode nei widget
- `StreamChartPalette.forTheme()` differenzia palette, griglie e legenda per Forest, Midnight, Minimal Sand e High Contrast
- Le superfici utente di Conti, Beneficiari, Categorie, MovementCard e chart widgets usano `context.$palette` / `StreamSurfaceTokens`
- `AccountsScreen` interactive sheet evita overflow verticali mantenendo fissi azioni e filtro tempo
- Nessuna logica dati cambiata: invariati DB/schema, backup/restore, import/export, analytics e formule KPI
- Stato analyzer locale: nessun errore nuovo; restano info storici in `categories_screen.dart`, `backup_screen.dart`, `database.dart`

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

## Charts Architecture (V0.10 — Grafici Tab)

**File chiave:**

| File | Ruolo |
|------|-------|
| `lib/screens/charts_screen.dart` | Main screen con 4 sezioni (chip scrollabili) + TimeFilter |
| `lib/utils/analytics_metrics.dart` | 10 funzioni pure che producono `ChartPoint/ChartSeries/DonutSlice` |
| `lib/widgets/charts/stream_chart_card.dart` | Card wrapper contenitore |
| `lib/widgets/charts/stream_bar_chart.dart` | Bar chart verticale (fl_chart) per dati temporali |
| `lib/widgets/charts/stream_donut_chart.dart` | Donut chart (fl_chart) per distribuzione tipo |
| `lib/widgets/charts/stream_horizontal_bar_chart.dart` | Bar chart orizzontale custom (Row/Container/FractionallySizedBox) per dati categorici |
| `lib/widgets/charts/chart_empty_state.dart` | Empty state widget |
| `test/charts_test.dart` | 20 test (11 metriche pure + 6 integrazione + 3 navigazione) |

**Libreria esterna:** `fl_chart: ^0.70.2` per barre verticali e donut.

**Grafici orizzontali custom:** `StreamHorizontalBarChart` usa `Row` + `Stack` + `Container` (nessuna dipendenza da fl_chart). Supporta label sinistra con ellissi, barra proporzionale, valore formattato a destra, secondary value e legenda multi-serie.

**Top N + Altro:** ogni funzione categorica prende le prime 7 entries; se ci sono più entries, aggrega il resto in "Altro" con `_maybeAddAltro()`.

**Transfer handling:** trasferimenti esclusi da income/expense in aggregazioni categorie e beneficiari. Trattati come neutri nella distribuzione tipo movimento. Conti: flussi separati.

**Chart type rules (V0.10.1c):**
- **Donut**: composizione categorie, distribuzione tipo movimento, top beneficiari (importo), frequenza beneficiari, giorni settimana più costosi, quota saldo conto. Mostra legenda con nome + percentuale + valore, totale centrale.
- **Barre orizzontali**: ranking, classifiche, confronto nomi lunghi (top categorie, saldo/flussi/attività conti, conti uscite/entrate, top giorni spesa, delta categorie, media beneficiario). Label sinistra (ellissi), barra proporzionale, valore a destra.
- **Barre verticali (fl_chart)**: dati temporali (cashflow nel tempo, movimenti per giorno). Touch disabilitato per scroll page.
- **Scroll UX**: tutti i grafici hanno touch disabilitato (`BarTouchData(enabled: false)`, `PieTouchData(enabled: false)`) in modo che il drag verticale scrolli la tab Grafici anziché il grafico. Nessun `ListView.builder` interno nei widget grafici.

**Nuove metriche pure (V0.10.1c):**
| Funzione | Descrizione |
|---|---|
| `buildWeekdayCostBreakdown` | Donut spesa per giorno settimana (Lun-Dom) |
| `buildAvgDailySpend` | Spesa media giornaliera = totale uscite / giorni periodo |
| `buildCategoryDeltaVsPreviousPeriod` | Delta categorie vs periodo precedente (in aumento/in calo) |
| `buildAccountOutflowSeries` | Classifica conti per uscite |
| `buildAccountInflowSeries` | Classifica conti per entrate |
| `buildBeneficiaryAverageSeries` | Valore medio per beneficiario (totale / conteggio) |
| `buildQuotaSaldoSeries` | Donut quota saldo (solo conti con saldo positivo) |

**Budget:** non implementato. La struttura a sezioni di `ChartsScreen` permette aggiunta futura di una sezione Budget. Non ci sono UI, campi DB o testi Budget visibili.

**Chart registry e visibilità (V0.11g):**
- `chartRegistry` in `charts_screen.dart` con ID stabili per ogni grafico
- `PreferencesService.hiddenChartIdsNotifier` + `loadHiddenChartIds()`, `setChartVisible()`, `isChartVisible()`, `resetChartVisibility()`
- `ChartsScreen`: icona `Icons.tune` → `_ChartVisibilitySheet` con SwitchListTile per sezione
- Sezione senza grafici visibili → `_noVisibleCharts()` con empty state

**Donut outside labels (V0.11g):**
- Percentuali rimosse da `PieChartSectionData.title` (causavano sovrapposizione).
- `_LeaderLinePainter` (CustomPainter): dot, leader line, e `TextPainter` per label esterna.
- Label posizionata a destra della lineetta se lato destro, a sinistra se lato sinistro.
- Soglia `_minExternalLabelPercent = 4%`: slice sotto 4% mostrano solo lineetta, percentuale solo in legenda.
- Legenda a destra: dot + label + percentuale + valore. Totale centrale mantenuto.
- Fix V0.11g-fix2+3: singola sorgente `_computeSliceData()` con `_SliceGeometry` per PieChart, legenda e painter. `startDegreeOffset: -90` allineato. Bug mapping slice → leader line risolto.
- Fix V0.11g-fix3: `sectionsSpace: 2` ora incluso nel calcolo angoli (`_sectionsSpaceRad`). Collision avoidance: `_layoutLabels()` separa label destra/sinistra, ordina per y, gap minimo 16px. `_minExternalLabelPercent = 4%` invariato. 1022 test totali.

**Categories Legacy Theme Cleanup (V0.11i):**
- categories_screen.dart: 49 StreamColors → palette tema (`context.$palette`)
- 3 Colors.white icon → p.textPrimary / StreamSurfaceTokens.onAccent()
- 2 Colors.transparent rimasti (tecnici)
- `final p = context.$palette;` aggiunto in 15 scopes
- Nessuna modifica DB, analytics, modelli, logica business

**V0.11j (implemented — Advanced Chart Styles):**
- 5 stili reali: `automatic`, `soft`, `technical`, `highContrast`, `editorial`
- Preferenza persistita in `SharedPreferences` tramite `PreferencesService.chartStyleNotifier`
- Separazione esplicita da KPI style: `kpiStyleNotifier` continua a governare solo le KPI card
- Leader lines, percentuali esterne, `sectionsSpace` e collision avoidance V0.11g preservati

**V0.11j-fix1 (Hero KPI Cards and Strong Theme Differentiation):**
- `StreamKpiEmphasis` (`normal` / `hero`) per ero/key card vs normali KPI
- High Contrast: hero card con sfondo giallo `#FFFF00`, testo nero, bordo bianco 1.5px
- Altri temi: hero card con `surfaceElevated` + gradient accento + bordo accento 1.2px
- Dashboard `_BalanceHero` override High Contrast
- Key stabili su tutte le schermate: `dashboard_hero_kpi`, `accounts_hero_kpi`, `categories_hero_kpi`, `beneficiaries_hero_kpi`, `heatmap_summary_kpi`, ecc.
- Settings, MovementCard, liste, picker, form, chart card NON trasformati in KPI card

**TimeFilter rispettato:** ogni funzione in analytics_metrics accetta `TimeFilter` e filtra con `filterByTime()`. La screen ha `TimeFilterBar` con `customRangeLabel: 'Range'`.

**CurrencyFormatter:** i valori precisi su barre usano `formatMovementCurrency()` dalla valuta globale.

## Theme System (V0.11)

**File chiave:**

| File | Ruolo |
|------|-------|
| `lib/design/stream_theme_palette.dart` | 6 palette colore (`StreamThemePalette`) + enum `StreamThemeId` con `fromString` e fallback |
| `lib/design/stream_chart_palette.dart` | `StreamChartPalette` per grafici (donut colors, category colors, grid, axis) per tema |
| `lib/design/stream_kpi_style.dart` | Enum `StreamKpiStyleId` / `StreamChartStyleId` con `fromString` e fallback |
| `lib/design/stream_theme_extension.dart` | `StreamThemeExtension` (ThemeExtension) con palette + chart palette |
| `lib/theme.dart` | `StreamTheme.build(palette)` — factory ThemeData completo |

**Architettura:**
- `StreamTheme.build(p)` produce `ThemeData` con `extensions: [StreamThemeExtension(...)]`.
- `StreamThemeExtension` si ottiene via `StreamThemeExtension.of(context)` o `context.streamTheme` (estensione con fallback).
- Helper disponibili: `context.$palette` → `StreamThemePalette`, `context.$chart` → `StreamChartPalette`.
- Fallback sicuro: se `StreamThemeExtension` non esiste nel tema (es. test senza tema custom), viene usata palette statica `_fallbackPalette` uguale ai colori Stream Classic.
- Widget migrati a tema: `StreamChartCard`, `ChartEmptyState`, `StreamDonutChart`, `StreamHorizontalBarChart`, `StreamBarChart`, Dashboard `_KpiCard`, `_EmptyState`, `ChartsScreen` chips/legend, `TimeFilterBar`.
- **StreamColors statici restano in ~520 occorrenze** in widget non prioritari (accounts, categories, backup, heatmap, calendar, movement_card, day_header). Migrazione completa come follow-up V0.12.
- **Stili KPI attivi (V0.11d)**: Dashboard `_KpiGrid` con `ValueListenableBuilder(kpiStyleNotifier)`. `_KpiCard` usa `StreamKpiStyleId.fromString(kpiStyle)` e switch per:
  - **Minimal/automatic**: sfondo surface, padding 12, label 11px, no bordo
  - **Dense**: padding 6, label 9px, value 13px (compatto)
  - **Glass**: sfondo `surfaceElevated.withAlpha(0.7)`, bordo `divider.withAlpha(0.5)`
  - **Outline**: bordo `primary.withAlpha(0.4)` evidente
  - **Solid**: sfondo `color.withAlpha(0.15)` (income/expense per colore semantico)
  - **Split**: layout Row — label a sinistra, value in badge colorato a destra
  Cambio live senza riavvio (solo `ValueListenableBuilder`, non ThemeData).
- **Stili grafici reali (V0.11j)**: `StreamChartPalette.applyStyle(StreamChartStyleId, palette)`:
  - **automatic**: comportamento coerente con il tema corrente, senza override estetici extra
  - **soft**: card piu morbide, meno bordi, track piu leggere, raggi barre e donut piu generosi
  - **technical**: griglia/assi piu leggibili, bordi piu presenti, barre piu compatte e struttura piu analitica
  - **highContrast**: massimo contrasto su card, testo, legenda e palette donut
  - **editorial**: card pulite con shadow controllata, meno rumore visivo e look piu presentabile
  `StreamApp` ascolta `themeIdNotifier` + `chartStyleNotifier` per ricostruire `ThemeData` con chart palette effettiva.

**Temi implementati:**

| Tema | Brightness | Primary | Income | Expense |
|------|-----------|---------|--------|---------|
| Stream Classic (default) | dark | #4B7BFF | #34C759 | #FF453A |
| Forest | dark | #22C55E | #4ADE80 | #F97316 |
| Midnight | dark | #60A5FA | #34D399 | #FB7185 |
| Aurora | dark | #8B5CF6 | #10B981 | #F43F5E |
| Minimal Sand | light | #C08457 | #15803D | #B91C1C |
| High Contrast | dark | #FFFF00 | #00FF66 | #FF3366 |

**Persistenza:** `PreferencesService` con `ValueNotifier` per live update. `StreamApp` è ora `StatefulWidget` che ascolta `themeIdNotifier` e ricostruisce `ThemeData`. `Settings → Aspetto` permette scelta tema, stile KPI e stile grafici via bottom sheet.

**Fallback:** `fromString` invalido → Stream Classic / Automatico. High Contrast ha colori molto separati, primary giallo, income verde acceso, expense rosso acceso.

**Budget:** non implementato. Nessuna UI Budget, nessun campo DB, nessun testo Budget visibile.

## MovementCard Widget

> Widget unico per renderizzare movimenti in tutta l'app. Sostituisce 4 classi private duplicate (~376 righe eliminate).

**File**: `lib/widgets/movement_card.dart`
**Test**: `test/movement_card_test.dart` (14 widget test)
**Versione**: Introdotto in V0.5.6+

### GroupedMovementsList Widget (V0.6.2)

> Widget riusabile per visualizzare movimenti raggruppati per giorno.

**File**: `lib/widgets/grouped_movements_list.dart`
**Versione**: Introdotto in V0.6.2

**API**:

| Prop | Tipo | Default | Descrizione |
|------|------|---------|-------------|
| movements | List<Movement> | required | Movimenti da raggruppare e visualizzare |
| db | AppDatabase | required | Database per risolvere categorie/conti |
| showNotes | bool | false | Mostra note nei MovementCard |
| scrollController | ScrollController? | null | Per DraggableScrollableSheet compatibilità |
| onEdit | Function(Movement)? | null | Azione modifica movimento |
| onDuplicate | Function(Movement)? | null | Azione duplica (con scelta data) |
| onSaveAsFavorite | Function(Movement)? | null | Salva come preferito |
| onAddQuick | Function(Movement)? | null | Salva come rapido |
| onDelete | Function(Movement)? | null | Elimina movimento |

**Comportamento**:
- Chiama `groupMovementsByDay()` internamente
- `ListView.builder` con DayHeader + MovementCard intercalati
- MovementCard con `showDate: false` (data già nell'header)
- Padding bottom 80px per spazio FAB

**Utilizzo**: `MovementsScreen`, `_CategoryDetailSheet` (Dashboard)

### Comparator Unico: compareMovementsForDisplay (V0.6.2)

> Top-level function in `lib/models/movement.dart` che centralizza l'ordinamento display di tutti i movimenti.

**Regola finale**:
```
updatedAt desc → createdAt desc → id asc
categoryId, type, amount, title NON influenzano
```

### MovementCardPopupMenu (V0.8.10b)

> Widget popup menu movimento reso pubblico per riuso in layout custom.

**File**: `lib/widgets/movement_card.dart` (ex `_PopupMenu`)
**API**: `onEdit`, `onDuplicate`, `onSaveAsFavorite`, `onAddQuick`, `onDelete` (tutti `VoidCallback?`)

### showDuplicateDateSheet (V0.8.10b)

> Utility per scelta data duplicata con bottom sheet modale.

**File**: `lib/utils/duplicate_date_selector.dart`
**Opzioni**: Oggi / Domani / Ieri / Scegli data / Annulla
**Return**: `Future<DateTime?>` — `null` se annulla
**Uso**: chiamato da ogni `onDuplicate` callback in `movements_screen.dart`, `categories_screen.dart`, `accounts_screen.dart`, `dashboard_screen.dart`
**Copia sicura**: nuovo id (`microsecondsSinceEpoch`), nessuna copia di fingerprint/import metadata

**Sostituisce 3 implementazioni separate**:

### Movement actions sheet / universal edit entry

> Le azioni movimento sono centralizzate in un bottom sheet condiviso.

**File:** `lib/widgets/movement_actions_sheet.dart`, `lib/widgets/movement_card.dart`

**Regole correnti**
- `MovementCard.onTap` usa `onEdit ?? onTap`, quindi il tap breve porta alla modifica nelle viste che passano `onEdit`
- `MovementCard.onLongPress` apre `showMovementActionsSheet(...)` con lo stesso set di callback
- `MovementCardPopupMenu` richiama lo stesso `showMovementActionsSheet(...)`, quindi long-press e tre puntini sono allineati
- Azioni oggi esposte dal foglio condiviso:
  - `Modifica`
  - `Duplica`
  - `Salva preferito`
  - `Salva rapido`
  - `Elimina`

**Copertura**
- Movimenti / Archivio tramite `MovementViewRenderer` e `GroupedMovementsList`
- Dashboard category detail sheet
- Account detail sheet
- Category detail sheet
- Heatmap / riepiloghi che renderizzano movimenti via `MovementCard`

**Limitazione esplicita**
- `BeneficiariesScreen` dettaglio usa `GroupedMovementsList` senza callback `onEdit`: i movimenti si vedono, ma non hanno ancora entry point diretto all’editor da quel punto

### BeneficiaryProfile / payee resolution

> I beneficiari manuali sono metadata persistiti separati dai movimenti.

**Modello:** `lib/models/beneficiary_profile.dart`
- Campi: `id`, `key`, `displayName`, `iconKey`, `color`, `archived`, `createdAt`, `updatedAt`
- `key` usa `normalizeKey()`
- `displayName` usa nome pulito, non modifica `movement.payee`

**Persistenza:**
- `SQLiteService` usa `version: 12`
- Migrazione `v11 → v12` crea `beneficiary_profiles` con `CREATE TABLE IF NOT EXISTS`
- `AppDatabase` mantiene cache `_beneficiaryProfiles`
- `BackupData` e `BackupService` includono `beneficiaryProfiles`
- Restore ripristina anche profili manuali senza movimenti
- `movements.payee` resta invariato; non esiste `payee_id` nella tabella `movements`

**Risoluzione UI:**
- `MovementCard` mostra `profile.displayName` se esiste un profilo con `normalize(movement.payee)`
- fallback: `movement.payee` pulito
- `BeneficiariesScreen` costruisce la lista unendo:
  - beneficiari derivati da `movement.payee`
  - profili manuali senza movimenti
  - tap su beneficiario apre il dettaglio con `GroupedMovementsList` filtrato per key normalizzata

**Picker icone:**
- Il picker beneficiari riusa `IconPickerDialog` e `StreamIconLibrary`
- Non esiste una `beneficiary_icon_library.dart` dedicata: deviazione non bloccante emersa dall’audit, senza impatto funzionale sul flusso Beneficiari

**Form movimento:**
- `MovementPicker` e `MovementForm` propongono il salvataggio del beneficiario solo al submit
- Se il payee non esiste:
  - `No, solo movimento` salva solo `movement.payee`
  - `Salva beneficiario` salva movimento + crea `BeneficiaryProfile`
  - `Annulla` non salva nulla
- Import iFinance escluso: nessun dialog durante preview/commit

### Movement text suggestions

> Suggerimenti locali e compatti per Titolo, Note e Beneficiario nei form movimento.

**File:** `lib/widgets/movement_text_suggestions.dart`
**Uso:** `lib/widgets/add_movement_flow.dart`, `lib/widgets/movement_form.dart`, branch manuale legacy di `lib/widgets/movement_picker.dart`

**Regole comuni**
- Suggerimenti mostrati solo dopo almeno 2 caratteri
- Lista limitata a 3-5 risultati visuali, con default 5
- Deduplica per testo normalizzato (`trim + lowercase + spazi compressi`)
- Valori vuoti e testo identico a quello già inserito esclusi
- Tap su chip sostituisce il campo corrente e chiude la tastiera
- I chip vengono mostrati solo quando il relativo `FocusNode` ha focus
- Dopo una selezione spariscono; tornano al refocus del campo

**Titolo / Note**
- I suggerimenti sono costruiti a partire dai movimenti già presenti
- Ordinamento per rilevanza, frequenza e attività più recente
- Note usa la stessa UX compatta di Titolo per evitare tre pattern diversi

**Beneficiario**
- I suggerimenti combinano `beneficiaryProfiles` manuali e payee derivati dai movimenti
- I profili manuali hanno peso maggiore rispetto ai payee grezzi
- Le entry archiviate vengono escluse
- I chip non fondono automaticamente nomi simili: suggeriscono soltanto
- I duplicati esatti vengono deduplicati tramite normalizzazione

### Add/Edit Movement flow

> `AddMovementFlow` è il percorso guidato corrente per creazione e modifica con prefill.

**File:** `lib/widgets/add_movement_flow.dart`, `lib/widgets/movement_picker.dart`

**Struttura**
- Step: categoria → sottocategoria → conto / conti transfer → dettagli
- `MovementPicker` delega ad `AddMovementFlow` per il branch guidato
- `prefill` abilita il percorso edit senza cambiare il motore del form

**Polish attuale**
- Header compatto top con indietro, `X`, e conferma sempre visibili
- Il submit top usa `_submit()` come il bottone finale: nessun doppio percorso logico
- `_amountCtrl` è condiviso tra display principale, validation ed eventuale sticky compact amount
- `_showStickyAmount` si attiva su scroll verticale del dettaglio e mostra un riepilogo compatto sincronizzato
- Validazione amount via `AmountExpressionEvaluator` con normalizzazione a 2 decimali
- Nessuna conversione valuta nel form: la preferenza globale cambia solo la formattazione UI

### Currency preference / formatter

> La valuta è una preferenza visuale globale, non una modifica allo schema dati.

**File:** `lib/data/preferences_service.dart`, `lib/utils/currency_formatter.dart`, `lib/screens/settings_screen.dart`

**Comportamento**
- `AppCurrency` è persistita in `SharedPreferences`
- `currencyNotifier` notifica le schermate che mostrano importi
- `SettingsScreen` espone la card `Valuta` con picker dedicato
- `formatMovementCurrency(...)` centralizza il rendering degli importi fuori dal campo di input
- La scelta della valuta cambia solo il simbolo/formattazione, non i valori memorizzati

### iFinance CSV import — transfer pairing hardening

> Il pairing transfer ora separa meglio i veri transfer dai movimenti normali e lascia ambigui solo i casi non risolvibili in modo univoco.

**File:** `lib/services/ifinance_csv_import_service.dart`
**Test:** `test/ifinance_csv_import_test.dart`

**Riconoscimento transfer**
- `IFinanceCsvRow.isLikelyTransfer()` usa un haystack combinato:
  - `title`
  - `payee`
  - `labels`
  - `categoryRaw`
  - `categoryParent`
- Scopo: riconoscere anche export dove la parola `Trasferimento` non sta solo nel titolo

**Strategia di pairing**
- Chiave gruppo: `data + abs(importo)`
- Caso semplice:
  - se il gruppo contiene esattamente `1` riga negativa e `1` positiva
  - e i conti sono diversi
  - viene creato subito un `IFinanceTransferPair`
- Caso multi-match:
  - parsing di hint `Trasferimento da ...` / `Trasferimento su ...`
  - normalizzazione del nome conto anche con suffissi parentetici
  - costruzione grafo candidati coerenti con source/destination hint
  - accettazione solo se esiste un matching perfetto univoco
- Se il matching completo non è univoco, il gruppo resta in `ambiguousTransfers`

**Dedupe**
- I transfer accoppiati usano fingerprint coerente con:
  - `MovementType.transfer`
  - account sorgente
  - account destinazione
  - titolo
  - nota
- Il reimport dello stesso CSV salta correttamente sia i movimenti normali sia i transfer già importati

**Metadati preview**
- `IFinanceImportPreview` espone anche:
  - `transferCandidateRows`
  - `ambiguousTransferGroups`
- La UI preview può distinguere tra:
  - righe candidate transfer
  - righe ambigue residue
  - gruppi realmente ambigui

**Vincoli preservati**
- Nessun dialog Beneficiari durante import iFinance
- `movement.payee` resta il raw importato
- note/commenti rimangono puliti, senza metadati sporchi aggiunti dal pairing

### Profili separati / isolamento dati reale

> Ogni profilo utente punta a un database SQLite distinto. Lo switch profilo cambia davvero il DB attivo e ricrea lo scaffold principale per evitare bleed di stato.

**File principali**
- `lib/models/profile.dart`
- `lib/services/profiles_controller.dart`
- `lib/services/profile_service.dart`
- `lib/main.dart`
- `lib/screens/profiles_screen.dart`
- `lib/screens/profile_picker_screen.dart`

**Registry**
- Persistenza file-based `profiles.json`
- Contiene:
  - lista profili
  - `activeProfileId`
  - `dbFileName` per profilo
- Regole:
  - profilo `main` → `stream.db`
  - profili secondari → `stream_profile_<profileId>.db`
  - healing automatico di registry corrotti:
    - secondario con `stream.db`
    - `dbFileName` duplicati
    - `dbFileName` vuoti
    - `activeProfileId` non valido

**App root**
- `main()` inizializza `ProfileService`
- `ProfileAwareStreamApp` apre il DB del profilo attivo
- allo switch:
  - salva il nuovo `activeProfileId`
  - apre il nuovo SQLite path
  - inizializza un nuovo `AppDatabase`
  - chiude il DB precedente

**Protezione anti-stale DB**
- `MainScaffold` usa `ValueKey('main_scaffold_$activeProfileId')`
- `_MainScaffoldState` usa `widget.db` direttamente
- nessun `late final` con `AppDatabase` persistito tra profili

**Isolamento verificato**
- movimenti separati per profilo
- reset dati limitato al profilo attivo
- beneficiari separati per profilo
- import iFinance separato per profilo
- `BackupScreen` e `Importa CSV iFinance` restano accessibili anche senza callback profili

### Archive / restore / category delete safety

**Conti**
- `AppDatabase.archiveAccount()` e `restoreAccount()` aggiornano RAM + SQLite preservando `iconKey`, `color`, `createdAt`
- `SQLiteService.restoreAccount()` esiste e fa flip di `archived = 0`

**Categorie / sottocategorie**
- Archive/restore mantiene icona, colore e relazioni esistenti
- `reassignMovementsAndDeleteCategory(...)` accetta solo target non archiviato e dello stesso `MovementType`
- La riassegnazione pulisce `subcategoryId` a `null` per evitare riferimenti orfani
- Il branch SQLite usa `transaction(...)` per update movimenti + delete sottocategorie + delete categoria

| File | Prima (V0.6.1) | Dopo (V0.6.2) |
|------|----------------|----------------|
| `daily_group.dart` (within-group) | `updatedAt desc → createdAt desc → id asc` | `compareMovementsForDisplay` |
| `time_filter.dart` (filterByTime) | `date desc → createdAt desc` | `date desc → compareMovementsForDisplay` |
| `database.dart` (lastMovements) | `date desc → createdAt desc` | `date desc → compareMovementsForDisplay` |

**Metodo di istanza**: `Movement.compareForDisplay(other)` — delega alla top-level function.

### Ordinamento Gruppi Giorno (V0.6.2 fix)

- **Problema**: chiave `"2026-6-8" > "2026-6-12"` per confronto lessicografico (8 > 1 a parità di prefisso)
- **Fix**: zero-padding con `padLeft(2, '0')` → `"2026-06-08" < "2026-06-12"`
- **File**: `lib/models/daily_group.dart:35`

### Dashboard insight-only (V0.6.2)

- Rimosso `_FilteredMovementsList` dalla Dashboard
- Resta solo: KPI periodici + Spese per categoria + dettaglio categoria bottom sheet (con `GroupedMovementsList`)
- **Vincolo**: nessuna lista movimenti in Dashboard — V0.5.6 decision restored

### Ricerca Globale Movimenti (V0.6.3)

- Helper: `lib/utils/movement_search.dart`
- Ricerca in-memory, senza FTS / SQLite full-text search
- Campi cercati:
  - title
  - note
  - category name
  - account name
- Match case-insensitive, con trim e matching parziale
- Combinabile con `TimeFilter` già esistente
- Risultati renderizzati con `GroupedMovementsList`

### Rapidi / Preferiti con scelta data (V0.6.4)

- La scelta data avviene prima del salvataggio del template
- Opzioni UX:
  - Oggi
  - Ieri
  - Domani
  - Scegli data
- `StreamDatePicker` riusato per la scelta custom
- `Movement.date` viene valorizzata dalla scelta utente
- `createdAt` / `updatedAt` restano la data tecnica di creazione o modifica

### Form movimento: label condizionale

- Entrata / Uscita → `Conto`
- Trasferimento → `Conto origine`
- La label dinamica evita ambiguità nel form manuale senza introdurre un secondo flusso

### DayHeader overflow fix (V0.6.2)

- **Problema**: Row riepilogo (Entrate/Uscite/Saldo) overflowava in `DraggableScrollableSheet` stretto (iPhone)
- **Fix**: `FittedBox(boxFit.scaleDown)` sul Row
- **File**: `lib/widgets/day_header.dart:74`

### HeatmapSettings Architecture (V0.8.7)

> Soglie e colori heatmap configurabili, persistiti via SharedPreferences, aggiornamento live della heatmap.

**File**: `lib/utils/heatmap_utils.dart` — classe `HeatmapSettings`
**Prefs**: `heatmap_thresholds` (List<String> di double), `heatmap_colors` (List<String> di int)
**Notifier**: `PreferencesService.heatmapSettingsNotifier` (ValueNotifier<HeatmapSettings>)
**Default soglie**: `[1, 5, 20, 50, 150, 500]`
**Default colori**: 7 gradazioni verde→rosso + grigio (palette invariata rispetto a V0.8.5)

**Flusso di caricamento**:
1. `MovementsScreen.initState()` chiama `PreferencesService.loadHeatmapSettings()` per inizializzare il notifier
2. `ExpenseHeatmap` e `HeatmapLegend` usano `ValueListenableBuilder<HeatmapSettings>` wrappato attorno a `PreferencesService.heatmapSettingsNotifier`
3. La UI si ricostruisce automaticamente quando il notifier cambia

**Validazione**:
- `HeatmapSettings.isValid` → soglie positive/crescenti + colors.count == thresholds.length + 1
- `HeatmapSettings.validateThresholds(List<double>)` → statico, riusato nell'editor
- `saveHeatmapSettings()` → salva solo se `isValid`, altrimenti return false
- `loadHeatmapSettings()` → fallback a default se prefs corrotte (parse fallito o isValid false)

**Separazione Treemap**:
- `CategoriesTreemap` continua a usare `category.color` — non coinvolta da `HeatmapSettings`
- Scelta architetturale: la heatmap Movimenti è una metrica di spesa per giorno, la treemap Categorie è una metrica per categoria con colori indipendenti

**`clearForReset()`**:
- Non pulisce le preferenze heatmap (scelta deliberata)
- Le impostazioni visive (soglie, colori) sopravvivono al reset dati, come aspetto UI
- L'utente può sempre usare "Ripristina default" nella sezione Heatmap di Impostazioni

### Subcategories Architecture (V0.8.8)

> Nuova entità Subcategory per gerarchia Categoria → Sottocategoria. DB v9.

**Modello:** `lib/models/subcategory.dart`
- `id` (UUID v4), `categoryId`, `name`, `iconKey?`, `color?`, `archived`, `createdAt`, `updatedAt`
- `iconKey` e `color` sono opzionali: se null la sottocategoria eredita dalla categoria madre
- `UNIQUE(category_id, name)` in SQL — stesso nome sotto categorie diverse è permesso

**DB (v9/v10):**
```sql
CREATE TABLE subcategories (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  name TEXT NOT NULL,
  icon_key TEXT,
  color INTEGER,
  archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE UNIQUE INDEX idx_subcategories_unique ON subcategories(category_id, name);
```
- Colonne `subcategory_id TEXT` nullable aggiunte a `movements`, `quick_movements`, `favorite_movements`
- Migrazione v10: aggiunta colonne `icon_key` e `color` a `subcategories`
- Nessuna FK SQLite — validazione applicativa coerente con lo schema attuale
- `resetAllData` cancella anche `subcategories`

**Backup/Restore:**
- `BackupData` include `subcategories` come lista opzionale (backup version 2 invariato)
- `_normalizeSubcategoryId` azzera subcategoryId se orfano o categoria mismatch
- Restore vecchio JSON senza subcategories funziona senza modifiche

**UI:**
- Categories screen: `_SubcategorySection` nel dialog categoria (aggiungi/rinomina/archivia/ripristina)
- Dialog modifica sottocategoria: salva nome, icona e colore in un solo update
- Movement form / picker: selector unificato `Categoria / Sottocategoria`
- Movimenti nulli `subcategoryId` in tutti i form — obbligatorio solo se una subcategory è selezionata

### Category / Subcategory Selector UX

> Selector gerarchico riusabile introdotto per eliminare la duplicazione tra categoria e sottocategoria nei form movimento.

**File:** `lib/widgets/category_subcategory_selector.dart`

**Contract UI / test keys:**
- field: `movement_category_subcategory_field`
- picker: `category_subcategory_picker`
- search: `category_subcategory_search_field`

**Regole:**
- mostra solo categorie e sottocategorie attive del `MovementType` corrente
- la categoria madre resta selezionabile anche se ha figli
- una sottocategoria selezionata salva:
  - `categoryId = parent.id`
  - `subcategoryId = child.id`
- una categoria madre selezionata salva:
  - `categoryId = parent.id`
  - `subcategoryId = null`
- ricerca su categoria e sottocategoria
- label combinata standard: `Categoria / Sottocategoria`

**Punti d'uso correnti:**
- `lib/widgets/movement_form.dart`
- `lib/widgets/movement_picker.dart`:
  - form manuale
  - rapidi
  - preferiti
- `lib/widgets/movement_card.dart` per il rendering combinato

**Completato (V0.8.9):**
- Conversione manuale categorie flat con parentesi (V0.8.9 ✅)
- Suggeriti espandibili/raggruppati per categoria (V0.8.9 ✅)
- Heatmap palette comune (V0.8.9 ✅)

**Non implementato:**
- CSV import 1Money sottocategorie (tbd)
- Budget/Actual/Scenari con subcategories (V0.9.2+)

### Category Conversion Architecture (V0.8.9)

> Servizio per convertire una categoria flat (es. `Spesa (Alimentari)`) in categoria madre + sottocategoria.

**Modello:** `lib/models/category.dart`
- `isConvertibleCategory` — getter safe (non crasha su nomi senza parentesi)
- Pattern match: `r'^(.+)\s\((.+)\)$'` — estrae `categoryName` e `subcategoryName`

**Servizio:** `lib/domain/category/services/category_conversion_service.dart`
- `CategoryConversionService.convert(db, Category)` → `CategoryConversionReport`
- Logica:
  1. Cerca/crea categoria madre per nome
  2. Cerca/crea sottocategoria sotto la madre
  3. Riassegna movimenti: `movement.categoryId` e `movement.subcategoryId`
  4. Riassegna QuickMovements: `quick.categoryId` e `quick.subcategoryId`
  5. Riassegna FavoriteMovements: `favorite.categoryId` e `favorite.subcategoryId`
  6. Archivia categoria flat (`archivedAt`), non elimina
  7. Restituisce report con conteggi (movements, quick, favorite)

**Helper:** `lib/domain/category/services/category_migration_service.dart`
- `findOrCreateParentCategory()` — cerca per nome o crea
- `findOrCreateSubcategory()` — cerca per nome+categoryId o crea

**Pattern tipo-lock:** Una categoria con movimenti collegati non può cambiare tipo. Il messaggio in UI è esplicito: "Puoi modificare nome, colore e icona. Il tipo non è modificabile per via dei movimenti collegati."

**Conversione morbida:** La categoria flat viene archiviata (non eliminata), preservando storico e relazioni. Il report strutturato `CategoryConversionReport` fornisce conteggi dettagliati.

**UI:**
- Tutti e 3 i layout categorie (clean list, grouped, card stream) mostrano l'azione nel popup menu
- `CategoryMovementsSheet` ha pulsante "Converti in sottocategoria"
- `CategoryEditPage` mostra card di conversione nella parte superiore

### Note tecniche aperte

- DB version corrente: **v10** (da V0.8.8; nessuna migrazione in V0.8.10)
- Migration V6: rumore `duplicate column name: date` nei test, ma non blocca
- Warning futuro Kotlin Gradle Plugin su `file_picker` / `package_info_plus` / `share_plus`

### TimeFilterMode.week (V0.8.10)

> Introdotto filtro periodo settimana per Movimenti.

**File:** `lib/models/time_filter.dart`

- `TimeFilterMode.week` — nuovo enum value tra `day` e `month`
- `TimeFilter.week(DateTime date)` — calcola:
  - `startDate = lunedì = date.subtract(Duration(days: date.weekday - 1))`
  - `endDate = domenica = startDate + 6 giorni`
- `label()` restituisce `"1–7 giugno 2026"` (giorno + mese del range)
- `next()` somma 7 giorni, `previous()` sottrae 7 giorni

**TimeFilterBar:**
- Nuovo segmento `Sett.` tra `Giorno` e `Mese`
- Navigazione frecce opera su blocchi di 7 giorni

### formatEuro() (V0.8.10)

> Funzione di formattazione euro al centesimo per tutti i KPI principali.

**File:** `lib/utils/heatmap_utils.dart`

```dart
String formatEuro(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '$intPart,${parts[1]} €';
}
```

- Formatta: `11842.35` → `11.842,35 €`
- KPI principali (Entrate/Uscite/Saldo) usano questo formato
- Micro-label heatmap possono restare compatte dove lo spazio è limitato (scelta pre-V0.8.10 preservata)

### PeriodHeatmapCard behavior per mode (V0.8.10)

> Widget principale per tutte le viste periodo premium.

**File:** `lib/widgets/period_heatmap_card.dart`

**Props aggiunte:** `subcategories` (List<Subcategory>?), `selectedPeriodDay` (DateTime?), `onClearSelectedDay` (VoidCallback?)

**Mode behavior:**
- **Day** (`_buildDaySurface`): header OGGI/GIORNO + data italiana + pill Giorno + chip metrici (prima uscita, ultima uscita, categoria top, conteggio movimenti) + KPI Entrate/Uscite/Saldo + sezione `_DayExpenseBreakdown` (barre proporzionali per categoria + tasto "Vedi dettaglio" → `_DayExpenseDetailSheet`)
- **Week** (`_buildWeekSurface`): KPI + heatmap 7 giorni con importo per cella + expense breakdown; se `selectedPeriodDay != null`: chip giorno selezionato + "Tutta settimana"
- **Month** (`_buildMonthSurface`): KPI + `ExpenseHeatmap` a calendario + `PeriodCategoryTreemap`; se `selectedPeriodDay != null`: chip giorno selezionato + "Tutto mese"
- **Year** (`_buildYearSurface`): KPI annuali + `AnnualHeatmapCard` + category treemap; se `selectedPeriodDay != null`: chip giorno selezionato + "Tutto anno"
- **Range** (`_buildRangeSurface`): KPI + heatmap a 3 livelli:
  - ≤31 giorni = griglia giorni
  - 32–183 giorni = griglia settimanale compatta
  - **>183 giorni = blocchi semestrali** (Gen–Giu / Lug–Dic, con _RangeSemesterGrid)
  - Se `selectedPeriodDay != null`: chip giorno selezionato + "Tutto intervallo"

**Day tap navigation:**
- `onDaySelected` callback collegata in tutti i mode a `_onHeatmapDayTap()` in `MovementsScreen`
- **Per Day**: flusso → `selectedDay = day` → `timeFilter = TimeFilter.day(day)` → aggiorna `visibleCalendarMonth`
- **Per Week/Month/Year/Range**: flusso unificato → imposta `_selectedPeriodDay` → **NON** cambia `_activeFilter`

### Semester blocks architecture (V0.8.10)

> Heatmap a blocchi semestrali per range intervallo >183 giorni.

**File:** `lib/widgets/period_heatmap_card.dart`

**Soglia:** `> 183 giorni` (6 mesi, verificata come `end.difference(start).inDays > 183`)

**Funzione:** `_buildSemesterRangeGrid(DateTime start, DateTime end, DateTime? effectiveSelectedDay)`

**Classe:** `_RangeSemesterGrid` — modellata su `_SemesterGrid` di `AnnualHeatmapCard`

**Regole:**
- Divide il range in blocchi semestrali fissi: Gen–Giu, Lug–Dic
- Per ogni semestre tra `start` e `end` crea una `_RangeSemesterGrid`
- Ogni `_RangeSemesterGrid` gestisce internamente giorni fuori range come `null`
- Supporto cross-year: range Nov 2025–Apr 2026 mostra 2 semestri (Lug–Dic 2025, Gen–Giu 2026)
- Supporto semestri parziali: range che inizia/finisce a metà semestre mostra solo giorni entro il range
- `effectiveSelectedDay` passato per highlighting giorno selezionato

**Parametri `_RangeSemesterGrid`:**
| Prop | Tipo | Descrizione |
|------|------|-------------|
| start | DateTime | Inizio semestre (fisso a 1° gen/1° lug) |
| end | DateTime | Fine semestre (fisso a 30 giu/31 dic) |
| rangeStart | DateTime | Inizio effettivo del range utente |
| rangeEnd | DateTime | Fine effettiva del range utente |
| movements | List<Movement> | Movimenti filtrati per l'intervallo |
| categories | List<Category> | Categorie per risoluzione colori |
| db | AppDatabase | Per metadati aggiuntivi |
| selectedDay | DateTime? | Giorno evidenziato (effectiveSelectedDay) |
| onDaySelected | Function(DateTime) | Callback tap giorno |

### Period day selection behavior (V0.8.10)

> Tap giorno nella heatmap Week/Month/Year/Range non cambia filtro (solo Day cambia).

**File:** `lib/screens/movements_screen.dart`

**Stato:** `DateTime? _selectedPeriodDay` in `_MovementsScreenState` (generalizzato da `_selectedRangeDay`)

**Flusso:**
- `_onHeatmapDayTap(day)`: switch su `_activeFilter.mode`
  - `TimeFilterMode.day` → flusso classico: `selectedDay = day`, `TimeFilter.day(day)`, aggiorna `visibleCalendarMonth`
  - `TimeFilterMode.week/month/year/customRange` → imposta `_selectedPeriodDay`, **NON** tocca `_activeFilter`
- `_setActiveFilter(filter)`: azzera `_selectedPeriodDay`
- `_clearSelectedPeriodDay()`: azzera `_selectedPeriodDay` e ricarica la lista

**Passaggio a MovementViewRenderer:**
- `selectedPeriodDay` passato come prop a `MovementViewRenderer` → `PeriodHeatmapCard` → `_MovementPanel`
- `_MovementPanel.build()` calcola `effectiveMovements`: se `selectedPeriodDay != null` filtra per quel giorno, altrimenti movimenti del periodo

**EffectiveSelectedDay:**
- Calcolato in ogni surface builder come `selectedPeriodDay ?? selectedDay`
- Passato a tutte le griglie heatmap per highlighting
- Evita duplicazione logica tra range e non-range

### GroupedMovementsList in panel mode (V0.8.10)

> Lista movimenti raggruppata per giorno anche in Calendar/Heatmap (panel mode).

**File:** `lib/widgets/grouped_movements_list.dart`

**Nuovi parametri:**
| Prop | Tipo | Default | Descrizione |
|------|------|---------|-------------|
| shrinkWrap | bool | false | Per uso dentro altro scrollable (Calendar/Heatmap column) |
| physics | ScrollPhysics? | null | ScrollPhysics custom per contenimento |

**Utilizzo in panel mode:**
- `_MovementPanel._buildMovementsList()` ora usa `GroupedMovementsList(shrinkWrap: true)` invece di flat `ListView.separated`
- Entrambi i rami (con/senza topWidget) supportano `shrinkWrap` e `physics`

### DayHeader migliorato (V0.8.10)

> Label Oggi/Ieri, conteggio movimenti, mese+anno.

**File:** `lib/widgets/day_header.dart`

**Modifiche:**
- Label "Oggi" se `day == today`, "Ieri" se `day == today - 1`, altrimenti giorno della settimana
- Conteggio movimenti mostrato nell'header (es. "3 movimenti")
- Rimosso anno-mese non più usato (V0.8.10)
- **Aggiunto mese+anno sotto il weekday (delta date chiare)**: es. `giugno 2026` sotto `MERCOLEDÌ`

### Date più chiare nei periodi/giorni (delta)

> `TimeFilter.customRange.label` ora include l'anno; `DayHeader` mostra mese+anno.

**File:** `lib/models/time_filter.dart` (linea 91), `lib/widgets/day_header.dart`

**Modifiche:**
- `TimeFilter.customRange.label`: `shortFmt` ora produce `"15 giu 2026 → 30 giu 2026"` invece di `"15 giu → 30 giu"`
- `DayHeader`: aggiunto `_monthNames` statico, mese+anno renderizzato sotto il weekday con `Text('${_monthNames[group.date.month - 1]} ${group.date.year}')`
- Obiettivo UX: evitare ambiguità temporali quando si navigano Giorno/Settimana/Mese/Anno/Intervallo

### Dialog propagazione stile categoria (delta)

> Dialog con checkbox per selezionare le sottocategorie a cui applicare il nuovo colore/icona.

**File:** `lib/screens/categories_screen.dart` — classi `_CategoryPropagateStyleDialog`, `_CategoryPropagateStyleDialogState`

**Trigger:** Si attiva in `_CategoryFormDialogState._save()` quando:
- Si sta modificando una categoria esistente (`widget.existing != null`)
- La categoria ha sottocategorie (`subcategories.isNotEmpty`)
- Colore O icona sono cambiati rispetto al valore originale

**UI:**
- `StatefulBuilder` con checkbox per ogni sottocategoria
- Preselezione smart: sottocategorie ereditarie (`color == null || color == oldColor && iconKey == null || iconKey == oldIconKey`) selezionate di default
- Azioni rapide: Seleziona tutte, Deseleziona tutte, Solo ereditarie
- Azioni finali: Annulla (restituisce `null` → non salva), Solo categoria (restituisce `{}` → solo madre), Applica alle selezionate (restituisce `Set<String>` dei subcategoryId selezionati)
- Subtitle per ogni checkbox descrive lo stato attuale (es. "colore ereditato", "icona personalizzata")

**`updateCategory` modificato:**
- Nuovo parametro opzionale: `Set<String>? propagateToSubcategoryIds`
- Se valorizzato (anche vuoto): la logica automatica inherit-based viene saltata; vengono aggiornate SOLO le sottocategorie i cui `id` sono presenti nel set
- Se null (comportamento storico): la logica inherit-based preesistente rimane attiva
- Nessuna migration DB

### ListenableBuilder in SubcategorySection (V0.8.10)

> Refresh immediato dialog sottocategorie senza uscire/rientrare.

**File:** `lib/screens/categories_screen.dart`

**Modifica:**
- `_SubcategorySection.build()` avvolto in `ListenableBuilder(listenable: widget.db)`
- Qualsiasi `notifyListeners()` sul database ricostruisce la UI automaticamente
- Non richiede `setState` manuale su archive/restore/create/delete sottocategoria

### deleteSubcategoryCascade (V0.8.10)

> Eliminazione sicura sottocategoria con spostamento movimenti alla categoria madre.

**File:** `lib/data/database.dart`

**Comportamento aggiornato:**
- Azzera `subcategoryId` in 3 tabelle in-memory:
  - `_movements`: `movement.copyWith(subcategoryId: null, updatedAt: DateTime.now())`
  - `_quickMovements`: crea `QuickMovement` con `subcategoryId: null`
  - `_favoriteMovements`: crea `FavoriteMovement` con `subcategoryId: null`
- Mantiene `categoryId` invariato — il movimento resta sotto la categoria madre

**Helper aggiunti:**
- `subcategoryQuickCount(String subcategoryId)` → conteggio movimenti rapidi associati
- `subcategoryFavoriteCount(String subcategoryId)` → conteggio movimenti preferiti associati

### updateCategory color/icon propagation (V0.8.10)

> Propagazione colore/icona alle sottocategorie che li ereditano.
> **Aggiornato:** condizione estesa per coprire anche ereditarietà pura (null).

**File:** `lib/data/database.dart`

**Logica:**
1. Dopo `_categories[index] = updated`, scorre tutte le sottocategorie
2. Per ogni sottocategoria della stessa `categoryId`:
   - Se `sc.color == null || sc.color == old.color` → aggiorna al nuovo colore (ereditarietà pura + vecchio colore madre)
   - Se `sc.iconKey == null || sc.iconKey == old.iconKey` → aggiorna al nuovo iconKey (ereditarietà pura + vecchia icona madre)
   - Se personalizzazione diversa → preservata
3. Per ogni sottocategoria modificata: chiama `_sqlite.updateSubcategory(updatedSub)`
4. Singolo `notifyListeners()` alla fine

**Vincolo rimosso:** la condizione originale `sc.color != null && sc.color == old.color` non copriva le sottocategorie con `null` (ereditarietà pura). Ora `sc.color == null || sc.color == old.color` aggiorna sia quelle con null sia quelle con colore esplicito uguale al vecchio colore madre.

**Ultima rifinitura:** `updateCategory` mantiene in modo esplicito `oldCategoryColor`, `oldCategoryIconKey`, `newCategoryColor`, `newCategoryIconKey`, così la regola di update sulle sottocategorie ereditate è leggibile e testabile.

### Immediate UI refresh for inherited subcategory style

> Il bug residuo non era solo nel dato aggiornato ma in alcune UI agganciate a snapshot vecchi.

**File:** `lib/screens/categories_screen.dart`, `lib/widgets/movement_form.dart`, `lib/widgets/movement_picker.dart`

**Intervento:**
- `categories_screen` rilegge i dati aggiornati dal DB notificato
- `_CategoryMovementsSheet` calcola categoria e movimenti dentro `ListenableBuilder`
- `_CategoryFormDialog` dopo `await widget.db.updateCategory(...)` esegue `if (!mounted) return` e `setState(() {})`
- `MovementForm` e i form di `MovementPicker` ascoltano `widget.db` mentre renderizzano `CategorySubcategorySelector`

**Effetto UX:**
- lista categorie e righe sottocategorie si riallineano subito
- category sheet/dialog non resta con valori vecchi
- movement form / movement picker / movement card riflettono subito il nuovo colore o la nuova icona della madre se la sottocategoria la eredita
- non serve uscire/rientrare

### _DayExpenseBreakdown / _DayExpenseDetailSheet (V0.8.10)

> Widget per la ripartizione spese nella vista Giorno.

**File:** `lib/widgets/period_heatmap_card.dart`

- `_DayExpenseBreakdown`: widget inline nella card giorno
  - Raggruppa le uscite del giorno per `categoryId`
  - Mostra barra proporzionale (`LinearProgressIndicator`) per ogni categoria
  - Colore e icona risolti da `categories` prop (fallback `Color(0xFF888888)` / `Icons.category`)
  - Tasto "Vedi dettaglio" apre `_DayExpenseDetailSheet`
- `_DayExpenseDetailSheet`: `DraggableScrollableSheet`
  - Lista movimenti spesa del giorno ordinati per importo decrescente
  - Ogni riga: icona categoria + titolo + sottocategoria (se presente) + importo + mini-barra percentuale
  - Barra percentuale con colore categoria su sfondo trasparente

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

## Dashboard Net Worth Account Selection (V0.11k)

### Preferenza
- Chiave scoped: `dashboard_net_worth_account_ids_<profileId>` (SharedPreferences)
- La chiave globale legacy `dashboard_net_worth_account_ids` non deve piu essere creata dai flussi di backup/restore Patrimonio
- Tipo: `List<String>` (serializzata come `Set<String>?`)
- null/assente/empty = Tutti i conti
- Notifier: `PreferencesService.netWorthAccountIdsNotifier`
- Metodi: `loadDashboardNetWorthAccountIds()`, `saveDashboardNetWorthAccountIds()`, `clearDashboardNetWorthAccountSelection()`

### Backup/restore profile-safe (V0.11k-fix5)
- `BackupService.exportToJson(..., activeProfileId:)` legge `netWorthAccountIds` solo dal profilo corrente
- `BackupService.restore(..., activeProfileId:)` salva o pulisce `netWorthAccountIds` solo sul profilo corrente dopo sanitize contro i conti validi post-restore
- `BackupScreen` riceve `activeProfileId` da `SettingsScreen` e lo propaga a export, pre-restore backup e restore
- Fallback sicuro: se `activeProfileId` e nullo, il restore non tocca chiavi patrimonio persistite e riallinea solo `netWorthAccountIdsNotifier` a `null`

### Calcolo patrimonio
- In `_DashboardScreenState.build()`: i `selectedAccounts` sostituiscono `activeAccounts`
- `accountsBalance` = somma di `db.getAccountBalance(a)` per ogni conto selezionato
- Pill conti hero (`_HeroStacked`/`_HeroSplit`) ricevono solo i conti selezionati

### Healing
- Conti archiviati o eliminati vengono esclusi dalla selezione
- Se nessun conto valido resta selezionato → torna a Tutti i conti

### Key testabili
- `dashboard_net_worth_account_filter_button` — bottone filtro nella hero
- `dashboard_net_worth_account_filter_sheet` — bottom sheet selezione
- `dashboard_net_worth_all_accounts_option` — opzione Tutti i conti
- `dashboard_net_worth_account_option_<id>` — checkbox per ogni conto
- `dashboard_net_worth_account_filter_apply` — Applica
- `dashboard_net_worth_account_filter_cancel` — Annulla

## Movimenti Scoped Filters (V0.11l-a)

### Preferenze
- Chiavi scoped:
  - `movements_filter_account_ids_<profileId>`
  - `movements_filter_category_ids_<profileId>`
- Tipo: `List<String>` persistita come `Set<String>?`
- `null` / assente / insieme vuoto = nessun filtro attivo
- Notifier:
  - `PreferencesService.movementsAccountFilterIdsNotifier`
  - `PreferencesService.movementsCategoryFilterIdsNotifier`
- Metodi:
  - `loadMovementsAccountFilterIds({required profileId})`
  - `saveMovementsAccountFilterIds(Set<String>? ids, {required profileId})`
  - `loadMovementsCategoryFilterIds({required profileId})`
  - `saveMovementsCategoryFilterIds(Set<String>? ids, {required profileId})`

### Wiring
- `MainScaffold` passa `activeProfileId` a `ArchiveScreen`
- `ArchiveScreen` passa `activeProfileId` a `MovementsScreen`
- `MovementsScreen` carica i filtri scoped in `initState()` e al cambio profilo in `didUpdateWidget()`

### Regole filtro
- Conti:
  - entrata/uscita passa se `movement.accountId` appartiene all'insieme selezionato
  - transfer passa se il set selezionato contiene `accountId` (origine) **oppure** `destinationAccountId` (destinazione)
- Categorie:
  - entrata/uscita passa se `movement.categoryId` appartiene all'insieme selezionato
  - transfer con `categoryId` vuoto viene escluso quando il filtro categorie e attivo
- Composizione:
  - filtro conti e filtro categorie si combinano in `AND`
  - nessun impatto su Dashboard, Grafici, Calendario o altre schermate

### Sanitize / reset
- Gli ID non piu validi o archiviati vengono rimossi automaticamente dalla preferenza del profilo corrente
- `clearForReset(activeProfileId: ...)` elimina solo:
  - `movements_filter_account_ids_<activeProfileId>`
  - `movements_filter_category_ids_<activeProfileId>`
- Reset senza `activeProfileId` non tocca le chiavi scoped di altri profili

### Key testabili
- `movements_filters_section`
- `movements_account_filter_button`
- `movements_category_filter_button`
- `movements_account_filter_sheet`
- `movements_account_filter_all_option`
- `movements_account_filter_option_<accountId>`
- `movements_account_filter_apply`
- `movements_account_filter_cancel`
- `movements_category_filter_sheet`
- `movements_category_filter_all_option`
- `movements_category_filter_option_<categoryId>`
- `movements_category_filter_apply`
- `movements_category_filter_cancel`

### UI (V0.11l-a-fix1)
- Le categorie nel bottom sheet sono raggruppate in sezioni "Uscite" (expense) ed "Entrate" (income)
- Header sezioni: `StreamTypography.h3`
- Se una sezione e vuota, l'header non viene mostrato
- La lista scrollabile usa `ConstrainedBox(maxHeight: 55% viewport)` + `SingleChildScrollView` per viewport piccoli
- Helper methods: `_expenseCategories()`, `_incomeCategories()`, `_buildCategoryOption(Category, Set<String>, VoidCallback, StreamThemePalette)`
- Import aggiunto: `stream_theme_palette.dart` (per `StreamThemePalette` nel parametro)
- Selezione mista expense+income ancora supportata; logica filtro invariata

## Tab Segmented single-line fix (V0.11k)
- Label dei `SegmentedButton` in `TimeFilterBar` avvolte in `FittedBox(fit: BoxFit.scaleDown, child: Text(maxLines:1, softWrap:false))`
- Previene wrapping di `Intervallo` su viewport stretti

## Archive Top Tabs Single-Line (V0.11k-fix1)
- `lib/screens/archive_screen.dart`: `SegmentedButton<int>` con 4 segmenti (`Movimenti`, `Conti`, `Categorie`, `Benefic.`).
- Ogni `ButtonSegment.label` ora contiene `FittedBox(fit: BoxFit.scaleDown, child: Row(children: [Icon(size:14), Text(maxLines:1, softWrap:false)]))`.
- `icon` parameter del `ButtonSegment` impostato a `SizedBox.shrink()` (icona gia dentro il label).
- Previene wrapping di `Movimenti`, `Categorie`, `Benefic.` su viewport stretti.

## Form azioni unificate (V0.11k)
- `AddMovementFlow`: rimosso `FilledButton` bottom (`movement_submit_button`). L'azione primaria rimane `movement_submit_top_button` nell'header.
- `MovementForm`: aggiunto `movement_form_save_action` in alto, rimosso `FilledButton` bottom `Salva`.
- `submitMovement()` helper in `calculator_test_helpers.dart`: fallback `movement_submit_top_button` → `movement_form_save_action` → legacy FilledButton text.

## Metriche

| Metrica | V0.6.4 | V0.7.0 | V0.7.1 | V0.8.0 | V0.8.1 | V0.8.2 | V0.8.3 | V0.8.4 | V0.8.5 | V0.8.6 | V0.8.7 | V0.8.8 | V0.8.9 | V0.8.10 | Delta |
|---------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| Test | 492 | 575 | 575 | 579 | 625 | 619 | 625 | 627 | 664 | 664 | 672 | 689 | 711 | 742 | 1104 |
| Analyze issues | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **0** | **0** | **0** |
| DB version | 6 | 6 | 6 | 6 | 6 | 6 | 6 | 6 | 6 | 6 | 6 | 9 | **9** | **10** | **10** |
| Build APK release | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
| Build iOS release | ⏳ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ | ⏳ |
