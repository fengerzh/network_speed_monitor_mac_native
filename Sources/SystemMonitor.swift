import Foundation
import SystemConfiguration
import IOKit.ps

/// 重构后的系统监控类，保持向后兼容
class SystemMonitor {
    /// 记录上一次全系统 CPU 各核的 tick 计数，用于计算 CPU 占用率的差分。
    @MainActor
    static var lastSystemCPUTicks: [UInt32] = []

    /// 内部使用的服务实例
    private static let service = SystemMonitorService.shared

    /// 获取全系统 CPU 使用率（百分比，带一位小数）。
    /// - 返回：当前全系统 CPU 使用率的字符串（如 "23.5"），若采样异常则返回 "--"。
    @MainActor
    static func getSystemCPUUsage() -> String {
        var kr: kern_return_t
        var count = UInt32(0)
        var cpuInfo: processor_info_array_t?
        var numCPU: natural_t = 0
        kr = host_processor_info(
            mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPU, &cpuInfo, &count)
        if kr != KERN_SUCCESS { return "--" }
        guard let cpuInfo = cpuInfo else { return "--" }
        let cpuCount = Int(numCPU)
        var ticks: [UInt32] = []
        for i in 0..<cpuCount {
            let user = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)])
            let system = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)])
            let nice = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)])
            let idle = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)])
            ticks.append(contentsOf: [user, system, nice, idle])
        }
        defer {
            vm_deallocate(
                mach_task_self_, vm_address_t(bitPattern: cpuInfo),
                vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.size))
        }
        if lastSystemCPUTicks.count == ticks.count {
            var totalDiff: UInt32 = 0
            var usedDiff: UInt32 = 0
            for i in 0..<cpuCount {
                let idx = i * 4
                let userDiff = ticks[idx] - lastSystemCPUTicks[idx]
                let systemDiff = ticks[idx + 1] - lastSystemCPUTicks[idx + 1]
                let niceDiff = ticks[idx + 2] - lastSystemCPUTicks[idx + 2]
                let idleDiff = ticks[idx + 3] - lastSystemCPUTicks[idx + 3]
                usedDiff += userDiff + systemDiff + niceDiff
                totalDiff += userDiff + systemDiff + niceDiff + idleDiff
            }
            lastSystemCPUTicks = ticks
            if totalDiff > 0 {
                let usage = Double(usedDiff) / Double(totalDiff) * 100.0
                return String(format: "%.1f", usage)
            } else {
                return "--"
            }
        } else {
            lastSystemCPUTicks = ticks
            return "--"
        }
    }

    /// 获取当前所有网络接口的累计收发字节数。
    /// - 返回：(rx, tx) 元组，分别为接收字节数和发送字节数（UInt64）。
    static func getNetworkBytes() -> (UInt64, UInt64) {
        let result = service.getNetworkBytes()
        switch result {
        case .success(let (rx, tx)):
            return (rx, tx)
        case .failure(let error):
            Logger.shared.logError(error)
            return (0, 0)
        }
    }

    /// 格式化速度数值为带单位的字符串（只保留G、M、K单位）。
    /// - 参数 speed: 速度（字节/秒，Double）。
    /// - 返回：格式化后的字符串（如 "1.23G"、"2.34M"、"512K"，无B/s）。
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

    /// 获取系统物理内存总量（字节）和当前已用物理内存（字节）。
    /// - 返回：(total, used) 元组，单位为字节（UInt64）。
    @MainActor
    static func getMemoryInfo() -> (UInt64, UInt64) {
        let result = service.getMemoryInfo()
        switch result {
        case .success(let (total, used)):
            return (total, used)
        case .failure(let error):
            Logger.shared.logError(error)
            return (0, 0)
        }
    }

    /// 获取当前电池电量百分比（如 87），若无电池则返回 "--"。
    static func getBatteryLevel() -> String {
        let result = service.getBatteryInfo()
        switch result {
        case .success(let batteryInfo):
            return batteryInfo.displayText
        case .failure(let error):
            Logger.shared.logError(error)
            return "--"
        }
    }
}
