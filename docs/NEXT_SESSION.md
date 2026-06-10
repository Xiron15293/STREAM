# NEXT SESSION — Stato Progetto e Priorità

> Aggiornato: Giugno 2026

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
| Hermes V0.8.0 — Import CSV 1Money | mapping dedicato + dedupe fingerprint | ✅ COMPLETATO |
| Hermes V0.8.1 — Saldo iniziale conti | `accounts.initial_balance` + saldo derivato | ✅ COMPLETATO |
| Hermes V0.8.x — Archivio navigabile | Conti/Categorie cliccabili + archiviati consultabili | ✅ COMPLETATO |
| Flutter analyze | — | ✅ PASS |
| Test mirati reset/import/archivio | — | ✅ PASS |
| Test totali | — | ⏳ suite completa da rilanciare |
| Build Android | `flutter build apk --release --no-pub` | ⏳ da rilanciare localmente |
| Build iOS | `flutter build ios --release --no-codesign --no-pub` | ⏳ da rilanciare localmente |

---

## 2. Ultima Milestone Completata

**Hermes V0.8.0 — Import CSV 1Money (prima versione)**

### Cosa è stato completato
- Import CSV 1Money, prima versione dedicata al formato 1Money:
  - `DATA`, `TIPOLOGIA`, `DAL CONTO`, `AL CONTO / ALLA CATEGORIA`, `IMPORTO`, `NOTE`
  - auto-creazione conti e categorie mancanti
  - trasferimenti nativi Stream con `destinationAccountId`
  - dedupe tramite fingerprint data/tipo/importo/conto/categoria/note
  - import di `note` e fallback del `title` su categoria/destinazione

### QA
- `flutter analyze --no-pub`: PASS
- `flutter test --no-pub test/one_money_csv_import_test.dart`: PASS
- Validazione dataset reale:
  - Backup Stream: 6369 movimenti
  - CSV 1Money unici: 6369 movimenti
  - overlap: 6369
  - backup-only: 0
  - csv-only: 0
  - nessuna perdita movimenti
- Suite completa: da rilanciare
- `flutter build apk --release --no-pub`: da rilanciare localmente
- `flutter build ios --release --no-codesign --no-pub`: da rilanciare localmente

---

## 3. Priorità Immediata (Prossima Sessione)

La prossima attività reale è:

1. **Calculator Pad per tutti i campi importo**

Da fare in commit/sessione separata.

Tasti richiesti:

- `+`
- `-`
- `*`
- `/`
- `:`
- `=`
- backspace
- clear
- `Fatto`

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

---

## 5. Handoff Rapido

Quando si riparte:
- verificare che i dati di test siano puliti prima della sessione
- riprendere dalla pianificazione Calculator Pad
- mantenere Dashboard insight-only
- non introdurre nuove feature fuori priorità senza allineamento
