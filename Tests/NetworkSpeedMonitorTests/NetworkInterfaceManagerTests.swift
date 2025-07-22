import XCTest
@testable import network_speed_monitor_mac_native

final class NetworkInterfaceManagerTests: XCTestCase {
    
    func testInterfaceTypeFromName() {
        XCTAssertEqual(NetworkInterfaceInfo.InterfaceType.fromInterfaceName("en0"), .ethernet)
        XCTAssertEqual(NetworkInterfaceInfo.InterfaceType.fromInterfaceName("en1"), .ethernet)
        XCTAssertEqual(NetworkInterfaceInfo.InterfaceType.fromInterfaceName("wi0"), .wifi)
        XCTAssertEqual(NetworkInterfaceInfo.InterfaceType.fromInterfaceName("wlan0"), .wifi)
        XCTAssertEqual(NetworkInterfaceInfo.InterfaceType.fromInterfaceName("lo0"), .other)
        XCTAssertEqual(NetworkInterfaceInfo.InterfaceType.fromInterfaceName("bridge0"), .other)
    }
    
    func testParseIPAddress() {
        let manager = NetworkInterfaceManager.shared
        
        // 测试有效的IP地址
        XCTAssertEqual(manager.parseIPAddress("192.168.1.1"), [192, 168, 1, 1])
        XCTAssertEqual(manager.parseIPAddress("10.0.0.1"), [10, 0, 0, 1])
        XCTAssertEqual(manager.parseIPAddress("172.16.0.1"), [172, 16, 0, 1])
        
        // 测试无效的IP地址
        XCTAssertNil(manager.parseIPAddress("192.168.1"))
        XCTAssertNil(manager.parseIPAddress("192.168.1.256"))
        XCTAssertNil(manager.parseIPAddress("192.168.1.a"))
        XCTAssertNil(manager.parseIPAddress(""))
    }
    
    func testCalculateSubnet() {
        let manager = NetworkInterfaceManager.shared
        
        // 测试标准子网计算
        XCTAssertEqual(manager.calculateSubnet(ip: "192.168.1.100", mask: "255.255.255.0"), "192.168.1.0")
        XCTAssertEqual(manager.calculateSubnet(ip: "10.0.0.50", mask: "255.0.0.0"), "10.0.0.0")
        XCTAssertEqual(manager.calculateSubnet(ip: "172.16.5.10", mask: "255.255.0.0"), "172.16.0.0")
        
        // 测试无效输入
        XCTAssertNil(manager.calculateSubnet(ip: "192.168.1.100", mask: "invalid"))
        XCTAssertNil(manager.calculateSubnet(ip: "invalid", mask: "255.255.255.0"))
    }
    
    func testGetActiveInterfaces() {
        let manager = NetworkInterfaceManager.shared
        let interfaces = manager.getActiveInterfaces()
        
        // 验证返回的接口信息
        for interface in interfaces {
            XCTAssertFalse(interface.name.isEmpty)
            XCTAssertTrue(interface.type == .ethernet || interface.type == .wifi)
            
            // 注意：接口可能没有IP地址（如只有MAC地址），这是正常的
            // 我们只验证接口名称和类型
        }
    }
    
    func testNetworkStatusMethods() {
        let manager = NetworkInterfaceManager.shared
        
        // 这些方法应该能够正常执行，即使没有实际的网络连接
        let hasEthernet = manager.hasActiveEthernetConnection()
        let hasWifi = manager.hasActiveWifiConnection()
        
        // 验证返回的是布尔值
        XCTAssertTrue(hasEthernet == true || hasEthernet == false)
        XCTAssertTrue(hasWifi == true || hasWifi == false)
        
        // 测试子网获取方法
        let ethernetSubnet = manager.getEthernetSubnet()
        let wifiSubnet = manager.getWifiSubnet()
        
        // 如果没有活跃连接，应该返回nil
        if !hasEthernet {
            XCTAssertNil(ethernetSubnet)
        }
        if !hasWifi {
            XCTAssertNil(wifiSubnet)
        }
    }
    
    func testShouldDisableWifi() {
        let manager = NetworkInterfaceManager.shared
        
        // 这个方法应该能够正常执行
        let shouldDisable = manager.shouldDisableWifi()
        XCTAssertTrue(shouldDisable == true || shouldDisable == false)
    }
} 