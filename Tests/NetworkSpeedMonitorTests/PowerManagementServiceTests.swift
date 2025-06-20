import XCTest
@testable import network_speed_monitor_mac_native

final class PowerManagementServiceTests: XCTestCase {
    
    var powerManagement: PowerManagementService!
    
    override func setUp() {
        super.setUp()
        powerManagement = PowerManagementService.shared
        // 确保测试开始时咖啡模式是关闭的
        if powerManagement.isCoffeeModeEnabled {
            _ = powerManagement.disableCoffeeMode()
        }
    }
    
    override func tearDown() {
        // 清理：确保测试结束时咖啡模式是关闭的
        if powerManagement.isCoffeeModeEnabled {
            _ = powerManagement.disableCoffeeMode()
        }
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(powerManagement.isCoffeeModeEnabled)
    }
    
    func testEnableCoffeeMode() {
        let result = powerManagement.enableCoffeeMode()
        
        switch result {
        case .success:
            XCTAssertTrue(powerManagement.isCoffeeModeEnabled)
        case .failure(let error):
            XCTFail("Failed to enable coffee mode: \(error)")
        }
    }
    
    func testDisableCoffeeMode() {
        // 先启用咖啡模式
        _ = powerManagement.enableCoffeeMode()
        XCTAssertTrue(powerManagement.isCoffeeModeEnabled)
        
        // 然后禁用
        let result = powerManagement.disableCoffeeMode()
        
        switch result {
        case .success:
            XCTAssertFalse(powerManagement.isCoffeeModeEnabled)
        case .failure(let error):
            XCTFail("Failed to disable coffee mode: \(error)")
        }
    }
    
    func testToggleCoffeeMode() {
        // 初始状态应该是关闭的
        XCTAssertFalse(powerManagement.isCoffeeModeEnabled)
        
        // 第一次切换：开启
        let result1 = powerManagement.toggleCoffeeMode()
        switch result1 {
        case .success(let enabled):
            XCTAssertTrue(enabled)
            XCTAssertTrue(powerManagement.isCoffeeModeEnabled)
        case .failure(let error):
            XCTFail("Failed to toggle coffee mode: \(error)")
        }
        
        // 第二次切换：关闭
        let result2 = powerManagement.toggleCoffeeMode()
        switch result2 {
        case .success(let enabled):
            XCTAssertFalse(enabled)
            XCTAssertFalse(powerManagement.isCoffeeModeEnabled)
        case .failure(let error):
            XCTFail("Failed to toggle coffee mode: \(error)")
        }
    }
    
    func testEnableAlreadyEnabled() {
        // 先启用咖啡模式
        _ = powerManagement.enableCoffeeMode()
        XCTAssertTrue(powerManagement.isCoffeeModeEnabled)
        
        // 再次尝试启用
        let result = powerManagement.enableCoffeeMode()
        
        switch result {
        case .success:
            XCTAssertTrue(powerManagement.isCoffeeModeEnabled)
        case .failure(let error):
            XCTFail("Should succeed when enabling already enabled coffee mode: \(error)")
        }
    }
    
    func testDisableAlreadyDisabled() {
        // 确保咖啡模式是关闭的
        XCTAssertFalse(powerManagement.isCoffeeModeEnabled)
        
        // 尝试禁用已经关闭的咖啡模式
        let result = powerManagement.disableCoffeeMode()
        
        switch result {
        case .success:
            XCTAssertFalse(powerManagement.isCoffeeModeEnabled)
        case .failure(let error):
            XCTFail("Should succeed when disabling already disabled coffee mode: \(error)")
        }
    }
    
    func testCleanup() {
        // 启用咖啡模式
        _ = powerManagement.enableCoffeeMode()
        XCTAssertTrue(powerManagement.isCoffeeModeEnabled)
        
        // 调用清理
        powerManagement.cleanup()
        
        // 验证咖啡模式已被禁用
        XCTAssertFalse(powerManagement.isCoffeeModeEnabled)
    }
}
