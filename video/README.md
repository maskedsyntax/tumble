# Tumble promo film (Remotion)

Vertical cuts rendered in code from the app's own palette, type ramp, print
geometry and photography.

| Composition | Length | Use |
|---|---|---|
| `TumblePreview` | 28.4 s | **App Store Connect app preview for 2.0** (30 s cap) |
| `TumbleFilm` | 38.9 s | Site hero, YouTube, Reels / TikTok / Shorts |
| `TumbleFilmShort` | 26.8 s | The 1.2 preview, kept until 2.0 ships |

All 1080 × 1920, 30 fps, H.264.

```sh
npm start                                   # Remotion Studio
npx remotion render TumblePreview out/tumble-preview-2.0.mp4
npx remotion render TumbleFilm out/tumble-film.mp4
npm run typecheck
```

## The 2.0 preview

`src/preview/` — six beats, cut look-first, because the App Store shows the
opening seconds and the 1.2 cut spent them on the twelve-shot roll: a
constraint, asked of someone who has not yet seen anything they want.

| Beat | Hook | Why it is there |
|---|---|---|
| `Open` | *Not a filter. A film stock.* | The grade sweeps across a real photograph. One frame that answers "why install this". |
| `Looks` | *One shot. Every film.* | The longest beat, because the stocks are the product. Twelve looks cycle on one photo, then the shelf they came from. |
| `Develop` | *Shake it. Watch it come up.* | The ritual nobody else has, at its real pace. |
| `Postcards` | *Made to be sent.* | The keepsake, mounted four ways. |
| `Drawer` | *A pile of prints.* | The Drawer as the heap it imitates. |
| `Close` | *Twelve shots a day.* | Constraint, then the offer: pay once, no account, no cloud. |

The looks are not CSS approximations. `scripts/render-video-looks.sh` renders
one photograph through the app's real catalog and the real grade pipeline
(`scripts/film-grade.swift`, ported from `TumblePhotoFilter`) into
`public/looks/`. Re-run it after tuning any grade, or the film drifts from the
app.

> **Before uploading**: Apple expects an app preview to be captured from the
> app running on a device. This film is a composed piece using the app's own
> surfaces rather than screen capture, which is how the 1.2 cut was built too —
> but that cut was never submitted, so the treatment is untested with App
> Review. If it comes back rejected, the fix is a screen recording of the same
> six beats, and this cut still earns its keep on the site and social.


## Why it looks like the app

Nothing here is a stylised impression of Tumble; the film is built from the
same values the app is:

- **Palette** — `src/theme.ts` is a port of `TumbleKit/Theme/Palette.swift`.
- **Type** — Fraunces / Inter / Caveat, the three faces in
  `TumbleKit/Theme/Typography.swift`.
- **Prints** — `src/components/Print.tsx` reproduces `TumbleKit/Views/PrintView.swift`:
  6 % padding with a 9 % deeper bottom margin, square photo, warm aged grade,
  grain, vignette, sheen. The develop reveal uses the app's actual formula —
  `saturation(progress)` under a white wash of `(1 − progress) × 0.65`.
- **Frames** — `src/components/Frames.tsx` follows `TumbleKit/Postcard/`:
  Classic, Vintage, Film, Deckled, with the same labels as the in-app picker.
- **Grain** — tiled fractal noise on overlay blend, as in `Theme/Grain.swift`.
- **Photography** — real files from `test-images/`, real filter outputs from
  `test-output/`, and the CC0 / public-domain archive set in
  `mockups-appstore/assets/archive/` (licences in `mockups-appstore/PHOTO-LICENSES.md`).
  No Simulator captures, no AI imagery, no phone shells.

## Why it should convert

Persuasion here comes from sequencing and specificity, not from claims:

1. **Cover frame is not blank.** Frame 0 already carries the kicker and the
   headline, because that frame is the thumbnail on every social platform.
2. **Constraint → ritual → keepsake**, the order the App Store screenshot set
   uses. The limit is stated before it is justified.
3. **The shake is shown, not described.** The develop scene is the longest in
   the film, and the pause mid-develop demonstrates saved progress instead of
   asserting it.
4. **Objections cleared before the ask.** Privacy, then price, then one
   instruction.
5. **Price framed as relief.** Free tier featured; the paid tiers are labelled
   "once" and followed by "No subscription."

Every factual line traces to shipped behaviour: twelve free shots a day
(`Entitlement.dailyQuota`), 72 at $5.99 and unlimited at $11.99 as one-time
purchases (`Entitlement.priceLabel`), on-device storage, no account, no feed,
press-and-hold under Reduce Motion. If any of those change, update the copy
before rendering again.

## Sound

`public/warm-tape-drift.m4a` — "Warm Tape Drift", generated in Suno under a
paid plan, so commercial use is covered. Mounted by `src/components/Music.tsx`.

The track is 2:33 and the cuts use a window of it rather than a fade in and out
of an arbitrary spot. Measured from the source PCM:

| Track time | Material |
|---|---|
| 118.0 – 121.9 s | plucked and gappy — near-silence between notes |
| 121.9 s | the plucks resolve into a sustained pad |
| 130 – 148 s | fullest, loudest sustained passage in the track |
| 148.0 – 153.3 s | a genuine outro, decaying to silence |

Both cuts are anchored so the track's **real ending lands on the film's
ending** — the decay falls under "Wait for it.", not under the call to action,
and no fade-out has to be invented.

- **Full cut, offset 112.77 s.** The plucked passage runs under the roll
  counter and the twelve slots lighting up; it resolves into the sustained pad
  at 9.13 s, which is the frame the first shake burst starts on (verified at
  ±0.03 s in the render). The fullest passage carries the middle and the CTA;
  the outro decays from 35.7 s to silence.
- **Short cut, offset 124.91 s.** Anchored on the ending only — the two events
  can't both be hit in 26.7 s, and a clean ending matters more for an App Store
  preview. Full through the pricing cards, decaying under the closing line.

Levels: −15.2 LUFS integrated, −4.9 dBFS true peak (short cut −15.0 / −5.0).
That sits just under the −14 LUFS that Instagram, TikTok and YouTube normalise
to, so the platforms lift it rather than clamping it.

To swap the track, replace the file and re-derive the offset — the analysis is
just RMS and chroma over the decoded PCM; don't keep these numbers.
