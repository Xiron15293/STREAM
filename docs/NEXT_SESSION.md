# NEXT SESSION — Stato Progetto e Priorità

> Aggiornato: 2026-06-14

---

## 1. Stato Attuale

| Componente | Versione | Stato |
|------------|----------|-------|
| Hermes V0.1 — MVP Base | Dashboard, Movimenti, Categorie | ✅ COMPLETATO |
| Hermes V0.2 — Speed Layer | Duplica, Rapidi, Preferiti, Suggeriti, Note | ✅ COMPLETATO |
| Hermes V0.3 — Fondamenta | SQLite, Persistenza, Conti | ✅ COMPLETATO |
| Hermes V0.3.1 — Modifica Movimento | Edit, Date picker, UPDATE SQL | ✅ COMPLETATO |
| Hermes V0.3.2 — Completamento | accountId fix + Confirm Delete + Categorie Editabili | ✅ COMPLETATO |
| Hermes V0.4 — Design System STREAM | Tema, Icone, Palette, Restyling, Database V4 | ✅ COMPLETATO |
| Hermes V0.5 — Calendario Foundation | Date movimenti, TimeFilter, Calendario, Archivio filtrato | ✅ COMPLETATO |
| Hermes V0.6.1 — Raggruppamento Giorno | GroupedMovementsList, DayHeader, riepilogo giornaliero | ✅ COMPLETATO |
| Hermes V0.6.2 — Ordinamento Centralizzato | Comparator unico + fix gruppi giorno | ✅ COMPLETATO |
| Hermes V0.6.3 — Ricerca Globale Movimenti | ricerca in-memory in Archivio > Movimenti | ✅ COMPLETATO |
| Hermes V0.6.4 — UX Rapidi/Preferiti Data Picker | Oggi / Ieri / Domani / Scegli data | ✅ COMPLETATO |
| Hermes V0.7.0 — Import CSV 1Money + Saldo Iniziale + Archivio Navigabile | Import CSV validato, saldo iniziale conti, conti/categorie cliccabili | ✅ COMPLETATO |
| Hermes V0.7.1 — QA Reset Stabilizzato | Test reset ripristinati e verdi | ✅ COMPLETATO |
| Hermes V0.8.0 — Calculator Pad | AmountExpressionEvaluator, CalculatorAmountField, fix tastiera nativa | ✅ COMPLETATO |
| Hermes V0.8.1 — Categories Layout Modes | Modello categoria, layout multipli, filtro Entrate/Uscite, KPI categorie | ✅ COMPLETATO |
| Hermes V0.8.2 — Financial KPI Corrections | Transfer esclusi dai KPI globali, helper centralizzati, Dashboard corretta | ✅ COMPLETATO |
| Hermes V0.8.3 — Date Filter Categories/Accounts | TimeFilter nelle schermate principali, saldo conto storico/as-of per periodo | ✅ COMPLETATO |
| Hermes V0.8.4 — Interactive Category/Account Menus | Sheet operativi con azioni rapide e prefill movimento/transfer | ✅ COMPLETATO |
| Hermes V0.8.5 — Movimenti Analytics / Heatmap | Lista, Calendario, Heatmap, search coerente, preview compatta | ✅ COMPLETATO |
| Hermes V0.8.6 — Category Treemap Analytics | Treemap stile market map in Categorie con filtri periodo e ordinamenti | ✅ COMPLETATO |
| Hermes V0.8.7 — Heatmap Settings | Soglie/colori heatmap configurabili, preview, restore defaults, SharedPreferences | ✅ COMPLETATO |
| Hermes V0.8.8 — Subcategories Foundation | Nuova entità Subcategory, DB v8→v9, subcategory_id nullable, backup/restore, UI categorie e form, fix UX nota rapida e soglie heatmap | ✅ COMPLETATO |
| Hermes V0.8.9 — Category Conversion & Suggested UX Polish | Fix crash menu categorie, categorie con movimenti modificabili, conversione manuale flat→sottocategoria, suggeriti espandibili/raggruppati, heatmap palette comune | ✅ COMPLETATO |
| Post V0.8.9 — Selector unico Categoria / Sottocategoria | Form manuale, rapidi, preferiti e rendering card riallineati; bug salvataggio sottocategoria coperto da test espliciti | ✅ COMPLETATO |
| **V0.8.10 — Period Views Premium + Subcategory Hardening** | **Filtro settimana, card giorno premium, tap giorno seleziona dentro periodo (Week/Month/Year/Range restano in modalità), chip giorno + reset contestuale per mode, _selectedPeriodDay generalizzato, expense breakdown, range premium, formatEuro, delete subcategory sicuro, propagazione colore/icona (condizione null), fix archive/restore** | ✅ **COMPLETATO** |
| Delta finale V0.8.10 — Refresh immediato madre → sottocategorie | `updateCategory` esplicito con old color/icon, UI riallineata via `ListenableBuilder`/`setState`, refresh immediato in categories screen, sheet/dialog, movement form/picker | ✅ COMPLETATO |
| **Delta date formatting + propagation dialog** | **Date più chiare (customRange con anno, DayHeader mese+anno) + dialog propagazione stile categoria con checkbox sottocategorie selezionabili** | ✅ **COMPLETATO** |
| **V0.9.0e — Beneficiari audit finale** | **Creazione manuale `BeneficiaryProfile`, merge profili+payee derivati, proposta salvataggio da movement form/picker, display metadata su MovementCard, dettaglio tappabile, backup/restore, DB v11→v12, payee raw preservato** | ✅ **COMPLETATO** |
| **Bugfix critico iFinance — transfer pairing** | **Pairing per `data + importo`, matching univoco con indizi `Trasferimento da/su`, movimenti normali sbloccati, reimport stesso CSV = 0 nuovi movimenti** | ✅ **COMPLETATO** |
| Flutter analyze | — | ✅ 0 errori, 0 warning, solo info pre-esistenti |
| `flutter test --no-pub` | — | ✅ **881 passed, 1 skipped** |
| `flutter build apk --release --no-pub` | — | ⏳ da rilanciare localmente |
| `flutter build ios --release --no-codesign --no-pub` | — | ⏳ da rilanciare localmente |

