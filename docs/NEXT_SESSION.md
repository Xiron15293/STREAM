# NEXT SESSION — V0.6.2 Ordinamento Centralizzato e Fix Gruppi Giorno ✅

> V0.6.2 completato. Comparator unico `compareMovementsForDisplay`, ordinamento `updatedAt desc`, fix ordinamento gruppi giorno (chiave zero-padded). 457 test pass.

## COMPLETATO (questa sessione)

### Comparator Centralizzato
- `compareMovementsForDisplay(a, b)` in `lib/models/movement.dart`
- Ordine: `updatedAt desc → createdAt desc → id asc`
- `categoryId`, `type`, `amount`, `title` NON influenzano l'ordine
- Sostituisce 3 implementazioni separate in `daily_group.dart`, `time_filter.dart`, `database.dart`

### Ordinamento updatedAt desc
- Dentro ogni giorno: `updatedAt desc` invece di `createdAt desc`
- Movimento modificato/inserito più recentemente appare sopra
- Fallback `createdAt desc → id asc`

### Fix ordinamento gruppi giorno (CRITICAL)
- **Causa**: chiave `"2026-6-8"` > `"2026-6-12"` per confronto lessicografico (8 > 1). 8 giugno appariva sopra 12 giugno.
- **Fix**: `padLeft(2, '0')` su mese e giorno → `"2026-06-08"` < `"2026-06-12"` ✅

### GroupedMovementsList riusabile
- Nuovo widget `lib/widgets/grouped_movements_list.dart`
- Accetta `scrollController` opzionale per `DraggableScrollableSheet`
- Usato da: `MovementsScreen`, `_CategoryDetailSheet`

### Dashboard insight-only restored
- Rimosso `_FilteredMovementsList` dalla Dashboard
- Resta solo KPI + spese per categoria (V0.5.6 decision)

### DayHeader Row overflow fix
- `FittedBox(boxFit.scaleDown)` sul Row riepilogo
- Previene overflow in bottom sheet stretto (iPhone)

## STATO PIATTAFORMA

| Metrica | Valore |
|---------|--------|
| Test totali | **457/457 pass** (+10 da V0.6.1) |
| flutter analyze | **0 issues** |
| `flutter build apk --release` | **PASS** (66.2MB) |
| `flutter build ios --release --no-codesign` | **PASS** (32.7MB) |

## PROSSIMO STEP

Priorità candidati (V0.6.x):
1. **V0.6.3** — Ricerca Globale Movimenti (LOW-MEDIUM risk, filtro in-memory)
2. **V0.6.4** — UX Movimenti Rapidi/Preferiti Data Picker (MEDIUM risk)
3. **V0.6.5** — Calendar Heatmap (MEDIUM risk, UI complessa ma foundation ✅)
4. **V0.6.6** — Beneficiario ed Etichette (HIGH risk, migration SQLite)
5. **V0.6.7** — Trasferimenti tra Conti (HIGH risk, nuovo MovementType)

Vedi `docs/HERMES_ROADMAP.md` e `docs/STREAM_FEATURE_BACKLOG.md` per dettaglio completo.
