# Asset audit

## Available

| File | Kind | Best use |
| --- | --- | --- |
| `raw/01-neon-crossing.png` | generated source photo | moving crowd / opening hook |
| `raw/02-elevated-train.png` | generated source photo | lateral train-speed match cut |
| `raw/03-rain-boulevard.png` | generated source photo | rain traffic / light-leak reveal |
| `raw/04-flyover-cyclist.png` | generated source photo | panning cyclist / daytime contrast |
| `raw/05-skyline-trails.png` | generated source photo | skyline climax / traffic trails |
| `graded/*` | real rendered filter outputs | honest before/after results |
| `app/Tumble/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | product icon | end card |

## Missing but useful

- Licensed music and final platform-native audio mix. The silent visual cut remains complete without it.

## Safe to simulate

- cursor / tap / scroll / focus / camera move

## Must not fabricate

- testimonials, metrics, customer results, fake UI dashboards

## Studio copies

Files copied or linked into `ad-studio/public/<campaign>/`:

- `01-before.png` / `01-after.jpg` — Warm Archive
- `02-before.png` / `02-after.jpg` — Everyday
- `03-before.png` / `03-after.jpg` — Pool Party
- `04-before.png` / `04-after.jpg` — Disposable
- `05-before.png` / `05-after.jpg` — Golden Hour
- `logo.png`

## Provenance

The five clean source photos were created with the built-in image-generation model for this campaign. Prompt set: photorealistic contemporary city photography, strong visible subject/camera motion, vertical-safe composition, neutral modern-digital starting color, no logos, text, watermark, grain, or pre-existing vintage cast. Scene specifics were neon pedestrian flow, an elevated train, rainy boulevard traffic, a cyclist beneath a flyover, and skyline traffic trails.

All after images were produced locally with `scripts/render-nostalgia-stills.swift`, `scripts/film-grade.swift`, and `app/TumbleKit/Filter/FilmStock.swift`. They are not CSS approximations.

## Filter revision

The first three selections were replaced after visual review. Warm Archive preserves the crossing's neon separation while adding a genuinely different amber film character; Everyday makes the moving train cleaner and more forceful than the low-contrast Overcast result; Pool Party keeps the rain scene's architecture and reflections legible without the broad orange veil introduced by Light Leak.
