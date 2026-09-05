#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

swiftc -O marketing/instagram/intro-carousel/render.swift -o /tmp/tumble-instagram-intro-render
/tmp/tumble-instagram-intro-render
