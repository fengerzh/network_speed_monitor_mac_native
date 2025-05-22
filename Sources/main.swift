import Cocoa
import Foundation
import SystemConfiguration

let appVersion = "1.0.1"
let appName = "NetworkSpeedMonitor"

class SpeedMonitorLabel: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.isEditable = false
        self.isBordered = false
        self.drawsBackground = false
        self.font = NSFont.monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        self.alignment = .center
        self.textColor = NSColor(calibratedRed: 1.0, green: 0.6, blue: 0.0, alpha: 1.0) // 桔黄色
        self.backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var label: SpeedMonitorLabel!
    var timer: Timer?
    var lastRx: UInt64 = 0
    var lastTx: UInt64 = 0
    var statusItem: NSStatusItem?
    var lastValid: Bool = true

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
        let height: CGFloat = 70 // 增加高度以显示两行
        let screenSize = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 400, height: 100)
        let windowSize = NSRect(x: screenSize.width - width - 20, y: screenSize.height - height - 40, width: width, height: height)
        window = NSWindow(contentRect: windowSize,
                          styleMask: [.borderless],
                          backing: .buffered, defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = NSColor.clear // 全透明
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.makeKeyAndOrderFront(nil)
        // 设置圆角
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 14
        window.contentView?.layer?.masksToBounds = true

        label = SpeedMonitorLabel(frame: NSRect(x: 0, y: 0, width: width, height: height))
        label.stringValue = "下行: --\n上行: --"
        window.contentView?.addSubview(label)

        (lastRx, lastTx) = getNetworkBytes()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(updateSpeed), userInfo: nil, repeats: true)
        updateSpeed()
    }

    @objc func updateSpeed() {
        let (rx, tx) = getNetworkBytes()
        var downloadSpeed: Double? = nil
        var uploadSpeed: Double? = nil
        if rx >= lastRx && tx >= lastTx && (lastRx != 0 || lastTx != 0) {
            downloadSpeed = Double(rx - lastRx) / 3.0
            uploadSpeed = Double(tx - lastTx) / 3.0
            lastValid = true
        } else {
            lastValid = false
        }
        lastRx = rx
        lastTx = tx
        if let down = downloadSpeed, let up = uploadSpeed {
            label.stringValue = "下行: \(formatSpeed(down))\n上行: \(formatSpeed(up))"
        } else {
            label.stringValue = "下行: --\n上行: --"
        }
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