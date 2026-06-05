#!/usr/bin/env bash
set -e

# prepare_release.sh
# Tự động hóa quá trình build, tạo DMG và tạo file appcast.xml

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

echo "==> Build ứng dụng và tạo DMG..."
bash "$PROJECT_DIR/scripts/package-dmg.sh"

# Lấy thông tin file DMG
DMG_PATH="$PROJECT_DIR/build/Closit.dmg"
if [ ! -f "$DMG_PATH" ]; then
    echo "Lỗi: Không tìm thấy file DMG tại $DMG_PATH"
    exit 1
fi

# Chép DMG vào dist
cp "$DMG_PATH" "$DIST_DIR/"

echo "==> Đang tạo file appcast.xml..."

# Chạy sign_update để lấy signature và length
if [ -n "$SPARKLE_PRIVATE_KEY" ]; then
    echo "==> Ký bảo mật bản cập nhật bằng Private Key từ môi trường (GitHub Actions)..."
    SIGN_OUTPUT=$(printenv SPARKLE_PRIVATE_KEY | "$SPARKLE_TOOLS_DIR/bin/sign_update" --ed-key-file - "$DIST_DIR/Closit.dmg")
else
    echo "==> Ký bảo mật bản cập nhật bằng Private Key từ Keychain (Local)..."
    SIGN_OUTPUT=$("$SPARKLE_TOOLS_DIR/bin/sign_update" "$DIST_DIR/Closit.dmg")
fi

ED_SIG=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
FILE_LEN=$(echo "$SIGN_OUTPUT" | grep -o 'length="[^"]*"' | cut -d'"' -f2)

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
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://github.com/khanhworktime/Closit/releases/download/v$MARKETING_VERSION/Closit.dmg"
                sparkle:version="$PROJECT_VERSION"
                sparkle:shortVersionString="$MARKETING_VERSION"
                length="$FILE_LEN"
                type="application/octet-stream"
                sparkle:edSignature="$ED_SIG" />
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
echo ""
echo "Các bước tiếp theo:"
echo "1. Tạo Release trên GitHub với tag là: v$MARKETING_VERSION"
echo "2. Upload file 'Closit.dmg' lên bản Release đó."
echo "3. Upload/Push file 'appcast.xml' lên GitHub Pages."
echo "   (File appcast đã được tự động điền sẵn chữ ký bảo mật và URL)"
echo "========================================================="
