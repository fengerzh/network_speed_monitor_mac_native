import Foundation
import SystemConfiguration

class SystemMonitor {
    @MainActor static var lastSystemCPUTicks: [UInt32] = []
    @MainActor static func getSystemCPUUsage() -> String {
        var kr: kern_return_t
        var count = UInt32(0)
        var cpuInfo: processor_info_array_t?
        var numCPU: natural_t = 0
        kr = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPU, &cpuInfo, &count)
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
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(count) * vm_size_t(MemoryLayout<integer_t>.size))
        }
        if lastSystemCPUTicks.count == ticks.count {
            var totalDiff: UInt32 = 0
            var usedDiff: UInt32 = 0
            for i in 0..<cpuCount {
                let idx = i * 4
                let userDiff = ticks[idx] - lastSystemCPUTicks[idx]
                let systemDiff = ticks[idx+1] - lastSystemCPUTicks[idx+1]
                let niceDiff = ticks[idx+2] - lastSystemCPUTicks[idx+2]
                let idleDiff = ticks[idx+3] - lastSystemCPUTicks[idx+3]
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

    static func formatSpeed(_ speed: Double) -> String {
        if speed < 1024 {
            return String(format: "%.0f B/s", speed)
        } else if speed < 1024*1024 {
            return String(format: "%.2f KB/s", speed/1024)
        } else {
            return String(format: "%.2f MB/s", speed/1024/1024)
        }
    }
} 