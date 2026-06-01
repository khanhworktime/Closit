import XCTest
@testable import Closit

final class AutoQuitControllerTests: XCTestCase {
    class MockActivityTracker: AppActivityTracking {
        var mockedTime: Date?
        func lastActiveTime(for bundleIdentifier: String) -> Date? {
            return mockedTime
        }
    }
    
    @MainActor
    func testAutoQuitControllerQuitsIdleApps() {
        let mockProvider = AppStateTests.MockRunningApplicationProvider()
        let mockTerminator = AppStateTests.MockAppTerminator()
        let mockStore = AppStateTests.MockSettingsStore()
        let mockTracker = MockActivityTracker()
        
        var currentTime = Date()
        let timeProvider = { currentTime }
        
        let app = AppInfo(name: "TestApp", bundleIdentifier: "com.test.app", processIdentifier: 123)
        mockProvider.appsToReturn = [app]
        
        mockStore.settings.isAutoQuitEnabled = true
        mockStore.settings.autoQuitIdleMinutes = 15
        
        let appState = ClositAppState(runningAppProvider: mockProvider, appTerminator: mockTerminator, settingsStore: mockStore, activityTracker: mockTracker)
        
        let controller = AutoQuitController(appState: appState, activityTracker: mockTracker, timeProvider: timeProvider)
        
        // Setup tracker to say the app was last active 16 minutes ago
        mockTracker.mockedTime = currentTime.addingTimeInterval(-16 * 60)
        
        // Trigger evaluate manually (since evaluateAndQuit is private, we can't call it directly, but we can start and stop quickly, or we can use reflection. Better yet, we can expose it as internal for testing if needed, or we just wait for the timer. Since we control the timer, we can't easily wait. Wait, let's just make it internal using `@testable`).
        // Actually, evaluateAndQuit is private. Let's start the timer with interval 0.01 and wait.
        let expectation = XCTestExpectation(description: "Wait for auto quit")
        controller.start(interval: 0.05)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            controller.stop()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertGreaterThanOrEqual(mockTerminator.quitCalls.count, 1)
        XCTAssertEqual(mockTerminator.quitCalls.first?.app.bundleIdentifier, "com.test.app")
        XCTAssertFalse(mockTerminator.quitCalls.first?.force ?? true) // Always graceful
    }
    
    @MainActor
    func testAutoQuitControllerIgnoresActiveApps() {
        let mockProvider = AppStateTests.MockRunningApplicationProvider()
        let mockTerminator = AppStateTests.MockAppTerminator()
        let mockStore = AppStateTests.MockSettingsStore()
        let mockTracker = MockActivityTracker()
        
        var currentTime = Date()
        let timeProvider = { currentTime }
        
        let app = AppInfo(name: "TestApp", bundleIdentifier: "com.test.app", processIdentifier: 123)
        mockProvider.appsToReturn = [app]
        
        mockStore.settings.isAutoQuitEnabled = true
        mockStore.settings.autoQuitIdleMinutes = 15
        
        let appState = ClositAppState(runningAppProvider: mockProvider, appTerminator: mockTerminator, settingsStore: mockStore, activityTracker: mockTracker)
        
        let controller = AutoQuitController(appState: appState, activityTracker: mockTracker, timeProvider: timeProvider)
        
        // 10 minutes idle < 15 minutes threshold
        mockTracker.mockedTime = currentTime.addingTimeInterval(-10 * 60)
        
        let expectation = XCTestExpectation(description: "Wait for auto quit")
        controller.start(interval: 0.05)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            controller.stop()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockTerminator.quitCalls.count, 0)
    }
}
