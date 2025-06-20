import Foundation

/// 应用错误类型定义
enum AppError: Error, LocalizedError {
    case systemMonitorError(String)
    case networkError(String)
    case uiError(String)
    case configurationError(String)
    case powerManagementError(String)
    case resourceError(String)
    
    var errorDescription: String? {
        switch self {
        case .systemMonitorError(let message):
            return "系统监控错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .uiError(let message):
            return "界面错误: \(message)"
        case .configurationError(let message):
            return "配置错误: \(message)"
        case .powerManagementError(let message):
            return "电源管理错误: \(message)"
        case .resourceError(let message):
            return "资源错误: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .systemMonitorError:
            return "请检查系统权限设置"
        case .networkError:
            return "请检查网络连接"
        case .uiError:
            return "请重启应用"
        case .configurationError:
            return "请检查应用配置"
        case .powerManagementError:
            return "请检查系统电源管理权限"
        case .resourceError:
            return "请重新安装应用"
        }
    }
}

/// 结果类型，用于错误处理
enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
