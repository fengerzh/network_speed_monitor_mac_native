import XCTest
@testable import network_speed_monitor_mac_native

final class AppErrorTests: XCTestCase {
    
    func testSystemMonitorError() {
        let error = AppError.systemMonitorError("Test error")
        XCTAssertEqual(error.errorDescription, "系统监控错误: Test error")
        XCTAssertEqual(error.recoverySuggestion, "请检查系统权限设置")
    }
    
    func testNetworkError() {
        let error = AppError.networkError("Network failure")
        XCTAssertEqual(error.errorDescription, "网络错误: Network failure")
        XCTAssertEqual(error.recoverySuggestion, "请检查网络连接")
    }
    
    func testUIError() {
        let error = AppError.uiError("UI issue")
        XCTAssertEqual(error.errorDescription, "界面错误: UI issue")
        XCTAssertEqual(error.recoverySuggestion, "请重启应用")
    }
    
    func testConfigurationError() {
        let error = AppError.configurationError("Config problem")
        XCTAssertEqual(error.errorDescription, "配置错误: Config problem")
        XCTAssertEqual(error.recoverySuggestion, "请检查应用配置")
    }
    
    func testPowerManagementError() {
        let error = AppError.powerManagementError("Power issue")
        XCTAssertEqual(error.errorDescription, "电源管理错误: Power issue")
        XCTAssertEqual(error.recoverySuggestion, "请检查系统电源管理权限")
    }
    
    func testResourceError() {
        let error = AppError.resourceError("Resource missing")
        XCTAssertEqual(error.errorDescription, "资源错误: Resource missing")
        XCTAssertEqual(error.recoverySuggestion, "请重新安装应用")
    }
}
