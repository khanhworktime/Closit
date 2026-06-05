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
        echo "==> Re-signing Sparkle.framework internals (inside-out)..."

        # Step 1: Find and sign ALL Mach-O executables inside the framework (innermost first)
        # Sign XPC services first (deepest nested)
        find "$SPARKLE_DIR" -path "*/XPCServices/*.xpc" -type d | while read xpc; do
            echo "  Signing XPC: $xpc"
            codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$xpc"
        done

        # Sign embedded apps (Updater.app)
        find "$SPARKLE_DIR" -name "*.app" -type d | while read app; do
            echo "  Signing App: $app"
            codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$app"
        done

        # Sign standalone executables (Autoupdate)
        find "$SPARKLE_DIR/Versions/B" -maxdepth 1 -type f -perm +111 | while read exe; do
            if file "$exe" | grep -q "Mach-O"; then
                echo "  Signing executable: $exe"
                codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$exe"
            fi
        done

        # Step 2: Sign the framework bundle itself
        echo "  Signing Sparkle.framework..."
        codesign --force --options runtime --timestamp --sign "$APPLE_CERT_HASH" "$SPARKLE_DIR"

        # Step 3: Re-sign the main app bundle (seal was invalidated by framework re-signing)
        echo "==> Re-signing main app bundle..."
        codesign --force --options runtime --timestamp --preserve-metadata=entitlements,identifier,requirements,flags --sign "$APPLE_CERT_HASH" "$APP_BUNDLE"

        # Verify
        echo "==> Verifying code signature..."
        codesign --verify --deep --strict "$APP_BUNDLE" && echo "✅ Signature is valid!" || echo "❌ Signature verification FAILED"
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
