# STREAM App

STREAM is a Flutter finance app focused on fast movement entry, category analysis, account tracking, and profile-isolated data management.

## Current State

The app currently includes:

- isolated profiles with a dedicated SQLite database per profile
- a guided `+ Movimento` flow for Entrata, Spesa, Trasferimento, and edit prefill
- a shared calculator pad for amount entry with realtime updates and sticky compact amount while scrolling
- transfer selection with separate origin and destination account pickers
- heatmap-based Movimenti views for the user-facing period navigation
- configurable heatmap thresholds and colors from Settings and Movimenti
- categories and subcategories with safe edit rules and duplicate validation
- beneficiaries with searchable suggestion chips in movement forms and a legacy picker that remains available
- quick movements, favorites, import/export, backup/restore, archive navigation, and app-wide currency preferences
- unified movement actions via tap, long-press, and three-dot menu wherever `MovementCard` is used

## Main Modules

- `lib/screens/`
  - app screens for Dashboard, Movimenti, Categorie, Conti, Archivio, Grafici, Beneficiari, Impostazioni, Backup
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
- the guided movement flow was stabilized with a compact top header, always-reachable close/confirm actions, shared amount controller, sticky compact amount, and legacy tests aligned to the step-based UX
- transfer UX now uses a dedicated origin/destination selection flow
- heatmap settings were consolidated and the user-facing Movimenti screen now relies on Heatmap for its default period visualization
- movement actions were centralized in a shared bottom sheet used by long-press and three-dot entry points
- category and subcategory edit flows now allow safe edits even when linked content exists, while destructive actions either archive or require safe reassignment
- duplicate validation now ignores the entity being edited and compares normalized names within the correct namespace
- calculator/input handling was updated so amount updates and form confirmations are consistent, including `0` / `0,00` edge cases
- Titolo, Note e Beneficiario now expose compact focus-aware suggestion chips that appear after 2 characters, deduplicate exact matches, and replace the field value on tap
- archived accounts and archived categories now expose restore actions while preserving icon/color and linked movements
- currency display is routed through a shared preference/formatter so the symbol can be changed from Settings without touching DB schema or converting stored values

## QA Status

- `flutter analyze`: clean from errors, with only pre-existing info-level notes in the project
- `flutter test`: latest declared full suite green (`911` passed, `1` skipped, `912` declared tests across `44` files)
- Hermes Extended QA Audit: `1.641` scenari data-driven, `7.475` controlli/logiche reali, suite finale verde, nessun nuovo P0/P1/P2

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
