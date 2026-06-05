import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: Any?

    let appState = ClositAppState()
    let updaterManager = UpdaterManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI view that provides the menu contents.
        let contentView = MenuContentView(appState: appState)
            .environmentObject(updaterManager)
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400) // Height will adjust dynamically
        popover.behavior = .transient // Automatically close when clicking outside
        popover.contentViewController = NSHostingController(rootView: contentView)

        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.action = #selector(togglePopover(_:))
        }
        
        // Ensure the app doesn't show up in the dock
        NSApp.setActivationPolicy(.accessory)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                popover.contentViewController?.view.window?.makeKey()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
