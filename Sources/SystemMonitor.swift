import Foundation
import SystemConfiguration

class SystemMonitor {
    /// 记录上一次全系统 CPU 各核的 tick 计数，用于计算 CPU 占用率的差分。
    @MainActor
    static var lastSystemCPUTicks: [UInt32] = []

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
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>? = nil
        var rx: UInt64 = 0
        var tx: UInt64 = 0
        if getifaddrs(&ifaddrsPtr) == 0, let firstAddr = ifaddrsPtr {
            var ptr = firstAddr
            while ptr.pointee.ifa_next != nil {
                let flags = Int32(ptr.pointee.ifa_flags)
                if (flags & IFF_UP) == IFF_UP, let data = ptr.pointee.ifa_data {
                    let networkData = data.load(as: if_data.self)
                    rx += UInt64(networkData.ifi_ibytes)
                    tx += UInt64(networkData.ifi_obytes)
                }
                if let next = ptr.pointee.ifa_next { ptr = next } else { break }
            }
            freeifaddrs(ifaddrsPtr)
        }
        return (rx, tx)
    }

    /// 格式化速度数值为带单位的字符串（B/s、KB/s、MB/s）。
    /// - 参数 speed: 速度（字节/秒，Double）。
    /// - 返回：格式化后的字符串（如 "123 B/s"、"1.23 KB/s"、"2.34 MB/s"）。
    static func formatSpeed(_ speed: Double) -> String {
        if speed < 1024 {
            return String(format: "%.0f B/s", speed)
        } else if speed < 1024 * 1024 {
            return String(format: "%.2f KB/s", speed / 1024)
        } else {
            return String(format: "%.2f MB/s", speed / 1024 / 1024)
        }
    }

    /// 获取系统物理内存总量（字节）和当前已用物理内存（字节）。
    /// - 返回：(total, used) 元组，单位为字节（UInt64）。会在控制台打印详细信息用于调试。
    @MainActor
    static func getMemoryInfo() -> (UInt64, UInt64) {
        // 获取总物理内存
        let total = ProcessInfo.processInfo.physicalMemory
        // 获取当前已用物理内存
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let hostPort: mach_port_t = mach_host_self()
        let result = withUnsafeMutablePointer(to: &stats) { statsPtr -> kern_return_t in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(hostPort, HOST_VM_INFO64, intPtr, &count)
            }
        }
        var used: UInt64 = 0
        if result == KERN_SUCCESS {
            let pageSize = UInt64(NSPageSize())
            let active = UInt64(stats.active_count) * pageSize
            let wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            used = active + wired + compressed
        }
        return (total, used)
    }
}
