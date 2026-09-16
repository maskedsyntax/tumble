# Tumble App Store screenshots

This is the approved six-card direction: Tezza-inspired typography and paper
texture wrapped around genuine Tumble Simulator screens.

## Final order

1. `01-shoot-real-film.png` — live camera with Faded Instant
2. `02-twenty-one-looks.png` — Film tool and look selection
3. `03-fine-tune.png` — Crop tool with a 4:5 composition
4. `04-postcard.png` — Classic postcard frame and note
5. `05-before-after.png` — the matching original image
6. `06-import-any-photo.png` — the native photo picker

`photo-library` contains the 15 generated editorial photographs used to fill
every visible slot in the final picker capture. Its prompt set is documented in
`photo-library/PROMPTS.md`.

The files in this directory are 1320 × 2868 for the 6.9-inch App Store slot.
The `6.5-inch` directory contains 1242 × 2688 fallbacks.

Run `./render-01.sh` from this directory or the repository root to rebuild the
6.9-inch compositions from the captures in `source`.

The promotional photography is injected only into Debug Simulator builds from
the app's Documents directory. It is not stored in, or copied into, the release
app bundle.
