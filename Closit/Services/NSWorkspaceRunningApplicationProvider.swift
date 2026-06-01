import AppKit

struct NSWorkspaceRunningApplicationProvider: RunningApplicationProviding {
    func runningApplications() -> [AppInfo] {
        let workspace = NSWorkspace.shared
        let stats = ProcessStatsService.shared.fetchStats()
        return workspace.runningApplications
            .compactMap { app -> AppInfo? in
                guard let name = app.localizedName,
                      let bundleId = app.bundleIdentifier else {
                    return nil
                }
                let pid = app.processIdentifier
                let stat = stats[pid]
                return AppInfo(
                    name: name,
                    bundleIdentifier: bundleId,
                    processIdentifier: pid,
                    isActive: app.isActive,
                    isRegular: app.activationPolicy == .regular,
                    cpu: stat?.cpu ?? 0.0,
                    ram: stat?.ram ?? 0
                )
            }
    }
}
