#!/usr/bin/env bash
set -e

# prepare_release.sh
# Tự động hóa quá trình build 2 phiên bản (macOS 14.0+ và macOS 26.0+),
# tạo DMG, Notarize và tạo file appcast.xml đa nền tảng.

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

# Hàm tiện ích để build, notarize và lấy thông tin sign
build_variant() {
    local TARGET_OS=$1
    local DMG_NAME=$2
    local DMG_DIST_PATH="$DIST_DIR/$DMG_NAME"
    
    echo "=========================================================" >&2
    echo "==> BẮT ĐẦU BUILD PHIÊN BẢN: macOS $TARGET_OS+" >&2
    echo "=========================================================" >&2
    
    # 1. Chỉnh sửa project.yml
    sed -i '' "s/macOS: \"[0-9.]*\"/macOS: \"$TARGET_OS\"/g" "$PROJECT_DIR/project.yml"
    
    # 2. Build ứng dụng và tạo DMG
    bash "$PROJECT_DIR/scripts/package-dmg.sh" >&2
    
    # 3. Chép DMG vào dist
    DMG_PATH="$PROJECT_DIR/build/Closit.dmg"
    if [ ! -f "$DMG_PATH" ]; then
        echo "Lỗi: Không tìm thấy file DMG tại $DMG_PATH" >&2
        exit 1
    fi
    mv "$DMG_PATH" "$DMG_DIST_PATH"
    
    # 4. Notarization
    if [ -n "$APPLE_ID" ] && [ -n "$APPLE_ID_PASSWORD" ] && [ -n "$APPLE_TEAM_ID" ]; then
        echo "==> Bắt đầu Notarization cho $DMG_NAME..." >&2
        xcrun notarytool submit "$DMG_DIST_PATH" --apple-id "$APPLE_ID" --password "$APPLE_ID_PASSWORD" --team-id "$APPLE_TEAM_ID" --wait >&2
        xcrun stapler staple "$DMG_DIST_PATH" >&2
    else
        echo "==> [CẢNH BÁO] Bỏ qua Notarization cho $DMG_NAME do thiếu cấu hình APPLE_ID hoặc APPLE_ID_PASSWORD." >&2
    fi
    
    # 5. Sign
    echo "==> Lấy chữ ký Sparkle cho $DMG_NAME..." >&2
    if [ -n "$SPARKLE_PRIVATE_KEY" ]; then
        SIGN_OUTPUT=$(printenv SPARKLE_PRIVATE_KEY | "$SPARKLE_TOOLS_DIR/bin/sign_update" --ed-key-file - "$DMG_DIST_PATH")
    else
        SIGN_OUTPUT=$("$SPARKLE_TOOLS_DIR/bin/sign_update" "$DMG_DIST_PATH")
    fi
    
    echo "$SIGN_OUTPUT"
}

# --- BUILD LEGACY (14.0+) ---
OUT_LEGACY=$(build_variant "14.0" "Closit-Legacy.dmg")
SIG_LEGACY=$(echo "$OUT_LEGACY" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2 | tail -n1)
LEN_LEGACY=$(echo "$OUT_LEGACY" | grep -o 'length="[^"]*"' | cut -d'"' -f2 | tail -n1)

# --- BUILD MODERN (26.0+) ---
OUT_MODERN=$(build_variant "26.0" "Closit-macOS26.dmg")
SIG_MODERN=$(echo "$OUT_MODERN" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2 | tail -n1)
LEN_MODERN=$(echo "$OUT_MODERN" | grep -o 'length="[^"]*"' | cut -d'"' -f2 | tail -n1)

# Khôi phục project.yml về mặc định (14.0)
sed -i '' 's/macOS: "[0-9.]*"/macOS: "14.0"/g' "$PROJECT_DIR/project.yml"
# Regenerate Xcode project to sync pbxproj
cd "$PROJECT_DIR" && xcodegen generate

echo "==> Đang tạo file appcast.xml đa nền tảng..."

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
            <title>Closit $MARKETING_VERSION (macOS 26+)</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:minimumSystemVersion>26.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://github.com/khanhworktime/Closit/releases/download/v$MARKETING_VERSION/Closit-macOS26.dmg"
                sparkle:version="$PROJECT_VERSION"
                sparkle:shortVersionString="$MARKETING_VERSION"
                length="$LEN_MODERN"
                type="application/octet-stream"
                sparkle:edSignature="$SIG_MODERN" />
        </item>
        <item>
            <title>Closit $MARKETING_VERSION (macOS 14 - 15)</title>
            <pubDate>$PUB_DATE</pubDate>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <sparkle:maximumSystemVersion>15.99</sparkle:maximumSystemVersion>
            <enclosure 
                url="https://github.com/khanhworktime/Closit/releases/download/v$MARKETING_VERSION/Closit-Legacy.dmg"
                sparkle:version="$PROJECT_VERSION"
                sparkle:shortVersionString="$MARKETING_VERSION"
                length="$LEN_LEGACY"
                type="application/octet-stream"
                sparkle:edSignature="$SIG_LEGACY" />
        </item>
    </channel>
</rss>
EOF

echo ""
echo "========================================================="
echo "🎉 HOÀN TẤT CHUẨN BỊ RELEASE KÉP 🎉"
echo "========================================================="
echo "Các file release đã sẵn sàng tại thư mục: $DIST_DIR"
echo "- Closit-macOS26.dmg (Dành cho macOS 26 trở lên)"
echo "- Closit-Legacy.dmg  (Dành cho macOS 14 - 15)"
echo "- appcast.xml        (Đã gộp chung cả 2 phiên bản)"
echo ""
echo "Các bước tiếp theo:"
echo "1. Tạo Release trên GitHub với tag là: v$MARKETING_VERSION"
echo "2. Upload CẢ 2 file DMG lên bản Release đó."
echo "3. Upload/Push file 'appcast.xml' lên GitHub Pages."
echo "========================================================="
