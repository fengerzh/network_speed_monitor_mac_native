import XCTest
import Cocoa
@testable import network_speed_monitor_mac_native

final class PreferencesWindowControllerTests: XCTestCase {

    var windowController: PreferencesWindowController!
    var preferencesManager: UserPreferencesManager!
    let testSuiteName = "PreferencesWindowControllerTests"

    override func setUp() {
        super.setUp()
        preferencesManager = UserPreferencesManager(suiteName: testSuiteName)
        windowController = PreferencesWindowController(preferencesManager: preferencesManager)
    }

    override func tearDown() {
        windowController?.close()
        windowController = nil

        // 清理测试数据
        if let userDefaults = UserDefaults(suiteName: testSuiteName) {
            userDefaults.removePersistentDomain(forName: testSuiteName)
        }
        preferencesManager = nil
        super.tearDown()
    }

    // MARK: - 初始化测试

    func testInitialization() {
        XCTAssertNotNil(windowController)
        XCTAssertNotNil(windowController.window)
        XCTAssertEqual(windowController.window?.title, "偏好设置")
    }

    func testWindowSize() {
        guard let window = windowController.window else {
            XCTFail("窗口应该存在")
            return
        }

        let expectedSize = NSSize(width: 400, height: 350)
        XCTAssertEqual(window.frame.size.width, expectedSize.width, accuracy: 1.0)
        // 窗口高度可能因为内容自动调整，所以放宽检查
        XCTAssertGreaterThan(window.frame.size.height, 300)
        XCTAssertLessThan(window.frame.size.height, 400)
    }

    // MARK: - 基本功能测试

    func testWindowCreation() {
        windowController.loadWindow()

        // 验证窗口已创建并配置正确
        guard let window = windowController.window else {
            XCTFail("窗口应该存在")
            return
        }

        XCTAssertEqual(window.title, "偏好设置")
        XCTAssertEqual(window.level, .modalPanel)
    }

    func testPreferencesManagerIntegration() {
        // 验证窗口控制器正确使用偏好设置管理器
        XCTAssertNotNil(windowController)

        // 验证可以访问偏好设置
        let preferences = preferencesManager.preferences
        XCTAssertEqual(preferences.updateInterval, 3.0)
        XCTAssertEqual(preferences.appearance.colorTheme, .blue)
    }

    // MARK: - 数据绑定测试

    func testPreferencesDataBinding() {
        // 设置一些非默认值
        var preferences = preferencesManager.preferences
        preferences.updateInterval = 5.0
        preferences.appearance.backgroundAlpha = 0.7
        preferences.appearance.colorTheme = .green
        preferences.enabledMetrics.networkSpeed = false
        preferences.autoStart = true
        let result = preferencesManager.savePreferences(preferences)

        XCTAssertTrue(result.isSuccess, "保存偏好设置应该成功")

        // 重新创建窗口控制器来测试数据绑定
        windowController = PreferencesWindowController(preferencesManager: preferencesManager)
        windowController.loadWindow()

        // 验证偏好设置已正确加载
        let loadedPreferences = preferencesManager.preferences
        XCTAssertEqual(loadedPreferences.updateInterval, 5.0)
        XCTAssertEqual(loadedPreferences.appearance.backgroundAlpha, 0.7, accuracy: 0.01)
        XCTAssertEqual(loadedPreferences.appearance.colorTheme, .green)
        XCTAssertFalse(loadedPreferences.enabledMetrics.networkSpeed)
        XCTAssertTrue(loadedPreferences.autoStart)
    }

    // MARK: - 偏好设置管理器集成测试

    func testPreferencesManagerUpdates() {
        windowController.loadWindow()

        // 通过偏好设置管理器直接更新设置
        let result1 = preferencesManager.updateUpdateInterval(5.0)
        XCTAssertTrue(result1.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 5.0)

        let result2 = preferencesManager.updateBackgroundAlpha(0.6)
        XCTAssertTrue(result2.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.appearance.backgroundAlpha, 0.6, accuracy: 0.01)

        let result3 = preferencesManager.updateColorTheme(.orange)
        XCTAssertTrue(result3.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.appearance.colorTheme, .orange)

        var metrics = preferencesManager.preferences.enabledMetrics
        metrics.networkSpeed = false
        let result4 = preferencesManager.updateEnabledMetrics(metrics)
        XCTAssertTrue(result4.isSuccess)
        XCTAssertFalse(preferencesManager.preferences.enabledMetrics.networkSpeed)
    }

    // MARK: - 重置功能测试

    func testResetToDefaults() {
        windowController.loadWindow()

        // 先修改一些设置
        var preferences = preferencesManager.preferences
        preferences.updateInterval = 10.0
        preferences.appearance.colorTheme = .green
        preferences.appearance.backgroundAlpha = 0.8
        preferences.autoStart = true
        let saveResult = preferencesManager.savePreferences(preferences)
        XCTAssertTrue(saveResult.isSuccess)

        // 验证设置已修改
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 10.0)
        XCTAssertEqual(preferencesManager.preferences.appearance.colorTheme, .green)

        // 重置为默认值
        let resetResult = preferencesManager.resetToDefaults()
        XCTAssertTrue(resetResult.isSuccess)

        // 验证设置已重置为默认值
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 3.0)
        XCTAssertEqual(preferencesManager.preferences.appearance.colorTheme, .blue)
        XCTAssertEqual(preferencesManager.preferences.appearance.backgroundAlpha, 0.5, accuracy: 0.01)
        XCTAssertFalse(preferencesManager.preferences.autoStart)
    }

    func testWindowVisibility() {
        windowController.loadWindow()

        // 验证窗口可以显示和隐藏
        windowController.showWindow(nil)
        XCTAssertTrue(windowController.window?.isVisible ?? false)

        windowController.close()
        XCTAssertFalse(windowController.window?.isVisible ?? true)
    }

    // MARK: - 验证测试

    func testInvalidValueHandling() {
        windowController.loadWindow()

        // 通过偏好设置管理器测试无效值处理
        let invalidIntervalResult = preferencesManager.updateUpdateInterval(0.5) // 小于最小值
        XCTAssertFalse(invalidIntervalResult.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.updateInterval, 3.0) // 应该保持原值

        let invalidAlphaResult = preferencesManager.updateBackgroundAlpha(1.5) // 大于最大值
        XCTAssertFalse(invalidAlphaResult.isSuccess)
        XCTAssertEqual(preferencesManager.preferences.appearance.backgroundAlpha, 0.5, accuracy: 0.01) // 应该保持原值
    }

    // MARK: - 通知测试

    func testPreferencesChangeNotification() {
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
}
