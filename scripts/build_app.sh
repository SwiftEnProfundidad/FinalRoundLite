#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FinalRoundLite"
APP_BUNDLE="$ROOT_DIR/build/$APP_NAME.app"
BIN_PATH="$ROOT_DIR/.build/release/$APP_NAME"
PLIST_PATH="$ROOT_DIR/App/Info.plist"

cd "$ROOT_DIR"

swift build -c release

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$PLIST_PATH" "$APP_BUNDLE/Contents/Info.plist"
cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Ad-hoc sign so macOS can prompt for permissions consistently during local use.
codesign --force --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true

echo "Built: $APP_BUNDLE"

