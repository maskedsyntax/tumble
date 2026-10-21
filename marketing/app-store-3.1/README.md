# Tumble 3.1 App Store relaunch

The eight-card sequence leads with results, then shows the tools:

1. **Your photos, on film.** — Studio in a phone, with real graded prints around it.
2. **Same moment, new feeling.** — Original / Golden Hour split of one photo, plus the film strip.
3. **Every mood, one tap away.** — one photo in nine looks on a film-negative contact sheet.
4. **Send it as a postcard.** — Finish in Postcard mode, with the other three styles lifted from real captures.
5. **Dial in the mood.** — the film-strength panel, magnified from the real screen.
6. **Fix the frame, right on the photo.** — on-canvas crop and the straighten ruler, magnified.
7. **Every print, kept.** — the Drawer of finished photos and postcards.
8. **Private by design. Pay once.** — the Complete paywall on the navy brand surface.

`scripts/capture-app-store-3.1.sh` rebuilds the app and captures deterministic
6.9-inch Simulator screens into `screenshots/3.1/raw`. `render.sh` compiles
`render.swift` with `scripts/film-grade.swift` and TumbleKit's film catalog, so
every graded photo outside a phone is the app's own output, and writes
`screenshots/3.1/final`. `render-duo.swift` lays the same eight cards out for
the other App Store Connect slots:

| Slot | Size | Folder |
| --- | --- | --- |
| iPhone 6.9" (large Dynamic Island) | 1320 × 2868 | `final` |
| iPhone 6.1"/6.3" (medium Dynamic Island) | 1206 × 2622, resampled from `final` | `final-63` |
| iPhone Duo | 2007 × 2853 | `final-duo` |
| Product page header | 5244 × 2950 | `final-header` |
| Search results (one before/after that reads as a thumbnail) | 3840 × 2560 | `final-search` |

`render.sh` renders every set; `render.sh duo 04` renders one page. There is
no iPhone Duo Simulator yet, so the Duo cards frame the 6.9-inch captures.
Tumble is iPhone-only and has no Watch app, so the iPad and Watch slots stay
empty. Phone screens are never edited; screens that show the
Save bar use free Core films so no lock appears. Photos come from
`mockups-appstore-v7/photo-library` (generated for Tumble; see its PROMPTS.md).

## Product Page Optimization

After 3.1 is live, run one 50/50 test:

- Control: hero → compare → looks → postcard → strength → crop → drawer → privacy.
- Treatment: compare → hero → looks → postcard → strength → crop → drawer → privacy.
- Keep the name and subtitle identical.
- Select Apple's confidence winner, or stop at the 90-day limit.
- Primary measure: product-page conversion. Guardrails: download volume and
  downstream Studio-to-export completion.
