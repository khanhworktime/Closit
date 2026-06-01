import Foundation

struct ClositSettings: Equatable, Codable {
    var pinnedBundleIdentifiers: Set<String> = []
    var isAdvancedModeEnabled = false
    var isAutoQuitEnabled = false
    var autoQuitIdleMinutes = 30
    var hasSeenOnboarding = false
    var showBackgroundApps = false
    var isDeveloperModeEnabled = false
}
