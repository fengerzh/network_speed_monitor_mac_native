import XCTest
@testable import network_speed_monitor_mac_native

final class SystemMonitorTests: XCTestCase {
    func testFormatSpeed() {
        XCTAssertEqual(SystemMonitor.formatSpeed(1024 * 1024 * 1024), "1.00G")
        XCTAssertEqual(SystemMonitor.formatSpeed(2 * 1024 * 1024), "2.00M")
        XCTAssertEqual(SystemMonitor.formatSpeed(512 * 1024), "512K")
        XCTAssertEqual(SystemMonitor.formatSpeed(500), "0")
    }
} 