---

## 2. Ultime Milestone Completate

### Delta — Date più chiare + Dialog propagazione stile categoria

#### Date più chiare
- `TimeFilter.customRange.label` ora include l'anno: `"15 giu 2026 → 30 giu 2026"` (era `"15 giu → 30 giu"`)
- `DayHeader` mostra mese+anno (es. `giugno 2026`) sotto il weekday
- Obiettivo: evitare ambiguità navigando giorno/settimana/mese/anno/intervallo

#### Dialog propagazione stile categoria
- `_CategoryPropagateStyleDialog` in `lib/screens/categories_screen.dart`
- Appare quando si modifica categoria esistente con sottocategorie e colore/icona cambiati
- Checkbox per ogni sottocategoria, preselezione smart (ereditarie ✅, custom ❌)
- Azioni rapide: Seleziona tutte, Deseleziona tutte, Solo ereditarie
- Azioni finali: Annulla, Solo categoria, Applica alle selezionate
- `updateCategory()` accetta `propagateToSubcategoryIds: Set<String>?`
  - Se valorizzato: aggiorna solo le selezionate (override inherit-based)
  - Se null: mantiene logica automatica preesistente

#### QA
- `flutter analyze --no-pub`: 0 errori, 0 warning, 25 info pre-esistenti
- `flutter test --no-pub`: **759/759 All tests passed**
- `test/time_filter_test.dart`: label customRange aggiornata
- `test/subcategories_test.dart`: test 37 aggiornato per dialog "Applica alle selezionate"
- Nessun DB/schema/migrazione modificato
- Nessun commit/push

### Delta — Beneficiari manuali + proposta salvataggio

#### Cosa è stato completato
- Tab Beneficiari con tasto `+` e dialog `Nuovo beneficiario`
- Creazione manuale di `BeneficiaryProfile` senza creare `Movement`
- Duplicati normalizzati bloccati in creazione
- Lista Beneficiari costruita come merge tra:
  - payee derivati dai movimenti
  - profili manuali senza movimenti
- Search compatibile anche con beneficiari manuali vuoti
- `MovementPicker` e `MovementForm` propongono:
  - `No, solo movimento`
  - `Salva beneficiario`
  - `Annulla`
- `MovementCard` risolve `displayName` dal profilo senza riscrivere `movement.payee`
- Tap su beneficiario apre uno sheet con movimenti filtrati per beneficiario
- Backup/restore preservano i profili manuali
- Import iFinance non apre dialog e non crea profili persistiti automaticamente
- Audit finale completato su `DB v12` con test espliciti di migrazione `v11 → v12`, idempotenza e `reloadFromDb()`

#### Nota architetturale
- Il beneficiario manuale resta solo `BeneficiaryProfile` finché non viene usato in un movimento
- `movement.payee` resta il dato sorgente del movimento; nome/icona/colore del profilo sono metadata separati

### Delta — Bugfix critico iFinance transfer pairing

