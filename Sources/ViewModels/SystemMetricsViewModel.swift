import Foundation
import Combine

/// 系统指标视图模型
@MainActor
class SystemMetricsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var timeString: String = "--:--"
    @Published var downloadSpeed: String = "--"
    @Published var uploadSpeed: String = "--"
    @Published var cpuUsage: String = "--"
    @Published var memoryUsage: String = "--"
    @Published var batteryLevel: String = "--"
    @Published var showCoffee: Bool = false
    @Published var isUpdating: Bool = false
    @Published var lastError: AppError?
    
    // MARK: - Private Properties
    private let systemMonitor: SystemMonitorServiceProtocol
    private let powerManagement: PowerManagementServiceProtocol
    private let networkCalculator: NetworkSpeedCalculator
    private var updateTimer: Timer?
    private let dateFormatter: DateFormatter
    
    // MARK: - Initialization
    init(systemMonitor: SystemMonitorServiceProtocol? = nil,
         powerManagement: PowerManagementServiceProtocol? = nil) {
        self.systemMonitor = systemMonitor ?? SystemMonitorService.shared
        self.powerManagement = powerManagement ?? PowerManagementService.shared
        self.networkCalculator = NetworkSpeedCalculator(systemMonitor: self.systemMonitor)
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "HH:mm"
        
        self.showCoffee = self.powerManagement.isCoffeeModeEnabled
        
        Logger.shared.info("SystemMetricsViewModel initialized")
    }
    
    // MARK: - Public Methods
    
    /// 开始定时更新
    func startUpdating() {
        guard updateTimer == nil else {
            Logger.shared.warning("Update timer is already running")
            return
        }
        
        Logger.shared.info("Starting metrics update timer")
        updateTimer = Timer.scheduledTimer(withTimeInterval: AppConfiguration.Monitoring.updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateMetrics()
            }
        }
        
        // 立即更新一次
        Task {
            await updateMetrics()
        }
    }
    
    /// 停止定时更新
    func stopUpdating() {
        Logger.shared.info("Stopping metrics update timer")
        updateTimer?.invalidate()
        updateTimer = nil
        isUpdating = false
    }
    
    /// 切换咖啡模式
    func toggleCoffeeMode() {
        let result = powerManagement.toggleCoffeeMode()
        
        switch result {
        case .success(let enabled):
            showCoffee = enabled
            Logger.shared.info("Coffee mode toggled: \(enabled)")
            
        case .failure(let error):
            lastError = error
            Logger.shared.logError(error)
        }
    }
    
    /// 重置网络速度计算器
    func resetNetworkCalculator() {
        networkCalculator.reset()
        downloadSpeed = "--"
        uploadSpeed = "--"
    }
    
    // MARK: - Private Methods
    
    /// 更新所有指标
    private func updateMetrics() async {
        isUpdating = true
        lastError = nil
        
        // 更新时间
        updateTime()
        
        // 更新网络速度
        await updateNetworkSpeed()
        
        // 更新CPU使用率
        await updateCPUUsage()
        
        // 更新内存信息
        await updateMemoryInfo()
        
        // 更新电池信息
        await updateBatteryInfo()
        
        // 更新咖啡模式状态
        updateCoffeeModeStatus()
        
        isUpdating = false
    }
    
    /// 更新时间显示
    private func updateTime() {
        timeString = dateFormatter.string(from: Date())
    }
    
    /// 更新网络速度
    private func updateNetworkSpeed() async {
        let result = networkCalculator.calculateSpeed()
        
        switch result {
        case .success(let networkStats):
            downloadSpeed = networkStats.formattedDownloadSpeed
            uploadSpeed = networkStats.formattedUploadSpeed
            
        case .failure(let error):
            downloadSpeed = "--"
            uploadSpeed = "--"
            lastError = error
        }
    }
    
    /// 更新CPU使用率
    private func updateCPUUsage() async {
        let result = systemMonitor.getCPUUsage()
        
        switch result {
        case .success(let usage):
            cpuUsage = String(format: "%.1f", usage)
            
        case .failure(let error):
            cpuUsage = "--"
            if case .systemMonitorError(let message) = error,
               !message.contains("初始化中") {
                lastError = error
            }
        }
    }
    
    /// 更新内存信息
    private func updateMemoryInfo() async {
        let result = systemMonitor.getMemoryInfo()
        
        switch result {
        case .success(let (_, used)):
            let memoryInfo = MemoryInfo(totalBytes: 0, usedBytes: used)
            memoryUsage = memoryInfo.formattedUsedMemory
            
        case .failure(let error):
            memoryUsage = "--"
            lastError = error
        }
    }
    
    /// 更新电池信息
    private func updateBatteryInfo() async {
        let result = systemMonitor.getBatteryInfo()
        
        switch result {
        case .success(let batteryInfo):
            batteryLevel = batteryInfo.displayText
            
        case .failure(let error):
            batteryLevel = "--"
            lastError = error
        }
    }
    
    /// 更新咖啡模式状态
    private func updateCoffeeModeStatus() {
        showCoffee = powerManagement.isCoffeeModeEnabled
    }
    
    // MARK: - Cleanup
    deinit {
        updateTimer?.invalidate()
        updateTimer = nil
        Logger.shared.info("SystemMetricsViewModel deinitialized")
    }
}
