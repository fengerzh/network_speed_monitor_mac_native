// swift-tools-version: 5.10.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "network_speed_monitor_mac_native",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "network_speed_monitor_mac_native",
            dependencies: [
                .product(name: "HotKey", package: "HotKey")
            ],
            exclude: [
                "Info.plist"
            ],
            resources: [
                .process("Resources/netspeed.icns"),
                .process("Resources/netspeed_menu.png")
            ]
        ),
        .testTarget(
            name: "NetworkSpeedMonitorTests",
            dependencies: ["network_speed_monitor_mac_native"]
        ),
    ]
)
