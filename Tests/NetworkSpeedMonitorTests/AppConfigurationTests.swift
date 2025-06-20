import XCTest
@testable import network_speed_monitor_mac_native

final class AppConfigurationTests: XCTestCase {
    
    func testAppInfo() {
        XCTAssertEqual(AppConfiguration.appName, "NetworkSpeedMonitor")
        XCTAssertFalse(AppConfiguration.appVersion.isEmpty)
    }
    
    func testUIConfiguration() {
        XCTAssertEqual(AppConfiguration.UI.windowWidth, 180)
        XCTAssertEqual(AppConfiguration.UI.windowHeight, 140)
        XCTAssertEqual(AppConfiguration.UI.windowMargin, 10)
        XCTAssertEqual(AppConfiguration.UI.cornerRadius, 12)
        XCTAssertEqual(AppConfiguration.UI.backgroundAlpha, 0.5)
        XCTAssertEqual(AppConfiguration.UI.lineSpacing, 28)
        XCTAssertEqual(AppConfiguration.UI.spacing, 8)
    }
    
    func testMonitoringConfiguration() {
        XCTAssertEqual(AppConfiguration.Monitoring.updateInterval, 3.0)
        XCTAssertTrue(AppConfiguration.Monitoring.networkInterfacePrefixes.contains("en"))
        XCTAssertTrue(AppConfiguration.Monitoring.networkInterfacePrefixes.contains("wi"))
        XCTAssertTrue(AppConfiguration.Monitoring.networkInterfacePrefixes.contains("eth"))
    }
    
    func testColorsConfiguration() {
        XCTAssertEqual(AppConfiguration.Colors.background.white, 0.08)
        XCTAssertEqual(AppConfiguration.Colors.background.alpha, 0.5)
        XCTAssertEqual(AppConfiguration.Colors.primaryText.red, 0.2)
        XCTAssertEqual(AppConfiguration.Colors.primaryText.green, 0.85)
        XCTAssertEqual(AppConfiguration.Colors.primaryText.blue, 1.0)
        XCTAssertEqual(AppConfiguration.Colors.primaryText.alpha, 1.0)
    }
    
    func testFontsConfiguration() {
        XCTAssertEqual(AppConfiguration.Fonts.titleSize, 12)
        XCTAssertEqual(AppConfiguration.Fonts.valueSize, 18)
        XCTAssertEqual(AppConfiguration.Fonts.unitSize, 12)
        XCTAssertEqual(AppConfiguration.Fonts.timeSize, 20)
    }
    
    func testResourcesConfiguration() {
        XCTAssertEqual(AppConfiguration.Resources.menuIcon, "netspeed_menu")
        XCTAssertEqual(AppConfiguration.Resources.appIcon, "netspeed.icns")
    }
}
