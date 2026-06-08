# NEXT SESSION — V0.6 QA Completa + Fix Critico IntervalPickerSheet

> V0.6.0 completato con QA 500 scenari. Fix critico: IntervalPickerSheet non veniva mai aperto (apreva month picker invece). 426 test pass.
>
> **Novità**: `docs/HERMES_QA_REPORT.md` contiene QA completa 500 scenari con gap analysis.

## COMPLETATO (questa sessione)

### Bug CRITICAL fix: IntervalPickerSheet mai aperto
- **Root cause**: `_onModeChanged(customRange)` schedulava `_pickDate` via `addPostFrameCallback` ma NON chiamava `onChanged`. Quando `_pickDate` eseguiva, `activeFilter.mode` era ancora `month`, quindi entrava nel branch `month` invece di `customRange`.
- **Fix**: `_pickDate` ora accetta `forcedMode: TimeFilterMode?`. `_onModeChanged(customRange)` passa `forcedMode: TimeFilterMode.customRange`, bypassando `activeFilter.mode`.

### UX IntervalPickerSheet (conforme a requisiti)
- Due card affiancate **Da** e **A** sempre visibili con formato `DD/MM/AAAA`
- Tap su Da → StreamDatePicker modifica solo startDate
- Tap su A → StreamDatePicker modifica solo endDate
- Applica → `TimeFilter.customRange(start, end)`
- Annulla → nessuna modifica al filtro
- A < Da → messaggio errore + Applica disabilitato
- Label nel SegmentedButton: "1 giu → 30 giu"

### QA 500 scenari — gap analysis
- 500 scenari progettati in 15 aree
- 416 coperti da test esistenti
- 84 scoperti (gap)
- 14 nuovi test implementati (più impattanti)

### Nuovi test (14)
- `dashboard_filtered_test.dart`: 4 interval picker widget test, 3 category detail widget test, 7 unit edge case (suggestion, archived category, rename propagation, default account)

## STATO PIATTAFORMA

| Metrica | Valore |
|---------|--------|
| Test totali | **426/426 pass** (+14) |
| flutter analyze | **0 issues** |
| `flutter build apk --release` | **PASS** (66.1MB) |
| `flutter build ios --release --no-codesign` | **PASS** (32.6MB) |

## PROSSIMO STEP

Priorità candidati (V0.6.x):
1. **V0.6.0** — Raggruppamento Movimenti per Giorno (LOW risk, UI pura)
2. **V0.6.1** — Ricerca Globale Movimenti (LOW-MEDIUM risk, filtro in-memory)
3. **V0.6.2** — UX Movimenti Rapidi/Preferiti Data Picker (MEDIUM risk)
4. **V0.6.3** — Calendar Heatmap (MEDIUM risk, UI complessa ma foundation ✅)
5. **V0.6.4** — Beneficiario ed Etichette (HIGH risk, migration SQLite)
6. **V0.6.5** — Trasferimenti tra Conti (HIGH risk, nuovo MovementType)

Vedi `docs/HERMES_ROADMAP.md` e `docs/STREAM_FEATURE_BACKLOG.md` per dettaglio completo.
