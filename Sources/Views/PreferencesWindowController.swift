import Cocoa

/// 偏好设置窗口控制器
class PreferencesWindowController: NSWindowController {
    
    // MARK: - Properties
    private let preferencesManager: UserPreferencesManager
    
    // MARK: - UI Controls

    // 基本设置
    private var updateIntervalPopUp: NSPopUpButton!
    private var updateIntervalLabel: NSTextField!

    // 显示内容
    private var networkSpeedCheckbox: NSButton!
    private var cpuUsageCheckbox: NSButton!
    private var memoryUsageCheckbox: NSButton!
    private var batteryLevelCheckbox: NSButton!
    private var timeDisplayCheckbox: NSButton!

    // 外观设置
    private var backgroundAlphaSlider: NSSlider!
    private var backgroundAlphaLabel: NSTextField!
    private var colorThemeMatrix: NSMatrix!
    private var colorThemeButtons: [NSButton] = []

    // 其他设置
    private var autoStartCheckbox: NSButton!
    private var alwaysOnTopCheckbox: NSButton!

    // 快捷键显示
    private var toggleVisibilityLabel: NSTextField!
    private var toggleCoffeeModeLabel: NSTextField!

    // 按钮
    private var resetButton: NSButton!
    private var cancelButton: NSButton!
    private var okButton: NSButton!
    
    // MARK: - Initialization
    
