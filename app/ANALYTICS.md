# Tumble analytics contract

Tumble sends anonymous product analytics to PostHog project `585380`. The app
does not call `identify`; the SDK-generated installation identifier is shared
with the Lock Screen capture extension through `group.com.tumble`.

Every event includes `schema_version` and `build_channel`. Custom events also
include `entitlement` and (when known) `source_screen`. Production insights
must filter to `build_channel = app_store`.

## Events

| Event | Required properties |
| --- | --- |
| `onboarding_started` | common properties |
| `onboarding_step_completed` | `step` |
| `onboarding_completed` | `path`, `tier` |
| `photo_captured` | `source`; `remaining_after` when limited |
| `photo_developed` | `source`, `method`, `film_stock_id` |
| `photo_removed` | `state` |
| `film_stock_selected` | `film_stock_id`, `pack_id` |
| `postcard_frame_selected` | `frame_style`, `scope` |
| `photo_saved` | `format`, `frame_style`, `photo_count` |
| `photo_save_failed` | `reason`, `format`, `photo_count` |
| `paywall_viewed` | `type`, `source`; optional `pack_id`, `remaining_shots` |
| `purchase_started` | `product_id`, `product_type`, `source` |
| `purchase_finished` | `product_id`, `product_type`, `source`, `outcome` |
| `restore_finished` | `source`, `outcome`, `entitlement` |
| `permission_responded` | `permission`, `outcome`, `context` |

Screens use PostHog's `$screen` event with the stable names declared by
`AnalyticsScreen`. PostHog also captures application lifecycle and `$exception`
events in the main app.

## Privacy constraints

- Never add photo bytes, photo IDs, filenames, captions, free-form text, URLs,
  contacts, location, or advertising identifiers.
- Session replay masks all text, images, and sandboxed system views. Logs and
  network telemetry are disabled, and replay pauses while the live camera is
  open.
- The Lock Screen extension sends `photo_captured` only; it never records
  screens, lifecycle, errors, or replay.
- `TumbleAnalytics` is the sole SDK boundary. UI and domain files must not
  import `PostHog` directly.

## PostHog workspace

- Existing dashboard: `Analytics basics (wizard)`, ID `2047785`.
- Rename it to `Tumble — Product Health` and filter its production tiles to
  `build_channel = app_store`.
- Create `Tumble — Revenue & Reliability` for paywall conversion, purchase
  outcomes, save failures, exceptions, and replay playlists.
- Project timezone: `Asia/Kolkata`; IP/geolocation enrichment: disabled;
  replay retention: 30 days.

Dashboard definitions:

| Dashboard | Tile | Definition |
| --- | --- | --- |
| Product Health | Activation | Funnel: `onboarding_started` → `photo_captured` → `photo_developed` → `onboarding_completed`, seven-day conversion window |
| Product Health | Core action | Weekly unique installations performing `photo_captured`, `photo_developed`, and `photo_saved` |
| Product Health | Capture-to-develop | Funnel: `photo_captured` → `photo_developed`, broken down by capture `source` |
| Product Health | Retention | New users who complete onboarding and return for `photo_captured`, shown as D1/D7/D30 |
| Product Health | Feature adoption | Weekly uniques for `film_stock_selected` and `postcard_frame_selected` |
| Revenue & Reliability | Roll conversion | Funnel: roll `paywall_viewed` → `purchase_started` → completed `purchase_finished`, broken down by `source` |
| Revenue & Reliability | Film conversion | The same funnel for film-pack and film-bundle product types, broken down by `pack_id` |
| Revenue & Reliability | Purchase outcomes | `purchase_finished` count broken down by `outcome` and `product_type` |
| Revenue & Reliability | Save reliability | Formula: `photo_save_failed` / (`photo_saved` + `photo_save_failed`), broken down by `reason` |
| Revenue & Reliability | Crashes | `$exception` count and unique affected installations by app version |
| Revenue & Reliability | Permissions | `permission_responded` broken down by `permission` and `outcome` |

Create replay playlists for sessions containing `$exception` or
`photo_save_failed`. Keep the base replay sample at 10%; exceptions and save
failures should be retained at 100% through server-side replay triggers.

## App Store privacy

`AppPrivacy.json` is the canonical App Store Connect declaration for this
integration. It declares anonymous device identifiers, product interaction,
other usage data, purchase history, crash data, and other diagnostics. None are
linked to the user or used for tracking; photo and replay content is not
declared because all images and text are masked before replay capture.
