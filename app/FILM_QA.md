# Film manifest v2 QA

The stable corpus is deliberately fixed so changes in the shared manifest can
be compared before every release. Use the original files in
`mockups-appstore-v7/photo-library/` and render all 21 stable film IDs at 100%
and 60% intensity, plus all four postcard formats at export resolution.

| Coverage | Source |
| --- | --- |
| Skin tones | `02-house-party.png`, `08-sidewalk-cafe.png` |
| Daylight | `03-flower-market.png` |
| Night / direct flash | `15-concert.png` |
| Landscape | `05-coastal-drive.png` |
| High dynamic range | `06-rainy-crosswalk.png` |
| Low light | `11-night-train.png` |

Review at full size and at the Studio thumbnail size for distinct identity,
skin and highlight handling, grain, halation, bloom, fading, tint, vignette,
clipping, banding, and destructive casts. Any approved grade change must keep
the film ID and pack assignment stable and increment `film-stocks.json`'s
manifest version. Existing exported JPEGs are immutable; recoverable drafts
resolve their saved ID through the current recipe.

The automated suite verifies every catalog film renders, the catalog remains
six free and fifteen Complete looks, stable legacy IDs resolve, intensity
endpoints behave, and postcard formats render. Visual sign-off on the corpus
is still required before TestFlight because renderer snapshots cannot decide
whether a skin tone or highlight treatment is aesthetically acceptable.
