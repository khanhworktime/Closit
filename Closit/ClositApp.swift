import SwiftUI

@main
struct ClositApp: App {
    @StateObject private var appState = ClositAppState()

    var body: some Scene {
        MenuBarExtra("Closit", image: "MenuBarIcon") {
            MenuContentView(appState: appState)
                .frame(width: 320)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(appState: appState)
        }
    }
}
