#!/usr/bin/env bash
set -e

# package-dmg.sh
# Builds the Closit app in Release configuration and packages it into a DMG.

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Closit"
APP_BUNDLE="$BUILD_DIR/Release/$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

cd "$PROJECT_DIR"

echo "==> Generating project..."
xcodegen generate

echo "==> Building $APP_NAME (Release)..."
xcodebuild build -scheme $APP_NAME -configuration Release CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release" -quiet

if [ ! -d "$APP_BUNDLE" ]; then
  echo "Error: App bundle not found at $APP_BUNDLE"
  exit 1
fi

echo "==> Creating DMG..."
mkdir -p "$BUILD_DIR/dmg"
cp -r "$APP_BUNDLE" "$BUILD_DIR/dmg/"
ln -s /Applications "$BUILD_DIR/dmg/Applications"

# Remove existing DMG if it exists
if [ -f "$DMG_PATH" ]; then
  rm "$DMG_PATH"
fi

hdiutil create -volname "$APP_NAME" -srcfolder "$BUILD_DIR/dmg" -ov -format UDZO "$DMG_PATH"

# Cleanup temp folder
rm -rf "$BUILD_DIR/dmg"

echo "==> Done! DMG created at: $DMG_PATH"
