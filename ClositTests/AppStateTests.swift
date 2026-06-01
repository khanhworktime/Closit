import XCTest
@testable import Closit

final class AppStateTests: XCTestCase {
    
    class MockRunningApplicationProvider: RunningApplicationProviding {
        var appsToReturn: [AppInfo] = []
        func runningApplications() -> [AppInfo] {
            return appsToReturn
        }
    }
    
    class MockAppTerminator: AppTerminating {
        var quitCalls: [(app: AppInfo, force: Bool)] = []
        
        func quit(app: AppInfo, force: Bool) {
            quitCalls.append((app, force))
        }
    }
    
    class MockSettingsStore: SettingsStoring {
        var settings = ClositSettings()
        var saveCallCount = 0
        
        func load() -> ClositSettings {
            return settings
        }
        
        func save(_ settings: ClositSettings) {
            self.settings = settings
            saveCallCount += 1
        }
    }
    
    @MainActor
    func testQuitAppCallsTerminator() {
        let mockProvider = MockRunningApplicationProvider()
        let mockTerminator = MockAppTerminator()
        let mockStore = MockSettingsStore()
        
        let app = AppInfo(name: "TestApp", bundleIdentifier: "com.test.app", processIdentifier: 123)
        mockProvider.appsToReturn = [app]
        
        let appState = ClositAppState(runningAppProvider: mockProvider, appTerminator: mockTerminator, settingsStore: mockStore)
        
        appState.quitApp(app, force: false)
        
        XCTAssertEqual(mockTerminator.quitCalls.count, 1)
        XCTAssertEqual(mockTerminator.quitCalls[0].app.bundleIdentifier, "com.test.app")
        XCTAssertFalse(mockTerminator.quitCalls[0].force)
    }
    
    @MainActor
    func testForceQuitAppCallsTerminator() {
        let mockProvider = MockRunningApplicationProvider()
        let mockTerminator = MockAppTerminator()
        let mockStore = MockSettingsStore()
        
        let app = AppInfo(name: "TestApp", bundleIdentifier: "com.test.app", processIdentifier: 123)
        
        let appState = ClositAppState(runningAppProvider: mockProvider, appTerminator: mockTerminator, settingsStore: mockStore)
        
        appState.quitApp(app, force: true)
        
        XCTAssertEqual(mockTerminator.quitCalls.count, 1)
        XCTAssertEqual(mockTerminator.quitCalls[0].app.bundleIdentifier, "com.test.app")
        XCTAssertTrue(mockTerminator.quitCalls[0].force)
    }
    
    @MainActor
    func testTogglePinnedSavesSettings() {
        let mockProvider = MockRunningApplicationProvider()
        let mockTerminator = MockAppTerminator()
        let mockStore = MockSettingsStore()
        
        let app = AppInfo(name: "TestApp", bundleIdentifier: "com.test.app", processIdentifier: 123)
        let appState = ClositAppState(runningAppProvider: mockProvider, appTerminator: mockTerminator, settingsStore: mockStore)
        
        mockStore.saveCallCount = 0 // Reset since init triggers didSet
        
        appState.togglePinned(app)
        
        XCTAssertTrue(appState.isPinned(app))
        XCTAssertEqual(mockStore.saveCallCount, 1)
        XCTAssertTrue(mockStore.settings.pinnedBundleIdentifiers.contains("com.test.app"))
        
        appState.togglePinned(app)
        
        XCTAssertFalse(appState.isPinned(app))
        XCTAssertEqual(mockStore.saveCallCount, 2)
        XCTAssertFalse(mockStore.settings.pinnedBundleIdentifiers.contains("com.test.app"))
    }
    
    @MainActor
    func testQuitAllExcludesPinnedApps() {
        let mockProvider = MockRunningApplicationProvider()
        let mockTerminator = MockAppTerminator()
        let mockStore = MockSettingsStore()
        
        let pinnedApp = AppInfo(name: "Pinned", bundleIdentifier: "com.test.pinned", processIdentifier: 1)
        let normalApp = AppInfo(name: "Normal", bundleIdentifier: "com.test.normal", processIdentifier: 2)
        
        mockProvider.appsToReturn = [pinnedApp, normalApp]
        mockStore.settings.pinnedBundleIdentifiers = ["com.test.pinned"]
        
        let appState = ClositAppState(runningAppProvider: mockProvider, appTerminator: mockTerminator, settingsStore: mockStore)
        
        appState.quitAll()
        
        XCTAssertEqual(mockTerminator.quitCalls.count, 1)
        XCTAssertEqual(mockTerminator.quitCalls[0].app.bundleIdentifier, "com.test.normal")
    }
}
