# Sparkle Auto-Update Guide for Closit

Tài liệu này hướng dẫn bạn cách phát hành một phiên bản mới của Closit bằng Sparkle để người dùng có thể tự động cập nhật.

## 1. Chuẩn bị file `appcast.xml`

File `appcast.xml` là file RSS Feed mà Sparkle sẽ đọc để biết có phiên bản mới hay không.
Bạn có thể host file này ở GitHub Pages hoặc bất kỳ server nào. 
Theo cấu hình hiện tại, ứng dụng sẽ tìm file này tại: `https://khanhworktime.github.io/Closit/appcast.xml`

**Cấu trúc mẫu của file `appcast.xml`**:
```xml
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
    <channel>
        <title>Closit Changelog</title>
        <item>
            <title>1.0.1 (Bản cập nhật mới)</title>
            <pubDate>Mon, 02 Jun 2026 12:00:00 +0000</pubDate>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure 
                url="https://github.com/khanhworktime/Closit/releases/download/v1.0.1/Closit.dmg"
                sparkle:version="11"
                sparkle:shortVersionString="1.0.1"
                length="12345678"
                type="application/octet-stream"
                sparkle:edSignature="CHU_KY_EDDSA_SINH_RA_TU_SCRIPT_PACKAGE" />
        </item>
    </channel>
</rss>
```

## 2. Quy trình phát hành bản cập nhật mới

1. Mở file `project.yml`, cập nhật `MARKETING_VERSION` (ví dụ: `1.0.1`) và `CURRENT_PROJECT_VERSION` (ví dụ: `11`).
2. Chạy lệnh tạo project: `xcodegen generate`.
3. Chạy lệnh build và tạo DMG: `./scripts/package-dmg.sh`.
4. Ở cuối output của script, bạn sẽ thấy nó in ra dòng chữ ký **EdDSA Signature** cho file `Closit.dmg` mới. Copy lại chữ ký và dung lượng byte file (`length`).
5. Tạo một bản Release mới trên GitHub và upload file `Closit.dmg` lên (ví dụ URL của dmg là `https://github.com/khanhworktime/Closit/releases/download/v1.0.1/Closit.dmg`).
6. Cập nhật file `appcast.xml` của bạn (thêm một thẻ `<item>` mới) với `url`, `length` và `sparkle:edSignature` vừa lấy được.
7. Đẩy (push) file `appcast.xml` lên GitHub Pages.
8. Hoàn tất! Người dùng Closit hiện tại khi nhấn "Check for Updates..." hoặc chờ tự động quét sẽ nhận được bản cập nhật mới.

## 3. Khóa bảo mật (Keys)

- **Public Key**: Được khai báo trong `project.yml` ở mục `SUPublicEDKey`.
- **Private Key**: Được lưu trong Keychain trên máy Mac của bạn. Hãy đảm bảo bạn không làm mất Keychain này, nếu không bạn sẽ không thể tạo chữ ký (`edSignature`) hợp lệ cho các bản cập nhật sau.
