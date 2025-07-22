import Foundation
import SystemConfiguration
import CoreWLAN

/// 网络接口信息
struct NetworkInterfaceInfo {
    let name: String
    let type: InterfaceType
    let isActive: Bool
    let ipAddress: String?
    let subnetMask: String?
    
    enum InterfaceType {
        case ethernet
        case wifi
        case other
        
        static func fromInterfaceName(_ name: String) -> InterfaceType {
            if name.hasPrefix("en") {
                return .ethernet
            } else if name.hasPrefix("wi") || name.hasPrefix("wlan") {
                return .wifi
            } else {
                return .other
            }
        }
    }
}

/// 网络接口管理服务协议
protocol NetworkInterfaceManagerProtocol {
    func getActiveInterfaces() -> [NetworkInterfaceInfo]
    func hasActiveEthernetConnection() -> Bool
    func hasActiveWifiConnection() -> Bool
    func getEthernetSubnet() -> String?
    func getWifiSubnet() -> String?
    func areSubnetsSame() -> Bool
    func shouldDisableWifi() -> Bool
    func executeNetworkSwitch() -> Result<Void, AppError>
}

/// 网络接口管理服务实现
class NetworkInterfaceManager: NetworkInterfaceManagerProtocol {
    static let shared = NetworkInterfaceManager()
    
    private init() {}
    
    /// 获取所有活跃的网络接口信息
    func getActiveInterfaces() -> [NetworkInterfaceInfo] {
        var interfaces: [NetworkInterfaceInfo] = []
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>? = nil
        
        // 首先获取WiFi接口信息
        let wifiInterface = getWifiInterfaceName()
        
        guard getifaddrs(&ifaddrsPtr) == 0, let firstAddr = ifaddrsPtr else {
            Logger.shared.error("Failed to get network interfaces")
            return []
        }
        
        defer {
            freeifaddrs(ifaddrsPtr)
        }
        
        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let currentPtr = ptr {
            let flags = Int32(currentPtr.pointee.ifa_flags)
            
            // 只统计活跃的网络接口，排除回环接口
            if (flags & IFF_UP) == IFF_UP && (flags & IFF_LOOPBACK) == 0,
               let interfaceName = currentPtr.pointee.ifa_name {
                
                let name = String(cString: interfaceName)
                let type = getInterfaceType(name: name, wifiInterface: wifiInterface)
                
                // 只关注有线网络和WiFi接口
                if type == .ethernet || type == .wifi {
                    let ipAddress = getIPAddress(from: currentPtr)
                    let subnetMask = getSubnetMask(from: currentPtr)
                    
                    // 只处理IPv4地址，过滤掉MAC地址和IPv6地址
                    if let ip = ipAddress, isValidIPv4Address(ip) {
                        let interfaceInfo = NetworkInterfaceInfo(
                            name: name,
                            type: type,
                            isActive: true,
                            ipAddress: ip,
                            subnetMask: subnetMask
                        )
                        
                        interfaces.append(interfaceInfo)
                        Logger.shared.debug("Found interface: \(name), type: \(type), active: true, IP: \(ip)")
                    }
                }
            }
            ptr = currentPtr.pointee.ifa_next
        }
        
        return interfaces
    }
    
    /// 检查是否有活跃的有线网络连接
    func hasActiveEthernetConnection() -> Bool {
        let interfaces = getActiveInterfaces()
        return interfaces.contains { $0.type == .ethernet && $0.isActive }
    }
    
    /// 检查是否有活跃的WiFi连接
    func hasActiveWifiConnection() -> Bool {
        let interfaces = getActiveInterfaces()
        return interfaces.contains { $0.type == .wifi && $0.isActive }
    }
    
    /// 获取有线网络的子网地址
    func getEthernetSubnet() -> String? {
        let interfaces = getActiveInterfaces()
        guard let ethernet = interfaces.first(where: { $0.type == .ethernet && $0.isActive }) else {
            Logger.shared.debug("No active ethernet interface found")
            return nil
        }
        
        guard let ip = ethernet.ipAddress else {
            Logger.shared.debug("No IP address found for ethernet interface: \(ethernet.name)")
            return nil
        }
        
        guard let mask = ethernet.subnetMask else {
            Logger.shared.debug("No subnet mask found for ethernet interface: \(ethernet.name), IP: \(ip)")
            return nil
        }
        
        Logger.shared.debug("Calculating ethernet subnet for IP: \(ip), mask: \(mask)")
        let subnet = calculateSubnet(ip: ip, mask: mask)
        Logger.shared.debug("Ethernet subnet result: \(subnet ?? "nil")")
        return subnet
    }
    
