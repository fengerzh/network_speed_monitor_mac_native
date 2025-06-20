import Cocoa
import Foundation

/// 现代化的应用委托
class ModernAppDelegate: NSObject, NSApplicationDelegate {
    private var appCoordinator: AppCoordinator?

    /// 应用启动后初始化
    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.shared.info("Application starting...")

        // 初始化应用协调器
        Task { @MainActor in
            appCoordinator = AppCoordinator()
            appCoordinator?.start()
        }

        Logger.shared.info("Application started successfully")
    }

    /// 应用即将终止
    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.info("Application terminating...")
        Task { @MainActor in
            appCoordinator?.stop()
        }
    }

    /// 应用是否应该在最后一个窗口关闭时终止
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 保持应用运行，即使窗口关闭
    }
}

/// 应用主入口，初始化 NSApplication 并启动事件循环
let app = NSApplication.shared
let delegate = ModernAppDelegate()
app.delegate = delegate
app.run()