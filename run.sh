#!/usr/bin/env bash
#
# Build, install, and launch Tumble on a running/boot-able iOS Simulator.
#
#   ./run.sh          # build + run the SwiftUI app in app/
#   ./run.sh --ios    # same, explicit
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IOS_DIR="$ROOT/app"
IOS_PROJECT="$IOS_DIR/Tumble.xcodeproj"
IOS_SCHEME="Tumble"
IOS_APP_ID="com.tumble.app"
IOS_DERIVED="$IOS_DIR/build/DerivedData"

log()  { printf '\033[1;36m▸ %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Build, install, and launch Tumble on a running/boot-able iOS Simulator.

  ./run.sh          # build + run the SwiftUI app in app/
  ./run.sh --ios    # same, explicit

Options:
  -i, --ios    Run the iOS app (default)
  -h, --help   Show this help
EOF
  exit "${1:-0}"
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
  case "${1:-}" in
    -i|--ios|"") run_ios ;;
    -h|--help)   usage 0 ;;
    *) die "unknown option: $1 (use --ios)";;
  esac
}

main "$@"
