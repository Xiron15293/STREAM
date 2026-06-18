# STREAM App

STREAM is a Flutter finance app focused on fast movement entry, category analysis, account tracking, and profile-isolated data management.

## Current State

The app currently includes:

- isolated profiles with a dedicated SQLite database per profile
- a guided `+ Movimento` flow for Entrata, Spesa, and Trasferimento
- a shared calculator pad for amount entry with realtime updates
- transfer selection with separate origin and destination account pickers
- heatmap-based Movimenti views for the user-facing period navigation
- configurable heatmap thresholds and colors from Settings and Movimenti
- categories and subcategories with safe edit rules and duplicate validation
- beneficiaries with searchable suggestion chips in movement forms
- quick movements, favorites, import/export, backup/restore, archive navigation, and app-wide currency preferences

## Main Modules

- `lib/screens/`
  - app screens for Dashboard, Movimenti, Categorie, Conti, Archivio, Beneficiari, Impostazioni, Backup
- `lib/widgets/`
  - reusable UI for movement forms, calculator pad, heatmap cards, category selectors, account selectors, and cards
- `lib/data/`
  - `AppDatabase`, `SQLiteService`, profile registry, preferences, backup helpers, import pipelines
- `lib/models/`
  - domain models for movements, accounts, categories, subcategories, beneficiaries, profiles, backups, and filters
- `docs/`
  - roadmap, changelog, next-session notes, and technical status documents

## Recent Stabilization Work

- profile isolation was hardened so each profile uses its own SQLite file and stale DB references are avoided on profile switch
- the guided movement flow was stabilized and legacy tests were aligned to the new step-based UX
- transfer UX now uses a dedicated origin/destination selection flow
- heatmap settings were consolidated and the user-facing Movimenti screen now relies on Heatmap for its default period visualization
- category and subcategory edit flows now allow safe edits even when linked content exists, while destructive actions remain blocked
- duplicate validation now ignores the entity being edited and compares normalized names within the correct namespace
- calculator/input handling was updated so amount updates and form confirmations are consistent
- Titolo, Note e Beneficiario now expose compact suggestion chips in the movement forms and legacy picker
- currency display is routed through a shared preference/formatter so the symbol can be changed from Settings without touching DB schema

## QA Status

- `flutter analyze`: clean from errors, with only pre-existing info-level notes in the project
- `flutter test`: full suite green (`910` tests on the latest run)
- Hermes Extended QA Audit: data-driven matrix, stress/extensive checks, and full suite all passed

## Useful Commands

```bash
flutter analyze
flutter test
```

## Documentation Map

- [docs/NEXT_SESSION.md](docs/NEXT_SESSION.md)
- [docs/HERMES_ROADMAP.md](docs/HERMES_ROADMAP.md)
- [docs/CHANGELOG.md](docs/CHANGELOG.md)
- [docs/STREAM_TECH_NOTES.md](docs/STREAM_TECH_NOTES.md)
- [docs/STREAM_FEATURE_BACKLOG.md](docs/STREAM_FEATURE_BACKLOG.md)
