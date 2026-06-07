# NEXT SESSION — Post V0.5.6 & MovementCard Refactor

> Stato: ✅ V0.5 COMPLETATO (tutte le 6 sotto-feature) + MovementCard unico

## Ultimo risultato (V0.5.6 + Refactor)

| Metrica | Valore |
|---------|--------|
| File nuovi | `lib/widgets/movement_card.dart` |
| File modificati | `lib/screens/dashboard_screen.dart`, `calendar_screen.dart`, `movements_screen.dart` |
| Componenti duplicati rimossi | 4 classi private (~376 righe eliminate) |
| Test aggiunti (Dashboard Filtrata) | 13 (10 in-memory + 3 widget) |
| Test aggiunti (MovementCard) | 14 (widget test) |
| Test totali | **326/326 pass** |
| flutter analyze | **0 nuovi issue** (2 pre-esistenti) |

## Componenti riutilizzati (V0.5.6)
- `TimeFilter` — invariato
- `TimeFilterBar` — già usata in CalendarScreen
- `filterByTime()` — già implementata su `List<Movement>`

## KPI Dashboard dopo V0.5.6

**Filtrati** (dipendono dal periodo selezionato):
- Entrate periodo, Spese periodo, Saldo periodo, Numero movimenti

**Non filtrati** (globali/strutturali):
- Patrimonio totale, Saldi conti

## MovementCard unico — posizionamento architetturale

`lib/widgets/movement_card.dart` è ora la **fonte di verità unica** per renderizzare un movimento nell'intera app. Questo prepara tecnicamente le feature future:

| Feature futura | Cosa riusa di MovementCard |
|----------------|---------------------------|
| Ricerca Globale (F23) | Card per mostrare risultati |
| Preferiti rapidi (F12) | Card per template preferiti |
| Import Preview (F21) | Card per preview movimenti importati |
| Heatmap Calendario (F13) | Card nel detail-on-tap del giorno |

MovementCard è **solo vista** (UI/callback). Non scrive su DB, non modifica Actual, non calcola aggregati.

## Prossimi step suggeriti

Con V0.5 completato, la priorità consigliata è:

### 1. V0.5.6 — UX Booster (prima di V0.6 Ricorrenze)
Blocco di 5 micro-feature a basso sforzo, massimo impatto UX, che sfruttano MovementCard già unificato:

| # | Feature | Sforzo | Impatto | Dipendenze |
|---|---------|--------|---------|------------|
| 1 | Ricerca globale movimenti (F23) | Basso | Alto | MovementCard ✅ |
| 2 | Preferiti rapidi (F12.1–F12.3) | Medio | Alto | MovementCard ✅ |
| 3 | Aggiorna preferito esistente (F12.4) | Basso | Medio | F12.3 |
| 4 | Categorie frequenti/suggerite | Basso | Medio | Nessuna |
| 5 | Calendar Heatmap (F13) | Medio | Alto | V0.5 Foundation ✅ |

### 2. V0.6 — Ricorrenze (F19)
Movimenti automatici ricorrenti. Dipende da: date ✅, TimeFilter ✅, Calendario tab ✅.
Sforzo più alto, pianificare dopo UX Booster.

### 3. V0.7+ — Import CSV, Athena, Scenari
Feature più complesse, da valutare dopo feedback utenti reali.

## Note tecniche residue
- iPhone app installata su device (`00008140-001E29803CD1801C`, iOS 26.5)
- Free Apple Developer provisioning profile scade in 7 giorni
- `flutter analyze`: 2 pre-existing (sqflite unused import, unused local `now` in test)
- Test suite: 326 tests, esecuzione ~23s
