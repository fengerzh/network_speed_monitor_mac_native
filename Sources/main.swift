import Cocoa
import Foundation
import SystemConfiguration

let appVersion = "1.0.2"
let appName = "NetworkSpeedMonitor"

class SpeedPanelView: NSView {
    var timeString: String = "--:--"
    var downloadSpeed: String = "--"
    var uploadSpeed: String = "--"
    var cpuUsage: String = "--"
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // 背景
        let bgColor = NSColor(calibratedWhite: 0.08, alpha: 0.85)
        bgColor.setFill()
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)
        path.fill()
        // 标题和内容样式
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: NSColor.white
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: 0.2, green: 0.85, blue: 1.0, alpha: 1.0)
        ]
        // 纵向布局
        let startY: CGFloat = bounds.height - 28
        let lineSpacing: CGFloat = 28
        // 时间
        let timeTitle = NSAttributedString(string: "时间", attributes: titleAttrs)
        let timeValue = NSAttributedString(string: timeString, attributes: valueAttrs)
        timeTitle.draw(at: NSPoint(x: 16, y: startY))
        timeValue.draw(at: NSPoint(x: 80, y: startY))
        // 下载
        let downloadTitle = NSAttributedString(string: "下载", attributes: titleAttrs)
        let downloadValue = NSAttributedString(string: downloadSpeed, attributes: valueAttrs)
        downloadTitle.draw(at: NSPoint(x: 16, y: startY - lineSpacing))
        downloadValue.draw(at: NSPoint(x: 80, y: startY - lineSpacing))
        // 上传
        let uploadTitle = NSAttributedString(string: "上传", attributes: titleAttrs)
        let uploadValue = NSAttributedString(string: uploadSpeed, attributes: valueAttrs)
        uploadTitle.draw(at: NSPoint(x: 16, y: startY - 2*lineSpacing))
        uploadValue.draw(at: NSPoint(x: 80, y: startY - 2*lineSpacing))
        // CPU
        let cpuTitle = NSAttributedString(string: "CPU", attributes: titleAttrs)
        let cpuValue = NSAttributedString(string: cpuUsage + "%", attributes: valueAttrs)
        cpuTitle.draw(at: NSPoint(x: 16, y: startY - 3*lineSpacing))
        cpuValue.draw(at: NSPoint(x: 80, y: startY - 3*lineSpacing))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var panel: SpeedPanelView!
    var timer: Timer?
    var lastRx: UInt64 = 0
    var lastTx: UInt64 = 0
    var statusItem: NSStatusItem?
    var lastSystemCPUTicks: [UInt32] = []
    var lastSystemCPUTotal: UInt32 = 0

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

        panel = SpeedPanelView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = panel

        (lastRx, lastTx) = getNetworkBytes()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(updateAll), userInfo: nil, repeats: true)
        updateAll()
    }

    @objc func updateAll() {
        // 时间
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        panel.timeString = formatter.string(from: date)
        // 网速
        let (rx, tx) = getNetworkBytes()
        var downloadSpeed: Double? = nil
        var uploadSpeed: Double? = nil
        if rx >= lastRx && tx >= lastTx && (lastRx != 0 || lastTx != 0) {
            downloadSpeed = Double(rx - lastRx) / 3.0
            uploadSpeed = Double(tx - lastTx) / 3.0
        }
        lastRx = rx
        lastTx = tx
        if let down = downloadSpeed, let up = uploadSpeed {
            panel.downloadSpeed = formatSpeed(down)
            panel.uploadSpeed = formatSpeed(up)
        } else {
            panel.downloadSpeed = "--"
            panel.uploadSpeed = "--"
        }
        // 全系统CPU使用率
        panel.cpuUsage = getSystemCPUUsage()
        panel.needsDisplay = true
    }

    func formatSpeed(_ speed: Double) -> String {
        if speed < 1024 {
            return String(format: "%.0f B/s", speed)
        } else if speed < 1024*1024 {
            return String(format: "%.2f KB/s", speed/1024)
        } else {
            return String(format: "%.2f MB/s", speed/1024/1024)
        }
    }

    func getSystemCPUUsage() -> String {
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
        // 差分计算
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

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = appName
        alert.informativeText = "版本号：" + appVersion
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }

    func getNetworkBytes() -> (UInt64, UInt64) {
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
        // 如果获取失败，返回0
        return (rx, tx)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run() 