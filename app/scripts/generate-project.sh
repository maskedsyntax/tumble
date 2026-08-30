#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_DIR=$(dirname "$SCRIPT_DIR")
cd "$APP_DIR"

# dotenv assignments are also valid shell assignments. Export them so
# XcodeGen resolves the ${POSTHOG_*} placeholders into the ignored project.
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

: "${POSTHOG_PROJECT_TOKEN:=}"
: "${POSTHOG_HOST:=https://us.i.posthog.com}"
export POSTHOG_PROJECT_TOKEN POSTHOG_HOST

xcodegen generate --spec project.yml
