import Cocoa

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