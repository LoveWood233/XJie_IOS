import Foundation

/// PROD-02: 崩溃上报抽象层 — 生产环境可替换为 Firebase Crashlytics / Sentry
protocol CrashReporting {
    func log(_ message: String)
    func recordError(_ error: Error, context: [String: String])
    func setUserId(_ id: String)
}

extension CrashReporting {
    func recordError(_ error: Error) {
        recordError(error, context: [:])
    }
}

/// 默认实现：日志输出（可在 Release 替换为 Firebase/Sentry 实现）
final class CrashReporter: CrashReporting {
    static let shared: CrashReporting = CrashReporter()

    func log(_ message: String) {
        AppLogger.data.info("CrashReporter: \(message)")
    }

    func recordError(_ error: Error, context: [String: String] = [:]) {
        AppLogger.data.error("CrashReporter error: \(error.localizedDescription) context: \(context)")
    }

    func setUserId(_ id: String) {
        AppLogger.auth.info("CrashReporter userId set")
    }
}
