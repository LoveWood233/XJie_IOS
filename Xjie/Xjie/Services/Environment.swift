import Foundation

/// 环境配置 — SEC-03: 根据编译条件切换 API 地址
enum AppEnvironment {
    /// API 基础地址
    /// - Debug: 从 Info.plist 的 API_BASE_URL 读取，默认 http://localhost:8000
    /// - Release: 必须在 Info.plist 中配置正确的生产地址
    static let apiBaseURL: String = {
        if let urlFromPlist = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !urlFromPlist.isEmpty {
            return urlFromPlist
        }
        #if DEBUG
        return "http://localhost:8000"
        #else
        fatalError("API_BASE_URL must be set in Info.plist for release builds")
        #endif
    }()
}
