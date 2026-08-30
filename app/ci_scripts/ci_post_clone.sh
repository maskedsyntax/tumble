#!/bin/sh
#
# Xcode Cloud runs this after cloning, before it resolves dependencies or
# builds. The Xcode project is not in the repository - it is generated from
# app/project.yml by XcodeGen - so a fresh clone has nothing to build until
# this runs. Lives beside Tumble.xcodeproj because Xcode Cloud looks for
# ci_scripts next to the project it was pointed at.
#
set -e

echo "▸ Installing XcodeGen"
brew install --quiet xcodegen

if [ -n "${POSTHOG_CLI_API_KEY:-}" ]; then
  echo "▸ Installing PostHog CLI 0.16.0 for release symbol uploads"
  export POSTHOG_CLI_UNMANAGED_INSTALL="$CI_PRIMARY_REPOSITORY_PATH/app/.ci-bin"
  curl --proto '=https' --tlsv1.2 -LsSf \
    'https://github.com/PostHog/posthog/releases/download/posthog-cli%2Fv0.16.0/posthog-cli-installer.sh' \
    | sh
else
  echo "▸ POSTHOG_CLI_API_KEY is not configured; skipping PostHog CLI installation"
fi

echo "▸ Generating Tumble.xcodeproj from project.yml"
cd "$CI_PRIMARY_REPOSITORY_PATH/app"
./scripts/generate-project.sh

echo "▸ Generated:"
ls -d Tumble.xcodeproj
