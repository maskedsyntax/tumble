#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/app"
OUT="$ROOT/screenshots/3.1/raw"
DERIVED="$APP_DIR/.build/AppStoreScreenshots"
BUNDLE_ID="com.tumble.app"
UDID="${1:-3D1039CB-C45F-4A10-AAA1-A1E3EF69C510}"
PHOTO_LIBRARY="$ROOT/mockups-appstore-v7/photo-library"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcodebuild -project "$APP_DIR/Tumble.xcodeproj" -scheme Tumble -configuration Debug \
  -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath "$DERIVED" build >/dev/null
xcrun simctl install "$UDID" "$DERIVED/Build/Products/Debug-iphonesimulator/Tumble.app"
mkdir -p "$OUT"

container="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)"
mkdir -p "$container/Documents"
for photo in 03-flower-market 05-coastal-drive 06-rainy-crosswalk 08-sidewalk-cafe 09-beach-run 10-motel-pool 13-skateboard 15-concert; do
  cp "$PHOTO_LIBRARY/$photo.png" "$container/Documents/$photo.png"
done
xcrun simctl status_bar "$UDID" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

capture() {
  local name="$1"
  shift
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" "$@" >/dev/null
  # Debug routes create a private draft, render the selected film, and may
  # present a second full-screen destination. Give that work time to settle;
  # capturing during the transition creates blank or half-presented frames.
  sleep "${SETTLE:-12}"
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/$name.png" >/dev/null
}

# Editor screens use free Core films wherever the action bar is visible, so
# the store never leads with a lock. Premium looks appear only as previews.
capture studio-hero -skipOnboard -studioDemo -demoImage 09-beach-run.png -demoStock goldenHour
capture studio-amount -skipOnboard -studioDemo -amountDemo -demoImage 10-motel-pool.png -demoStock warmArchive
capture studio-crop -skipOnboard -studioDemo -demoImage 13-skateboard.png -demoStock warmArchive -studioTool crop -demoCrop portrait -demoStraighten 4
capture finish-classic -skipOnboard -finishDemo -demoImage 06-rainy-crosswalk.png -demoStock warmArchive -demoFrame classicInstant -demoNote "Wish you were here"
capture finish-vintage -skipOnboard -finishDemo -demoImage 05-coastal-drive.png -demoStock sunbleached -demoFrame vintagePostcard -demoNote "Coast road, July"
capture finish-deckled -skipOnboard -finishDemo -demoImage 08-sidewalk-cafe.png -demoStock fadedInstant -demoFrame deckledEdge -demoNote "Same table next year?"
capture finish-bordered -skipOnboard -finishDemo -demoImage 15-concert.png -demoStock everyday -demoFrame borderedFilm -demoNote "Front row"
# The Drawer seeds eight finished prints through the real export path first.
SETTLE=40 capture drawer -skipOnboard -clearDraft -drawerDemo -openDrawer
capture complete -skipOnboard -finishDemo -completeDemo -demoImage 10-motel-pool.png -demoStock goldenHour

asc screenshots validate --path "$OUT" --device-type APP_IPHONE_67 --output table
