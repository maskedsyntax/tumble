# Android Tumble 3 closed-beta runbook

## Release gate

- Run `./gradlew testDebugUnitTest lintRelease assembleDebug bundleRelease` and
  `./gradlew connectedDebugAndroidTest` on a connected test device.
- Supply the separate upload key only through `TUMBLE_UPLOAD_STORE_FILE`,
  `TUMBLE_UPLOAD_STORE_PASSWORD`, `TUMBLE_UPLOAD_KEY_ALIAS`, and
  `TUMBLE_UPLOAD_KEY_PASSWORD`; never commit credentials or the keystore.
- Validate the bundle and 16 KB native-library alignment before upload.
- Run an internal-track smoke test on API 31, 34, and 36 plus one Samsung-class
  device. Also inspect current API 37 behavior before promoting the build.
- Verify clean install, upgrade, first camera grant, denial and settings recovery,
  import without camera access, both cameras, flash availability, concurrent
  shutter protection, draft recovery after process death, crop/rotate, every
  film, postcard/note rendering, failed-save recovery, MediaStore save, share,
  relaunch, and confirmed discard.
- Require no open crash, ANR, data-loss, privacy, purchase, capture, render, or
  save blocker and a clean Play pre-launch report.

## Play declarations

- Free download, no ads, and one optional non-consumable Tumble Complete product
  (`com.tumble.pack.all`). Price text must come from Play Billing.
- Photos are processed locally. Drafts, pixels, filenames, crop contents, notes,
  and library metadata are never analytics payloads.
- Optional anonymous product analytics, crash diagnostics, and masked session
  replay are disabled by default. Nothing is sent before consent; opting out
  stops capture, clears queued data, and resets the anonymous identity.
- Permissions are Camera, Internet for opted-in diagnostics, and Billing through
  the Play library. Photo Picker imports do not require broad library access.
- Private draft content is excluded from cloud backup and device transfer. Saved
  photos may still sync through the user's own OS photo-library configuration.
- Privacy policy: <https://gettumbleapp.com/privacy>
- Support: aftaab@aftaab.dev

## Tester clock

Start counting only after all 12 testers show as opted in. Record an anonymized
tester ID, device, Android version, mission completion, feedback, issue, and
resolution. Any opt-out risks restarting or delaying eligibility.

### Day 1

Install, onboard, capture and import, apply a free film, edit, save/share, and
report the device and Android version. License testers also exercise the Complete
purchase states: success, pending/cancelled, restore, and locked-film routing.

### Day 7

Verify repeat use, draft recovery after relaunch, camera switching, multiple
crop/frame/note combinations, MediaStore output, and analytics opt-in then
opt-out behavior.

### Day 14

Repeat the complete camera/import → Studio → save/share loop and submit final
usability, reliability, purchase, and privacy feedback.

Only critical Tumble 3 fixes go to the closed track during the clock. Record the
missions, feedback, fixes, and readiness evidence for the production-access
application; completion of the clock does not itself grant production access.
