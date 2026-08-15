#!/usr/bin/env bash
# Render the v3 App Store screenshot set. Run from the repo root.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
swiftc -O mockups-appstore-v3/main.swift app/TumbleKit/Filter/FilmStock.swift -o /tmp/tumble-render-v3
/tmp/tumble-render-v3