#### Cosa è stato completato
- Riconoscimento transfer esteso oltre `title/payee` anche a `labels`, `categoryRaw`, `categoryParent`
- Pairing transfer spostato da logica greedy per sola data a gruppi `data + importo assoluto`
- Nei gruppi multi-match il pairing usa gli indizi testuali `Trasferimento da ...` e `Trasferimento su ...`
- Solo i gruppi senza soluzione completa univoca restano ambigui
- I movimenti normali vengono importati correttamente anche quando nello stesso CSV sono presenti molti transfer
- Dedupe transfer verificato: reimport dello stesso CSV non aggiunge movimenti

#### Verifica su CSV reale
- `Transazioni finale.csv` verificato su DB temporaneo/account test
- `4265` righe lette
- `3067` movimenti normali importabili
- `584` transfer accoppiati
- `30` righe ambigue residue in `24` gruppi
- Reimport dello stesso CSV: `0` nuovi movimenti

#### Vincoli preservati
- Nessun dialog Beneficiari durante import iFinance
- `movement.payee` raw invariato
- Note importate pulite
- Nessun DB/schema/migrazione modificato

### V0.8.10b — Universal Movement Actions + Duplicate Date Choice

**Cosa è stato completato:**
- Azioni movimento universali in tutte le viste
- Dashboard sheet reattivo con `ListenableBuilder`
- Duplica con scelta data utility `showDuplicateDateSheet`
- Catena callback completa MovementCard → GroupedMovementsList → screen

### Delta completato dopo V0.8.10b
- `updateCategory` ora conserva in modo esplicito `oldCategoryColor` e `oldCategoryIconKey`
- Propagazione verso sottocategorie ereditarie: `sub.color == null || sub.color == oldCategoryColor`
- Refresh UI immediato in categories screen, sheet/dialog, movement form/picker
- Non serve più uscire/rientrare per vedere colore/icona aggiornati

---

## 3. Priorità Immediata (Prossima Sessione)

### Stato attuale
- Audit Beneficiari chiuso e bugfix iFinance completato: test finali `881 passed, 1 skipped` ✅
- `flutter analyze --no-pub`: `36 info`, `0 errori`, `0 warning` ✅
- DB `v12` verificato: `beneficiary_profiles` presente, `movements.payee` invariato ✅
- Unica deviazione non bloccante: picker icone beneficiari riusa `StreamIconLibrary`, non esiste una libreria dedicata separata ✅

### Prossimi step consigliati
1. **QA manuale estesa iFinance su altri export reali**
2. **V0.9.x — Notes & Tags**
3. **V0.9.x — Dashboard recalcolo + tabella editor**
4. **Subcategories Analytics — Budget/Actual/Scenari**

---

## 4. Note Tecniche Aperte

### TimeFilterMode.week
- `TimeFilterMode.week` aggiunto in `lib/models/time_filter.dart`
- `TimeFilter.week()` calcola: lunedì = `date.subtract(Duration(days: date.weekday - 1))`, domenica = lunedì + 6
- `label()` restituisce `"1–7 giugno 2026"` con giorno+mese del range
- `next()` somma 7, `previous()` sottrae 7 giorni

### _onHeatmapDayTap()
- Metodo in `MovementsScreen` per navigare tap giorno → vista Giorno
- Flusso: `selectedDay = day`, `timeFilter = TimeFilter.day(day)`, aggiorna `visibleCalendarMonth`
- Collegato a `PeriodHeatmapCard.onDaySelected`

### formatEuro()
- Funzione in `lib/utils/heatmap_utils.dart`
- Formatta importi al centesimo: `11.842,35 €`
- KPI principali usano sempre questo formato
- Micro-label heatmap restano compatte dove spazio è limitato (scelta esistente preservata)

### PeriodHeatmapCard behavior per mode
- **Day**: card dashboard premium con header, chip metrici, KPI, expense breakdown
- **Week**: KPI + heatmap 7 giorni + expense breakdown
- **Month**: KPI + heatmap mensile (riusa `ExpenseHeatmap`) + category treemap
- **Year**: KPI annuali + annual heatmap (`AnnualHeatmapCard`) + category treemap
- **Range**: ≤31gg = griglia giorni, 32–183gg = griglia settimanale compatta, **>183gg = blocchi semestrali** (Gen–Giu / Lug–Dic); KPI + heatmap

