import Foundation

enum AppRules {
    static let protectedBundleIdentifiers: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.loginwindow",
        "com.apple.systemuiserver"
    ]

    static func isUserFacing(_ app: AppInfo) -> Bool {
        app.isRegular && !app.name.isEmpty && !protectedBundleIdentifiers.contains(app.bundleIdentifier)
    }

    static func quitCandidates(from apps: [AppInfo], pinnedBundleIdentifiers: Set<String>) -> [AppInfo] {
        return apps.filter { app in
            isUserFacing(app) && !pinnedBundleIdentifiers.contains(app.bundleIdentifier)
        }
    }
    
    static func autoQuitCandidates(from apps: [AppInfo], pinnedBundleIdentifiers: Set<String>) -> [AppInfo] {
        // For now, auto quit shares the exact same filtering rules as Quit All.
        return quitCandidates(from: apps, pinnedBundleIdentifiers: pinnedBundleIdentifiers)
    }
}
