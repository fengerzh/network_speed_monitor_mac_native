import Cocoa

/// 重构后的速度面板视图，保持向后兼容
class SpeedPanelView: NSView {
    var timeString: String = "--:--" {
        didSet { needsDisplay = true }
    }
    var downloadSpeed: String = "--" {
        didSet { needsDisplay = true }
    }
    var uploadSpeed: String = "--" {
        didSet { needsDisplay = true }
    }
    var cpuUsage: String = "--" {
        didSet { needsDisplay = true }
    }
    var memoryUsage: String = "--" {
        didSet { needsDisplay = true }
    }
    var batteryLevel: String = "--" {
        didSet { needsDisplay = true }
    }
    var showCoffee: Bool = false {
        didSet { needsDisplay = true }
    }
    var onMouseEntered: (() -> Void)?
    private var trackingArea: NSTrackingArea?

    // 用户偏好设置
    var userPreferences: UserPreferences = UserPreferences.defaultSettings() {
        didSet { needsDisplay = true }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 使用配置化的样式
        drawBackground()
        drawContent()
    }

    private func drawBackground() {
        let bgColor = NSColor(calibratedWhite: AppConfiguration.Colors.background.white,
                             alpha: userPreferences.appearance.backgroundAlpha)
        bgColor.setFill()
        let path = NSBezierPath(roundedRect: bounds,
                               xRadius: AppConfiguration.UI.cornerRadius,
                               yRadius: AppConfiguration.UI.cornerRadius)
        path.fill()
    }

