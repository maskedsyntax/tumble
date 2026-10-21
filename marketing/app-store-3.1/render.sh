#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Compiled with the app's grade pipeline so every graded photograph outside
# the phone is exactly what Tumble produces. Pass a target (iphone, duo, header
# or search) to render one set, optionally followed by a page prefix (e.g. 03).
bin="$(mktemp -d)/render-screenshots"
swiftc -O -parse-as-library marketing/app-store-3.1/render.swift marketing/app-store-3.1/render-duo.swift \
  scripts/film-grade.swift app/TumbleKit/Filter/FilmStock.swift -o "$bin"
if [ $# -gt 0 ]; then
  "$bin" "$@"
else
  for target in iphone duo header search; do "$bin" "$target"; done
fi
rm -f "$bin"

# 6.1- and 6.3-inch iPhones share the 6.9-inch aspect ratio, so that set is an
# exact resample of the finals rather than a separate layout.
if [ $# -eq 0 ] || [ "$1" = iphone ]; then
  rm -rf screenshots/3.1/final-63
  mkdir -p screenshots/3.1/final-63
  for page in screenshots/3.1/final/*.png; do
    sips -z 2622 1206 "$page" --out "screenshots/3.1/final-63/$(basename "$page")" >/dev/null
  done
fi

asc screenshots validate --path screenshots/3.1/final --device-type APP_IPHONE_67 --output table
asc screenshots validate --path screenshots/3.1/final-63 --device-type APP_IPHONE_61 --output table
asc screenshots validate --path screenshots/3.1/final-duo --device-type APP_IPHONE_DUO --output table
