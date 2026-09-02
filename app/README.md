# Tumble 3.0 — iOS

Tumble is a private film camera and Studio. Capture a photo or import one from
the system picker, preview a film look, refine the crop and postcard treatment,
then explicitly save or share the finished image. Source photos and edits stay
on-device; there is no account or Tumble cloud.

## Requirements

- Xcode 18+ (iOS 18 deployment target)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Getting started

```sh
cd app
cp .env.example .env     # optional PostHog project token
./scripts/generate-project.sh
open Tumble.xcodeproj
```

The project is generated from `project.yml`. PostHog is not initialized and
sends nothing until the user explicitly opts into analytics.

## Build and test

```sh
./scripts/generate-project.sh
xcodebuild -scheme Tumble -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme Tumble -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Architecture

| Target | Responsibility |
|---|---|
| `Tumble` | SwiftUI camera workspace, Studio, onboarding, settings, Complete storefront, draft recovery, and conditional Legacy Drawer. |
| `TumbleKit` | Domain models, camera, canonical film catalog, recipe renderer, StoreKit access, persistence, and Graincore theme. |
| `TumbleAnalytics` | Consent-gated, masked diagnostics and product analytics. |

The Lock Screen capture, Control Center, widget, Live Activity, and Dynamic
Island targets are retired from the generated Tumble 3 project. The existing
App Group and SwiftData content remain available so upgraded users can browse,
finish, export, and delete old prints from **Settings → Legacy Drawer**.

## Product contracts

- `../shared/film-stocks.json` is the versioned source for all 21 stable film
  IDs, ownership packs, copy, and grade parameters.
- One recoverable draft is written atomically under Application Support and is
  excluded from backups. It is cleared only after Photos confirms a save or the
  user confirms discard.
- Preview and export use the same `EditRecipe`: orientation, crop, film and
  intensity, then postcard frame and note.
- Exports are metadata-free sRGB JPEGs capped at a 4096-pixel long edge.
- Six Core films are free. `com.tumble.pack.all` unlocks Tumble Complete;
  retired Plus and Unlimited purchases remain restorable and map to Complete.

The simulator can exercise imports and the Studio. Real camera capture,
add-only Photos authorization, and StoreKit sandbox acceptance should also be
verified on physical devices before TestFlight promotion.
