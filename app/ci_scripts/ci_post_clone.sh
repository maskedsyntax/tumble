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

echo "▸ Installing PostHog CLI for release symbol uploads"
npm install --global @posthog/cli@0.16.0

echo "▸ Generating Tumble.xcodeproj from project.yml"
cd "$CI_PRIMARY_REPOSITORY_PATH/app"
./scripts/generate-project.sh

echo "▸ Generated:"
ls -d Tumble.xcodeproj
