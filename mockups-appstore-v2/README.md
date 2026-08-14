# Tumble App Store screenshot set — postcard frames update

Seven portrait marketing mockups for App Store Connect, each exported at
**1242 × 2688 px** as an opaque 24-bit RGB PNG. Upload the numbered PNGs in
order.

## Upload order

1. `01-daily-roll.png` — hook: the intentional 12-shot daily roll.
2. `02-shake-to-develop.png` — hook: shake-to-develop and saved partial
   progress.
3. `03-postcard-frames.png` — hook: the new Classic, Vintage, Film, and
   Deckled postcard frames.
4. `04-the-drawer.png` — the private, on-device Drawer and recent daily rolls.
5. `05-memory-filters.png` — Original, Faded Instant, and Warm Archive, plus
   photo or framed-postcard export.
6. `06-full-archive.png` — the complete older-roll Archive.
7. `07-own-it-once.png` — the complete free ritual and optional one-time roll
   sizes.

The first three images carry the conversion story: **constraint, ritual,
keepsake**.

## Art direction and App Review accuracy

This set deliberately follows the original Tumble screenshot direction. Every
image is a standalone, code-rendered editorial composition; it uses no
Simulator captures, phone shells, navigation controls, or copied app screens.

The product details shown here are tied to the current implementation:

- the four frame illustrations follow the geometry and treatments in
  `ClassicInstantFrame`, `VintagePostcardFrame`, `BorderedFilmFrame`, and
  `DeckledEdgeFrame`;
- frame labels match the current picker: Classic, Vintage, Film, and Deckled;
- the Classic date, Vintage postmark, Film date burn, Deckled tape and torn
  edge, handwritten notes, and frame proportions are all represented;
- Faded Instant and Warm Archive use the repository's real filtered outputs;
- plan sizes and fallback USD labels match the current entitlement model:
  12 Free, 72 Plus at $5.99 once, and Unlimited at $11.99 once.

If any of those product details change, update the renderer before submitting
the next build. This avoids showing obsolete controls or a frame treatment that
the shipped app no longer produces.

## Photography

Hero photography comes from `test-images/`. Filter comparisons and postcard
frames use the real outputs in `test-output/faded-instant/` and
`test-output/warm-archive/`. The Archive reuses the 18 CC0 or public-domain
photographs in `mockups-appstore/assets/archive/`; their source and license
record is in `mockups-appstore/PHOTO-LICENSES.md`.

No Simulator placeholder scenes or AI-generated images are used.

## Rebuild

```sh
swift mockups-appstore-v2/render.swift
```

Only the seven numbered PNG files at the root of this directory are App Store
deliverables. Visually inspect all seven after any renderer, font, image, frame,
filter, plan, or copy change.
