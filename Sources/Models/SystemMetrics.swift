import Foundation

/// 系统指标数据模型
struct SystemMetrics {
    let timestamp: Date
    let networkStats: NetworkStats
    let cpuUsage: CPUUsage
    let memoryInfo: MemoryInfo
    let batteryInfo: BatteryInfo
    
    init(networkStats: NetworkStats, cpuUsage: CPUUsage, memoryInfo: MemoryInfo, batteryInfo: BatteryInfo) {
        self.timestamp = Date()
        self.networkStats = networkStats
        self.cpuUsage = cpuUsage
        self.memoryInfo = memoryInfo
        self.batteryInfo = batteryInfo
    }
}

/// 网络统计信息
struct NetworkStats {
    let receivedBytes: UInt64
    let transmittedBytes: UInt64
    let downloadSpeed: Double?
    let uploadSpeed: Double?
    
    var isValid: Bool {
        return downloadSpeed != nil && uploadSpeed != nil
    }
    
    var formattedDownloadSpeed: String {
        guard let speed = downloadSpeed else { return "--" }
        return SystemMetricsFormatter.formatSpeed(speed)
    }
    
    var formattedUploadSpeed: String {
        guard let speed = uploadSpeed else { return "--" }
        return SystemMetricsFormatter.formatSpeed(speed)
    }
}

/// CPU使用率信息
struct CPUUsage {
    let percentage: Double?
    
    var isValid: Bool {
        return percentage != nil
    }
    
    var formattedPercentage: String {
        guard let percentage = percentage else { return "--" }
        return String(format: "%.1f", percentage)
    }
}

/// 内存信息
struct MemoryInfo {
    let totalBytes: UInt64
    let usedBytes: UInt64
    
    var usagePercentage: Double {
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
    
    var formattedUsedMemory: String {
        let gb = 1024.0 * 1024.0 * 1024.0
        let usedGB = Double(usedBytes) / gb
        return String(format: "%.2f GB", usedGB)
    }
}

/// 电池信息
struct BatteryInfo {
    let percentage: Int?
    let isCharging: Bool
    let isPresent: Bool
    
    var formattedPercentage: String {
        guard let percentage = percentage else { return "--" }
        return String(percentage)
    }
    
    var displayText: String {
        guard isPresent else { return "--" }
        let baseText = formattedPercentage
        return isCharging ? "\(baseText)⚡" : baseText
    }
}

/// 系统指标格式化工具
struct SystemMetricsFormatter {
    /// 格式化速度数值为带单位的字符串（只保留G、M、K单位）
    static func formatSpeed(_ speed: Double) -> String {
        if speed >= 1024 * 1024 * 1024 {
            return String(format: "%.2fG", speed / 1024 / 1024 / 1024)
        } else if speed >= 1024 * 1024 {
            return String(format: "%.2fM", speed / 1024 / 1024)
        } else if speed >= 1024 {
            return String(format: "%.0fK", speed / 1024)
        } else {
            return "0"
        }
    }
    
    /// 格式化内存大小
    static func formatMemory(_ bytes: UInt64) -> String {
        let gb = 1024.0 * 1024.0 * 1024.0
        let mb = 1024.0 * 1024.0
        let kb = 1024.0
        
        let value = Double(bytes)
        
        if value >= gb {
            return String(format: "%.2f GB", value / gb)
        } else if value >= mb {
            return String(format: "%.1f MB", value / mb)
        } else if value >= kb {
            return String(format: "%.0f KB", value / kb)
        } else {
            return "\(bytes) B"
        }
    }
}
