import Foundation

/// 网络监控服务协议
protocol NetworkMonitorServiceProtocol {
    func startMonitoring()
    func stopMonitoring()
    func checkAndSwitchNetwork()
    var isMonitoring: Bool { get }
}

/// 网络监控服务实现
class NetworkMonitorService: NetworkMonitorServiceProtocol {
    static let shared = NetworkMonitorService(preferencesManager: UserPreferencesManager())
    
    private let networkManager: NetworkInterfaceManagerProtocol
    private let preferencesManager: UserPreferencesManager
    private var monitoringTimer: Timer?
    private var _isMonitoring = false
    
    var isMonitoring: Bool {
        return _isMonitoring
    }
    
    private init(networkManager: NetworkInterfaceManagerProtocol = NetworkInterfaceManager.shared, preferencesManager: UserPreferencesManager) {
        self.networkManager = networkManager
        self.preferencesManager = preferencesManager
    }
    
    /// 开始网络监控
    func startMonitoring() {
        guard !_isMonitoring else {
            Logger.shared.warning("Network monitoring is already running")
            return
        }
        
        Logger.shared.info("Starting network monitoring")
        _isMonitoring = true
        
        // 使用用户偏好设置中的刷新间隔
        let interval = preferencesManager.preferences.updateInterval
        Logger.shared.info("Network monitoring interval set to: \(interval) seconds")
        
        // 立即执行一次网络检查
        Logger.shared.info("Executing initial network check...")
        DispatchQueue.global(qos: .background).async {
            Logger.shared.info("Initial network check started on background queue")
            self.checkAndSwitchNetwork()
        }
        
        // 在主线程上运行Timer，但使用后台队列执行网络检查
        Logger.shared.info("Creating Timer with interval: \(interval) seconds")
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            Logger.shared.info("Timer fired! Executing scheduled network check...")
            DispatchQueue.global(qos: .background).async {
                Logger.shared.info("Scheduled network check started on background queue")
                self?.checkAndSwitchNetwork()
            }
        }
        
        if let timer = monitoringTimer {
            Logger.shared.info("Timer created successfully: \(timer)")
        } else {
            Logger.shared.error("Failed to create Timer!")
        }
        
        Logger.shared.info("Network monitoring started successfully")
    }
    
    /// 停止网络监控
    func stopMonitoring() {
        guard _isMonitoring else {
            Logger.shared.warning("Network monitoring is not running")
            return
        }
        
        Logger.shared.info("Stopping network monitoring")
        _isMonitoring = false
        
        if let timer = monitoringTimer {
            Logger.shared.info("Invalidating timer: \(timer)")
            timer.invalidate()
        } else {
            Logger.shared.warning("No timer to invalidate")
        }
        
        monitoringTimer = nil
        Logger.shared.info("Network monitoring stopped successfully")
    }
    
    /// 检查网络状态并执行切换
    func checkAndSwitchNetwork() {
        Logger.shared.info("=== Starting network check and switch ===")
        
        // 获取网络接口信息
        Logger.shared.info("Getting active network interfaces...")
        let interfaces = networkManager.getActiveInterfaces()
        Logger.shared.info("Found \(interfaces.count) active interfaces")
        
        for interface in interfaces {
            Logger.shared.info("Interface: \(interface.name), Type: \(interface.type), Active: \(interface.isActive), IP: \(interface.ipAddress ?? "none")")
        }
        
        let hasEthernet = networkManager.hasActiveEthernetConnection()
        let hasWifi = networkManager.hasActiveWifiConnection()
        
        Logger.shared.info("Network status - Ethernet: \(hasEthernet), WiFi: \(hasWifi)")
        
        if hasEthernet {
            if let ethernetSubnet = networkManager.getEthernetSubnet() {
                Logger.shared.info("Ethernet subnet: \(ethernetSubnet)")
            } else {
                Logger.shared.warning("Ethernet connected but no subnet found")
            }
        }
        
        if hasWifi {
            if let wifiSubnet = networkManager.getWifiSubnet() {
                Logger.shared.info("WiFi subnet: \(wifiSubnet)")
            } else {
                Logger.shared.warning("WiFi connected but no subnet found")
            }
        }
        
        // 检查子网是否相同
        let sameSubnet = networkManager.areSubnetsSame()
        Logger.shared.info("Subnets are same: \(sameSubnet)")
        
        // 检查是否需要切换网络
        let shouldDisable = networkManager.shouldDisableWifi()
        Logger.shared.info("Should disable WiFi: \(shouldDisable)")
        
        if shouldDisable {
            Logger.shared.info("Detected Ethernet connection with same subnet as WiFi, attempting to disable WiFi")
            
            let result = networkManager.executeNetworkSwitch()
            switch result {
            case .success:
                Logger.shared.info("Successfully disabled WiFi due to active Ethernet connection")
            case .failure(let error):
                Logger.shared.error("Failed to disable WiFi: \(error.localizedDescription)")
            }
        } else if hasEthernet == false && hasWifi == false {
            // 如果都没有连接，尝试启用WiFi
            Logger.shared.info("No active connections detected, attempting to enable WiFi")
            
            let result = networkManager.executeNetworkSwitch()
            switch result {
            case .success:
                Logger.shared.info("Successfully enabled WiFi")
            case .failure(let error):
                Logger.shared.error("Failed to enable WiFi: \(error.localizedDescription)")
            }
        } else {
            Logger.shared.info("No network switch needed - current state is optimal")
        }
        
        Logger.shared.info("=== Network check and switch completed ===")
    }
    
    /// 获取当前网络状态信息（用于调试和显示）
    func getNetworkStatusInfo() -> String {
        _ = networkManager.getActiveInterfaces()
        let hasEthernet = networkManager.hasActiveEthernetConnection()
        let hasWifi = networkManager.hasActiveWifiConnection()
        let sameSubnet = networkManager.areSubnetsSame()
        
        var status = "网络状态:\n"
        status += "有线网络: \(hasEthernet ? "已连接" : "未连接")\n"
        status += "WiFi: \(hasWifi ? "已连接" : "未连接")\n"
        
        if hasEthernet && hasWifi {
            status += "子网一致: \(sameSubnet ? "是" : "否")\n"
            if sameSubnet {
                status += "建议: 关闭WiFi使用有线网络"
            } else {
                status += "建议: 保持当前状态"
            }
        } else if hasEthernet {
            status += "建议: 使用有线网络"
        } else if hasWifi {
            status += "建议: 使用WiFi"
        } else {
            status += "建议: 尝试连接网络"
        }
        
        return status
    }
} 