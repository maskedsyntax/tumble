#!/usr/bin/env bash
#
# Capture the App Review screenshot for every film-pack in-app purchase.
#
# Apple requires one screenshot per IAP showing where in the app the purchase
# is offered. Each capture drives the app straight to that pack's store card
# with `-packPaywall <packID>` (see Tumble/App/DebugLaunch.swift), so the set
# can be regenerated after any paywall change instead of re-tapped by hand.
#
#   ./scripts/capture-iap-screenshots.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/app"
OUT_DIR="$ROOT/iap-review-screenshots"
DERIVED="$APP_DIR/build/DerivedData"
APP_ID="com.tumble.app"

log() { printf '\033[1;36m▸ %s\033[0m\n' "$*"; }

# packID:output name — the free pack has nothing to sell, so it is not here.
PACKS=(
  "nineties:com.tumble.pack.nineties"
  "darkroom:com.tumble.pack.darkroom2"
  "summer:com.tumble.pack.summer"
)

# App Store Connect only accepts a fixed set of screenshot dimensions, and a
# simulator's native size is not necessarily one of them (iPhone 17 shoots
# 1206x2622). Everything is normalised to the 6.5-inch size, which is what the
# marketing screenshot set already uses: scale to width, then trim the few
# leftover rows off the bottom rather than squash the aspect ratio.
readonly TARGET_W=1242
readonly TARGET_H=2688

resize() {
  local file="$1"
  sips --resampleWidth "$TARGET_W" "$file" >/dev/null
  sips -c "$TARGET_H" "$TARGET_W" "$file" >/dev/null
}

device="$(xcrun simctl list devices booted | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)"
if [ -z "$device" ]; then
  device="$(xcrun simctl list devices available | grep 'iPhone 17 (' | grep -Eo '[0-9A-Fa-f-]{36}' | head -1)"
  log "Booting simulator $device"
  xcrun simctl boot "$device"
fi

log "Building (Debug)"
xcodebuild -project "$APP_DIR/Tumble.xcodeproj" -scheme Tumble -configuration Debug \
  -destination "id=$device" -derivedDataPath "$DERIVED" build >/dev/null

app_path="$(find "$DERIVED/Build/Products" -maxdepth 2 -name 'Tumble.app' -type d | head -1)"
xcrun simctl install "$device" "$app_path"

mkdir -p "$OUT_DIR"
xcrun simctl status_bar "$device" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

for entry in "${PACKS[@]}"; do
  pack="${entry%%:*}"
  product="${entry##*:}"
  log "Capturing $product"
  xcrun simctl terminate "$device" "$APP_ID" 2>/dev/null || true
  xcrun simctl launch "$device" "$APP_ID" -seed -skipOnboard -packPaywall "$pack" >/dev/null
  sleep 6   # let the sample scene render through all five stocks
  xcrun simctl io "$device" screenshot --type=png "$OUT_DIR/$product.png" >/dev/null
  resize "$OUT_DIR/$product.png"
done

# The bundle is sold from the same card, under the single-pack button, so its
# review screenshot is any pack's card with the "take every pack" offer visible.
log "Capturing com.tumble.pack.all"
xcrun simctl terminate "$device" "$APP_ID" 2>/dev/null || true
xcrun simctl launch "$device" "$APP_ID" -seed -skipOnboard -packPaywall darkroom >/dev/null
sleep 6
xcrun simctl io "$device" screenshot --type=png "$OUT_DIR/com.tumble.pack.all.png" >/dev/null
resize "$OUT_DIR/com.tumble.pack.all.png"

xcrun simctl terminate "$device" "$APP_ID" 2>/dev/null || true
log "Wrote $(ls -1 "$OUT_DIR"/*.png | wc -l | tr -d ' ') screenshots to $OUT_DIR"
