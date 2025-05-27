import Cocoa

class SpeedPanelView: NSView {
    var timeString: String = "--:--"
    var downloadSpeed: String = "--"
    var uploadSpeed: String = "--"
    var cpuUsage: String = "--"
    var memoryUsage: String = "--"
    var showCoffee: Bool = false
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // 背景
        let bgColor = NSColor(calibratedWhite: 0.08, alpha: 0.5)
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
        let unitAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor(calibratedRed: 0.2, green: 0.85, blue: 1.0, alpha: 1.0)
        ]
        // 纵向布局
        let startY: CGFloat = bounds.height - 28
        let lineSpacing: CGFloat = 28
        // 时间
        let timeFont = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
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
        let spacing: CGFloat = 8
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
} 