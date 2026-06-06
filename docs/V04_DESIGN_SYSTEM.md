# STREAM V0.4 — Design System

## Principi di Design

- **Content-first**: i dati finanziari sono il centro, la UI è al loro servizio
- **Gerarchia visiva forte**: numeri grandi, etichette piccole, azioni secondarie
- **Pochi bordi, nessuna linea**: le card si distinguono per luminosità, non per bordi
- **Spazio bianco generoso**: 16px margini, 12px tra card
- **Dark mode nativa**: sfondo quasi nero, testo 90% bianco, accenti vibranti
- **Look premium**: card arrotondate (16px), ombre sottili, sfumature leggere

## Palette Colori

| Token | Hex | Uso |
|-------|-----|-----|
| `canvas` | `#0C0E12` | Sfondo principale (near-black) |
| `surface` | `#15171D` | Card livello 1 |
| `surfaceElevated` | `#1E2028` | Card livello 2, input bg |
| `surfaceHighlight` | `#272A33` | Hover/press states |
| `primary` | `#4B7BFF` | Accento blu, CTA, FAB |
| `income` | `#34C759` | Entrate, saldi positivi |
| `expense` | `#FF453A` | Uscite, saldi negativi |
| `warning` | `#FFD60A` | Warning, lock type |
| `textPrimary` | `#EBEBF5` | Testo principale |
| `textSecondary` | `#8E8E93` | Testo secondario |
| `textMuted` | `#636366` | Testo terziario, placeholder |

## Tipografia

| Style | Size | Weight | Letter Spacing | Uso |
|-------|------|--------|----------------|-----|
| `display` | 40px | Bold (700) | -1.5px | Patrimonio, numeri grandi |
| `h1` | 28px | SemiBold (600) | -0.5px | Titoli schermata |
| `h2` | 20px | SemiBold (600) | 0 | Sezioni |
| `h3` | 17px | SemiBold (600) | 0 | Card title, intestazioni |
| `body` | 15px | Regular (400) | 0 | Testo standard |
| `bodyBold` | 15px | SemiBold (600) | 0 | Testo enfatizzato |
| `caption` | 13px | Regular (400) | 0.2px | Etichette |
| `captionBold` | 13px | SemiBold (600) | 0.2px | Valori KPI |
| `micro` | 11px | Medium (500) | 0.5px | Label uppercase |
| `amount` | 17px | SemiBold (600) | -0.2px | Importi nei tile |
| `amountLarge` | 40px | Bold (700) | -1.5px | Importi hero |

## Spacing Scale

| Token | Value | Uso |
|-------|-------|-----|
| `xs` | 4px | Gap minimo |
| `sm` | 8px | Gap piccolo |
| `md` | 12px | Gap medio, padding interno card |
| `lg` | 16px | Margini schermo, padding card |
| `xl` | 20px | Padding hero card |
| `xxl` | 24px | Padding empty state |
| `section` | 32px | Gap tra sezioni |

## Border Radius

| Token | Value | Uso |
|-------|-------|-----|
| `sm` | 8px | Icon container, badge |
| `md` | 12px | Card, input, button |
| `lg` | 16px | Card grandi, bottom sheet |
| `xl` | 20px | Hero card, dialog |
| `full` | 100px | Chip, avatar |

## Componenti

### Card
- Colore: `surface` (#15171D)
- Border radius: 12px (md)
- Nessun bordo
- Padding interno: 12-16px
- Margine bottom: 8px

### Input
- Sfondo: `surfaceElevated` (#1E2028)
- Border radius: 12px
- Nessun bordo a riposo
- Bordo primario 1.5px al focus
- Padding: 16px orizzontale, 14px verticale

### Button (Filled)
- Sfondo: `primary` (#4B7BFF)
- Testo: bianco
- Border radius: 12px
- Padding: 24px orizzontale, 14px verticale
- Nessuna ombra

### FAB
- Sfondo: `primary` (#4B7BFF)
- Forma: cerchio
- Nessuna ombra

### Bottom Navigation
- Sfondo: `surface` (#15171D)
- Selected: `primary` (#4B7BFF)
- Unselected: `textMuted` (#636366)
- Label style: micro (11px, caps)
- Divisore superiore: 0.5px

### Dialog
- Sfondo: `surface` (#15171D)
- Border radius: 20px (xl)
- Nessuna ombra

### Bottom Sheet
- Sfondo: `surface` (#15171D)
- Border radius: 20px solo superiore

## Schermate Aggiornate

### Dashboard
- Hero card patrimonio con gradiente blu
- KPI grid 3 colonne (Entrate, Uscite, Saldo)
- Lista transazioni recenti senza card (solo righe)
- Empty state con icona

### Movimenti
- Card movimento con icona categoria rettangolare
- Note in container separato con icona
- Popup menu con `more_horiz`
- Settings con `tune` icon
- ListView.separated per spaziatura pulita

### Conti
- Card conto con icona rettangolare colorata
- Saldo prominente a destra
- Popup menu integrato nel tile

### Categorie
- Card categoria con icona rettangolare
- Type badge colorato (Entrata verde, Uscita rossa)
- Sezioni con count badge
- Popup menu integrato

### Form Movimento
- Input con sfondo scuro, nessun bordo a riposo
- Dropdown con stesso stile input
- SegmentedButton temizzato
- Spaziatura coerente

## Account Color (V0.4.1)

Ogni account ha un proprio colore:
- **Default**: `0xFFEF5350` (rosso salmone, `StreamColorPalette.defaultColor`)
- **Modello**: `Account` contiene `int color` persistito in SQLite
- **ColorPicker**: ora funzionale — il colore scelto viene salvato via `updateAccount()` con parametro `color` opzionale
- **Rendering**: Icona account in tutte le viste usa `account.color` come colore di sfondo
  - accounts_screen: card bg
  - movement_form: dropdown icon
  - movement_picker: 3 punti (Rapidi, Preferiti, lista)
  - dashboard_screen: tile movimento
  - movements_screen: card movimento
- **Regola**: mai usare `StreamColors.primary` per account. Risolvere sempre via `accountId → db.accounts`
