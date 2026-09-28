# Tumble analytics contract

Tumble sends anonymous, consent-gated product analytics to PostHog project
`585380`. Schema version 3 describes the canvas-first 3.1 product. The app
does not call `identify`; no event is collected or backfilled before consent.

Every event includes `schema_version`, `build_channel`, and `entitlement`.
Production insights must filter to `build_channel = app_store`.

## Primary funnel

`home_viewed → source_selected → studio_opened → finish_opened → export_completed`

| Event | Properties |
| --- | --- |
| `home_viewed` | common properties |
| `home_entry_selected` | `entry_point`; optional `film_stock_id`, `intended_format` |
| `source_selected` | `source`: `library` or `camera` |
| `source_preparation_finished` | `source`, `outcome`; safe optional `reason` |
| `studio_opened` | `source`, `initial_film_stock_id` |
| `film_previewed` | `film_stock_id`, `pack_id`, `premium` |
| `original_comparison_used` | common properties |
| `finish_opened` | `film_stock_id`, `premium` |
| `finish_format_selected` | `format`: `photo` or `postcard` |
| `postcard_configured` | `frame_style`, `has_note` (boolean only) |
| `premium_export_gated` | `film_stock_id`, `action` |
| `export_started` | `format`, `action`, `premium` |
| `export_completed` | `format`, `action`, `frame_style` |
| `export_failed` | safe `reason`, `format`, `action` |
| `paywall_viewed` | `type`, `source` |
| `purchase_started` / `purchase_finished` | product, source, safe outcome |
| `restore_finished` | source, safe outcome, entitlement |
| `permission_responded` | permission, outcome, context |

Legacy 3.0 events remain defined only so upgrades and extension code keep
working. They are not part of the 3.1 funnel.

## Privacy constraints

- Never send pixels, image data, filenames, photo IDs, note content, captions,
  crop coordinates, URLs, contacts, location, or advertising identifiers.
- `has_note` is a boolean. The handwritten note itself never crosses the
  analytics boundary.
- Session replay masks all text, images, and sandboxed system views. Logs and
  network telemetry are disabled, and replay pauses while the camera is open.
- `TumbleAnalytics` is the sole SDK boundary. UI and domain files must not
  import PostHog directly.

## Measurement views

| View | Definition |
| --- | --- |
| Home discovery | `home_entry_selected → studio_opened`, broken down by `entry_point` |
| Editing funnel | Primary funnel, seven-day conversion window, broken down by source |
| Studio completion | `studio_opened → export_completed`, broken down by format |
| Film discovery | `film_previewed`, broken down by pack and premium |
| Complete conversion | `premium_export_gated → paywall_viewed → purchase_finished(completed)` |
| Export reliability | `export_failed / (export_completed + export_failed)`, by reason and action |
| Postcard adoption | `finish_format_selected`, photo versus postcard |

Initial launch targets are approximately 3% App Store conversion and at least
40% Studio-to-export completion among consenting users. Recalibrate after the
first 30 days because current volume is low.

`AppPrivacy.json` remains the canonical App Store Connect privacy declaration.
