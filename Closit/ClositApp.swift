import SwiftUI

@main
struct ClositApp: App {
    @StateObject private var appState = ClositAppState()
    @StateObject private var updaterManager = UpdaterManager()

    var body: some Scene {
        MenuBarExtra("Closit", image: "MenuBarIcon") {
            MenuContentView(appState: appState)
                .frame(width: 320)
                .environmentObject(updaterManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: appState)
                .environmentObject(updaterManager)
        }
    }
}
