# NEXT SESSION — Hermes V0.5 Calendario

> Stato: 🔜 NEXT
> Dipende da: Hermes V0.4.2 Navigation Refactor: Archivio = COMPLETATO

## Stato attuale

Hermes V0.4 Design System STREAM ✅ COMPLETATO:
- 193 test preserved, 0 analyze issues
- Tema scuro Material 3 con `lib/theme.dart`
- Dashboard, Movimenti, Conti, Categorie, Form completamente restilizzati
- Android APK e iOS IPA build OK
- App installata su iPhone (`com.mattiasironi.flow` v1.0.0)

Hermes V0.4.1 Account Icon/Color Refresh ✅ COMPLETATO:
- **Root cause**: Account model senza campo `color`. ColorPicker decorativo.
- **Fix**: `int color` in Account model, SQLite V5 migration, `updateAccount()` con color opzionale.
- **Test**: 15 nuovi test (account_icon_color_test.dart)
- **Total tests**: 235/235 | flutter analyze: 0 errors
- **Builds**: APK e iOS OK, tutte le regressioni passano

Hermes V0.4.2 Navigation Refactor: Archivio ✅ COMPLETATO:
- **Refactor**: Tab Movimenti, Conti, Categorie consolidate in unica tab "Archivio"
- **Nuova schermata**: `lib/screens/archive_screen.dart` — SegmentedButton + IndexedStack
- **Bottom nav**: ora 2 elementi — Dashboard, Archivio
- **Rapidi e Preferiti** restano sotto Movimenti
- **235 test preserved** | flutter analyze: 0 errors in lib/
- **Nessuna migrazione database**

## Obiettivo

V0.5 — Calendario: vista mensile con navigazione date e movimenti giornalieri:

- Vista calendario mensile con indicatori di movimenti
- Navigazione tra mesi (swipe o frecce)
- Tap su giorno → lista movimenti del giorno
- Inserimento movimento con data preselezionata
- Test coverage per calendario

## Prerequisiti

- [x] Hermes V0.4 Design System STREAM — COMPLETATO
- [x] Hermes V0.4.1 Account Icon/Color Refresh — COMPLETATO
- [x] Hermes V0.4.2 Navigation Refactor: Archivio — COMPLETATO
- [ ] Uso reale app per 2-3 giorni (raccogliere feedback su V0.3-V0.4)

## Uso reale consigliato

Prima di iniziare V0.5, usare l'app con dati reali per 2-3 giorni:
- Validare UI/UX del nuovo design system
- Verificare che conti, categorie, movimenti funzionino correttamente
- Raccogliere feedback su cosa migliorare

## Backlog completo

Tutte le feature (approvate, in valutazione, future, post-MVP) sono censite in:
📋 **`docs/STREAM_FEATURE_BACKLOG.md`** — 32 feature classificate.

## Prossime priorità

Dettaglio completo in `docs/STREAM_FEATURE_BACKLOG.md` sezione 8.

### V0.5.4 — Calendario Tab (🔄 IN VALUTAZIONE)
- Nuova tab nella bottom nav con vista mensile
- Griglia giorni con indicatori movimenti
- Navigazione swipe/frecce tra mesi
- Tap giorno → lista movimenti del giorno

### V0.5.5 — Archivio Filtrato per Data (🔄 IN VALUTAZIONE)
- Filtro periodo nella tab Movimenti di Archivio
- Usa TimeFilter (F11 ✅ già pronto)

### V0.5.6 — Dashboard Filtrata per Periodo (🔄 IN VALUTAZIONE)
- KPI calcolati su periodo selezionato
- Hero card e KPI grid filtrate

## To-do prossima sessione

- [ ] V0.5.4 — Calendario Tab: vista mensile + navigazione
- [ ] V0.5.5 — Archivio Filtrato per Data
- [ ] V0.5.6 — Dashboard Filtrata per Periodo
- [ ] V0.4.3 — Quick/Favorite UX (da valutare priorità vs Calendario)
- [ ] Verificare rebuild iOS (scadenza 7 giorni)

## Riferimenti

- `docs/STREAM_FEATURE_BACKLOG.md` — backlog completo (32 feature)
- `docs/HERMES_ROADMAP.md` — roadmap versioni
- `docs/STREAM_PRODUCT_ROADMAP.md` — visione prodotto
- `docs/STREAM_TECH_NOTES.md` — note tecniche
- `lib/models/time_filter.dart` — F11 TimeFilter Foundation (✅ pronto)
- `lib/screens/archive_screen.dart` — Archivio (base per F15)
