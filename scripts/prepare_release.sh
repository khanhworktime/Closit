#!/usr/bin/env bash
set -e

# prepare_release.sh
# Tự động hóa quá trình build phiên bản mới nhất,
# tạo DMG, Notarize và tạo file appcast.xml.

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SPARKLE_TOOLS_DIR="$PROJECT_DIR/.sparkle_tools"
DIST_DIR="$PROJECT_DIR/dist"

echo "==> Chuẩn bị thư mục release..."
mkdir -p "$DIST_DIR"
rm -rf "$DIST_DIR"/*

# Tải Sparkle tools nếu chưa có
if [ ! -f "$SPARKLE_TOOLS_DIR/bin/sign_update" ]; then
    echo "==> Đang tải Sparkle tools..."
    mkdir -p "$SPARKLE_TOOLS_DIR"
    curl -sLO https://github.com/sparkle-project/Sparkle/releases/download/2.6.4/Sparkle-2.6.4.tar.xz
    tar -xf Sparkle-2.6.4.tar.xz -C "$SPARKLE_TOOLS_DIR"
    rm Sparkle-2.6.4.tar.xz
fi

echo "=========================================================" >&2
echo "==> BẮT ĐẦU BUILD PHIÊN BẢN MỚI NHẤT" >&2
echo "=========================================================" >&2

# 1. Build ứng dụng và tạo DMG
bash "$PROJECT_DIR/scripts/package-dmg.sh" >&2

DMG_NAME="Closit.dmg"
DMG_DIST_PATH="$DIST_DIR/$DMG_NAME"
DMG_PATH="$PROJECT_DIR/build/Closit.dmg"

if [ ! -f "$DMG_PATH" ]; then
    echo "Lỗi: Không tìm thấy file DMG tại $DMG_PATH" >&2
    exit 1
fi
mv "$DMG_PATH" "$DMG_DIST_PATH"

# 2. Notarization
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ] && [ -n "$APPLE_TEAM_ID" ]; then
    echo "==> Bắt đầu Notarization cho $DMG_NAME..." >&2
    xcrun notarytool submit "$DMG_DIST_PATH" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$APPLE_TEAM_ID" --wait >&2
    xcrun stapler staple "$DMG_DIST_PATH" >&2
else
    echo "==> [CẢNH BÁO] Bỏ qua Notarization do thiếu cấu hình APPLE_ID hoặc APPLE_ID_PASSWORD." >&2
fi

# 3. Sign
echo "==> Lấy chữ ký Sparkle..." >&2
if [ -n "$SPARKLE_PRIVATE_KEY" ]; then
    SIGN_OUTPUT=$(printenv SPARKLE_PRIVATE_KEY | "$SPARKLE_TOOLS_DIR/bin/sign_update" --ed-key-file - "$DMG_DIST_PATH")
else
    SIGN_OUTPUT=$("$SPARKLE_TOOLS_DIR/bin/sign_update" "$DMG_DIST_PATH")
fi

SIG=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2 | tail -n1)
LEN=$(echo "$SIGN_OUTPUT" | grep -o 'length="[^"]*"' | cut -d'"' -f2 | tail -n1)

echo "==> Đang tạo file appcast.xml..."

# Lấy Version từ project.yml
MARKETING_VERSION=$(grep 'MARKETING_VERSION' "$PROJECT_DIR/project.yml" | awk -F'"' '{print $2}')
PROJECT_VERSION=$(grep 'CURRENT_PROJECT_VERSION' "$PROJECT_DIR/project.yml" | awk -F'"' '{print $2}')

# Format thời gian theo chuẩn RFC 2822
PUB_DATE=$(LC_TIME=en_US.UTF-8 date "+%a, %d %b %Y %H:%M:%S %z")

APPCAST_PATH="$DIST_DIR/appcast.xml"
cat > "$APPCAST_PATH" <<EOF
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>Closit Changelog</title>
        <item>
            <title>Closit $MARKETING_VERSION</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://github.com/khanhworktime/Closit/releases/download/v$MARKETING_VERSION/Closit.dmg"
                sparkle:version="$PROJECT_VERSION"
                sparkle:shortVersionString="$MARKETING_VERSION"
                length="$LEN"
                type="application/octet-stream"
                sparkle:edSignature="$SIG" />
        </item>
    </channel>
</rss>
EOF

echo ""
echo "========================================================="
echo "🎉 HOÀN TẤT CHUẨN BỊ RELEASE 🎉"
echo "========================================================="
echo "Các file release đã sẵn sàng tại thư mục: $DIST_DIR"
echo "- Closit.dmg"
echo "- appcast.xml"
echo "========================================================="
