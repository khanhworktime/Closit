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
if [ -n "$APPLE_CERT_HASH" ]; then
    echo "Building with Code Signing (Developer ID)..."
    xcodebuild build \
        -scheme $APP_NAME \
        -configuration Release \
        CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release" \
        CODE_SIGN_IDENTITY="Developer ID Application" \
        CODE_SIGN_STYLE=Manual \
        DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
        OTHER_CODE_SIGN_FLAGS="--timestamp --options runtime" \
        CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
        -quiet
else
    echo "Building without Code Signing..."
    xcodebuild build \
        -scheme $APP_NAME \
        -configuration Release \
        CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release" \
        CODE_SIGNING_ALLOWED=NO \
        -quiet
fi

if [ ! -d "$APP_BUNDLE" ]; then
  echo "Error: App bundle not found at $APP_BUNDLE"
  exit 1
fi

# Fix Sparkle.framework signing (Xcode/SPM does NOT properly sign binary dependencies)
if [ -n "$APPLE_CERT_HASH" ]; then
    SPARKLE_DIR="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
    if [ -d "$SPARKLE_DIR" ]; then
        echo "==> Re-signing ALL binaries in Sparkle.framework..."

        # Find every Mach-O binary inside Sparkle and sign them individually
        # This catches: Sparkle dylib, Autoupdate, Updater, Downloader, Installer, etc.
        find "$SPARKLE_DIR" -type f | while read f; do
            if file "$f" | grep -q "Mach-O"; then
                echo "  Signing: $f"
                codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$f"
            fi
        done

        # Now sign the bundle directories (XPC, apps) from inside out
        find "$SPARKLE_DIR" -path "*/XPCServices/*.xpc" -type d | while read xpc; do
            echo "  Signing bundle: $xpc"
            codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$xpc"
        done

        find "$SPARKLE_DIR" -name "*.app" -type d | while read app; do
            echo "  Signing bundle: $app"
            codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$app"
        done

        # Sign the framework bundle itself
        echo "  Signing Sparkle.framework bundle..."
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$SPARKLE_DIR"

        # Re-sign the main app bundle (seal was invalidated by framework re-signing)
        echo "==> Re-signing main app bundle..."
        codesign --force --options runtime --timestamp --preserve-metadata=entitlements,identifier,requirements,flags --sign "$APPLE_CERT_HASH" "$APP_BUNDLE"

        # Verify everything
        echo "==> Verifying code signature..."
        codesign -dvvv "$APP_BUNDLE" 2>&1 | head -5
        codesign --verify --deep --strict "$APP_BUNDLE" && echo "✅ Signature is valid!" || echo "❌ Signature verification FAILED"
        
        # Also verify Sparkle specifically
        echo "==> Verifying Sparkle.framework..."
        codesign -dvvv "$SPARKLE_DIR" 2>&1 | head -5
    fi
fi

echo "==> Creating DMG using create-dmg..."
mkdir -p "$BUILD_DIR/dmg"
ditto "$APP_BUNDLE" "$BUILD_DIR/dmg/$APP_NAME.app"

# Remove existing DMG if it exists
if [ -f "$DMG_PATH" ]; then
  rm "$DMG_PATH"
fi

if ! command -v create-dmg &> /dev/null; then
    echo "create-dmg could not be found, installing via brew..."
    brew install create-dmg
fi

# The background PNG should be located at scripts/dmg_background.png
BG_PATH="$PROJECT_DIR/scripts/dmg_background.png"

create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 120 \
  --icon "$APP_NAME.app" 150 200 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 450 200 \
  --background "$BG_PATH" \
  "$DMG_PATH" \
  "$BUILD_DIR/dmg/"

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
