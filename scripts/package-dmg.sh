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

if [ -n "$APPLE_CERT_HASH" ]; then
    echo "==> Fixing Code Signatures for Notarization..."
    
    # 1. Extract Entitlements so we don't lose them when re-signing the main app
    ENTITLEMENTS_FILE="$BUILD_DIR/app.entitlements"
    codesign -d --entitlements :- "$APP_BUNDLE" > "$ENTITLEMENTS_FILE" 2>/dev/null || true

    # 2. Sign inner components of Sparkle
    SPARKLE_DIR="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
    if [ -d "$SPARKLE_DIR" ]; then
        # Sign specific known executables/apps/xpcs in Sparkle
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$SPARKLE_DIR/Versions/B/Autoupdate" || true
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$SPARKLE_DIR/Versions/B/Updater.app" || true
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$SPARKLE_DIR/Versions/B/XPCServices/Downloader.xpc" || true
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$SPARKLE_DIR/Versions/B/XPCServices/Installer.xpc" || true
        
        # Sign the Sparkle framework bundle itself
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$SPARKLE_DIR" || true
    fi

    # 3. Re-sign the main app to fix the seal, preserving extracted entitlements
    echo "==> Re-signing main app bundle..."
    if grep -q "DOCTYPE plist" "$ENTITLEMENTS_FILE"; then
        codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS_FILE" --sign "$APPLE_CERT_HASH" "$APP_BUNDLE"
    else
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$APP_BUNDLE"
    fi
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

echo "==> Generating Sparkle EdDSA signature for the update..."
SIGN_UPDATE="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework/Versions/B/Resources/sign_update"
if [ -f "$SIGN_UPDATE" ]; then
    "$SIGN_UPDATE" "$DMG_PATH"
else
    echo "Warning: sign_update tool not found at $SIGN_UPDATE. You may need to sign the update manually."
fi
