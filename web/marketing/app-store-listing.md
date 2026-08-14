# App Store listing — look-first rewrite

Ready to paste into App Store Connect. Character counts are validated against
Apple's limits. Nothing here requires a new build except the screenshots and
the app preview video — **name, subtitle, keywords, description, and
promotional text can all ship as a metadata-only update today.**

## Why this changes

The current subtitle, "Shoot, shake, collect prints", spends 30 indexed
characters on words nobody searches. Apple's search index is built from the
**name + subtitle + keywords** fields only — the description is not indexed.
So today the app is competing for "instant camera" alone, against every
established camera app, with zero ratings to rank on.

Every field below targets terms with real search demand, and no word is
repeated across fields (a repeat is a wasted indexed character).

---

## Name — 19/30

```
Tumble: Film Camera
```

"Film camera" is the highest-volume term the app can honestly claim. Keeps the
brand first so existing links and word-of-mouth still work.

## Subtitle — 30/30

```
Retro filters & instant prints
```

Uses the full field. Claims *retro*, *filters*, *instant*, *prints* — four
searchable terms, none of them duplicated from the name.

## Keywords — 92/100

```
disposable,vintage,polaroid,analog,35mm,grain,aesthetic,editor,photo,darkroom,lomo,nostalgic
```

No spaces after commas (a space costs an indexed character). No word repeated
from the name or subtitle.

> ⚠️ **"polaroid" is a registered trademark.** Apple does sometimes reject
> listings for trademarked keywords, and Polaroid has historically enforced
> against camera apps. It is high-volume and highly relevant, so it's a real
> judgement call. Trademark-free alternative, 91/100:
>
> ```
> disposable,vintage,analog,35mm,grain,aesthetic,editor,photo,darkroom,lomo,nostalgic,develop
> ```

## Promotional text — 91/170

Editable **without a new build** — this is the field to reuse for every future
film pack release.

```
New: four postcard frames and a handwritten note. Save any shot as a keepsake you can send.
```

## Description — first two lines

Only the first two lines show before "more", so they carry the whole pitch.
Lead with the look; the roll comes after the reader is already interested.

```
Real film looks, straight out of your iPhone camera — grain, halation, faded
blacks, and warm archive tones on every shot you take.

Tumble is a film camera, not a filter you bolt on afterwards. Shoot, shake the
phone to develop the print, and watch the image come up the way it used to.

WHAT MAKES IT LOOK LIKE FILM
• Hand-graded film stocks with real grain, halation bloom and lifted blacks
• Shake to develop — the image rises out of a blank print, like it should
• Four postcard frames: Classic Instant, Vintage Postcard, Bordered Film,
  Deckled Edge — with a handwritten note on the print itself
• Prints age over time, picking up grain, vignette and patina

A DAILY ROLL
Twelve shots a day, reset every morning. Not a limit for its own sake — it's
what makes you actually look before you press the shutter. Want more? Plus and
Unlimited are one-time unlocks.

PRIVATE BY DEFAULT
Everything stays on your device. No account, no cloud, no analytics SDK, no
feed. Your Drawer is yours.

PAY ONCE
No subscriptions. No renewals. Ever.
```

## Screenshots — new order

Reuse the code-rendered pipeline in `mockups-appstore-v2/render.swift`. The
existing set opens on the 12-shot roll, which asks a stranger to care about a
constraint before they've seen anything they want.

| Slot | Now | Should be |
|---|---|---|
| 1 | Daily roll | **The look** — before/after on one photo |
| 2 | Shake to develop | **The stock library** — one photo, many looks |
| 3 | Postcard frames | Shake to develop |
| 4 | The Drawer | Postcard frames |
| 5 | Memory filters | The Drawer |
| 6 | Full archive | Daily roll |
| 7 | Own it once | Own it once |

Slots 1–2 need the expanded film stock library to exist first, so they land
with the engine work. Slots 3–7 can be reordered today.

## Also add: an app preview video

The listing currently has none. `video/out/tumble-preview-appstore.mp4` is
already rendered at 26.8s, under Apple's 30s cap, 1080×1920 H.264 — it can go
up as-is.

## Before assuming any of this is the problem

Zero impressions is extreme even for an unranked app. Check in App Store
Connect first:

- **Availability** — is it live in all territories, or just one?
- **Keyword field** — was it ever filled in? An empty field is a common cause.
- **Category** — Photo & Video, with a sensible secondary.
- **Age rating / content** — nothing suppressing it from search.
- **App Analytics date range** — confirm you're reading impressions over a
  range where the app was actually live.
