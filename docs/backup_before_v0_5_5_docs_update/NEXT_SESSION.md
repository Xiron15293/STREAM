# NEXT SESSION — Hermes V0.5.5 Dashboard Filtrata per Periodo

> Stato: ✅ COMPLETATO

## Risultato

| Metrica | Valore |
|---------|--------|
| File modificati | `lib/screens/dashboard_screen.dart` |
| Test aggiunti | 13 (10 in-memory logica + 3 widget) |
| Test totali | 312/312 pass |
| flutter analyze | 0 nuovi issue (2 pre-esistenti) |
| flutter analyze | ✅ |

## Componenti riutilizzati

- `TimeFilter` — invariato, nessuna nuova classe
- `TimeFilterBar` — già usata in CalendarScreen
- `filterByTime()` — già implementata su `List<Movement>`

## KPI filtrati

- **Entrate periodo** — `movements.filterByTime(filter).where(type == income).sum`
- **Spese periodo** — `movements.filterByTime(filter).where(type == expense).sum`
- **Saldo periodo** — entrate − spese
- **Numero movimenti** — `filteredMovements.length`
- **Ultime transazioni** — `filteredMovements.take(5)`

## KPI non filtrati

- **Patrimonio totale** — `db.totalAccountsBalance` (globale, invariato)
- **Saldi conti** — globali, non dipendono dal periodo

## Modifiche architetturali

- `DashboardScreen` convertita da `StatelessWidget` a `StatefulWidget`
- Aggiunto `TimeFilter _filter` nello stato (default: mese corrente)
- KPI grid: da 3-colonne a 2×2 (aggiunto Movimenti count)
- Nuovo empty state: "Nessun movimento nel periodo selezionato" quando il periodo è vuoto ma ci sono movimenti globali

## Prossimo step suggerito

Con V0.5 completato (tutte le sotto-feature ✅), il prossimo step logico è:

**Hermes V0.6 — Ricorrenze** (F19)