### Period day selection behavior (generalizzato)
- **Tap giorno**: solo in mode **Day** cambia `_activeFilter` a `TimeFilter.day`; in **Week/Month/Year/Range** resta nel periodo corrente
- `_selectedPeriodDay` (DateTime?) unificato in `MovementsScreenState` (ex `_selectedRangeDay`)
- `_onHeatmapDayTap()` usa switch su `timeFilter.mode`: solo `day` cambia filtro, tutti gli altri impostano `_selectedPeriodDay`
- Chip giorno selezionato unificato: key `period_selected_day_yyyy_m_d`; chip key: `period_selected_day_chip` (week/month/year), `range_selected_day_chip` (customRange)
- Clear button per mode: `week_clear_selected_day` ("Tutta settimana"), `month_clear_selected_day` ("Tutto mese"), `year_clear_selected_day` ("Tutto anno"), `range_clear_selected_day` ("Tutto intervallo")
- `_setActiveFilter()` azzera `_selectedPeriodDay` al cambio filtro
- `_MovementPanel` filtra movimenti quando `selectedPeriodDay != null`
- `effectiveSelectedDay = selectedPeriodDay ?? selectedDay` per highlighting heatmap

### Semester blocks architecture
- Soglia: >183 giorni (6 mesi) attiva `_buildSemesterRangeGrid()`
- Blocchi fissi: Gen–Giu, Lug–Dic
- `_RangeSemesterGrid` modellata su `_SemesterGrid` di `AnnualHeatmapCard`
- Ogni semestre mostra solo giorni entro il range effettivo
- Supporto cross-year (es. Nov 2025–Apr 2026 mostra 2 semestri)
- Supporto semestri parziali (range inizia/finisce a metà semestre)

### deleteSubcategoryCascade
- **File**: `lib/data/database.dart`
- Ora azzera `subcategoryId` in 3 tabelle:
  - `_movements`: usa `Movement.copyWith(subcategoryId: null)`
  - `_quickMovements`: crea `QuickMovement` con `subcategoryId: null`
  - `_favoriteMovements`: crea `FavoriteMovement` con `subcategoryId: null`
- Mantiene `categoryId` invariato — il movimento resta sotto la categoria madre
- Helper aggiunti: `subcategoryQuickCount()`, `subcategoryFavoriteCount()`

### updateCategory color/icon propagation
- **File**: `lib/data/database.dart`
- Dopo aver aggiornato la categoria, scorre tutte le sottocategorie
- Se sottocategoria ha `color == null || color == old.color` → aggiorna al nuovo colore (ereditarietà pura + vecchio colore madre)
- Se sottocategoria ha `iconKey == null || iconKey == old.iconKey` → aggiorna al nuovo iconKey
- Se sottocategoria ha personalizzazione diversa → preservata (condizione: `sc.color != null && sc.color != old.color`)
- Aggiornamento SQLite per ogni sottocategoria modificata, poi singolo `notifyListeners()`
- Ultima rifinitura: `updateCategory` conserva esplicitamente `oldCategoryColor` e `oldCategoryIconKey`, così la regola di ereditarietà è chiara e stabile

### Refresh UI immediato madre → sottocategorie
- Il problema residuo era anche UI: alcuni widget restavano agganciati a snapshot vecchi
- `categories_screen.dart` ora rilegge i dati aggiornati dal DB notificato
- `_CategoryMovementsSheet` calcola categoria/movimenti dentro `ListenableBuilder`
- `_CategoryFormDialog` dopo `await updateCategory()` esegue `if (!mounted) return` + `setState(() {})`
- `movement_form.dart` e `movement_picker.dart` ascoltano `widget.db` mentre mostrano il selector `Categoria / Sottocategoria`

### DB version corrente
- **v12** (`beneficiary_profiles`; nessuna modifica a `movements.payee`, nessun `payee_id`)

### iFinance transfer pairing
- `IFinanceCsvRow.isLikelyTransfer()` usa un haystack combinato: `title`, `payee`, `labels`, `categoryRaw`, `categoryParent`
- Pairing per chiave `data + abs(importo)`, non più solo per data
- Caso semplice:
  - `1` negativo + `1` positivo + conti diversi → pair immediato
- Caso multi-match:
  - parsing di `Trasferimento da X` / `Trasferimento su Y`
  - verifica coerenza tra hint e conti delle righe candidate
  - matching completo accettato solo se univoco
- `IFinanceImportPreview` espone anche:
  - `transferCandidateRows`
  - `ambiguousTransferGroups`

### Subcategories
- Nessuna FK SQLite, validazione applicativa (coerente con schema attuale)
- Color/icon: se null la sottocategoria eredita dalla categoria madre
- Backup v2 invariato — `subcategories` è lista opzionale in `BackupData`
- Budget/Actual/Scenari potranno usare `categoryId` + `subcategoryId` opzionale
- Rumore in migrazione V6: `duplicate column name: date` nei test, non blocca
- Warning futuro Kotlin Gradle Plugin su `file_picker` / `package_info_plus` / `share_plus`
