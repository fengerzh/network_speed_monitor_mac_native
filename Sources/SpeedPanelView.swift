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
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 使用配置化的样式
        drawBackground()
        drawContent()
    }

    private func drawBackground() {
        let bgColor = NSColor(calibratedWhite: AppConfiguration.Colors.background.white,
                             alpha: AppConfiguration.Colors.background.alpha)
        bgColor.setFill()
        let path = NSBezierPath(roundedRect: bounds,
                               xRadius: AppConfiguration.UI.cornerRadius,
                               yRadius: AppConfiguration.UI.cornerRadius)
        path.fill()
    }

    private func drawContent() {
        // 标题和内容样式
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: AppConfiguration.Fonts.titleSize),
            .foregroundColor: NSColor.white
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: AppConfiguration.Fonts.valueSize, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: AppConfiguration.Colors.primaryText.red,
                                    green: AppConfiguration.Colors.primaryText.green,
                                    blue: AppConfiguration.Colors.primaryText.blue,
                                    alpha: AppConfiguration.Colors.primaryText.alpha)
        ]
        let unitAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: AppConfiguration.Fonts.unitSize, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: AppConfiguration.Colors.primaryText.red,
                                    green: AppConfiguration.Colors.primaryText.green,
                                    blue: AppConfiguration.Colors.primaryText.blue,
                                    alpha: AppConfiguration.Colors.primaryText.alpha)
        ]
        // 纵向布局
        let startY: CGFloat = bounds.height - 28
        let lineSpacing = AppConfiguration.UI.lineSpacing
        // 时间
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
        let timeY = startY
        timeValue.draw(at: NSPoint(x: centerX, y: timeY))
        if showCoffee {
            let coffeeText = "☕️"
            let coffeeAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: timeColor
            ]
            let coffeeX = centerX + timeValue.size().width + 6
            let coffeeY = timeY + (timeValue.size().height - coffeeSize.height) / 2
            coffeeText.draw(at: NSPoint(x: coffeeX, y: coffeeY), withAttributes: coffeeAttrs)
        }
        // 下载/上传合并一行
        let downloadStr = NSAttributedString(string: downloadSpeed, attributes: valueAttrs)
        let uploadStr = NSAttributedString(string: uploadSpeed, attributes: valueAttrs)
        let arrowAttrs = titleAttrs
        let arrowDown = NSAttributedString(string: "⬇️", attributes: arrowAttrs)
        let arrowUp = NSAttributedString(string: "⬆️", attributes: arrowAttrs)
        // 计算整体宽度
        let spacing = AppConfiguration.UI.spacing
        let slash = NSAttributedString(string: "/", attributes: valueAttrs)
        let speedRowWidth = arrowDown.size().width + spacing + downloadStr.size().width + spacing + slash.size().width + spacing + uploadStr.size().width + spacing + arrowUp.size().width
        let baseY = startY - lineSpacing
        let baseX = (bounds.width - speedRowWidth) / 2
        var x = baseX
        arrowDown.draw(at: NSPoint(x: x, y: baseY))
        x += arrowDown.size().width + spacing
        downloadStr.draw(at: NSPoint(x: x, y: baseY))
        x += downloadStr.size().width + spacing
        slash.draw(at: NSPoint(x: x, y: baseY))
        x += slash.size().width + spacing
        uploadStr.draw(at: NSPoint(x: x, y: baseY))
        x += uploadStr.size().width + spacing
        arrowUp.draw(at: NSPoint(x: x, y: baseY))
        // CPU
        let cpuTitle = NSAttributedString(string: "CPU", attributes: titleAttrs)
        let (cpuNum, cpuUnit) = SpeedPanelView.splitValueAndUnit(cpuUsage + "%")
        let cpuValue = NSAttributedString(string: cpuNum, attributes: valueAttrs)
        let cpuUnitStr = NSAttributedString(string: cpuUnit, attributes: unitAttrs)
        cpuTitle.draw(at: NSPoint(x: 16, y: startY - 2*lineSpacing))
        let cpuValuePoint = NSPoint(x: 80, y: startY - 2*lineSpacing)
        cpuValue.draw(at: cpuValuePoint)
        let cpuUnitPoint = NSPoint(x: 80 + cpuValue.size().width + 2, y: startY - 2*lineSpacing + 3)
        cpuUnitStr.draw(at: cpuUnitPoint)
        // 内存
        let memTitle = NSAttributedString(string: "内存", attributes: titleAttrs)
        let (memNum, memUnit) = SpeedPanelView.splitValueAndUnit(memoryUsage)
        let memValue = NSAttributedString(string: memNum, attributes: valueAttrs)
        let memUnitStr = NSAttributedString(string: memUnit, attributes: unitAttrs)
        memTitle.draw(at: NSPoint(x: 16, y: startY - 3*lineSpacing))
        let memValuePoint = NSPoint(x: 80, y: startY - 3*lineSpacing)
        memValue.draw(at: memValuePoint)
        let memUnitPoint = NSPoint(x: 80 + memValue.size().width + 2, y: startY - 3*lineSpacing + 3)
        memUnitStr.draw(at: memUnitPoint)
        // 电池电量
        let batteryTitle = NSAttributedString(string: "电量", attributes: titleAttrs)
        let batteryValue = NSAttributedString(string: batteryLevel + "%", attributes: valueAttrs)
        batteryTitle.draw(at: NSPoint(x: 16, y: startY - 4*lineSpacing))
        let batteryValuePoint = NSPoint(x: 80, y: startY - 4*lineSpacing)
        batteryValue.draw(at: batteryValuePoint)
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