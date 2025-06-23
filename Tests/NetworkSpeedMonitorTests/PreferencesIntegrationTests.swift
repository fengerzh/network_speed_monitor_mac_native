import XCTest
import Cocoa
@testable import network_speed_monitor_mac_native

final class PreferencesIntegrationTests: XCTestCase {
    
    var speedPanel: SpeedPanelView!
    var preferencesManager: UserPreferencesManager!
    let testSuiteName = "PreferencesIntegrationTests"
    
    override func setUp() {
        super.setUp()
        preferencesManager = UserPreferencesManager(suiteName: testSuiteName)
        speedPanel = SpeedPanelView(frame: NSRect(x: 0, y: 0, width: 180, height: 140))
        speedPanel.userPreferences = preferencesManager.preferences
    }
    
    override func tearDown() {
        // 清理测试数据
        if let userDefaults = UserDefaults(suiteName: testSuiteName) {
            userDefaults.removePersistentDomain(forName: testSuiteName)
        }
        speedPanel = nil
        preferencesManager = nil
        super.tearDown()
    }
    
    // MARK: - 偏好设置生效测试
    
    func testBackgroundAlphaChanges() {
        // 设置初始透明度
        speedPanel.userPreferences = preferencesManager.preferences
        XCTAssertEqual(speedPanel.userPreferences.appearance.backgroundAlpha, 0.5, accuracy: 0.01)
        
        // 修改透明度设置
        let result = preferencesManager.updateBackgroundAlpha(0.7)
        XCTAssertTrue(result.isSuccess)
        
        // 更新SpeedPanel的偏好设置
        speedPanel.userPreferences = preferencesManager.preferences
        XCTAssertEqual(speedPanel.userPreferences.appearance.backgroundAlpha, 0.7, accuracy: 0.01)
    }
    
    func testColorThemeChanges() {
        // 设置初始颜色主题
        speedPanel.userPreferences = preferencesManager.preferences
        XCTAssertEqual(speedPanel.userPreferences.appearance.colorTheme, .blue)
        
        // 修改颜色主题
        let result = preferencesManager.updateColorTheme(.green)
        XCTAssertTrue(result.isSuccess)
        
        // 更新SpeedPanel的偏好设置
        speedPanel.userPreferences = preferencesManager.preferences
        XCTAssertEqual(speedPanel.userPreferences.appearance.colorTheme, .green)
        
        // 验证颜色值
        let greenColor = speedPanel.userPreferences.appearance.colorTheme.primaryColor
        XCTAssertEqual(greenColor.red, 0.2, accuracy: 0.01)
        XCTAssertEqual(greenColor.green, 1.0, accuracy: 0.01)
        XCTAssertEqual(greenColor.blue, 0.4, accuracy: 0.01)
    }
    
    func testEnabledMetricsChanges() {
        // 设置初始显示内容（默认全部启用）
        speedPanel.userPreferences = preferencesManager.preferences
        XCTAssertTrue(speedPanel.userPreferences.enabledMetrics.networkSpeed)
        XCTAssertTrue(speedPanel.userPreferences.enabledMetrics.cpuUsage)
        XCTAssertTrue(speedPanel.userPreferences.enabledMetrics.memoryUsage)
        XCTAssertTrue(speedPanel.userPreferences.enabledMetrics.batteryLevel)
        XCTAssertTrue(speedPanel.userPreferences.enabledMetrics.timeDisplay)
        
        // 修改显示内容设置
        var metrics = preferencesManager.preferences.enabledMetrics
        metrics.networkSpeed = false
        metrics.cpuUsage = false
        metrics.timeDisplay = false
        
        let result = preferencesManager.updateEnabledMetrics(metrics)
        XCTAssertTrue(result.isSuccess)
        
        // 更新SpeedPanel的偏好设置
        speedPanel.userPreferences = preferencesManager.preferences
        XCTAssertFalse(speedPanel.userPreferences.enabledMetrics.networkSpeed)
        XCTAssertFalse(speedPanel.userPreferences.enabledMetrics.cpuUsage)
        XCTAssertTrue(speedPanel.userPreferences.enabledMetrics.memoryUsage) // 仍然启用
        XCTAssertTrue(speedPanel.userPreferences.enabledMetrics.batteryLevel) // 仍然启用
        XCTAssertFalse(speedPanel.userPreferences.enabledMetrics.timeDisplay)
    }
    
    func testUpdateIntervalChanges() {
        // 设置初始刷新间隔
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 3.0)
        
        // 修改刷新间隔
        let result = preferencesManager.updateUpdateInterval(5.0)
        XCTAssertTrue(result.isSuccess)
        
