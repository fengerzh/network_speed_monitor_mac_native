import Foundation
import SystemConfiguration
import IOKit.ps

/// 系统监控服务协议
protocol SystemMonitorServiceProtocol {
    func getNetworkBytes() -> Result<(UInt64, UInt64), AppError>
    func getCPUUsage() -> Result<Double, AppError>
    func getMemoryInfo() -> Result<(UInt64, UInt64), AppError>
    func getBatteryInfo() -> Result<BatteryInfo, AppError>
}

/// 系统监控服务实现
class SystemMonitorService: SystemMonitorServiceProtocol {
    static let shared = SystemMonitorService()
    
    /// 记录上一次全系统 CPU 各核的 tick 计数，用于计算 CPU 占用率的差分
    private var lastSystemCPUTicks: [UInt32] = []
    
    private init() {}
    
    /// 获取当前所有网络接口的累计收发字节数
    func getNetworkBytes() -> Result<(UInt64, UInt64), AppError> {
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>? = nil
        var rx: UInt64 = 0
        var tx: UInt64 = 0
        
        guard getifaddrs(&ifaddrsPtr) == 0, let firstAddr = ifaddrsPtr else {
            Logger.shared.error("Failed to get network interfaces")
            return .failure(.networkError("无法获取网络接口信息"))
        }
        
        defer {
            freeifaddrs(ifaddrsPtr)
        }
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let currentPtr = ptr {
            let flags = Int32(currentPtr.pointee.ifa_flags)
            
            // 只统计活跃的网络接口，排除回环接口
            if (flags & IFF_UP) == IFF_UP && (flags & IFF_LOOPBACK) == 0,
               let data = currentPtr.pointee.ifa_data,
               let interfaceName = currentPtr.pointee.ifa_name {
                
                let name = String(cString: interfaceName)
                
                // 只统计真实的网络接口，排除虚拟接口
                if AppConfiguration.Monitoring.networkInterfacePrefixes.contains(where: { name.hasPrefix($0) }) {
                    let networkData = data.load(as: if_data.self)
                    rx += UInt64(networkData.ifi_ibytes)
                    tx += UInt64(networkData.ifi_obytes)
                    
                    Logger.shared.debug("Network interface \(name): rx=\(networkData.ifi_ibytes), tx=\(networkData.ifi_obytes)")
                }
            }
            ptr = currentPtr.pointee.ifa_next
        }
        
        Logger.shared.debug("Total network bytes: rx=\(rx), tx=\(tx)")
        return .success((rx, tx))
    }
    
    /// 获取全系统 CPU 使用率
    func getCPUUsage() -> Result<Double, AppError> {
        var kr: kern_return_t
        var count = UInt32(0)
        var cpuInfo: processor_info_array_t?
        var numCPU: natural_t = 0

        kr = host_processor_info(
            mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPU, &cpuInfo, &count)

        guard kr == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            Logger.shared.error("Failed to get CPU info: \(kr)")
            return .failure(.systemMonitorError("无法获取CPU信息"))
        }

        defer {
            vm_deallocate(
                mach_task_self_, vm_address_t(bitPattern: cpuInfo),
                vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        let cpuCount = Int(numCPU)
        var ticks: [UInt32] = []

        for i in 0..<cpuCount {
            let user = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_USER)])
            let system = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_SYSTEM)])
            let nice = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_NICE)])
            let idle = UInt32(cpuInfo[Int(CPU_STATE_MAX) * i + Int(CPU_STATE_IDLE)])
            ticks.append(contentsOf: [user, system, nice, idle])
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
                Logger.shared.debug("CPU usage: \(usage)%")
                return .success(usage)
            } else {
                return .failure(.systemMonitorError("CPU使用率计算异常"))
            }
        } else {
            lastSystemCPUTicks = ticks
            return .failure(.systemMonitorError("CPU数据初始化中"))
        }
    }

    /// 获取系统物理内存信息
    func getMemoryInfo() -> Result<(UInt64, UInt64), AppError> {
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

        guard result == KERN_SUCCESS else {
            Logger.shared.error("Failed to get memory info: \(result)")
            return .failure(.systemMonitorError("无法获取内存信息"))
        }

        let pageSize = UInt64(NSPageSize())
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed

        Logger.shared.debug("Memory info: total=\(total), used=\(used)")
        return .success((total, used))
    }

    /// 获取电池信息
    func getBatteryInfo() -> Result<BatteryInfo, AppError> {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            Logger.shared.debug("No battery found")
            return .success(BatteryInfo(percentage: nil, isCharging: false, isPresent: false))
        }

        for ps in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] {
                if let capacity = info[kIOPSCurrentCapacityKey as String] as? Int,
                   let max = info[kIOPSMaxCapacityKey as String] as? Int,
                   max > 0 {

                    let percentage = Int(Double(capacity) / Double(max) * 100)
                    let isCharging = (info[kIOPSPowerSourceStateKey as String] as? String) == kIOPSACPowerValue

                    Logger.shared.debug("Battery: \(percentage)%, charging: \(isCharging)")
                    return .success(BatteryInfo(percentage: percentage, isCharging: isCharging, isPresent: true))
                }
            }
        }

        Logger.shared.debug("No valid battery info found")
        return .success(BatteryInfo(percentage: nil, isCharging: false, isPresent: false))
    }
}
