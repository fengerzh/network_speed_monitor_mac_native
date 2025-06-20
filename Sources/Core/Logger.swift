import Foundation
import os.log

/// 日志管理器
class Logger {
    static let shared = Logger()
    
    private let osLog: OSLog
    
    private init() {
        osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "NetworkSpeedMonitor", 
                      category: "Application")
    }
    
    enum LogLevel {
        case debug
        case info
        case warning
        case error
        case fault
        
        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            case .fault:
                return .fault
            }
        }
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // 在调试模式下也打印到控制台
        #if DEBUG
        print("[\(level)] \(logMessage)")
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fault, file: file, function: function, line: line)
    }
    
    func logError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = "Error: \(error.localizedDescription)"
        log(errorMessage, level: .error, file: file, function: function, line: line)
    }
}
