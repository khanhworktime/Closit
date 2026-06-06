import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static var shared: AppDelegate?
    
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: Any?
    var settingsWindow: NSWindow?

    let appState = ClositAppState()
    let updaterManager = UpdaterManager()

    override init() {
        super.init()
        Self.shared = self
    }

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
    
    @objc func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.setFrameAutosaveName("Settings")
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .unified
        window.delegate = self
        
        let settingsView = SettingsView(appState: appState)
            .environmentObject(updaterManager)
            
        window.contentView = NSHostingView(rootView: settingsView)
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            self.settingsWindow = nil
        }
    }
}
