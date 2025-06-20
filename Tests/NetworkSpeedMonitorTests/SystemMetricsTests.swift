import XCTest
@testable import network_speed_monitor_mac_native

final class SystemMetricsTests: XCTestCase {
    
    func testNetworkStats() {
        let networkStats = NetworkStats(
            receivedBytes: 1024,
            transmittedBytes: 512,
            downloadSpeed: 2048.0,  // 2K
            uploadSpeed: 1536.0     // 1.5K
        )

        XCTAssertEqual(networkStats.receivedBytes, 1024)
        XCTAssertEqual(networkStats.transmittedBytes, 512)
        XCTAssertEqual(networkStats.downloadSpeed, 2048.0)
        XCTAssertEqual(networkStats.uploadSpeed, 1536.0)
        XCTAssertTrue(networkStats.isValid)
        XCTAssertEqual(networkStats.formattedDownloadSpeed, "2K")
        XCTAssertEqual(networkStats.formattedUploadSpeed, "2K")  // 1536 / 1024 = 1.5, 格式化为 "2K"
    }
    
    func testNetworkStatsInvalid() {
        let networkStats = NetworkStats(
            receivedBytes: 1024,
            transmittedBytes: 512,
            downloadSpeed: nil,
            uploadSpeed: nil
        )
        
        XCTAssertFalse(networkStats.isValid)
        XCTAssertEqual(networkStats.formattedDownloadSpeed, "--")
        XCTAssertEqual(networkStats.formattedUploadSpeed, "--")
    }
    
    func testCPUUsage() {
        let cpuUsage = CPUUsage(percentage: 75.5)
        
        XCTAssertEqual(cpuUsage.percentage, 75.5)
        XCTAssertTrue(cpuUsage.isValid)
        XCTAssertEqual(cpuUsage.formattedPercentage, "75.5")
    }
    
    func testCPUUsageInvalid() {
        let cpuUsage = CPUUsage(percentage: nil)
        
        XCTAssertNil(cpuUsage.percentage)
        XCTAssertFalse(cpuUsage.isValid)
        XCTAssertEqual(cpuUsage.formattedPercentage, "--")
    }
    
    func testMemoryInfo() {
        let memoryInfo = MemoryInfo(totalBytes: 8 * 1024 * 1024 * 1024, usedBytes: 4 * 1024 * 1024 * 1024)
        
        XCTAssertEqual(memoryInfo.totalBytes, 8 * 1024 * 1024 * 1024)
        XCTAssertEqual(memoryInfo.usedBytes, 4 * 1024 * 1024 * 1024)
        XCTAssertEqual(memoryInfo.usagePercentage, 50.0, accuracy: 0.1)
        XCTAssertEqual(memoryInfo.formattedUsedMemory, "4.00 GB")
    }
    
    func testBatteryInfo() {
        let batteryInfo = BatteryInfo(percentage: 85, isCharging: false, isPresent: true)
        
        XCTAssertEqual(batteryInfo.percentage, 85)
        XCTAssertFalse(batteryInfo.isCharging)
        XCTAssertTrue(batteryInfo.isPresent)
        XCTAssertEqual(batteryInfo.formattedPercentage, "85")
        XCTAssertEqual(batteryInfo.displayText, "85")
    }
    
    func testBatteryInfoCharging() {
        let batteryInfo = BatteryInfo(percentage: 85, isCharging: true, isPresent: true)
        
        XCTAssertEqual(batteryInfo.displayText, "85⚡")
    }
    
    func testBatteryInfoNotPresent() {
        let batteryInfo = BatteryInfo(percentage: nil, isCharging: false, isPresent: false)
        
        XCTAssertNil(batteryInfo.percentage)
        XCTAssertFalse(batteryInfo.isPresent)
        XCTAssertEqual(batteryInfo.formattedPercentage, "--")
        XCTAssertEqual(batteryInfo.displayText, "--")
    }
    
    func testSystemMetricsFormatter() {
        XCTAssertEqual(SystemMetricsFormatter.formatSpeed(1024 * 1024 * 1024), "1.00G")
        XCTAssertEqual(SystemMetricsFormatter.formatSpeed(2 * 1024 * 1024), "2.00M")
        XCTAssertEqual(SystemMetricsFormatter.formatSpeed(512 * 1024), "512K")
        XCTAssertEqual(SystemMetricsFormatter.formatSpeed(500), "0")
        
        XCTAssertEqual(SystemMetricsFormatter.formatMemory(1024 * 1024 * 1024), "1.00 GB")
        XCTAssertEqual(SystemMetricsFormatter.formatMemory(512 * 1024 * 1024), "512.0 MB")
        XCTAssertEqual(SystemMetricsFormatter.formatMemory(256 * 1024), "256 KB")
        XCTAssertEqual(SystemMetricsFormatter.formatMemory(100), "100 B")
    }
}
