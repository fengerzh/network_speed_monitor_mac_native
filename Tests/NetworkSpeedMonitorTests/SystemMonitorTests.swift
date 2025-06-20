import XCTest
@testable import network_speed_monitor_mac_native

final class SystemMonitorTests: XCTestCase {
    func testFormatSpeed() {
        XCTAssertEqual(SystemMonitor.formatSpeed(1024 * 1024 * 1024), "1.00G")
        XCTAssertEqual(SystemMonitor.formatSpeed(2 * 1024 * 1024), "2.00M")
        XCTAssertEqual(SystemMonitor.formatSpeed(512 * 1024), "512K")
        XCTAssertEqual(SystemMonitor.formatSpeed(500), "0")
    }

    func testGetNetworkBytes() {
        // 测试网络字节统计功能
        let (rx, tx) = SystemMonitor.getNetworkBytes()

        // 验证返回值是非负数
        XCTAssertGreaterThanOrEqual(rx, 0, "接收字节数应该是非负数")
        XCTAssertGreaterThanOrEqual(tx, 0, "发送字节数应该是非负数")

        // 验证函数能够正常执行并返回合理的值
        // 在正常运行的系统中，通常会有一些网络活动
        XCTAssertNotNil(rx, "接收字节数不应该为 nil")
        XCTAssertNotNil(tx, "发送字节数不应该为 nil")
    }
}