        // 验证设置已更新
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 5.0)
    }
    
    func testWindowAlwaysOnTopChanges() {
        // 设置初始窗口置顶状态
        XCTAssertTrue(preferencesManager.preferences.windowAlwaysOnTop)
        
        // 修改窗口置顶设置
        let result = preferencesManager.updateWindowAlwaysOnTop(false)
        XCTAssertTrue(result.isSuccess)
        
        // 验证设置已更新
        XCTAssertFalse(preferencesManager.preferences.windowAlwaysOnTop)
    }
    
    func testAutoStartChanges() {
        // 设置初始开机自启动状态
        XCTAssertFalse(preferencesManager.preferences.autoStart)
        
        // 修改开机自启动设置
        let result = preferencesManager.updateAutoStart(true)
        XCTAssertTrue(result.isSuccess)
        
        // 验证设置已更新
        XCTAssertTrue(preferencesManager.preferences.autoStart)
    }
    
    // MARK: - 完整的偏好设置流程测试
    
    func testCompletePreferencesWorkflow() {
        // 1. 验证默认设置
        let defaultPrefs = preferencesManager.preferences
        XCTAssertEqual(defaultPrefs.updateInterval, 3.0)
        XCTAssertEqual(defaultPrefs.appearance.backgroundAlpha, 0.5, accuracy: 0.01)
        XCTAssertEqual(defaultPrefs.appearance.colorTheme, .blue)
        XCTAssertTrue(defaultPrefs.enabledMetrics.networkSpeed)
        XCTAssertFalse(defaultPrefs.autoStart)
        XCTAssertTrue(defaultPrefs.windowAlwaysOnTop)
        
        // 2. 修改多个设置
        var newPrefs = defaultPrefs
        newPrefs.updateInterval = 2.0
        newPrefs.appearance.backgroundAlpha = 0.8
        newPrefs.appearance.colorTheme = .orange
        newPrefs.enabledMetrics.networkSpeed = false
        newPrefs.enabledMetrics.timeDisplay = false
        newPrefs.autoStart = true
        newPrefs.windowAlwaysOnTop = false
        
        let saveResult = preferencesManager.savePreferences(newPrefs)
        XCTAssertTrue(saveResult.isSuccess)
        
        // 3. 验证所有设置都已保存
        let savedPrefs = preferencesManager.preferences
        XCTAssertEqual(savedPrefs.updateInterval, 2.0)
        XCTAssertEqual(savedPrefs.appearance.backgroundAlpha, 0.8, accuracy: 0.01)
        XCTAssertEqual(savedPrefs.appearance.colorTheme, .orange)
        XCTAssertFalse(savedPrefs.enabledMetrics.networkSpeed)
        XCTAssertFalse(savedPrefs.enabledMetrics.timeDisplay)
        XCTAssertTrue(savedPrefs.autoStart)
        XCTAssertFalse(savedPrefs.windowAlwaysOnTop)
        
        // 4. 更新SpeedPanel并验证
        speedPanel.userPreferences = savedPrefs
        XCTAssertEqual(speedPanel.userPreferences.appearance.backgroundAlpha, 0.8, accuracy: 0.01)
        XCTAssertEqual(speedPanel.userPreferences.appearance.colorTheme, .orange)
        XCTAssertFalse(speedPanel.userPreferences.enabledMetrics.networkSpeed)
        XCTAssertFalse(speedPanel.userPreferences.enabledMetrics.timeDisplay)
        
        // 5. 重置为默认值
        let resetResult = preferencesManager.resetToDefaults()
        XCTAssertTrue(resetResult.isSuccess)
        
        // 6. 验证已重置
        let resetPrefs = preferencesManager.preferences
        XCTAssertEqual(resetPrefs.updateInterval, 3.0)
        XCTAssertEqual(resetPrefs.appearance.backgroundAlpha, 0.5, accuracy: 0.01)
        XCTAssertEqual(resetPrefs.appearance.colorTheme, .blue)
        XCTAssertTrue(resetPrefs.enabledMetrics.networkSpeed)
        XCTAssertTrue(resetPrefs.enabledMetrics.timeDisplay)
        XCTAssertFalse(resetPrefs.autoStart)
        XCTAssertTrue(resetPrefs.windowAlwaysOnTop)
    }
    
    // MARK: - 通知机制测试
    
    func testPreferencesChangeNotificationIntegration() {
        let expectation = XCTestExpectation(description: "偏好设置变更通知集成测试")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .userPreferencesDidChange,
            object: nil,
            queue: .main
        ) { notification in
            // 验证通知包含正确的信息
            XCTAssertNotNil(notification.userInfo)
            if let preferences = notification.userInfo?["preferences"] as? UserPreferences {
                XCTAssertEqual(preferences.updateInterval, 7.0)
            }
            expectation.fulfill()
        }
        
        // 触发设置变更
        _ = preferencesManager.updateUpdateInterval(7.0)
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
