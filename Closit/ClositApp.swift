import SwiftUI

@main
struct ClositApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences...") {
                    AppDelegate.shared?.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
