import Cocoa
import HotKey

/// 简化的应用协调器
@MainActor
class AppCoordinator {
    // MARK: - Properties
    private var window: NSWindow?
    private var speedPanel: SpeedPanelView?
    private var statusItem: NSStatusItem?
    private var hotKey: HotKey?
    private var coffeeHotKey: HotKey?
    private var coffeeMenuItem: NSMenuItem?
    private var timer: Timer?
    private var lastRx: UInt64 = 0
    private var lastTx: UInt64 = 0
    private var globalMouseMonitor: Any?

    private let powerManagement = PowerManagementService.shared

    // MARK: - Initialization
    init() {
        Logger.shared.info("AppCoordinator initialized")
    }
    
    // MARK: - Lifecycle
    func start() {
        Logger.shared.info("Starting application coordinator")

        setupMenuBar()
        setupWindow()
        setupHotKeys()
        startMonitoring()

        Logger.shared.info("Application coordinator started successfully")
    }

    func stop() {
        Logger.shared.info("Stopping application coordinator")

        timer?.invalidate()
        timer = nil

        powerManagement.cleanup()

        hotKey = nil
        coffeeHotKey = nil

        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }

        Logger.shared.info("Application coordinator stopped")
    }
    
    // MARK: - Setup Methods
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let iconPath = Bundle.main.path(forResource: AppConfiguration.Resources.menuIcon, ofType: "png"),
               let image = NSImage(contentsOfFile: iconPath) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "📊"
            }
        }

        let menu = NSMenu()

        coffeeMenuItem = NSMenuItem(title: "咖啡", action: #selector(toggleCoffee), keyEquivalent: "")
        coffeeMenuItem?.target = self
        menu.addItem(coffeeMenuItem!)

        menu.addItem(NSMenuItem.separator())

        let aboutMenuItem = NSMenuItem(title: "关于", action: #selector(showAbout), keyEquivalent: "")
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)

        let quitMenuItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        statusItem?.menu = menu
    }

    private func setupWindow() {
        let width = AppConfiguration.UI.windowWidth
        let height = AppConfiguration.UI.windowHeight
        let margin = AppConfiguration.UI.windowMargin

        guard let screen = NSScreen.main else { return }

        let windowRect = NSRect(
            x: screen.frame.maxX - width - margin,
            y: screen.frame.maxY - height - margin,
            width: width,
            height: height
        )

        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window?.level = .floating
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.hasShadow = true
        window?.isMovable = false
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        speedPanel = SpeedPanelView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        speedPanel?.onMouseEntered = { [weak self] in
            self?.hideWindowOnHover()
        }

        window?.contentView = speedPanel
        window?.orderFront(nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustWindowPosition),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func setupHotKeys() {
        hotKey = HotKey(key: .t, modifiers: [.control, .option, .command])
        hotKey?.keyDownHandler = { [weak self] in
            self?.toggleWindowVisibility()
        }

        coffeeHotKey = HotKey(key: .k, modifiers: [.control, .option, .command])
        coffeeHotKey?.keyDownHandler = { [weak self] in
            self?.toggleCoffee()
        }
    }

    private func startMonitoring() {
        (lastRx, lastTx) = SystemMonitor.getNetworkBytes()
        timer = Timer.scheduledTimer(timeInterval: AppConfiguration.Monitoring.updateInterval, target: self, selector: #selector(updateAll), userInfo: nil, repeats: true)
        updateAll()
    }
    
    // MARK: - Action Handlers
    @objc private func updateAll() {
        guard let speedPanel = speedPanel else { return }

        // 时间
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        speedPanel.timeString = formatter.string(from: Date())

        // 网速
        let (rx, tx) = SystemMonitor.getNetworkBytes()
        var downloadSpeed: Double? = nil
        var uploadSpeed: Double? = nil

        if rx >= lastRx && tx >= lastTx && (lastRx != 0 || lastTx != 0) {
            downloadSpeed = Double(rx - lastRx) / AppConfiguration.Monitoring.updateInterval
            uploadSpeed = Double(tx - lastTx) / AppConfiguration.Monitoring.updateInterval
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

        // CPU使用率
        speedPanel.cpuUsage = SystemMonitor.getSystemCPUUsage()

        // 内存使用
        let (_, used) = SystemMonitor.getMemoryInfo()
        let gb = 1024.0 * 1024.0 * 1024.0
        let usedGB = Double(used) / gb
        speedPanel.memoryUsage = String(format: "%.2f GB", usedGB)

        // 电池电量
        speedPanel.batteryLevel = SystemMonitor.getBatteryLevel()

        // 咖啡模式状态
        speedPanel.showCoffee = powerManagement.isCoffeeModeEnabled
    }

    private func toggleWindowVisibility() {
        guard let window = window else { return }

        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.orderFront(nil)
        }
    }

    private func hideWindowOnHover() {
        guard let window = window else { return }

        window.orderOut(nil)

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, let window = self.window else { return }

            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame

            if !windowFrame.contains(mouseLocation) {
                Task { @MainActor in
                    window.orderFront(nil)
                    if let monitor = self.globalMouseMonitor {
                        NSEvent.removeMonitor(monitor)
                        self.globalMouseMonitor = nil
                    }
                }
            }
        }
    }

    @objc private func toggleCoffee() {
        let result = powerManagement.toggleCoffeeMode()

        switch result {
        case .success(let enabled):
            coffeeMenuItem?.state = enabled ? .on : .off
            speedPanel?.showCoffee = enabled
            Logger.shared.info("Coffee mode toggled: \(enabled)")

        case .failure(let error):
            Logger.shared.logError(error)
        }
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = AppConfiguration.appName
        alert.informativeText = "版本号：\(AppConfiguration.appVersion)"
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    @objc private func quitApp() {
        stop()
        NSApplication.shared.terminate(nil)
    }

    @objc private func adjustWindowPosition() {
        guard let window = window, let screen = NSScreen.main else { return }

        let width = window.frame.width
        let height = window.frame.height
        let margin = AppConfiguration.UI.windowMargin

        let newOrigin = NSPoint(
            x: screen.frame.maxX - width - margin,
            y: screen.frame.maxY - height - margin
        )

        window.setFrameOrigin(newOrigin)
    }
}
