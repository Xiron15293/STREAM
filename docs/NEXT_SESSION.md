# NEXT SESSION — V0.5.6 Completato

> Stato attuale: V0.5.6 completato. Build release native sbloccate. Backup esportabile via share sheet.

## COMPLETATO

- Dashboard come sintesi/insight, non come secondo Archivio
- `TimeFilter` + `TimeFilterBar` riusati per filtrare il periodo
- KPI filtrati: entrate, uscite, saldo, numero movimenti
- KPI non filtrati: patrimonio totale, saldi conti, situazione attuale
- Sezione `Spese per categoria` con massimo 5 categorie visibili, ordinamento per spesa decrescente e empty state dedicato
- `MovementCard` condivisa per le schermate operative
- Fix `heroTag` FAB mantenuto
- Backup/Restore spostato in `Impostazioni`
- **Build release Android**: fix KGP per `file_picker` in `android/build.gradle.kts`
- **Backup esportabile**: share sheet nativo via `share_plus` (post-export + lista backup)
- **Build pipeline**: tutti e 4 i comandi PASS (`analyze`, `test`, `apk --release`, `ios --release`)

## STATO PIATTAFORMA

| Metrica | Valore |
|---------|--------|
| Test totali | **363/363 pass** |
| flutter analyze | **0 issues** |
| `flutter build apk --release` | **PASS** (66.1MB) |
| `flutter build ios --release --no-codesign` | **PASS** (32.7MB) |
| share_plus | `^12.0.2` aggiunto |

## PROSSIMO STEP REALE

Build release native sbloccate. Si può riprendere la roadmap feature V0.6+.

Priorità candidate:
1. **F12** — Quick/Favorite Movement Library UX (Ricerca, filtri, salva da Manuale)
2. **F23** — Ricerca Globale Movimenti
3. **F13** — Calendar Heatmap / Category Heatmap
4. **F30** — Inline Form Validation
