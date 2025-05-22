import Cocoa
import Foundation

let appVersion = "1.0.2"
let appName = "NetworkSpeedMonitor"

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var speedPanel: SpeedPanelView!
    var timer: Timer?
    var lastRx: UInt64 = 0
    var lastTx: UInt64 = 0
    var statusItem: NSStatusItem?

    /// 应用启动后初始化窗口、菜单栏、定时器等
    /// - 参数 notification: 启动通知
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 菜单栏图标和菜单
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            let iconPath = Bundle.main.path(forResource: "netspeed_menu", ofType: "png")
            if let iconPath = iconPath, let image = NSImage(contentsOfFile: iconPath) {
                image.isTemplate = true // 支持深色模式自动变色
                button.image = image
            }
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "关于", action: #selector(showAbout), keyEquivalent: "i"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu

        let width: CGFloat = 180
        let height: CGFloat = 140
        let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 400, height: 100)
        let windowSize = NSRect(x: screenSize.width - width - 20, y: screenSize.height - height - 40, width: width, height: height)
        window = NSWindow(contentRect: windowSize,
                          styleMask: [.borderless],
                          backing: .buffered, defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.makeKeyAndOrderFront(nil)

        speedPanel = SpeedPanelView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = speedPanel

        (lastRx, lastTx) = SystemMonitor.getNetworkBytes()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(updateAll), userInfo: nil, repeats: true)
        updateAll()
    }

    /// 定时刷新所有监控数据（时间、网速、CPU、内存），并更新界面
    @MainActor
    @objc func updateAll() {
        // 时间
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        speedPanel.timeString = formatter.string(from: date)
        // 网速
        let (rx, tx) = SystemMonitor.getNetworkBytes()
        var downloadSpeed: Double? = nil
        var uploadSpeed: Double? = nil
        if rx >= lastRx && tx >= lastTx && (lastRx != 0 || lastTx != 0) {
            downloadSpeed = Double(rx - lastRx) / 3.0
            uploadSpeed = Double(tx - lastTx) / 3.0
        }
        lastRx = rx
        lastTx = tx
        if let down = downloadSpeed, let up = uploadSpeed {
            speedPanel.downloadSpeed = SystemMonitor.formatSpeed(down)
            speedPanel.uploadSpeed = SystemMonitor.formatSpeed(up)
        } else {
            speedPanel.downloadSpeed = "--"
            speedPanel.uploadSpeed = "--"
        }
        // 全系统CPU使用率
        speedPanel.cpuUsage = SystemMonitor.getSystemCPUUsage()
        // 内存监控
        let (_, used) = SystemMonitor.getMemoryInfo()
        let gb = 1024.0 * 1024.0 * 1024.0
        let usedGB = Double(used) / gb
        speedPanel.memoryUsage = String(format: "%.2f GB", usedGB)
        speedPanel.needsDisplay = true
    }

    /// 显示"关于"弹窗，展示应用名称和版本号
    @MainActor
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = appName
        alert.informativeText = "版本号：" + appVersion
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    /// 优雅退出应用
    @MainActor
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}

/// 应用主入口，初始化 NSApplication 并启动事件循环
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run() 