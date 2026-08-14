# Tumble App Store screenshot set

Six portrait marketing mockups for App Store Connect, each exported at **1242 × 2688 px** as an opaque 24-bit RGB PNG with no alpha channel. The renderer keeps the established layout on its internal design canvas and emits only this accepted submission format.

Upload order:

1. `01-daily-roll.png` — establishes the intentional 12-shot daily constraint.
2. `02-shake-to-develop.png` — makes the immediate shake-to-reveal interaction visible and explains saved partial progress.
3. `03-the-drawer.png` — presents the private, on-device Drawer and recent daily collections without feed language or social UI.
4. `04-memory-filters.png` — compares the original with Faded Instant and Warm Archive, then covers photo and postcard export.
5. `05-full-archive.png` — shows the complete older-roll Archive.
6. `06-own-it-once.png` — establishes that the complete ritual is free, then frames Plus and Unlimited as optional one-time roll sizes.

These are standalone editorial compositions inspired by Tumble’s graincore palette, instant-print materials, typography, and tactile product language. They contain no simulator screenshots, phone frames, navigation bars, app controls, or recreated app screens.

Hero photography comes from the repository’s `test-images/` set. Filter comparisons use the real outputs in `test-output/faded-instant/` and `test-output/warm-archive/`. The Archive uses 18 distinct CC0 or public-domain photographs stored in `assets/archive/`; its full source and license record is in `PHOTO-LICENSES.md`. No AI-generated imagery is used.

The filter comparison applies a controlled preview-only color emphasis on top of those real outputs so Faded Instant and Warm Archive remain distinguishable at App Store thumbnail size.

To rebuild the final layouts:

```sh
swift mockups-appstore/render.swift
```