    private func drawContent() {
        // 获取用户选择的颜色主题
        let primaryColor = userPreferences.appearance.colorTheme.primaryColor

        // 标题和内容样式
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: AppConfiguration.Fonts.titleSize),
            .foregroundColor: NSColor.white
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: AppConfiguration.Fonts.valueSize, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: primaryColor.red,
                                    green: primaryColor.green,
                                    blue: primaryColor.blue,
                                    alpha: primaryColor.alpha)
        ]
        let unitAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: AppConfiguration.Fonts.unitSize, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: primaryColor.red,
                                    green: primaryColor.green,
                                    blue: primaryColor.blue,
                                    alpha: primaryColor.alpha)
        ]
        // 纵向布局
        let startY: CGFloat = bounds.height - 28
        let lineSpacing = AppConfiguration.UI.lineSpacing
        var currentY = startY

        // 时间显示（如果启用）
        if userPreferences.enabledMetrics.timeDisplay {
            let timeFont = NSFont.monospacedDigitSystemFont(ofSize: AppConfiguration.Fonts.timeSize, weight: .bold)
            let timeColor = NSColor.systemOrange
            let timeAttrs: [NSAttributedString.Key: Any] = [
                .font: timeFont,
                .foregroundColor: timeColor
            ]
            let timeValue = NSAttributedString(string: timeString, attributes: timeAttrs)
            var totalWidth = timeValue.size().width
            var coffeeSize = CGSize.zero
            if showCoffee {
                let coffeeText = "☕️"
                let coffeeAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 20, weight: .medium),
                    .foregroundColor: timeColor
                ]
                coffeeSize = coffeeText.size(withAttributes: coffeeAttrs)
                totalWidth += coffeeSize.width + 6
            }
            let centerX = (bounds.width - totalWidth) / 2
            timeValue.draw(at: NSPoint(x: centerX, y: currentY))
            if showCoffee {
                let coffeeText = "☕️"
                let coffeeAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 20, weight: .medium),
                    .foregroundColor: timeColor
                ]
                let coffeeX = centerX + timeValue.size().width + 6
                let coffeeY = currentY + (timeValue.size().height - coffeeSize.height) / 2
                coffeeText.draw(at: NSPoint(x: coffeeX, y: coffeeY), withAttributes: coffeeAttrs)
            }
            currentY -= lineSpacing
        }
        // 网络速度显示（如果启用）
        if userPreferences.enabledMetrics.networkSpeed {
            let downloadStr = NSAttributedString(string: downloadSpeed, attributes: valueAttrs)
            let uploadStr = NSAttributedString(string: uploadSpeed, attributes: valueAttrs)
            let arrowAttrs = titleAttrs
            let arrowDown = NSAttributedString(string: "⬇️", attributes: arrowAttrs)
            let arrowUp = NSAttributedString(string: "⬆️", attributes: arrowAttrs)
            // 计算整体宽度
            let spacing = AppConfiguration.UI.spacing
            let slash = NSAttributedString(string: "/", attributes: valueAttrs)
            let speedRowWidth = arrowDown.size().width + spacing + downloadStr.size().width + spacing + slash.size().width + spacing + uploadStr.size().width + spacing + arrowUp.size().width
            let baseX = (bounds.width - speedRowWidth) / 2
            var x = baseX
            arrowDown.draw(at: NSPoint(x: x, y: currentY))
            x += arrowDown.size().width + spacing
            downloadStr.draw(at: NSPoint(x: x, y: currentY))
            x += downloadStr.size().width + spacing
            slash.draw(at: NSPoint(x: x, y: currentY))
            x += slash.size().width + spacing
            uploadStr.draw(at: NSPoint(x: x, y: currentY))
            x += uploadStr.size().width + spacing
            arrowUp.draw(at: NSPoint(x: x, y: currentY))
            currentY -= lineSpacing
        }
        // CPU使用率显示（如果启用）
        if userPreferences.enabledMetrics.cpuUsage {
            let cpuTitle = NSAttributedString(string: "CPU", attributes: titleAttrs)
            let (cpuNum, cpuUnit) = SpeedPanelView.splitValueAndUnit(cpuUsage + "%")
            let cpuValue = NSAttributedString(string: cpuNum, attributes: valueAttrs)
            let cpuUnitStr = NSAttributedString(string: cpuUnit, attributes: unitAttrs)
            cpuTitle.draw(at: NSPoint(x: 16, y: currentY))
            let cpuValuePoint = NSPoint(x: 80, y: currentY)
            cpuValue.draw(at: cpuValuePoint)
            let cpuUnitPoint = NSPoint(x: 80 + cpuValue.size().width + 2, y: currentY + 3)
            cpuUnitStr.draw(at: cpuUnitPoint)
            currentY -= lineSpacing
        }

        // 内存使用显示（如果启用）
        if userPreferences.enabledMetrics.memoryUsage {
            let memTitle = NSAttributedString(string: "内存", attributes: titleAttrs)
            let (memNum, memUnit) = SpeedPanelView.splitValueAndUnit(memoryUsage)
            let memValue = NSAttributedString(string: memNum, attributes: valueAttrs)
            let memUnitStr = NSAttributedString(string: memUnit, attributes: unitAttrs)
            memTitle.draw(at: NSPoint(x: 16, y: currentY))
            let memValuePoint = NSPoint(x: 80, y: currentY)
            memValue.draw(at: memValuePoint)
            let memUnitPoint = NSPoint(x: 80 + memValue.size().width + 2, y: currentY + 3)
            memUnitStr.draw(at: memUnitPoint)
            currentY -= lineSpacing
        }

        // 电池电量显示（如果启用）
        if userPreferences.enabledMetrics.batteryLevel {
            let batteryTitle = NSAttributedString(string: "电量", attributes: titleAttrs)
            let batteryValue = NSAttributedString(string: batteryLevel + "%", attributes: valueAttrs)
            batteryTitle.draw(at: NSPoint(x: 16, y: currentY))
            let batteryValuePoint = NSPoint(x: 80, y: currentY)
            batteryValue.draw(at: batteryValuePoint)
        }
    }
    /// 拆分数值和单位（如 "12.34 MB/s" -> ("12.34", "MB/s")）
    static func splitValueAndUnit(_ value: String) -> (String, String) {
        let pattern = "([\\d\\.\\-]+)\\s*(.*)"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: value, range: NSRange(location: 0, length: value.utf16.count)),
           let numRange = Range(match.range(at: 1), in: value) {
            let num = String(value[numRange])
            let unit: String
            if let unitRange = Range(match.range(at: 2), in: value) {
                unit = String(value[unitRange])
            } else {
                unit = ""
            }
            return (num, unit)
        }
        return (value, "")
    }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea {
            self.removeTrackingArea(area)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(area)
        trackingArea = area
    }
    override func mouseEntered(with event: NSEvent) {
        onMouseEntered?()
    }
} 