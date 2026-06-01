import XCTest
@testable import Closit

final class AppRulesTests: XCTestCase {
    func testQuitCandidatesExcludePinnedApps() {
        let apps = [
            AppInfo(name: "Safari", bundleIdentifier: "com.apple.Safari", processIdentifier: 1),
            AppInfo(name: "Notes", bundleIdentifier: "com.apple.Notes", processIdentifier: 2)
        ]

        let candidates = AppRules.quitCandidates(
            from: apps,
            pinnedBundleIdentifiers: ["com.apple.Safari"]
        )

        XCTAssertEqual(candidates, [
            AppInfo(name: "Notes", bundleIdentifier: "com.apple.Notes", processIdentifier: 2)
        ])
    }

    func testQuitCandidatesExcludeProtectedApps() {
        let apps = [
            AppInfo(name: "Finder", bundleIdentifier: "com.apple.finder", processIdentifier: 1),
            AppInfo(name: "Notes", bundleIdentifier: "com.apple.Notes", processIdentifier: 2)
        ]

        let candidates = AppRules.quitCandidates(from: apps, pinnedBundleIdentifiers: [])

        XCTAssertEqual(candidates, [
            AppInfo(name: "Notes", bundleIdentifier: "com.apple.Notes", processIdentifier: 2)
        ])
    }

    func testAutoQuitCandidatesExcludePinnedApps() {
        let testApps = [
            AppInfo(name: "Safari", bundleIdentifier: "com.apple.Safari", processIdentifier: 1),
            AppInfo(name: "Notes", bundleIdentifier: "com.apple.Notes", processIdentifier: 2)
        ]
        let candidates = AppRules.autoQuitCandidates(from: testApps, pinnedBundleIdentifiers: ["com.apple.Safari"])
        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.name, "Notes")
    }
}
