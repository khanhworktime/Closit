import Foundation

protocol SettingsStoring {
    func load() -> ClositSettings
    func save(_ settings: ClositSettings)
}

struct UserDefaultsSettingsStore: SettingsStoring {
    private let key = "com.closeit.settings"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> ClositSettings {
        guard let data = userDefaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(ClositSettings.self, from: data) else {
            return ClositSettings()
        }
        return settings
    }

    func save(_ settings: ClositSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: key)
        }
    }
}
