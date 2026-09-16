#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
swiftc -O mockups-appstore-v7/render-01.swift -o /tmp/tumble-appstore-v7-shot-01
/tmp/tumble-appstore-v7-shot-01
