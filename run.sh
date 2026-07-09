#!/usr/bin/env bash
#
# Build, install, and launch Tumble on a running/boot-able emulator or simulator.
#
#   ./run.sh --android    # Kotlin/Compose app in android/
#   ./run.sh --ios        # SwiftUI app in app/
#
# Options:
#   -a, --android   Run the Android app
#   -i, --ios       Run the iOS app
#   -h, --help      Show this help
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Android config ---------------------------------------------------------
ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
ADB="$ANDROID_SDK/platform-tools/adb"
EMULATOR="$ANDROID_SDK/emulator/emulator"
ANDROID_APP_ID="com.tumble"
ANDROID_ACTIVITY="com.tumble/.MainActivity"

# ---- iOS config -------------------------------------------------------------
IOS_DIR="$ROOT/app"
IOS_PROJECT="$IOS_DIR/Tumble.xcodeproj"
IOS_SCHEME="Tumble"
IOS_APP_ID="com.tumble.app"
IOS_DERIVED="$IOS_DIR/build/DerivedData"

log()  { printf '\033[1;36m▸ %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Build, install, and launch Tumble on a running/boot-able emulator or simulator.

  ./run.sh --android    # Kotlin/Compose app in android/
  ./run.sh --ios        # SwiftUI app in app/

Options:
  -a, --android   Run the Android app
  -i, --ios       Run the iOS app
  -h, --help      Show this help
EOF
  exit "${1:-0}"
}

run_android() {
  [ -x "$ADB" ] || die "adb not found at $ADB (set ANDROID_HOME)"
  [ -x "$EMULATOR" ] || die "emulator not found at $EMULATOR"

  # Boot an emulator if no device/emulator is attached.
  if [ "$("$ADB" get-state 2>/dev/null || true)" != "device" ]; then
    local avd
    avd="$("$EMULATOR" -list-avds | head -1)"
    [ -n "$avd" ] || die "no AVDs found — create one in Android Studio > Device Manager"
    log "Booting emulator: $avd"
    nohup "$EMULATOR" -avd "$avd" >/tmp/tumble-emulator.log 2>&1 &
    log "Waiting for device…"
    "$ADB" wait-for-device
    until [ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
      sleep 2
    done
  fi

  log "Building + installing debug APK"
  ( cd "$ROOT/android" && ./gradlew :app:installDebug )

  log "Launching $ANDROID_ACTIVITY"
  "$ADB" shell am start -n "$ANDROID_ACTIVITY" >/dev/null
  log "Android app launched."
}

run_ios() {
  command -v xcodebuild >/dev/null || die "xcodebuild not found (install Xcode)"

  # Regenerate the Xcode project from project.yml if needed/possible.
  if command -v xcodegen >/dev/null; then
    log "Generating Xcode project (xcodegen)"
    ( cd "$IOS_DIR" && xcodegen generate >/dev/null )
  fi
  [ -d "$IOS_PROJECT" ] || die "iOS project missing: $IOS_PROJECT"

  # Find a booted simulator, else boot the first available iPhone.
  local device_id
  device_id="$(xcrun simctl list devices booted | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)"
  if [ -z "$device_id" ]; then
    device_id="$(xcrun simctl list devices available | grep 'iPhone' | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)"
    [ -n "$device_id" ] || die "no iPhone simulators available (add one in Xcode)"
    log "Booting simulator $device_id"
    xcrun simctl boot "$device_id"
  fi
  open -a Simulator

  log "Building for simulator (Debug)"
  xcodebuild \
    -project "$IOS_PROJECT" \
    -scheme "$IOS_SCHEME" \
    -configuration Debug \
    -destination "id=$device_id" \
    -derivedDataPath "$IOS_DERIVED" \
    build >/dev/null

  local app_path
  app_path="$(find "$IOS_DERIVED/Build/Products" -maxdepth 2 -name 'Tumble.app' -type d | head -1)"
  [ -n "$app_path" ] || die "built Tumble.app not found under $IOS_DERIVED"

  log "Installing + launching"
  xcrun simctl install "$device_id" "$app_path"
  xcrun simctl launch "$device_id" "$IOS_APP_ID" >/dev/null
  log "iOS app launched."
}

main() {
  [ $# -gt 0 ] || usage 1
  case "$1" in
    -a|--android) run_android ;;
    -i|--ios)     run_ios ;;
    -h|--help)    usage 0 ;;
    *) die "unknown option: $1 (use --android or --ios)";;
  esac
}

main "$@"
