import SwiftUI

@main
struct ClositApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            SettingsView(appState: delegate.appState)
                .environmentObject(delegate.updaterManager)
        }
    }
}
