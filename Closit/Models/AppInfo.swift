import Foundation

struct AppInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let processIdentifier: Int32
    let isActive: Bool
    let isRegular: Bool
    var cpu: Double
    var ram: Int64

    init(
        name: String,
        bundleIdentifier: String,
        processIdentifier: Int32,
        isActive: Bool = false,
        isRegular: Bool = true,
        cpu: Double = 0.0,
        ram: Int64 = 0
    ) {
        self.id = String(processIdentifier)
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.isActive = isActive
        self.isRegular = isRegular
        self.cpu = cpu
        self.ram = ram
    }
}
