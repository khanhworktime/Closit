import Foundation
import Sparkle

class UpdaterManager: ObservableObject {
    let updaterController: SPUStandardUpdaterController

    init() {
        // Khởi tạo Sparkle updater controller.
        // startingUpdater: true sẽ tự động bắt đầu updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    func checkForUpdates() {
        // Trigger check for updates manually
        updaterController.checkForUpdates(nil)
    }
}
