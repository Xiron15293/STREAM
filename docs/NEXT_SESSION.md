# NEXT SESSION — Stato Progetto e Priorità

> Aggiornato: 2026-06-12

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
| Flutter analyze | — | ⚠️ da tenere distinto: presenti issue legacy non legate a questa lavorazione |
| `flutter test --no-pub` | — | ✅ rilanciato in questa sessione |
| `flutter build apk --release --no-pub` | — | ⏳ da rilanciare localmente |
| `flutter build ios --release --no-codesign --no-pub` | — | ⏳ da rilanciare localmente |

---

## 2. Ultima Milestone Completata

**Post V0.8.9 — Selector unico Categoria / Sottocategoria + subcategory save verification**

### Cosa è stato completato
- Verificato il salvataggio sottocategoria su nome + icona + colore:
  - update immediato in memoria
  - persistenza SQLite confermata dopo reload
  - dialog UI coperto con test del primo tap
- Introdotto il selector unico `Categoria / Sottocategoria`
  - field key `movement_category_subcategory_field`
  - bottom sheet key `category_subcategory_picker`
  - search key `category_subcategory_search_field`
  - selezione categoria madre o `Categoria / Sottocategoria`
  - solo elementi attivi
- Flussi aggiornati:
  - movimento manuale
  - rapidi
  - preferiti
  - rendering `MovementCard`

### QA finali
- `test/subcategories_test.dart`: copertura esplicita del bug salvataggio sottocategoria e del selector unificato
- `test/movement_card_test.dart`: copertura rendering combinato `Categoria / Sottocategoria`
- Nessuno skip aggiunto
- Nessun commit/push

---

## 3. Priorità Immediata (Prossima Sessione)

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

- DB version corrente: **v9** (da V0.8.8)
- Subcategories: nessuna FK SQLite, validazione applicativa (coerente con lo schema attuale)
- Color/icon su Subcategory: supportati come campi opzionali; se null resta il fallback alla categoria madre
- Backup v2 invariato — `subcategories` è una lista opzionale in `BackupData`
- Budget/Actual/Scenari potranno usare `categoryId` + `subcategoryId` opzionale
- Rumore in migrazione V6: `duplicate column name: date` nei test, ma non blocca l'esecuzione
- Warning futuro Kotlin Gradle Plugin su `file_picker` / `package_info_plus` / `share_plus`
- Reset dati app: verificato manualmente su Pixel 6; i failure QA residui erano dovuti a helper/test fragili e non a un bug confermato del prodotto
- Import CSV 1Money: validato su dataset reale, con 6369 movimenti unici coincidenti tra Stream e 1Money
- Import CSV 1Money: la sezione finale dei conti/fondi esportata da 1Money viene ignorata dalla riga `NOME`
- Se serve riallineare i saldi conto per una verifica manuale, usare i valori del backup Stream validato come riferimento operativo
- Saldo iniziale conti: il saldo attuale è ora sempre derivato da saldo iniziale + movimenti, e la modifica conto espone solo il saldo iniziale come campo editabile
- Archivio > Conti: la vista `Movimenti del conto` è stata aggiunta e usa `TimeFilter` + `GroupedMovementsList`
- Archivio > Categorie: la vista `Movimenti categoria` è stata aggiunta e usa `TimeFilter` + `GroupedMovementsList`
- Conti e categorie archiviate sono consultabili e cliccabili in sezioni separate (`Archiviati`)
- Reset widget flow: `reset_data_test.dart` e `qa_extensive_test.dart` sono verdi; `C2`, `F2`, `F3`, `L1` stabilizzati tramite flusso UI reale con backup pre-reset stub nel test harness dove necessario
- Categories Layout Modes: preferenza `category_layout`, default `cleanList`, reset incluso in `PreferencesService.clearForReset()`
- Financial KPI Corrections: Dashboard, database totals e riepiloghi giornalieri usano helper income/expense espliciti; i transfer restano neutrali sui KPI globali e attivi sui saldi conto
- Date Filter Categories/Accounts: Categorie e Conti hanno `TimeFilterBar` nella schermata principale; nei Conti il saldo visibile è storico/as-of al termine del periodo selezionato
- Interactive Category/Account Menus: restore conto non implementato perché non esiste una API esistente da riusare; archiviazione conto attivo disponibile
- Movimenti Analytics: Lista/Calendario/Heatmap completati; search, filtro periodo e picker data/anno coerenti
- Category Treemap Analytics: treemap definitiva in Categorie, non in Movimenti; usa `category.color`, filtri periodo e ordinamenti dedicati
- **Heatmap Settings (V0.8.7)**: soglie/colori configurabili in `Settings > Heatmap`; aggiornamento live della heatmap via `heatmapSettingsNotifier`; fallback a default se prefs corrotte; `clearForReset()` non tocca le preferenze heatmap (scelta deliberata — le impostazioni visive sopravvivono al reset dati)
- QA hardening: resta del rumore legacy in analyze e un warning hit-test noto sul bottone Salva in parte della suite; non appartiene al fix sottocategorie

---

## 5. Handoff Rapido

Quando si riparte:
- verificare stato git
- proseguire con **V0.9.0 — Notes & Tags**
- DB è ora v9, `subcategories` tabella e `subcategory_id` colonne disponibili
- mantenere SharedPreferences-only per le impostazioni visuali
- non modificare DB/schema oltre v9 senza progettazione
- considerare QA hardening hit-test prima di rendere warning fatali
