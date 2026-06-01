import Foundation

protocol RunningApplicationProviding {
    func runningApplications() -> [AppInfo]
}

struct PreviewRunningApplicationProvider: RunningApplicationProviding {
    func runningApplications() -> [AppInfo] {
        [
            AppInfo(
                name: "Safari",
                bundleIdentifier: "com.apple.Safari",
                processIdentifier: 101,
                isActive: true
            ),
            AppInfo(
                name: "Notes",
                bundleIdentifier: "com.apple.Notes",
                processIdentifier: 102
            )
        ]
    }
}
