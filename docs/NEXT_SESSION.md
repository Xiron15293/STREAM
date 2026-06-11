# NEXT SESSION — Stato Progetto e Priorità

> Aggiornato: 2026-06-11

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
| Flutter analyze | — | ✅ PASS — 0 issues |
| `flutter test --no-pub` | — | ✅ 664/664 All tests passed |
| `flutter build apk --release --no-pub` | — | ⏳ da rilanciare localmente |
| `flutter build ios --release --no-codesign --no-pub` | — | ⏳ da rilanciare localmente |

---

## 2. Ultima Milestone Completata

**Hermes V0.8.5 — Movimenti Analytics / Heatmap**

### Cosa è stato completato
- Archivio senza tab Calendario separata
- Movimenti con modalita interne:
  - Lista
  - Calendario
  - Heatmap / AdvancedHeatmap
- Heatmap Movimenti basata sulle uscite
- Income e transfer esclusi dai colori/metriche heatmap spese
- Search coerente con heatmap:
  - titolo
  - nota
  - categoria
  - conto
- Filtro periodo corretto:
  - Giorno
  - Mese
  - Anno
  - Intervallo
- Picker data/anno coerente con mese visibile, heatmap e lista
- Preview heatmap compatta in Lista
- `MovementCard` mantiene `PopupMenuButton` stabile

### QA
- `flutter analyze --no-pub`: PASS — 0 issues
- `flutter test --no-pub`: **664/664 All tests passed**

**Hermes V0.8.6 — Category Treemap Analytics**

### Cosa è stato completato
- Treemap Categorie come quarta modalita visuale:
  - Lista pulita
  - Lista grouped
  - Card Stream
  - Treemap
- Treemap stile market map:
  - blocco = categoria
  - area = totale categoria nel periodo
  - colore = `category.color`
  - testo = nome categoria, importo e/o numero movimenti
- Filtri periodo supportati:
  - Giorno
  - Mese
  - Anno
  - Intervallo
- Ordinamenti:
  - totale decrescente
  - totale crescente
  - nome A-Z
  - numero movimenti decrescente
- Transfer esclusi dai totali categoria
- Tap su blocco apre lo sheet/dettaglio categoria esistente
- Empty state per periodo senza dati
- Movimenti non contiene piu la treemap del periodo; mantiene heatmap e calendario

### QA finale
- `flutter analyze --no-pub`: PASS — 0 issues
- `flutter test --no-pub`: **664/664 All tests passed**
- Nessun DB/schema/migrazione modificato
- Backup/restore/import/reset non modificati
- Nessuno skip aggiunto
- Nessun commit/push eseguito

---

## 3. Priorità Immediata (Prossima Sessione)

Una volta ripresa la sessione:

1. **FASE 3 — Heatmap Settings**
   - soglie heatmap configurabili
   - colori heatmap configurabili
   - restore defaults
   - preview impostazioni
   - SharedPreferences only
   - nessun DB/schema

2. **FASE 4 — Lista Movimenti Premium**
   - heatmap annuale tipo reference utente
   - card giornaliere aggregate
   - layout premium
   - mantenere pipeline dati esistente

3. **QA hardening opzionale**
   - risolvere warning hit-test sul bottone Salva nei test
   - rendere fatali i warning solo dopo fix helper
   - non indebolire test

---

## 4. Note Tecniche Aperte

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
- QA hardening: resta un warning hit-test noto sul bottone Salva nei test; non blocca la suite ma puo essere ripulito in una sessione dedicata

---

## 5. Handoff Rapido

Quando si riparte:
- verificare stato git
- scegliere tra FASE 3 Heatmap Settings e FASE 4 Lista Movimenti Premium
- mantenere SharedPreferences-only per le impostazioni heatmap
- non modificare DB/schema per le prossime impostazioni visuali
- considerare QA hardening hit-test prima di rendere warning fatali
