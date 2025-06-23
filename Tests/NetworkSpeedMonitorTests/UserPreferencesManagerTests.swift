import XCTest
@testable import network_speed_monitor_mac_native

final class UserPreferencesManagerTests: XCTestCase {
    
    var preferencesManager: UserPreferencesManager!
    let testSuiteName = "UserPreferencesManagerTests"
    
    override func setUp() {
        super.setUp()
        // 使用测试专用的UserDefaults
        preferencesManager = UserPreferencesManager(suiteName: testSuiteName)
    }
    
    override func tearDown() {
        // 清理测试数据
        if let userDefaults = UserDefaults(suiteName: testSuiteName) {
            userDefaults.removePersistentDomain(forName: testSuiteName)
        }
        preferencesManager = nil
        super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() {
        XCTAssertNotNil(preferencesManager)
        
        // 验证默认设置
        let preferences = preferencesManager.preferences
        XCTAssertEqual(preferences.updateInterval, 3.0)
        XCTAssertTrue(preferences.enabledMetrics.networkSpeed)
        XCTAssertTrue(preferences.enabledMetrics.cpuUsage)
        XCTAssertTrue(preferences.enabledMetrics.memoryUsage)
        XCTAssertTrue(preferences.enabledMetrics.batteryLevel)
        XCTAssertTrue(preferences.enabledMetrics.timeDisplay)
        XCTAssertFalse(preferences.autoStart)
        XCTAssertTrue(preferences.windowAlwaysOnTop)
        XCTAssertEqual(preferences.appearance.backgroundAlpha, 0.5)
        XCTAssertEqual(preferences.appearance.colorTheme, .blue)
    }
    
    // MARK: - 保存和加载测试
    
    func testSaveAndLoadPreferences() {
        // 修改设置
        var preferences = preferencesManager.preferences
        preferences.updateInterval = 5.0
        preferences.autoStart = true
        preferences.appearance.backgroundAlpha = 0.7
        preferences.appearance.colorTheme = .green
        preferences.enabledMetrics.networkSpeed = false
        
        // 保存设置
        let saveResult = preferencesManager.savePreferences(preferences)
        XCTAssertTrue(saveResult.isSuccess, "保存设置应该成功")
        
        // 重新创建管理器来测试加载
        let newManager = UserPreferencesManager(suiteName: testSuiteName)
        let loadedPreferences = newManager.preferences
        
        // 验证加载的设置
        XCTAssertEqual(loadedPreferences.updateInterval, 5.0)
        XCTAssertTrue(loadedPreferences.autoStart)
        XCTAssertEqual(loadedPreferences.appearance.backgroundAlpha, 0.7)
        XCTAssertEqual(loadedPreferences.appearance.colorTheme, .green)
        XCTAssertFalse(loadedPreferences.enabledMetrics.networkSpeed)
    }
    
    // MARK: - 更新设置测试
    
    func testUpdateUpdateInterval() {
        let result = preferencesManager.updateUpdateInterval(2.0)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 2.0)
    }
    
    func testUpdateUpdateIntervalInvalidValue() {
        let result = preferencesManager.updateUpdateInterval(0.5) // 小于最小值
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 3.0) // 应该保持原值
    }
    
    func testUpdateBackgroundAlpha() {
        let result = preferencesManager.updateBackgroundAlpha(0.8)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.appearance.backgroundAlpha, 0.8)
    }
    
    func testUpdateBackgroundAlphaInvalidValue() {
        let result = preferencesManager.updateBackgroundAlpha(1.5) // 大于最大值
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.appearance.backgroundAlpha, 0.5) // 应该保持原值
    }
    
    func testUpdateColorTheme() {
        let result = preferencesManager.updateColorTheme(.orange)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.appearance.colorTheme, .orange)
    }
    
    func testUpdateEnabledMetrics() {
        var metrics = EnabledMetrics()
        metrics.networkSpeed = false
        metrics.cpuUsage = false
        
        let result = preferencesManager.updateEnabledMetrics(metrics)
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(preferencesManager.preferences.enabledMetrics.networkSpeed)
        XCTAssertFalse(preferencesManager.preferences.enabledMetrics.cpuUsage)
        XCTAssertTrue(preferencesManager.preferences.enabledMetrics.memoryUsage) // 其他保持不变
    }
    
    func testUpdateAutoStart() {
        let result = preferencesManager.updateAutoStart(true)
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(preferencesManager.preferences.autoStart)
    }
    
    func testUpdateWindowAlwaysOnTop() {
        let result = preferencesManager.updateWindowAlwaysOnTop(false)
        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(preferencesManager.preferences.windowAlwaysOnTop)
    }
    
    // MARK: - 重置测试
    
    func testResetToDefaults() {
        // 先修改一些设置
        var preferences = preferencesManager.preferences
        preferences.updateInterval = 10.0
        preferences.autoStart = true
        preferences.appearance.colorTheme = .green
        _ = preferencesManager.savePreferences(preferences)
        
        // 重置为默认值
        let result = preferencesManager.resetToDefaults()
        XCTAssertTrue(result.isSuccess)
        
        // 验证已重置
        let resetPreferences = preferencesManager.preferences
        XCTAssertEqual(resetPreferences.updateInterval, 3.0)
        XCTAssertFalse(resetPreferences.autoStart)
        XCTAssertEqual(resetPreferences.appearance.colorTheme, .blue)
    }
    
    // MARK: - 验证测试
    
    func testValidateUpdateInterval() {
        XCTAssertTrue(preferencesManager.validateUpdateInterval(1.0))
        XCTAssertTrue(preferencesManager.validateUpdateInterval(5.0))
        XCTAssertTrue(preferencesManager.validateUpdateInterval(10.0))
        XCTAssertFalse(preferencesManager.validateUpdateInterval(0.5))
        XCTAssertFalse(preferencesManager.validateUpdateInterval(15.0))
    }
    
    func testValidateBackgroundAlpha() {
        XCTAssertTrue(preferencesManager.validateBackgroundAlpha(0.3))
        XCTAssertTrue(preferencesManager.validateBackgroundAlpha(0.5))
        XCTAssertTrue(preferencesManager.validateBackgroundAlpha(0.8))
        XCTAssertFalse(preferencesManager.validateBackgroundAlpha(0.2))
        XCTAssertFalse(preferencesManager.validateBackgroundAlpha(1.0))
    }
    
    // MARK: - 通知测试
    
    func testPreferencesChangedNotification() {
        let expectation = XCTestExpectation(description: "偏好设置变更通知")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .userPreferencesDidChange,
            object: nil,
            queue: .main
        ) { notification in
            XCTAssertNotNil(notification.userInfo)
            expectation.fulfill()
        }
        
        // 触发设置变更
        _ = preferencesManager.updateUpdateInterval(5.0)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - 错误处理测试
    
    func testInvalidJSONHandling() {
        // 这个测试验证当UserDefaults中有无效数据时的处理
        if let userDefaults = UserDefaults(suiteName: testSuiteName) {
            userDefaults.set("invalid json", forKey: UserPreferencesManager.preferencesKey)
        }
        
        // 重新创建管理器，应该回退到默认设置
        let newManager = UserPreferencesManager(suiteName: testSuiteName)
        let preferences = newManager.preferences
        
        // 应该是默认设置
        XCTAssertEqual(preferences.updateInterval, 3.0)
        XCTAssertEqual(preferences.appearance.colorTheme, .blue)
    }
}

// MARK: - 扩展：通知名称

extension Notification.Name {
    static let userPreferencesDidChange = Notification.Name("userPreferencesDidChange")
}
