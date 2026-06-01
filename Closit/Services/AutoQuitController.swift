import Foundation
import Combine

@MainActor
final class AutoQuitController {
    private let appState: ClositAppState
    private let activityTracker: AppActivityTracking
    private let timeProvider: () -> Date
    private var timer: Timer?

    init(appState: ClositAppState, activityTracker: AppActivityTracking, timeProvider: @escaping () -> Date = Date.init) {
        self.appState = appState
        self.activityTracker = activityTracker
        self.timeProvider = timeProvider
    }

    @MainActor
    func start(interval: TimeInterval = 60.0) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateAndQuit()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @MainActor
    private func evaluateAndQuit() {
        guard appState.settings.isAutoQuitEnabled else { return }
        
        let thresholdMinutes = Double(appState.settings.autoQuitIdleMinutes)
        let thresholdSeconds = thresholdMinutes * 60.0
        let now = timeProvider()
        
        let candidates = AppRules.autoQuitCandidates(from: appState.apps, pinnedBundleIdentifiers: appState.settings.pinnedBundleIdentifiers)
        
        for app in candidates {
            if let lastActive = activityTracker.lastActiveTime(for: app.bundleIdentifier) {
                let idleTime = now.timeIntervalSince(lastActive)
                if idleTime >= thresholdSeconds {
                    appState.quitApp(app, force: false) // Auto quit always graceful
                }
            }
        }
    }
}
