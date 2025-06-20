import Foundation

/// 网络速度计算器
class NetworkSpeedCalculator {
    private var lastRx: UInt64 = 0
    private var lastTx: UInt64 = 0
    private var lastUpdateTime: Date?
    private let systemMonitor: SystemMonitorServiceProtocol
    
    init(systemMonitor: SystemMonitorServiceProtocol) {
        self.systemMonitor = systemMonitor
    }
    
    /// 计算网络速度
    func calculateSpeed() -> Result<NetworkStats, AppError> {
        let result = systemMonitor.getNetworkBytes()
        
        switch result {
        case .success(let (rx, tx)):
            let currentTime = Date()
            
            var downloadSpeed: Double?
            var uploadSpeed: Double?
            
            // 如果有历史数据，计算速度
            if let lastTime = lastUpdateTime,
               lastRx != 0 || lastTx != 0,
               rx >= lastRx && tx >= lastTx {
                
                let timeInterval = currentTime.timeIntervalSince(lastTime)
                
                if timeInterval > 0 {
                    downloadSpeed = Double(rx - lastRx) / timeInterval
                    uploadSpeed = Double(tx - lastTx) / timeInterval
                    
                    Logger.shared.debug("Speed calculated: down=\(downloadSpeed ?? 0), up=\(uploadSpeed ?? 0), interval=\(timeInterval)")
                }
            }
            
            // 更新历史数据
            lastRx = rx
            lastTx = tx
            lastUpdateTime = currentTime
            
            let networkStats = NetworkStats(
                receivedBytes: rx,
                transmittedBytes: tx,
                downloadSpeed: downloadSpeed,
                uploadSpeed: uploadSpeed
            )
            
            return .success(networkStats)
            
        case .failure(let error):
            Logger.shared.logError(error)
            return .failure(error)
        }
    }
    
    /// 重置计算器状态
    func reset() {
        lastRx = 0
        lastTx = 0
        lastUpdateTime = nil
        Logger.shared.info("Network speed calculator reset")
    }
}
