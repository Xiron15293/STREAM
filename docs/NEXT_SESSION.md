# NEXT SESSION — After Dashboard Filtrata

> Stato attuale: Dashboard filtrata, Backup/Restore in Impostazioni e refactor UI già allineati al codice reale.

## COMPLETATO

- Dashboard come sintesi/insight, non come secondo Archivio
- `TimeFilter` + `TimeFilterBar` riusati per filtrare il periodo
- KPI filtrati: entrate, uscite, saldo, numero movimenti
- KPI non filtrati: patrimonio totale, saldi conti, situazione attuale
- Sezione `Spese per categoria` con massimo 5 categorie visibili, ordinamento per spesa decrescente e empty state dedicato
- `MovementCard` condivisa per le schermate operative
- Fix `heroTag` FAB mantenuto
- Backup/Restore spostato in `Impostazioni`

## IN CORSO

- Nessuna feature di prodotto aperta in questo file

## FUTURO

- Risolvere i blocchi delle build release native prima di riprendere nuove feature
- Poi riprendere la roadmap V0.6, senza riaprire la Dashboard come lista movimenti

## Ultimo stato verificato

| Metrica | Valore |
|---------|--------|
| Test totali | **363/363 pass** |
| flutter analyze | **0 issue nuovi** |
| `flutter build apk --release` | **FAIL**: errore plugin `file_picker` nel registrant Android |
| `flutter build ios --release` | **FAIL**: risoluzione SPM/Xcode bloccata da cache/permessi e CoreSimulator |

## Componenti riutilizzati

- `TimeFilter`
- `TimeFilterBar`
- `filterByTime()`

## Dashboard filtrata

**Filtrati**:
- Entrate periodo
- Spese periodo
- Saldo periodo
- Numero movimenti periodo
- Spese per categoria nel periodo

**Non filtrati**:
- Patrimonio totale
- Saldi conti
- Fondi/situazione conti attuale

## Prossimo step reale

Sbloccare le build release native:

1. sistemare il registrant Android di `file_picker`
2. sistemare la cache/permessi SwiftPM e CoreSimulator per iOS

Solo dopo ha senso riprendere la prossima feature di prodotto.
