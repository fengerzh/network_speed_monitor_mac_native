import Foundation

/// 应用配置管理
struct AppConfiguration {
    // MARK: - App Info
    static let appName = "NetworkSpeedMonitor"
    static let appVersion = "1.1.0"
    
    // MARK: - UI Configuration
    struct UI {
        static let windowWidth: CGFloat = 180
        static let windowHeight: CGFloat = 140
        static let windowMargin: CGFloat = 10
        static let cornerRadius: CGFloat = 12
        static let backgroundAlpha: CGFloat = 0.5
        static let lineSpacing: CGFloat = 28
        static let spacing: CGFloat = 8
    }
    
    // MARK: - Monitoring Configuration
    struct Monitoring {
        static let updateInterval: TimeInterval = 3.0
        static let networkInterfacePrefixes = ["en", "wi", "eth"]
    }
    
    // MARK: - HotKeys Configuration
    struct HotKeys {
        static let toggleVisibility = (key: "t", modifiers: ["control", "option", "command"])
        static let toggleCoffeeMode = (key: "k", modifiers: ["control", "option", "command"])
    }
    
    // MARK: - Colors
    struct Colors {
        static let background = (white: 0.08, alpha: 0.5)
        static let primaryText = (red: 0.2, green: 0.85, blue: 1.0, alpha: 1.0)
        static let timeText = "systemOrange"
        static let titleText = "white"
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let titleSize: CGFloat = 12
        static let valueSize: CGFloat = 18
        static let unitSize: CGFloat = 12
        static let timeSize: CGFloat = 20
    }
    
    // MARK: - Resources
    struct Resources {
        static let menuIcon = "netspeed_menu"
        static let appIcon = "netspeed.icns"
    }
}
