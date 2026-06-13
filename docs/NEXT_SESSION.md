# NEXT SESSION — Stato Progetto e Priorità

> Aggiornato: 2026-06-13

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
| Flutter analyze | — | ✅ 0 errori, 0 warning, solo info pre-esistenti |
| `flutter test --no-pub` | — | ✅ **759/759 test passati** |
| `flutter build apk --release --no-pub` | — | ⏳ da rilanciare localmente |
| `flutter build ios --release --no-codesign --no-pub` | — | ⏳ da rilanciare localmente |

---

## 2. Ultima Milestone Completata

**V0.8.10b — Universal Movement Actions + Duplicate Date Choice**

### Cosa è stato completato
- **Azioni movimento universali**: ogni `MovementCard` mostra popup menu completo (Modifica, Duplica, Aggiungi a rapido, Aggiungi a preferito, Elimina) in tutte le viste
- Viste coperte: Movimenti, categorie/sottocategorie, conti/account sheet, dashboard category detail sheet, ripartizione spese giorno (`_DayExpenseDetailSheet`)
- **Dashboard sheet reattivo**: `_CategoryDetailSheet` usa `ListenableBuilder(listenable: db)` — delete/duplicate/modifica aggiornano UI senza chiudere/riaprire
- **Duplica con scelta data**: utility `showDuplicateDateSheet` (Oggi/Domani/Ieri/Scegli data/Annulla); annulla non crea duplicato; nuovo id; nessuna copia fingerprint/import metadata
- Catena callback completa: `MovementCard` → `GroupedMovementsList` → ogni screen

### QA finali
- `flutter analyze --no-pub`: 0 errori, 0 warning, 25 info (pre-esistenti)
- `flutter test --no-pub`: **749/749 All tests passed**
- 2 nuovi test: annulla non crea duplicato (53b), Domani funziona (53c); test 53 aggiornato con scelta Oggi
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push

### Delta completato dopo la milestone
- `updateCategory` ora conserva in modo esplicito `oldCategoryColor` e `oldCategoryIconKey`
- La propagazione verso le sottocategorie ereditarie usa:
  - `sub.color == null || sub.color == oldCategoryColor`
  - `sub.iconKey == null || sub.iconKey == oldCategoryIconKey`
- Colori e icone custom diversi restano preservati
- Il fix è anche UI:
  - `categories_screen` rilegge dal DB notificato
  - category sheet/dialog usa `ListenableBuilder` e `setState` dove necessario
  - `movement_form` e `movement_picker` ascoltano il DB mentre mostrano categoria/sottocategoria
- Non serve più uscire/rientrare per vedere colore/icona aggiornati
- Verifica finale aggiornata:
  - `flutter analyze --no-pub`: nessun errore o warning bloccante; restano solo info pre-esistenti
  - `flutter test --no-pub`: **759/759 All tests passed**
  - test estesi in `test/subcategories_test.dart` e `test/movement_card_test.dart`

---

## 3. Priorità Immediata (Prossima Sessione)

### Stato attuale
- Azioni movimento universali completate in ogni vista
- Dashboard sheet reattivo
- Duplica con scelta data (Oggi/Domani/Ieri/Scegli data/Annulla)
- Test: 749/749

### Prossimi step consigliati
1. **V0.9.0 — Notes & Tags**
   - Campo notes su movimento
   - Tag multi-selezione su movimento
   - Filtro per tag in dashboard
2. **V0.9.1 — Dashboard recalcolo + tabella editor**
   - recalcolo KPI, tabella modificabile
3. **V0.9.2 — Export/Backup**
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
- **v10** (da V0.8.8, invariato in V0.8.10 — nessuna migrazione)

### Subcategories
- Nessuna FK SQLite, validazione applicativa (coerente con schema attuale)
- Color/icon: se null la sottocategoria eredita dalla categoria madre
- Backup v2 invariato — `subcategories` è lista opzionale in `BackupData`
- Budget/Actual/Scenari potranno usare `categoryId` + `subcategoryId` opzionale
- Rumore in migrazione V6: `duplicate column name: date` nei test, non blocca
- Warning futuro Kotlin Gradle Plugin su `file_picker` / `package_info_plus` / `share_plus`
