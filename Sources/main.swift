import Cocoa
import Foundation
import HotKey
import IOKit.pwr_mgt

let appVersion = "1.0.2"
let appName = "NetworkSpeedMonitor"

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var speedPanel: SpeedPanelView!
    var timer: Timer?
    var lastRx: UInt64 = 0
    var lastTx: UInt64 = 0
    var statusItem: NSStatusItem?
    var hotKey: HotKey? // 全局快捷键
    var coffeeHotKey: HotKey? // 咖啡模式快捷键
    var coffeeMenuItem: NSMenuItem! // 咖啡菜单项
    var coffeeAssertionID: IOPMAssertionID = 0 // 咖啡模式 Assertion
    var coffeeDisplayAssertionID: IOPMAssertionID = 0 // 阻止显示器休眠 Assertion
    var globalMouseMonitor: Any?

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
        // 仅保留咖啡、关于、退出
        coffeeMenuItem = NSMenuItem(title: "咖啡", action: #selector(toggleCoffee), keyEquivalent: "k")
        coffeeMenuItem.state = .off
        menu.addItem(coffeeMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "关于", action: #selector(showAbout), keyEquivalent: "i"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu

        let width: CGFloat = 180
        let height: CGFloat = 140
        let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 400, height: 100)
        // 固定在屏幕最右上角
        let windowSize = NSRect(x: screenSize.width - width - 10, y: screenSize.height - height - 10, width: width, height: height)
        window = NSWindow(contentRect: windowSize,
                          styleMask: [.borderless],
                          backing: .buffered, defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovable = false // 禁止拖动
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.orderFront(nil)

        speedPanel = SpeedPanelView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        speedPanel.onMouseEntered = { [weak self] in
            self?.hideWindowOnHover()
        }
        window.contentView = speedPanel

        (lastRx, lastTx) = SystemMonitor.getNetworkBytes()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(updateAll), userInfo: nil, repeats: true)
        updateAll()

        // 注册全局快捷键 control+option+command+t
        hotKey = HotKey(key: .t, modifiers: [.control, .option, .command])
        hotKey?.keyDownHandler = { [weak self] in
            self?.toggleWindowVisibility()
        }
        // 注册全局快捷键 control+option+command+k 切换咖啡模式
        coffeeHotKey = HotKey(key: .k, modifiers: [.control, .option, .command])
        coffeeHotKey?.keyDownHandler = { [weak self] in
            self?.toggleCoffee()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustWindowPosition),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        adjustWindowPosition()
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
        // 电池电量
        speedPanel.batteryLevel = SystemMonitor.getBatteryLevel()
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

    /// 切换咖啡模式，防止/允许电脑睡眠和屏保
    @MainActor
    @objc func toggleCoffee() {
        if coffeeMenuItem.state == .off {
            // 开启咖啡模式，防止睡眠和屏保
            let reasonForActivity = "保持清醒，防止电脑睡眠和屏保" as CFString
            let result1 = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventSystemSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reasonForActivity,
                &coffeeAssertionID
            )
            let result2 = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reasonForActivity,
                &coffeeDisplayAssertionID
            )
            if result1 == kIOReturnSuccess && result2 == kIOReturnSuccess {
                coffeeMenuItem.state = .on
                speedPanel.showCoffee = true
                speedPanel.needsDisplay = true
            }
        } else {
            // 关闭咖啡模式，允许睡眠和屏保
            IOPMAssertionRelease(coffeeAssertionID)
            IOPMAssertionRelease(coffeeDisplayAssertionID)
            coffeeMenuItem.state = .off
            speedPanel.showCoffee = false
            speedPanel.needsDisplay = true
        }
    }

    /// 优雅退出应用
    @MainActor
    @objc func quitApp() {
        // 退出时如有必要释放 Assertion
        if coffeeMenuItem != nil && coffeeMenuItem.state == .on {
            IOPMAssertionRelease(coffeeAssertionID)
            IOPMAssertionRelease(coffeeDisplayAssertionID)
        }
        NSApplication.shared.terminate(self)
    }

    /// 鼠标悬停时隐藏窗口，移开后自动显示
    @MainActor
    func hideWindowOnHover() {
        window.orderOut(nil)
        // 注册全局鼠标移动监听
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            let mouseLocation = NSEvent.mouseLocation
            Task { @MainActor in
                let windowFrame = self.window.frame
                // 鼠标离开原窗口区域
                if !windowFrame.contains(mouseLocation) {
                    self.window.orderFront(nil)
                    if let monitor = self.globalMouseMonitor {
                        NSEvent.removeMonitor(monitor)
                        self.globalMouseMonitor = nil
                    }
                }
            }
        }
    }

    /// 切换窗口显示/隐藏
    @MainActor
    func toggleWindowVisibility() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.orderFront(nil)
        }
    }

    /// 自动将窗口吸附到主屏幕右上角
    @objc
    @MainActor
    func adjustWindowPosition() {
        let width: CGFloat = window.frame.width
        let height: CGFloat = window.frame.height
        if let screen = NSScreen.main {
            let x = screen.frame.maxX - width - 10
            let y = screen.frame.maxY - height - 10
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

/// 应用主入口，初始化 NSApplication 并启动事件循环
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run() 