    init(preferencesManager: UserPreferencesManager) {
        self.preferencesManager = preferencesManager
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        super.init(window: window)
        
        setupWindow()
        setupUI()
        loadPreferencesToUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupWindow() {
        guard let window = window else { return }

        window.title = "偏好设置"
        window.center()
        window.level = .modalPanel
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // 创建主容器
        let mainStackView = NSStackView()
        mainStackView.orientation = .vertical
        mainStackView.spacing = 20
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // 添加各个设置区域
        mainStackView.addArrangedSubview(createBasicSettingsSection())
        mainStackView.addArrangedSubview(createDisplaySettingsSection())
        mainStackView.addArrangedSubview(createAppearanceSettingsSection())
        mainStackView.addArrangedSubview(createOtherSettingsSection())
        mainStackView.addArrangedSubview(createHotkeysSection())
        mainStackView.addArrangedSubview(createButtonsSection())
    }
    
    private func createBasicSettingsSection() -> NSView {
        let section = createSectionView(title: "基本设置")
        
        // 刷新频率
        let intervalContainer = NSStackView()
        intervalContainer.orientation = .horizontal
        intervalContainer.spacing = 10
        
        updateIntervalLabel = NSTextField(labelWithString: "刷新频率:")
        updateIntervalPopUp = NSPopUpButton()
        updateIntervalPopUp.addItems(withTitles: ["1秒", "2秒", "3秒", "5秒", "10秒"])
        updateIntervalPopUp.itemArray.enumerated().forEach { index, item in
            let intervals = [1, 2, 3, 5, 10]
            item.tag = intervals[index]
        }
        updateIntervalPopUp.target = self
        updateIntervalPopUp.action = #selector(updateIntervalChanged(_:))
        
        intervalContainer.addArrangedSubview(updateIntervalLabel)
        intervalContainer.addArrangedSubview(updateIntervalPopUp)
        intervalContainer.addArrangedSubview(NSView()) // 占位符
        
        section.addArrangedSubview(intervalContainer)
        return section
    }
    
    private func createDisplaySettingsSection() -> NSView {
        let section = createSectionView(title: "显示内容")
        
        // 创建复选框
        networkSpeedCheckbox = createCheckbox(title: "网络速度", action: #selector(metricsCheckboxChanged(_:)))
        cpuUsageCheckbox = createCheckbox(title: "CPU使用率", action: #selector(metricsCheckboxChanged(_:)))
        memoryUsageCheckbox = createCheckbox(title: "内存使用", action: #selector(metricsCheckboxChanged(_:)))
        batteryLevelCheckbox = createCheckbox(title: "电池电量", action: #selector(metricsCheckboxChanged(_:)))
        timeDisplayCheckbox = createCheckbox(title: "时间显示", action: #selector(metricsCheckboxChanged(_:)))
        
        section.addArrangedSubview(networkSpeedCheckbox)
        section.addArrangedSubview(cpuUsageCheckbox)
        section.addArrangedSubview(memoryUsageCheckbox)
        section.addArrangedSubview(batteryLevelCheckbox)
        section.addArrangedSubview(timeDisplayCheckbox)
        
        return section
    }
    
    private func createAppearanceSettingsSection() -> NSView {
        let section = createSectionView(title: "外观设置")
        
        // 透明度设置
        let alphaContainer = NSStackView()
        alphaContainer.orientation = .horizontal
        alphaContainer.spacing = 10
        
        backgroundAlphaLabel = NSTextField(labelWithString: "透明度:")
        backgroundAlphaSlider = NSSlider()
        backgroundAlphaSlider.minValue = 0.3
        backgroundAlphaSlider.maxValue = 0.8
        backgroundAlphaSlider.target = self
        backgroundAlphaSlider.action = #selector(backgroundAlphaChanged(_:))
        
        alphaContainer.addArrangedSubview(backgroundAlphaLabel)
        alphaContainer.addArrangedSubview(backgroundAlphaSlider)
        
        // 颜色主题 - 使用单选按钮组
        let themeLabel = NSTextField(labelWithString: "颜色主题:")

        let themeContainer = NSStackView()
        themeContainer.orientation = .horizontal
        themeContainer.spacing = 15

        let blueButton = NSButton(radioButtonWithTitle: "蓝色", target: self, action: #selector(colorThemeChanged(_:)))
        blueButton.tag = 0

        let greenButton = NSButton(radioButtonWithTitle: "绿色", target: self, action: #selector(colorThemeChanged(_:)))
        greenButton.tag = 1

        let orangeButton = NSButton(radioButtonWithTitle: "橙色", target: self, action: #selector(colorThemeChanged(_:)))
        orangeButton.tag = 2

        colorThemeButtons = [blueButton, greenButton, orangeButton]

        themeContainer.addArrangedSubview(blueButton)
        themeContainer.addArrangedSubview(greenButton)
        themeContainer.addArrangedSubview(orangeButton)

        // 创建一个假的matrix来保持接口兼容
        colorThemeMatrix = NSMatrix(frame: NSRect.zero)
        colorThemeMatrix.isHidden = true
        
        section.addArrangedSubview(alphaContainer)
        section.addArrangedSubview(themeLabel)
        section.addArrangedSubview(themeContainer)
        
        return section
    }
    
    private func createOtherSettingsSection() -> NSView {
        let section = createSectionView(title: "其他设置")
        
        autoStartCheckbox = createCheckbox(title: "开机自动启动", action: #selector(otherSettingsChanged(_:)))
        alwaysOnTopCheckbox = createCheckbox(title: "窗口置顶", action: #selector(otherSettingsChanged(_:)))
        
        section.addArrangedSubview(autoStartCheckbox)
        section.addArrangedSubview(alwaysOnTopCheckbox)
        
        return section
    }
    
    private func createHotkeysSection() -> NSView {
        let section = createSectionView(title: "快捷键")
        
        let hotkeys = preferencesManager.preferences.hotkeys
        
        toggleVisibilityLabel = NSTextField(labelWithString: "显示/隐藏窗口: \(hotkeys.toggleVisibility)")
        toggleCoffeeModeLabel = NSTextField(labelWithString: "咖啡模式切换: \(hotkeys.toggleCoffeeMode)")
        
        section.addArrangedSubview(toggleVisibilityLabel)
        section.addArrangedSubview(toggleCoffeeModeLabel)
        
        return section
    }
    
    private func createButtonsSection() -> NSView {
        let container = NSStackView()
        container.orientation = .horizontal
        container.spacing = 10
        
        resetButton = NSButton(title: "重置为默认", target: self, action: #selector(resetButtonClicked(_:)))
        cancelButton = NSButton(title: "取消", target: self, action: #selector(cancelButtonClicked(_:)))
        okButton = NSButton(title: "确定", target: self, action: #selector(okButtonClicked(_:)))
        
        okButton.keyEquivalent = "\r" // 回车键
        cancelButton.keyEquivalent = "\u{1b}" // ESC键
        
        container.addArrangedSubview(resetButton)
        container.addArrangedSubview(NSView()) // 占位符
        container.addArrangedSubview(cancelButton)
        container.addArrangedSubview(okButton)
        
        return container
    }
    
    // MARK: - Helper Methods
    
    private func createSectionView(title: String) -> NSStackView {
        let section = NSStackView()
        section.orientation = .vertical
        section.spacing = 8
        
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        section.addArrangedSubview(titleLabel)
        
        return section
    }
    
    private func createCheckbox(title: String, action: Selector) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: self, action: action)
        return checkbox
    }
    
    private func loadPreferencesToUI() {
        let preferences = preferencesManager.preferences
        
        // 基本设置
        updateIntervalPopUp?.selectItem(withTag: Int(preferences.updateInterval))
        
        // 显示内容
        networkSpeedCheckbox?.state = preferences.enabledMetrics.networkSpeed ? .on : .off
        cpuUsageCheckbox?.state = preferences.enabledMetrics.cpuUsage ? .on : .off
        memoryUsageCheckbox?.state = preferences.enabledMetrics.memoryUsage ? .on : .off
        batteryLevelCheckbox?.state = preferences.enabledMetrics.batteryLevel ? .on : .off
        timeDisplayCheckbox?.state = preferences.enabledMetrics.timeDisplay ? .on : .off
        
        // 外观设置
        backgroundAlphaSlider?.doubleValue = preferences.appearance.backgroundAlpha
        
        let themeIndex: Int
        switch preferences.appearance.colorTheme {
        case .blue: themeIndex = 0
        case .green: themeIndex = 1
        case .orange: themeIndex = 2
        }

        // 更新单选按钮状态
        for (index, button) in colorThemeButtons.enumerated() {
            button.state = (index == themeIndex) ? .on : .off
        }
        
        // 其他设置
        autoStartCheckbox?.state = preferences.autoStart ? .on : .off
        alwaysOnTopCheckbox?.state = preferences.windowAlwaysOnTop ? .on : .off
    }

    // MARK: - Action Methods

    @objc private func updateIntervalChanged(_ sender: NSPopUpButton) {
        let interval = TimeInterval(sender.selectedTag())
        let result = preferencesManager.updateUpdateInterval(interval)

        if !result.isSuccess {
            Logger.shared.error("Failed to update interval: \(result.error?.localizedDescription ?? "Unknown error")")
            // 恢复到之前的值
            sender.selectItem(withTag: Int(preferencesManager.preferences.updateInterval))
        }
    }

    @objc private func backgroundAlphaChanged(_ sender: NSSlider) {
        let alpha = sender.doubleValue
        let result = preferencesManager.updateBackgroundAlpha(alpha)

        if !result.isSuccess {
            Logger.shared.error("Failed to update alpha: \(result.error?.localizedDescription ?? "Unknown error")")
            // 恢复到之前的值
            sender.doubleValue = preferencesManager.preferences.appearance.backgroundAlpha
        }
    }

    @objc private func colorThemeChanged(_ sender: NSButton) {
        let themeIndex = sender.tag
        let theme: AppearanceSettings.ColorTheme

        switch themeIndex {
        case 0: theme = .blue
        case 1: theme = .green
        case 2: theme = .orange
        default: theme = .blue
        }

        let result = preferencesManager.updateColorTheme(theme)

        if result.isSuccess {
            // 更新其他按钮状态
            for button in colorThemeButtons {
                button.state = (button == sender) ? .on : .off
            }
        } else {
            Logger.shared.error("Failed to update theme: \(result.error?.localizedDescription ?? "Unknown error")")
            // 恢复到之前的值
            sender.state = .off
            let currentTheme = preferencesManager.preferences.appearance.colorTheme
            let currentIndex: Int
            switch currentTheme {
            case .blue: currentIndex = 0
            case .green: currentIndex = 1
            case .orange: currentIndex = 2
            }
            colorThemeButtons[currentIndex].state = .on
        }
    }

    @objc private func metricsCheckboxChanged(_ sender: NSButton) {
        var metrics = preferencesManager.preferences.enabledMetrics

        switch sender {
        case networkSpeedCheckbox:
            metrics.networkSpeed = sender.state == .on
        case cpuUsageCheckbox:
            metrics.cpuUsage = sender.state == .on
        case memoryUsageCheckbox:
            metrics.memoryUsage = sender.state == .on
        case batteryLevelCheckbox:
            metrics.batteryLevel = sender.state == .on
        case timeDisplayCheckbox:
            metrics.timeDisplay = sender.state == .on
        default:
            return
        }

        let result = preferencesManager.updateEnabledMetrics(metrics)

        if !result.isSuccess {
            Logger.shared.error("Failed to update metrics: \(result.error?.localizedDescription ?? "Unknown error")")
            // 恢复到之前的值
            loadPreferencesToUI()
        }
    }

    @objc private func otherSettingsChanged(_ sender: NSButton) {
        switch sender {
        case autoStartCheckbox:
            let result = preferencesManager.updateAutoStart(sender.state == .on)
            if !result.isSuccess {
                Logger.shared.error("Failed to update auto start: \(result.error?.localizedDescription ?? "Unknown error")")
                sender.state = preferencesManager.preferences.autoStart ? .on : .off
            }

        case alwaysOnTopCheckbox:
            let result = preferencesManager.updateWindowAlwaysOnTop(sender.state == .on)
            if !result.isSuccess {
                Logger.shared.error("Failed to update always on top: \(result.error?.localizedDescription ?? "Unknown error")")
                sender.state = preferencesManager.preferences.windowAlwaysOnTop ? .on : .off
            }

        default:
            return
        }
    }

    @objc private func resetButtonClicked(_ sender: NSButton) {
        let result = preferencesManager.resetToDefaults()

        if result.isSuccess {
            loadPreferencesToUI()
            Logger.shared.info("Preferences reset to defaults")
        } else {
            Logger.shared.error("Failed to reset preferences: \(result.error?.localizedDescription ?? "Unknown error")")

            // 显示错误提示
            let alert = NSAlert()
            alert.messageText = "重置失败"
            alert.informativeText = result.error?.localizedDescription ?? "未知错误"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }

    @objc private func cancelButtonClicked(_ sender: NSButton) {
        close()
    }

    @objc private func okButtonClicked(_ sender: NSButton) {
        // 确定按钮被点击时，设置已经实时保存了，所以只需要关闭窗口
        close()
    }
}
