import AppKit

protocol AppTerminating {
    func quit(app: AppInfo, force: Bool)
}

struct NSWorkspaceAppTerminator: AppTerminating {
    func quit(app: AppInfo, force: Bool) {
        let workspace = NSWorkspace.shared
        guard let runningApp = workspace.runningApplications.first(where: { $0.processIdentifier == app.processIdentifier }) else {
            return
        }
        
        if force {
            runningApp.forceTerminate()
        } else {
            runningApp.terminate()
        }
    }
}
