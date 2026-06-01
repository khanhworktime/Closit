<div align="center">
  <img src="closeit_logo.png" width="128" alt="Closit Logo" />
  <h1>Closit</h1>
  <p><strong>A smart, elegant menu bar utility for macOS that automatically quits unused apps to free up memory and save battery.</strong></p>

  <p>
    <a href="https://github.com/khanhworktime/Closit/releases"><img src="https://img.shields.io/github/v/release/khanhworktime/Closit?style=flat-square" alt="Latest Release" /></a>
    <img src="https://img.shields.io/badge/Platform-macOS%2014.0+-blue?style=flat-square" alt="Platform: macOS" />
    <img src="https://img.shields.io/badge/Swift-5.0-orange?style=flat-square" alt="Swift 5.0" />
    <a href="https://ko-fi.com/kristhoang"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="ko-fi" /></a>
  </p>
</div>

<br/>

<div align="center">
  <img src="assets/screenshot.png" alt="Closit Screenshot" width="700" style="border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); margin-bottom: 20px;" />
</div>

<br/>

## ✨ Features

- 🔋 **Save Battery & Memory**: Automatically detects and quits applications that have been idle for a specified threshold.
- 🎯 **Smart Whitelisting**: Keep your important apps running. Essential system processes are protected by default.
- 👻 **Background App Detection**: Uncover hidden daemons and background tasks running silently on your Mac.
- 🎨 **Native SwiftUI Experience**: Beautiful, premium interface designed exclusively for macOS with smooth animations and dynamic layouts.
- ⚡️ **Lightweight**: Runs quietly in your menu bar with near-zero performance overhead.

## 🚀 Installation

1. Go to the [Releases](https://github.com/khanhworktime/Closit/releases) page.
2. Download the latest `Closit.dmg`.
3. Open the DMG and drag **Closit** into your `Applications` folder.
4. Launch Closit and enjoy a cleaner, faster Mac!

*(Note: Closit requires macOS 14.0 or later).*

## 🛠 Building from Source

Closit uses `xcodegen` to generate the Xcode project cleanly without merge conflicts.

### Prerequisites
- Xcode 15.0+
- macOS 14.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/khanhworktime/Closit.git
cd Closit

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open Closit.xcodeproj
```

You can also build and package the DMG directly using the included script:
```bash
./scripts/package-dmg.sh
```

## 💖 Support

If you find Closit helpful and want to support its development, consider buying me a coffee!

<a href='https://ko-fi.com/kristhoang' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/brandasset/v2/support_me_on_kofi_badge_beige.png' border='0' alt='Support on Ko-fi' /></a>

## 📄 License

This project is open-source and available under the MIT License.

---
<div align="center">
  <i>Designed and developed with ❤️ by <a href="https://github.com/khanhworktime">@khanhworktime</a></i><br>
  <i><a href="mailto:krist.dev.vn@gmail.com">krist.dev.vn@gmail.com</a></i>
</div>
