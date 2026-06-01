import AppKit
import Combine

protocol AppActivityTracking {
    func lastActiveTime(for bundleIdentifier: String) -> Date?
}

final class WorkspaceAppActivityTracker: AppActivityTracking {
    private var lastActiveTimes: [String: Date] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let timeProvider: () -> Date

    init(workspace: NSWorkspace = .shared, timeProvider: @escaping () -> Date = Date.init) {
        self.timeProvider = timeProvider
        
        // Initialize current running apps to current time as a baseline
        let now = timeProvider()
        for app in workspace.runningApplications {
            if let bundleId = app.bundleIdentifier {
                lastActiveTimes[bundleId] = now
            }
        }
        
        workspace.notificationCenter.publisher(for: NSWorkspace.didDeactivateApplicationNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleId = app.bundleIdentifier else { return }
                
                self.lastActiveTimes[bundleId] = self.timeProvider()
            }
            .store(in: &cancellables)
            
        workspace.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .sink { [weak self] notification in
                guard let self = self,
                      let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                      let bundleId = app.bundleIdentifier else { return }
                
                self.lastActiveTimes[bundleId] = self.timeProvider()
            }
            .store(in: &cancellables)
    }
    
    func lastActiveTime(for bundleIdentifier: String) -> Date? {
        return lastActiveTimes[bundleIdentifier]
    }
}
