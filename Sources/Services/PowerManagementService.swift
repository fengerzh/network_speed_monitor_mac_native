import Foundation
import IOKit.pwr_mgt

/// 电源管理服务协议
protocol PowerManagementServiceProtocol {
    var isCoffeeModeEnabled: Bool { get }
    func enableCoffeeMode() -> Result<Void, AppError>
    func disableCoffeeMode() -> Result<Void, AppError>
    func toggleCoffeeMode() -> Result<Bool, AppError>
    func cleanup()
}

/// 电源管理服务实现
class PowerManagementService: PowerManagementServiceProtocol {
    static let shared = PowerManagementService()
    
    private var coffeeAssertionID: IOPMAssertionID = 0
    private var coffeeDisplayAssertionID: IOPMAssertionID = 0
    private var _isCoffeeModeEnabled = false
    
    var isCoffeeModeEnabled: Bool {
        return _isCoffeeModeEnabled
    }
    
    private init() {}
    
    /// 启用咖啡模式（防止系统睡眠）
    func enableCoffeeMode() -> Result<Void, AppError> {
        guard !_isCoffeeModeEnabled else {
            Logger.shared.warning("Coffee mode is already enabled")
            return .success(())
        }
        
        let reasonForActivity = "保持清醒，防止电脑睡眠和屏保" as CFString
        
        // 防止系统睡眠
        let result1 = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &coffeeAssertionID
        )
        
        // 防止显示器睡眠
        let result2 = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reasonForActivity,
            &coffeeDisplayAssertionID
        )
        
        if result1 == kIOReturnSuccess && result2 == kIOReturnSuccess {
            _isCoffeeModeEnabled = true
            Logger.shared.info("Coffee mode enabled successfully")
            return .success(())
        } else {
            Logger.shared.error("Failed to enable coffee mode: system=\(result1), display=\(result2)")
            
            // 清理可能成功的断言
            if result1 == kIOReturnSuccess {
                IOPMAssertionRelease(coffeeAssertionID)
            }
            if result2 == kIOReturnSuccess {
                IOPMAssertionRelease(coffeeDisplayAssertionID)
            }
            
            return .failure(.powerManagementError("无法启用咖啡模式"))
        }
    }
    
    /// 禁用咖啡模式（允许系统睡眠）
    func disableCoffeeMode() -> Result<Void, AppError> {
        guard _isCoffeeModeEnabled else {
            Logger.shared.warning("Coffee mode is already disabled")
            return .success(())
        }
        
        let result1 = IOPMAssertionRelease(coffeeAssertionID)
        let result2 = IOPMAssertionRelease(coffeeDisplayAssertionID)
        
        _isCoffeeModeEnabled = false
        coffeeAssertionID = 0
        coffeeDisplayAssertionID = 0
        
        if result1 == kIOReturnSuccess && result2 == kIOReturnSuccess {
            Logger.shared.info("Coffee mode disabled successfully")
            return .success(())
        } else {
            Logger.shared.warning("Coffee mode disabled with warnings: system=\(result1), display=\(result2)")
            return .success(()) // 即使释放失败，也认为是成功的，因为状态已经重置
        }
    }
    
    /// 切换咖啡模式状态
    func toggleCoffeeMode() -> Result<Bool, AppError> {
        if _isCoffeeModeEnabled {
            let result = disableCoffeeMode()
            return result.isSuccess ? .success(false) : .failure(result.error!)
        } else {
            let result = enableCoffeeMode()
            return result.isSuccess ? .success(true) : .failure(result.error!)
        }
    }
    
    /// 清理资源（应用退出时调用）
    func cleanup() {
        if _isCoffeeModeEnabled {
            _ = disableCoffeeMode()
        }
    }
}