    /// 获取WiFi的子网地址
    func getWifiSubnet() -> String? {
        let interfaces = getActiveInterfaces()
        guard let wifi = interfaces.first(where: { $0.type == .wifi && $0.isActive }) else {
            Logger.shared.debug("No active WiFi interface found")
            return nil
        }
        
        guard let ip = wifi.ipAddress else {
            Logger.shared.debug("No IP address found for WiFi interface: \(wifi.name)")
            return nil
        }
        
        guard let mask = wifi.subnetMask else {
            Logger.shared.debug("No subnet mask found for WiFi interface: \(wifi.name), IP: \(ip)")
            return nil
        }
        
        Logger.shared.debug("Calculating WiFi subnet for IP: \(ip), mask: \(mask)")
        let subnet = calculateSubnet(ip: ip, mask: mask)
        Logger.shared.debug("WiFi subnet result: \(subnet ?? "nil")")
        return subnet
    }
    
    /// 检查有线网络和WiFi是否在同一子网
    func areSubnetsSame() -> Bool {
        guard let ethernetSubnet = getEthernetSubnet(),
              let wifiSubnet = getWifiSubnet() else {
            return false
        }
        return ethernetSubnet == wifiSubnet
    }
    
    /// 判断是否应该关闭WiFi
    func shouldDisableWifi() -> Bool {
        // 如果有有线网络连接，且有线网络和WiFi在同一子网，则关闭WiFi
        return hasActiveEthernetConnection() && areSubnetsSame()
    }
    
    /// 执行网络切换操作
    func executeNetworkSwitch() -> Result<Void, AppError> {
        if shouldDisableWifi() {
            return disableWifi()
        } else {
            return enableWifi()
        }
    }
    
    // MARK: - Private Methods
    
