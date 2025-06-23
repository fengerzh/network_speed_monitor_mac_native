import Foundation

/// 用户偏好设置管理器
class UserPreferencesManager {
    
    // MARK: - Constants
    static let preferencesKey = "UserPreferences"
    private static let defaultSuiteName = "com.networkspeedmonitor.preferences"
    
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private var _preferences: UserPreferences
    
    /// 当前用户偏好设置
    var preferences: UserPreferences {
        return _preferences
    }
    
    // MARK: - Initialization
    
    /// 初始化偏好设置管理器
    /// - Parameter suiteName: UserDefaults套件名称，用于测试时隔离数据
    init(suiteName: String? = nil) {
        let suite = suiteName ?? Self.defaultSuiteName
        self.userDefaults = UserDefaults(suiteName: suite) ?? UserDefaults.standard
        self._preferences = Self.loadPreferences(from: userDefaults)
    }
    
    // MARK: - Public Methods
    
    /// 保存偏好设置
    /// - Parameter preferences: 要保存的偏好设置
    /// - Returns: 操作结果
    func savePreferences(_ preferences: UserPreferences) -> Result<Void, AppError> {
        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: Self.preferencesKey)
            userDefaults.synchronize()
            
            self._preferences = preferences
            
            // 发送通知
            NotificationCenter.default.post(
                name: .userPreferencesDidChange,
                object: self,
                userInfo: ["preferences": preferences]
            )
            
            Logger.shared.info("User preferences saved successfully")
            return .success(())
            
        } catch {
            Logger.shared.error("Failed to save preferences: \(error)")
            return .failure(.configurationError("保存偏好设置失败: \(error.localizedDescription)"))
        }
    }
    
    /// 重置为默认设置
    /// - Returns: 操作结果
    func resetToDefaults() -> Result<Void, AppError> {
        let defaultPreferences = UserPreferences.defaultSettings()
        return savePreferences(defaultPreferences)
    }
    
    // MARK: - 更新特定设置的方法
    
    /// 更新刷新间隔
    /// - Parameter interval: 新的刷新间隔（1.0-10.0秒）
    /// - Returns: 操作结果
    func updateUpdateInterval(_ interval: TimeInterval) -> Result<Void, AppError> {
        guard validateUpdateInterval(interval) else {
            return .failure(.configurationError("刷新间隔必须在1.0到10.0秒之间"))
        }
        
        var newPreferences = _preferences
        newPreferences.updateInterval = interval
        return savePreferences(newPreferences)
    }
    
    /// 更新背景透明度
    /// - Parameter alpha: 新的透明度（0.3-0.8）
    /// - Returns: 操作结果
    func updateBackgroundAlpha(_ alpha: Double) -> Result<Void, AppError> {
        guard validateBackgroundAlpha(alpha) else {
            return .failure(.configurationError("背景透明度必须在0.3到0.8之间"))
        }
        
        var newPreferences = _preferences
        newPreferences.appearance.backgroundAlpha = alpha
        return savePreferences(newPreferences)
    }
    
    /// 更新颜色主题
    /// - Parameter theme: 新的颜色主题
    /// - Returns: 操作结果
    func updateColorTheme(_ theme: AppearanceSettings.ColorTheme) -> Result<Void, AppError> {
        var newPreferences = _preferences
        newPreferences.appearance.colorTheme = theme
        return savePreferences(newPreferences)
    }
    
    /// 更新启用的监控指标
    /// - Parameter metrics: 新的监控指标设置
    /// - Returns: 操作结果
    func updateEnabledMetrics(_ metrics: EnabledMetrics) -> Result<Void, AppError> {
        var newPreferences = _preferences
        newPreferences.enabledMetrics = metrics
        return savePreferences(newPreferences)
    }
    
    /// 更新开机自启动设置
    /// - Parameter autoStart: 是否开机自启动
    /// - Returns: 操作结果
    func updateAutoStart(_ autoStart: Bool) -> Result<Void, AppError> {
        var newPreferences = _preferences
        newPreferences.autoStart = autoStart
        return savePreferences(newPreferences)
    }
    
    /// 更新窗口置顶设置
    /// - Parameter alwaysOnTop: 是否窗口置顶
    /// - Returns: 操作结果
    func updateWindowAlwaysOnTop(_ alwaysOnTop: Bool) -> Result<Void, AppError> {
        var newPreferences = _preferences
        newPreferences.windowAlwaysOnTop = alwaysOnTop
        return savePreferences(newPreferences)
    }
    
    // MARK: - 验证方法
    
    /// 验证刷新间隔是否有效
    /// - Parameter interval: 要验证的间隔
    /// - Returns: 是否有效
    func validateUpdateInterval(_ interval: TimeInterval) -> Bool {
        return interval >= 1.0 && interval <= 10.0
    }
    
    /// 验证背景透明度是否有效
    /// - Parameter alpha: 要验证的透明度
    /// - Returns: 是否有效
    func validateBackgroundAlpha(_ alpha: Double) -> Bool {
        return alpha >= 0.3 && alpha <= 0.8
    }
    
    // MARK: - Private Methods
    
    /// 从UserDefaults加载偏好设置
    /// - Parameter userDefaults: UserDefaults实例
    /// - Returns: 加载的偏好设置或默认设置
    private static func loadPreferences(from userDefaults: UserDefaults) -> UserPreferences {
        guard let data = userDefaults.data(forKey: preferencesKey) else {
            Logger.shared.info("No saved preferences found, using defaults")
            return UserPreferences.defaultSettings()
        }
        
        do {
            let preferences = try JSONDecoder().decode(UserPreferences.self, from: data)
            Logger.shared.info("User preferences loaded successfully")
            return preferences
        } catch {
            Logger.shared.error("Failed to decode preferences: \(error), using defaults")
            return UserPreferences.defaultSettings()
        }
    }
}

// MARK: - 通知扩展

extension Notification.Name {
    /// 用户偏好设置变更通知
    static let userPreferencesDidChange = Notification.Name("userPreferencesDidChange")
}
