# Tumble App Store screenshots — v3, the look-first set

Six portrait screenshots at **1242 x 2688**, opaque 24-bit RGB PNG. Upload in
the numbered order.

## Upload order, and why it is this order

The v2 set opened on the twelve-shot roll — it asked a stranger to care about a
constraint before they had seen anything they wanted. Search results show the
first two or three, so those carry the whole pitch. This set leads with the
look, and the roll arrives once someone is already interested.

| # | File | The hook |
|---|---|---|
| 1 | `01-the-look.png` | **"Not a filter. A film stock."** One photo split down the middle: straight out of the camera on the left, Warm Archive on the right. The whole promise in one frame, legible at thumbnail size. |
| 2 | `02-every-film.png` | **"One shot. Every film."** Nine looks over the same photograph, so the library reads as range rather than a list of names. |
| 3 | `03-shake-to-develop.png` | **"Shake it. Watch it come up."** The ritual nobody else has — blank, shaking, developed, in the order it happens. |
| 4 | `04-postcards.png` | **"Made to be sent, not scrolled."** The keepsake: a framed print with a handwritten note. |
| 5 | `05-the-drawer.png` | **"A pile of prints. Not a grid."** The Drawer as the physical thing it imitates. |
| 6 | `06-the-roll.png` | **"A roll that runs out."** The constraint, then the pay-once promise — the last thing read before the Get button. |

Every page carries one line of small print at the foot ("no subscriptions", "on
device · no account · no cloud"), so the privacy and pricing stance lands even
if a reader only swipes.

## Honesty

Each page is a composed editorial frame rather than a device capture — the same
art direction as the v1 and v2 sets — but nothing in it is faked:

- The photographs run through the **real grade pipeline**, ported filter-for-
  filter from `app/TumbleKit/Filter/TumblePhotoFilter.swift`, driven by the
  **real catalog** in `app/TumbleKit/Filter/FilmStock.swift`, which is compiled
  into the renderer. A look on these pages is the look the app produces.
- Stock names, pack structure, frame names (Classic, Vintage, Film, Deckled),
  roll size, and every price come from the shipping code.

If a grade, a name, or a price changes, re-render before submitting — these
pages will follow the code automatically, but only if the renderer is run.

## Photography

The 18 CC0 / public-domain photographs in `mockups-appstore/assets/archive/`.
Their source and licence record is in `mockups-appstore/PHOTO-LICENSES.md`. No
AI-generated imagery, no simulator placeholder scenes.

## Rebuild

```sh
./mockups-appstore-v3/render.sh
```

Compiles `main.swift` together with the app's film-stock catalog and writes the
six PNGs here. The PNGs are not committed — one command regenerates them, and a
stale screenshot is worse than none.