    /// 获取WiFi接口名称
    private func getWifiInterfaceName() -> String? {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listallhardwareports"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                
                for (index, line) in lines.enumerated() {
                    if line.contains("Wi-Fi") || line.contains("AirPort") {
                        // 查找下一行的设备名称
                        if index + 1 < lines.count {
                            let deviceLine = lines[index + 1]
                            if deviceLine.contains("Device:") {
                                let components = deviceLine.components(separatedBy: ":")
                                if components.count >= 2 {
                                    return components[1].trimmingCharacters(in: .whitespaces)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Logger.shared.error("Failed to get WiFi interface name: \(error)")
        }
        
        return nil
    }
    
    /// 获取接口类型，考虑WiFi接口的实际名称
    private func getInterfaceType(name: String, wifiInterface: String?) -> NetworkInterfaceInfo.InterfaceType {
        // 如果这个接口是WiFi接口，返回wifi类型
        if let wifiInterface = wifiInterface, name == wifiInterface {
            return .wifi
        }
        
        // 否则使用传统的命名规则
        return NetworkInterfaceInfo.InterfaceType.fromInterfaceName(name)
    }
    
    /// 从网络接口获取IP地址
    private func getIPAddress(from ifaddr: UnsafeMutablePointer<ifaddrs>) -> String? {
        let addr = ifaddr.pointee.ifa_addr
        guard let addr = addr else { return nil }
        
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(
            addr,
            socklen_t(addr.pointee.sa_len),
            &hostname,
            socklen_t(hostname.count),
            nil,
            0,
            NI_NUMERICHOST
        )
        
        if result == 0 {
            return String(cString: hostname)
        }
        return nil
    }
    
    /// 从网络接口获取子网掩码
    private func getSubnetMask(from ifaddr: UnsafeMutablePointer<ifaddrs>) -> String? {
        let netmask = ifaddr.pointee.ifa_netmask
        guard let netmask = netmask else { 
            Logger.shared.debug("No netmask found for interface")
            return nil 
        }
        
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result = getnameinfo(
            netmask,
            socklen_t(netmask.pointee.sa_len),
            &hostname,
            socklen_t(hostname.count),
            nil,
            0,
            NI_NUMERICHOST
        )
        
        if result == 0 {
            let mask = String(cString: hostname)
            Logger.shared.debug("Found subnet mask: \(mask)")
            return mask
        } else {
            Logger.shared.debug("Failed to get subnet mask, error: \(result)")
            return nil
        }
    }
    
    /// 计算子网地址
    internal func calculateSubnet(ip: String, mask: String) -> String? {
        guard let ipComponents = parseIPAddress(ip),
              let maskComponents = parseIPAddress(mask) else {
            return nil
        }
        
        var subnetComponents: [UInt8] = []
        for i in 0..<4 {
            subnetComponents.append(ipComponents[i] & maskComponents[i])
        }
        
        return subnetComponents.map(String.init).joined(separator: ".")
    }
    
    /// 解析IP地址字符串为字节数组
    internal func parseIPAddress(_ ipString: String) -> [UInt8]? {
        let components = ipString.split(separator: ".")
        guard components.count == 4 else { return nil }
        
        var bytes: [UInt8] = []
        for component in components {
            guard let byte = UInt8(component) else { return nil }
            bytes.append(byte)
        }
        return bytes
    }
    
    /// 验证是否为有效的IPv4地址
    private func isValidIPv4Address(_ ipString: String) -> Bool {
        let components = ipString.split(separator: ".")
        guard components.count == 4 else { return false }
        
        for component in components {
            guard let byte = UInt8(component) else { return false }
            // 检查是否为有效的字节值 (0-255)
            if byte < 0 || byte > 255 { return false }
        }
        return true
    }
    
    /// 关闭WiFi（使用CoreWLAN Framework）
    private func disableWifi() -> Result<Void, AppError> {
        Logger.shared.info("Attempting to disable WiFi using CoreWLAN")
        
        do {
            // 获取WiFi客户端
            let wifiClient = CWWiFiClient.shared()
            
            // 获取WiFi接口
            guard let interface = wifiClient.interface() else {
                Logger.shared.error("No WiFi interface found")
                return .failure(.networkError("未找到WiFi接口"))
            }
            
            // 关闭WiFi电源
            try interface.setPower(false)
            
            Logger.shared.info("WiFi disabled successfully using CoreWLAN")
            return .success(())
            
        } catch {
            Logger.shared.error("Error disabling WiFi with CoreWLAN: \(error)")
            
            // 如果CoreWLAN失败，回退到sudo方式
            Logger.shared.info("Falling back to sudo method")
            return disableWifiWithSudo()
        }
    }
    
    /// 使用sudo方式关闭WiFi（备用方案）
    private func disableWifiWithSudo() -> Result<Void, AppError> {
        Logger.shared.info("Attempting to disable WiFi with sudo")
        
        let task = Process()
        task.launchPath = "/usr/bin/sudo"
        task.arguments = ["/usr/sbin/networksetup", "-setairportpower", "en0", "off"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                Logger.shared.info("WiFi disabled successfully with sudo")
                return .success(())
            } else {
                Logger.shared.error("Failed to disable WiFi: exit code \(task.terminationStatus)")
                return .failure(.networkError("关闭WiFi失败，可能需要管理员权限"))
            }
        } catch {
            Logger.shared.error("Error disabling WiFi: \(error)")
            return .failure(.networkError("关闭WiFi时发生错误: \(error.localizedDescription)"))
        }
    }
    
    /// 启用WiFi（使用CoreWLAN Framework）
    private func enableWifi() -> Result<Void, AppError> {
        Logger.shared.info("Attempting to enable WiFi using CoreWLAN")
        
        do {
            // 获取WiFi客户端
            let wifiClient = CWWiFiClient.shared()
            
            // 获取WiFi接口
            guard let interface = wifiClient.interface() else {
                Logger.shared.error("No WiFi interface found")
                return .failure(.networkError("未找到WiFi接口"))
            }
            
            // 启用WiFi电源
            try interface.setPower(true)
            
            Logger.shared.info("WiFi enabled successfully using CoreWLAN")
            return .success(())
            
        } catch {
            Logger.shared.error("Error enabling WiFi with CoreWLAN: \(error)")
            
            // 如果CoreWLAN失败，回退到sudo方式
            Logger.shared.info("Falling back to sudo method")
            return enableWifiWithSudo()
        }
    }
    
    /// 使用sudo方式启用WiFi（备用方案）
    private func enableWifiWithSudo() -> Result<Void, AppError> {
        Logger.shared.info("Attempting to enable WiFi with sudo")
        
        let task = Process()
        task.launchPath = "/usr/bin/sudo"
        task.arguments = ["/usr/sbin/networksetup", "-setairportpower", "en0", "on"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                Logger.shared.info("WiFi enabled successfully with sudo")
                return .success(())
            } else {
                Logger.shared.error("Failed to enable WiFi: exit code \(task.terminationStatus)")
                return .failure(.networkError("启用WiFi失败，可能需要管理员权限"))
            }
        } catch {
            Logger.shared.error("Error enabling WiFi: \(error)")
            return .failure(.networkError("启用WiFi时发生错误: \(error.localizedDescription)"))
        }
    }
} 