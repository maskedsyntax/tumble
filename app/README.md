# Tumble — iOS app

A slower camera you can actually own. Twelve shots a day, shake to develop, and
a Drawer of prints that age. On-device, no account, no cloud. One-time
purchases, never a subscription.

This is the native iOS app that the marketing site (`../web`) is a waitlist for.

## Requirements

- Xcode 18+ (built against the iOS 18 SDK; deployment target iOS 18.0)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Getting started

```sh
cd app
xcodegen generate        # writes Tumble.xcodeproj from project.yml
open Tumble.xcodeproj
```

The `.xcodeproj` is generated and git-ignored; edit `project.yml` to change
targets/settings, then regenerate.

## Build & test from the CLI

```sh
xcodegen generate
xcodebuild -scheme Tumble -destination 'generic/platform=iOS Simulator' build
xcodebuild -scheme Tumble -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Architecture

| Target | What it is |
|---|---|
| `Tumble` | The app (SwiftUI). Camera, Drawer, develop, paywall, settings. |
| `TumbleKit` | Shared domain: models, Roll/quota, storage, film pipeline, StoreKit, theme, camera. |
| `TumbleControls` | Lock Screen / Control Center control that launches the camera. |
| `TumbleCapture` | `LockedCameraCapture` extension — the camera while the phone is locked. |

All product rules live in `TumbleKit` so the lock-screen extension enforces the
same Roll and writes to the same Drawer via a shared **App Group**
(`group.com.tumble`). Photos are SwiftData rows; the image bytes are files in the
shared container. No networking beyond StoreKit.

### Signature pieces

- **The Roll** — `TumbleKit/Roll/RollManager.swift`. Daily quota (12 / 72 /
  unlimited), midnight rollover, mirrored into the App Group.
- **Shake to develop** — `TumbleKit/Motion/ShakeMonitor.swift` +
  `Tumble/Screens/DevelopView.swift`. Accelerometer energy ramps the develop;
  press-and-hold fallback under Reduce Motion / no accelerometer.
- **The Drawer & prints** — `TumbleKit/Views/PrintView.swift`,
  `Tumble/Screens/DrawerScreen.swift`. Scattered pile with the site's exact
  print treatment (aged grade, grain, vignette, sheen); aging is a function of
  capture time (`Photo.ageFraction`).
- **Graincore theme** — `TumbleKit/Theme/`. Ports the tokens and atmosphere from
  `../web/src/app/globals.css`.

## Simulator vs device

The Simulator has no camera, accelerometer, or Lock Screen, and `simctl` can't
apply the StoreKit test config. To exercise the UI without a device, launch with
debug flags (guarded, no effect in a normal launch):

```sh
xcrun simctl launch <device> com.tumble.app -seed -drawer     # seed prints, open Drawer
xcrun simctl launch <device> com.tumble.app -seed -drawer -develop -devMid  # develop mid-state
xcrun simctl launch <device> com.tumble.app -paywall          # paywall
xcrun simctl launch <device> com.tumble.app -settings         # settings
```

Real camera, shake haptics, in-app purchases, and lock-screen capture require a
physical device. Purchases also need the `com.tumble.plus` / `com.tumble.unlimited`
products and the `group.com.tumble` App Group registered in App Store Connect;
the `.storekit` config only covers local testing in Xcode.
