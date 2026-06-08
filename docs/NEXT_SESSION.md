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
| Flutter analyze | — | ✅ PASS |
| Test totali | 492 | ✅ 492/492 |
| Build Android | `flutter build apk --release --no-pub` | ✅ PASS |
| Build iOS | `flutter build ios --release --no-codesign --no-pub` | ⏳ da rilanciare localmente |

---

## 2. Ultima Milestone Completata

**Hermes V0.6.4 — UX Movimenti Rapidi/Preferiti con scelta data**

### Cosa è stato completato
- Ricerca globale movimenti in Archivio > Movimenti
  - titolo
  - nota
  - categoria
  - conto
- Ricerca combinata con `TimeFilter`
- Risultati renderizzati con `GroupedMovementsList`
- Movimenti rapidi / preferiti con scelta data rapida:
  - `Oggi`
  - `Ieri`
  - `Domani`
  - `Scegli data`
- Fix del flusso bottom sheet / date picker con `Key` stabili
- Fix test lazy list con `scrollUntilVisible` corretto
- Fix label form movimento:
  - Entrata / Uscita = `Conto`
  - Trasferimento = `Conto origine`

### QA
- `flutter analyze --no-pub`: PASS
- `flutter test --no-pub`: 492/492 PASS
- `flutter build apk --release --no-pub`: PASS
- `flutter build ios --release --no-codesign --no-pub`: da rilanciare localmente

---

## 3. Priorità Immediata (Prossima Sessione)

La prossima attività reale è:

1. **Reset dati app controllato**
2. **Trasferimenti tra conti**
3. **Import CSV 1Money**

---

## 4. Note Tecniche Aperte

- Rumore in migrazione V6: `duplicate column name: date` nei test, ma non blocca l'esecuzione
- Warning futuro Kotlin Gradle Plugin su `file_picker` / `package_info_plus` / `share_plus`

---

## 5. Handoff Rapido

Quando si riparte:
- verificare che i dati di test siano puliti prima della sessione
- riprendere dalla pianificazione Reset dati app
- mantenere Dashboard insight-only
- non introdurre nuove feature fuori priorità senza allineamento
