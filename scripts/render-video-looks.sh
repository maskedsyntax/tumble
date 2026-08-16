#!/usr/bin/env bash
# Render the graded stills the Remotion film uses. Run from the repo root.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
swiftc -O scripts/video-looks/main.swift scripts/film-grade.swift app/TumbleKit/Filter/FilmStock.swift -o /tmp/tumble-video-looks
/tmp/tumble-video-looks
