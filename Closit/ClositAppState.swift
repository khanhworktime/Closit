import Foundation

@MainActor
final class ClositAppState: ObservableObject {
    @Published private(set) var apps: [AppInfo] = []
    @Published var settings = ClositSettings() {
        didSet {
            settingsStore.save(settings)
        }
    }
    @Published var selectedAppIDs: Set<String> = []
    private let runningAppProvider: RunningApplicationProviding
    private let appTerminator: AppTerminating
    private let settingsStore: SettingsStoring
    let activityTracker: AppActivityTracking
    private var autoQuitController: AutoQuitController?

    init(
        runningAppProvider: RunningApplicationProviding = NSWorkspaceRunningApplicationProvider(),
        appTerminator: AppTerminating = NSWorkspaceAppTerminator(),
        settingsStore: SettingsStoring = UserDefaultsSettingsStore(),
        activityTracker: AppActivityTracking = WorkspaceAppActivityTracker()
    ) {
        self.runningAppProvider = runningAppProvider
        self.appTerminator = appTerminator
        self.settingsStore = settingsStore
        self.activityTracker = activityTracker
        self.settings = settingsStore.load()
        
        refresh()
        
        // self.autoQuitController = AutoQuitController(appState: self, activityTracker: activityTracker)
        self.autoQuitController?.start()
    }

    func refresh() {
        apps = runningAppProvider.runningApplications()
    }

    func togglePinned(_ app: AppInfo) {
        var newSettings = settings
        if newSettings.pinnedBundleIdentifiers.contains(app.bundleIdentifier) {
            newSettings.pinnedBundleIdentifiers.remove(app.bundleIdentifier)
        } else {
            newSettings.pinnedBundleIdentifiers.insert(app.bundleIdentifier)
        }
        settings = newSettings
    }

    func isPinned(_ app: AppInfo) -> Bool {
        settings.pinnedBundleIdentifiers.contains(app.bundleIdentifier)
    }

    func quitApp(_ app: AppInfo, force: Bool = false) {
        appTerminator.quit(app: app, force: force)
        // Refresh a bit later to allow the OS to kill the process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }

    func quitAll() {
        let candidates = AppRules.quitCandidates(from: apps, pinnedBundleIdentifiers: settings.pinnedBundleIdentifiers)
        for app in candidates {
            appTerminator.quit(app: app, force: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }

    func completeOnboarding() {
        var newSettings = settings
        newSettings.hasSeenOnboarding = true
        settings = newSettings
    }

    func toggleSelection(_ app: AppInfo) {
        if selectedAppIDs.contains(app.id) {
            selectedAppIDs.remove(app.id)
        } else {
            selectedAppIDs.insert(app.id)
        }
    }

    func isSelected(_ app: AppInfo) -> Bool {
        selectedAppIDs.contains(app.id)
    }

    func quitSelected() {
        let candidates = apps.filter { selectedAppIDs.contains($0.id) }
        for app in candidates {
            appTerminator.quit(app: app, force: false)
        }
        selectedAppIDs.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }
}
