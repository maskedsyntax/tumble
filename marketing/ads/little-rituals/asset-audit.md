# Asset audit

## Available

| File | Kind | Best use |
| --- | --- | --- |
| `raw/01-morning-coffee.png` | Generated lifestyle source | Dawn hook; steam-led reveal |
| `raw/02-flower-walk.png` | Generated lifestyle source | Bright daytime energy |
| `raw/03-record-shop.png` | Generated lifestyle source | Tactile sleeve-flip transition |
| `raw/04-rainy-bus.png` | Generated lifestyle source | Reflective blue-hour pause |
| `raw/05-diner-fries.png` | Generated lifestyle source | Flash-lit human climax |
| `graded/*` | 105 real renderer outputs | Filter comparison and selected same-pixel afters |
| `logo.png` | Tumble app icon | End card |

## Selected filter decisions

| Scene | Selected look | Why this image benefits |
| --- | --- | --- |
| Morning coffee | Warm Archive | Warms the practical light and table textures without losing the cool dawn outside. |
| Flower walk | Everyday | Adds clean color and mild grain while preserving natural skin, white fabric, and petal detail. |
| Record shop | Date Stamp | Deepens the wood and sleeve tones; the burned-in date suits the record-store artifact. |
| Rainy bus | Pool Party | Separates blue rain from amber streetlights and keeps the reflected face readable. |
| Diner fries | Everyday | Adds warmth, clean color, and light grain while preserving faces, jacket texture, and booth detail; selected after Flash Night proved too contrasty in the first delivered cut. |

## Missing but useful

- Licensed music with a five-beat day-to-night arc; the hero cut remains sound-off legible.
- Real user-shot ritual photos for a future UGC variant.

## Safe to simulate

- Camera push, parallax, focus drift, steam/rain light movement, flash, and develop masks over real same-pixel pairs.

## Must not fabricate

- Testimonials, creator handles, metrics, customer outcomes, fake UI, or filters not rendered by Tumble's production-equivalent pipeline.

## Studio copies

Files copied or linked into `ad-studio/public/<campaign>/`:

- Five before JPEGs, five selected after JPEGs, and `logo.png`.

## Provenance

The five source photos were generated with the built-in image generation tool on 2026-09-01. Each prompt requested one photorealistic vertical smartphone-style photograph, neutral processing ready for grading, no logos, no text, no border, and no watermark. Every selected after was rendered locally through `scripts/render-nostalgia-stills.swift`, `scripts/film-grade.swift`, and `FilmStockCatalog`.
