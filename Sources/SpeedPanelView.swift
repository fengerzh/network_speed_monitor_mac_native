import Cocoa

class SpeedPanelView: NSView {
    var timeString: String = "--:--"
    var downloadSpeed: String = "--"
    var uploadSpeed: String = "--"
    var cpuUsage: String = "--"
    var memoryUsage: String = "--"
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
        let timeTitle = NSAttributedString(string: "时间", attributes: titleAttrs)
        let timeValue = NSAttributedString(string: timeString, attributes: valueAttrs)
        timeTitle.draw(at: NSPoint(x: 16, y: startY))
        timeValue.draw(at: NSPoint(x: 80, y: startY))
        // 下载
        let downloadTitle = NSAttributedString(string: "下载", attributes: titleAttrs)
        let (downloadNum, downloadUnit) = SpeedPanelView.splitValueAndUnit(downloadSpeed)
        let downloadValue = NSAttributedString(string: downloadNum, attributes: valueAttrs)
        let downloadUnitStr = NSAttributedString(string: downloadUnit, attributes: unitAttrs)
        downloadTitle.draw(at: NSPoint(x: 16, y: startY - lineSpacing))
        let downloadValuePoint = NSPoint(x: 80, y: startY - lineSpacing)
        downloadValue.draw(at: downloadValuePoint)
        let downloadUnitPoint = NSPoint(x: 80 + downloadValue.size().width + 2, y: startY - lineSpacing + 3)
        downloadUnitStr.draw(at: downloadUnitPoint)
        // 上传
        let uploadTitle = NSAttributedString(string: "上传", attributes: titleAttrs)
        let (uploadNum, uploadUnit) = SpeedPanelView.splitValueAndUnit(uploadSpeed)
        let uploadValue = NSAttributedString(string: uploadNum, attributes: valueAttrs)
        let uploadUnitStr = NSAttributedString(string: uploadUnit, attributes: unitAttrs)
        uploadTitle.draw(at: NSPoint(x: 16, y: startY - 2*lineSpacing))
        let uploadValuePoint = NSPoint(x: 80, y: startY - 2*lineSpacing)
        uploadValue.draw(at: uploadValuePoint)
        let uploadUnitPoint = NSPoint(x: 80 + uploadValue.size().width + 2, y: startY - 2*lineSpacing + 3)
        uploadUnitStr.draw(at: uploadUnitPoint)
        // CPU
        let cpuTitle = NSAttributedString(string: "CPU", attributes: titleAttrs)
        let (cpuNum, cpuUnit) = SpeedPanelView.splitValueAndUnit(cpuUsage + "%")
        let cpuValue = NSAttributedString(string: cpuNum, attributes: valueAttrs)
        let cpuUnitStr = NSAttributedString(string: cpuUnit, attributes: unitAttrs)
        cpuTitle.draw(at: NSPoint(x: 16, y: startY - 3*lineSpacing))
        let cpuValuePoint = NSPoint(x: 80, y: startY - 3*lineSpacing)
        cpuValue.draw(at: cpuValuePoint)
        let cpuUnitPoint = NSPoint(x: 80 + cpuValue.size().width + 2, y: startY - 3*lineSpacing + 3)
        cpuUnitStr.draw(at: cpuUnitPoint)
        // 内存
        let memTitle = NSAttributedString(string: "内存", attributes: titleAttrs)
        let (memNum, memUnit) = SpeedPanelView.splitValueAndUnit(memoryUsage)
        let memValue = NSAttributedString(string: memNum, attributes: valueAttrs)
        let memUnitStr = NSAttributedString(string: memUnit, attributes: unitAttrs)
        memTitle.draw(at: NSPoint(x: 16, y: startY - 4*lineSpacing))
        let memValuePoint = NSPoint(x: 80, y: startY - 4*lineSpacing)
        memValue.draw(at: memValuePoint)
        let memUnitPoint = NSPoint(x: 80 + memValue.size().width + 2, y: startY - 4*lineSpacing + 3)
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