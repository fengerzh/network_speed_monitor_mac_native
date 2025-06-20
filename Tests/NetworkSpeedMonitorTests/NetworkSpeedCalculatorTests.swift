import XCTest
@testable import network_speed_monitor_mac_native

// Mock SystemMonitorService for testing
class MockSystemMonitorService: SystemMonitorServiceProtocol {
    var networkBytesResult: Result<(UInt64, UInt64), AppError> = .success((0, 0))
    var cpuUsageResult: Result<Double, AppError> = .success(0.0)
    var memoryInfoResult: Result<(UInt64, UInt64), AppError> = .success((0, 0))
    var batteryInfoResult: Result<BatteryInfo, AppError> = .success(BatteryInfo(percentage: nil, isCharging: false, isPresent: false))
    
    func getNetworkBytes() -> Result<(UInt64, UInt64), AppError> {
        return networkBytesResult
    }
    
    func getCPUUsage() -> Result<Double, AppError> {
        return cpuUsageResult
    }
    
    func getMemoryInfo() -> Result<(UInt64, UInt64), AppError> {
        return memoryInfoResult
    }
    
    func getBatteryInfo() -> Result<BatteryInfo, AppError> {
        return batteryInfoResult
    }
}

final class NetworkSpeedCalculatorTests: XCTestCase {
    
    var mockSystemMonitor: MockSystemMonitorService!
    var calculator: NetworkSpeedCalculator!
    
    override func setUp() {
        super.setUp()
        mockSystemMonitor = MockSystemMonitorService()
        calculator = NetworkSpeedCalculator(systemMonitor: mockSystemMonitor)
    }
    
    override func tearDown() {
        calculator = nil
        mockSystemMonitor = nil
        super.tearDown()
    }
    
    func testInitialCalculation() {
        // 第一次计算应该没有速度数据
        mockSystemMonitor.networkBytesResult = .success((1024, 512))
        
        let result = calculator.calculateSpeed()
        
        switch result {
        case .success(let networkStats):
            XCTAssertEqual(networkStats.receivedBytes, 1024)
            XCTAssertEqual(networkStats.transmittedBytes, 512)
            XCTAssertNil(networkStats.downloadSpeed)
            XCTAssertNil(networkStats.uploadSpeed)
            XCTAssertFalse(networkStats.isValid)
        case .failure(let error):
            XCTFail("Should succeed: \(error)")
        }
    }
    
    func testSpeedCalculation() {
        // 第一次调用建立基线
        mockSystemMonitor.networkBytesResult = .success((1024, 512))
        _ = calculator.calculateSpeed()
        
        // 等待一小段时间
        Thread.sleep(forTimeInterval: 0.1)
        
        // 第二次调用计算速度
        mockSystemMonitor.networkBytesResult = .success((2048, 1024))
        
        let result = calculator.calculateSpeed()
        
        switch result {
        case .success(let networkStats):
            XCTAssertEqual(networkStats.receivedBytes, 2048)
            XCTAssertEqual(networkStats.transmittedBytes, 1024)
            XCTAssertNotNil(networkStats.downloadSpeed)
            XCTAssertNotNil(networkStats.uploadSpeed)
            XCTAssertTrue(networkStats.isValid)
            
            // 验证速度计算（1024字节在0.1秒内 = 10240字节/秒）
            if let downloadSpeed = networkStats.downloadSpeed {
                XCTAssertGreaterThan(downloadSpeed, 0)
            }
            if let uploadSpeed = networkStats.uploadSpeed {
                XCTAssertGreaterThan(uploadSpeed, 0)
            }
        case .failure(let error):
            XCTFail("Should succeed: \(error)")
        }
    }
    
    func testNetworkError() {
        mockSystemMonitor.networkBytesResult = .failure(.networkError("Test error"))
        
        let result = calculator.calculateSpeed()
        
        switch result {
        case .success:
            XCTFail("Should fail with network error")
        case .failure(let error):
            if case .networkError(let message) = error {
                XCTAssertEqual(message, "Test error")
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    func testReset() {
        // 建立一些历史数据
        mockSystemMonitor.networkBytesResult = .success((1024, 512))
        _ = calculator.calculateSpeed()
        
        // 重置计算器
        calculator.reset()
        
        // 下一次计算应该没有速度数据
        mockSystemMonitor.networkBytesResult = .success((2048, 1024))
        let result = calculator.calculateSpeed()
        
        switch result {
        case .success(let networkStats):
            XCTAssertNil(networkStats.downloadSpeed)
            XCTAssertNil(networkStats.uploadSpeed)
            XCTAssertFalse(networkStats.isValid)
        case .failure(let error):
            XCTFail("Should succeed: \(error)")
        }
    }
    
    func testBytesDecrease() {
        // 第一次调用
        mockSystemMonitor.networkBytesResult = .success((2048, 1024))
        _ = calculator.calculateSpeed()
        
        // 第二次调用，字节数减少（不应该计算速度）
        mockSystemMonitor.networkBytesResult = .success((1024, 512))
        
        let result = calculator.calculateSpeed()
        
        switch result {
        case .success(let networkStats):
            XCTAssertEqual(networkStats.receivedBytes, 1024)
            XCTAssertEqual(networkStats.transmittedBytes, 512)
            XCTAssertNil(networkStats.downloadSpeed)
            XCTAssertNil(networkStats.uploadSpeed)
            XCTAssertFalse(networkStats.isValid)
        case .failure(let error):
            XCTFail("Should succeed: \(error)")
        }
    }
}
