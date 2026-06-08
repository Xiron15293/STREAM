# NEXT SESSION — V0.6.1 Raggruppamento Movimenti per Giorno ✅

> V0.6.1 completato. Grouped display in Archivio con header giornaliero e riepilogo entrate/uscite/saldo. Info app in Impostazioni. 447 test pass.

## COMPLETATO (questa sessione)

### Raggruppamento Movimenti per Giorno
- `DailyMovementGroup` model + `groupMovementsByDay()` helper
- `DayHeader` widget: numero giorno (07), giorno settimana (SABATO), mese+anno (GIUGNO 2026)
- Riepilogo economico per giorno: Entrate/Uscite/Saldo con colori income/expense
- MovimentiScreen: `ListView.separated` → `ListView.builder` con grouped layout
- MovementCard riusato con `showDate: false` (data già nell'header)
- 11 test unit, 10 test widget (raggruppamento + regressione + 1000 dataset)

### Info app in Impostazioni
- Bottom sheet informativo: versione, build, ambiente (Debug/Release/Profile), piattaforma (iOS/Android), pacchetto
- `package_info_plus` dependency aggiunta
- Placeholder "Info app" ora funzionante

## STATO PIATTAFORMA

| Metrica | Valore |
|---------|--------|
| Test totali | **447/447 pass** (+21 da V0.6.0) |
| flutter analyze | **0 issues** |
| `flutter build apk --release` | **PASS** (66.2MB) |
| `flutter build ios --release --no-codesign` | **PASS** (32.6MB) |

## PROSSIMO STEP

Priorità candidati (V0.6.x):
1. **V0.6.2** — Ricerca Globale Movimenti (LOW-MEDIUM risk, filtro in-memory)
2. **V0.6.3** — UX Movimenti Rapidi/Preferiti Data Picker (MEDIUM risk)
3. **V0.6.4** — Calendar Heatmap (MEDIUM risk, UI complessa ma foundation ✅)
4. **V0.6.5** — Beneficiario ed Etichette (HIGH risk, migration SQLite)
5. **V0.6.6** — Trasferimenti tra Conti (HIGH risk, nuovo MovementType)

Vedi `docs/HERMES_ROADMAP.md` e `docs/STREAM_FEATURE_BACKLOG.md` per dettaglio completo.
