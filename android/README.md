# Tumble 3.0 — Android

The Android app implements the same private camera-to-Studio workflow as iOS:

```text
Capture or import → preview film → edit → save/share
```

It uses `com.tumble.app`, requires API 31, targets API 36, and is built with
CameraX 1.6.2 and Play Billing 9.1.0.

## Build and test

Use Android Studio's bundled JDK when the machine default is newer than the
Android Gradle toolchain supports:

```sh
cd android
JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' \
ANDROID_HOME="$HOME/Library/Android/sdk" \
./gradlew testDebugUnitTest lintRelease assembleDebug bundleRelease
```

With an emulator or device connected:

```sh
./gradlew connectedDebugAndroidTest installDebug
```

## Product contracts

- `../shared/film-stocks.json` is packaged as an asset and defines all 21 film
  stocks. Six Core stocks are free; the remaining 15 require Complete.
- Capture and Photo Picker imports are copied atomically into one backup-excluded
  private draft. A failed export keeps the draft; a confirmed discard or
  successful MediaStore save removes it.
- Studio applies orientation, crop, film/intensity, and postcard/note rendering,
  then writes a metadata-free sRGB JPEG capped at 4096 pixels.
- Camera permission is contextual and import works without it. Production
  capture never substitutes a synthetic image.
- Optional PostHog analytics remains entirely inactive before explicit consent;
  camera, photo, and note content is masked and forbidden from event payloads.
- The one-time Play product is `com.tumble.pack.all`. Price copy is supplied by
  Play Billing, and purchases are acknowledged and refreshed on foreground.

Release signing is configured through environment variables so upload-key
material never enters the repository. Store listing, Data Safety, license-test
purchases, pre-launch reporting, and the 12-tester closed-test clock are Play
Console operations and are performed only after the local release gate passes.
