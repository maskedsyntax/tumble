# Tumble — Android app

A slower camera you can actually own. Native Android version of Tumble, built with Kotlin and Jetpack Compose.

This is the native Android app that the marketing site (`../web`) refers to.

## Requirements

- Android Studio Koala+ or Ladybug+
- JDK 17+
- Android SDK 31+ (Min SDK 31, Target/Compile SDK 36)

## Getting started

```sh
cd android
./gradlew :app:installDebug
```

You can also use the root `run.sh` script:

```sh
./run.sh --android
```

## Architecture

| Package | What it is |
|---|---|
| `com.tumble.ui` | Compose screens and viewmodels (Home, Capture, Develop, etc.) |
| `com.tumble.camera` | CameraX implementation and viewfinder. |
| `com.tumble.roll` | Daily quota (12 shots) and midnight rollover logic. |
| `com.tumble.motion` | Accelerometer-based shake detection for developing prints. |
| `com.tumble.data` | Room database for photos and DataStore for preferences. |
| `com.tumble.quick` | Home screen widgets (Glance) and Quick Settings tile. |
| `com.tumble.store` | Google Play Billing integration. |

## Feature Parity with iOS

- [x] **The Roll:** 12 shots per day limit.
- [x] **Shake to Develop:** Physical accelerometer energy ramps the progress.
- [x] **The Drawer:** Scattered pile of prints with aging effects.
- [x] **Quick Capture:** Tile and Widget for immediate camera access.
- [x] **Graincore Theme:** Custom Material 3 tokens matching the brand.
- [x] **Private:** All photos stored locally; no cloud sync.

## Development

The app uses **Hilt** for dependency injection and **Room** for persistence. Images are saved as files in the app's internal storage, with metadata stored in SQLite.

To test the shake-to-develop on an emulator (which lacks an accelerometer), the `DevelopViewModel` has a fallback for manual progress (long-press the print) or you can use `adb` to simulate sensor data if the emulator supports it.
